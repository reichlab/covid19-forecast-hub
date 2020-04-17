## Geneva death data functions
## Johannes Bracher
## April 2020

#' turn Geneva forecast file into quantile-based format
#'
#' @param geneva_filepath path to a Geneva submission file
#' @param file the name of the file
#' @param timezero the origin date for the forecast
#'
#' @details typically timezero will be a Monday and the 1-week ahead
#' forecast will be for the EW of the Monday. 1-day-ahead would be Tuesday.
#'
#' @return a data.frame in quantile format

process_geneva_file <- function(geneva_filepath, timezero){

  timezero <- as.Date(timezero)
  # extract Geneva forecast date from path:
  forecast_date <- as.Date(gsub(".csv", "", gsub("predictions_deaths_", "", geneva_filepath)))

  # plausibility check: is forecast date before timezero, but not too much?
  if(is.na(forecast_date)){
    warning("forecast date could not be extracted from geneva_filepath")
  }else{
    if(timezero != forecast_date) warning("Geneva forecasts are usually issued every day. Is a forecast from day timezero availalble?")
    if(forecast_date > timezero) stop("timezero is before the forecast date")
  }

  dat <- read.csv(paste0("data-raw/Geneva/", geneva_filepath))

  # restrict to US, format:
  dat <- subset(dat, country == "United States of America" & observed == "Predicted")
  dat$date <- as.Date(dat$date)
  dat <- subset(dat, date > timezero) # restrict to timepoints after collection date
  dat$location <- dat$location_name <- "US"
  dat$country <- NULL
  dat$X <- dat$observed <- NULL

  # transform to wide format, tidy up:
  dat_wide <- reshape(dat, direction = "long", varying = list(c("per.day", "cumulative")),
                 times = c("day ahead inc death", "days ahead cum death"))
  dat_wide$id <- NULL
  rownames(dat_wide) <- NULL

  # get forecast horizons:
  dat_wide$horizon <- as.numeric(dat_wide$date - timezero)
  dat_wide$target <- paste(dat_wide$horizon, dat_wide$time)

  # remove unneeded columns
  dat_wide$date <- dat_wide$time <- dat_wide$horizon <- NULL

  # add required ones:
  dat_wide$quantile <- NA
  dat_wide$type = "point"

  # adapt colnames and order
  colnames(dat_wide)[colnames(dat_wide) == "per.day"] <- "value"
  dat_wide <- dat_wide[, c("target", "location", "location_name", "type", "quantile", "value")]

  return(dat_wide)
}
