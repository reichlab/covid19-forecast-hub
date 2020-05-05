require(tidyverse)
require(stringr)
require(lubridate)
source("./code/ensemble-scripts/ew_quantile.R")
source("./code/validation/functions_plausibility.R")
#source("./code/ensemble-scripts/component_check.R")

## CODE FOR RUNNING COVIDhub-ensemble for Tuesday, May 5 only
## THERE ARE CUSTOM FIXES THAT ARE PARTICULAR TO THIS DATE
## DO NOT RUN AS IS FOR OTHER DATES

# run shinyapp first to generate all_data and fips data locally (this should be broken out into it's own function)

# UPDATE THE GLOBAL VARIABLE of this_date
this_date<-"2020-05-04"
last_friday <- as.Date(this_date) - wday(as.Date(this_date) + 1)
quan=c(0.01, 0.025, seq(0.05, 0.95, by = 0.05), 0.975, 0.99)

# read in truth for quantile plausibility check
truths <- read.csv("./data-truth/truth-Cumulative Deaths.csv",stringsAsFactors = FALSE) %>%
  dplyr::filter(date==as.Date(this_date)-1)

# targets that we are looking to build ensembles for
targets <- c(paste(1:4,"wk ahead cum death"))

# manual check for overlapping quantiles and targets
# latest <- unique(latest[,1:ncol(latest)])
US_models <- all_data %>% 
  filter(target%in%targets, 
    fips_alpha=="US", 
    model != "ensemble",
    type=="quantile",
    as.Date(forecast_date) >= as.Date(last_friday), 
    (quantile==0.10|quantile==0.1))

## checks that model has all 4 targets. this check may not be needed anymore
US_models_tar <- US_models %>%
  group_by(model) %>%
  tally() %>%
  filter(n==4)

# check that models that have all 4 weekly targets also pass the 10th quantile check
US_models_10 <- US_models %>% 
  filter(target==targets[1], 
    value > truths$value[which(truths$location_name=="US")],
    model %in% c(US_models_tar$model))

#state

truths_state <- truths %>%
  filter(location_name!="US") %>%
  left_join(fips, by=c("location"="fips_numeric"))

state_models <- all_data %>% 
  filter(target%in%targets,
    model != "ensemble",
    type=="quantile",
    as.Date(forecast_date)>=as.Date(last_friday),
    (quantile==0.10|quantile==0.1))


## build `list` = data.frame for 0/1 check values
list<-data.frame(cbind(unique(state_models$fips_alpha)))
list[,unique(state_models$model)] <- NA
names(list)[1] <- "state"

# check that models that have all 4 weekly targets also pass the 10th quantile check
state_models_tar <- state_models %>%
  group_by(model,fips_alpha) %>%
  tally() %>%
  filter(n==4)
state_models_10 <- state_models %>% 
  filter(target==targets[1], model %in% c(state_models_tar$model)) %>%
  left_join(truths_state, by=c("fips_alpha"="fips_alpha")) 

# tem fix, needed because we don't have truth data for a few locations
state_models_10$value.y[which(is.na(state_models_10$value.y))]<-0
state_models_10 <- state_models_10 %>%
  filter(value.x>value.y) 

## for each cell in the "check" column, add 0 or 1
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


# modifying list of models to exclude certain models?
list_mod <- list %>%
  mutate(excl=rowSums(list[,-1])) %>%
  filter(excl!=1) %>%
  left_join(fips, by=c("state"="fips_alpha")) %>%
  select(-"full_name", -"excl",
         -"80contact",-"80contactw") %>%
  select(fips_numeric,everything())

## manually remove UT model from SD
SD_fips <- fips$fips_numeric[which(fips$fips_alpha=="SD")]
list_mod[which(list_mod$fips_numeric==SD_fips), "Mobility"] <- 0

