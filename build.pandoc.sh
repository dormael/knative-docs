#!/bin/bash

#sudo apt install texlive-fonts-recommended texlive-latex-recommended

FILES=( `go run pkg/main/main.go | sed 's/\/home\/dormael\/go\/src\/github.com\/dormael\/knative-docs\///' | sed 's/LocalFile //' | sed 's/^TOC.md$/README.md/'` )

pandoc --toc --top-level-division=chapter -o knative-doc.pdf ${FILES[@]}
#pandoc --toc --top-level-division=chapter -o knative-doc.pdf ${FILES[@]} && mv knative-doc.pdf /data0/download/
