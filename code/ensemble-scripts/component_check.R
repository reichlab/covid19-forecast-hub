require(tidyverse)
require(MMWRweek)
require(lubridate)
require(plyr)
require("shiny")
require("rmarkdown")
require(DT)

read_my_csv = function(f, into) {
  tryCatch(
    readr::read_csv(f,
                    col_types = readr::cols(
                      forecast_date   = readr::col_date(format = ""),
                      target          = readr::col_character(),
                      target_end_date = readr::col_date(format = ""),
                      location        = readr::col_character(),
                      type            = readr::col_character(),
                      quantile        = readr::col_double(),
                      value           = readr::col_double()
                    )),
    warning = function(w) {
      w$message <- paste0(f,": ", gsub("simpleWarning: ","",w))
      warning(w)
      suppressWarnings(
        readr::read_csv(f,
                        col_types = readr::cols(
                          forecast_date   = readr::col_date(format = ""),
                          target          = readr::col_character(),
                          target_end_date = readr::col_date(format = ""),
                          location        = readr::col_character(),
                          type            = readr::col_character(),
                          quantile        = readr::col_double(),
                          value           = readr::col_double()
                        ))
      )
    }
  ) %>%
    dplyr::mutate(file = paste0("./",str_sub(f,18))) %>%
    tidyr::separate(file, into, sep="-|/") 
}
read_dir = function(path, pattern, into) {
  all_files = list.files(path  = paste0(path,"/data-processed"),
                     pattern    = pattern,
                     recursive  = TRUE,
                     full.names = TRUE) 
  fcast_files <- all_files[grepl("[0-9]{4}-[0-9]{2}-[0-9]{2}",all_files)]
  # take out ensemble
  fcast_files <- all_files[-grepl("COVIDhub-ensemble",all_files)]
  dir_names <- unique(dirname(fcast_files))
  latest_files <-c()
  for(i in 1:length(dir_names)){
    mod_files <- fcast_files[grepl(dir_names[i],fcast_files)]
    latest_date <- max(as.Date(substr(basename(mod_files),start=1,stop=10)))
    latest_files <-c(latest_files,mod_files[grepl(latest_date,mod_files)]) 
  }
  plyr::ldply(latest_files, read_my_csv, into = into)
}
# above from https://gist.github.com/jarad/8f3b79b33489828ab8244e82a4a0c5b3
#############################################################################
fips <- read_csv("./template/state_fips_codes.csv",
                 col_types = readr::cols(
                   state = col_character(),
                   state_code = col_character(),
                   state_name = col_character()
                 )) %>%
  dplyr::rename(fips_numeric = state_code,
         fips_alpha   = state,
         full_name    = state_name) %>%
  dplyr::bind_rows(dplyr::tibble(fips_alpha = "US", 
                          fips_numeric = "US", 
                          full_name = "United States"))
# take subset of overlapping location and quantiles and show each model's non overlapping from that set
targets <- c(paste(1:4,"wk ahead cum death"))
latest = read_dir(".",
                       "*.csv",
                       into = c("period","team","model",
                                "year","month","day","team2","model_etc")) %>%
  dplyr::select(team, model, forecast_date, type, location, target, quantile, value) %>%
  dplyr::rename(fips_numeric = location) %>%
  dplyr::left_join(fips, by=c("fips_numeric")) %>%
  select(-fips_numeric, -full_name) %>%
  filter(!is.na(forecast_date),target %in% targets) %>%
  group_by(team, model) %>%
  dplyr::filter(forecast_date == max(forecast_date)) %>%
  ungroup() %>%
  tidyr::separate(target, into=c("n_unit","unit","ahead","inc_cum","death_cases"),
                  remove = FALSE)
