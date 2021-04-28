library("googlesheets4")
library(tidyverse)


# historical records of cases, hospitalizations, and deaths using
# data available as of Sunday each week.
most_recent_sunday <- lubridate::floor_date(Sys.Date(), unit = "week")
first_as_of_dates <- data.frame(
  measure = c("cases", "hospitalizations", "deaths"),
  first_as_of_date = as.Date(c("2020-04-26", "2020-11-22", "2020-04-26"))
)

# get data to use in measuring outlier size
# locations to include: state and national have 2 digit location codes
all_locations <- covidData::fips_codes %>%
  dplyr::filter(nchar(location) == 2) %>%
  dplyr::pull(location)

measure <- "deaths"
# vector of all as_of dates to plot
all_as_ofs <- seq.Date(
  from = first_as_of_dates %>%
    dplyr::filter(measure == UQ(measure)) %>%
    dplyr::pull(first_as_of_date),
  to = most_recent_sunday,
  by = 7
)

# collect all required data up front to reduce number of calls to load_data
temporal_resolution <- "weekly"
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

# clean death annotations from ELR
start_deaths_elr <- read_sheet(
  ss = "https://docs.google.com/spreadsheets/d/1Vw1Oakr-KdLB8RJoZNF7u6MRXMzg6iSJLpT_PpaKi2Y/edit#gid=799534143",
  range = "deaths_ELR"
)

inds_to_fill <- which(sapply(start_deaths_elr$issue_date, typeof) == "character")

