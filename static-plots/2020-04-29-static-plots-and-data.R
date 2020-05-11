rm(list=ls())

library(tidyverse)

source("../covid19-forecast-hub/code/processing-fxns/get_next_saturday.R")

inclusion_dates <- as.Date("2020-05-04") - 0:3
#timezero <- "2020-04-27"
#models_to_exclude <- c("CU-nointerv", "JHU_IDD-CovidSP")
models_to_exclude <- ""


## get truth data
obs_data <- read_csv("../covid19-forecast-hub/data-truth/truth-Cumulative Deaths.csv") %>%
    mutate(wk_end_date = as.Date(date, "%m/%d/%y"),
      location_name = ifelse(location == 'US', 'National', location_name)) %>%
    select(-date) %>%
    filter(wk_end_date %in% c(get_next_saturday(inclusion_dates[1]) + seq(0, -70, by=-7)))

## setup to load in all forecasts
max_wk_ahead <- 6
wk_ahead_saturdays <- tibble(
    wks_ahead = paste(1:max_wk_ahead, "wk ahead"),
    wk_end_date = get_next_saturday(inclusion_dates[1]) + c(0:(max_wk_ahead - 1)) * 7)

datapath <- "../covid19-forecast-hub/data-processed"
filenames <- c(list.files(path=datapath, pattern=as.character(inclusion_dates[1]), 
    full.names = TRUE, recursive = TRUE),
  list.files(path=datapath, pattern=as.character(inclusion_dates[2]), 
    full.names = TRUE, recursive = TRUE),
  list.files(path=datapath, pattern=as.character(inclusion_dates[3]), 
    full.names = TRUE, recursive = TRUE),
  list.files(path=datapath, pattern=as.character(inclusion_dates[4]), 
    full.names = TRUE, recursive = TRUE)
  )

dat_list <- lapply(filenames, 
    FUN = function(x) read_csv(x, col_types = cols(.default = "c")))
model_names <- str_split(filenames, "/", simplify = TRUE)[ , 4]

## load in all files sequentially
all_dat <- tibble() #bind_cols(model = rep(model_names[1], nrow(dat_list[[1]])), as_tibble(dat_list[[1]], ))
for (i in 1:length(model_names)) {
#    tmp <- bind_cols(model = rep(model_names[i], nrow(dat_list[[i]])), as_tibble(dat_list[[i]]))
    all_dat <- bind_rows(all_dat, 
      dat_list[[i]] %>%
        mutate(
          model = model_names[i],
          value = as.numeric(value),
          )
    )
}
location_names <- filter(all_dat, !is.na(location_name)) %>%
    select(location, location_name) %>%
    group_by(location, location_name) %>%
    slice(1) %>%
    ungroup()

all_dat <- arrange(all_dat, desc(forecast_date)) %>%
  select(-location_name) %>%
  left_join(location_names) %>%
  mutate(
    location_name = ifelse(location == 'US', 'National', location_name),
    location_name = ifelse(location_name == 'U.S. Virgin Islands', 'Virgin Islands', location_name),
  ) %>%
  group_by(model, target, location_name, type, quantile) %>%
  slice(1) %>%
  ungroup()

  

## reformat all the data
dat <- all_dat %>%
    filter(!(model %in% models_to_exclude), ## drop excluded models
        grepl("wk ahead", target)) %>%   ## only include week-ahead targets
    mutate(wks_ahead = str_extract(target, '\\d{1,2} wk ahead')) %>%
    left_join(wk_ahead_saturdays) %>%   ## add week end dates, limit to 1-4 wk ahead
    mutate(value = round(value)) %>%
    pivot_wider(names_from = c(type, quantile), values_from=value) %>%
    dplyr::rename(point = point_NA)
# unique(filter(all_dat, duplicated(all_dat))$model)
# unique(filter(all_dat, duplicated(all_dat))$target)
# filter(all_dat, duplicated(all_dat), target == '1 wk ahead cum death')
# filter(all_dat, str_detect(model, 'YYG'), target == '1 wk ahead cum death', location == 16) %>%
#   View()
# x <- read_csv(file.path(datapath, filenames[[8]]))
# filter(x, target == '1 wk ahead cum death', location == 16) %>%
#   View()

## change model labels


