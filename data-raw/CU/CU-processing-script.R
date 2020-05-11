## script for processing CU data
## Johannes Bracher
## April 2020


source("process_cu_file.R")
# make sure that English names of days and months are used
Sys.setlocale(category = "LC_TIME", locale = "en_US.UTF-8")

folders_to_process <- list.dirs("./", recursive = FALSE)
forecast_dates <- lapply(folders_to_process, date_from_cu_filepath)

# process only files from 2020-04-12 onwards:
#------- commented out to avoid re-processing all files until we have updated the hosp forecasts in the repo
# folders_to_process <- folders_to_process[forecast_dates >= as.Date("2020-04-12")]
#-------------------------------------------------------
# set folders_to_process <- ".//Projection_<Date>" to process a single folder
folders_to_process <- "./Projection_May10" 

# different versions of CU forecasts:
scenarios <- c( "80contact1x10p", "80contactw10p", "80contact1x5p", "80contactw5p")

for(i in seq_along(folders_to_process)) {
  cat("Starting", folders_to_process[i], "...\n")
  # check if file naming still the same:
 # tmp_ls_files <- list.files(paste0(folders_to_process[i], "/cdc_hosp")) # this is when i was using the cdc_hosp folder
  tmp_ls_files <- list.files(paste0(folders_to_process[i]))
  
  # run over different scenarios:
  for(sc in scenarios){
    # create directory if it is not already there:
    dir.create(paste0("../../data-processed/CU-", sc, "/"), showWarnings = FALSE)

    # if scenario is contained in the folder: process it
    if(any(grepl(pattern = paste0(sc, ".csv"), x = tmp_ls_files))){
      forecast_date_temp <- date_from_cu_filepath(folders_to_process[i])

      tmp_dat <- process_cu_file(
        cu_filepath = folders_to_process[i],
        file = paste0("state_cdchosp_", sc, ".csv"),
        forecast_date = forecast_date_temp)

      write.csv(tmp_dat, paste0("../../data-processed/CU-", sc, "/",
                               forecast_date_temp,
                              "-CU-", sc, ".csv"), row.names = FALSE)
    }

  }
}

