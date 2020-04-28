# execute this script in this directory (data-processed/)

# Provides a shiny dashboard to explore the processed data

library("shiny")
library("rmarkdown")

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
                                 collapse = " "))

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
  output$latest           <- DT::renderDT(latest,           filter = "top")
  
  output$all_data         <- DT::renderDT(all_data,         filter = "top")
}

# Run the application 
shinyApp(ui = ui, server = server)


