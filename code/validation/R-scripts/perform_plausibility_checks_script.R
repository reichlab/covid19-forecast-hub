source("code/validation/R-scripts/functions_plausibility.R")

### THESE CODES ARE NO LONGER MAINTAINED OR KEPT IN SYNC WITH THE AUTORITATIVE PYTHON CHECKS
### THEY ARE KEPT HERE MERELY AS A RESSOURCE FOR TEAMS SPECIALIZING IN R.

# make sure locale is English US
Sys.setlocale(category = "LC_TIME", locale = "en_US.UTF8")

directories <- list.dirs("data-processed")[-1]

plausibility_checks <- list()

for(dir in directories){
  plausibility_checks[[dir]] <- validate_directory(dir)
}