# wrapper <- function(x, ...) paste(strwrap(x, ...), collapse = "\n")
# 
# ## subtitles for plots WITH ensemble
# nat_label_text <- "The ensemble forecast shown here combines models with predictions for all four weeks. All models combined are either conditional on existing social distancing measures continuing through the projected time-period or make different assumptions about current intervention effectiveness. Intervals shown are at the 95% uncertainty level."
# state_label_text <- "The ensemble forecast shown here combines models that are either explicitly 'unconditional' on any particular interventions being in place or are conditional on existing social distancing measures continuing through the projected time-period. Intervals shown are at the 95% uncertainty level."
# 
# ## subtitles for plots WITHOUT ensemble
# nat_noens_label_text <- "The IHME and MOBS models are conditional on existing social distancing measures continuing through the projected time-period shown. The CU models make different assumptions about the effectiveness of current interventions. Intervals shown are at the 95% uncertainty level."
# state_noens_label_text <- "Forecasts shown here fall into one of three categories. The LANL model is explicitly 'unconditional' on any particular interventions being in place. The IHME and MOBS_NEU models are conditional on existing social distancing measures continuing through the projected time-period. The CU models make different assumptions about the effectiveness of current interventions. Intervals shown are at the 95% uncertainty level."
# #state_label_text <- "Forecasts shown here fall into one of three categories. The LANL model is explicitly 'unconditional' on any particular interventions being in place. The IHME and MOBS_NEU models are conditional on existing social distancing measures continuing through the projected time-period. The CU models make different assumptions about the effectiveness of current interventions. Intervals shown are at the 95% uncertainty level."


## set colors
cols <- c("darkred", "#F3DF6C", "#CEAB07", "#D5D5D3", "#798E87", "#C27D38", 
    "#CCC591", "#85D4E3", "#F4B5BD", "#9C964A", "#FAD77B", 
  "#02401B", "#A2A475", "#81A88D", "#972D15", 
  "#D8B70A", "#02401B", "#A2A475", "#81A88D", "#972D15", "#FB6467FF","917C5DFF")
model_colors <- c(
    "COVIDhub-ensemble" = cols[1],
    "LANL-GrowthRate" = cols[2],
    "MOBS_NEU-GLEAM_COVID" = cols[3],
    "IHME-CurveFit" = cols[4],
    "CU-80contactw" = cols[5],
    "CU-80contact_1x" = cols[6],
    "CU-80contact" = cols[7],
    "UMass-ExpertCrowd" = cols[8],
    "YYG-ParamSearch" = cols[9],
    "Geneva-DeterministicGrowth" = cols[10],
    "MIT_CovidAnalytics-DELPHI" = cols[11],
    "NotreDame-FRED" = cols[12],
    "UT-Mobility" = cols[13],
    "JHU_IDD-CovidSP" = cols[14],
    "Imperial-ensemble1" = cols[15],
    "Imperial-ensemble2" = cols[16],
    "UMass-MechBayes" = cols[17],
    "UCLA-SuEIR" = cols[17],
    "Auquan-SEIR" = cols[18]
)

model_display_names <- c(
  "COVIDhub-ensemble" = "Ensemble",
  "LANL-GrowthRate" = "LANL",
  "MOBS_NEU-GLEAM_COVID" = "MOBS",
  "IHME-CurveFit" = "IHME",
  "CU-80contactw" = "CU-20w", 
  "CU-80contact_1x" = "CU-20_1x",
  "CU-80contact" = "CU-20",
  "UMass-ExpertCrowd" = "UMass-EC",
  "YYG-ParamSearch" = "YYG",
  "Geneva-DeterministicGrowth" = 'Geneva',
  "MIT_CovidAnalytics-DELPHI" = 'MIT',
  "NotreDame-FRED" = 'NotreDame',
  "UT-Mobility" = "UT",
  "JHU_IDD-CovidSP" = "JHU",
  "Imperial-ensemble1" = 'Imperial1',
  "Imperial-ensemble2" = 'Imperial2',
  "UMass-MechBayes" = "UMass-MB",
  "UCLA-SuEIR" = "UCLA",
  "Auquan-SEIR"="Auquan"
  )

### plots

plot_bands <- function(x, ...) {
  polygon(c(x[[1]], rev(x[[1]])), c(x[[2]], rev(x[[3]])), ...)
}

selected_targets <- c("1 wk ahead cum death", "2 wk ahead cum death", "3 wk ahead cum death", 
"4 wk ahead cum death")
all_locations <- c("National",
  sort(unique(dat$location_name[dat$location_name != "National"])))

