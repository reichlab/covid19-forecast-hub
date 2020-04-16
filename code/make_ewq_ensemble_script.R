require(dplyr)
require(cdcForecastUtils) #devtools::install_github("reichlab/cdcForecastUtils")
require(stringr)
source("./code/ew_quantile.R")

# define week
# get info. fix to read old one in and add on after the first run
this_date<-""
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
combined_table <- pull_all_forecasts(this_date) 
quant_ensemble<-ew_quantile(combined_table, quantiles=c(0.025,0.5,0.975))
# if(cdcForecastUtils::verify_entry(quant_ensemble)){
#   write.csv(quant_ensemble,
#             file=paste0("./data/ILIForecastProject-ensemble/2020-ew",this_ew,
#                         "-ILIForecastProject-ensemble.csv"),
#             row.names = FALSE)
# } else {warning("Manual check required")}

write.csv(quant_ensemble,
          file=paste0("./data/ILIForecastProject-ensemble/2020-ew",this_date,
                        "-DeathForecastProject-quantile_ensemble.csv"),
            row.names = FALSE)