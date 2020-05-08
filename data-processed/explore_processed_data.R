# execute this script in this directory (data-processed/)

# Provides a shiny dashboard to explore the processed data

library("tidyverse")
library("shiny")
library("DT")
library("rmarkdown")

options(DT.options = list(pageLength = 25))

source("../code/processing-fxns/get_next_saturday.R")
source("read_processed_data.R")

# Further process the processed data for ease of exploration
latest <- all_data %>% 
  filter(!is.na(forecast_date)) %>%
  group_by(team, model) %>%
  dplyr::filter(forecast_date == max(forecast_date)) %>%
  ungroup() %>%
  tidyr::separate(target, into=c("n_unit","unit","ahead","inc_cum","death_cases"),
                  remove = FALSE)

latest_locations <- latest %>%
  dplyr::group_by(team, model, forecast_date) %>%
  dplyr::summarize(US = ifelse(any(fips_alpha == "US"), "Yes", "-"),
                   n_states = sum(state.abb %in% fips_alpha),
                   other = paste(unique(setdiff(fips_alpha, c(state.abb,"US"))),
                                 collapse = " "),
                   missing_states = paste(unique(setdiff(state.abb, fips_alpha)),
                                          collapse = " "),
                   missing_states = ifelse(missing_states == paste(state.abb, collapse = " "), 
                                           "all", missing_states),
                   missing_states = ifelse(nchar(missing_states) > 7, 
                                           "...lots...", missing_states)
                   )


latest_targets <- latest %>%
  dplyr::group_by(team, model, forecast_date, type, unit, ahead, inc_cum, death_cases) %>%
  dplyr::summarize(max_n = max(as.numeric(n_unit))) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(target = paste(unit, ahead, inc_cum, death_cases)) %>%
  dplyr::select(team, model, forecast_date, type, max_n, target) %>%
  dplyr::arrange(team, model, forecast_date, type, target)

# Quantiles
full_quantiles <- sprintf("%.3f", c(0.01, 0.025, seq(0.05, 0.95, by = 0.05), 0.975, 0.99))
min_quantiles  <- sprintf("%.3f", c(0.01, 0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.99))

latest_quantiles <- latest %>%
  dplyr::filter(type == "quantile") %>%
  dplyr::mutate(quantile = sprintf("%.3f", quantile)) %>%
  dplyr::group_by(team, model, forecast_date, target) %>%
  dplyr::summarize(
    full = all(full_quantiles %in% quantile),
    min  = all(min_quantiles  %in% quantile),
    quantiles = paste(unique(quantile), collapse = " ")) 

latest_quantiles_summary <- latest_quantiles %>%
  dplyr::group_by(team, model, forecast_date) %>%
  dplyr::summarize(
    all_full = ifelse(all(full), "Yes", "-"),
    any_full = ifelse(any(full), "Yes", "-"),
    all_min  = ifelse(all(min),  "Yes", "-"),
    any_min  = ifelse(any(min),  "Yes", "-")
  )

offset <- 0 # currently 7 for testing, but should be 0
ensemble_data <- latest %>%
  filter(forecast_date > get_next_saturday(Sys.Date())-9)
  # filter( (target_end_date == get_next_saturday(Sys.Date()-offset) & grepl("1 wk", target)) |
  #           (target_end_date == get_next_saturday(Sys.Date()+ 7-offset) & grepl("2 wk", target))|
  #           (target_end_date == get_next_saturday(Sys.Date()+14-offset) & grepl("3 wk", target))|
  #           (target_end_date == get_next_saturday(Sys.Date()+21-offset) & grepl("4 wk", target)))


