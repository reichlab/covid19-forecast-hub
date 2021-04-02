## get data for ensemble summaries

library(zoltr) ## devtools::install_github("reichlab/zoltr")
library(tidyverse)
theme_set(theme_bw())

## load special functions
source("code/processing-fxns/get_next_saturday.R")
source("code/exploration/get_zoltar_PI.R")

this_ensemble_timezero <- as.character(get_next_saturday(Sys.Date())-5)
target_end_dates <- get_next_saturday(this_ensemble_timezero)+7*c(0:3)

inc_death_targets <- paste(1:4, "wk ahead inc death")
cum_death_targets <- paste(1:4, "wk ahead cum death")

## connect to Zoltar
zoltar_connection <- new_connection()
zoltar_authenticate(zoltar_connection, Sys.getenv("Z_USERNAME"), Sys.getenv("Z_PASSWORD"))

## construct Zoltar query
project_url <- "https://www.zoltardata.com/api/project/44/"

# submit query
dat <- do_zoltar_query(
    zoltar_connection, project_url, 
    model_abbrs = "COVIDhub-ensemble",
    targets = c(inc_death_targets, cum_death_targets),
    timezeros = this_ensemble_timezero,
    types = c("point", "quantile"))


get_zoltar_PI(dat, this_ensemble_timezero, targets = cum_death_targets, location = "US", alpha = .1)
get_zoltar_PI(dat, this_ensemble_timezero, targets = inc_death_targets, location = 25, alpha = .1)
get_zoltar_PI(dat, this_ensemble_timezero, targets = cum_death_targets, location = 25, alpha = .5)

