## reformat Imperial forecasts
## Nicholas Reich
## April 2020

library(tidyverse)

source("code/processing-fxns/process_imperial_file.R")

## this reads in an RDS file provided by the Imperial team  on April 11
ens_preds <- readRDS("./data-raw/Imperial/20200503-ensemble_model_predictions.rds")
forecast_date = as.Date("2020-05-03")

## the object is a big list, with one element for each of the 5 times forecasts were made
## each of those elements is itself a list, with one element for each country
## each of the country-specific items is a list with two ensemble forecasts, one for each serial interval assumption
## each forecast itself is a matrix with rows as samples (30K) and columns representing days in the future

## this code produces the mean predicted incident deaths for seven day-ahead
## colMeans(ens_preds$`2020-04-05`$United_States_of_America[[1]])


## transform and write the files for each date
ensemble1_output <- process_imperial_file(
    ens_preds[[as.character(forecast_date)]]$United_States_of_America[[1]],
    location="US",
    timezero=forecast_date)
ensemble2_output <- process_imperial_file(
    ens_preds[[as.character(forecast_date)]]$United_States_of_America[[2]],
    location="US",
    timezero=forecast_date)
write_csv(ensemble1_output,
    path = paste0("data-processed/Imperial-ensemble1/", forecast_date,"-Imperial-ensemble1.csv"))
write_csv(ensemble2_output,
    path = paste0("data-processed/Imperial-ensemble2/", forecast_date,"-Imperial-ensemble2.csv"))

