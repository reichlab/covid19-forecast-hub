#!/usr/bin/env bash
Rscript -e 'install.packages(c("readr"), repos="http://cran.us.r-project.org")'

# update truth data
cd ./data-truth

# update zoltar truth
python3 ./zoltar-truth-data.py

# upload daily truth
python3 ./get-truth-data.py

# update nytimes and usa facts
cd ./usafacts
Rscript ./usafacts.R
cd ../nytimes
Rscript ./nytimes.R
cd ../../