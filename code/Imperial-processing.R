## reformat Imperial forecasts
## Nicholas Reich
## April 2020

library(tidyverse)

source("code/process_imperial_file.R")

## this reads in an RDS file provided by the Imperial team  on April 11
ens_preds <- readRDS("./data-raw/Imperial/20200412-ensemble_model_predictions.rds")

## the object is a big list, with one element for each of the 5 times forecasts were made
## each of those elements is itself a list, with one element for each country
## each of the country-specific items is a list with two ensemble forecasts, one for each serial interval assumption
## each forecast itself is a matrix with rows as samples (30K) and columns representing days in the future

## this code produces the mean predicted incident deaths for seven day-ahead
colMeans(ens_preds$`2020-04-12`$United_States_of_America[[1]])

## align forecast dates with timezeros
imperial_forecast_dates <- tibble(
    #raw_forecast_date = seq.Date(as.Date("2020-03-15"), by="1 week", length.out = 4),
    raw_forecast_date = as.Date("2020-04-12"),
    timezero = raw_forecast_date + 1
)
write_csv(imperial_forecast_dates, "data-processed/Imperial-ensemble1/Imperial-forecast-dates.csv")
write_csv(imperial_forecast_dates, "data-processed/Imperial-ensemble2/Imperial-forecast-dates.csv")

## transform and write the files for each date
for(i in 1:nrow(imperial_forecast_dates)){
    ensemble1_output <- process_imperial_file(
        ens_preds[[as.character(imperial_forecast_dates$raw_forecast_date[i])]]$United_States_of_America[[1]], 
        location="US", 
        timezero=imperial_forecast_dates$timezero[i])
    ensemble2_output <- process_imperial_file(
        ens_preds[[as.character(imperial_forecast_dates$raw_forecast_date[i])]]$United_States_of_America[[2]], 
        location="US", 
        timezero=imperial_forecast_dates$timezero[i])
    write_csv(ensemble1_output, 
        path = paste0("data-processed/Imperial-ensemble1/", imperial_forecast_dates$timezero[i],"-Imperial-ensemble1.csv"))
    write_csv(ensemble2_output, 
        path = paste0("data-processed/Imperial-ensemble2/", imperial_forecast_dates$timezero[i],"-Imperial-ensemble2.csv"))
}

