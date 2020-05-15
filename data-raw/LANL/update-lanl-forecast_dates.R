## the function below adds one day to the forecast date for a particular forecast file
## this will be used to 
##    1. merge the LANL-GrowthRateHosp files into a single LANL GrowthRate model
##    2. realign forecast dates to be one greater than the original dates reported by LANL

add_one_day_to_forecast_date <- function(filepath, return_obj=TRUE, ...) {
    require(tidyverse)
    ## assumes file is validated and that week-ahead targets don't change
    
    file_name <- basename(filepath)
    dir_name <- dirname(filepath)
    
    old_forecast_date <- as.Date(substr(file_name, 0, 10))
    old_file_basename <- substr(file_name, 11, nchar(file_name))
    new_forecast_date <- old_forecast_date + 1
    
    ## read in file and split into week ahead and daily targets
    dat <- read_csv(filepath, ...)
    dat_wk <- filter(dat, str_detect(target, 'wk ahead')) %>%
        mutate(forecast_date = forecast_date + 1)
    dat_day <- filter(dat, str_detect(target, 'day ahead'))
    
    ## adjust daily targets
    new_dat_day <- dat_day %>%
        filter(!str_detect(target, "1 day ahead")) %>%
        mutate(new_day = as.numeric(str_split(target, " ", n=2, simplify=TRUE)[,1])-1,
            new_target = str_split(target, " ", n=2, simplify=TRUE)[,2],
            target= paste(new_day, new_target),
            forecast_date = forecast_date+1) %>%
        select(-new_day, -new_target)
    
    ## remerge and save
    new_dat <- bind_rows(dat_wk, new_dat_day)
    
    if(return_obj){
        return(new_dat)
    } else {
        write_csv(new_dat, file.path(dir_name, paste(new_forecast_date, old_file_basename)))
    }    
}


#### merge GrowthRateHosp with other files

## 2020-05-06/07
lanl_0507 <- read_csv("data-processed/LANL-GrowthRate/2020-05-07-LANL-GrowthRate.csv", col_types = "DcDcccdd")
lanlhosp_0507 <- add_one_day_to_forecast_date("data-processed/LANL-GrowthRateHosp/2020-05-06-LANL-GrowthRateHosp.csv")

new_lanl_0507 <- bind_rows(lanl_0507, lanlhosp_0507)
write_csv(new_lanl_0507, "data-processed/LANL-GrowthRate/2020-05-07-LANL-GrowthRate.csv")

## 2020-05-03/04
lanl_0504 <- add_one_day_to_forecast_date("data-processed/LANL-GrowthRate/2020-05-03-LANL-GrowthRate.csv", col_types = "DcDcccdd")
lanlhosp_0504 <- read_csv("data-processed/LANL-GrowthRateHosp/2020-05-04-LANL-GrowthRateHosp.csv")

new_lanl_0504 <- bind_rows(lanl_0504, lanlhosp_0504)
write_csv(new_lanl_0504, "data-processed/LANL-GrowthRate/2020-05-04-LANL-GrowthRate.csv")

#### update all other LANL files
forecast_dates <- c(seq.Date(as.Date("2020-04-05"), by="7 days", length.out=4),
    seq.Date(as.Date("2020-04-08"), by="7 days", length.out=4))
files_to_update <- paste0("data-processed/LANL-GrowthRate/", forecast_dates, "-LANL-GrowthRate.csv")
for(ff in files_to_update){
    add_one_day_to_forecast_date(ff, return=FALSE, col_types = "DcDcccdd")
}
