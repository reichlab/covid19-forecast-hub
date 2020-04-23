## script for processing LANL data
## Nicholas Reich
## April 2020

library(tidyverse)

source("code/processing-fxns/process_lanl_file.R")

lanl_filenames <- list.files("data-raw/LANL", pattern=".csv", full.names=TRUE)
dates <- unlist(lapply(lanl_filenames, FUN = function(x) substr(basename(x), 0, 10)))
most_recent_date <- max(as.Date(dates))

cum_filename <- paste0("data-raw/LANL/", most_recent_date, "_deaths_quantiles_us.csv")
inc_filename <- paste0("data-raw/LANL/", most_recent_date, "_deaths_incidence_quantiles_us.csv")

cum_dat <- process_lanl_file(cum_filename)    
if(file.exists(inc_filename)){
    cum_dat <- bind_rows(cum_dat, process_lanl_file(inc_filename))
}    

write_csv(cum_dat, paste0("data-processed/LANL-GrowthRate/", most_recent_date, "-LANL-GrowthRate.csv"))

