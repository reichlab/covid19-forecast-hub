## script for processing LANL data
## Nicholas Reich
## April 2020

library(tidyverse)

source("code/process_lanl_file.R")

files_to_munge <- list.files("data-raw/LANL/", pattern="*deaths_quantiles_us.csv", )

for(i in 1:length(files_to_munge)) {
    forecast_date <- substr(basename(files_to_munge[i]), 0, 10)
    tmp_dat <- process_lanl_file(file.path("data-raw/LANL/",files_to_munge[i]))    
    write_csv(tmp_dat, paste0("data-processed/LANL-GrowthRate/", forecast_date, "-LANL-GrowthRate.csv"))
}

