## get data for ensemble summaries

library(zoltr) ## devtools::install_github("reichlab/zoltr")
library(tidyverse)
theme_set(theme_bw())

## load special functions
source("code/processing-fxns/get_next_saturday.R")
source("code/exploration/get_zoltar_PI.R")

this_ensemble_timezero <- as.character(get_next_saturday(Sys.Date())-5)
target_end_dates <- get_next_saturday(this_ensemble_timezero)+7*c(0:3)

## connect to Zoltar
zoltar_connection <- new_connection()
zoltar_authenticate(zoltar_connection, Sys.getenv("Z_USERNAME"), Sys.getenv("Z_PASSWORD"))

## construct Zoltar query
project_url <- "https://www.zoltardata.com/api/project/44/"
list_query <- list(
    "models" = list("ensemble"),
    "timezeros" = as.list(this_ensemble_timezero),
    "targets" = as.list(c(paste(1:4, "wk ahead inc death"), paste(1:4, "wk ahead cum death")))
)
zoltar_query <- zoltr::query_with_ids(zoltar_connection, project_url, list_query)

# submit query
job_url <- zoltr::submit_query(zoltar_connection, project_url, zoltar_query)

## extract query data
tmp <- job_data(zoltar_connection, job_url)

inc_deaths <- paste(1:4, "wk ahead inc death")
cum_deaths <- paste(1:4, "wk ahead cum death")

get_zoltar_PI(tmp, this_ensemble_timezero, targets = cum_deaths, location = "US", alpha = .1)
get_zoltar_PI(tmp, this_ensemble_timezero, targets = inc_deaths, location = 25, alpha = .1)
get_zoltar_PI(tmp, this_ensemble_timezero, targets = cum_deaths, location = 25, alpha = .5)

