library(tidyverse)
library(covidData)
library(here)
setwd(here())

## note that this file depends on a recent successful covidData `make all`

## function to load one week of data for a particular target variable as of a certain date  
load_one_as_of <- function(as_of, target_var)
{
  # temporal resolution depends on target_var
  if (target_var == "hospitalizations") {
    temporal_resolution <- "daily"
  } else {
    temporal_resolution <- "weekly"
  }
  
  # spatial resolution depends on target_var
  if (target_var == "cases") {
    all_locations <- covidData::fips_codes %>%
      dplyr::pull(location)
    this_spatial_resolution <- c("county", "state", "national")
  } else {
    all_locations <- covidData::fips_codes %>%
      dplyr::filter(nchar(location) == 2) %>%
      dplyr::pull(location)
    this_spatial_resolution <- c("state", "national")
  }
  
  load_data(
    as_of = as_of,
    spatial_resolution = this_spatial_resolution,
    temporal_resolution = temporal_resolution,
    measure = target_var) %>%
    mutate(as_of = lubridate::ymd(as_of)) #add column listing as_of date
}

# define Sundays to use for as_of dates
most_recent_sunday <- lubridate::floor_date(Sys.Date(), unit = "week")

get_next_sunday <- function(csv, default, start_from_scratch = FALSE) {
  if (file.exists(csv) & !start_from_scratch) {
    suppressMessages(read_csv(csv)) %>% 
    summarise(max(issue_date))%>% 
    pull(1)
  } else {
    lubridate::ymd(default)
  }
}

first_case_as_of <- get_next_sunday("data-anomalies/revisions-inc-case.csv", "2020-04-26")

first_hosp_as_of <- get_next_sunday("data-anomalies/revisions-inc-hosp.csv", "2020-11-22")

first_death_as_of <- get_next_sunday("data-anomalies/revisions-inc-death.csv", "2020-04-26")

if (first_case_as_of <= most_recent_sunday) {

  case_as_ofs <- seq.Date(
    from = first_case_as_of,  
    to = most_recent_sunday,
    by = 7
  )

  weekly_inc_cases <- plyr::ldply(case_as_ofs,
    load_one_as_of,
    target_var = "cases")  #combine revisions into 1 dataframe

  case_revisions <- suppressMessages(purrr::map_dfr(
    case_as_ofs[-1], # remove first issue which has no earlier issues to revise 
    function(as_of) {
      updates <- weekly_inc_cases %>%
      dplyr::filter(as_of == UQ(as_of - 7)) %>%  ## filtering to only include last week's obs
      dplyr::select(-as_of, -cum) %>%
      dplyr::inner_join(                         ## joining this week's obs
        weekly_inc_cases %>%
        dplyr::filter(as_of == UQ(as_of)) %>%
        dplyr::select(-cum),
        by = c("location", "date")
      ) %>%
      dplyr::filter(inc.x != inc.y)              ## only keeping rows where obs are not the same
    }) %>%
  dplyr::left_join(covidData::fips_codes) %>%
  dplyr::rename(
    issue_date = as_of,
    orig_obs = inc.x,         ## inc.x comes from the df filtered to existing observations
    revised_obs = inc.y) %>%  ## inc.y comes from the df with most recent obs
  dplyr::mutate(
    real_diff = revised_obs - orig_obs,
    relative_diff = ifelse(
      orig_obs == 0,
      revised_obs,
      real_diff / abs(orig_obs))
  ) %>%
  dplyr::select(location, location_name, date, orig_obs, issue_date, real_diff, relative_diff)
)

write_csv(case_revisions, file="data-anomalies/revisions-inc-case.csv", append = TRUE)

}

if (first_death_as_of <= most_recent_sunday) {

  death_as_ofs <- seq.Date(
    from = first_death_as_of,
    to = most_recent_sunday,
    by = 7
  )


## get all data for each target_var
  weekly_inc_deaths <- plyr::ldply(death_as_ofs,
   load_one_as_of,
   target_var = "deaths")  #combine revisions into 1 dataframe


## identify and compute the revisions
  death_revisions <- suppressMessages(purrr::map_dfr(
    death_as_ofs[-1], # remove first issue which has no earlier issues to revise 
    function(as_of) {
      updates <- weekly_inc_deaths %>%
      dplyr::filter(as_of == UQ(as_of - 7)) %>%  ## filtering to only include last week's obs
      dplyr::select(-as_of, -cum) %>%
      dplyr::inner_join(                         ## joining this week's obs
        weekly_inc_deaths %>%
        dplyr::filter(as_of == UQ(as_of)) %>%
        dplyr::select(-cum),
        by = c("location", "date")
      ) %>%
      dplyr::filter(inc.x != inc.y)              ## only keeping rows where obs are not the same
    }) %>%
  dplyr::left_join(covidData::fips_codes) %>%
  dplyr::rename(
    issue_date = as_of,
    orig_obs = inc.x,         ## inc.x comes from the df filtered to existing observations
    revised_obs = inc.y) %>%  ## inc.y comes from the df with most recent obs
  dplyr::mutate(
    real_diff = revised_obs - orig_obs,
    relative_diff = ifelse(
      orig_obs == 0,
      revised_obs,
      real_diff / abs(orig_obs))
  ) %>%
  dplyr::select(location, location_name, date, orig_obs, issue_date, real_diff, relative_diff)
)

  write_csv(death_revisions, file="data-anomalies/revisions-inc-death.csv", append = TRUE)

}

if (first_hosp_as_of <= most_recent_sunday) {

  hosp_as_ofs <- seq.Date(
    from = first_hosp_as_of,
    to = most_recent_sunday,
    by = 7
  )

  daily_inc_hosps <- plyr::ldply(hosp_as_ofs,
   load_one_as_of,
   target_var = "hospitalizations")  #combine revisions into 1 dataframe


  hosp_revisions <- suppressMessages(purrr::map_dfr(
    hosp_as_ofs[-1], # remove first issue which has no earlier issues to revise 
    function(as_of) {
      updates <- daily_inc_hosps %>%
      dplyr::filter(as_of == UQ(as_of - 7)) %>%  ## filtering to only include last week's obs
      dplyr::select(-as_of, -cum) %>%
      dplyr::inner_join(                         ## joining this week's obs
        daily_inc_hosps %>%
        dplyr::filter(as_of == UQ(as_of)) %>%
        dplyr::select(-cum),
        by = c("location", "date")
      ) %>%
      dplyr::filter(inc.x != inc.y)              ## only keeping rows where obs are not the same
    }) %>%
  dplyr::left_join(covidData::fips_codes) %>%
  dplyr::rename(
    issue_date = as_of,
    orig_obs = inc.x,         ## inc.x comes from the df filtered to existing observations
    revised_obs = inc.y) %>%  ## inc.y comes from the df with most recent obs
  dplyr::mutate(
    real_diff = revised_obs - orig_obs,
    relative_diff = ifelse(
      orig_obs == 0,
      revised_obs,
      real_diff / abs(orig_obs))
  ) %>%
  dplyr::select(location, location_name, date, orig_obs, issue_date, real_diff, relative_diff)
)

  write_csv(hosp_revisions, file="data-anomalies/revisions-inc-hosp.csv", append = TRUE)

}








