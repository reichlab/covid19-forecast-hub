# Some functions to perform plausibility checks on forecasts in quantiel format
# Johannes Bracher, April 2020

#' Checking if the filename corresponds to the requirements for quantile death functions
#'
#' Format should be: YYYY-MM-DD-Team-Model.csv
#'
#' @param filename the file name
#'
#' @return invisibly returns TRUE if file name fulfills criteria, FALSE otherwise
#'
verify_filename <- function(filename){

  result <- TRUE

  # check that fileame has only basename
  if(basename(filename) != filename){
    result <- FALSE
    warning("ERROR: please ensure that the filename does not have any directories in it.")
  }

  # check that starts with date:
  date0 <- substr(filename, start = 1, stop = 10)
  date <- tryCatch({as.Date(date0, format = "%Y-%m-%d")}, error = function(e){NA})
  if(is.na(date) | date < as.Date("2020-03-01")){
    result <- FALSE
    warning("ERROR: File name needs to start with a date of format YYYY-MM-DD (and later than 2020-03-01).")
  }

  # check that contains ".csv":
  if(substr(filename, start = nchar(filename) - 3, nchar(filename)) != ".csv"){
    result <- FALSE
    warning("ERROR: File name needs to end in .csv")
  }

  if(result) cat("VALIDATED: filename \n")

  return(invisible(result))
}


#' Checking if date in file name and variable forecast_date agree
#'
#' @param file the fle name
#' @param entry the contents of the file as data.frame
#'
#' @return silently TRUE if dates agree, FALSE otherwise

check_agreement_forecast_date <- function(file, entry){
  date0 <- substr(file, start = 1, stop = 10)
  date_file <- tryCatch({as.Date(date0, format = "%Y-%m-%d")}, error = function(e){NA})
  forecast_date_entry <- as.Date(entry$forecast_date)
  if(!all(forecast_date_entry == date_file)){
    warning("ERROR: Date in file name and forecast_date do not agree.")
    return(invisible(FALSE))
  }else{
    return(invisible(TRUE))
  }
}


#' Checking if a data.frame in quantile format has the right column names
#'
#' Column names should be: "target", "location", "location_name" (optional), "type", "quantile", "value",
#' in that order
#'
#' @param entry the data.frame
#'
#' @return invisibly returns TRUE if column names correct, FALSE otherwise
#'
verify_colnames <- function(entry){
  coln <- colnames(entry)
  colnames_template <- c("forecast_date", "target", "target_end_date",
                         "location", "location_name", "type", "quantile", "value")
  compulsory_colnames_template <- c("forecast_date", "target", "target_end_date",
                                    "location", "type", "quantile", "value") # location_name is optional

  result <- TRUE

  # check whether there are colnames present which should not
  # if(!all(coln %in% colnames_template)){
  #   warning("ERROR: there is at least one column name which does not conform with the template: ",
  #           paste(coln[!(coln %in% colnames_template)], collapse = ", "))
  #   result <- FALSE
  # }

  # check if essential columns are there
  if(!all(compulsory_colnames_template %in% coln)){
    warning("ERROR: at least one required column is missing: ",
            paste(compulsory_colnames_template[!(compulsory_colnames_template %in% coln)],
                  collapse = ", "))
    result <- FALSE
  }

  # check order
  colnames_template_available <- colnames_template[colnames_template %in% coln]

  if(result){
    cat("VALIDATED: column names\n")

    # check order and give warning if not as recommended
    if(any(coln[coln %in% colnames_template_available] != colnames_template_available)){
      cat("  MESSAGE: Preferred order of columns is (forecast_date, target, target_end_date, location,
          location_name (optional), type, quantile, value), but this is not compulsory.\n")
    }
  }

  return(invisible(result))
}

#' Checking that all entries in quantile are from the allowed list of values
#'
#' @param entry the file (to avoid floating point issues with R the file is read in
#' with `quantile` as character rather than numeric)
#'
#' @return invisibly TRUE if all values acceptable, vector with unacceptable values otherwise

