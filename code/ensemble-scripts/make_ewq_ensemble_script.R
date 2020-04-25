require(tidyverse)
require(stringr)
source("./code/ensemble-scripts/ew_quantile.R")
source("./code/validation/functions_plausibility.R")

# ----------------------------  make ensemble ---------------------------- #
## state
models <- c("LANL-GrowthRate","IHME-CurveFit")
state_output <- pull_all_forecasts(this_date,models,"wk ahead cum",quantiles=c(0.025,0.5,0.975))
combined_table <- unlist(state_output[[1]]) %>%
  dplyr::filter(target!="7 wk ahead cum death",location!="US")
# adding manual check
check_table <-combined_table %>% 
  group_by(location,target,quantile) %>%
  dplyr::mutate(n=n())
mismatched_location <- unique(check_table$location[which(check_table$n!=length(models))])
# excluding mismatched location
combined_table <- combined_table %>%
  dplyr::filter(location!=78&location!=72)
quant_ensemble<-ew_quantile(combined_table, quantiles=c(0.025,0.5,0.975),national=FALSE)

## national
models_n <- c("CU-60contact","CU-70contact","CU-80contact","IHME-CurveFit")
nat_output <- pull_all_forecasts(this_date,models_n,"wk ahead cum",quantiles=c(0.025,0.5,0.975))
combined_table_n <- unlist(nat_output[[1]]) %>%
  dplyr::filter(target!="7 wk ahead cum death",location=="US") 
# adding manual check
check_table_n <-combined_table_n %>% 
  group_by(location,target,quantile) %>%
  dplyr::mutate(n=n())
mismatched_location_n <- unique(check_table_n$location[which(check_table_n$n!=length(models_n))])
# excluding mismatched location if any and run
quant_ensemble_n<-ew_quantile(combined_table_n, quantiles=c(0.025,0.5,0.975),national=TRUE)

## -------- combine state and national -------- ##
final_ens <- rbind(quant_ensemble_n,quant_ensemble)
# format code
final_ens$location[which(nchar(final_ens$location)==1)] <- paste0(0,final_ens$location[which(nchar(final_ens$location)==1)])
# check again
check_table2 <-final_ens %>% 
  group_by(location,target,quantile) %>%
  dplyr::mutate(n=n())
mismatched <- unique(check_table2$location[which(check_table2$n!=1)])

verify_quantile_forecasts(final_ens)
write.csv(final_ens,file=paste0("./data-processed/COVIDhub-ensemble/",this_date,"-COVIDhub-ensemble.csv"),
            row.names = FALSE)


## -------------------- write ensemble info ----------------------------##
nat_info <- unlist(nat_output[[2]]) %>%
  dplyr::mutate(location="US national-level") %>%
  dplyr::select(location,model_name,quantile,forecast_date,weight,target)
state_info <-  unlist(state_output[[2]]) %>%
  dplyr::mutate(location="state-level") %>%
  dplyr::select(location,model_name,quantile,forecast_date,weight,target)
ensemble_info <- rbind(nat_info,state_info)
# read in previous data
preinfo <- read.csv("./data-processed/COVIDhub-ensemble/COVIDhub-ensemble-information.csv",stringsAsFactors = FALSE)
names(preinfo) <- c("location","model_name","quantile","forecast_date","weight","target")
all_info <- rbind(preinfo,ensemble_info)
write.csv(all_info,file=paste0("./data-processed/COVIDhub-ensemble/COVIDhub-ensemble-information.csv"),
          row.names = FALSE)