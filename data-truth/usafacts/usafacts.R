# Download and format usafacts data
# Jarad Niemi
# May 2020

library("tidyverse")

confirmed_url <- "https://usafactsstatic.blob.core.windows.net/public/data/covid-19/covid_confirmed_usafacts.csv"
deaths_url    <- "https://usafactsstatic.blob.core.windows.net/public/data/covid-19/covid_deaths_usafacts.csv"

cases <- readr::read_csv(confirmed_url,
                     col_types = readr::cols(
                       countyFIPS    = readr::col_integer(),
                       `County Name` = readr::col_character(),
                       State         = readr::col_character(),
                       stateFIPS     = readr::col_integer(),
                       .default      = readr::col_integer()
                     )) 

deaths <- readr::read_csv(deaths_url,
                          col_types = readr::cols(
                            countyFIPS    = readr::col_integer(),
                            `County Name` = readr::col_character(),
                            State         = readr::col_character(),
                            stateFIPS     = readr::col_integer(),
                            .default      = readr::col_integer()
                          ))
                          

readr::write_csv(cases,  path = "raw/covid_confirmed_usafacts.csv")
readr::write_csv(deaths, path = "raw/covid_deaths_usafacts.csv")


d <- cases %>% dplyr::mutate(cases_deaths = "case") %>%
  bind_rows(deaths %>% dplyr::mutate(cases_deaths = "death")) %>%
  
  dplyr::select(-countyFIPS, -`County Name`, -State) %>%
  dplyr::rename(location = stateFIPS) %>%
  dplyr::mutate(location = sprintf("%02d", location)) %>%
  tidyr::pivot_longer(
    -c(location, cases_deaths),
    names_to = "date",
    values_to = "cum"
  ) %>%
  dplyr::mutate(date = as.Date(date, format = "%m/%d/%y")) %>%
  
  # Calculate incident cases and deaths 
  # aggregated across counties within a state
  dplyr::group_by(location, cases_deaths, date) %>%
  dplyr::summarize(cum = sum(cum)) %>%
  dplyr::group_by(location, cases_deaths) %>%
  dplyr::arrange(date) %>%
  dplyr::mutate(inc = diff(c(0,cum))) %>%
  ungroup()
  
  

readr::write_csv(
  d %>% 
    dplyr::filter(cases_deaths == "death") %>% 
    dplyr::rename(value = cum) %>%
    dplyr::select(date, location, value),
  path = "truth_usafacts-Cumulative Deaths.csv")

readr::write_csv(
  d %>% 
    dplyr::filter(cases_deaths == "death") %>% 
    dplyr::rename(value = inc) %>%
    dplyr::select(date, location, value),
  path = "truth_usafacts-Incident Deaths.csv")

readr::write_csv(
  d %>% 
    dplyr::filter(cases_deaths == "case") %>% 
    dplyr::rename(value = cum) %>%
    dplyr::select(date, location, value),
  path = "truth_usafacts-Cumulative Cases.csv")

readr::write_csv(
  d %>% 
    dplyr::filter(cases_deaths == "case") %>% 
    dplyr::rename(value = inc) %>%
    dplyr::select(date, location, value),
  path = "truth_usafacts-Incident Cases.csv")
