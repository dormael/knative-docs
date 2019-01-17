#!/bin/bash

#sudo apt install texlive-xetex librsvg2-bin

FILES=( `go run pkg/main/main.go | sed 's/\/home\/dormael\/go\/src\/github.com\/dormael\/knative-docs\///' | sed 's/LocalFile //' | sed 's/^TOC.md$/README.md/'` )

RESOURCE_PATH=".:./install:./build:./serving:./eventing:./serving/samples/autoscale-go:./serving/samples/knative-routing-go"

pandoc --resource-path=${RESOURCE_PATH} --pdf-engine=xelatex --toc --top-level-division=chapter -o knative-doc.pdf ${FILES[@]}
#pandoc --resource-path=${RESOURCE_PATH} --css=pandoc.css --pdf-engine=xelatex --toc --top-level-division=chapter -o knative-doc.pdf install/Knative-with-Gardener.md
