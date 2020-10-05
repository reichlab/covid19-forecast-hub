# COVID-19 Forecast Hub Shiny App

The shiny app is complementary to the COVID-19 Forecast Hub 
[Dashboard](https://reichlab.io/covid19-forecast-hub/).
These files are a work-in-progress version of the files in [data-processed/](../../data-processed).
For now, the data-processed/ files should be used.

Software requirements: R 4.0 or higher and the following packages:

    install.packages(c("tidyverse","data.table","R.utils","shiny","DT",
                       "shinyWidgets","ggnewscale","reshape2","drake","MMWRweek","scales","future"))

If you want to try out this new version of the shiny app you can use 
    
    future::plan(future::multiprocess)  
    drake::r_make("code/shiny/_drake.R") # this line can take over 10 minutes to run
    source("code/shiny/app.R")
    shinyApp(ui = ui, server = server) # if it doesn't automatically run
    
from the base folder of the repository.

If you would like to set default team and default model to Latest Viz in shiny app,
please add to ```.Rprofile``` and then restart R session

    shiny::shinyOptions(default_model_abbr = "default model_abbr")

Note: JHU New York City County truth is different from those from other sources because five boroughs in NYC were aggregated under “New York City.” For more information: please go to https://coronavirus.jhu.edu/us-map-faq

## Background

Originally the app was designed to be an internal tool for the COVID-19 Forecast
Hub team to know what forecast existed within the repository,
aid in the building of an ensemble forecast, 
and (quickly) visualize forecasts (before updating of the Dashboard). 

On May 15, the app was introduced to teams submitting forecasts and therefore
the user base is a lot wider than original intended. 

## Uses

The primary use of the app is for the COVID-19 Forecast Hub team to know what
forecasts are in the repository. Most of the shiny app tabs are aimed at this 
goal including the tabs All, Latest, Latest locations, Latest targets, and
Latest quantiles. These tabs all provide interactive access to data sets that 
provide details about the latest forecast for each model with the exception
of the "All" tab which has all of the forecasts for each model 
(not just the latest forecasts). 

The tab that is likely more helpful to teams is the "Latest viz" tab. 
This tab provides a visualization of all the teams forecasts similar to the
Dashboard, but with some slightly different features. 
This tab can be used to visualize forecasts before submitting those forecasts
to the Hub. 

