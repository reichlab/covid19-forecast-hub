#!/usr/bin/env bash

# update truth data
cd ./visualization
python3 ./scripts/zoltar-truth-data.py

# upload to zoltar
cd ../
python3 ./code/zoltar-scripts/upload_truth_to_zoltar.py 