library("googlesheets4")
library(tidyverse)

start_deaths <- read_sheet(
  ss = "https://docs.google.com/spreadsheets/d/1Vw1Oakr-KdLB8RJoZNF7u6MRXMzg6iSJLpT_PpaKi2Y/edit#gid=799534143",
  range = "deaths_ELR"
)

inds_to_fill <- which(sapply(start_deaths$issue_date, typeof) == "character")

new_rows <- purrr::map_dfr(
  inds_to_fill,
  function(ind) {
    print(ind)
    base_row <- start_deaths[ind - 1, ]
    start_issue_date <- as.Date(base_row$issue_date[[1]])
    if (start_issue_date < "2021-03-08") {
      issue_dates <- seq(from = start_issue_date + 7, to = as.Date("2021-03-08"), by = 7)
      new_rows <- data.frame(
        location = NA_character_,
        location_name = base_row$location_name,
        date = as.Date(base_row$date),
        issue_date = issue_dates,
        relative_diff = NA,
        absolute_diff = NA
      )
      return(new_rows)
    }
  })

combined_deaths <- dplyr::bind_rows(
  start_deaths %>%
    dplyr::slice(-inds_to_fill) %>%
    dplyr::mutate(
      date = as.Date(date),
      issue_date = issue_date %>%
        purrr::map_chr(function(x) as.character(as.Date(x))) %>%
        as.Date()
    ),
  new_rows
)
combined_deaths <- combined_deaths %>%
  dplyr::select(-location) %>%
  dplyr::filter(!is.na(location_name)) %>%
  dplyr::left_join(
    covidData::fips_codes %>% select(location, abbreviation),
    by = c("location_name" = "abbreviation")
  ) %>%
  dplyr::arrange(location) %>%
  dplyr::relocate(location)

write_sheet(
  combined_deaths,
  ss = "https://docs.google.com/spreadsheets/d/1Vw1Oakr-KdLB8RJoZNF7u6MRXMzg6iSJLpT_PpaKi2Y/edit#gid=799534143",
  sheet = "deaths"
)
