## script for processing LANL data
## Nicholas Reich
## April 2020

library(tidyverse)

source("code/process_lanl_file.R")

files_to_munge <- tibble(
    filenames=list.files("data-raw/LANL/", pattern="*deaths_quantiles_us.csv", ),
    timezeroes = c("2020-04-06", "2020-04-13", "2020-04-13")
)


for(i in 1:nrow(files_to_munge)) {
    tmp_dat <- process_lanl_file(file.path("data-raw/LANL/",files_to_munge$filenames[i]), timezero=files_to_munge$timezeroes[i])    
    write_csv(tmp_dat, paste0("data-processed/LANL-GrowthRate/", files_to_munge$timezeroes[i], "-LANL-GrowthRate.csv"))
}

