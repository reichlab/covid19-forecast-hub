## LANL cumulative death data functions
## Nicholas Reich, Jarad Niemi
## April 2020

source("../../code/processing-fxns/get_next_saturday.R")

#' turn LANL forecast file into quantile-based format
#'
#' @param lanl_filepath path to a lanl submission file
#'
#' @details designed to process either an incidence or cumulative death forecast
#'
#' @return a data.frame in quantile format
process_global_lanl_file <- function(lanl_filepath, 
                              forecast_dates_file = "../../template/covid19-death-forecast-dates.csv") {
    require(tidyverse)
    require(MMWRweek)
    require(lubridate)
  
    if(!grepl("deaths", lanl_filepath)) 
      stop("check to make sure this is a deaths file")

    ## check this is an incident deaths file or not
    inc_or_cum <- ifelse(grepl("incidence", basename(lanl_filepath)),
        "inc", "cum")
    
    ## read in forecast dates
    fcast_dates <- read_csv(forecast_dates_file)
    timezero <- as.Date(substr(basename(lanl_filepath), 0, 10))
    
    ## read in data
    dat <- read_csv(lanl_filepath)
    forecast_date <- unique(dat$fcst_date)
    
    if(forecast_date != timezero)
        stop("timezero in the filename is not equal to the forecast date in the data")
    
    
    ## put into long format
    dat_long <- tidyr::pivot_longer(dat, cols=starts_with("q."), 
                             names_to = "q", 
                             values_to = "cum_deaths") %>%
        dplyr::filter(dates > forecast_date, countries == "US") %>%
        dplyr::mutate(quantile = as.numeric(sub("q", "0", q)), type="quantile") %>%
        dplyr::select(countries, type, quantile, cum_deaths, dates) %>%
        dplyr::rename(
            location = countries, 
            value = cum_deaths,
            target_end_date = dates)
    
    ## create tables corresponding to the days for each of the targets
    n_day_aheads <- length(unique(dat_long$target_end_date))
    n_week_aheads <- sum(wday(unique(dat_long$target_end_date))==7)
        
    day_aheads <- tibble(
        target = paste(1:n_day_aheads, "day ahead", inc_or_cum, "death"), 
        target_end_date = forecast_date+1:n_day_aheads)

    ## merge so targets are aligned with dates
    fcast_days <- inner_join(day_aheads, dat_long) 
    fcast_all <- fcast_days %>% ## this will be overwritten if cumulative file.
        mutate(forecast_date = forecast_date)
    
    ## only do week-ahead for cumulative counts
    if(inc_or_cum == "cum") {
        if(wday(forecast_date) <= 2 ) { ## sunday = 1, ..., saturday = 7
            ## if timezero is Sun or Mon, then the current epiweek ending on Saturday is the "1 week-ahead"
            week_aheads <- tibble(
                target = paste(1:n_week_aheads, "wk ahead cum death"),
                target_end_date = get_next_saturday(forecast_date+seq(0, by=7, length.out = n_week_aheads))
            )
        } else {
            ## if timezero is after Monday, then the next epiweek is "1 week-ahead"
            week_aheads <- tibble(
                target = paste(1:n_week_aheads, "wk ahead cum death"), 
                target_end_date = get_next_saturday(forecast_date+seq(7, by=7, length.out = n_week_aheads))
            )
        }
        
        ## merge so targets are aligned with dates
        fcast_weeks <- inner_join(week_aheads, dat_long)
        fcast_all <- bind_rows(fcast_days, fcast_weeks) %>%
            mutate(forecast_date = forecast_date)
    }
    
    
    ## make and merge point estimates as medians
    point_ests <- fcast_all %>% 
        filter(quantile==0.5) %>% 
        mutate(quantile=NA, type="point")
    
    all_dat <- bind_rows(fcast_all, point_ests) %>%
        arrange(type, target, quantile) %>%
        mutate(quantile = round(quantile, 3)) %>%
        ## making sure ordering is right :-)
        select(forecast_date, target, target_end_date, location, type, quantile, value)
    
    return(all_dat)
}

