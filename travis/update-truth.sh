#!/usr/bin/env bash

# update truth data
cd ./data-truth

# update zoltar truth
python3 ./zoltar-truth-data.py

# upload daily truth
python3 ./get-truth-data.py

# update nytimes and usa facts
cd ../
# Rscript ./data-truth/usafacts/usafacts.R
# Rscript ./data-truth/nytimes/nytimes.R