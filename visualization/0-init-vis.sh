#!/usr/bin/env bash

# Script to download and setup directory structure
set -e

# Parse data model data files to flusight format
npm run test
npm run parse-data

# Remove CU-models except select
rm -rf ./data/Cumulative\ Deaths/CU-nointerv
rm -rf ./data/Incident\ Deaths/CU-nointerv
rm -rf ./data/Cumulative\ Deaths/CU-60-contact
rm -rf ./data/Incident\ Deaths/CU-60-contact
rm -rf ./data/Cumulative\ Deaths/CU-70-contact
rm -rf ./data/Incident\ Deaths/CU-70-contact
rm -rf ./data/Cumulative\ Deaths/CU-80-contact
rm -rf ./data/Incident\ Deaths/CU-80-contact
rm -rf ./data/Cumulative\ Deaths/CU-80-contact1x5p
rm -rf ./data/Incident\ Deaths/CU-80-contact1x5p
rm -rf ./data/Cumulative\ Deaths/CU-80-contact1x10p
rm -rf ./data/Incident\ Deaths/CU-80-contact1x10p
rm -rf ./data/Cumulative\ Deaths/CU-80-contactw5p
rm -rf ./data/Incident\ Deaths/CU-80-contactw5p
rm -rf ./data/Cumulative\ Deaths/CU-80-contactw10p
rm -rf ./data/Incident\ Deaths/CU-80-contactw10p

rm -rf ./data/Cumulative\ Deaths/CU-scenario_*
rm -rf ./data/Incident\ Deaths/CU-scenario_*

rm -rf ./data/Cumulative\ Deaths/Auquan-SEIR
rm -rf ./data/Incident\ Deaths/Auquan-SEIR


# Remove UChicago except CovidIL_100
rm -rf ./data/Cumulative\ Deaths/UChicago-CovidIL_40
rm -rf ./data/Incident\ Deaths/UChicago-CovidIL_40
rm -rf ./data/Cumulative\ Deaths/UChicago-CovidIL_60
rm -rf ./data/Incident\ Deaths/UChicago-CovidIL_60
rm -rf ./data/Cumulative\ Deaths/UChicago-CovidIL_80
rm -rf ./data/Incident\ Deaths/UChicago-CovidIL_80
rm -rf ./data/Cumulative\ Deaths/UChicago-CovidIL_100
rm -rf ./data/Incident\ Deaths/UChicago-CovidIL_100
rm -rf ./data/Cumulative\ Deaths/UChicago-CovidIL_10_increase
rm -rf ./data/Incident\ Deaths/UChicago-CovidIL_10_increase
rm -rf ./data/Cumulative\ Deaths/UChicago-CovidIL_30_increase
rm -rf ./data/Incident\ Deaths/UChicago-CovidIL_30_increase

# Remove JHU
# rm -rf ./data/Cumulative\ Deaths/JHU_IDD-CovidSPHighDist
# rm -rf ./data/Incident\ Deaths/JHU_IDD-CovidSPHighDist
# rm -rf ./data/Cumulative\ Deaths/JHU_IDD-CovidSPModDist
# rm -rf ./data/Incident\ Deaths/JHU_IDD-CovidSPModDist
# rm -rf ./data/Cumulative\ Deaths/JHU_IDD-CovidSP
# rm -rf ./data/Incident\ Deaths/JHU_IDD-CovidSP

# Remove Iowa State Except STEM10
# rm -rf ./data/Cumulative\ Deaths/IowaStateLW-STEM15
# rm -rf ./data/Incident\ Deaths/IowaStateLW-STEM15

# Remove LANL-GrowthRateHosp
# rm -rf ./data/Cumulative\ Deaths/LANL-GrowthRateHosp
# rm -rf ./data/Incident\ Deaths/LANL-GrowthRateHosp

# Remove Auquan
# rm -rf ./data/Cumulative\ Deaths/Auquan-SEIR
rm -rf ./data/Incident\ Deaths/Auquan-SEIR

# Remove CovidActNow-SEIR_CAN (no week estimates)
# rm -rf ./data/Cumulative\ Deaths/CAN-SEIR_CAN
# rm -rf ./data/Incident\ Deaths/CAN-SEIR_CAN

# Remove Imperial ensemble 1
rm -rf ./data/Cumulative\ Deaths/Imperial-Ensemble1
rm -rf ./data/Incident\ Deaths/Imperial-Ensemble1

rm -rf ./data/Cumulative\ Deaths/CovidActNow-SEIR_CAN
rm -rf ./data/Incident\ Deaths/CovidActNow-SEIR_CAN
# rm -rf ./data/Incident\ Deaths/Imperial-Ensemble2

rm -rf ./data/Cumulative\ Deaths/CU-high
rm -rf ./data/Incident\ Deaths/CU-high

rm -rf ./data/Cumulative\ Deaths/CU-low
rm -rf ./data/Incident\ Deaths/CU-low

rm -rf ./data/Cumulative\ Deaths/CU-mid
rm -rf ./data/Incident\ Deaths/CU-mid

# Remove failing models right now
rm -rf ./data/Cumulative\ Deaths/RobertWalraven-ESG
rm -rf ./data/Incident\ Deaths/RobertWalraven-ESG

# Remove Ensemble Incident
# rm -rf ./data/Incident\ Deaths/COVIDhub-ensemble

# # Remove MOBS_NEU-GLEAM_COVID Incident
# rm -rf ./data/Incident\ Deaths/MOBS-GLEAM_COVID

# Remove UMass-ExpertCrowd
rm -rf ./data/Incident\ Deaths/UMass-ExpertCrowd
rm -rf ./data/Cumulative\ Deaths/UMass-ExpertCrowd

#Remove CU-nochange
rm -rf ./data/Incident\ Deaths/CU-nochange
rm -rf ./data/Cumulative\ Deaths/CU-nochange

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
npm run parse-viz-master # Parse visualization data to json
#yarn run test
cd .. # in flusight-deploy now