ensemble <- ensemble_data %>%
  group_by(team, model, forecast_date) %>%
  filter(model != "ensemble", 
         unit == "wk",
         type == "quantile",
         death_cases == "death") %>%
  dplyr::summarize(
    median    = ifelse(any(quantile == 0.5, na.rm = TRUE), "Yes", "-"),
    cum_death = ifelse(all(paste(1:4, "wk ahead cum death") %in% target), "Yes", "-"),
    inc_death = ifelse(all(paste(1:4, "wk ahead inc death") %in% target), "Yes", "-"),
    all_weeks = ifelse(all(1:4 %in% n_unit), "Yes", "-"),
    has_US    = ifelse("US" %in% fips_alpha, "Yes", "-"),
    has_states = ifelse(all(state.abb %in% fips_alpha), "Yes", "-")
  )

ensemble_quantiles <- ensemble_data %>%
  filter(model != "ensemble", !is.na(quantile)) %>%
  select(team, model, forecast_date, quantile) %>%
  unique() %>%
  mutate(yes = "Yes",
         quantile = as.character(quantile)) 

g_ensemble_quantiles <- ggplot(ensemble_quantiles %>%
                                 mutate(team_model = paste(team,model,sep="-")), 
                               aes(x = quantile, y = team_model, fill = yes)) +
  geom_tile() +
  theme_bw() + 
  theme(legend.position = "none",
        axis.text.x = element_text(angle = 90, hjust = 1))



# Define UI for application that draws a histogram
ui <- navbarPage(
  "Explore:",
  
  tabPanel("Latest locations", 
           DT::DTOutput("latest_locations")),
  
  tabPanel("Latest targets",  
           h5("max_n: the farthest ahead forecast for this target (does not guarantee that all earlier targets exist)"),
           DT::DTOutput("latest_targets")),
  
  tabPanel("Latest quantiles", 
           h3("Quantiles collapsed over targets"),
           h5("all_full: the full set of 23 quantiles exists in all targets"),
           h5("any_full: the full set of 23 quantiles exists in at least one target"),
           h5("all_min: the minimum set of 9 quantiles exists in all targets"),
           h5("any_min: the minimum set of 9 quantiles exists in at least one target"),
           DT::DTOutput("latest_quantiles_summary"), 
           h3("Quantiles by target"),
           DT::DTOutput("latest_quantiles")),
  
  tabPanel("Ensemble",           
           DT::DTOutput("ensemble"),
           # DT::DTOutput("ensemble_quantiles"),
           plotOutput("ensemble_quantile_plot")),
  
  tabPanel("Latest",           
           DT::DTOutput("latest")),
  
  tabPanel("All",              
           DT::DTOutput("all_data")),
  
  tabPanel("Help",
           h3("Explore tabs"),
           h5("All: contains all of the processed data including those with missing required fields"),
           h5("Latest: subset of `All` that only contains the most recent forecast for each team-model"),
           h5("Latest targets: summarizes `Latest` to see which targets are included"),
           h5("Latest locations: summarizes `Latest` to see which locations are included"),
           h5("Latest quantiles: summarizes `Latest` to see which quantiles are included"),
           h3("Usage"),
           h4("Each table has the capability to be searched and filtered")
           )
)


# Define server logic required to draw a histogram
server <- function(input, output) {
  
  output$latest_targets   <- DT::renderDT(latest_targets,   filter = "top")
  output$latest_locations <- DT::renderDT(latest_locations, filter = "top")
  output$latest_quantiles <- DT::renderDT(latest_quantiles, filter = "top")
  output$latest_quantiles_summary <- DT::renderDT(latest_quantiles_summary, filter = "top")
  
  output$ensemble         <- DT::renderDT(ensemble,         filter = "top")
  # output$ensemble_quantiles        <- DT::renderDT(ensemble_quantiles,         filter = "top")
  output$ensemble_quantile_plot <- shiny::renderPlot(g_ensemble_quantiles)
  
  output$latest           <- DT::renderDT(latest,           filter = "top")
  
  output$all_data         <- DT::renderDT(all_data,         filter = "top")
}

# Run the application 
shinyApp(ui = ui, server = server)