# get weight
norm <- function(x){return (x/sum(x))}
list_w <- data.frame(t(apply(list_mod[,-c(1,2)],1,norm))) 
list_w$state <- list_mod$state
list_w$fips <- list_mod$fips_numeric
list_w <- list_w %>%
  select(fips, state, everything()) 
list_w[is.na(list_w)] <- 0

## remove fips
list_mod <- select(list_mod, -state)


# -------------  make ensemble (1-4 week ahead incident AND cumulative death) ------------------ #

## only take last friday
## state cum death
quant_ensemble<-data.frame()
for (i in 1:nrow(list_mod)){
  ## for each state, find the models that we should exclude
  excl <- c(names(list_mod[i,])[which(list_mod[i,]==0)])
  all_m <- paste(names(list_mod)[-1],sep="")
  excl_n <- which(all_m %in% excl)
  ## subset to only have the models for each included state
  mod_each_state <- all_m[-excl_n]
  state_output <- pull_all_forecasts(this_date, mod_each_state, targets[1:4], quan, list_mod$fips_numeric[i])[[1]]
  quant_ensemble_each <- ew_quantile(state_output, national=FALSE, this_date)
  quant_ensemble <- rbind(quant_ensemble, quant_ensemble_each)
}

# temp fix: this fixes a one-off quantile crossing issue in KY 4-week-ahead
offending_idx <- which(quant_ensemble$target=="4 wk ahead cum death" & quant_ensemble$location=="21" & quant_ensemble$quantile==0.050)
quant_ensemble$value[offending_idx] <- quant_ensemble$value[offending_idx] + 1

## build national ensemble 
## manually removing models that we don't want to include
models_n <- US_models_10 %>%
  dplyr::filter(model!="80contactw", model!="80contact") %>%
  dplyr::select(model) 
models_n <- c(unique(models_n$model))
nat_output <- pull_all_forecasts(this_date, models_n, targets[1:4], quan, "US")
combined_table_n <- nat_output[[1]]
quant_ensemble_n <- ew_quantile(combined_table_n, national=TRUE, this_date)


## -------- combine state and national -------- ##

# final_ens <- rbind(quant_ensemble,quant_ensemble_2,quant_ensemble_n,quant_ensemble_n2)
final_ens <- rbind(quant_ensemble, quant_ensemble_n)

filename_ens <- paste0("./data-processed/COVIDhub-ensemble/",this_date,"-COVIDhub-ensemble.csv")
write.csv(final_ens,file=filename_ens,
            row.names = FALSE)
tmp <- validate_file(filename_ens)

## -------------------- write ensemble info ----------------------------##

## this code creates the metadata files about the models
nat_info <-nat_output[[2]] %>%
  dplyr::mutate(location="US national-level") %>%
  dplyr::select(location, model_name, quantile, forecast_date, weight, target)
ensemble_info <- rbind(nat_info)
ensemble_info$epiweek <- unname(MMWRweek::MMWRweek(this_date)$MMWRweek)
ensemble_info$forecast_date <- this_date
#read in previous data
preinfo <- read.csv("./data-raw/COVIDhub-ensemble/COVIDhub-ensemble-information.csv",stringsAsFactors = FALSE) %>%
  filter(forecast_date < last_friday)
# check below before running
names(preinfo) <- c("location","model_name","quantile","forecast_date","weight","target")

## add n_models to list_w
list_w$sum <- rowSums(list_w[,-c(1:2)])
list_w$n_models <- rowSums(list_w[,-c(1:2, ncol(list_w))]>0)

all_info <- rbind(preinfo,ensemble_info)
write.csv(ensemble_info,file=paste0("./data-raw/COVIDhub-ensemble/COVIDhub-ensemble-information.csv"),
          row.names = FALSE)
write.csv(list,file=paste0("./data-raw/COVIDhub-ensemble/state-check-information.csv"),
          row.names = FALSE)
write.csv(list_w,file=paste0("./data-raw/COVIDhub-ensemble/state-weight-information.csv"),
          row.names = FALSE)
