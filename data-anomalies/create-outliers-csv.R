library("googlesheets4")
library(tidyverse)
library(here)
setwd(here())

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



##################################################################################
# collect all required data up front to reduce number of calls to load_data
##################################################################################

# deaths
measure <- "deaths"

# vector of all as_of dates
death_as_ofs <- seq.Date(
  from = first_as_of_dates %>%
    dplyr::filter(measure == UQ(measure)) %>%
    dplyr::pull(first_as_of_date),
  to = most_recent_sunday,
  by = 7
)
temporal_resolution <- "weekly"
deaths_all_locations <- purrr::map_dfr(
  death_as_ofs, # used for as_of argument to covidData::load_data
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

# cases
measure <- "cases"
# vector of all as_of dates to plot
cases_as_ofs <- seq.Date(
  from = first_as_of_dates %>%
    dplyr::filter(measure == UQ(measure)) %>%
    dplyr::pull(first_as_of_date),
  to = most_recent_sunday,
  by = 7
)
temporal_resolution <- "weekly"
cases_all_locations <- purrr::map_dfr(
  cases_as_ofs, # used for as_of argument to covidData::load_data
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

# hospitalizations
measure <- "hospitalizations"

# vector of all as_of dates to plot
hosps_as_ofs <- seq.Date(
  from = first_as_of_dates %>%
    dplyr::filter(measure == UQ(measure)) %>%
    dplyr::pull(first_as_of_date),
  to = most_recent_sunday,
  by = 1
)

temporal_resolution <- "daily"

hosps_all_locations <- purrr::map_dfr(
  hosps_as_ofs, # used for as_of argument to covidData::load_data
  function(as_of) {
    covidData::load_data(
      spatial_resolution = c("state", "national"),
      temporal_resolution = temporal_resolution,
      measure = measure
    ) %>%
      dplyr::mutate(
        as_of = as_of
      )
  }
)

###############################################
# Combine annotations from individual reviewers
###############################################

combine_annotations <- function(measure) {
  reviewer1 <- read_sheet(
    ss = "https://docs.google.com/spreadsheets/d/1Vw1Oakr-KdLB8RJoZNF7u6MRXMzg6iSJLpT_PpaKi2Y/edit#gid=799534143",
    range = paste0(measure, "_reviewer1"))
  reviewer2 <- read_sheet(
    ss = "https://docs.google.com/spreadsheets/d/1Vw1Oakr-KdLB8RJoZNF7u6MRXMzg6iSJLpT_PpaKi2Y/edit#gid=799534143",
    range = paste0(measure, "_reviewer2"))

  combined <- dplyr::full_join(
    reviewer1 %>%
      dplyr::transmute(
        location_abbreviation,
        date = as.Date(outlier_date),
        issue_date = as.Date(issue_date),
        reviewer1 = reviewer_initials,
        comments_reviewer1 = comments),
    reviewer2 %>%
      dplyr::transmute(
        location_abbreviation,
        date = as.Date(outlier_date),
        issue_date = as.Date(issue_date),
        reviewer2 = reviewer_initials,
        comments_reviewer2 = comments),
    by = c("location_abbreviation", "date", "issue_date")) %>%
    dplyr::transmute(
      location_abbreviation,
      date,
      issue_date,
      reviewers_marked_outlier = ifelse(
        !is.na(reviewer1) & !is.na(reviewer2),
        paste(reviewer1, reviewer2, sep = ";"),
        ifelse(
          !is.na(reviewer1),
          reviewer1,
          reviewer2
        )
      ),
      num_reviewers_marked_oulier = as.numeric(!is.na(reviewer1)) + as.numeric(!is.na(reviewer2)),
      comments_reviewer1,
      comments_reviewer2
    ) %>%
    dplyr::left_join(
      covidData::fips_codes %>% select(location, abbreviation),
      by = c("location_abbreviation" = "abbreviation")
    )

  if (measure == "cases") {
    data_all_locations <- cases_all_locations
  } else if (measure == "hosps") {
    data_all_locations <- hosps_all_locations
  } else if (measure == "deaths") {
    data_all_locations <- deaths_all_locations
  }

  # get imputed values for data that were marked as outliers by any reviewer
  data_imputed <- purrr::pmap_dfr(
    combined %>% dplyr::distinct(location, issue_date),
    function(location, issue_date) {
      loc_issue_data <- data_all_locations %>%
        dplyr::filter(
          location == UQ(location),
          as_of == UQ(issue_date))
      outlier_dates <- combined %>%
        dplyr::filter(
          location == UQ(location),
          issue_date == UQ(issue_date)) %>%
        dplyr::pull(date)
      loc_issue_data$inc[loc_issue_data$date %in% outlier_dates] <- NA_integer_
      loc_issue_data %>%
        tidyr::fill(inc)
    }
  )

  # get information about size of outlier
  augmented_combined <- combined %>%
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
      relative_size = ifelse(imputed_inc == 0, reported_inc, absolute_size / imputed_inc)
    ) %>%
    dplyr::select(
      location, location_abbreviation, date, issue_date,
      reported_inc, imputed_inc, absolute_size, relative_size,
      reviewers_marked_outlier, num_reviewers_marked_oulier, comments_reviewer1,
      comments_reviewer2
    )

  write_sheet(
    augmented_combined,
    ss = "https://docs.google.com/spreadsheets/d/1Vw1Oakr-KdLB8RJoZNF7u6MRXMzg6iSJLpT_PpaKi2Y/edit#gid=799534143",
    sheet = measure
  )

  write.csv(
    augmented_combined,
    paste0('data-anomalies/outliers-inc-', measure, '.csv')
  )
}

if (!interactive()) {
  # This works... if you have a service account token...
  gs4_auth(path = "/path/to/your/service-account-token.json")
}

combine_annotations("cases")
combine_annotations("hosps")
combine_annotations("deaths")
