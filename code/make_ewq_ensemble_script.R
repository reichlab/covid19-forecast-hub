require(tidyverse)
# require(cdcForecastUtils) #devtools::install_github("reichlab/cdcForecastUtils")
require(stringr)
source("./code/ew_quantile.R")
source("./code/functions_plausibility.R")

# define week
# get info. fix to read old one in and add on after the first run
this_date<-"2020-04-13"
death_files <- c(list.files(path="./data-processed", pattern="^(2020-04-13-)(.*?)(.csv)$", full.names=TRUE, recursive=TRUE))

death_info_file<-data.frame()
for(i in death_files){
  text <- paste("Retrieve information", i, "...")
  print(text)
  death_info_file <- rbind(death_info_file,get_model_information(i))
}
write.csv(death_info_file, file="./template/death_forecast-model-infomation.csv",row.names = FALSE)
# check<-unique(death_info_file[ ,3:4])

# ----------------------------  make ensemble ---------------------------- #
## state
models <- c("LANL-GrowthRate","IHME-CurveFit")
combined_table <- pull_all_forecasts(this_date,models,"wk ahead cum",quantiles=c(0.025,0.5,0.975)) %>%
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
combined_table_n <- pull_all_forecasts(this_date,models_n,"wk ahead cum",quantiles=c(0.025,0.5,0.975)) %>%
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
# need to change weekly
ensemble_info <- data.frame(
  cbind(c(rep("US national-level",length(models_n)),rep("state-level",length(models))),
                                  c(models_n,models),
                                  rep("0.025,0.5,0.975",length(c(models_n,models))),
                                  rep(this_date,length(c(models_n,models))),
                                  # weight
                                  c(rep(1/length(models_n),length(models_n)),rep(1/length(models),length(models))),
                                  # target
                                  rep("1-6 wk ahead cum death",length(c(models_n,models)))
        )
  )
  
names(ensemble_info) <- c("location","model_name","quantile","forecast_colleceted_date","weight","target")

# read in previous data
preinfo <- read.csv("./data-processed/COVIDhub-ensemble/COVIDhub-ensemble-information.csv",stringsAsFactors = FALSE)
all_info <- rbind(preinfo,ensemble_info)
write.csv(all_info,file=paste0("./data-processed/COVIDhub-ensemble/COVIDhub-ensemble-information.csv"),
          row.names = FALSE)