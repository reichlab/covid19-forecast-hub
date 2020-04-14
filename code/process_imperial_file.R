## functions for Imperial data

source("./code/get_next_saturday.R")

#' Transform matrix of samples for one location into a quantile-format data_frame
#'
#' @param sample_mat matrix of samples, columns are horizons, rows are samples
#' @param location the FIPS code for the location for this matrix
#' @param timezero date of official forecast collection
#' @param qntls set of quantiles for which forecasts will be computed, defaults to c(0.025, 0.1, 0.2, .5, 0.8, .9, 0.975)
#'
#' @return long-format data_frame with quantiles
#' 
#' @details Assumes that the matrix gives 1 through 7 day ahead forecasts
#'
process_imperial_file <- function(sample_mat, location, timezero, qntls=c(0.01, 0.025, seq(0.05, 0.95, by=0.05), 0.975, 0.99)) {
    require(tidyverse)
    
    fcast_dates <- read_csv("template/covid19-death-forecast-dates.csv")
    
    ## create tables corresponding to the days for each of the targets
    day_aheads <- tibble(target = paste(1:7, "day ahead inc"), dates = timezero+1:7)
    week_aheads <- tibble(target = "1 wk ahead inc", dates = get_next_saturday(timezero))
    
    which_days <- which(colnames(sample_mat) %in% as.character(day_aheads$dates))
    which_weeks <- which(colnames(sample_mat) %in% as.character(week_aheads$dates))
    samples_daily <- sample_mat[,which_days]
    samples_weekly <- sample_mat[,which_weeks]
    
    ## choosing quantile type=1 b/c more compatible with discrete samples
    ## other choices gave decimal answers
    qntl_daily <- apply(samples_daily, FUN=function(x) quantile(x, qntls, type=1), MAR=2) 
    colnames(qntl_daily) <- day_aheads$target[which(day_aheads$dates %in% as.Date(colnames(qntl_daily)))]
    qntl_daily_long <- as_tibble(qntl_daily) %>%
        mutate(location=location, quantile = qntls, type="quantile") %>%
        pivot_longer(cols=contains("day ahead"), names_to = "target") 
    
    if(is.null(dim(samples_weekly))){
        ## if only one week
        qntl_weekly <- enframe(quantile(samples_weekly, qntls, type=1)) %>% select(value)
        colnames(qntl_weekly) <- "1 wk ahead inc"
        qntl_weekly_long <- qntl_weekly %>%
            mutate(location=location, quantile = qntls, type="quantile") %>%
            pivot_longer(cols=contains("wk ahead"), names_to = "target") 
    } else { 
        ## if there are more than 1 weeks
        qntl_weekly <- apply(samples_weekly, FUN=function(x) quantile(x, qntls, type=1), MAR=2) 
        colnames(qntl_weekly) <- week_aheads$target[which(week_aheads$dates %in% as.Date(colnames(qntl_weekly)))]
        qntl_weekly_long <- as_tibble(qntl_weekly) %>%
            mutate(location=location, quantile = qntls, type="quantile") %>%
            pivot_longer(cols=contains("wk ahead"), names_to = "target") 
        
    }
    
    qntl_dat_long <- bind_rows(qntl_daily_long, qntl_weekly_long)    
        
    point_ests <- qntl_dat_long %>% 
        filter(quantile==0.5) %>% 
        mutate(quantile=NA, type="point")
    
    all_dat <- bind_rows(qntl_dat_long, point_ests) %>%
        arrange(type, target, quantile) %>%
        mutate(quantile = round(quantile, 3))
    
    return(all_dat)
}

