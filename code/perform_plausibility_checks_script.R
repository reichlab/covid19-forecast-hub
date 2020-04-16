source("code/functions_plausibility.R")

directories <- list.dirs("data-processed")[-1]


plausibility_checks <- list()

for(dir in directories){
  cat("----------------------------------\n")
  cat("\n \n Starting directory ", dir, "...\n\n")
  files_temp <- list.files(dir)
  files_temp <- files_temp[grepl("csv", files_temp)]

  plausibility_checks[[dir]] <- list()

  for(fi in files_temp){
    cat("\n Starting", fi, "...\n \n")
    # check file name:
    check_filename_temp <- verify_filename(fi)
    # read in:
    entry_temp <- read.csv(paste0(dir, "/", fi), stringsAsFactors = FALSE)
    plausibility_checks[[dir]][[fi]] <- verify_quantile_forecasts(entry_temp)
  }
}
