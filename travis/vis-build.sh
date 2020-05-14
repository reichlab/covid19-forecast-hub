#!/usr/bin/env bash

set -e

# Script for building 
echo "> Building visualization"
cd ./visualization
bash ./one-time-setup.sh
bash ./0-init-vis.sh
bash ./1-patch-vis.sh
bash ./2-build-vis.sh
cd .. # in repo root now

