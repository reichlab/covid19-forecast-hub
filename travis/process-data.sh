#!/usr/bin/env bash

# process raw covid forecast for CU
Rscript ./code/processing-scripts/CU-processing-script.R
echo "PROCESS CU COMPLETE."

# process raw covid forecast for IHME
Rscript ./code/processing-scripts/IHME-processing.R
echo "PROCESS IHME COMPLETE."

# # process raw covid forecast for LANL
# Rscript ./data-raw/LANL/LANL-processing-script.R
# echo "PROCESS LANL COMPLETE."