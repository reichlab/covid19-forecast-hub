library(tidyverse)
library(MMWRweek)
library(lubridate)

pull_all_forecasts <- function(monday_run_date, model,targets,
                               quantiles=c(0.01, 0.025, seq(0.05, 0.95, by = 0.05), 0.975, 0.99),
                               each_location) {
  # get files with this week's forecasts
  # change to only take Friday and later days from run date (previously take upto Tuesday)
  date_set <- paste(c(as.Date(monday_run_date),as.Date(monday_run_date)-1:3),collapse="|")
  all_files <- list.files("./data-processed", pattern = "*.csv", recursive=T)
  fcast_files <- all_files[grepl("[0-9]{4}-[0-9]{2}-[0-9]{2}",all_files)]
  current_fcast <- fcast_files[(grep(date_set, fcast_files))]
  
  # remove models
  list_op <- paste(paste0(model, ".csv"), collapse="|")
  component_fcast <- current_fcast[(grep(list_op, current_fcast))]
  
  # ensure single most recent forecast file for current week for each model
  forecast_files <- c()
  for (j in 1:length(model)){
    current_comp_fcast <- component_fcast[(grepl(model[j], component_fcast))]
    if (length(current_comp_fcast)==1){
      forecast_files <- c(forecast_files,current_comp_fcast)
    }else{
      comp_fdate <- substr(basename(current_comp_fcast),start=1,stop=10)
      most_recent_fdate <-comp_fdate[which.max(as.Date(comp_fdate))]
      current_comp_fcast_single <- current_comp_fcast[(grepl(most_recent_fdate, current_comp_fcast))]
      forecast_files <- c(forecast_files,current_comp_fcast_single)
    }
  }
  # check and document
  if (length(forecast_files) == 0){stop("No forecasts-check for errors.")} else{
    ensemble_component_info <- data.frame(cbind(c(dirname(forecast_files)),
                                                rep(paste(quantiles,collapse = ","),length(forecast_files)),
                                                c(substr(basename(forecast_files),start=1,stop=10)),
                                                rep(1/length(forecast_files),length(forecast_files)),
                                                rep(paste(targets,collapse = ","),length(forecast_files))
                                                
    ))
    names(ensemble_component_info) <- c("model_name","quantile","forecast_date","weight","target")
  }
  
  # start reading
  forecast_data <- data.frame()
  for (i in 1:length(forecast_files)) {
    single_forecast <- read.csv(paste0("./data-processed/",forecast_files[i]),
                                colClasses="character",stringsAsFactors = FALSE) %>%
      dplyr::filter(type == "quantile",target %in% targets,location==each_location)
    if ("location_name" %in% colnames(single_forecast)){
      single_forecast <- single_forecast %>% dplyr::select(-"location_name")
    }
    print(forecast_files[i])
    if (forecast_files[i]==forecast_files[1]){
      forecast_data <- single_forecast
    } else {
      forecast_data <- dplyr::full_join(forecast_data, single_forecast) 
    }
  }
  forecast_data$quantile <- round(as.numeric(forecast_data$quantile),3)
  forecast_data$value <- as.numeric(forecast_data$value)
  forecast_data$type <- as.character(forecast_data$type)
  # forecast_data <- forecast_data %>%
  #   dplyr::filter(quantile %in% quantiles)
  output <- list(forecast_data,ensemble_component_info)
  return(output)
}

ew_quantile <- function(forecast_data,national=FALSE, forecast_date_monday) {
  fips <- read.csv("./template/state_fips_codes.csv",stringsAsFactors = FALSE) 
  US <- data.frame(cbind("US","US","US"));names(US) <-colnames(fips)
  if (national ==TRUE) {
    loc <- rbind(fips,US)
  } else {
    loc <- fips
    loc$state_code[which(nchar(loc$state_code)==1)] <- paste0(0,loc$state_code[which(nchar(loc$state_code)==1)])
  }
  # equal weight quantile
  combined_file <- forecast_data %>%
    na.omit() %>%
    dplyr::group_by(location, target, quantile) %>%
    dplyr::mutate(avg = mean(as.numeric(value))) %>%
    dplyr::ungroup() %>%
    dplyr::select(-"value") %>%
    dplyr::rename(value=avg) 
  concised_dat<-combined_file[!duplicated(combined_file[,c("location","target","quantile")]),] 
  # generate point forecast for ensemble
  points <- concised_dat %>%
    dplyr::filter(quantile == 0.5) %>%
    dplyr::mutate(quantile=NA, type="point") 
  points$quantile <- as.numeric(points$quantile)
  ensemble <- concised_dat %>%
    dplyr::full_join(points, by=c(names(concised_dat))) %>%
    dplyr::left_join(loc,by=c("location"="state_code")) %>%
    dplyr::rename(location_name=state_name) %>%
    dplyr::mutate(forecast_date=forecast_date_monday) %>%
    dplyr::select(-"state") %>%
    dplyr::select(forecast_date,target,target_end_date,location,location_name,type,quantile,value)
  
  return(ensemble)
}