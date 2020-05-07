#!/usr/bin/env bash

# Script to download and setup directory structure
set -e

# Parse data model data files to flusight format
yarn
yarn run test
yarn run parse-data

# Remove CU-nointerv
rm -r ./data/Cumulative\ Deaths/CU-nointerv
rm -r ./data/Incident\ Deaths/CU-nointerv

# Remove Iowa State
# rm -r ./data/Cumulative\ Deaths/IowaStateLW-STEM10
# rm -r ./data/Incident\ Deaths/IowaStateLW-STEM10
# rm -r ./data/Cumulative\ Deaths/IowaStateLW-STEM15
# rm -r ./data/Incident\ Deaths/IowaStateLW-STEM15

# Remove LANL-GrowthRateHosp
rm -r ./data/Cumulative\ Deaths/LANL-GrowthRateHosp
rm -r ./data/Incident\ Deaths/LANL-GrowthRateHosp

# Remove Auquan
rm -r ./data/Cumulative\ Deaths/Auquan-SEIR
rm -r ./data/Incident\ Deaths/Auquan-SEIR

# Remove Imperial Incident
rm -r ./data/Incident\ Deaths/Imperial-Ensemble1
rm -r ./data/Incident\ Deaths/Imperial-Ensemble2

# Remove Ensemble Incident
rm -r ./data/Incident\ Deaths/COVIDhub-ensemble

# # Remove MOBS_NEU-GLEAM_COVID Incident
# rm -r ./data/Incident\ Deaths/MOBS-GLEAM_COVID

# Remove UMass-ExpertCrowd
rm -r ./data/Incident\ Deaths/UMass-ExpertCrowd
rm -r ./data/Cumulative\ Deaths/UMass-ExpertCrowd

# Parse through forecasts and update format
python3 ./scripts/convert-forecasts.py

# Get truth data
python3 ./scripts/get-truth-data.py

# Replace already present data
rm -rf ./vis-master/data
mv ./data ./vis-master

cd ./vis-master
npm install
yarn
yarn run parse # Parse visualization data to json
#yarn run test
cd .. # in flusight-deploy now
