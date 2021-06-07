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







# plot case outliers
case_outliers <- read_sheet(
  ss = "https://docs.google.com/spreadsheets/d/1Vw1Oakr-KdLB8RJoZNF7u6MRXMzg6iSJLpT_PpaKi2Y/edit#gid=799534143",
  range = "cases"
) %>%
  dplyr::mutate(
    date = as.Date(date),
    issue_date = as.Date(issue_date)
  )

case_outliers <- case_outliers %>%
  dplyr::mutate(
    reviewer_marked = dplyr::case_when(
      outlier_reviewer1 & outlier_reviewer2 ~ paste(reviewer1, reviewer2, sep = " and "),
      outlier_reviewer1 ~ reviewer1,
      outlier_reviewer2 ~ reviewer2
    )
  )

outlier_location_issues_case <- case_outliers %>%
  distinct(location, location_name, issue_date) %>%
  arrange(location, location_name, issue_date)

pdf("case_outliers.pdf", width = 14, height = 10)
for (i in seq_len(nrow(outlier_location_issues_case))) {
  message(i)
  data <- covidData::load_data(
    as_of = outlier_location_issues_case$issue_date[i],
    spatial_resolution = ifelse(outlier_location_issues_case$location[i] == "US", "national", "state"),
    temporal_resolution = "weekly",
    measure = "cases"
  ) %>%
    dplyr::filter(location == outlier_location_issues_case$location[i])
  
  outliers_to_plot_case <- case_outliers %>%
    filter(
      location == outlier_location_issues_case$location[i],
      issue_date == outlier_location_issues_case$issue_date[i]
    )
  
  p <- ggplot() +
    geom_line(data = data, mapping = aes(x = date, y = inc)) +
    geom_point(
      data = outliers_to_plot_case %>%
        tidyr::pivot_longer(c("reported_inc", "imputed_inc"), names_to = "type", values_to = "inc"),
      mapping = aes(x = date, y = inc, color = reviewer_marked, shape = type), size = 3) +
    scale_color_viridis_d(
      breaks = unique(case_outliers$reviewer_marked),
      option = "plasma",
      end = 0.8) +
    scale_x_date(
      breaks = data %>%
        dplyr::filter(weekdays(date) == "Saturday") %>%
        dplyr::pull(date) %>%
        unique(),
      limits = c(as.Date("2020-01-01"), as.Date("2021-04-04"))) +
    ggtitle(paste0(
      outlier_location_issues_case$location_name[i],
      ", issue date ",
      outlier_location_issues_case$issue_date[i])) +
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

hosp_outliers <- hosp_outliers %>%
  dplyr::mutate(
    reviewer_marked = dplyr::case_when(
      outlier_reviewer1 & outlier_reviewer2 ~ paste(reviewer1, reviewer2, sep = " and "),
      outlier_reviewer1 ~ reviewer1,
      outlier_reviewer2 ~ reviewer2
    )
  )

outlier_location_issues_hosp <- hosp_outliers %>%
  distinct(location, location_name, issue_date) %>%
  arrange(location, location_name, issue_date)

pdf("hosp_outliers.pdf", width = 14, height = 10)
for (i in seq_len(nrow(outlier_location_issues_hosp))) {
  data <- covidData::load_data(
    as_of = outlier_location_issues_hosp$issue_date[i],
    # spatial_resolution = ifelse(outlier_location_issues_hosp$location[i] == "US", "national", "state"),
    spatial_resolution = c("state", "national"),
    temporal_resolution = "daily",
    measure = "hospitalizations"
  ) %>%
    dplyr::filter(location == outlier_location_issues_hosp$location[i])
  
  
  outliers_dates_hosp <- hosp_outliers %>%
    filter(
      location == outlier_location_issues_hosp$location[i],
      issue_date == outlier_location_issues_hosp$issue_date[i]
    ) %>%
    pull(date) %>%
   `-`(2)
   
  outliers_to_plot_hosp <- hosp_outliers %>%
    filter(
      location == outlier_location_issues_hosp$location[i],
      issue_date == outlier_location_issues_hosp$issue_date[i]
    )
  
  q <- ggplot() +
    geom_line(data = data, mapping = aes(x = date, y = inc)) +
    geom_point(
      data = outliers_to_plot_hosp %>%
        tidyr::pivot_longer(c("reported_inc", "imputed_inc"), names_to = "type", values_to = "inc"),
      mapping = aes(x = date, y = inc, color = reviewer_marked, shape = type), size = 3) +
    scale_color_viridis_d(
      breaks = unique(hosp_outliers$reviewer_marked),
      option = "plasma",
      end = 0.8) +
    scale_x_date(
      breaks = data %>%
        dplyr::filter(weekdays(date) == "Saturday") %>%
        dplyr::pull(date) %>%
        unique(),
      limits = c(as.Date("2020-01-01"), as.Date("2021-04-04"))) +
    ggtitle(paste0(
      outlier_location_issues_hosp$location_name[i],
      ", issue date ",
      outlier_location_issues_hosp$issue_date[i])) +
    theme_bw() +
    theme(
      axis.text.x = element_text(angle = 90, vjust = 0.5),
      panel.grid.major.x = element_line(colour = "darkgrey")
    )
  print(q)
}
dev.off()
