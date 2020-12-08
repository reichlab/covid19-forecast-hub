#!/usr/bin/env bash

# This script install the covidData package, download the raw truth from JHU
# preprocess the raw truths into standard csv files used by many functionalities in covid-hub-forecast.

# Install covidData
# Note: this might just need to be done only once when we move towards VM platform
git clone https://github.com/reichlab/covidData.git
cd ./covidData/data-raw/
mkdir "JHU"
cd ../code/data-processing
python3 download-historical-jhu.py
Rscript assemble-historical-jhu.R
cd ../../../
R CMD INSTALL covidData

# Install covidHubUtils
# Note: this might just need to be done only once when we move towards VM platform
Rscript -e "install.packages('remotes', repos = 'http://cran.us.r-project.org')"
Rscript -e "remotes::install_github('reichlab/covidHubUtils')"

# Loading packages and preprocess raw truth into standard csv file
# Default save location is "./data-truth"
Rscript -e "library(covidHubUtils);covidHubUtils::preprocess_jhu()"