verify_quantile_levels <- function(file){
  # read in file with `qualtile` variable as string
  entry_temp <- read.csv(file, stringsAsFactors = FALSE, colClasses = c("quantile" = "character"))
  vals_quantiles <- unique(gsub("0+$", "", entry_temp$quantile))
  allowed_values <- as.character(c(0.01, 0.025, seq(0.05, 0.95, by = 0.05), 0.975, 0.99, NA))
  if(!all(vals_quantiles %in% allowed_values)){
    warning("  ERROR: `quantile` may only contain values from c(0.01, 0.025, seq(0.05, 0.95, by = 0.05), 0.975, 0.99)).",
            " This error may be due to floating point issues. Disallowed values found:",
            vals_quantiles[!vals_quantiles %in% allowed_values])
    return(invisible(vals_quantiles[!vals_quantiles %in% allowed_values]))
  }else{
    cat("VALIDATED: entries of `quantile`\n")
    return(invisible(TRUE))
  }
}

#' Checking whether there are any NA values
#'
#' @param entry the data.frame
#'
#' @return invisibly TRUE if no NA values found, FALSE otherwise
verify_no_na <- function(entry){
  result <- TRUE

  # check for NAs in columns other than quantile:
  if(any(is.na(entry[, -which(colnames(entry) %in% c("quantile"))]))){
    warning("  ERROR: NA values are only allowed in the `quantile` column (for type == `point`).")
    result <- FALSE
  }

  # check for NAs in quantile despite type == "quantile"
  if(any(is.na(entry$quantile) & entry$type == "quantile")){
    warning("  ERROR: `quantile` column can only contain NA values where type == `point`.")
    result <- FALSE
  }

  if(result){
    cat("VALIDATED: no NA values\n")
  }

  return(invisible(result))
}

#' Checking that all entries in `target` correspond to standards
#'
#' @param entry the data.frame
#'
#' @return invisibly returns TRUE if problems detected, FALSE otherwise
verify_targets <- function(entry){
  allowed_targets <- c(
    paste(0:130, "day ahead inc death"),
    paste(0:130, "day ahead cum death"),
    paste(0:20, "wk ahead inc death"),
    paste(0:20, "wk ahead cum death"),
    paste(0:130, "day ahead inc hosp")
  )
  targets_in_entry <- unique(entry$target)
  if(!all(targets_in_entry %in% allowed_targets)){
    warning("ERROR: Some entries in `targets` do not correspond to standards:",
            paste0(targets_in_entry[!(targets_in_entry %in% allowed_targets)], collapse = ", "))
    return(invisible(FALSE))
  }else{
    cat("VALIDATED: targets\n")
    return(invisible(TRUE))
  }
}

#' Check that the dates are formatted as "%Y-%m-%d"
#'
#' @param entry the data.frame
#' @return invisibly returns TRUE if problems detected, FALSE otherwise
verify_date_format <- function(entry){
  forecast_date <- as.Date(entry$forecast_date, format = "%Y-%m-%d")
  target_end_date <- as.Date(entry$target_end_date, format = "%Y-%m-%d")
  if(any(is.na(c(forecast_date, target_end_date)))){
    warning("ERROR: forecast_date or target_end_date are in wrong format or contain NA values. ",
            "Required date format is %Y-%m-%d.")
    return(invisible(FALSE))
  }else{
    cat("VALIDATED: date format \n")
    return(invisible(TRUE))
  }
}

