## make some plots
## Nick Reich
## April 2020

library(tidyverse)
library(ggforce)
library(scales)
source("code/get_next_saturday.R")
theme_set(theme_minimal())

timezero <- "2020-04-13"
models_to_exclude <- c("CU-nointerv")

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
    filter(!(model %in% models_to_exclude), ## drop other models
        grepl("wk ahead", target)) %>%   ## only include week-ahead targets
    inner_join(wk_ahead_saturdays) %>%   ## add week end dates, limit to 1-4 wk ahead
    mutate(value = round(value)) %>%
    pivot_wider(names_from = c(type, quantile), values_from=value) %>%
    rename(point = point_NA) 

## change ensemble label
ensemble_idx <- which(dat$model=="UMassCoE-ensemble")
dat$model[ensemble_idx] <- "ensemble forecast"


wrapper <- function(x, ...) paste(strwrap(x, ...), collapse = "\n")
nat_label_text <- "The IHME and MOBS models are conditional on existing social distancing measures continuing through the projected time-period shown. The CU models make different assumptions about the effectiveness of current interventions. Intervals shown are at the 95% uncertainty level."
#state_label_text <- "Forecasts shown here fall into one of three categories. The LANL model is explicitly 'unconditional' on any particular interventions being in place. The IHME and MOBS_NEU models are conditional on existing social distancing measures continuing through the projected time-period. The CU models make different assumptions about the effectiveness of current interventions. Intervals shown are at the 95% uncertainty level."
state_label_text <- "The ensemble forecast shown here combines models that are either explicitly 'unconditional' on any particular interventions being in place or are conditional on existing social distancing measures continuing through the projected time-period. Intervals shown are at the 95% uncertainty level."

state_data <- bind_rows(dat, data.frame(model="observed data", obs_data)) %>%
    filter(!(location_name %in% c("US", "US National", "Puerto Rico", "U.S. Virgin Islands")))
    #filter(location_name %in% c("Rhode Island", "New York", "Colorado", "Louisiana"))

# ggplot(state_data, aes(x=wk_end_date, group=model)) +
#     facet_wrap(~location_name, scales = "free_y") +
#     ## plot true data
#     geom_line(data=filter(state_data, model=="obs data"), aes(y=value, color=model)) + 
#     geom_point(data=filter(state_data, model=="obs data"), aes(y=value, color=model), size=1) +
#     ## plot all forecast data
#     geom_line(aes(y=point), alpha=.3) + 
#     #geom_point(aes(y=point), alpha=.3, size=1) +
#     ## plot ensemble forecast data
#     geom_line(data=filter(state_data, model=="UMassCoE-ensemble"), aes(y=point, color=model), ) + 
#     geom_point(data=filter(state_data, model=="UMassCoE-ensemble"), aes(y=point, color=model), size=1) +
#     geom_ribbon(data=filter(state_data, model=="UMassCoE-ensemble"), aes(ymin=quantile_0.025, ymax=quantile_0.975, fill=model), alpha=.2)+
#     #annotate("text", x=as.Date("2020-01-15"), y=Inf, label=wrapper(label_text, width=125), hjust=0, vjust=1.2, size=2) +
#     scale_x_date(limits=c(as.Date("2020-01-15"), as.Date("2020-08-01")), date_breaks="1 month", date_labels = "%b") +
#     scale_y_continuous(labels = comma) +
#     scale_color_manual(values=c("black", "#2ca25f")) +
#     scale_fill_manual(values = "#2ca25f", guide=FALSE) +
#     theme(legend.position = c(0,1), legend.justification = c(0,1), legend.title = element_blank()) +
#     ggtitle("Observed and forecasted cumulative COVID-19 deaths in the US", 
#         subtitle = wrapper(state_label_text, width=100)) +
#     ylab("cumulative deaths") + xlab(NULL)


