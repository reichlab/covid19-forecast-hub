library("googlesheets4")
library(tidyverse)
library(covidData)

death_outliers <- read_sheet(
  ss = "https://docs.google.com/spreadsheets/d/1Vw1Oakr-KdLB8RJoZNF7u6MRXMzg6iSJLpT_PpaKi2Y/edit#gid=799534143",
  range = "deaths"
) %>%
  dplyr::mutate(
    date = as.Date(date),
    issue_date = as.Date(issue_date)
  )

death_outliers <- death_outliers %>%
  dplyr::mutate(
    reviewer_marked = dplyr::case_when(
      outlier_reviewer1 & outlier_reviewer2 ~ paste(reviewer1, reviewer2, sep = " and "),
      outlier_reviewer1 ~ reviewer1,
      outlier_reviewer2 ~ reviewer2
    )
  )

outlier_location_issues <- death_outliers %>%
  distinct(location, location_name, issue_date) %>%
  arrange(location, location_name, issue_date)

pdf("death_outliers.pdf", width = 14, height = 10)
for (i in seq_len(nrow(outlier_location_issues))) {
  message(i)
  data <- covidData::load_data(
    as_of = outlier_location_issues$issue_date[i],
    spatial_resolution = ifelse(outlier_location_issues$location[i] == "US", "national", "state"),
    temporal_resolution = "weekly",
    measure = "deaths"
  ) %>%
    dplyr::filter(location == outlier_location_issues$location[i])

  outliers_to_plot <- death_outliers %>%
    filter(
      location == outlier_location_issues$location[i],
      issue_date == outlier_location_issues$issue_date[i]
    )

  p <- ggplot() +
    geom_line(data = data, mapping = aes(x = date, y = inc)) +
    geom_point(
      data = outliers_to_plot %>%
        tidyr::pivot_longer(c("reported_inc", "imputed_inc"), names_to = "type", values_to = "inc"),
      mapping = aes(x = date, y = inc, color = reviewer_marked, shape = type), size = 3) +
    scale_color_viridis_d(
      breaks = unique(death_outliers$reviewer_marked),
      option = "plasma",
      end = 0.8) +
    scale_x_date(
      breaks = data %>%
        dplyr::filter(weekdays(date) == "Saturday") %>%
        dplyr::pull(date) %>%
        unique(),
      limits = c(as.Date("2020-01-01"), as.Date("2021-04-04"))) +
    ggtitle(paste0(
      outlier_location_issues$location_name[i],
      ", issue date ",
      outlier_location_issues$issue_date[i])) +
    theme_bw() +
    theme(
      axis.text.x = element_text(angle = 90, vjust = 0.5),
      panel.grid.major.x = element_line(colour = "darkgrey")
    )
  print(p)
}
dev.off()



hosp_outliers <- read_sheet(
  ss = "https://docs.google.com/spreadsheets/d/1Vw1Oakr-KdLB8RJoZNF7u6MRXMzg6iSJLpT_PpaKi2Y/edit#gid=799534143",
  range = "hospitalizations"
) %>%
  dplyr::mutate(
    date = as.Date(date),
    issue_date = as.Date(issue_date)
  )

outlier_location_issues <- hosp_outliers %>%
  distinct(location, location_name, issue_date) %>%
  arrange(location, location_name, issue_date)

pdf("hosp_outliers.pdf", width = 14, height = 10)
for (i in seq_len(nrow(outlier_location_issues))) {
  data <- covidData::load_data(
    as_of = outlier_location_issues$issue_date[i],
    spatial_resolution = ifelse(outlier_location_issues$location[i] == "US", "national", "state"),
    temporal_resolution = "daily",
    measure = "hospitalizations"
  ) %>%
    dplyr::filter(location == outlier_location_issues$location[i])
  
  outliers_dates <- hosp_outliers %>%
    filter(
      location == outlier_location_issues$location[i],
      issue_date == outlier_location_issues$issue_date[i]
    ) %>%
    pull(date) %>%
    `-`(2)
  p <- ggplot() +
    geom_line(data = data, mapping = aes(x = date, y = inc)) +
    geom_point(
      data = data %>% filter(date %in% outliers_dates),
      mapping = aes(x = date, y = inc), color = "red", size = 3) +
    scale_x_date(limits = c(as.Date("2020-01-01"), as.Date("2021-03-08"))) +
    ggtitle(paste0(
      outlier_location_issues$location_name[i],
      ", issue date ",
      outlier_location_issues$issue_date[i])) +
    theme_bw()
  print(p)
}
dev.off()