#' Check that target_end_date for week ahead forecasts are Saturdays,
#' forecast_date, target and target_end_date are coherent
verify_forecast_date_end_date <- function(entry){
  entry$forecast_date <- as.Date(entry$forecast_date)
  entry$target_end_date <- as.Date(entry$target_end_date)

  result <- TRUE

  # warning if NA values occur:
  if(any(is.na(c(entry$forecast_date, entry$target_end_date)))){
    warning("ERROR: forecast_date and target_end_date contain NA values or are not in standard format.")
    result <- FALSE
  }else{
    # check that forecast_date, target and target_end_date are coherent for day ahead forecasts
    entry_day <- subset(entry, grepl("day", target))
    horizon_day <- as.numeric(gsub(" .*", "", entry_day$target))
    if(any(as.numeric(entry_day$target_end_date - entry_day$forecast_date) != horizon_day)){
      warning("ERROR: Incoherences between forecast_date, target_end_date and target detected for day ahead forecasts.")
      result <- FALSE
    }

    # check that target_end_date is always a Saturday for week ahead targets
    entry_week <- subset(entry, grepl("wk", target))
    if(any(weekdays(entry_week$target_end_date) != "Saturday")){
      warning("ERROR: target_end_date needs to be a Saturday for all week-ahead forecasts.")
      result <- FALSE
    }

    # check that target_end_date is between 5 and 11 days from forecast_date for one week ahead etc
    horizon_week <- as.numeric(gsub(" .*", "", entry_week$target))
    if(any(
      as.numeric(entry_week$target_end_date - entry_week$forecast_date) < 5 + (horizon_week - 1)*7 |
      as.numeric(entry_week$target_end_date - entry_week$forecast_date) > 11 + (horizon_week - 1)*7
    )){
      warning("ERROR: Difference between target_date and forecast_date needs to be between 5 and 11 days for 1 week ahead forecasts,",
              " between 12 and 18 days for two week ahead and so on.")
      result <- FALSE
    }
  }

  if(result){
    cat("VALIDATED: forecast_date, target_end_date\n")
  }

  return(invisible(result))
}

#' Checking a data.frame in quantile format for quantile crossing
#'
#' @param entry the data.frame
#'
#' @return invisibly returns TRUE if no quantile crossings found; otherwise
#'  a matrix with the locations and targets concerned

verify_no_quantile_crossings <- function(entry){
  # restrict to quantiles
  entry <- subset(entry, type == "quantile")
  # transform to wide
  entry_wide <- reshape(entry, direction = "wide", v.names = "value", timevar = "quantile",
                        idvar = c("location", "target"))
  if(nrow(entry_wide) == 1) return(TRUE) # no reason to check if just one forecast horizon

  # choose columns representing quantiles
  quantiles <- as.matrix(entry_wide[, grepl("value.", colnames(entry_wide))])
  # re-order columns if necessary:
  quantiles <- quantiles[, sort(colnames(quantiles))]
  # check whether rows are non-decreasing (i.e. there are no crossings)
  is_crossing <- apply(quantiles, 1, function(v) any(diff(v) < -0.01)) # leave some tolerance
  # warn if there are crossing and return info on where they ocurred
  if(any(is_crossing)){
    cat("  WARNING: Quantile crossing found for ", sum(is_crossing),
        " combination(s) of location and target. Details in returned table.")
    return(invisible(entry_wide[is_crossing, c("location", "target")]))
  }else{
    cat("VALIDATED: no quantile crossing\n")
    return(invisible(TRUE))
  }
}

#' Checking a data.frame in quantile format for temporal non-monotonicity in forecasts of cumulative deaths
#'
#' @param entry the data.frame
#'
#' @return invisibly returns TRUE if no non-monotonicities found; otherwise
#'  a matrix with the locations and quantiles (or "point" for point forecasts) concerned

