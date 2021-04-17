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

outlier_location_issues <- death_outliers %>%
  distinct(location, location_name, issue_date) %>%
  arrange(location, location_name, issue_date)

pdf("death_outliers.pdf", width=14, height=10)
for (i in seq_len(nrow(outlier_location_issues))) {
  data <- covidData::load_data(
    as_of = outlier_location_issues$issue_date[i],
    spatial_resolution = ifelse(outlier_location_issues$location[i] == "US", "national", "state"),
    temporal_resolution = "weekly",
    measure = "deaths"
  ) %>%
    dplyr::filter(location == outlier_location_issues$location[i])
  
  outliers_dates <- death_outliers %>%
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
