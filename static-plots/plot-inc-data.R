## code to plot day ahead incident death data

rm(list=ls())

library(tidyverse)
library(scales)
library(zoo)
theme_set(theme_minimal())

source("code/processing-fxns/get_next_saturday.R")

inclusion_dates <- as.Date("2020-04-28") - 0:3
models_to_exclude <- c("CU-nointerv", "Geneva-DeterministicGrowth")

## get truth data
obs_data <- read_csv("data-truth/truth-Incident Deaths.csv") %>%
    mutate(target_end_date = as.Date(date, "%m/%d/%y"),
        location_name = ifelse(location == 'US', 'National', location_name),
        model="Reported new deaths (JHU)", type="point") %>%
    select(-date) 

smooth_data <- obs_data %>% 
    group_by(location) %>%
    arrange(location, target_end_date) %>%
    mutate(model="Smoothed new deaths (JHU)", 
        value = rollmean(x = value, 7, align = "center", fill = NA))


datapath <- "data-processed"
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
model_names <- str_split(filenames, "/", simplify = TRUE)[ , 2]

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

dat_to_plot <- all_dat %>%
    mutate(quantile = round(as.numeric(quantile), 3)) %>%
    filter(!(model %in% models_to_exclude), ## drop excluded models
        grepl("day ahead inc death", target)) %>%   ## only include day-ahead targets
    # select(-location_name) %>%
    # left_join(location_names) %>% 
    mutate(target_end_date=as.Date(target_end_date))%>%
    bind_rows(obs_data) %>%
    bind_rows(smooth_data) %>%
    mutate(
        location_name = ifelse(location == 'US', 'National', location_name),
        location_name = ifelse(location_name == 'U.S. Virgin Islands', 'Virgin Islands', location_name),
    ) %>%
    mutate(days_ahead = str_extract(target, '\\d{1,2} day ahead')) %>%
    mutate(value = round(value)) %>%
    pivot_wider(names_from = c(type, quantile), values_from=value)
    


# ## reformat all the data
# dat <- all_dat %>%
#     filter(!(model %in% models_to_exclude), ## drop excluded models
#         grepl("day ahead inc death", target)) %>%   ## only include day-ahead targets
#     mutate(days_ahead = str_extract(target, '\\d{1,2} day ahead')) %>%
#     mutate(value = round(value), target_end_date=as.Date(target_end_date)) %>%
#     pivot_wider(names_from = c(type, quantile), values_from=value) %>%
#     rename(point = point_NA)

## change model labels


## set colors
cols <- c("darkred", "#F3DF6C", "#CEAB07", "#D5D5D3", "#798E87", "#C27D38", 
    "#CCC591", "#85D4E3", "#F4B5BD", "#9C964A", "#FAD77B", 
    "#02401B", "#A2A475", "#81A88D", "#972D15", 
    "#D8B70A", "#02401B", "#A2A475", "#81A88D", "#972D15")
model_colors <- c(
    "COVIDhub-ensemble" = cols[1],
    "LANL-GrowthRate" = cols[2],
    "MOBS_NEU-GLEAM_COVID" = cols[3],
    "IHME-CurveFit" = cols[4],
    "CU-60contact" = cols[5],
    "CU-70contact" = cols[6],
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
    "UMass-MechBayes" = cols[17]
)

model_display_names <- c(
    "COVIDhub-ensemble" = "Ensemble",
    "LANL-GrowthRate" = "LANL",
    "MOBS_NEU-GLEAM_COVID" = "MOBS",
    "IHME-CurveFit" = "IHME",
    "CU-60contact" = "CU-40", 
    "CU-70contact" = "CU-30",
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
    "UMass-MechBayes" = "UMass-MB"
)

### plots

ggplot(filter(dat_to_plot, location_name=="Florida"), aes(x=target_end_date, y=point_NA, color=model)) +
    geom_line() +
    ylab("incident COVID-19 deaths per day") + xlab(NULL)+
    scale_x_date(limits=c(as.Date("2020-01-15"), as.Date("2020-08-01")), date_breaks="1 month", date_labels = "%b") +
    scale_y_continuous(labels = comma) +
    # scale_color_manual(values=model_colors) 
    #scale_alpha_manual(guide=FALSE) +
    #scale_fill_manual(values = model_colors, guide=FALSE) +
    theme(legend.position = c(0,1), legend.justification = c(0,1), legend.title = element_blank())
    
