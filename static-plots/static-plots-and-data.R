## make some plots
## Nick Reich
## April 2020

library(tidyverse)
library(ggforce)
library(scales)
source("code/processing-fxns/get_next_saturday.R")
theme_set(theme_minimal())

timezero <- "2020-04-13"
models_to_exclude <- c("CU-nointerv")

## get truth data
obs_data <- read_csv("data-truth/truth-Cumulative Deaths.csv") %>%
    mutate(wk_end_date = as.Date(date, "%m/%d/%y")) %>%
    select(-date) %>%
    filter(wk_end_date %in% c(get_next_saturday(timezero)+seq(0, -70, by=-7)))

## setup to load in all forecasts
wk_ahead_saturdays <- tibble(
    target = paste(1:4, "wk ahead cum death"),
    wk_end_date = get_next_saturday(timezero)+c(0:3)*7)
datapath <- "data-processed"
filenames <- list.files(path=datapath, pattern=timezero, recursive = TRUE)
dat_list <-  lapply(file.path(datapath, filenames), 
    FUN = function(x) read_csv(x, col_types = "ccccdd"))
model_names <- str_split(filenames, "/", simplify = TRUE)[,1]

## load in all files sequentially
all_dat <- bind_cols(model = rep(model_names[1], nrow(dat_list[[1]])), as_tibble(dat_list[[1]], ))
for(i in 2:length(model_names)){
    tmp <- bind_cols(model = rep(model_names[i], nrow(dat_list[[i]])), as_tibble(dat_list[[i]]))
    all_dat <- bind_rows(all_dat, tmp)
}

## reformat all the data
dat <- all_dat %>%
    filter(!(model %in% models_to_exclude), ## drop excluded models
        grepl("wk ahead", target)) %>%   ## only include week-ahead targets
    inner_join(wk_ahead_saturdays) %>%   ## add week end dates, limit to 1-4 wk ahead
    mutate(value = round(value)) %>%
    pivot_wider(names_from = c(type, quantile), values_from=value) %>%
    rename(point = point_NA) %>%
    bind_rows(data.frame(model="observed data", obs_data))

## change model labels
ensemble_idx <- which(dat$model=="COVIDhub-ensemble")
dat$model[ensemble_idx] <- "ensemble forecast"

cu60_idx <- which(dat$model=="CU-60contact")
dat$model[cu60_idx] <- "CU 40% contact reduction"

cu70_idx <- which(dat$model=="CU-70contact")
dat$model[cu70_idx] <- "CU 30% contact reduction"

cu80_idx <- which(dat$model=="CU-80contact")
dat$model[cu80_idx] <- "CU 20% contact reduction"

mobs_idx <- which(dat$model=="MOBS_NEU-GLEAM_COVID")
dat$model[mobs_idx] <- "MOBS"

lanl_idx <- which(dat$model=="LANL-GrowthRate")
dat$model[lanl_idx] <- "LANL"

ihme_idx <- which(dat$model=="IHME-CurveFit")
dat$model[ihme_idx] <- "IHME"

## make state data with observed data
state_data <- dat %>%
    filter(!(location_name %in% c("US", "US National", "Puerto Rico", "U.S. Virgin Islands")))

wrapper <- function(x, ...) paste(strwrap(x, ...), collapse = "\n")

## subtitles for plots WITH ensemble
nat_label_text <- "The ensemble forecast shown here combines models with predictions for all four weeks. All models combined are either conditional on existing social distancing measures continuing through the projected time-period or make different assumptions about current intervention effectiveness. Intervals shown are at the 95% uncertainty level."
state_label_text <- "The ensemble forecast shown here combines models that are either explicitly 'unconditional' on any particular interventions being in place or are conditional on existing social distancing measures continuing through the projected time-period. Intervals shown are at the 95% uncertainty level."

