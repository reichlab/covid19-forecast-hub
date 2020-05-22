#!/usr/bin/env bash

# update truth data
cd ./data-truth

# update zoltar truth
python3 ./zoltar-truth-data.py

# upload daily truth
python3 ./get-truth-data