library(tidyverse)
library(covidData)
library(here)
setwd(here())

# do we want to plot historical data available as of all past weeks or only the
# most recent?
plot_all_historical_as_ofs <- TRUE

# plot historical records of cases, hospitalizations, and deaths using
# data available as of Sunday each week.
most_recent_sunday <- lubridate::floor_date(Sys.Date(), unit = "week")
if (plot_all_historical_as_ofs) {
  first_as_of_dates <- data.frame(
    measure = c("cases", "hospitalizations", "deaths"),
    first_as_of_date = as.Date(c("2020-04-26", "2020-11-22", "2020-04-26"))
  )
} else {
  first_as_of_dates <- data.frame(
    measure = c("cases", "hospitalizations", "deaths"),
    first_as_of_date = rep(most_recent_sunday, 3)
  )
}

# date ranges for plots
plot_start_date <- lubridate::ymd("2020-01-01")
plot_end_date <- most_recent_sunday

# locations to plot: state and national have 2 digit location codes
all_locations <- covidData::fips_codes %>%
  dplyr::filter(nchar(location) == 2) %>%
  dplyr::pull(location)

# make the plots
for (measure in c("cases", "hospitalizations", "deaths")) {
  # vector of all as_of dates to plot
  all_as_ofs <- seq.Date(
    from = first_as_of_dates %>%
      dplyr::filter(measure == UQ(measure)) %>%
      dplyr::pull(first_as_of_date),
    to = most_recent_sunday,
    by = 7
  )

  # temporal resolution depends on measure
  if (measure == "hospitalizations") {
    temporal_resolution <- "daily"
  } else {
    temporal_resolution <- "weekly"
  }

  # collect all required data up front to reduce number of calls to load_data
  data_all_locations <- purrr::map_dfr(
    all_as_ofs, # used for as_of argument to covidData::load_data
    function(as_of) {
      covidData::load_data(
        as_of = as_of,
        spatial_resolution = c("state", "national"),
        temporal_resolution = temporal_resolution,
        measure = measure
      ) %>%
        dplyr::mutate(
          as_of = as_of
        )
    }
  )

  pdf(paste0("data-truth/plots_", measure, ".pdf"), width = 14, height = 9)
  for (location in all_locations) {
    location_name <- covidData::fips_codes %>%
      dplyr::filter(location == UQ(location)) %>%
      dplyr::pull(location_name)

    for (as_of in as.character(all_as_ofs)) {
      message(paste0(location_name, ", ", as_of))
      data_to_plot <- data_all_locations %>%
        dplyr::filter(
          location == UQ(location),
          as_of == UQ(as_of),
          date >= plot_start_date)

      p <- ggplot() +
        geom_line(data = data_to_plot,
          mapping = aes(x = date, y = inc)) +
        scale_x_date(
          breaks = data_to_plot %>%
            dplyr::filter(weekdays(date) == "Saturday") %>%
            dplyr::pull(date) %>%
            unique(),
          minor_breaks = NULL,
          limits = c(plot_start_date, plot_end_date)) +
        ggtitle(paste0(location_name, " as of ", as_of)) +
        theme_bw() +
        theme(
          axis.text.x = element_text(angle = 90, vjust = 0.5),
          panel.grid.major.x = element_line(colour = "darkgrey")
        )

      print(p)
    }
  }
  dev.off()
}
