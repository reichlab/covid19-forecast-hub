## LANL cumulative death data functions
## Nicholas Reich
## April 2020


#' turn LANL forecast file into quantile-based format
#'
#' @param lanl_filepath path to a lanl submission file
#' @param timezero the origin date for the forecast
#'
#' @details typically timezero will be a monday and the 1-week ahead 
#' forecast will be for the EW of the Monday. 1-day-ahead would be Tuesday.
#'
#' @return a data.frame in quantile format
process_lanl_file <- function(lanl_filepath, timezero) {
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
    timezero <- as.Date(timezero)
    
    ## read in data
    dat <- read_csv(lanl_filepath)
    forecast_date <- unique(dat$fcst_date)
    
    diff_in_fcast_dates <- timezero - forecast_date 
    if(diff_in_fcast_dates<0)
        stop("timezero is before the forecast date")
    
    ## put into long format
    dat_long <- pivot_longer(dat, cols=starts_with("q."), names_to = "q", values_to = "cum_deaths") %>%
        filter(dates > forecast_date) %>%
        left_join(select(fips, -state), by=c("state" = "state_name")) %>%
        mutate(quantile = as.numeric(sub("q", "0", q)), type="quantile") %>%
        select(state_code, state, type, quantile, cum_deaths, dates) %>%
        rename(
            location_id = state_code, 
            location_name = state, 
            value = cum_deaths)
    
    ## create tables corresponding to the days for each of the targets
    day_aheads <- tibble(target_id = paste(1:7, "day ahead cum"), dates = timezero+1:7)
    week_aheads <- tibble(target_id = paste(1:7, "wk ahead cum"), dates = get_next_saturday(timezero+seq(0, by=7, length.out = 7)))
    
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