verify_monotonicity_cumulative <- function(entry){
  # restrict to compulsory columns (otherwise warnings when reshaping):
  entry <- entry[, c("target", "location", "type", "quantile", "value")]

  # daily forecasts (cumulative only):
  entry_daily <- subset(entry, grepl("day", target) & grepl("cum", target))
  entry_daily$quantile[entry_daily$type == "point"] <- "point"

  # sort by target so columns in wide format will be in right order:
  entry_daily <- entry_daily[order(nchar(entry_daily$target), entry_daily$target), ]
  # transform to wide:
  entry_daily_wide <- reshape(entry_daily, direction = "wide", v.names = "value", timevar = "target",
                              idvar = c("location", "quantile"))
  # choose columns representing dates
  quantiles_daily <- as.matrix(entry_daily_wide[, grepl("value.", colnames(entry_daily_wide))])
  # check whether rows are non-decreasing (i.e. there are no crossings)
  is_decreasing_daily <- apply(quantiles_daily, 1, function(v) any(diff(v) < -0.01)) # some tolerance

  # weekly forecasts (cumulative only):
  entry_weekly <- subset(entry, grepl("wk", target) & grepl("cum", target))
  entry_weekly$quantile[entry_weekly$type == "point"] <- "point"
  # sort by target so columns in wide format will be in right order:
  entry_weekly <- entry_weekly[order(nchar(entry_weekly$target), entry_weekly$target), ]
  # transform to wide:
  entry_weekly_wide <- reshape(entry_weekly, direction = "wide", v.names = "value", timevar = "target",
                               idvar = c("location", "quantile"))
  # choose columns representing dates
  quantiles_weekly <- as.matrix(entry_weekly_wide[, grepl("value.", colnames(entry_weekly_wide))])
  # check whether rows are non-decreasing (i.e. there are no crossings)
  is_decreasing_weekly <- apply(quantiles_weekly, 1, function(v) any(diff(v) < -0.01)) # some tolerance

  # warn if there are crossing and return info on where they ocurred
  if(any(c(is_decreasing_daily, is_decreasing_weekly), na.rm = TRUE)){
    cat("  WARNING: Temporal non-monotonicity found in forecasts of cumulative deaths for ",
        sum(c(is_decreasing_daily, is_decreasing_weekly)),
        " combination(s) of location and quantile/point forecast. Details in returned table. \n")
    ret_obj <- rbind(entry_daily_wide[is_decreasing_daily, c("location", "quantile")],
                     entry_weekly_wide[is_decreasing_weekly, c("location", "quantile")])
    rownames(ret_obj) <- NULL
    return(invisible(ret_obj))
  }else{
    cat("VALIDATED: temporal monotonicity\n")
  }

  return(invisible(TRUE))
}

#' Checking a data.frame in quantile format for basic coherence between forecasts of cumulative
#' and incident deaths
#'
#' Qauntiles / point forecasts of cumulative deaths should always be greater than or equal to the
#' respective incidence forecasts.
#'
#' @param entry the data.frame
#'
#' @return invisibly returns TRUE if no confilcts found; otherwise
#'  a matrix with the locations, forecast horizons and quantiles concerned

verify_cumulative_geq_incident <- function(entry){
  targets <- unique(entry$target)
  targets_cum <- targets[grepl("cum", targets)]
  targets_inc <- targets[grepl("inc", targets)]

  # Catch cases where only incident or only cumulative deaths are covered
  if(length(targets_cum) == 0){
    cat("  MESSAGE: File does not contain forecasts of cumulative deaths.\n")
    return(invisible(TRUE))
  }

  if(length(targets_inc) == 0){
    cat("  MESSAGE: File does not contain forecasts of incident deaths.\n")
    return(invisible(TRUE))
  }

  # which of the incidence and cumulative targets are also covered in the respective other set?
  relevant_targets_inc <- targets_inc[gsub("inc ", "", targets_inc) %in% gsub("cum ", "", targets_cum)]
  relevant_targets_cum <- targets_cum[gsub("cum ", "", targets_cum) %in% gsub("inc ", "", targets_inc)]
  # restrict to these:
  entry <- subset(entry, target %in% c(relevant_targets_inc, relevant_targets_cum))
  # introduce horizon variable (identical for incident and cumulative):
  entry$horizon <- gsub("cum ", "", gsub("inc ", "", entry$target))
  # introduce variable stating if incidence or cumulative:
  entry$inc_or_cum <- c("inc", "cum")[1 + grepl("cum", entry$target)]

  # move to wide:
  entry$target <- NULL # otherwise causes warning
  entry_wide <- reshape(entry, direction = "wide", v.names = "value", timevar = "inc_or_cum",
                        idvar = c("location", "quantile", "horizon"))

  inc_exceeds_cum <- entry_wide$value.inc > entry_wide$value.cum

  # mark point forecasts in quantile column (for return object):
  entry_wide$quantile[entry_wide$type == "point"] <- "point"

  if(any(is.na(inc_exceeds_cum))){
    warning("ERROR: NA values either in the incidence or cumulative death forecats.")
  }

  if(any(inc_exceeds_cum, na.rm = TRUE)){
    cat("WARNING: Incidence forecast exceed cumulative forecast for ", sum(inc_exceeds_cum),
        " combinations of location, forecast horizon and quantile. Details in returned table.")
    return(invisible(entry_wide[inc_exceeds_cum, c("location", "horizon", "quantile")]))
  }else{
    cat("VALIDATED: cum geq inc\n")
    return(invisible(TRUE))
  }


}

