#!/usr/bin/env bash

# Script to download and setup directory structure
set -e

# Parse data model data files to flusight format
yarn
yarn run test
yarn run parse-data

# Remove CU-models except select
rm -r ./data/Cumulative\ Deaths/CU-nointerv
rm -r ./data/Incident\ Deaths/CU-nointerv
rm -r ./data/Cumulative\ Deaths/CU-60-contact
rm -r ./data/Incident\ Deaths/CU-60-contact
rm -r ./data/Cumulative\ Deaths/CU-70-contact
rm -r ./data/Incident\ Deaths/CU-70-contact
rm -r ./data/Cumulative\ Deaths/CU-80-contact
rm -r ./data/Incident\ Deaths/CU-80-contact
rm -r ./data/Cumulative\ Deaths/CU-80-contact1x5p
rm -r ./data/Incident\ Deaths/CU-80-contact1x5p
rm -r ./data/Cumulative\ Deaths/CU-80-contact1x10p
rm -r ./data/Incident\ Deaths/CU-80-contact1x10p
rm -r ./data/Cumulative\ Deaths/CU-80-contactw5p
rm -r ./data/Incident\ Deaths/CU-80-contactw5p
rm -r ./data/Cumulative\ Deaths/CU-80-contactw10p
rm -r ./data/Incident\ Deaths/CU-80-contactw10p

# Remove UChicago except CovidIL_100
rm -r ./data/Cumulative\ Deaths/UChicago-CovidIL_40
rm -r ./data/Incident\ Deaths/UChicago-CovidIL_40
rm -r ./data/Cumulative\ Deaths/UChicago-CovidIL_60
rm -r ./data/Incident\ Deaths/UChicago-CovidIL_60
rm -r ./data/Cumulative\ Deaths/UChicago-CovidIL_80
rm -r ./data/Incident\ Deaths/UChicago-CovidIL_80
rm -r ./data/Cumulative\ Deaths/UChicago-CovidIL_100
rm -r ./data/Incident\ Deaths/UChicago-CovidIL_100
rm -r ./data/Cumulative\ Deaths/UChicago-CovidIL_10_increase
rm -r ./data/Incident\ Deaths/UChicago-CovidIL_10_increase
rm -r ./data/Cumulative\ Deaths/UChicago-CovidIL_30_increase
rm -r ./data/Incident\ Deaths/UChicago-CovidIL_30_increase

# Remove JHU
# rm -r ./data/Cumulative\ Deaths/JHU_IDD-CovidSPHighDist
# rm -r ./data/Incident\ Deaths/JHU_IDD-CovidSPHighDist
# rm -r ./data/Cumulative\ Deaths/JHU_IDD-CovidSPModDist
# rm -r ./data/Incident\ Deaths/JHU_IDD-CovidSPModDist
# rm -r ./data/Cumulative\ Deaths/JHU_IDD-CovidSP
# rm -r ./data/Incident\ Deaths/JHU_IDD-CovidSP

# # Remove Iowa State Except STEM10
# rm -r ./data/Cumulative\ Deaths/IowaStateLW-STEM15
# rm -r ./data/Incident\ Deaths/IowaStateLW-STEM15

# Remove LANL-GrowthRateHosp
# rm -r ./data/Cumulative\ Deaths/LANL-GrowthRateHosp
# rm -r ./data/Incident\ Deaths/LANL-GrowthRateHosp

# Remove Auquan
# rm -r ./data/Cumulative\ Deaths/Auquan-SEIR
rm -r ./data/Incident\ Deaths/Auquan-SEIR

# Remove CovidActNow-SEIR_CAN (no week estimates)
# rm -r ./data/Cumulative\ Deaths/CAN-SEIR_CAN
# rm -r ./data/Incident\ Deaths/CAN-SEIR_CAN

# Remove Imperial ensemble 1
rm -r ./data/Cumulative\ Deaths/Imperial-Ensemble1
rm -r ./data/Incident\ Deaths/Imperial-Ensemble1
# rm -r ./data/Incident\ Deaths/Imperial-Ensemble2

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
cd ../data-truth
python3 ./get-truth-data.py
cd ../visualization

# Replace already present data
rm -rf ./vis-master/data
mv ./data ./vis-master

cd ./vis-master
npm install
yarn
yarn run parse-viz-master # Parse visualization data to json
#yarn run test
cd .. # in flusight-deploy now
