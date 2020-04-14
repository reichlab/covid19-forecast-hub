## CU incident death data functions
## Johannes Bracher
## April 2020

#' turn CU forecast file into quantile-based format
#'
#' NOTE: only extracts incident deaths, will need to be adapted once cumulative deaths become available
#'
#' @param cu_filepath path to a cu submission file
#' @param file the name of the file (CU forecast files are bed_60contact.csv,
#' bed_70contact.csv, bed_80contact.csv, bed_nointerv.csv)
#' @param timezero the origin date for the forecast
#' @param exclude_counties should county-level forecasts be excluded and only state
#'  and national forecasts kept? Defaults to TRUE
#'
#' @details typically timezero will be a monday and the 1-week ahead
#' forecast will be for the EW of the Monday. 1-day-ahead would be Tuesday.
#'
#' @return a data.frame in quantile format

process_cu_file <- function(cu_filepath, file, timezero, exclude_counties = TRUE) {

  timezero <- as.Date(timezero)

  # extract forecast date from path:
  forecast_date <- as.Date(paste0(strsplit(strsplit(cu_filepath, "Projection_")[[1]][2],
                                           "/", fixed = TRUE)[[1]][1], "/2020"),
                           format = "%B%d/%Y")
  # plausibility check:
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

  # get rid of unnecessary columns:
  death_vars <- colnames(dat)[grepl(colnames(dat), pattern = "death")]
  dat <- dat[, c("location", "fips", "Date", death_vars)]

  # restrict to state and national-level forecasts
  if(exclude_counties){
    dat <- subset(dat, nchar(fips) < 3)
  }


  dat <- reshape(dat, direction = "long", varying = list(death_vars), times = c(2.5, 25, 50, 75, 97.5))
  # adapt columns and their names to template
  dat$id <- NULL
  colnames(dat) <- c("location_name", "location_id", "date", "quantile", "value")
  rownames(dat) <- NULL
  dat$type <- "quantile"


  # bring quantiles to unit interval
  dat$quantile <- dat$quantile/100

  # restrict to timepoints after time of collection:
  dat <- subset(dat, date > timezero)

  # create target variable:
  # !!! This will need to be adapted when cumulative deaths become available
  dat$target_id <- paste(dat$date - timezero, "day ahead inc")

  # remove date variable:
  dat$date <- NULL

  # add medians as point estimates:
  medians <- subset(dat, quantile == 0.5)
  medians$type <- "point"
  medians$quantile <- NA

  # add to data:
  dat <- rbind(dat, medians)
  # re-order:
  dat <- dat[order(dat$target_id, dat$type),
             c("location_id", "location_name", "target_id", "type", "quantile", "value")]

  return(dat)
}