## simple with ensemble
#pdf(paste0("static-plots/", timezero, "-state-plots-ensemble.pdf"), paper='letter')
#for (i in 1:10){
#  par(mfrow=c(8, 4))
plot_us <- function() {
  jpeg(paste0("./static-plots/National-plot-ensemble-", inclusion_dates[1], ".jpg"), 
    width=7.5, height=3.5, units='in', res=300)
  par(mfrow=c(1, 2), mar=c(1.25, 1.25, 1.25, 0.5), oma=c(0.5, 2.5, 2, 0), 
    mgp=c(0.5, 0.3, 0), tck=-0.01, cex=0.8)
  obs <- filter(obs_data, location_name == "National")
  fcasts <- filter(dat, location_name == "National", model != 'COVIDhub-ensemble',
    target %in% selected_targets)
  plot(select(obs, wk_end_date, value), 
    xlim=c(min(obs$wk_end_date), max(fcasts$wk_end_date)), 
    ylim=c(0, max(fcasts$quantile_0.975, na.rm=T)),
    pch=16, col='black', axes=F, xlab='', ylab='')
  mtext("National Forecast", 3, 0.5, adj=0, font=2, cex=1.25, outer=T)
  abline(h=pretty(c(0, fcasts$point, fcasts$quantile_0.975), 10), 
    col = "grey70", lty = 3, lwd = 0.5)
  abline(v=pretty(c(obs$wk_end_date, fcasts$wk_end_date), 10), 
    col = "grey70", lty = 3, lwd = 0.5)
  lines(select(obs, wk_end_date, value))
  for (this_model in unique(fcasts$model)) {
    plot_bands(filter(fcasts, model == this_model) %>% 
        select(wk_end_date, quantile_0.025, quantile_0.975),
      col=adjustcolor(model_colors[this_model], 0.25), border=NA)
  }
  for (this_model in unique(fcasts$model)) {
    lines(filter(fcasts, model == this_model) %>% 
        select(wk_end_date, point), 
      col=adjustcolor(model_colors[this_model]))
    points(filter(fcasts, model == this_model) %>% 
        select(wk_end_date, point), 
      col=adjustcolor(model_colors[this_model]), pch=16)
  }
  axis.Date(1, at=pretty(c(obs$wk_end_date, fcasts$wk_end_date), 10), 
    labels=format(pretty(c(obs$wk_end_date, fcasts$wk_end_date), 10), '%b-%d'), 
      cex.axis=0.75)
  axis(2)

  mtext("Cumulative reported deaths", 2, 2)
  legend('topleft', legend=c('Reported', model_display_names[unique(fcasts$model)]), 
    fill=c('black', model_colors[unique(fcasts$model)]), border=NA, 
    bty='n')
  
  ensemble <- filter(dat, location_name == "National", model == 'COVIDhub-ensemble',
    target %in% selected_targets)
  plot(select(obs, wk_end_date, value), 
    xlim=c(min(obs$wk_end_date), max(fcasts$wk_end_date)), 
    ylim=c(0, max(fcasts$quantile_0.975, na.rm=T)),
    pch=16, col='black', axes=F, xlab='', ylab='')
  abline(h=pretty(c(0, fcasts$point, fcasts$quantile_0.975), 10), 
    col = "grey70", lty = 3, lwd = 0.5)
  abline(v=pretty(c(obs$wk_end_date, fcasts$wk_end_date), 10), 
    col = "grey70", lty = 3, lwd = 0.5)
  lines(select(obs, wk_end_date, value))
  for (this_model in unique(fcasts$model)) {
    lines(filter(fcasts, model == this_model) %>% 
        select(wk_end_date, point), 
      col='darkgrey')
  }
  plot_bands(ensemble %>% 
        select(wk_end_date, quantile_0.025, quantile_0.975),
      col=adjustcolor(model_colors['COVIDhub-ensemble'], 0.25), border=NA)
  # plot_bands(ensemble %>% 
  #     select(wk_end_date, quantile_0.25, quantile_0.75),
  #   col=adjustcolor(model_colors['COVIDhub-ensemble'], 0.5), border=NA)
  points(ensemble %>% select(wk_end_date, point),
      col=model_colors['COVIDhub-ensemble'], pch=16)
  lines(ensemble %>% select(wk_end_date, point),
      col=model_colors['COVIDhub-ensemble'])
  axis.Date(1, at=pretty(c(obs$wk_end_date, fcasts$wk_end_date), 10), 
    labels=format(pretty(c(obs$wk_end_date, fcasts$wk_end_date), 10), '%b-%d'), 
      cex.axis=0.75)
  axis(2)
  legend('topleft', legend=c("Ensemble", "Individual models"), 
    fill=c(model_colors['COVIDhub-ensemble'], 'darkgrey'), border=NA, 
    bty='n')
  dev.off()
}
plot_us()
#dev.off()


