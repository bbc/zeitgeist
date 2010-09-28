#!/bin/sh
ruby scripts/display-pipeline.rb | dot -Tpng > pipeline.png
