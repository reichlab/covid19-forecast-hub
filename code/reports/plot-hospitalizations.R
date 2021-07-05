library(tidyverse)
library(covidHubUtils)

library(cowplot)

library(patchwork)

theme_set(theme_bw())

forecast_date <- as.Date("2021-06-28") 

fdat <- load_latest_forecasts(
  locations = "US",
  targets = paste(1:31, "day ahead inc hosp"),
  last_forecast_date = forecast_date,
  forecast_date_window_size = 6,
  source = "zoltar")


p1 <- plot_forecasts(filter(fdat, model=="COVIDhub-ensemble"), 
               target_variable = "inc hosp", 
               truth_source="HealthData", 
               subtitle = "none", 
               show_caption=FALSE) + 
  scale_x_date(name=NULL, date_breaks = "1 month", date_labels = "%b '%y", limits=c(as.Date(NA), forecast_date+32), expand = expansion(mult=c(0.02,0.02))) + 
  ylim(c(0, NA)) +
  theme(axis.ticks.length.x = unit(0.5, "cm"),  
        axis.text.x = element_text(vjust = 7, hjust = -0.2),
        legend.position = "none")

p2 <- plot_forecasts(filter(fdat, !(model %in% c("COVIDhub-ensemble", "COVIDhub-trained_ensemble"))), 
               target_variable = "inc hosp", 
               truth_source="HealthData", 
               subtitle = "none", 
               title = "none",
               show_caption=FALSE,
               fill_by_model = TRUE, fill_transparency = .3,
               intervals=NULL) + 
  scale_x_date(name=NULL, date_breaks = "1 month", date_labels = "%b '%y", limits=c(as.Date(NA), forecast_date+32), expand = expansion(mult=c(0.02,0.02))) + 
  theme(axis.ticks.length.x = unit(0.5, "cm"),  
        axis.text.x = element_text(vjust = 7, hjust = -0.2),
        legend.position = "none")


plot_grid(p1, p2, ncol=1) # plot main two figures


p1_zoomed <- p1 + 
  coord_cartesian(ylim = c(-25, 3500)) +
  scale_x_date(name=NULL, date_breaks = "1 month", date_labels = "%b '%y", limits = c(as.Date("2021-06-01"), as.Date("2021-07-31"))) + 
  theme(axis.title.y = element_blank(), plot.title = element_blank())

p2_zoomed <- p2 + 
  coord_cartesian(ylim = c(-25, 3500)) +
  scale_x_date(name=NULL, date_breaks = "1 month", date_labels = "%b '%y", limits = c(as.Date("2021-06-01"), as.Date("2021-07-31"))) + 
  theme(axis.title.y = element_blank(), plot.title = element_blank())

# add box to show zoomed-in area
p1_box <- 
  p1 +
  geom_rect(
    xmin = as.Date("2021-06-01"),
    ymin = -25,
    xmax = as.Date("2021-07-31"),
    ymax = 3500,
    fill = NA, 
    colour = "black",
    size = 0.6
  )

p2_box <- 
  p2 +
  geom_rect(
    xmin = as.Date("2021-06-01"),
    ymin = -25,
    xmax = as.Date("2021-07-31"),
    ymax = 3500,
    fill = NA, 
    colour = "black",
    size = 0.6
  )

# plot all four graphs
p1_box + p1_zoomed + p2_box + p2_zoomed + 
  plot_layout(widths = c(2, 1))
