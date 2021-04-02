library(zoltr) ## devtools::install_github("reichlab/zoltr")
library(tidyverse)
library(lubridate)
theme_set(theme_bw())

## load special functions
source("code/exploration/get_filtered_counties.R")
source("code/processing-fxns/get_next_saturday.R")

## get county info
high_pop_counties <- get_filtered_counties(n_top=15)

## get truth data
inc_cases <- read_csv("data-truth/truth-Incident Cases.csv") %>%
    filter(location %in% c(high_pop_counties$FIPS, "US")) %>%
    rename(target_end_date = date, fips = location) %>%
    mutate(model = "observed data (JHU)") %>%
    group_by(fips, model) %>% arrange(target_end_date) %>%
    mutate(value = RcppRoll::roll_sum(value, 7, align = "right", fill = NA)) %>%
    ungroup() %>%
    left_join(select(high_pop_counties, FIPS, loc_name, Population), by=c("fips" = "FIPS")) %>%
    filter(target_end_date %in% seq.Date(as.Date("2020-01-25"), to = Sys.Date(), by="1 week"))

## connect to Zoltar
zoltar_connection <- new_connection()
zoltar_authenticate(zoltar_connection, Sys.getenv("Z_USERNAME"), Sys.getenv("Z_PASSWORD"))

## construct Zoltar query
project_url <- "https://www.zoltardata.com/api/project/44/"
list_query <- list(
    "units" = as.list(c(high_pop_counties$FIPS, "US")),
    "types" = list("point"),
    "timezeros" = list("2020-07-19", "2020-07-20"),
    "targets" = as.list(paste(1:8, "wk ahead inc case"))
)
zoltar_query <- zoltr::query_with_ids(zoltar_connection, project_url, list_query)

dat <- zoltr:: do_zoltar_query(
    zoltar_connection, project_url, 
    units = c(high_pop_counties$FIPS, "US"),
    targets = paste(1:8, "wk ahead inc case"),
    timezeros = as.character(this_monday),
    types = c("point", "quantile"), 
    verbose = FALSE) %>%
    ## choose only columns we need and with data
    select(model, timezero, unit, target, class, quantile, value) %>%
    rename(fips=unit) %>%
    ## create rate variable and week-ahead
    mutate(week_ahead = as.numeric(substr(target, 0,1)),
        ## recreates the target_end_date from GitHub
        target_end_date = get_next_saturday(timezero + 7*(week_ahead-1))) %>%
    ## combine with county-level info
    left_join(select(high_pop_counties, FIPS, Admin2, Province_State, Population, loc_name), by = c("unit" = "FIPS")) %>%
    bind_rows(inc_cases) %>%
    mutate(model = relevel(factor(model), ref = "observed data (JHU)"),
        inc_case_rate = value/Population)

## plotting    
ggplot(dat, aes(x=target_end_date, y=value, color=model)) +
    geom_point(size=1) + geom_line() +
    facet_wrap(.~loc_name, scales = "free_y") +
    xlab(NULL) + ylab("incident cases by week") +
    theme(legend.position = "bottom")

ggplot(dat, aes(x=target_end_date, y=inc_case_rate, color=model)) +
    geom_point(size=1) + geom_line() +
    facet_wrap(.~loc_name, scales = "free_y") +
    xlab(NULL) + ylab("incident case rate by week") +
    theme(legend.position = "bottom")

case_models_in_ensemble <- c("UMass-MechBayes", "Columbia_UNC-SurvCon", 
    "COVIDhub-baseline", "UMich-RidgeTfReg", "LANL-GrowthRate", 
    "LNQ-ens1", "UCLA-SuEIR", "USACE-ERDC_SEIR", "observed data (JHU)")

ggplot(filter(dat, model %in% case_models_in_ensemble), 
    aes(x=target_end_date, y=inc_case_rate*1000, color=model)) +
    geom_point(size=1, alpha=.7) + geom_line() +
    facet_wrap(.~loc_name) +
    xlab(NULL) + ylab("incident case rate by week (per 1000 pop'n)") +
    scale_x_date(date_breaks = "1 month", date_labels = "%b %d") +
    scale_color_manual(name=NULL, values = c("#2B2D2F", RColorBrewer::brewer.pal(length(case_models_in_ensemble)-1, "Dark2"))) +
    theme(legend.position = "bottom", axis.text.x = element_text(angle=90, vjust=0.5)) +
    labs(title="Incident rates of reported COVID-19 cases (observed data and forecasts)",
        caption="source: JHU CSSE (observed data), COVID-19 Forecast Hub (forecasts)")

selected_models <- c("UMass-MechBayes", "COVIDhub-baseline", 
    "COVIDhub-ensemble", "LANL-GrowthRate", 
    "LNQ-ens1", "UCLA-SuEIR", "observed data (JHU)")

## case plot
ggplot(filter(dat, model %in% selected_models), 
    aes(x=target_end_date, y=value, color=model)) +
    geom_point(size=1, alpha=.9) + geom_line() +
    facet_wrap(.~loc_name, scales = "free_y") +
    xlab(NULL) + ylab("incident cases by week") +
    scale_x_date(date_breaks = "1 month", date_labels = "%b %d") +
    scale_color_manual(name=NULL, values = c("#2B2D2F", RColorBrewer::brewer.pal(length(selected_models)-1, "Dark2"))) +
    theme(legend.position = "bottom", axis.text.x = element_text(angle=90, vjust=0.5)) +
    labs(title="Weekly reported COVID-19 cases (observed and forecasted)",
        subtitle="US and 15 most-populous counties",
        caption="source: JHU CSSE (observed data), COVID-19 Forecast Hub (forecasts)")

## rate plot
ggplot(filter(dat, model %in% selected_models), 
    aes(x=target_end_date, y=inc_case_rate*1000, color=model)) +
    geom_point(size=1, alpha=.9) + geom_line() +
    facet_wrap(.~loc_name, scales = "free_y") +
    xlab(NULL) + ylab("incident case rate by week (per 1000 pop'n)") +
    scale_x_date(date_breaks = "1 month", date_labels = "%b %d") +
    scale_color_manual(name=NULL, values = c("#2B2D2F", RColorBrewer::brewer.pal(length(selected_models)-1, "Dark2"))) +
    theme(legend.position = "bottom", axis.text.x = element_text(angle=90, vjust=0.5)) +
    labs(title="Weekly rates per 1,000 people of new reported COVID-19 cases (observed and forecasted)",
        subtitle="US and 15 most-populous counties",
        caption="source: JHU CSSE (observed data), COVID-19 Forecast Hub (forecasts)")

