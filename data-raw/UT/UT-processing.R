stop("Moved from code/")

library(lubridate)
library(dplyr)
library(readr)
library(tidyr)
library(here)
library(stringr)


## Read in data from most previous Monday (or just read it in yourself)
last6days <- today() - 0:6 

last6weekdays <- wday(last6days, label = TRUE)

lastMonday <- last6days[last6weekdays == "Mon"]

raw <- read_csv(here(sprintf("data-raw/UT/%s-UT-Mobility-raw.csv", lastMonday)))

glimpse(raw)


## Create mapping of quantile col name to quantile number
myprobs <- c(0.01, 0.025, seq(0.05, 0.95, by = 0.05), 0.975, 0.99)

colnamesquantile_inc <- raw %>%
  select(starts_with("quantile_")) %>%
  colnames()

colnamesquantile_cum <- raw %>%
  select(starts_with("quantilecm_")) %>%
  colnames()

quantnamemap_inc <- data.frame(name = colnamesquantile_inc,
                               quantile = myprobs,
                               stringsAsFactors = FALSE)

quantnamemap_cum <- data.frame(name = colnamesquantile_cum,
                               quantile = myprobs,
                               stringsAsFactors = FALSE)

## Format data for processed data files

###############################################################################
                                        #       Process data for export       #
###############################################################################

## Loop through days
incDfList <- vector("list", 7)
cumDfList <- vector("list", 7)


for (j in 1:7) {

  dateJ <- today() + j

  ## INC
  sub_inc <- raw %>%
    filter(date == dateJ) %>%
    select(-contains("quantilecm")) %>%
    mutate(target = sprintf("%i day ahead inc death", j),
           ## target_end_date = dateJ,
           type = "quantile") %>%
    mutate(forecast_date = today()) %>% 
    select(forecast_date, target, target_end_date = date,
           location, location_name, everything())

  sub_inc_long <- sub_inc %>%
    pivot_longer(cols = starts_with("quant")) %>%
    left_join(quantnamemap_inc) %>%
    select(forecast_date, target, target_end_date, location,
           location_name, type, quantile, value)

  incDfList[[j]] <- sub_inc_long

  ## CUM
  sub_cum <- raw %>%
    filter(date == dateJ) %>%
    select(-contains("quantile_")) %>%
    mutate(target = sprintf("%i day ahead cum death", j),
           ## target_end_date = dateJ,
           type = "quantile") %>%
    mutate(forecast_date = today()) %>% 
    select(forecast_date, target, target_end_date = date,
           location, location_name, everything())

  sub_cum_long <- sub_cum %>%
    pivot_longer(cols = starts_with("quant")) %>%
    left_join(quantnamemap_cum) %>%    
    select(forecast_date, target, target_end_date, location,
           location_name, type, quantile, value)

  cumDfList[[j]] <- sub_cum_long
  
}

incDf <- incDfList %>% plyr::rbind.fill()
cumDf <- cumDfList %>% plyr::rbind.fill()


## loop through weeks

incWeekDfList <- vector("list", 6)
cumWeekDfList <- vector("list", 6)

for (j in 1:6) {

  ## INC
  sub_incWeek <- raw %>%
    filter(date == today() + 5 + (j - 1) * 7) %>%
    select(-contains("quantilecm")) %>%
    mutate(target = sprintf("%i wk ahead inc death", j),
           type = "quantile") %>%
    mutate(forecast_date = today()) %>% 
    select(forecast_date, target, target_end_date = date,
           location, location_name, everything())

  sub_incWeek_long <- sub_incWeek %>%
    pivot_longer(cols = starts_with("quant")) %>%
    left_join(quantnamemap_inc) %>%
    select(forecast_date, target, target_end_date, location,
           location_name, type, quantile, value)


  incWeekDfList[[j]] <- sub_incWeek_long

  ## CUM
  sub_cumWeek <- raw %>%
    filter(date == today() + 5 + (j - 1) * 7) %>%
    select(-contains("quantile_")) %>%
    mutate(target = sprintf("%i wk ahead cum death", j),
           type = "quantile") %>%

    mutate(forecast_date = today()) %>% 
    select(forecast_date, target, target_end_date = date,
           location, location_name, everything())

  sub_cumWeek_long <- sub_cumWeek %>%
    pivot_longer(cols = starts_with("quant")) %>%
    left_join(quantnamemap_cum) %>%
    select(forecast_date, target, target_end_date, location,
           location_name, type, quantile, value)

  cumWeekDfList[[j]] <- sub_cumWeek_long

  
}

incWeekDf <- incWeekDfList %>% plyr::rbind.fill()
cumWeekDf <- cumWeekDfList %>% plyr::rbind.fill()

deathSummary <- rbind(incDf, cumDf, incWeekDf, cumWeekDf)

## Point estimates are the same as 0.5 quantile

deathSummaryPoint <- deathSummary %>%
  filter(quantile == 0.5) %>%
  mutate(type = "point") %>% 
  mutate(quantile = NA)

deathSummaryFinal <- rbind(deathSummary, deathSummaryPoint) %>%
  arrange(location,
          target %>% str_detect("wk"),
          target %>% str_detect("cum"),
          target, type, quantile)

glimpse(deathSummaryFinal)


###############################################################################
                                        #            Export to CSV            #
###############################################################################



write_csv(deathSummaryFinal,
          here(sprintf("data-processed/UT-Mobility/%s-UT-Mobility.csv", lastMonday)))
