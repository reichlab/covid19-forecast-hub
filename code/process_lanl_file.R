## LANL cumulative death data functions
## Nicholas Reich
## April 2020


#' Calculate the date of the next Saturday
#'
#' @param date date for calculation
#'
#' @return a date of the subsequent Saturday. if date is a Saturday, it will return this day itself.
get_next_saturday <- function(date) {
    require(lubridate)
    date <- as.Date(date)
    ## calculate days until saturday (day 7)
    diff <- 7 - wday(date)
    ## add to given date
    new_date <- diff + date
    return(new_date)
}

#' turn LANL forecast file into quantile-based format
#'
#' @param lanl_filepath path to a lanl submission file
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
    
    ## read in data
    dat <- read_csv(lanl_filepath)
    forecast_date <- unique(dat$fcst_date)
    
    ## put into long format
    dat_long <- pivot_longer(dat, cols=starts_with("q."), names_to = "q", values_to = "cum_deaths") %>%
        filter(dates > forecast_date) %>%
        left_join(select(fips, -state), by=c("state" = "state_name")) %>%
        mutate(quantile = as.numeric(substr(q, 3, nchar(q)))/100, type="quantile") %>%
        select(state_code, state, type, quantile, cum_deaths, dates) %>%
        rename(
            location_id = state_code, 
            location_name = state, 
            value = cum_deaths)
    
    ## create tables corresponding to the days for each of the targets
    day_aheads <- tibble(target_id = paste(1:7, "day ahead cum"), dates = forecast_date+1:7)
    week_aheads <- tibble(target_id = paste(1:7, "wk ahead cum"), dates = get_next_saturday(forecast_date+seq(0, by=7, length.out = 7)))
    
    ## merge so targets are aligned with dates
    fcast_days <- inner_join(day_aheads, dat_long) %>% select(-dates)
    fcast_weeks <- inner_join(week_aheads, dat_long) %>% select(-dates)
    fcast_all <- bind_rows(fcast_days, fcast_weeks)
    
    ## make and merge point estimates as medians
    point_ests <- fcast_all %>% 
        filter(quantile==0.5) %>% 
        mutate(quantile=NA, type="point")
    
    all_dat <- bind_rows(fcast_all, point_ests) %>%
        arrange(type, target_id, quantile) %>%
        mutate(quantile = round(quantile, 3))
    
    return(all_dat)
}

