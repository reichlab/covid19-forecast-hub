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
    warning("please ensure that the filename does not have any directories in it.")
  }

  # check that starts with date:
  date0 <- substr(filename, start = 1, stop = 10)
  date <- tryCatch({as.Date(date0, format = "%Y-%m-%d")}, error = function(e){NA})
  if(is.na(date) | date < as.Date("2020-03-01")){
    result <- FALSE
    warning("File name needs to start with a date of format YYYY-MM-DD (and later than 2020-03-01).")
  }

  # check that contains ".csv":
  if(substr(filename, start = nchar(filename) - 3, nchar(filename)) != ".csv"){
    result <- FALSE
    warning("File name needs to end in .csv")
  }

  if(result) cat("File name corresponds to standards.\n")

  return(result)
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
  compulsory_colnames_template <- c("target", "location", "type", "quantile", "value") # location_name is optional

  result <- TRUE

  # check whether there are colnames present which should not
  if(!all(coln %in% colnames_template)){
    warning("There is at least one column name which does not conform with the template: ",
            coln[!(coln %in% colnames_template)])
    result <- FALSE
  }

  # check if essential columns are there
  if(!all(compulsory_colnames_template %in% coln)){
    warning("At least one required column is missing: ",
            compulsory_colnames_template[!(compulsory_colnames_template %in% coln)])
    result <- FALSE
  }

  # check order
  colnames_template_available <- colnames_template[colnames_template %in% coln]
  if(any(coln != colnames_template_available)){
    warning("Order of coumns does not correspond to template.")
    result <- FALSE
  }

  if(result) cat("Column names correspond to standards.\n")

  return(invisible(result))
}

#' Checking that all entries in `target` correspond to standards
#'
#' @param entry the data.frame
#'
#' @return invisibly returns TRUE if problems detected, FALSE otherwise
verify_targets <- function(entry){
  allowed_targets <- c(
    paste(1:130, "day ahead inc death"),
    paste(1:130, "day ahead cum death"),
    paste(1:20, "wk ahead inc death"),
    paste(1:20, "wk ahead cum death"),
    paste(1:30, "day ahead inc hosp")
  )
  targets_in_entry <- unique(entry$target)
  if(!all(targets_in_entry %in% allowed_targets)){
    warning("Some entries in `targets` do not correspond to standards:",
            paste0(targets_in_entry[!(targets_in_entry %in% allowed_targets)], collapse = ", "))
    return(FALSE)
  }else{
    cat("All entries in `target` correspond to standards.\n")
    return(TRUE)
  }
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
  # choose columns representing quantiles
  quantiles <- as.matrix(entry_wide[, grepl("value.", colnames(entry_wide))])
  # re-order columns if necessary:
  quantiles <- quantiles[, sort(colnames(quantiles))]
  # check whether rows are non-decreasing (i.e. there are no crossings)
  is_crossing <- apply(quantiles, 1, function(v) any(diff(v) < -0.01)) # leave some tolerance
  # warn if there are crossing and return info on where they ocurred
  if(any(is_crossing)){
    warning("Quantile crossing found for ", sum(is_crossing), " combinations of location and target.")
    return(invisible(entry_wide[is_crossing, c("location", "target")]))
  }else{
    cat("No quantile crossings found.\n")
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
  if(any(c(is_decreasing_daily, is_decreasing_weekly))){
    warning("Temporal non-monotonicity found in forecasts of cumulative deaths for ",
            sum(c(is_decreasing_daily, is_decreasing_weekly)),
            " combinations of location and quantile/point forecast")
    ret_obj <- rbind(entry_daily_wide[is_decreasing_daily, c("location", "quantile")],
                     entry_weekly_wide[is_decreasing_weekly, c("location", "quantile")])
    rownames(ret_obj) <- NULL
    return(invisible(ret_obj))
  }else{
    cat("No temporal non-monotonicity found in forecasts of cumulative deaths.\n")
    return(invisible(TRUE))
  }
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
    cat("File does not contain forecasts of cumulative deaths.\n")
    return(invisible(TRUE))
  }

  if(length(targets_inc) == 0){
    cat("File does not contain forecasts of incident deaths.\n")
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

  if(any(inc_exceeds_cum, na.rm = TRUE)){
    warning("Incidence forecast exceecd cumulative forecast ", sum(inc_exceeds_cum),
            " combinations of location, forecast horizon and quantile.")
    if(any(is.na(inc_exceeds_cum))){
      warning("There seem to be NA values either in the incidence or cumulative death forecats.")
    }
    return(invisible(entry_wide[inc_exceeds_cum, c("location", "horizon", "quantile")]))
  }else{
    cat("No case found in which incidence forecast exceecds cumulative forecast.\n")
    if(any(is.na(inc_exceeds_cum))){
      warning("There seem to be NA values either in the incidence or cumulative death forecats.")
    }
    return(invisible(TRUE))
  }
}


verify_quantile_forecasts <- function(entry){
  options(warn = 1) # show warnigns as tehy happen
  results <- list()
  results$colnames <- verify_colnames(entry)
  results$tarfets <- verify_targets(entry)
  results$no_quantile_crossings <- verify_no_quantile_crossings(entry)
  results$monotonicity_cumulative <- verify_monotonicity_cumulative(entry)
  results$cumulative_geq_incident <- verify_cumulative_geq_incident(entry)
  options(warn = 0)
  return(invisible(results))
}
