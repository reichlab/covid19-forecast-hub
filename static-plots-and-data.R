## make some plots
## Nick Reich
## April 2020

library(tidyverse)
library(ggforce)
source("code/get_next_saturday.R")
theme_set(theme_bw())

timezero <- "2020-04-13"
models_to_include <- c("IHME-CurveFit", "LANL-GrowthRate", "MOBS_NEU-GLEAM")

## get truth data
obs_data <- read_csv("data-processed/truth-cum-death.csv") %>%
    mutate(wk_end_date = as.Date(date, "%m/%d/%y")) %>%
    select(-date) %>%
    filter(wk_end_date %in% c(get_next_saturday(timezero)+seq(0, -70, by=-7)))

## get all forecasts
wk_ahead_saturdays <- tibble(
    target = paste(1:4, "wk ahead cum death"),
    wk_end_date = get_next_saturday(timezero)+c(0:3)*7)
datapath <- "data-processed"
filenames <- list.files(path=datapath, pattern=timezero, recursive = TRUE)
dat_list <-  lapply(file.path(datapath, filenames), 
    FUN = function(x) read_csv(x, col_types = "ccccdd"))
model_names <- str_split(filenames, "/", simplify = TRUE)[,1]

all_dat <- bind_cols(model = rep(model_names[1], nrow(dat_list[[1]])), as_tibble(dat_list[[1]], ))
for(i in 2:length(model_names)){
    tmp <- bind_cols(model = rep(model_names[i], nrow(dat_list[[i]])), as_tibble(dat_list[[i]]))
    all_dat <- bind_rows(all_dat, tmp)
}

## reformat all the data
dat <- all_dat %>%
    filter(model %in% models_to_include, ## drop other models
        grepl("wk ahead", target)) %>%   ## only include week-ahead targets
    inner_join(wk_ahead_saturdays) %>%   ## add week end dates, limit to 1-4 wk ahead
    mutate(value = round(value)) %>%
    pivot_wider(names_from = c(type, quantile), values_from=value) %>%
    rename(point = point_NA) 


ggplot(filter(obs_data, location=="US"), aes(x=wk_end_date)) +
    ## plot true data
    geom_line(aes(y=value)) + geom_point(aes(y=value)) +
    ## plot forecast data
    geom_point(data=filter(dat,location=="US"), aes(y=point, color=model)) + 
    geom_line(data=filter(dat, location=="US"), aes(y=point, color=model)) + 
    geom_ribbon(data=filter(dat, location=="US"), aes(ymin=quantile_0.025, ymax=quantile_0.975, fill=model), alpha=.5)+
    scale_x_date(limits=c(as.Date("2020-01-01"), as.Date("2020-09-01"))) +
    ylab("cumulative deaths") + xlab(NULL)

pdf(paste0("static-plots/", timezero, "-state-plots.pdf"), width = 7.5, height=10)
for(i in 1:6) {
    p <- ggplot(obs_data, aes(x=wk_end_date)) +
        geom_line(aes(y=value)) + geom_point(aes(y=value)) +
        geom_point(data=dat, aes(y=point, color=model)) + 
        geom_line(data=dat, aes(y=point, color=model)) + 
        geom_ribbon(data=dat, aes(ymin=quantile_0.025, ymax=quantile_0.975, fill=color), alpha=.5)+
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

write_csv(dat_to_save, paste0("static-plots/", timezero, "-plotted-data.csv"))

