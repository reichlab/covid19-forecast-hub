## script for processing LANL data 
## Nicholas Reich, Jarad Niemi (US)
## April 2020

library(tidyverse)

source("process_lanl_file.R")
source("process_global_lanl_file.R")

lanl_filenames <- list.files(".", pattern=".csv", full.names=FALSE)
dates <- unlist(lapply(lanl_filenames, FUN = function(x) substr(basename(x), 0, 10)))
most_recent_date <- max(as.Date(dates))

cum_filename <- paste0(most_recent_date, "_deaths_quantiles_us_website.csv")
inc_filename <- paste0(most_recent_date, "_deaths_incidence_quantiles_us_website.csv")

cum_dat <- process_lanl_file(cum_filename) 

if(file.exists(inc_filename)) inc_dat <- process_lanl_file(inc_filename)

### 
us_cum_filename <- paste0(most_recent_date, "_deaths_quantiles_global_website.csv")
us_inc_filename <- paste0(most_recent_date, "_deaths_incidence_quantiles_global_website.csv")

us_cum <- process_global_lanl_file(us_cum_filename)
us_inc <- process_global_lanl_file(us_inc_filename)


write_csv(bind_rows(cum_dat, inc_dat, us_cum, us_inc), 
          paste0("../../data-processed/LANL-GrowthRate/", 
                          most_recent_date, 
                          "-LANL-GrowthRate.csv"))
