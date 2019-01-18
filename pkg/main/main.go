package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	blackfriday "gopkg.in/russross/blackfriday.v2"
)

var globalProcessedMap = make(map[string]string, 0)

func main() {
	rdir, _ := os.Getwd()
	replaceMap := make(map[string]string, 0)
	replaceMap["https://github.com/knative/docs/blob/master"] = rdir

	parse([]string{filepath.Join(".", "TOC.md")}, replaceMap)
}

func parse(files []string, replaceMap map[string]string) {
	suspended := make([]string, 0)
	for _, filename := range files {
		dir, file := filepath.Split(filename)

		linkOrder, _ := collectLinks(dir, file)
		localFileQueue, suspendDirQueue, suspendFileQueue := aggregateLinks(dir, linkOrder, replaceMap)

		for _, f := range localFileQueue {
			globalProcessedMap[f] = "Done"
			fmt.Println("LocalFile", f)
		}

		for _, d := range suspendDirQueue {
			readme := filepath.Join(d, "README.md")
			if _, err := os.Stat(readme); err == nil {
				suspended = append(suspended, readme)
			} else if os.IsNotExist(err) {
				files, err := ioutil.ReadDir(d)
				if err != nil {
					panic(err)
				}
				for _, f := range files {
					if f.IsDir() {
						continue
					}
					suspended = append(suspended, filepath.Join(d, f.Name()))
				}
			} else {
				panic(err)
			}
		}

		for _, f := range suspendFileQueue {
			suspended = append(suspended, f)
		}
	}

	arranged := make([]string, 0)
	for _, f := range suspended {
		if _, ok := globalProcessedMap[f]; !ok {
			arranged = append(arranged, f)
		}
	}

	if len(arranged) > 0 {
		parse(arranged, replaceMap)
	}
}

func collectLinks(dir, file string) ([]string, map[string]string) {
	input, err := ioutil.ReadFile(filepath.Join(dir, file))

	if err != nil {
		panic(err)
	}

	linkMap := make(map[string]string, 0)
	linkOrder := make([]string, 0)

	linkMap[file] = ""
	linkOrder = append(linkOrder, file)

	md := blackfriday.New(blackfriday.WithExtensions(blackfriday.CommonExtensions))
	node := md.Parse(input)

	var lastDest string
	node.Walk(func(n *blackfriday.Node, entering bool) blackfriday.WalkStatus {
		t := n.Type
		text := string(n.Literal)

		if t == blackfriday.CodeBlock {
			return blackfriday.SkipChildren
		}

		if t == blackfriday.Link {
			ld := n.LinkData
			lastDest = string(ld.Destination)
		} else if t == blackfriday.Text && lastDest != "" {

			_, ok := linkMap[lastDest]

			if ok {
				lastDest = ""
			} else if text != "" {
				linkOrder = append(linkOrder, lastDest)
				linkMap[lastDest] = text
			}
			lastDest = ""
		} else {
			lastDest = ""
		}

		return blackfriday.GoToNext
	})

	return linkOrder, linkMap
}

func aggregateLinks(dir string, linkOrder []string, replaceMap map[string]string) (localFileQueue, suspendDirQueue, suspendFileQueue []string) {
	localFileQueue = make([]string, 0)
	suspendDirQueue = make([]string, 0)
	suspendFileQueue = make([]string, 0)

	for _, k := range linkOrder {
		for o, n := range replaceMap {
			if strings.HasPrefix(k, o) {
				k = strings.Replace(k, o, n, 1)
				break
			}
		}

		if strings.HasPrefix(k, "http") {
			continue
		}

		var dirfile string
		if isAbs(k) {
			dirfile = k
		} else {
			dirfile = filepath.Join(dir, k)
		}

		spl := strings.Split(dirfile, "#L")

		if len(spl) > 0 {
			if _, err := strconv.Atoi(spl[len(spl)-1]); err == nil {
				continue
			}
		}

		abs := toAbs(dirfile)

		d, f := filepath.Split(k)
		if f == "" {
			fmt.Println("Skip", dirfile)
			continue
		}

		if _, ok := globalProcessedMap[abs]; ok {
			continue
		}

		stat, err := os.Stat(abs)

		if err != nil {
			if os.IsNotExist(err) {
				continue
			}
			panic(err)
		}

		if stat.IsDir() {
			suspendDirQueue = append(suspendDirQueue, abs)
			continue
		}

		if toAbs(d) == toAbs(dir) {
			localFileQueue = append(localFileQueue, abs)
		} else {
			suspendFileQueue = append(suspendFileQueue, abs)
		}
	}

	return localFileQueue, suspendDirQueue, suspendFileQueue
}

func toAbs(dirfile string) string {
	abs, err := filepath.Abs(dirfile)
	if err != nil {
		panic(err)
	}
	return abs
}

func isAbs(dirfile string) bool {
	abs, err := filepath.Abs(dirfile)
	if err != nil {
		return false
	}

	return abs == dirfile
}

func chdir() string {
	err := os.Chdir("../..")
	if err != nil {
		panic(err)
	}

	wd, err := os.Getwd()
	if err != nil {
		panic(err)
	}

	return wd
}
