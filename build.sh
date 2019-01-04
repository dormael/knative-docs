#!/bin/bash

rm -f *.pdf
find . -name "*.md"|grep -v "./test" | grep -v "./vendor" | grep -v "./.github" | sed 's/.\///' | sed 's/\//\t/' | cut -f 1|grep -v ".md"|sort|uniq | while read -r dir; do gimli -merge -outputfilename ${dir} -file ${dir} -stylesheet style.css -w '--toc --footer-right "[page]/[toPage]"'; done

rm knative.docs.tar.gz
tar cvfz knative.docs.tar.gz *.pdf
