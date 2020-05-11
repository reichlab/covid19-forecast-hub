#!/usr/bin/env bash

# validate file names
echo "TESTING FILENAMES..."
Rscript code/validation/validate_filenames.R

# test covid forecast submission formatting
echo "TESTING SUBMISSIONS..."
python3 code/validation/test-formatting.py