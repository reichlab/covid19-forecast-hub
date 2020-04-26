#!/usr/bin/env bash

# Automating pulling of data
python3 ./code/automate-download/auto-download-ihme-covid19.py ./data-raw/IHME/
python3 code/automate-download/auto-download-lanl-covid19.py $pwd/data-raw/LANL/