#!/usr/bin/env bash

# Script to download and setup flusight directory structure
set -e

# Parse data model data files to flusight format
yarn
yarn run test
yarn run parse-data
rm -r ./data/NaN-NaN
rm -r ./data/2019-2020/CU-nointerv
rm -r ./data/2019-2020/CovidAnalytics-DELPHI
rm -r ./data/2019-2020/NotreDame-FRED
python3 ./scripts/convert-forecasts.py
python3 ./scripts/get-truth-data.py

# Replace already present data
rm -rf ./vis-master/data
mv ./data ./vis-master

cd ./vis-master
yarn
yarn run parse
#yarn run test
cd .. # in flusight-deploy now