new_rows <- purrr::map_dfr(
  inds_to_fill,
  function(ind) {
    print(ind)
    base_row <- start_deaths_elr[ind - 1, ]
    start_issue_date <- as.Date(base_row$issue_date[[1]])
    if (start_issue_date < "2021-04-04") {
      issue_dates <- seq(from = start_issue_date + 7, to = as.Date("2021-04-04"), by = 7)
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

deaths_elr <- dplyr::bind_rows(
  start_deaths_elr %>%
    dplyr::slice(-inds_to_fill) %>%
    dplyr::mutate(
      date = as.Date(date),
      issue_date = issue_date %>%
        purrr::map_chr(function(x) as.character(as.Date(x))) %>%
        as.Date()
    ),
  new_rows
) %>%
  dplyr::select(-location) %>%
  tidyr::fill(location_name) %>%
  dplyr::left_join(
    covidData::fips_codes %>% select(location, abbreviation),
    by = c("location_name" = "abbreviation")
  ) %>%
  dplyr::arrange(location) %>%
  dplyr::relocate(location)



start_deaths_mwz <- read_sheet(
  ss = "https://docs.google.com/spreadsheets/d/1Vw1Oakr-KdLB8RJoZNF7u6MRXMzg6iSJLpT_PpaKi2Y/edit#gid=799534143",
  range = "deaths_MWZ"
)
deaths_mwz <- start_deaths_mwz %>%
  dplyr::mutate(
    date = as.Date(date),
    issue_date = as.Date(issue_date)
  ) %>%
  dplyr::select(-location) %>%
  tidyr::fill(location_name) %>%
  dplyr::left_join(
    covidData::fips_codes %>% select(location, abbreviation),
    by = c("location_name" = "abbreviation")
  ) %>%
  dplyr::arrange(location) %>%
  dplyr::relocate(location)


combined_deaths <- dplyr::full_join(
  deaths_elr %>%
    dplyr::transmute(location, location_name, date, issue_date, outlier_reviewer1 = TRUE),
  deaths_mwz %>%
    dplyr::transmute(location, location_name, date, issue_date, outlier_reviewer2 = TRUE),
  by = c("location", "location_name", "date", "issue_date")
) %>%
  dplyr::mutate(
    reviewer1 = "ELR",
    reviewer2 = "MWZ",
    outlier_reviewer1 = !is.na(outlier_reviewer1),
    outlier_reviewer2 = !is.na(outlier_reviewer2)
  )

# get imputed values for data that were marked as outliers by any reviewer
data_imputed <- purrr::pmap_dfr(
  combined_deaths %>% dplyr::distinct(location, issue_date),
  function(location, issue_date) {
    loc_issue_data <- data_all_locations %>%
      dplyr::filter(
        location == UQ(location),
        as_of == UQ(issue_date))
    outlier_dates <- combined_deaths %>%
      dplyr::filter(location == UQ(location), issue_date == UQ(issue_date)) %>%
      dplyr::pull(date)
    loc_issue_data$inc[loc_issue_data$date %in% outlier_dates] <- NA_integer_
    loc_issue_data %>%
      tidyr::fill(inc)
  }
)

# get information about size of outlier
combined_deaths <- combined_deaths %>%
  dplyr::left_join(
    data_all_locations %>%
      dplyr::transmute(location, date, issue_date = as_of, reported_inc = inc),
    by = c("location", "date", "issue_date")
  ) %>%
  dplyr::left_join(
    data_imputed %>%
      dplyr::transmute(location, date, issue_date = as_of, imputed_inc = inc),
    by = c("location", "date", "issue_date")
  ) %>%
  dplyr::mutate(
    absolute_size = abs(reported_inc - imputed_inc),
    relative_size = absolute_size / imputed_inc
  )

write_sheet(
  combined_deaths,
  ss = "https://docs.google.com/spreadsheets/d/1Vw1Oakr-KdLB8RJoZNF7u6MRXMzg6iSJLpT_PpaKi2Y/edit#gid=799534143",
  sheet = "deaths"
)






# Process hospitalization annotations from APG
start_hosps_apg <- read_sheet(
  ss = "https://docs.google.com/spreadsheets/d/1Vw1Oakr-KdLB8RJoZNF7u6MRXMzg6iSJLpT_PpaKi2Y/edit#gid=799534143",
  range = "hospitalizations_APG"
)

inds_to_fill <- which(sapply(start_hosps_apg$issue_date, typeof) == "character")

new_rows <- purrr::map_dfr(
  inds_to_fill,
  function(ind) {
    print(ind)
    base_row <- start_hosps_apg[ind - 1, ]
    start_issue_date <- as.Date(base_row$issue_date[[1]])
    if (start_issue_date < "2021-04-04") {
      issue_dates <- seq(from = start_issue_date + 7, to = as.Date("2021-04-04"), by = 7)
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

hosps_apg <- dplyr::bind_rows(
  start_hosps_apg %>%
    dplyr::slice(-inds_to_fill) %>%
    dplyr::mutate(
      date = as.Date(date),
      issue_date = issue_date %>%
        purrr::map_chr(function(x) as.character(as.Date(x))) %>%
        as.Date()
    ),
  new_rows
)
hosps_apg <- hosps_apg %>%
  dplyr::select(-location) %>%
  dplyr::filter(!is.na(location_name)) %>%
  dplyr::left_join(
    covidData::fips_codes %>% select(location, abbreviation),
    by = c("location_name" = "abbreviation")
  ) %>%
  dplyr::arrange(location) %>%
  dplyr::relocate(location)


# Process hospitalization annotations from MWZ
start_hosps_mwz <- read_sheet(
  ss = "https://docs.google.com/spreadsheets/d/1Vw1Oakr-KdLB8RJoZNF7u6MRXMzg6iSJLpT_PpaKi2Y/edit#gid=799534143",
  range = "hospitalizations_MWZ"
)

hosps_mwz <- start_hosps_mwz
hosps_mwz$date <- purrr::map_chr(
  start_hosps_mwz$date,
  function(d) {
    if (is.character(d)) {
      substr(d, 1, nchar(d) - 1)
    } else {
      as.character(d)
    }
  }) %>%
  as.Date()
hosps_mwz$issue_date <- hosps_mwz$issue_date %>%
  purrr::map_chr(function(x) as.character(as.Date(x))) %>%
  as.Date()
hosps_mwz <- hosps_mwz %>%
  dplyr::select(-location) %>%
  tidyr::fill(location_name) %>%
  dplyr::left_join(
    covidData::fips_codes %>% select(location, abbreviation),
    by = c("location_name" = "abbreviation")
  ) %>%
  dplyr::arrange(location) %>%
  dplyr::relocate(location)

combined_hosps <- dplyr::bind_rows(hosps_apg, hosps_mwz) %>%
  dplyr::filter(date >= "2020-11-16") %>%
  dplyr::distinct(location, location_name, date, issue_date)


write_sheet(
  combined_hosps,
  ss = "https://docs.google.com/spreadsheets/d/1Vw1Oakr-KdLB8RJoZNF7u6MRXMzg6iSJLpT_PpaKi2Y/edit#gid=799534143",
  sheet = "hospitalizations"
)




