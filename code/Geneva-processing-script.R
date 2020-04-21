## script for processing Geneva data
## Johannes Bracher
## April 2020

source("code/process_geneva_file.R")

dir.create("data-processed/Geneva-DeterministicGrowth", showWarnings = FALSE)

files_to_process <- list.files("data-raw/Geneva", recursive = FALSE)
files_to_process <- files_to_process[grepl(".csv", files_to_process) &
                                       grepl("predictions_death", files_to_process)]
forecast_dates <- lapply(files_to_process, date_from_geneva_filepath)

# proces files:
for(i in 1:length(files_to_process)) {
  tmp_dat <- process_geneva_file(files_to_process[i], forecast_date = forecast_dates[[i]])
  write.csv(tmp_dat,
            paste0("data-processed/Geneva-DeterministicGrowth/", forecast_dates[[i]],
                   "-Geneva-DeterministicGrowth.csv"),
            row.names = FALSE)
}

