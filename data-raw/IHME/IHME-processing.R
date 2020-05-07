## reformat IHME forecasts
# Run from data-raw/IHME

#' Transform matrix of samples for one location into a quantile-format data_frame
#'
#' @param path the forecast file path
#' @return long-format data_frame with quantiles
#' 
make_qntl_dat <- function(path) {
  require(tidyverse)
  require(MMWRweek)
  require(lubridate)
  forecast_date <- gsub("_", "-",substr(dirname(path), 
                                        start = date_offset +  1,  # these should not be hard-coded
                                        stop  = date_offset + 10)) 
  forecast_date <- as.Date(forecast_date)
  data <- read.csv(path, stringsAsFactors = FALSE)
  # format read-in file
  data <- data %>%
    dplyr::select(grep("location",names(data)),grep("date",names(data)),everything()) 
  if (names(data)[grep("date",names(data))]!="date"){
    data<-data %>%
      dplyr::rename(date=names(data)[grep("date",names(data))])
  }  
  if (sum(grepl("location_name",names(data)))>0 & !("location" %in% names(data))){
    data<-data %>%
      dplyr::rename(location=location_name)
  }
  if (sum(grepl("V1",names(data)))>0){
    data<-data %>%
      dplyr::select(-"V1")
  }
  data <- data %>%
    dplyr::select(-names(data)[which(grepl("location",names(data))==TRUE)][-which(names(data)[which(grepl("location",names(data))==TRUE)]=="location")])

  ## read state code
  state_fips_codes<-read.csv("../../template/state_fips_codes.csv",stringsAsFactors = FALSE) %>%
    dplyr::select(-"state")
  col_list1 <- c(grep("location", colnames(data)),grep("date", colnames(data)),grep("death", colnames(data)))
  death_qntl1 <- data[,c(col_list1)] %>%
    dplyr::rename(date_v=date) %>%
    # dplyr::filter(as.Date(as.character(date_v)) %in% c(forecast_date+1:7)) %>%
    dplyr::filter(as.Date(as.character(date_v)) > forecast_date) %>%
    dplyr::mutate(target_id=paste(difftime(as.Date(as.character(date_v)),forecast_date,units="days"),"day ahead inc death")) %>%
    dplyr::rename("0.025"=deaths_lower,"0.975"=deaths_upper,"NA"=deaths_mean) %>%
    gather(quantile, value, -c(location, date_v, target_id)) %>%
    dplyr::left_join(state_fips_codes, by=c("location"="state_name")) %>%
    dplyr::rename(location_id=state_code) %>%
    dplyr::mutate(type=ifelse(quantile=="NA","point","quantile"),forecast_date=forecast_date) %>%
    dplyr::rename(target_end_date=date_v)
  col_list2 <- c(grep("location", colnames(data)),grep("date", colnames(data)),grep("totdea",colnames(data)))
  death_qntl2 <- data[,c(col_list2)] %>%
    dplyr::rename(date_v=date) %>%
    # dplyr::filter(as.Date(as.character(date_v)) %in% c(forecast_date+1:7)) %>%
    dplyr::filter(as.Date(as.character(date_v)) > forecast_date) %>%
    dplyr::mutate(target_id=paste(difftime(as.Date(as.character(date_v)),forecast_date,units="days"),"day ahead cum death")) %>%
    dplyr::rename("0.025"=totdea_lower,"0.975"=totdea_upper,"NA"=totdea_mean) %>%
    gather(quantile, value, -c(location, date_v, target_id)) %>%
    dplyr::left_join(state_fips_codes, by=c("location"="state_name")) %>%
    dplyr::rename(location_id=state_code) %>%
    dplyr::mutate(type=ifelse(quantile=="NA","point","quantile"),forecast_date=forecast_date) %>%
    dplyr::rename(target_end_date=date_v)
  # add hospitalization daily incident (admis)
  col_list3 <- c(grep("location", colnames(data)),grep("date", colnames(data)),grep("admis",colnames(data)))
  death_qntl3 <- data[,c(col_list3)] %>%
    dplyr::rename(date_v=date) %>%
    # dplyr::filter(as.Date(as.character(date_v)) %in% c(forecast_date+1:7)) %>%
    dplyr::filter(as.Date(as.character(date_v)) > forecast_date) %>%
    dplyr::mutate(target_id=paste(difftime(as.Date(as.character(date_v)),forecast_date,units="days"),"day ahead inc hosp")) %>%
    dplyr::rename("0.025"=admis_lower,"0.975"=admis_upper,"NA"=admis_mean) %>%
    gather(quantile, value, -c(location, date_v, target_id)) %>%
    dplyr::left_join(state_fips_codes, by=c("location"="state_name")) %>%
    dplyr::rename(location_id=state_code) %>%
    dplyr::mutate(type=ifelse(quantile=="NA","point","quantile"),forecast_date=forecast_date) %>%
    dplyr::rename(target_end_date=date_v)
  # add if for forecast date weekly
  if (lubridate::wday(forecast_date,label = TRUE, abbr = FALSE)=="Sunday"|lubridate::wday(forecast_date,label = TRUE, abbr = FALSE)=="Monday"){
    death_qntl2_1 <- data[,c(col_list2)] %>%
      dplyr::rename(date_v=date) %>%
      dplyr::mutate(day_v=lubridate::wday(date_v,label = TRUE, abbr = FALSE),
                    ew=unname(MMWRweek(date_v)[[2]])) %>%
      # dplyr::filter(day_v =="Saturday" & 
      #                 ew<unname(MMWRweek(forecast_date)[[2]])+6 & 
      #                 ew>unname(MMWRweek(forecast_date)[[2]])-1) %>%
      dplyr::filter(day_v =="Saturday" & ew>unname(MMWRweek(forecast_date)[[2]])-1) %>%
      dplyr::mutate(target_id=paste((ew-(unname(MMWRweek(forecast_date)[[2]]))+1),"wk ahead cum death")) 
  } else {
    death_qntl2_1 <- data[,c(col_list2)] %>%
      dplyr::rename(date_v=date) %>%
      dplyr::mutate(day_v=lubridate::wday(date_v,label = TRUE, abbr = FALSE),
                    ew=unname(MMWRweek(date_v)[[2]])) %>%
      # dplyr::filter(day_v =="Saturday" & 
      #                 ew<(unname(MMWRweek(forecast_date)[[2]])+1)+6 & 
      #                 ew>unname(MMWRweek(forecast_date)[[2]])) %>%
      dplyr::filter(day_v =="Saturday" & ew>unname(MMWRweek(forecast_date)[[2]])) %>%
      dplyr::mutate(target_id=paste((ew-(unname(MMWRweek(forecast_date)[[2]])+1))+1,"wk ahead cum death")) 
  }
  death_qntl2_2 <- death_qntl2_1 %>%
    dplyr::rename("0.025"=totdea_lower,"0.975"=totdea_upper,"NA"=totdea_mean) %>%
    gather(quantile, value, -c(location, date_v, day_v, ew, target_id)) %>%
    dplyr::left_join(state_fips_codes, by=c("location"="state_name")) %>%
    dplyr::rename(location_id=state_code,target_end_date=date_v) %>%
    dplyr::mutate(type=ifelse(quantile=="NA","point","quantile"),forecast_date=forecast_date) %>%
    dplyr::select(-"day_v",-"ew")
  # combining data
  comb <-rbind(death_qntl1,death_qntl2,death_qntl2_2,death_qntl3) 
  comb$location[which(comb$location=="United States of America")] <- "US"
  comb$location_id[which(comb$location=="US")] <- "US"
  comb <- comb %>%
    dplyr::filter(!is.na(location_id)) %>%
    dplyr::rename(location_name=location)
  comb$quantile[which(comb$quantile=="NA")] <- NA
  comb$quantile <- as.numeric(comb$quantile)
  comb$value <- as.numeric(comb$value)
  final<- comb %>%
    dplyr::select(forecast_date,target_id,target_end_date,location_id,location_name,type,quantile,value) %>%
    dplyr::rename(target=target_id,location=location_id) %>%
    arrange(location,type,quantile,target)
  final$location[which(nchar(final$location)==1)] <- paste0(0,final$location[which(nchar(final$location)==1)])
  return(final)
}


## list all files and read
filepaths <- list.files("./",pattern = "Hospitalization_all_locs.csv", recursive =TRUE,full.names = TRUE)
file_processed_dates <- substr(basename(list.files("../../data-processed/IHME-CurveFit",
                                                   pattern = ".csv", 
                                                   recursive = TRUE,
                                                   full.names = TRUE)),
                               start = 1,
                               stop  = 10)
file_processed_dates <- file_processed_dates[-length(file_processed_dates)]

date_offset = 3
raw_file_dates <- substr(dirname(filepaths),
                         start = date_offset +  1,
                         stop  = date_offset + 10)

newfile_date <- setdiff(gsub("_", "-",raw_file_dates),file_processed_dates)

if (length(newfile_date)) {
  new_filepath <- filepaths[grepl(gsub("-", "_",newfile_date),filepaths)]
  for(i in 1:length(new_filepath)){
    formatted_file <- make_qntl_dat(new_filepath[i])
    
    date <- gsub("_", "-",substr(dirname(new_filepath[i]),
                                 start = date_offset +  1,
                                 stop  = date_offset + 10))
    
    write_csv(formatted_file,
              path = paste0("../../data-processed/IHME-CurveFit/",
                            date,
                            "-IHME-CurveFit.csv"))
  }
}
