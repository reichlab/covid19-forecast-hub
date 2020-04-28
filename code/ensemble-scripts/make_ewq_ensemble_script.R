require(tidyverse)
require(stringr)
require(lubridate)
source("./code/ensemble-scripts/ew_quantile.R")
source("./code/validation/functions_plausibility.R")
#source("./data-processed/read_processed_data.R")
# change weekly
last_friday <- Sys.Date() - wday(Sys.Date() + 1)
this_date<-"2020-04-27"
# target
targets <- c(paste(1:4,"wk ahead cum death"),paste(1:4,"wk ahead inc death"))
# manual check for overlapping quantiles and targets
latest <- all_data %>% 
  filter(!is.na(forecast_date)) %>%
  group_by(team, model) %>%
  dplyr::filter(forecast_date %in% c(last_friday+0:3),target %in% targets) %>%
  ungroup() %>%
  tidyr::separate(target, into=c("n","unit","ahead","inc_cum","death_cases"),
                  remove = FALSE)
US_models<-latest %>% 
  filter(target%in%targets[1:4],fips_alpha=="US",type=="quantile") %>%
  group_by(model) %>%
  summarise(quan=paste(sort(quantile), collapse=','),count=length(quantile)) %>%
  ungroup(.) %>%
  filter(count==92)
# 4 target *23 quantiles=92
US_models_inc<-latest %>% 
  filter(target%in%targets[5:8],fips_alpha=="US",type=="quantile") %>%
  group_by(model) %>%
  summarise(quan=paste(sort(quantile), collapse=','),count=length(quantile))%>%
  ungroup(.) %>%
  filter(count==92)

state_models<-latest %>% 
  filter(target%in%targets[1:4],fips_alpha=="NY",type=="quantile") %>%
  group_by(model) %>%
  summarise(quan=paste(sort(quantile), collapse=','),count=length(quantile))%>%
  ungroup(.) %>%
  filter(count==92)

state_models_inc<-latest %>% 
  filter(target%in%targets[5:8],fips_alpha=="NY",type=="quantile") %>%
  group_by(model) %>%
  summarise(quan=paste(sort(quantile), collapse=','),count=length(quantile))%>%
  ungroup(.) %>%
  filter(count==92)

# -------------  make ensemble (1-4 week ahead incident AND cumulative death) ------------------ #
## only take last friday
## state cum death
models <- state_models %>%
  dplyr::filter(model!="60contact",model!="80contact",model!="nointerv", model!="ensemble2",model!="GLEAM_COVID",model!="ensemble") %>%
  dplyr::select(model) 
models <- c(models$model)
state_output <- pull_all_forecasts(this_date,models,targets[1:4],quantiles=c(state_models$quan[1]))
combined_table <- state_output[[1]] %>%
  dplyr::filter(location!="US")
# adding manual check
check_table <-combined_table %>% 
  group_by(location,target,quantile) %>%
  dplyr::mutate(n=n())
mismatched_location <- unique(check_table$location[which(check_table$n==1)])
mismatched_location
# excluding mismatched location
combined_table <- combined_table %>%
  dplyr::filter(location!=66&location!=69)
quant_ensemble<-ew_quantile(combined_table,national=FALSE,this_date)

## state inc death
models_sinc <- state_models_inc %>%
  dplyr::filter(model!="GLEAM_COVID",model!="ensemble") %>%
  dplyr::select(model) 
models_sinc  <- c(models_sinc$model)
state_output_2 <- pull_all_forecasts(this_date,models_sinc,targets[5:8],quantiles=c(state_models$quan[1]))
combined_table_2 <- state_output_2[[1]] %>%
  dplyr::filter(location!="US")
# adding manual check
check_table <-combined_table_2 %>% 
  group_by(location,target,quantile) %>%
  dplyr::mutate(n=n())
mismatched_location <- unique(check_table$location[which(check_table$n==1)])
mismatched_location
# excluding mismatched location
combined_table_2 <- combined_table_2 %>%
  dplyr::filter(location!=66&location!=69&location!=72&location!=78)
quant_ensemble_2<-ew_quantile(combined_table_2,national=FALSE,this_date)

## national
models_n <- US_models %>%
  dplyr::filter(model!="60contact",model!="80contact",model!="nointerv", model!="ensemble2",model!="GLEAM_COVID",model!="ensemble") %>%
  dplyr::select(model) 
models_n <- c(models_n$model)
nat_output <- pull_all_forecasts(this_date,models_n,targets[1:4],quantiles=c(US_models$quan[1]))
combined_table_n <- nat_output[[1]] %>%
  dplyr::filter(location=="US") 
quant_ensemble_n<-ew_quantile(combined_table_n,national=TRUE,this_date)

models_n2 <- US_models_inc %>%
  dplyr::filter(model!="60contact",model!="80contact",model!="nointerv", model!="ensemble2",model!="GLEAM_COVID",model!="ensemble") %>%
  dplyr::select(model) 
models_n2 <- c(models_n2$model)
nat_output_2 <- pull_all_forecasts(this_date,models_n2,targets[5:8],quantiles=c(US_models_inc$quan[1]))
combined_table_n2 <- nat_output_2[[1]] %>%
  dplyr::filter(location=="US") 
quant_ensemble_n2<-ew_quantile(combined_table_n2,national=TRUE,this_date)
## -------- combine state and national -------- ##
final_ens <- rbind(quant_ensemble,quant_ensemble_2,quant_ensemble_n,quant_ensemble_n2)
# format code
# final_ens$location[which(nchar(final_ens$location)==1)] <- paste0(0,final_ens$location[which(nchar(final_ens$location)==1)])
# check again
# check_table2 <-final_ens %>% 
#   group_by(location,target,quantile) %>%
#   dplyr::mutate(n=n())
# mismatched <- unique(check_table2$location[which(check_table2$n!=1)])

verify_quantile_forecasts(final_ens)
write.csv(final_ens,file=paste0("./data-processed/COVIDhub-ensemble/",this_date,"-COVIDhub-ensemble.csv"),
            row.names = FALSE)

## -------------------- write ensemble info ----------------------------##
nat_info <-nat_output[[2]] %>%
  dplyr::mutate(location="US national-level") %>%
  dplyr::select(location,model_name,quantile,forecast_date,weight,target)
nat_info2 <-nat_output_2[[2]] %>%
  dplyr::mutate(location="US national-level") %>%
  dplyr::select(location,model_name,quantile,forecast_date,weight,target)
state_info <-  state_output[[2]] %>%
  dplyr::mutate(location="state-level") %>%
  dplyr::select(location,model_name,quantile,forecast_date,weight,target)
state_info2 <-  state_output_2[[2]] %>%
  dplyr::mutate(location="state-level") %>%
  dplyr::select(location,model_name,quantile,forecast_date,weight,target)
ensemble_info <- rbind(nat_info,state_info,nat_info2,state_info2)
names(ensemble_info)[5]<-"approx_weight"
#read in previous data
# preinfo <- read.csv("./data-processed/COVIDhub-ensemble/COVIDhub-ensemble-information.csv",stringsAsFactors = FALSE)
# names(preinfo) <- c("location","model_name","quantile","forecast_date","weight","target")
# all_info <- rbind(preinfo,ensemble_info)
write.csv(ensemble_info,file=paste0("./data-raw/COVIDhub-ensemble/COVIDhub-ensemble-information.csv"),
          row.names = FALSE)

