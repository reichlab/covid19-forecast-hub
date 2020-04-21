## LANL cumulative death data functions
## Nicholas Reich
## April 2020

source("code/get_next_saturday.R")

#' turn LANL forecast file into quantile-based format
#'
#' @param lanl_filepath path to a lanl submission file
#'
#' @details typically timezero will be a monday and the 1-week ahead 
#' forecast will be for the EW of the Monday. 1-day-ahead would be Tuesday.
#'
#' @return a data.frame in quantile format
process_lanl_file <- function(lanl_filepath) {
    require(tidyverse)
    require(MMWRweek)
    require(lubridate)
    ## check this is a deaths file
    if(substr(basename(lanl_filepath), 12, 17) != "deaths")
        stop("check to make sure this is a deaths file")
    
    ## read in FIPS codes
    fips <- read_csv("template/state_fips_codes.csv")
    
    ## read in forecast dates
    fcast_dates <- read_csv("template/covid19-death-forecast-dates.csv")
    timezero <- as.Date(substr(basename(lanl_filepath), 0, 10))
    
    ## read in data
    dat <- read_csv(lanl_filepath)
    forecast_date <- unique(dat$fcst_date)
    
    if(forecast_date != timezero)
        stop("timezero in the filename is not equal to the forecast date in the data")
    
    ## make USVI adjustment
    usvi_idx <- which(dat$state=="Virgin Islands")
    dat[usvi_idx, "state"] <- rep("U.S. Virgin Islands")
    
    ## put into long format
    dat_long <- pivot_longer(dat, cols=starts_with("q."), names_to = "q", values_to = "cum_deaths") %>%
        filter(dates > forecast_date) %>%
        left_join(select(fips, -state), by=c("state" = "state_name")) %>%
        mutate(quantile = as.numeric(sub("q", "0", q)), type="quantile") %>%
        select(state_code, state, type, quantile, cum_deaths, dates) %>%
        rename(
            location = state_code, 
            location_name = state, 
            value = cum_deaths)
    
    ## create tables corresponding to the days for each of the targets
    day_aheads <- tibble(target = paste(1:7, "day ahead cum death"), dates = timezero+1:7)
    if(wday(timezero) <= 2 ) { ## sunday = 1, ..., saturday = 7
        ## if timezero is Sun or Mon, then the current epiweek ending on Saturday is the "1 week-ahead"
        week_aheads <- tibble(target = paste(1:7, "wk ahead cum death"), dates = get_next_saturday(timezero+seq(0, by=7, length.out = 7)))
    } else {
        ## if timezero is after Monday, then the next epiweek is "1 week-ahead"
        week_aheads <- tibble(target = paste(0:7, "wk ahead cum death"), dates = get_next_saturday(timezero+seq(0, by=7, length.out = 8)))
    }
    
    ## merge so targets are aligned with dates
    fcast_days <- inner_join(day_aheads, dat_long) 
    fcast_weeks <- inner_join(week_aheads, dat_long)
    fcast_all <- bind_rows(fcast_days, fcast_weeks) %>%
        rename(target_end_date = dates) %>%
        mutate(forecast_date = forecast_date)
    
    ## make and merge point estimates as medians
    point_ests <- fcast_all %>% 
        filter(quantile==0.5) %>% 
        mutate(quantile=NA, type="point")
    
    all_dat <- bind_rows(fcast_all, point_ests) %>%
        arrange(type, target, quantile) %>%
        mutate(quantile = round(quantile, 3)) %>%
        ## making sure ordering is right :-)
        select(forecast_date, target, target_end_date, location, location_name, type, quantile, value)
    
    return(all_dat)
}

