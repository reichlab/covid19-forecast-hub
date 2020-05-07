stop("Moved from code/validation/processing-scripts/. Needs to be updated.")

## NEU processing
## one-off updates for 4/13 file.

library(tidyverse)
library(lubridate)

source("code/processing-fxns/get_next_saturday.R")


mobs_filenames <- list.files("data-raw/MOBS", pattern=".csv", full.names=TRUE)

dates <- unlist(lapply(mobs_filenames, FUN = function(x) substr(basename(x), 0, 10)))

most_recent_file_idx <- which(as.Date(dates)==max(as.Date(dates)))

mobs_filename <- mobs_filenames[most_recent_file_idx]

forecast_date <- as.Date(substr(basename(mobs_filename), 0, 10))
    
dat <- read_csv(mobs_filename) %>%
    ## rename(target=target_id, location=location_id) %>% ## only needed for 4/13
    mutate(forecast_date = forecast_date,
        location = str_pad(as.character(location), width = 2, side = "left", pad = "0"),
        target = paste(target, "death"))

US_loc_idx <- which(dat$location=="00")
dat$location[US_loc_idx] <- "US"

dat$target <- sub("week", "wk", dat$target)
dat$target <- sub("death death", "death", dat$target)

## add target_end_dates
day_aheads <- tibble(
    target = c(paste(1:7, "day ahead cum death"), paste(1:7, "day ahead inc death")), 
    target_end_date = rep(forecast_date+1:7, times=2))
if(wday(forecast_date) <= 2 ) { ## sunday = 1, ..., saturday = 7
    ## if timezero is Sun or Mon, then the current epiweek ending on Saturday is the "1 week-ahead"
    week_aheads <- tibble(
        target = c(paste(1:7, "wk ahead cum death"), paste(1:7, "wk ahead inc death")), 
        target_end_date = rep(get_next_saturday(forecast_date+seq(0, by=7, length.out = 7)), times=2)
        )
} else {
    ## if timezero is after Monday, then the next epiweek is "1 week-ahead"
    week_aheads <- tibble(
        target = c(paste(0:7, "wk ahead cum death"), paste(0:7, "wk ahead inc death")), 
        target_end_date = rep(get_next_saturday(forecast_date+seq(0, by=7, length.out = 8)), times=2)
        )
}

joined_dat <- inner_join(bind_rows(day_aheads, week_aheads), dat) 


point_ests <- joined_dat %>% 
    filter(quantile==0.5) %>% 
    mutate(quantile=NA, type="point")

all_dat <- bind_rows(joined_dat, point_ests) %>%
    arrange(type, target, quantile) %>%
    select(forecast_date, target, target_end_date, location, location_name, type, quantile, value)


write_csv(all_dat, paste0("data-processed/MOBS_NEU-GLEAM_COVID/", dates[most_recent_file_idx],"-MOBS_NEU-GLEAM_COVID.csv"))

