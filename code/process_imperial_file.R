## functions for Imperial data

source("./code/get_next_saturday.R")

#' Transform matrix of samples for one location into a quantile-format data_frame
#'
#' @param sample_mat matrix of samples, columns are horizons, rows are samples
#' @param location_id the FIPS code for the location for this matrix
#' @param timezero date of official forecast collection
#' @param qntls set of quantiles for which forecasts will be computed, defaults to c(0.025, 0.1, 0.2, .5, 0.8, .9, 0.975)
#'
#' @return long-format data_frame with quantiles
#' 
#' @details Assumes that the matrix gives 1 through 7 day ahead forecasts
#'
process_imperial_file <- function(sample_mat, location_id, timezero, qntls=c(0.01, 0.025, seq(0.05, 0.95, by=0.05), 0.975, 0.99)) {
    require(tidyverse)
    cols_to_include <- paste(1:7, "day ahead inc")
    
    fcast_dates <- read_csv("template/covid19-death-forecast-dates.csv")
    
    ## create tables corresponding to the days for each of the targets
    day_aheads <- tibble(target_id = paste(1:7, "day ahead inc"), dates = timezero+1:7)
    week_aheads <- tibble(target_id = "1 wk ahead inc", dates = get_next_saturday(timezero))
    
    
    ## choosing quantile type=1 b/c more compatible with discrete samples
    ## other choices gave decimal answers
    qntl_dat <- apply(sample_mat, FUN=function(x) quantile(x, qntls, type=1), MAR=2) 
    colnames(qntl_dat) <- cols_to_include
    
    qntl_dat_long <- as_tibble(qntl_dat) %>%
        mutate(location_id=location_id, quantile = qntls, type="quantile") %>%
        pivot_longer(cols=cols_to_include, names_to = "target_id") 
    
    point_ests <- qntl_dat_long %>% 
        filter(quantile==0.5) %>% 
        mutate(quantile=NA, type="point")
    
    all_dat <- bind_rows(qntl_dat_long, point_ests) %>%
        arrange(type, target_id, quantile) %>%
        mutate(quantile = round(quantile, 3))
    
    return(all_dat)
}