plot_all <- function() {
  pdf(paste0("./static-plots/Consolidated-Forecasts-", inclusion_dates[1], ".pdf"), 
    width=7.5, height=10, paper='letter')
  par(mfrow=c(5, 2), mar=c(1.25, 1.25, 1.25, 0.5), oma=c(2.5, 2.5, 2, 0), 
    mgp=c(0.5, 0.3, 0), tck=-0.01)
  for (i in 1:length(all_locations)) {
    this_location <- all_locations[i]
    obs <- filter(obs_data, location_name == this_location)
    if (nrow(obs) == 0) {
      print(this_location)
      next
    }
    fcasts <- filter(dat, location_name == this_location, model != 'COVIDhub-ensemble',
      target %in% selected_targets)
    plot(select(obs, wk_end_date, value), 
      xlim=c(min(obs$wk_end_date), max(fcasts$wk_end_date)), 
      ylim=c(0, max(fcasts$quantile_0.975, na.rm=T)),
      pch=16, col='black', axes=F, xlab='', ylab='')
    mtext(this_location, 3, -0.25, adj=0, font=2)
    #abline(h=., lty=3, col='grey70', lwd=0.5)
    #grid(lty=3, col='grey70', lwd=0.5)
    #grid(nx=NA, ny=NULL)
  abline(h=pretty(c(0, fcasts$point, fcasts$quantile_0.975), 10), 
    col = "grey70", lty = 3, lwd = 0.5)
  abline(v=pretty(c(obs$wk_end_date, fcasts$wk_end_date), 10), 
    col = "grey70", lty = 3, lwd = 0.5)
    lines(select(obs, wk_end_date, value))
    for (this_model in unique(fcasts$model)) {
      plot_bands(filter(fcasts, model == this_model) %>% 
          select(wk_end_date, quantile_0.025, quantile_0.975),
        col=adjustcolor(model_colors[this_model], 0.25), border=NA)
    }
    for (this_model in unique(fcasts$model)) {
      lines(filter(fcasts, model == this_model) %>% 
          select(wk_end_date, point), 
        col=adjustcolor(model_colors[this_model]))
      points(filter(fcasts, model == this_model) %>% 
          select(wk_end_date, point), 
        col=adjustcolor(model_colors[this_model]), pch=16)
    }
  axis.Date(1, at=pretty(c(obs$wk_end_date, fcasts$wk_end_date), 10), 
    labels=format(pretty(c(obs$wk_end_date, fcasts$wk_end_date), 10), '%b-%d'), 
      cex.axis=0.75)
  axis(2)
    legend('topleft', legend=c('Reported', model_display_names[unique(fcasts$model)]), 
      fill=c('black', model_colors[unique(fcasts$model)]), border=NA, 
      bty='n')
    
    ### plot ensemble
    ensemble <- filter(dat, location_name == this_location, model == 'COVIDhub-ensemble',
      target %in% selected_targets)
    plot(select(obs, wk_end_date, value), 
      xlim=c(min(obs$wk_end_date), max(fcasts$wk_end_date)), 
      ylim=c(0, max(fcasts$quantile_0.975, na.rm=T)),
      pch=16, col='black', axes=F, xlab='', ylab='')
  abline(h=pretty(c(0, fcasts$point, fcasts$quantile_0.975), 10), 
    col = "grey70", lty = 3, lwd = 0.5)
  abline(v=pretty(c(obs$wk_end_date, fcasts$wk_end_date), 10), 
    col = "grey70", lty = 3, lwd = 0.5)
    lines(select(obs, wk_end_date, value))
    for (this_model in unique(fcasts$model)) {
      lines(filter(fcasts, model == this_model) %>% 
          select(wk_end_date, point), 
        col='darkgrey')
    }
    plot_bands(ensemble %>% 
          select(wk_end_date, quantile_0.025, quantile_0.975),
        col=adjustcolor(model_colors['COVIDhub-ensemble'], 0.25), border=NA)
    # plot_bands(ensemble %>% 
    #     select(wk_end_date, quantile_0.25, quantile_0.75),
    #   col=adjustcolor(model_colors['COVIDhub-ensemble'], 0.5), border=NA)
    points(ensemble %>% select(wk_end_date, point),
        col=model_colors['COVIDhub-ensemble'], pch=16)
    lines(ensemble %>% select(wk_end_date, point),
        col=model_colors['COVIDhub-ensemble'])
    #axis.Date(1, pretty(c(obs$wk_end_date, fcasts$wk_end_date)))
    legend('topleft', legend=c("Ensemble", "Individual models"), 
      fill=c(model_colors['COVIDhub-ensemble'], 'darkgrey'), border=NA, 
      bty='n')
    axis.Date(1, at=pretty(c(obs$wk_end_date, fcasts$wk_end_date), 10), 
    labels=format(pretty(c(obs$wk_end_date, fcasts$wk_end_date), 10), '%b-%d'), 
      cex.axis=0.75)
    if ((i - 1)/5 == round((i - 1)/5)) {
      mtext("Cumulative reported deaths", 2, 1, outer=T)
    }
    mtext(paste0("Update: ", inclusion_dates[1] + 1), 3, 1, adj=0, outer=T, cex=0.75)
    mtext("https://www.cdc.gov/coronavirus/2019-ncov/covid-data/forecasting-us.html", 
      3, 1, adj=1, outer=T, cex=0.75)
  }
  dev.off()
}
plot_all()


