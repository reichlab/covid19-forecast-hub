## Code for plotting forecasts for a visual 

## you should make sure you install the latest version of covidHubUtils:
## remotes::install_github("reichlab/covidHubUtils")

library(covidHubUtils)

## plot inc death forecasts
forecast_data_deaths <- load_forecast_files_repo(file_paths = "data-processed/COVIDhub-ensemble/2021-02-15-COVIDhub-ensemble.csv",
                                                 targets = paste(1:4, "wk ahead inc death"))

plot_forecast(forecast_data_deaths, truth_source="JHU", 
              facet = .~location, facet_scales = "free_y") 


## plot inc cases forecasts
state_fips <- hub_locations[hub_locations$geo_type=="state", ]$fips

forecast_data_cases <- load_forecast_files_repo(file_paths = "data-processed/COVIDhub-ensemble/2021-02-15-COVIDhub-ensemble.csv",
                                                targets = paste(1:4, "wk ahead inc case"), 
                                                locations = state_fips)

plot_forecast(forecast_data_cases, truth_source="JHU", 
              facet = .~location, facet_scales = "free_y") 
