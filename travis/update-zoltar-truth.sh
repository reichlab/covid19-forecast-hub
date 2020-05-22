#!/usr/bin/env bash

# update truth data
python3 ./data-truth/zoltar-truth-data.py

# upload to zoltar
python3 ./code/zoltar-scripts/upload_truth_to_zoltar.py 