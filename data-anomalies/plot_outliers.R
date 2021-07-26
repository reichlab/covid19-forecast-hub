library(tidyverse)
library(covidData)
library(here)
setwd(here())

most_recent_sunday <- lubridate::floor_date(Sys.Date(), unit = "week")

# plot death outliers
for (measure in c("cases", "deaths", "hosps")) {
  outliers <- readr::read_csv(
    paste0("data-anomalies/outliers-inc-", measure, ".csv")
  )

  if (measure == "hosps") {
    first_as_of_date <- as.Date("2020-11-22")
  } else {
    first_as_of_date <- as.Date("2020-04-26")
  }
  all_as_ofs <- seq.Date(
    from = first_as_of_date,
    to = most_recent_sunday,
    by = 7
  )

  data_all_as_ofs <- purrr::map_dfr(
    all_as_ofs,
    function(as_of) {
      covidData::load_data(
        as_of = as_of,
        spatial_resolution = c("national", "state"),
        temporal_resolution = ifelse(measure == "hosps", "daily", "weekly"),
        measure = ifelse(measure == "hosps", "hospitalizations", measure)
      ) %>%
        dplyr::mutate(as_of = as_of)
    }
  )

  location_issues <- tidyr::expand_grid(
    location = unique(outliers$location),
    as_of = all_as_ofs
  ) %>%
    dplyr::left_join(
      covidData::fips_codes %>%
        dplyr::select(location, location_name),
      by = "location")

  pdf(paste0("data-anomalies/outliers-inc-", measure, ".pdf"), width = 14, height = 10)
  for (i in seq_len(nrow(location_issues))) {
    message(i)
    data <- data_all_as_ofs %>%
      dplyr::filter(
        as_of == location_issues$as_of[i],
        location == location_issues$location[i])

    outliers_to_plot <- outliers %>%
      filter(
        location == location_issues$location[i],
        issue_date == location_issues$as_of[i]
      )

    p <- ggplot() +
      geom_line(data = data, mapping = aes(x = date, y = inc)) +
      geom_point(data = data, mapping = aes(x = date, y = inc)) +
      geom_point(
        data = outliers_to_plot %>%
          tidyr::pivot_longer(c("reported_inc", "imputed_inc"), names_to = "type", values_to = "inc"),
        mapping = aes(x = date, y = inc, color = factor(num_reviewers_marked_outlier), shape = type), size = 3) +
      scale_color_manual(
        breaks = c(1, 2),
        values = c("orange", "red")) +
      scale_x_date(
        breaks = data %>%
          dplyr::filter(weekdays(date) == "Saturday") %>%
          dplyr::pull(date) %>%
          unique(),
        limits = c(as.Date("2020-01-01"), as.Date(most_recent_sunday))) +
      ggtitle(paste0(
        location_issues$location_name[i],
        ", issue date ",
        location_issues$as_of[i])) +
      theme_bw() +
      theme(
        axis.text.x = element_text(angle = 90, vjust = 0.5),
        panel.grid.major.x = element_line(colour = "darkgrey")
      )
    print(p)
  }
  dev.off()
}
