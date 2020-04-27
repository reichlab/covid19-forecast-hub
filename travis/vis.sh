#!/usr/bin/env bash

set -e

# Script for building 
echo "> Building visualization"
cd ./visualization
bash ./0-init-flusight.sh
bash ./1-patch-flusight.sh
bash ./2-build-flusight.sh
cd .. # in repo root now