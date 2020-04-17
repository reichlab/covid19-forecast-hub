## script for processing Geneva data
## Johannes Bracher
## April 2020

source("code/process_geneva_file.R")

dir.create("data-processed/Geneva-GrowthRate", showWarnings = FALSE)

# no forecast available for 13 April, can only be used from 20 April on (below code is for testing)
# files_to_process <- data.frame(
#   filenames = as.character(c("predictions_deaths_2020-04-15.csv")),
#   timezeroes = as.Date(c("2020-04-15"))
# )

# check whether all timezero values are valid:
templ <- read.csv("template/covid19-death-forecast-dates.csv", stringsAsFactors = FALSE)
templ$timezero <- as.Date(templ$timezero)
if(!all(as.Date(files_to_process$timezeroes) %in% templ$timezero)){
  stop("At least one timezero provided in folders_to_process is not valid.")
}

# proces files:
for(i in 1:nrow(files_to_process)) {
  tmp_dat <- process_geneva_file(files_to_process$filenames[i], timezero=files_to_process$timezeroes[i])
  write.csv(tmp_dat,
            paste0("data-processed/Geneva-GrowthRate/", files_to_process$timezeroes[i], "-Geneva-GrowthRate.csv"),
            row.names = FALSE)
}

