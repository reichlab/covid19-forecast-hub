#!/usr/bin/env bash

# Script to download and setup directory structure
set -e

# Parse data model data files to flusight format
npm run test
npm run parse-data

# Parse through forecasts and update format
python3 ./scripts/convert_forecasts.py

# Get truth data
cd ../data-truth
python3 ./get-truth-data.py
cd ../visualization

# Replace already present data
rm -rf ./vis-master/data
mv ./data ./vis-master

cd ./vis-master
npm run parse-viz-master # Parse visualization data to json
#yarn run test
cd .. # in flusight-deploy now
