## Geneva death data functions
## Johannes Bracher
## April 2020

#' helper funtion to extract a date from a CU path name
#'
#' @param geneva_filepath the path from which to extract the date
#'
#' @return an object of class date

date_from_geneva_filepath <- function(geneva_filepath){
  as.Date(gsub(".csv", "", gsub("predictions_deaths_", "", geneva_filepath)))
}

#' turn Geneva forecast file into quantile-based format
#'
#' @param geneva_filepath path to a Geneva submission file
#' @param forecast_date the time at which the forecast was issued; is internally compared
#'  to date indicated in file name
#'
#' @details typically timezero will be a Monday and the 1-week ahead
#' forecast will be for the EW of the Monday. 1-day-ahead would be Tuesday.
#'
#' @return a data.frame in quantile format

process_geneva_file <- function(geneva_filepath, forecast_date){

  # extract Geneva forecast date from path:
  check_forecast_date <- date_from_geneva_filepath(geneva_filepath)
  # plausibility check: does forecast_date agree with file name?
  if(is.na(check_forecast_date)){
    warning("forecast date could not be extracted from geneva_filepath")
  }else{
    if(check_forecast_date != forecast_date) stop("forecast_date and date in file name differ.")
  }

  dat <- read.csv(geneva_filepath)

  # restrict to US, format:
  dat <- subset(dat, country == "United States of America" & observed == "Predicted")
  dat$date <- as.Date(dat$date)
  dat <- subset(dat, date > forecast_date) # restrict to timepoints after forecast date
  dat$location <- dat$location_name <- "US"
  dat$country <- NULL
  dat$X <- dat$observed <- NULL

  # transform to wide format, tidy up:
  daily_dat <- reshape(dat, direction = "long", varying = list(c("per.day", "cumulative")),
                 times = c("day ahead inc death", "day ahead cum death"))
  daily_dat$id <- NULL
  rownames(daily_dat) <- NULL

  # get forecast horizons:
  daily_dat$horizon <- as.numeric(daily_dat$date - forecast_date)
  daily_dat$target <- paste(daily_dat$horizon, daily_dat$time)

  # remove unneeded columns
  daily_dat$time <- daily_dat$horizon <- NULL

  # add required ones:
  daily_dat$quantile <- NA
  daily_dat$type = "point"
  daily_dat$forecast_date <- forecast_date

  # adapt colnames and order
  colnames(daily_dat)[colnames(daily_dat) == "per.day"] <- "value"
  colnames(daily_dat)[colnames(daily_dat) == "date"] <- "target_end_date"
  daily_dat <- daily_dat[, c("forecast_date", "target", "target_end_date", "location",
                           "location_name", "type", "quantile", "value")]

  # add one-week-ahead cumulative forecast if possible:
  # get day of the week of forecast_date:
  day <- weekdays(forecast_date, abbreviate = TRUE)

  # When do the one-week-ahead forecast end?
  next_dates <- seq(from = forecast_date, length.out = 14, by = 1)
  next_days <- weekdays(next_dates, abbreviate = TRUE)
  if(day %in% c("Sun", "Mon")){
    forecast_1_wk_ahead_end <- next_dates[next_days == "Sat"][1]
  }else{
    forecast_1_wk_ahead_end <- next_dates[next_days == "Sat"][2]
  }
  # Whether the one-week-ahead forecast can be computed depends on the day
  # the forecasts were issued:
  if(max(daily_dat$target_end_date) > forecast_1_wk_ahead_end){
    ends_weekly_forecasts <- data.frame(end = seq(from = forecast_1_wk_ahead_end,
                                                  by = 7, to = max(daily_dat$target_end_date)))
    ends_weekly_forecasts$target <- paste(1:nrow(ends_weekly_forecasts), "wk ahead cum death")
    # restrict to respective cumulative forecasts:
    weekly_dat <- subset(daily_dat, target_end_date %in% ends_weekly_forecasts$end &
                           grepl("cum", daily_dat$target))
    weekly_dat$target <- NULL
    weekly_dat <- merge(weekly_dat, ends_weekly_forecasts, by.x = "target_end_date", by.y = "end")
    weekly_dat <- weekly_dat[, colnames(daily_dat)]

    daily_dat <- rbind(daily_dat, weekly_dat)
  }

  return(daily_dat)
}
