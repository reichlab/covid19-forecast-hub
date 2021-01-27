# Read in all the forecast files in data-processed/

library("dplyr")
library("tidyr")
library("readr")

read_my_csv = function(f, into) {
  tryCatch(
    readr::read_csv(f,
                    col_types = readr::cols_only(
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
                        col_types = readr::cols_only(
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
    dplyr::mutate(file = f) %>%
    tidyr::separate(file, into, sep="-|/") 
}

read_my_dir = function(path, pattern, into, exclude = NULL) {
  files = list.files(path       = path,
                     pattern    = pattern,
                     recursive  = TRUE,
                     full.names = TRUE) %>%
    setdiff(exclude)
  plyr::ldply(files, read_my_csv, into = into)
}

# above from https://gist.github.com/jarad/8f3b79b33489828ab8244e82a4a0c5b3
#############################################################################

locations <- readr::read_csv("../data-locations/locations.csv",
                             col_types = readr::cols(
                               abbreviation  = readr::col_character(),
                               location      = readr::col_character(),
                               location_name = readr::col_character()
                             )) 


all_data = read_my_dir(".", "*.csv",
                into = c("period","team","model",
                         "year","month","day","team2","model_etc")) %>%
  
  dplyr::select(team, model, forecast_date, type, location, target, quantile, 
                value, target_end_date) %>%
    
  dplyr::left_join(locations, by=c("location")) 
