## script for processing LANL data
## Nicholas Reich
## April 2020

library(tidyverse)

source("code/process_lanl_file.R")

files_to_munge <- tibble(
    filenames_cum=list.files("data-raw/LANL/", pattern="*deaths_quantiles_us.csv"),
    ##filenames_inc=list.files("data-raw/LANL/", pattern="*deaths_incidence_quantiles_us.csv"),
    timezeroes = substr(filenames_cum, 0, 10)
)


for(i in 1:nrow(files_to_munge)) {
    tmp_dat <- process_lanl_file(file.path("data-raw/LANL/",files_to_munge$filenames_cum[i]))    
    write_csv(tmp_dat, paste0("data-processed/LANL-GrowthRate/", files_to_munge$timezeroes[i], "-LANL-GrowthRate.csv"))
}

