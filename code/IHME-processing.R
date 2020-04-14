## reformat IHME forecasts

library(tidyverse)

#' Transform matrix of samples for one location into a quantile-format data_frame
#'
#' @param data the forecast data frames 
#' @param forecast_date the forecast date in a date format
#'
#' @return long-format data_frame with quantiles
#' 
#'
make_qntl_dat <- function(data, forecast_date) {
  require(tidyverse)
  require(MMWRweek)
  require(lubridate)
  state_fips_codes<-read.csv("./template/state_fips_codes.csv",stringsAsFactors = FALSE) %>%
    dplyr::select(-"state")
    col_list1 <- grep("death", colnames(data))
    death_qntl1 <- data[,c(1:3,col_list1)] %>%
      dplyr::select(-"V1") %>%
      dplyr::rename(date_v=date) %>%
      dplyr::filter(as.Date(as.character(date_v)) %in% c(forecast_date+1:7)) %>%
      dplyr::mutate(target_id=paste(difftime(as.Date(as.character(date_v)),forecast_date,units="days"),"day ahead inc")) %>%
      dplyr::rename("0.025"=deaths_lower,"0.975"=deaths_upper,"NA"=deaths_mean) %>%
      gather(quantile, value, -c(location, date_v, target_id)) %>%
      dplyr::left_join(state_fips_codes, by=c("location"="state_name")) %>%
      dplyr::rename(location_id=state_code) %>%
      dplyr::mutate(type=ifelse(quantile=="NA","point","quantile")) %>%
      dplyr::select(-"date_v")
    col_list2 <- grep("totdea",colnames(data))
    death_qntl2 <- data[,c(1:3,col_list2)] %>%
      dplyr::select(-"V1") %>%
      dplyr::rename(date_v=date) %>%
      dplyr::filter(as.Date(as.character(date_v)) %in% c(forecast_date+1:7)) %>%
      dplyr::mutate(target_id=paste(difftime(as.Date(as.character(date_v)),forecast_date,units="days"),"day ahead cum")) %>%
      dplyr::rename("0.025"=totdea_lower,"0.975"=totdea_upper,"NA"=totdea_mean) %>%
      gather(quantile, value, -c(location, date_v, target_id)) %>%
      dplyr::left_join(state_fips_codes, by=c("location"="state_name")) %>%
      dplyr::rename(location_id=state_code) %>%
      dplyr::mutate(type=ifelse(quantile=="NA","point","quantile")) %>%
      dplyr::select(-"date_v")
    death_qntl3 <- data[,c(1:3,col_list2)] %>%
      dplyr::select(-"V1") %>%
      dplyr::rename(date_v=date) %>%
      dplyr::mutate(day_v=lubridate::day(date_v),ew=unname(MMWRweek(date_v)[[2]])) %>%
      dplyr::filter(day_v =="Saturday" & ew<unname(MMWRweek(forecast_date)[[2]])+7) %>%
      dplyr::mutate(target_id=paste(ew-unname(MMWRweek(forecast_date)[[2]]),"wk ahead cum")) %>%
      dplyr::rename("0.025"=totdea_lower,"0.975"=totdea_upper,"NA"=totdea_mean) %>%
      gather(quantile, value, -c(location, date_v, day_v, ew, target_id)) %>%
      dplyr::left_join(state_fips_codes, by=c("location"="state_name")) %>%
      dplyr::rename(location_id=state_code) %>%
      dplyr::mutate(type=ifelse(quantile=="NA","point","quantile")) %>%
      dplyr::select(-"date_v",-"day_v",-"ew")
    comb <-rbind(death_qntl1,death_qntl2,death_qntl3) %>% 
      dplyr::filter(!is.na(location_id)) %>%
      dplyr::rename(location_name=location) %>%
      dplyr::select(target_id,location_id,location_name,type,quantile,value)
    comb$quantile[which(comb$quantile=="NA")] <- NA
    comb$quantile <- as.numeric(comb$quantile)
    comb$value <- as.numeric(comb$value)
    return(comb)
}


## list all files and read
filepaths <- list.files("./data-raw/IHME",pattern = ".csv", recursive =TRUE,full.names = TRUE)
for(i in 1:length(filepaths)){
  assign(substr(dirname(filepaths[i]),start=17,stop=nchar(dirname(filepaths[i]))),
         read.csv(filepaths[i], stringsAsFactors = FALSE))}
## colname 
names(`2020_03_27`)[2] <- "date"
names(`2020_03_29`)[2] <- "date"
names(`2020_03_27`)[1] <- "location"
names(`2020_03_29`)[1] <- "location"
names(`2020_04_05.08.all`)[2] <- "location"
names(`2020_04_07.04.all`)[2] <- "location"
`2020_03_27`$V1 <-1
`2020_03_29`$V1 <-1
`2020_03_27`<-`2020_03_27`[,c(30,1:29)]
`2020_03_29`<-`2020_03_29`[,c(30,1:29)]

## reformat the read files
`2020-03-27_file` <- make_qntl_dat(`2020_03_27`, as.Date("2020-03-27"))
write_csv(`2020-03-27_file`, path = "data-processed/IHME-IHME/2020-03-27-IHME-IHME.csv")

`2020-03-29_file` <- make_qntl_dat(`2020_03_29`, as.Date("2020-03-29"))
write_csv(`2020-03-29_file`, path = "data-processed/IHME-IHME/2020-03-29-IHME-IHME.csv")

`2020-03-30_file` <- make_qntl_dat(`2020_03_30`, as.Date("2020-03-30"))
write_csv(`2020-03-30_file`, path = "data-processed/IHME-IHME/2020-03-30-IHME-IHME.csv")

`2020-03-31_file` <- make_qntl_dat(`2020_03_31.1`, as.Date("2020-03-31"))
write_csv(`2020-03-31_file`, path = "data-processed/IHME-IHME/2020-03-31-IHME-IHME.csv")

`2020-04-01_file` <- make_qntl_dat(`2020_04_01.2`, as.Date("2020-04-01"))
write_csv(`2020-04-01_file`, path = "data-processed/IHME-IHME/2020-04-01-IHME-IHME.csv")

`2020-04-05_file` <- make_qntl_dat(`2020_04_05.08.all`, as.Date("2020-04-05"))
write_csv(`2020-04-05_file`, path = "data-processed/IHME-IHME/2020-04-05-IHME-IHME.csv")

`2020-04-07_file` <- make_qntl_dat(`2020_04_07.04.all`, as.Date("2020-04-07"))
write_csv(`2020-04-07_file`, path = "data-processed/IHME-IHME/2020-04-07-IHME-IHME.csv")



