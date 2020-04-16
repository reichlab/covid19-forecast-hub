## make some plots
## Nick Reich
## April 2020

timezero <- "2020-04-13"


library(tidyverse)
library(ggforce)

source("code/get_next_saturday.R")

theme_set(theme_bw())

## get truth data
obs_data <- read_csv("data-processed/truth-cum-death.csv") %>%
    mutate(date = as.Date(date, "%m/%d/%y")) %>%
    filter(date %in% c(as.Date(timezero)+seq(0, -70, by=-7)))

## get all forecasts
wk_ahead_saturdays <- tibble(
    target = paste(1:4, "wk ahead cum death"),
    date = get_next_saturday(timezero)+c(0:3)*7)
datapath <- "data-processed"
filenames <- list.files(path=datapath, pattern=timezero, recursive = TRUE)
myfiles <-  lapply(file.path(datapath, filenames), read_csv)

dat <- myfiles[[6]] %>%
    filter(grepl("wk ahead", target)) %>%
    left_join(wk_ahead_saturdays) %>%
    pivot_wider(names_from = quantile, values_from=value, names_prefix = "q")


ggplot(filter(obs_data, location=="US"), aes(x=date)) +
    geom_line(aes(y=value)) + geom_point(aes(y=value)) +
    geom_point(data=filter(dat, type=="point", location=="US"), aes(y=qNA), color="red") + 
    geom_line(data=filter(dat, type=="point", location=="US"), aes(y=qNA), color="red") + 
    geom_ribbon(data=filter(dat, type=="quantile", location=="US"), aes(ymin=q0.05, ymax=q0.95), alpha=.5, fill="red")+
    scale_x_date(limits=c(as.Date("2020-01-01"), as.Date("2020-09-01"))) +
    ylab("cumulative deaths") + xlab(NULL)

pdf(paste0("static-plots/", timezero, "state-plots.pdf"), width = 7.5, height=10)
for(i in 1:6) {
    p <- ggplot(obs_data, aes(x=date)) +
        geom_line(aes(y=value)) + geom_point(aes(y=value)) +
        geom_point(data=filter(dat, type=="point"), aes(y=qNA), color="red") + 
        geom_line(data=filter(dat, type=="point"), aes(y=qNA), color="red") + 
        geom_ribbon(data=filter(dat, type=="quantile"), aes(ymin=q0.05, ymax=q0.95), alpha=.5, fill="red")+
        scale_x_date(limits=c(as.Date("2020-01-01"), as.Date("2020-09-01"))) +
        ylab("cumulative deaths") + xlab(NULL) +
        facet_wrap_paginate(~location_name, nrow = 5, ncol=2, page=i, scales = "free_y")
    print(p)
    }
dev.off()

## NEED TO FIX THIS!
##  - take real points not q.5, only use 1-4 week, ensure we have US forecasts, ...
dat_to_save <- dat %>%
    filter(type=="quantile") %>%
    rename(target_week_end_date = date, point=q0.5, lowerci.q05=q0.05, upperci.q95=q0.95) %>%
    mutate(
        forecast_date=timezero, 
        point=round(point), 
        lowerci.q05=round(lowerci.q05),
        upperci.q95=round(upperci.q95)) %>%
    select(forecast_date, target, target_week_end_date, location_name, point, lowerci.q05, upperci.q95) 

write_csv(dat_to_save, paste0("static-plots/", timezero, "plotted-data.csv"))

