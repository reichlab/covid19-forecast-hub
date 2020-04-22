#!/usr/bin/env bash

# Script to download and setup flusight directory structure
set -e

# Parse data model data files to flusight format
yarn
yarn run test
yarn run parse-data
rm -r ./data/NaN-NaN
rm -r ./data/2019-2020/CU-nointerv
python3 convert-forecasts.py
python3 get-truth-data.py

# Replace already present data
rm -rf ./flusight-master/data
mv ./data ./flusight-master

cd ./flusight-master
yarn
yarn run parse
#yarn run test
cd .. # in flusight-deploy now
