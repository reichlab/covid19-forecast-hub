## script for processing CU data
## Johannes Bracher
## April 2020

source("code/process_cu_file.R")

folders_to_process <- data.frame(
  folders = as.character(c("Projection_April12/cdchosp")),
  timezeroes = as.Date(c("2020-04-13"))
)

# different versions of CU forecasts:
scenarios <- c("60contact", "70contact", "80contact", "nointerv")

# check whether all timezero values are valid:
templ <- read.csv("template/covid19-death-forecast-dates.csv", stringsAsFactors = FALSE)
templ$timezero <- as.Date(templ$timezero)
if(!all(as.Date(folders_to_process$timezeroes) %in% templ$timezero)){
  stop("At least one timezero provided in folders_to_process is not valid.")
}

for(i in 1:nrow(folders_to_process)) {
  # check if file naming still the same:
  tmp_ls_files <- list.files(paste0("data-raw/CU/",
                                    folders_to_process$folders[i]))
  if(!all(paste0("state_cdchosp_", scenarios, ".csv") %in% tmp_ls_files)){
    stop("Not all expected files found.")
  }

  # run over different scenarios:
  for(sc in scenarios){
    dir.create(paste0("data-processed/CU-", sc, "/"), showWarnings = FALSE)

    tmp_dat <- process_cu_file(
      cu_filepath = file.path("data-raw/CU/", folders_to_process$folders[i]),
      file = paste0("state_cdchosp_", sc, ".csv"),
      timezero = folders_to_process$timezeroes[i])

    write.csv(tmp_dat, paste0("data-processed/CU-", sc, "/",
                              folders_to_process$timezeroes[i],
                              "-CU-", sc, ".csv"), row.names = FALSE)
  }
}