#' running various checks on a data.frame of quantile forecasts
#'
#' Qauntiles / point forecasts of cumulative deaths should always be greater than or equal to the
#' respective incidence forecasts.
#'
#' @param entry the data.frame
#'
#' @return invisibly returns a named list with entries corresponding to the results of the different
#' plausibility checks
verify_quantile_forecasts <- function(entry){
  #  show warnings as they occur
  op <- options("warn")
  on.exit(options(op))
  options(warn = 1)

  results <- list()
  # run different checks:
  results$colnames <- verify_colnames(entry)
  results$no_na <- verify_no_na(entry)
  results$targets <- verify_targets(entry)
  results$date_format <- verify_date_format(entry)
  results$forecast_date_end_date <- verify_forecast_date_end_date(entry)
  results$no_quantile_crossings <- verify_no_quantile_crossings(entry)
  results$monotonicity_cumulative <- verify_monotonicity_cumulative(entry)
  results$cumulative_geq_incident <- verify_cumulative_geq_incident(entry)
  return(invisible(results))
}

#' running various checks on a csv file containing quantile forecasts
#'
#' @param file the name of the file which the data are to be read from
#' @return invisibly returns a named list with entries corresponding to the results of the different
#' plausibility checks
validate_file <- function(file){

  cat("\n\n Validating", file, "...\n")
  # check file name:
  check_filename_temp <- verify_filename(basename(file))
  # read in:
  entry_temp <- read.csv(file, stringsAsFactors = FALSE)

  # check agreement of file name and forecast_date
  agreement_forecast_date <-
    check_agreement_forecast_date(file = basename(file), entry = entry_temp)

  # actual check wrapped into try() so actuall errors don't stop the process
  plausibility_checks <- verify_quantile_forecasts(entry_temp)
  plausibility_checks$agreement_forecast_date <- agreement_forecast_date

  # check that `quantile` column only contains allowed values (done separately
  # as this reads in the file with `quantile`as character):
  plausibility_checks$quantile_levels <- verify_quantile_levels(file)

  return(invisible(plausibility_checks))
}

#' running various checks on all csv files contained in a directory
#'
#' @param dir the directory
#' @return invisibly returns a named list with entries corresponding to the results of the
#' plausibility checks for the different files.
validate_directory <- function(dir){
  cat("--------------------------\n \n")
  cat("\n Validating directory", dir, "...\n ")

  #  show warnings as they occur
  op <- options("warn")
  on.exit(options(op))
  options(warn = 1)

  files_temp <- list.files(dir)
  # select files which look roughly like forecast files:
  files_temp <- files_temp[grepl("csv", files_temp) &
                             (grepl("2020-", files_temp) |
                                grepl("2021-", files_temp))]

  plausibility_checks <- list()

  for(fi in files_temp){
    try({
      plausibility_checks[[fi]] <- validate_file(paste0(dir, "/", fi))
    })
    if(!is.list(plausibility_checks[[fi]])) warning("Plausibility check ended with errors!")
  }

  return(invisible(plausibility_checks))
}
