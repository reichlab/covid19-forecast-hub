# Process JHU data
# Jarad Niemi
# April 2020

library("dplyr")
library("tidyr")
library("readr")

team  = "JHU_IDD"
model = "CovidSP"

read_JHU_csv = function(f, into = NULL) {
  my_sep = "-|/|\\."
  if (is.null(into)) {
    tmp <- strsplit(f, split = my_sep)[[1]]
    into <- paste0("V",1:length(tmp))
  }
  
  readr::read_csv(f,
                  col_types = readr::cols(
                    time = col_date(format = ""),
                    quantile = col_character(),
                    hosp_curr = col_double(),
                    cum_death = col_double(),
                    death = col_double(),
                    infections = col_double(),
                    cum_infections = col_double(),
                    hosp = col_double()
                    )
                  ) %>%
    dplyr::mutate(file = f) %>%
    tidyr::separate(file, into, sep=my_sep) 
}

read_JHU_dir = function(path, pattern, into = NULL) {
  files = list.files(path       = path,
                     pattern    = pattern,
                     recursive  = FALSE,
                     full.names = FALSE)
  plyr::ldply(files, read_JHU_csv, into = into)
}

# above from https://gist.github.com/jarad/8f3b79b33489828ab8244e82a4a0c5b3
###############################################################################

JHU <- read_JHU_dir(".",
            pattern = "*.csv",
            into = c("location",
                     "year","month","day","csv")
            ) %>%
  
  dplyr::mutate(forecast_date = as.Date(paste(year,month,day,sep="-")),
                quantile = as.numeric(gsub("%","",quantile))/100,
                
                type = "quantile",
                location = "US") %>%
  
  dplyr::rename(
    target_end_date = time,
    
    `inc death` = death,
    `cum death` = cum_death,
    `inc cases` = infections,
    `cum cases` = cum_infections,
    `inc hosp`  = hosp,
    `cum hosp`  = hosp_curr
  ) %>%
  
  dplyr::filter(target_end_date > forecast_date) %>%
  dplyr::select(-year, -month, -day, -csv) %>%
  
  dplyr::mutate(target = as.numeric(target_end_date - forecast_date),
                target = paste(target, "day ahead")) %>%
  
  tidyr::gather(
    `inc death`, `cum death`, `inc cases`,`cum cases`, `inc hosp`, `cum hosp`,
    key = "target2", value = "value"
  ) %>%
  
  dplyr::filter(target2 %in% c("inc death","cum death","inc hosp")) %>% 
  dplyr::mutate(target = paste(target, target2)) %>%
  dplyr::select(-target2) %>%
  
  dplyr::select(forecast_date, target, target_end_date, location, type, quantile, value) 



# Create weekly targets
JHU_weekly_cum_death<- JHU %>%
  
  filter(weekdays(target_end_date) == "Saturday",
         grepl("cum death", target)) %>%
  
  mutate(n_days = as.numeric(gsub( " .*$", "", target )),
         target = paste((n_days-1)/7, "wk ahead cum death")) %>%
  filter(n_days > 1) %>% # due to Friday forecast_date
  select(-n_days)
  

JHU_point <- bind_rows(JHU, JHU_weekly_cum_death) %>%
  
  filter(quantile == 0.5) %>% 
  mutate(type = "point",
         quantile = NA) 
  

  
bind_rows(JHU, JHU_weekly_cum_death, JHU_point) %>%
  
  group_by(forecast_date) %>%
  
  do(readr::write_csv(.,path = paste0("../../data-processed/JHU_IDD-CovidSP/",
                                 unique(.$forecast_date),"-",
                                 "JHU_IDD-CovidSP.csv")))
