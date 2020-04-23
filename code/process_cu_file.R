## CU death data functions
## Johannes Bracher
## April 2020

#' helper funtion to extract a date from a CU path name
#'
#' @param cu_filepath the path from which to extract the date
#' @param year the year (currently not contained in path names)

date_from_cu_filepath <- function(cu_filepath, year = 2020){
  as.Date(paste0(strsplit(strsplit(cu_filepath, "Projection_")[[1]][2],
                          "/", fixed = TRUE)[[1]][1], "/", year),
          format = "%B%d/%Y")
}

#' turn CU forecast file into quantile-based format
#'
#' @param cu_filepath path to a CU submission file
#' @param file the name of the file (CU forecast files are state_cdchosp_60contact.csv,
#' state_cdchosp_70contact.csv, state_cdchosp_80contact.csv, state_cdchosp_nointerv.csv)
#' @param forecast_date the time at which the forecast was issued; is internally compared
#'  to date indicated in file name
#'
#' @return a data.frame in quantile format

process_cu_file <- function(cu_filepath, file, forecast_date) {

  # extract CU forecast date from path:
  check_forecast_date <- date_from_cu_filepath(cu_filepath = cu_filepath)
  # plausibility check: does forecast_date agree with file name?
  if(is.na(check_forecast_date)){
    warning("forecast date could not be extracted from cu_filepath")
  }else{
    if(check_forecast_date != forecast_date) stop("forecast_date and date in file name differ.")
  }

  # get day of the week of forecast_date:
  day <- weekdays(forecast_date, abbreviate = TRUE)

  # read in data:
  dat <- read.csv(paste0(cu_filepath, "/cdc_hosp/", file),
                  stringsAsFactors = FALSE)
  # format date variable:
  dat$Date <- as.Date(dat$Date, format = "%m/%d/%y")
  # restrict to forecasts from forecast_date + 1 onwards
  dat <- subset(dat, Date > forecast_date)

  # identify columns with death forecasts:
  all_death_vars <- colnames(dat)[grepl(colnames(dat), pattern = "death")]
  c_death_vars <- colnames(dat)[grepl(colnames(dat), pattern = "cdeath")]
  i_death_vars <- setdiff(all_death_vars, c_death_vars)

  #####################################################
  # re-shape daily forecasts:

  # split into incident and cumulative, reshape each:
  # cumulative:
  c_dat <- dat[, c("location", "fips", "Date", c_death_vars)]
  c_dat <- reshape(c_dat, direction = "long", varying = list(c_death_vars),
                 times = c(1, 2.5, seq(from = 5, to = 95, by = 5), 97.5, 99)/100)
  c_dat$id <- NULL
  c_dat$target <- paste(c_dat$Date - forecast_date, "day ahead cum death")

  # incident:
  i_dat <- dat[, c("location", "fips", "Date", i_death_vars)]
  i_dat <- reshape(i_dat, direction = "long", varying = list(i_death_vars),
                   times = c(1, 2.5, seq(from = 5, to = 95, by = 5), 97.5, 99)/100)
  i_dat$id <- NULL
  i_dat$target <- paste(i_dat$Date - forecast_date, "day ahead inc death")

  # adapt columns and their names to template
  colnames(c_dat) <- colnames(i_dat) <- c("location_name", "location", "target_end_date",
                                          "quantile", "value", "target")

  ###################################################
  # add cumulative weekly forecasts:

  # When do the one-week-ahead forecast end?
  next_dates <- seq(from = forecast_date, length.out = 14, by = 1)
  next_days <- weekdays(next_dates, abbreviate = TRUE)
  if(day %in% c("Sun", "Mon")){
    forecast_1_wk_ahead_end <- next_dates[next_days == "Sat"][1]
  }else{
    forecast_1_wk_ahead_end <- next_dates[next_days == "Sat"][2]
  }
  ends_weekly_forecasts <- data.frame(end = seq(from = forecast_1_wk_ahead_end, by = 7, to = max(dat$Date)))
  ends_weekly_forecasts$target <- paste(1:nrow(ends_weekly_forecasts), "wk ahead cum death")

  # restrict to respective cumulative forecasts:
  c_weekly_dat <- dat[dat$Date %in% ends_weekly_forecasts$end, c("location", "fips", "Date", c_death_vars)]
  # reshape:
  c_weekly_dat <- reshape(c_weekly_dat, direction = "long", varying = list(c_death_vars),
                   times = c(1, 2.5, seq(from = 5, to = 95, by = 5), 97.5, 99)/100)
  c_weekly_dat$id <- NULL
  # merge target variable
  c_weekly_dat <- merge(c_weekly_dat, ends_weekly_forecasts, by.x = "Date", by.y = "end")
  # tidy up:
  colnames(c_weekly_dat) <- c("target_end_date", "location_name", "location",
                              "quantile", "value", "target")
  c_weekly_dat <- c_weekly_dat[, colnames(i_dat)]


  ###################################################
  # pool daily and weekly forecasts, add type and forecast_date:
  dat_quantiles <- rbind(i_dat, c_dat, c_weekly_dat)
  # add type variable (all quantiles until here):
  dat_quantiles$type <- "quantile"
  dat_quantiles$forecast_date <- forecast_date

  # add medians as point estimates:
  medians <- subset(dat_quantiles, quantile == 0.5)
  medians$type <- "point"
  medians$quantile <- NA
  # add to data:
  dat_quantiles <- rbind(dat_quantiles, medians)


  # re-order columns:
  dat_quantiles <- dat_quantiles[order(dat_quantiles$target, dat_quantiles$type),
             c("forecast_date", "target", "target_end_date", "location",
               "location_name", "type", "quantile", "value")]

  # format FIPS codes:
  dat_quantiles$location <- as.character(dat_quantiles$location)
  dat_quantiles$location[nchar(dat_quantiles$location) == 1] <-
    paste0("0", dat_quantiles$location[nchar(dat_quantiles$location) == 1])

  # format location_names:
  dat_quantiles$location_name[dat_quantiles$location_name == "US National"] <- "US"
  rownames(dat_quantiles) <- NULL

  return(dat_quantiles)
}
