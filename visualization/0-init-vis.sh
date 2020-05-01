#!/usr/bin/env bash

# Script to download and setup directory structure
set -e

# Parse data model data files to flusight format
yarn
yarn run test
yarn run parse-data
<<<<<<< HEAD
#rm -r ./data/2019-2020/CU-nointerv
#rm -r ./data/2019-2020/NotreDame-FRED
=======
rm -r ./data/2019-2020/CU-nointerv
rm -r ./data/2019-2020/NotreDame-FRED
rm -r ./data/2019-2020/IowaStateLW-STEM10
rm -r ./data/2019-2020/IowaStateLW-STEM15
>>>>>>> 83cb2235b87bd30275d6a3862567e7709a346a8e
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
