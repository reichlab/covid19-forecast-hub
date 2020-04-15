## devtools::install_github("reichlab/cdcForecastUtils")
library(cdcForecastUtils) 
library(dplyr)
library(devtools)
library(tidyverse)

# write get data functions (get quantiles info/location/target from each model)

get_model_information <- function(file) {
  entry <- read.csv(file, colClasses = "character",stringsAsFactors = FALSE)
  fips <- read.csv("./template/state_fips_codes.csv",stringsAsFactors = FALSE) 
  US <- data.frame(cbind(US,US,US));names(US) <-colnames(fips)
  loc <- rbind(fips,US)
  ## get unique set of locations and targets as df
  set <- entry %>%
    dplyr::group_by(location,target) %>%
    dplyr::select(location,target) %>%
    dplyr::ungroup() %>%
    unique()
  ## get model name and forecast week from filename
  model_name <- substr(basename(file),12,nchar(basename(file))-4)
  forecast_date <- substr(basename(file),1,10)
  date_file <- cdcForecastUtils::covid19_death_forecast_dates
  set$model_name <- model_name
  set$forecasts_collected_ew <- date_file$forecasts_collected_ew[which(date_file$timezero==forecast_date)]
  set$location_name <- loc$state_name[which(loc$state_code==set$location)]
  return(set)
}

# write quantile functions
pull_all_forecasts <- function(date) {
  # only take files for a given date
  forecast_files <- list.files("./data-processed", pattern = date, recursive=T)
  if (length(forecast_files) == 0) stop("No forecasts-check for submissions.")
  # remove ensemble
  # if(any(grepl("ILIForecastProject-ensemble", forecast_files))){
  #   forecast_files <- forecast_files[-(grep("ILIForecastProject-ensemble", forecast_files))]
  # } else {forecast_files <- forecast_files}
  # 
  forecast_data <- data.frame()
  for (i in 1:length(forecast_files)) {
    single_forecast <- read.csv(file, stringsAsFactors = FALSE) %>%
      filter(type == "quantile") 
    if (grepl("location_name",colnames(single_forecast))){
      single_forecast <- single_forecast %>% dplyr::select(-"location_name")
    }
    print(forecast_files[i])
    forecast_data <- rbind(forecast_data, single_forecast)
  }
  return(forecast_data)
}

ew_quantile <- function(forecast_data,quantiles=c(0.025,0.5,0.975)) {
  fips <- read.csv("./template/state_fips_codes.csv",stringsAsFactors = FALSE) 
  US <- data.frame(cbind(US,US,US));names(US) <-colnames(fips)
  loc <- rbind(fips,US)
  # equal weight quantile
  combined_file <- forecast_data %>%
    na.omit() %>%
    dplyr::filter(quantile %in% quantiles) %>%
    dplyr::group_by(location, target, quantile) %>%
    dplyr::mutate(avg = mean(value)) %>%
    dplyr::ungroup() %>%
    dplyr::select(-"value") 
  concised_dat<-combined_file[!duplicated(combined_file[,c("location","target","quantile")]),] %>%
    dplyr::group_by(location, target) %>%
    dplyr::mutate(norm_value=avg/sum(avg)) %>%
    dplyr::ungroup()  %>%
    dplyr::select(-"avg") %>%
    dplyr::rename(value=norm_value) 
  # generate point forecast for ensemble
  points <- concised_dat %>%
    dplyr::filter(quantile == 0.5) %>%
    dplyr::mutate(quantile=NA, type="point") 
  ensemble <- concised_dat %>%
    dplyr::full_join(points, by=c(names(concised_dat))) 
  ensemble$location_name <- loc$state_name[which(loc$state_code==ensemble$location)]
  ensemble <- ensemble %>%
    dplyr::arrange(location,location_name,type,quantile,value)
  return(ensemble)
}