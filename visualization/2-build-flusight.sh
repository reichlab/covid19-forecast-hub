#!/usr/bin/env bash

set -e

# Build the site
cd ./flusight-master

yarn run build
# cp -r ./dist/* ../../ # Copy to repo root
cd .. # in ./flusight-deploy
rm -rf ./flusight-master/data