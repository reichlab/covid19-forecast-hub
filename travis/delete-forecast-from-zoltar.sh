#!/usr/bin/env bash

# Automate upload all new forecast to Zoltar
python3 ./code/zoltar_scripts/remove_covid19_forecasts_from_zoltar.py
echo "DELETE EXTRA FORECASTS FROM ZOLTAR SUCCESSFUL"