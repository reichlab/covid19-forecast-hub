require(tidyverse)
require(stringr)
require(lubridate)
source("./code/ensemble-scripts/ew_quantile.R")
source("./code/validation/functions_plausibility.R")
source("./code/ensemble-scripts/component_check.R")

# change weekly
last_friday <- Sys.Date() - wday(Sys.Date() + 1)
this_date<-"2020-05-04"
quan=c(0.01, 0.025, seq(0.05, 0.95, by = 0.05), 0.975, 0.99)
#read in truth
truths <- read.csv("./data-truth/truth-Cumulative Deaths.csv",stringsAsFactors = FALSE) %>%
  dplyr::filter(date==as.Date(this_date)-1)
# target
targets <- c(paste(1:4,"wk ahead cum death"))
# manual check for overlapping quantiles and targets
latest <- unique(latest[,1:ncol(latest)])
US_models<-latest %>% 
  filter(target%in%targets,fips_alpha=="US",type=="quantile",
         as.Date(forecast_date)>=as.Date(last_friday),(quantile==0.10|quantile==0.1))
US_models_tar<-US_models %>%
  group_by(model) %>%
  tally() %>%
  filter(n==4)
# check for 10th quantile
US_models_10<-US_models %>% 
  filter(target==targets[1], value > truths$value[which(truths$location_name=="US")],
         model%in%c(US_models_tar$model))
# US_models_inc<-latest %>% 
#   filter(target%in%targets[5:8],fips_alpha=="US",type=="quantile") %>%
#   group_by(model) %>%
#   summarise(quan=paste(sort(quantile), collapse=','),count=length(quantile))%>%
#   ungroup(.) %>%
#   filter(count==92)

truths_state <- truths %>%
  filter(location_name!="US") %>%
  left_join(fips, by=c("location"="fips_numeric"))
state_models<-latest %>% 
  filter(target%in%targets,type=="quantile",
         as.Date(forecast_date)>=as.Date(last_friday),(quantile==0.10|quantile==0.1)) 
list<-data.frame(cbind(unique(state_models$fips_alpha)))
list[,unique(state_models$model)] <- NA
names(list)[1]<-"state"
state_models_tar<-state_models %>%
  group_by(model,fips_alpha) %>%
  tally() %>%
  filter(n==4)
state_models_10<-state_models %>% 
  filter(target==targets[1],model%in%c(state_models_tar$model)) %>%
  left_join(truths_state, by=c("fips_alpha"="fips_alpha")) 
# tem fix
state_models_10$value.y[which(is.na(state_models_10$value.y))]<-0
state_models_10<-state_models_10 %>%
  filter(value.x>value.y) 
check_state <- state_models_10 %>%
  select(model,fips_alpha)
for(i in 1:length(names(list)[-1])){
  loc <- check_state %>%
    filter(model==names(list)[i+1])
  for(j in 1:length(list$state)){
    list[j,i+1] <-
      ifelse(list[j,1] %in% c(loc$fips_alpha),1,0)
  }
}
list <- list %>%
  filter(state!="US")
# get weight
norm<-function(x){return (x/sum(x))}
list_w <- data.frame(t(apply(list[,-1],1,norm))) 
list_w$state<-list$state
list_w <-list_w %>%
  select(state,everything()) 
list_w[is.na(list_w)]<-0
# for model names
list_mod <- list %>%
  mutate(excl=rowSums(list[,-1])) %>%
  filter(excl!=1) %>%
  left_join(fips, by=c("state"="fips_alpha")) %>%
  select(-"full_name",-"state",-"excl",
         -"80contact",-"80contactw") %>%
  select(fips_numeric,everything())

  # group_by(location_name) %>%
  # summarize(n=paste(model,collapse=',')) 
# state_models_inc<-latest %>% 
#   filter(target%in%targets[5:8],fips_alpha=="NY",type=="quantile") %>%
#   group_by(model) %>%
#   summarise(quan=paste(sort(quantile), collapse=','),count=length(quantile))%>%
#   ungroup(.) %>%
#   filter(count==92)