pdf(paste0("static-plots/", timezero, "-us-plot.pdf"), width = 7.5, height=4)
ggplot(filter(obs_data, location=="US"), aes(x=wk_end_date)) +
    ## plot true data
    geom_line(aes(y=value)) + geom_point(aes(y=value), size=1) +
    ## plot forecast data
    geom_point(data=filter(dat,location=="US"), aes(y=point, color=model), size=1) + 
    geom_line(data=filter(dat, location=="US"), aes(y=point, color=model)) + 
    geom_ribbon(data=filter(dat, location=="US"), aes(ymin=quantile_0.025, ymax=quantile_0.975, fill=model), alpha=.15)+
    #annotate("text", x=as.Date("2020-01-15"), y=Inf, label=wrapper(label_text, width=125), hjust=0, vjust=1.2, size=2) +
    scale_x_date(limits=c(as.Date("2020-01-15"), as.Date("2020-08-01")), date_breaks="1 month", date_labels = "%b") +
    scale_y_continuous(labels = comma) +
    scale_color_brewer(palette="Dark2") +
    scale_fill_brewer(palette="Dark2") +
    theme(legend.position = c(1,0), legend.justification = c(1,0), 
        legend.title = element_blank(), plot.subtitle=element_text(size=8)) +
    ggtitle("Observed and forecasted cumulative COVID-19 deaths in the US", 
        subtitle = wrapper(nat_label_text, width=120)) +
    ylab("cumulative deaths") + xlab(NULL)
dev.off()

pdf(paste0("static-plots/", timezero, "-state-plots.pdf"), width = 7.5, height=10)
for(i in 1:7) {
    # p <- ggplot(filter(obs_data, location!="US"), aes(x=wk_end_date)) +
    #     geom_line(aes(y=value)) + geom_point(aes(y=value), size=1) +
    #     geom_ribbon(data=filter(dat, location!="US"), aes(ymin=quantile_0.025, ymax=quantile_0.975, fill=model), alpha=.1)+
    #     geom_point(data=filter(dat, location!="US"), aes(y=point, color=model), size=1) + 
    #     geom_line(data=filter(dat, location!="US"), aes(y=point, color=model)) + 
    #     # annotate("text", x=as.Date("2020-01-15"), y=Inf, label=wrapper(label_text, width=80), hjust=0, vjust=1.2, size=2) +
    #     scale_x_date(limits=c(as.Date("2020-01-15"), as.Date("2020-08-01"))) +
    #     ylab("cumulative deaths") + xlab(NULL) +
    #     theme(legend.position = "top", plot.subtitle=element_text(size=8)) +
    #     scale_y_continuous(labels = comma) +
    #     scale_color_brewer(palette="Dark2") +
    #     scale_fill_brewer(palette="Dark2") +
    #     ggtitle("Observed and forecasted cumulative COVID-19 deaths in US states", 
    #         subtitle = wrapper(state_label_text, width=120)) +
    #     facet_wrap_paginate(~location_name, nrow = 4, ncol=2, page=i, scales = "free_y")
    p <- ggplot(state_data, aes(x=wk_end_date, group=model)) +
        facet_wrap_paginate(~location_name, nrow = 4, ncol=2, page=i, scales = "free_y") +
        ## plot true data
        geom_line(data=filter(state_data, model=="observed data"), aes(y=value, color=model)) + 
        geom_point(data=filter(state_data, model=="observed data"), aes(y=value, color=model), size=1) +
        ## plot all forecast data
        geom_line(aes(y=point), alpha=.3) + 
        #geom_point(aes(y=point), alpha=.3, size=1) +
        ## plot ensemble forecast data
        geom_line(data=filter(state_data, model=="ensemble forecast"), aes(y=point, color=model), ) + 
        geom_point(data=filter(state_data, model=="ensemble forecast"), aes(y=point, color=model), size=1) +
        geom_ribbon(data=filter(state_data, model=="ensemble forecast"), aes(ymin=quantile_0.025, ymax=quantile_0.975, fill=model), alpha=.2)+
        #annotate("text", x=as.Date("2020-01-15"), y=Inf, label=wrapper(label_text, width=125), hjust=0, vjust=1.2, size=2) +
        scale_x_date(limits=c(as.Date("2020-01-15"), as.Date("2020-08-01")), date_breaks="1 month", date_labels = "%b") +
        scale_y_continuous(labels = comma) +
        scale_color_manual(values=c("#2ca25f", "black")) +
        scale_fill_manual(values = "#2ca25f", guide=FALSE) +
        theme(legend.position = c(0,1), legend.justification = c(0,1), legend.title = element_blank(), plot.subtitle=element_text(size=8)) +
        ggtitle("Observed and forecasted cumulative COVID-19 deaths in the US", 
            subtitle = wrapper(state_label_text, width=100)) +
        ylab("cumulative deaths") + xlab(NULL)
    
    print(p)
    }
dev.off()

dat_to_save <- dat %>%
    rename(target_week_end_date = wk_end_date) %>%
    mutate(forecast_date=timezero) %>%
    select(forecast_date, target, target_week_end_date, location_name, point, quantile_0.025, quantile_0.975) 

write_csv(dat_to_save, paste0("static-plots/", timezero, "-plotted-data.csv"))

