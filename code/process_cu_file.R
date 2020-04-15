## CU incident death data functions
## Johannes Bracher
## April 2020

#' turn CU forecast file into quantile-based format
#'
#' @param cu_filepath path to a cu submission file
#' @param file the name of the file (CU forecast files are state_cdchosp_60contact.csv,
#' state_cdchosp_70contact.csv, state_cdchosp_80contact.csv, state_cdchosp_nointerv.csv)
#' @param timezero the origin date for the forecast
#'
#' @details typically timezero will be a Monday and the 1-week ahead
#' forecast will be for the EW of the Monday. 1-day-ahead would be Tuesday.
#'
#' @return a data.frame in quantile format

process_cu_file <- function(cu_filepath, file, timezero) {

  timezero <- as.Date(timezero)

  # extract CU forecast date from path:
  forecast_date <- as.Date(paste0(strsplit(strsplit(cu_filepath, "Projection_")[[1]][2],
                                           "/", fixed = TRUE)[[1]][1], "/2020"),
                           format = "%B%d/%Y")
  # plausibility check: is forecast date before timezero, but not too much?
  if(is.na(forecast_date)){
    warning("forecast date could not be extracted from cu_filepath")
  }else{
    if(timezero - forecast_date > 7) stop("Forecasts are more thn one week old")
    if(forecast_date > timezero) stop("timezero is before the forecast date")
  }

  # read in data:
  dat <- read.csv(paste0(cu_filepath, "/", file),
                  stringsAsFactors = FALSE)

  # format date variable:
  dat$Date <- as.Date(dat$Date, format = "%m/%d/%y")

  # restrict to timepoints after time of collection:
  dat <- subset(dat, Date > timezero)

  # identify columns with death forecasts:
  all_death_vars <- colnames(dat)[grepl(colnames(dat), pattern = "death")]
  c_death_vars <- colnames(dat)[grepl(colnames(dat), pattern = "cdeath")]
  i_death_vars <- setdiff(all_death_vars, c_death_vars)

  # split into incident and cumulative, reshape each:
  # cumulative:
  c_dat <- dat[, c("location", "fips", "Date", c_death_vars)]
  c_dat <- reshape(c_dat, direction = "long", varying = list(c_death_vars),
                 times = c(1, 2.5, seq(from = 5, to = 95, by = 5), 97.5, 99)/100)
  c_dat$id <- NULL
  c_dat$target <- paste(c_dat$Date - timezero, "day ahead cum")

  # incident:
  i_dat <- dat[, c("location", "fips", "Date", i_death_vars)]
  i_dat <- reshape(i_dat, direction = "long", varying = list(i_death_vars),
                   times = c(1, 2.5, seq(from = 5, to = 95, by = 5), 97.5, 99)/100)
  i_dat$id <- NULL
  i_dat$target <- paste(i_dat$Date - timezero, "day ahead inc")

  # adapt columns and their names to template
  colnames(c_dat) <- colnames(i_dat) <- c("location_name", "location", "date",
                                          "quantile", "value", "target")

  # put together and tidy up:
  dat <- rbind(c_dat, i_dat)
  dat$date <- NULL

  # add type variable (all quantiles until here):
  dat$type <- "quantile"

  # add medians as point estimates:
  medians <- subset(dat, quantile == 0.5)
  medians$type <- "point"
  medians$quantile <- NA

  # add to data:
  dat <- rbind(dat, medians)
  rownames(dat) <- NULL

  # re-order:
  dat <- dat[order(dat$target, dat$type),
             c("location", "location_name", "target", "type", "quantile", "value")]

  return(dat)
}