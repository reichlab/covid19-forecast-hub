## reformat Imperial forecasts
## Nicholas Reich
## April 2020

library(tidyverse)

source("code/process_imperial_file.R")

## this reads in an RDS file provided by the Imperial team  on April 11
ens_preds <- readRDS("./data-raw/Imperial/20200405-ensemble_model_predictions.rds")

## the object is a big list, with one element for each of the 5 times forecasts were made
## each of those elements is itself a list, with one element for each country
## each of the country-specific items is a list with two ensemble forecasts, one for each serial interval assumption
## each forecast itself is a matrix with rows as samples (30K) and columns representing days in the future

## this code produces the mean predicted incident deaths for seven day-ahead
colMeans(ens_preds$`2020-04-05`$United_States_of_America[[1]])

## align forecast dates with timezeros
imperial_forecast_dates <- tibble(
    raw_forecast_date = seq.Date(as.Date("2020-03-15"), by="1 week", length.out = 6),
    timezero = raw_forecast_date + 1
)
write_csv(imperial_forecast_dates, "data-processed/Imperial-ensemble1/Imperial-forecast-dates.csv")
write_csv(imperial_forecast_dates, "data-processed/Imperial-ensemble2/Imperial-forecast-dates.csv")

## transform and write the files for each date
for(i in 1:nrow(imperial_forecast_dates)){
    ensemble1_output <- process_imperial_file(
        ens_preds[[as.character(imperial_forecast_dates$raw_forecast_date[i])]]$United_States_of_America[[1]], 
        location_id="US", 
        timezero=imperial_forecast_dates$raw_forecast_date[i])
    ensemble2_output <- process_imperial_file(
        ens_preds[[as.character(imperial_forecast_dates$raw_forecast_date[i])]]$United_States_of_America[[2]], 
        location_id="US", 
        timezero=imperial_forecast_dates$raw_forecast_date[i])
    write_csv(ensemble1_output, path = "data-processed/Imperial-ensemble1/2020-03-16-Imperial-ensemble1.csv")
    write_csv(ensemble2_output, path = "data-processed/Imperial-ensemble2/2020-03-16-Imperial-ensemble2.csv")
    
}

qntl_mdl_1_20200315 <- process_imperial_file(ens_preds$`2020-03-15`$United_States_of_America[[1]], location_id="US", timezero=)
qntl_mdl_2_20200315 <- process_imperial_file(ens_preds$`2020-03-15`$United_States_of_America[[2]], location_id="US")
write_csv(qntl_mdl_1_20200315, path = "data-processed/Imperial-ensemble1/2020-03-16-Imperial-ensemble1.csv")
write_csv(qntl_mdl_2_20200315, path = "data-processed/Imperial-ensemble2/2020-03-16-Imperial-ensemble2.csv")

qntl_mdl_1_20200322 <- process_imperial_file(ens_preds$`2020-03-22`$United_States_of_America[[1]], location_id="US")
qntl_mdl_2_20200322 <- process_imperial_file(ens_preds$`2020-03-22`$United_States_of_America[[2]], location_id="US")
write_csv(qntl_mdl_1_20200322, path = "data-processed/Imperial-ensemble1/2020-03-23-Imperial-ensemble1.csv")
write_csv(qntl_mdl_2_20200322, path = "data-processed/Imperial-ensemble2/2020-03-23-Imperial-ensemble2.csv")

qntl_mdl_1_20200329 <- process_imperial_file(ens_preds$`2020-03-29`$United_States_of_America[[1]], location_id="US")
qntl_mdl_2_20200329 <- process_imperial_file(ens_preds$`2020-03-29`$United_States_of_America[[2]], location_id="US")
write_csv(qntl_mdl_1_20200329, path = "data-processed/Imperial-ensemble1/2020-03-30-Imperial-ensemble1.csv")
write_csv(qntl_mdl_2_20200329, path = "data-processed/Imperial-ensemble2/2020-03-30-Imperial-ensemble2.csv")

qntl_mdl_1_20200405 <- process_imperial_file(ens_preds$`2020-04-05`$United_States_of_America[[1]], location_id="US")
qntl_mdl_2_20200405 <- process_imperial_file(ens_preds$`2020-04-05`$United_States_of_America[[2]], location_id="US")
write_csv(qntl_mdl_1_20200405, path = "data-processed/Imperial-ensemble1/2020-04-06-Imperial-ensemble1.csv")
write_csv(qntl_mdl_2_20200405, path = "data-processed/Imperial-ensemble2/2020-04-06-Imperial-ensemble2.csv")


