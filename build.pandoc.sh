#!/bin/bash

FILES=( "install/README.md" "serving/README.md" "build/README.md" "eventing/README.md" )

pandoc --toc --top-level-division=chapter -o knative-doc.pdf ${FILES[@]} && mv knative-doc.pdf /data0/download/