## subtitles for plots WITHOUT ensemble
nat_noens_label_text <- "The IHME and MOBS models are conditional on existing social distancing measures continuing through the projected time-period shown. The CU models make different assumptions about the effectiveness of current interventions. Intervals shown are at the 95% uncertainty level."
state_noens_label_text <- "Forecasts shown here fall into one of three categories. The LANL model is explicitly 'unconditional' on any particular interventions being in place. The IHME and MOBS_NEU models are conditional on existing social distancing measures continuing through the projected time-period. The CU models make different assumptions about the effectiveness of current interventions. Intervals shown are at the 95% uncertainty level."
#state_label_text <- "Forecasts shown here fall into one of three categories. The LANL model is explicitly 'unconditional' on any particular interventions being in place. The IHME and MOBS_NEU models are conditional on existing social distancing measures continuing through the projected time-period. The CU models make different assumptions about the effectiveness of current interventions. Intervals shown are at the 95% uncertainty level."


## set colors
cols <- brewer_pal(palette="Dark2")(8)
model_colors <- c(
    "observed data" = "black",
    "ensemble forecast" = cols[1],
    "LANL" = cols[2],
    "MOBS" = cols[3],
    "IHME" = cols[4],
    "CU 20% contact reduction" = cols[5],
    "CU 30% contact reduction" = cols[6],
    "CU 40% contact reduction" = cols[7]
)



### US plots

## plot without ensemble
p_nat_no_ens <- ggplot(filter(dat, location=="US", model != "ensemble forecast"), aes(x=wk_end_date)) +
    ## plot true data
    geom_line(aes(y=value)) + geom_point(aes(y=value), size=1) +
    ## plot forecast data
    geom_point(aes(y=point, color=model), size=1) + 
    geom_line(aes(y=point, color=model)) + 
    geom_ribbon(aes(ymin=quantile_0.025, ymax=quantile_0.975, fill=model), alpha=.15)+
    #annotate("text", x=as.Date("2020-01-15"), y=Inf, label=wrapper(label_text, width=125), hjust=0, vjust=1.2, size=2) +
    scale_x_date(limits=c(as.Date("2020-01-15"), as.Date("2020-08-01")), date_breaks="1 month", date_labels = "%b") +
    scale_y_continuous(labels = comma) +
    scale_color_manual(values=model_colors) +
    scale_fill_manual(values=model_colors, guide=FALSE) +
    theme(legend.position = c(0,1), legend.justification = c(0,1), 
        legend.title = element_blank(), 
        plot.tag=element_text(size=8),
        plot.tag.position = "bottom", 
        plot.margin = margin(t = 10, r = 10, b = 20, l = 10)) +
    labs(title="Observed and forecasted cumulative COVID-19 deaths in the US", 
        tag = paste("\n\n\n", wrapper(nat_noens_label_text, width=120))) +
    ylab("cumulative deaths") + xlab(NULL)

pdf(paste0("static-plots/", timezero, "-us-plot-no-ens.pdf"), width = 7.5, height=4)
print(p_nat_no_ens)
dev.off()

## US plot with ensemble
pdf(paste0("static-plots/", timezero, "-us-plot-ensemble.pdf"), width = 7.5, height=4)
ggplot(filter(dat, location=="US"), aes(x=wk_end_date, group=model)) +
    ## plot true data
    geom_line(aes(y=value)) + geom_point(aes(y=value), size=1) +
    ## plot faint lines data
    geom_line(aes(y=point), alpha=.3) +
    ## plot points and heavy lines for obs and ensemble
    geom_line(data=filter(dat, location=="US", model %in% c("observed data", "ensemble forecast")), aes(y=point, color=model)) +
    geom_point(data=filter(dat, location=="US", model %in% c("observed data", "ensemble forecast")), aes(y=point, color=model), size=1) +
    geom_ribbon(data=filter(dat, location=="US", model == "ensemble forecast"), aes(ymin=quantile_0.025, ymax=quantile_0.975, fill=model), alpha=.15) +
    #annotate("text", x=as.Date("2020-01-15"), y=Inf, label=wrapper(label_text, width=125), hjust=0, vjust=1.2, size=2) +
    scale_x_date(limits=c(as.Date("2020-01-15"), as.Date("2020-08-01")), date_breaks="1 month", date_labels = "%b") +
    scale_y_continuous(labels = comma) +
    scale_color_manual(values=model_colors) +
    scale_fill_manual(values=model_colors, guide=FALSE) +
    theme(legend.position = c(0,1), legend.justification = c(0,1), 
        legend.title = element_blank(), 
        plot.tag=element_text(size=8),
        plot.tag.position = "bottom", 
        plot.margin = margin(t = 10, r = 10, b = 20, l = 10)) +
    labs(title="Observed and forecasted cumulative COVID-19 deaths in the US", 
        tag = paste("\n\n\n", wrapper(nat_label_text, width=120))) +
    ylab("cumulative deaths") + xlab(NULL)
