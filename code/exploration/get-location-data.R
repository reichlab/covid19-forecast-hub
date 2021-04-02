## script to download forecasts for a particular location

library(zoltr) ## devtools::install_github("reichlab/zoltr")
library(tidyverse)

## load special functions
source("code/processing-fxns/get_next_saturday.R")

## connect to Zoltar, requires an account: 
## https://docs.google.com/forms/d/1C7IEFbBEJ1JibG-svM5XbnnKkgwvH0770LYILDjBxUc/viewform?edit_requested=true
zoltar_connection <- new_connection()
zoltar_authenticate(zoltar_connection, Sys.getenv("Z_USERNAME"), Sys.getenv("Z_PASSWORD"))

## construct Zoltar query
project_url <- "https://www.zoltardata.com/api/project/44/"
list_query <- list(
    ## specifies only the ensemble model
    "models" = list("ensemble"),
    ## specifies the Puerto Rico FIPS code
    "units" = as.list("72"),
    ## specifies all "forecast dates" for which to retrieve forecasts
    ## see forecast_date definition and relationship to targets here: 
    ##    https://github.com/reichlab/covid19-forecast-hub/tree/master/data-processed#forecast_date
    ## to ensure that you have all forecasts whose "1 wk ahead" forecasts end on the same date, 
    ##   you want to always ask for forecasts from a Tuesday through a Monday
    ## most forecasts come in with a forecast date of Sunday or Monday
    "timezeros" = list("2020-07-19", "2020-07-20")#,
    #"types" = list("point", "quantile")
)
zoltar_query <- zoltr::query_with_ids(zoltar_connection, project_url, list_query)

# submit query
job_url <- zoltr::submit_query(zoltar_connection, project_url, zoltar_query)

## extract query data
tmp <- job_data(zoltar_connection, job_url)

saveRDS(tmp, "PR-forecast-data.rds")
