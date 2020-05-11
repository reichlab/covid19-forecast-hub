source("code/validation/functions_plausibility.R")

# make sure locale is English US
Sys.setlocale(category = "LC_TIME", locale = "en_US.UTF8")

directories <- list.dirs("data-processed")[-1]

plausibility_checks <- list()

for(dir in directories){
  plausibility_checks[[dir]] <- validate_directory(dir)
}
