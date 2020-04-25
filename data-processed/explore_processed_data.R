# execute this script in this directory (data-processed/)

# Provides a shiny dashboard to explore the processed data

library("shiny")
library("rmarkdown")

source("read_processed_data.R")

# Further process the processed data for ease of exploration
latest <- all_data %>% 
  group_by(team, model) %>%
  dplyr::filter(forecast_date == max(forecast_date)) %>%
  ungroup() %>%
  filter(!is.na(forecast_date)) %>%
  tidyr::separate(target, into=c("n","unit","ahead","inc_cum","death_cases"),
                  remove = FALSE)

latest_locations <- latest %>%
  dplyr::group_by(team, model, forecast_date) %>%
  summarize(US = ifelse(any(fips_alpha == "US"), "Yes", "-"),
            n_states = length(state.abb %in% fips_alpha),
            other = paste(unique(setdiff(fips_alpha, c(state.abb,"US"))),
                          collapse = " "))

latest_targets <- latest %>%
  dplyr::group_by(team, model, forecast_date, type, unit, ahead, inc_cum, death_cases) %>%
  dplyr::summarize(max_n = max(n)) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(target = paste(unit, ahead, inc_cum, death_cases)) %>%
  dplyr::select(team, model, forecast_date, type, max_n, target) %>%
  dplyr::arrange(team, model, forecast_date, type, target)






# Define UI for application that draws a histogram
ui <- navbarPage(
  "Explore:",
  tabPanel("Latest targets",   DT::DTOutput("latest_targets")),
  tabPanel("Latest locations", DT::DTOutput("latest_locations")),
  tabPanel("Latest",           DT::DTOutput("latest")),
  
  tabPanel("All",              DT::DTOutput("all_data"))
  )

# Define server logic required to draw a histogram
server <- function(input, output) {
  
  output$latest_targets   <- DT::renderDT(latest_targets,   filter = "top")
  output$latest_locations <- DT::renderDT(latest_locations, filter = "top")
  output$latest           <- DT::renderDT(latest,           filter = "top")
  
  output$all_data         <- DT::renderDT(all_data,         filter = "top")
}

# Run the application 
shinyApp(ui = ui, server = server)