# -------------  make ensemble (1-4 week ahead incident AND cumulative death) ------------------ #
## only take last friday
## state cum death
quant_ensemble<-data.frame()
for (i in 1:length(list_mod$fips_numeric)){
  excl <-c(names(list_mod[i,])[which(list_mod[i,]==0)])
  all_m<-paste(names(list_mod)[-1],sep="")
  excl_n<-which(all_m %in% excl)
  mod_each_state <- all_m[-excl_n]
  state_output <- pull_all_forecasts(this_date,mod_each_state,targets[1:4],quan,list_mod$fips_numeric[i])[[1]]
  quant_ensemble_each<-ew_quantile(state_output,national=FALSE,this_date)
  quant_ensemble<-rbind(quant_ensemble,quant_ensemble_each)
}

## state inc death
# models_sinc <- state_models_inc %>%
#   dplyr::filter(model!="GLEAM_COVID") %>%
#   dplyr::select(model) 
# models_sinc  <- c(models_sinc$model)
# state_output_2 <- pull_all_forecasts(this_date,models_sinc,targets[5:8],quantiles=c(state_models$quan[1]))
# combined_table_2 <- state_output_2[[1]] %>%
#   dplyr::filter(location!="US")
# # adding manual check
# check_table <-combined_table_2 %>% 
#   group_by(location,target,quantile) %>%
#   dplyr::mutate(n=n())
# mismatched_location <- unique(check_table$location[which(check_table$n==1)])
# mismatched_location
# # excluding mismatched location
# combined_table_2 <- combined_table_2 %>%
#   dplyr::filter(location!=66&location!=69&location!=72&location!=78)
# quant_ensemble_2<-ew_quantile(combined_table_2,national=FALSE,this_date)

## national
models_n <- US_models_10 %>%
  dplyr::filter(model!="80contactw",model!="80contact") %>%
  dplyr::select(model) 
models_n <- c(unique(models_n$model))
nat_output <- pull_all_forecasts(this_date,models_n,targets[1:4],quan,"US")
combined_table_n <- nat_output[[1]]
quant_ensemble_n<-ew_quantile(combined_table_n,national=TRUE,this_date)

# models_n2 <- US_models_inc %>%
#   dplyr::filter(model!="60contact",model!="80contact",model!="nointerv", model!="ensemble2",model!="GLEAM_COVID") %>%
#   dplyr::select(model) 
# models_n2 <- c(models_n2$model)
# nat_output_2 <- pull_all_forecasts(this_date,models_n2,targets[5:8],quantiles=c(US_models_inc$quan[1]))
# combined_table_n2 <- nat_output_2[[1]] %>%
#   dplyr::filter(location=="US") 
# quant_ensemble_n2<-ew_quantile(combined_table_n2,national=TRUE,this_date)

## -------- combine state and national -------- ##

# final_ens <- rbind(quant_ensemble,quant_ensemble_2,quant_ensemble_n,quant_ensemble_n2)
final_ens <- rbind(quant_ensemble,quant_ensemble_n)
# recheck crossing next week
verify_quantile_forecasts(final_ens)
write.csv(final_ens,file=paste0("./data-processed/COVIDhub-ensemble/",this_date,"-COVIDhub-ensemble.csv"),
            row.names = FALSE)
## -------------------- write ensemble info ----------------------------##
nat_info <-nat_output[[2]] %>%
  dplyr::mutate(location="US national-level") %>%
  dplyr::select(location,model_name,quantile,forecast_date,weight,target)
ensemble_info <- rbind(nat_info)
ensemble_info$epiweek <- unname(MMWRweek::MMWRweek(this_date)$MMWRweek)
#read in previous data
preinfo <- read.csv("./data-raw/COVIDhub-ensemble/COVIDhub-ensemble-information.csv",stringsAsFactors = FALSE) %>%
  filter(location=="US national-level")
# check below before running
names(preinfo) <- c("location","model_name","quantile","forecast_date","weight","target")

all_info <- rbind(preinfo,ensemble_info)
write.csv(ensemble_info,file=paste0("./data-raw/COVIDhub-ensemble/COVIDhub-ensemble-information.csv"),
          row.names = FALSE)
write.csv(list,file=paste0("./data-raw/COVIDhub-ensemble/state-check-information.csv"),
          row.names = FALSE)
write.csv(list_w,file=paste0("./data-raw/COVIDhub-ensemble/state-weight-information.csv"),
          row.names = FALSE)