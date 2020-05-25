#!/usr/bin/env bash

set -e

# Build the site
cd ./vis-master

yarn run build
# cp -r ./dist/* ../../ # Copy to repo root
cd .. # in ./visualization
rm -rf ./vis-master/data