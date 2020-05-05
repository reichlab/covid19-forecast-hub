
library(tidyverse)
library(here)

setwd(here())

forecast0427 <- read_csv("data-processed/UT-Mobility/2020-04-27-UT-Mobility.csv")

glimpse(forecast0427)

forecast0427$target %>% unique()

forecast0427$target %>% unique() %>% str_sub(1, 2) %>% as.numeric()

forecast0427_new <- forecast0427 %>%
  filter(((target %>% str_detect("wk")) &
          (as.numeric(str_sub(target, 1, 2)) %in% 1:4))
         |
         ((target %>% str_detect("day")) &
          (as.numeric(str_sub(target, 1, 2)) %in% 1:28)))

forecast0427_new$target %>% unique()





forecast0504 <- read_csv("data-processed/UT-Mobility/2020-05-04-UT-Mobility.csv")

glimpse(forecast0504)

forecast0504$target %>% unique()

forecast0504$target %>% unique() %>% str_sub(1, 2) %>% as.numeric()

forecast0504_new <- forecast0504 %>%
  filter(((target %>% str_detect("wk")) &
          (as.numeric(str_sub(target, 1, 2)) %in% 1:4))
         |
         ((target %>% str_detect("day")) &
          (as.numeric(str_sub(target, 1, 2)) %in% 1:28)))

forecast0504_new$target %>% unique()

write_csv(forecast0427_new,
          "data-processed/UT-Mobility/2020-04-27-UT-Mobility.csv")

write_csv(forecast0504_new,
          "data-processed/UT-Mobility/2020-05-04-UT-Mobility.csv")
