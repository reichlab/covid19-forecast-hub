## devtools::install_github("reichlab/cdcForecastUtils")
library(cdcForecastUtils) 
library(dplyr)
library(devtools)
library(tidyverse)

# write get data functions (get quantiles info/location/target from each model)

get_model_information <- function(file) {
  entry <- read.csv(file,colClasses = "character",stringsAsFactors = FALSE) %>%
    dplyr::filter(type!="point")
  fips <- read.csv("./template/state_fips_codes.csv",colClasses = "character",stringsAsFactors = FALSE) 
  US <- data.frame(cbind("US","US","US"));names(US) <-colnames(fips)
  loc <- rbind(fips,US)
  ## get unique set of locations and targets as df
  set <- entry %>%
    dplyr::group_by(location,target,quantile) %>%
    dplyr::select(location,target,quantile) %>%
    dplyr::ungroup() %>%
    unique()
  ## get model name and forecast week from filename
  model_name <- substr(basename(file),12,nchar(basename(file))-4)
  forecast_date <- substr(basename(file),1,10)
  date_file <- read.csv("./template/covid19-death-forecast-dates.csv",stringsAsFactors = FALSE)
  set$model_name <- model_name
  set$forecasts_collected_ew <- date_file$forecasts_collected_ew[which(date_file$timezero==forecast_date)]
  set <- set %>%
    dplyr::left_join(loc,by=c("location"="state_code")) %>%
    dplyr::rename(location_name=state_name) %>%
    dplyr::select(-"state")
  return(set)
}

# write quantile functions
pull_all_forecasts <- function(date, model,targets,quantiles=c(0.025,0.5,0.975)) {
  # only take files for a given date
  forecast_files <- list.files("./data-processed", pattern = date, recursive=T)
  if (length(forecast_files) == 0) stop("No forecasts-check for submissions.")
  # remove models
  list_op <- paste(model,collapse="|")
  forecast_files <- forecast_files[(grep(list_op, forecast_files))]

  forecast_data <- data.frame()
  for (i in 1:length(forecast_files)) {
    single_forecast <- read.csv(paste0("./data-processed/",forecast_files[i]),
                                colClasses="character",stringsAsFactors = FALSE) %>%
      dplyr::filter(type == "quantile") 
    if ("location_name" %in% colnames(single_forecast)){
      single_forecast <- single_forecast %>% dplyr::select(-"location_name")
    }
    print(forecast_files[i])
    if (i==1){
      forecast_data <- single_forecast
    } else {
      forecast_data <- dplyr::full_join(forecast_data, single_forecast) %>%
        dplyr::filter(grepl(targets,target),type=="quantile")
    }
  }
  forecast_data$quantile <- as.numeric(forecast_data$quantile)
  forecast_data$value <- as.numeric(forecast_data$value)
  # forecast_data$location <- as.numeric(forecast_data$location)
  forecast_data$type <- as.character(forecast_data$type)
  forecast_data <- forecast_data %>%
    dplyr::filter(quantile %in% quantiles)
  return(forecast_data)
}

ew_quantile <- function(forecast_data,quantiles=c(0.025,0.5,0.975),national=FALSE) {
  fips <- read.csv("./template/state_fips_codes.csv",stringsAsFactors = FALSE) 
  US <- data.frame(cbind("US","US","US"));names(US) <-colnames(fips)
  if (national ==TRUE) {
    loc <- rbind(fips,US)
  } else {
    loc <- fips
    loc$state_code <- as.numeric(loc$state_code)
  }
  # equal weight quantile
  combined_file <- forecast_data %>%
    na.omit() %>%
    # dplyr::filter(as.numeric(quantile) %in% as.numeric(quantiles)) %>%
    dplyr::filter(as.numeric(quantile) %in% as.numeric(c(0.025,0.5,0.975))) %>%
    dplyr::group_by(location, target, quantile) %>%
    dplyr::mutate(avg = mean(as.numeric(value))) %>%
    dplyr::ungroup() %>%
    dplyr::select(-"value") %>%
    dplyr::rename(value=avg) 
  concised_dat<-combined_file[!duplicated(combined_file[,c("location","target","quantile")]),] 
  # %>%
    # dplyr::group_by(location, target) %>%
    # # dplyr::mutate(norm_value=as.numeric(avg)/sum(as.numeric(avg))) %>%
    # dplyr::ungroup()  %>%
    # dplyr::select(-"avg") %>%
    # dplyr::rename(value=norm_value) 
  # generate point forecast for ensemble
  points <- concised_dat %>%
    dplyr::filter(quantile == 0.5) %>%
    dplyr::mutate(quantile=NA, type="point") 
  points$quantile <- as.numeric(points$quantile)
  ensemble <- concised_dat %>%
    dplyr::full_join(points, by=c(names(concised_dat))) %>%
    dplyr::left_join(loc,by=c("location"="state_code")) %>%
    dplyr::rename(location_name=state_name) %>%
    dplyr::select(-"state") %>%
    dplyr::select(target,location,location_name,type,quantile,value)
  return(ensemble)
}