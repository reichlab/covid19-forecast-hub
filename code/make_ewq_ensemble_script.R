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

# make ensemble
models <- c("LANL","IHME")
combined_table <- pull_all_forecasts(this_date,models,"wk ahead cum",quantiles=c(0.025,0.5,0.975)) %>%
  dplyr::filter(target!="7 wk ahead cum death")
# adding manual check
check_table <-combined_table %>% 
  group_by(location,target,quantile) %>%
  dplyr::mutate(n=n())
mismatched_location <- unique(check_table$location[which(check_table$n!=length(models))])
# excluding mismatched location
combined_table <- combined_table %>%
  dplyr::filter(location!=78&location!=72)
quant_ensemble<-ew_quantile(combined_table, quantiles=c(0.025,0.5,0.975))
quant_ensemble$location[which(nchar(quant_ensemble$location)==1)] <- paste0(0,quant_ensemble$location[which(nchar(quant_ensemble$location)==1)])

# check again
check_table2 <-quant_ensemble %>% 
  group_by(location,target,quantile) %>%
  dplyr::mutate(n=n())
mismatched <- unique(check_table2$location[which(check_table2$n!=1)])

# if(cdcForecastUtils::verify_entry(quant_ensemble)){
#   write.csv(quant_ensemble,
#             file=paste0("./data/ILIForecastProject-ensemble/2020-ew",this_ew,
#                         "-ILIForecastProject-ensemble.csv"),
#             row.names = FALSE)
# } else {warning("Manual check required")}

write.csv(quant_ensemble,
          file=paste0("./data-processed/UMassCoE-ensemble/",this_date,"-UMassCoE-ensemble.csv"),
            row.names = FALSE)


# more formal check
verify_filename(basename(paste0("./data-processed/UMassCoE-ensemble/",this_date,"-UMassCoE-ensemble.csv")))
verify_quantile_forecasts(quant_ensemble)