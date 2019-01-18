package main

import (
	"path/filepath"
	"testing"
)

func Test_parse(t *testing.T) {
	rdir := chdir()
	replaceMap := make(map[string]string, 0)
	replaceMap["https://github.com/knative/docs/blob/master"] = rdir

	tests := []struct {
		name string
		path []string
	}{
		// {name: "parseCodeBlock", path: []string{filepath.Join("serving/samples/helloworld-clojure", "README.md")}},
		// {name: "linkWithLOC", path: []string{filepath.Join("serving/samples/autoscale-go", "README.md")}},
		{name: "replaceLinksToLocal", path: []string{filepath.Join("build", "README.md")}},
		//{name: "parse", path: filepath.Join(".", "TOC.md")},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			parse(tt.path, replaceMap)
		})
	}
}
