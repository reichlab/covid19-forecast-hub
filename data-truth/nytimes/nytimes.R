# Download and format nytimes data
# Jarad Niemi
# May 2020

library("readr")
library("dplyr")

us_url     <- "https://raw.githubusercontent.com/nytimes/covid-19-data/master/us.csv"
states_url <- "https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv"
counties_url <- "https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv"
relative_path <- "./data-truth/nytimes/"

us <- readr::read_csv(us_url,
                      col_types = readr::cols(
                        date   = readr::col_date(format = "%Y-%m-%d"),
                        cases  = readr::col_integer(),
                        deaths = readr::col_integer()
                      )) 

states <- readr::read_csv(states_url,
                          col_types = readr::cols(
                            date   = readr::col_date(format = "%Y-%m-%d"),
                            state  = readr::col_character(),
                            fips   = readr::col_character(),
                            cases  = readr::col_integer(),
                            deaths = readr::col_integer()
                          )) 

counties <- readr::read_csv(counties_url,
                            col_types = readr::cols(
                              date   = readr::col_date(format = "%Y-%m-%d"),
                              county = readr::col_character(),
                              state  = readr::col_character(),
                              fips   = readr::col_character(),
                              cases  = readr::col_integer(),
                              deaths = readr::col_integer()
                            )) 

readr::write_csv(us,       path = paste0(relative_path,"raw/us.csv"))
readr::write_csv(states,   path = paste0(relative_path,"raw/us-states.csv"))
readr::write_csv(counties, path = paste0(relative_path,"raw/us-counties.csv"))

d <- us %>%
  dplyr::mutate(location = "US") %>%
  dplyr::bind_rows(states %>% 
                     dplyr::rename(location = fips) %>%
                     dplyr::select(-state)
  ) %>%
  dplyr::bind_rows(counties %>%
                     dplyr::rename(location = fips) %>%
                     dplyr::select(-state, -county)
  ) %>%
  dplyr::group_by(location) %>%
  dplyr::arrange(date) %>%
  dplyr::mutate(
    inc_deaths = as.integer(diff(c(0, deaths))),
    inc_cases  = as.integer(diff(c(0, cases )))) %>%
  dplyr::arrange(location, date) 


readr::write_csv(
  d %>% dplyr::select(date, location, deaths) %>% dplyr::rename(value = deaths),
  path = paste0(relative_path,"truth_nytimes-Cumulative Deaths.csv"))

readr::write_csv(
  d %>% dplyr::select(date, location, cases) %>% dplyr::rename(value = cases),
  path = paste0(relative_path,"truth_nytimes-Cumulative Cases.csv"))

readr::write_csv(
  d %>% dplyr::select(date, location, inc_deaths) %>% dplyr::rename(value = inc_deaths),
  path = paste0(relative_path,"truth_nytimes-Incident Deaths.csv"))

readr::write_csv(
  d %>% dplyr::select(date, location, inc_cases) %>% dplyr::rename(value = inc_cases),
  path = paste0(relative_path,"truth_nytimes-Incident Cases.csv"))