dev.off()



### state plots

## simple with ensemble
pdf(paste0("static-plots/", timezero, "-state-plots-ensemble.pdf"), width = 7.5, height=10)
for(i in 1:7) {
    p <- ggplot(state_data, aes(x=wk_end_date, group=model)) +
        facet_wrap_paginate(~location_name, nrow = 4, ncol=2, page=i, scales = "free") +
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
        scale_color_manual(values=model_colors) +
        scale_fill_manual(values = model_colors, guide=FALSE) +
        theme(legend.position = c(0,1), legend.justification = c(0,1), 
            legend.title = element_blank(),
            plot.tag=element_text(size=8),
            plot.tag.position = "bottom", 
            plot.margin = margin(t = 10, r = 10, b = 20, l = 10)) +
        labs(title="Observed and forecasted cumulative COVID-19 deaths in the US", 
            tag = paste("\n", wrapper(state_label_text, width=120))) +
        ylab("cumulative deaths") + xlab(NULL)
    print(p)
}
dev.off()


## busy without ensemble
pdf(paste0("static-plots/", timezero, "-state-plots-no-ens.pdf"), width = 7.5, height=10)
for(i in 1:7) {
    p <- ggplot(filter(state_data, model != "ensemble forecast"), aes(x=wk_end_date, group=model)) +
        facet_wrap_paginate(~location_name, nrow = 4, ncol=2, page=i, scales = "free") +
        ## plot true data
        geom_line(data=filter(state_data, model=="observed data"), aes(y=value)) + 
        geom_point(data=filter(state_data, model=="observed data"), aes(y=value), size=1) +
        ## plot all forecast data
        geom_line(aes(y=point, color=model)) + 
        geom_point(aes(y=point, color=model), size=1) +
        geom_ribbon(aes(ymin=quantile_0.025, ymax=quantile_0.975, fill=model), alpha=.1)+
        #annotate("text", x=as.Date("2020-01-15"), y=Inf, label=wrapper(label_text, width=125), hjust=0, vjust=1.2, size=2) +
        scale_x_date(limits=c(as.Date("2020-01-15"), as.Date("2020-08-01")), date_breaks="1 month", date_labels = "%b") +
        scale_y_continuous(labels = comma) +
        scale_color_manual(values=model_colors) +
        scale_alpha_manual(guide=FALSE) +
        scale_fill_manual(values = model_colors, guide=FALSE) +
        theme(legend.position = "bottom", legend.title = element_blank(), 
            plot.tag=element_text(size=8),
            plot.tag.position = "bottom", 
            plot.margin = margin(t = 10, r = 10, b = 10, l = 10)) +
        labs(title="Observed and forecasted cumulative COVID-19 deaths in the US", 
            tag = paste("", wrapper(state_noens_label_text, width=120))) +
        ylab("cumulative deaths") + xlab(NULL)
    
    print(p)
}
dev.off()


### save data

dat_to_save <- dat %>%
    filter(model != "observed data") %>%
    rename(target_week_end_date = wk_end_date) %>%
    mutate(forecast_date=timezero) %>%
    select(model, forecast_date, target, target_week_end_date, location_name, point, quantile_0.025, quantile_0.975) 

write_csv(dat_to_save, paste0("static-plots/", timezero, "-model-data.csv"))

