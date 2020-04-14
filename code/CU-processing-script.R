## script for processing CU data
## Johannes Bracher
## April 2020

##############################################
# This is only for demonstration purposes right now as
# the April 12 file is damaged
##############################################

source("code/process_cu_file.R")

# !!! Using April 09 for demonstration as April 12 csvs are somehow faulty (contain extra columns)
# uncomment the following lines to test with April 9 data
# folders_to_process <- data.frame(
#   folders = as.character(c("Projection_April09/cdc_hosp")),
#   timezeroes = as.Date(c("2020-04-13"))
# )

# names of the files that should be contained in a CU folder:
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
  if(!all(paste0("cdchosp_", scenarios, ".csv") %in% tmp_ls_files)){
    stop("Not all expected iles found.")
  }

  # run over different scenarios:
  for(sc in scenarios){
    dir.create(paste0("data-processed/CU-", sc, "/"), showWarnings = FALSE)

    tmp_dat <- process_cu_file(
      cu_filepath = file.path("data-raw/CU/", folders_to_process$folders[i]),
      file = paste0("cdchosp_", sc, ".csv"),
      timezero = folders_to_process$timezeroes[i])

    write.csv(tmp_dat, paste0("data-processed/CU-", sc, "/",
                              folders_to_process$timezeroes[i],
                              "-CU-", sc, ".csv"), row.names = FALSE)
  }
}

