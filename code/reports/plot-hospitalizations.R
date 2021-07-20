#' Plot hospitalization forecasts and truth data, 
#' faceted for ensemble with quantiles and point forecasts for all other models
#' with additional plots that show a close-up of forecasts for both larger figures
#'
#' @param location string for US fips code, location name, or abbreviation
#' Defaults to 'US', must have a geo_type of "state", can only take a single location
#'
#' @return ggplot with two facets of most recent forecasts and truth data, with close-up of forecasts
#' @export
#'
#' @examples plot_hospitalization_forecasts("48"), plot_hospitalization_forecasts("Texas"), plot_hospitalization_forecasts("tx")
#' 
plot_hospitalization_forecasts <- function(location = "US") {
  library(tidyverse)
  library(dplyr)
  library(covidHubUtils)
  library(lubridate)
  library(cowplot)
  library(patchwork)
  
  theme_set(theme_bw())
  
  forecast_date <- lubridate::floor_date(Sys.Date(), "week", week_start = 2)
  loc_frame <- covidHubUtils::hub_locations
  loc_info <- loc_frame %>%
    filter(geo_type == "state") %>%
    filter_all(any_vars(str_starts(., fixed(location, ignore_case = TRUE)) & 
                          str_ends(., fixed(location, ignore_case = TRUE))))
  
  if(nrow(loc_info) == 0)
    stop("Please enter a valid state name, abbreviation, or fips code.")
  
  fdat <- load_latest_forecasts(
    locations = loc_info$fips,
    targets = paste(1:31, "day ahead inc hosp"),
    last_forecast_date = forecast_date,
    forecast_date_window_size = 6,
    source = "zoltar")
  
  truth <- load_truth("HealthData", 
                      "inc hosp", 
                      temporal_resolution="weekly",
                      locations = loc_info$fips,
                      data_location = "remote_hub_repo")
  
  
  # determine x limits for zoomed-in figures
  start_date <- forecast_date %m-% months(1)
  end_date <- forecast_date %m+% months(1)
  
  # determine y limits for zoomed-in figures
  ensemble_max <- fdat %>% 
    filter(model=="COVIDhub-ensemble", 
           type=="quantile", quantile==0.975, 
           target_end_date >= forecast_date %m-% months(1)) %>% 
    pull(value) %>% max(.)
  
  models_max <- fdat %>% 
    filter(type=="point", target_end_date >= start_date) %>% 
    pull(value) %>% max(.)
  
  overall_max <- max(ensemble_max, models_max)*1.1
  
  
  p1 <- plot_forecasts(filter(fdat, model=="COVIDhub-ensemble"), 
                       target_variable = "inc hosp",
                       truth_source="HealthData", 
                       subtitle = "none", 
                       show_caption=FALSE) + 
    scale_x_date(name=NULL, date_breaks = "1 month", 
                 date_labels = "%b '%y", 
                 limits=c(as.Date("2020-07-01"), forecast_date+32), 
                 expand = expansion(mult=c(0.02,0.02))) + 
    ylim(c(0, NA)) +
    theme(axis.ticks.length.x = unit(0.5, "cm"),  
          axis.text.x = element_text(vjust = 7, hjust = -0.2),
          legend.position = "none",
          plot.title = element_blank())
  
  
  
  p2 <- plot_forecasts(filter(fdat, !(model %in% c("COVIDhub-ensemble", "COVIDhub-trained_ensemble"))), 
                       target_variable = "inc hosp", 
                       truth_source="HealthData", 
                       subtitle = "none", 
                       title = "none",
                       show_caption=FALSE,
                       fill_by_model = TRUE, fill_transparency = .3,
                       intervals=NULL) + 
    scale_x_date(name=NULL, date_breaks = "1 month", 
                 date_labels = "%b '%y", 
                 limits=c(as.Date("2020-07-01"), forecast_date+32), 
                 expand = expansion(mult=c(0.02,0.02))) + 
    theme(axis.ticks.length.x = unit(0.5, "cm"),  
          axis.text.x = element_text(vjust = 7, hjust = -0.2),
          legend.position = "none",
          plot.title = element_blank())
  
  
  # zoomed-in figures
  p1_zoomed <- p1 + 
    coord_cartesian(ylim = c(0, overall_max)) +
    scale_x_date(name=NULL, 
                 date_breaks = "1 month", 
                 date_labels = "%b '%y", 
                 limits = c(start_date, end_date)) + 
    theme(axis.title.y = element_blank(), plot.title = element_blank())
  
  p2_zoomed <- p2 + 
    coord_cartesian(ylim = c(0, overall_max)) +
    scale_x_date(name=NULL, 
                 date_breaks = "1 month", 
                 date_labels = "%b '%y", 
                 limits = c(start_date, end_date)) + 
    theme(axis.title.y = element_blank(), plot.title = element_blank())
  
  # add box to show zoomed-in area
  p1_box <- 
    p1 +
    geom_rect(
      xmin = start_date,
      ymin = 0,
      xmax = end_date,
      ymax = overall_max,
      fill = NA, 
      colour = "black",
      size = 0.6
    )
  
  p2_box <- 
    p2 +
    geom_rect(
      xmin = start_date,
      ymin = 0,
      xmax = end_date,
      ymax = overall_max,
      fill = NA, 
      colour = "black",
      size = 0.6
    )
  
  # plot all four graphs
  p1_box + p1_zoomed + p2_box + p2_zoomed + 
    plot_layout(widths = c(2, 1)) + 
    plot_annotation(paste("Daily COVID-19 Inc Hosp (observed and forecasted):", 
                          paste(loc_info$location_name, Sys.Date())))
}
