# execute this script in this directory (data-processed/)

# Provides a shiny dashboard to explore the processed data

library("tidyverse")
library("ggnewscale")
library("shiny")
library("DT")
library("rmarkdown")
library("MMWRweek")

options(DT.options = list(pageLength = 25))

source("../code/processing-fxns/get_next_saturday.R")
source("read_processed_data.R")

fourweek_date <- get_next_saturday(Sys.Date() + 3*7)

###############################################################################
# Get truth 
truth_cols = readr::cols_only(
  date          = readr::col_date(format = ""),
  location      = readr::col_character(),
  # location_name = readr::col_character(),
  value         = readr::col_double()
)

# JHU
inc_jhu = readr::read_csv("../data-truth/truth-Incident Deaths.csv",   
                      col_types = truth_cols) %>%
  dplyr::mutate(inc_cum = "inc", source = "JHU-CSSE") %>%
  na.omit()

cum_jhu = readr::read_csv("../data-truth/truth-Cumulative Deaths.csv", 
                      col_types = truth_cols) %>%
  dplyr::mutate(inc_cum = "cum", source = "JHU-CSSE")


# USAFacts
inc_usa = readr::read_csv("../data-truth/usafacts/truth_usafacts-Incident Deaths.csv",
                          col_types = truth_cols) %>%
  dplyr::mutate(inc_cum = "inc", source = "USAFacts") %>%
  na.omit()

cum_usa = readr::read_csv("../data-truth/usafacts/truth_usafacts-Cumulative Deaths.csv", 
                          col_types = truth_cols) %>%
  dplyr::mutate(inc_cum = "cum", source = "USAFacts")


# NYTimes 
inc_nyt = readr::read_csv("../data-truth/nytimes/truth_nytimes-Incident Deaths.csv",
                          col_types = truth_cols) %>%
  dplyr::mutate(inc_cum = "inc", source = "NYTimes") %>%
  na.omit()

cum_nyt = readr::read_csv("../data-truth/nytimes/truth_nytimes-Cumulative Deaths.csv", 
                          col_types = truth_cols) %>%
  dplyr::mutate(inc_cum = "cum", source = "NYTimes")



truth = bind_rows(
  bind_rows(inc_jhu, inc_usa, inc_nyt) %>% dplyr::mutate(unit = "day"),
  
  bind_rows(inc_jhu, inc_usa, inc_nyt) %>% 
    dplyr::mutate(week = MMWRweek::MMWRweek(date)$MMWRweek) %>%
    dplyr::group_by(location, week, inc_cum, source) %>%
    dplyr::summarize(date = max(date),
                     value = sum(value, na.rm = TRUE)) %>%
    dplyr::ungroup() %>%
    dplyr::filter(weekdays(date) == "Saturday") %>%
    dplyr::mutate(unit = "wk") %>%
    dplyr::select(-week),
  
  bind_rows(cum_jhu, cum_usa, cum_nyt) %>% 
    dplyr::mutate(unit = "wk") %>%
    dplyr::filter(weekdays(date) == "Saturday"),
  
  bind_rows(cum_jhu, cum_usa, cum_nyt) %>% dplyr::mutate(unit = "day")
) %>%
  dplyr::left_join(locations, by = c("location")) %>%
  dplyr::mutate(death_cases = "death",
         simple_target = paste(unit, "ahead", inc_cum, death_cases)) 

truth_sources = unique(truth$source)

###############################################################################


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
  dplyr::summarize(US = ifelse(any(abbreviation == "US", na.rm=TRUE), "Yes", "-"),
                   n_states = sum(state.abb %in% abbreviation),
                   other = paste(unique(setdiff(abbreviation, c(state.abb,"US"))),
                                 collapse = " "),
                   missing_states = paste(unique(setdiff(state.abb, abbreviation)),
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
quantiles = list(
  full = sprintf("%.3f", c(0.01, 0.025, seq(0.05, 0.95, by = 0.05), 0.975, 0.99)),
  min  = sprintf("%.3f", c(0.01, 0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.99))
)

latest_quantiles <- latest %>%
  dplyr::filter(type == "quantile") %>%
  dplyr::mutate(quantile = sprintf("%.3f", quantile)) %>%
  dplyr::group_by(team, model, forecast_date, target) %>%
  dplyr::summarize(
    full = all(quantiles$full %in% quantile),
    min  = all(quantiles$min  %in% quantile),
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
  filter(forecast_date > get_next_saturday(Sys.Date())-offset-9)
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
    has_US    = ifelse("US" %in% abbreviation, "Yes", "-"),
    has_states = ifelse(all(state.abb %in% abbreviation), "Yes", "-")
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



###############################################################################
# Create shiny latest plot
latest_plot_data <- latest %>%
  filter(quantile %in% c(.025,.25,.5,.75,.975) | type == "point") %>%
  
  mutate(quantile = ifelse(type == "point", "point", quantile),
         simple_target = paste(unit,ahead,inc_cum, death_cases)) %>%
  select(-type) %>%
  tidyr::pivot_wider(
    names_from = quantile,
    values_from = value
  )







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
  
  tabPanel("Latest Viz",
           sidebarLayout(
             sidebarPanel(
               selectInput("team",         "Team", sort(unique(latest_plot_data$team         )), "IHME"),
               selectInput("model",       "Model", sort(unique(latest_plot_data$model        ))),
               selectInput("target",     "Target", sort(unique(latest_plot_data$simple_target))),
               selectInput("abbreviation", "Location", sort(unique(latest_plot_data$abbreviation   ))),
               selectInput("sources", "Truth sources", truth_sources, selected = "JHU-CSSE", multiple = TRUE),
               dateRangeInput("dates", "Date range", start = "2020-03-01", end = fourweek_date)
             ), 
             mainPanel(
               plotOutput("latest_plot")
             )
           )
           ),
  
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
           ),
  
  selected = "Latest Viz"
)


# Define server logic required to draw a histogram
server <- function(input, output, session) {
  
  output$latest_targets   <- DT::renderDT(latest_targets,   filter = "top")
  output$latest_locations <- DT::renderDT(latest_locations, filter = "top")
  output$latest_quantiles <- DT::renderDT(latest_quantiles, filter = "top")
  output$latest_quantiles_summary <- DT::renderDT(latest_quantiles_summary, filter = "top")
  
  output$ensemble         <- DT::renderDT(ensemble,         filter = "top")
  # output$ensemble_quantiles        <- DT::renderDT(ensemble_quantiles,         filter = "top")
  output$ensemble_quantile_plot <- shiny::renderPlot(g_ensemble_quantiles)
  
  output$latest           <- DT::renderDT(latest,           filter = "top")
  
  #############################################################################
  # Latest viz: Filter data based on user input
  
  observe({
    models <- sort(unique(latest_t()$model))
    updateSelectInput(session, "model", choices = models, selected = models[1])
  })
  
  observe({
    targets <- sort(unique(latest_tm()$simple_target))
    updateSelectInput(session, "target", choices = targets, 
                      selected = ifelse("wk ahead cum death" %in% targets, 
                                        "wk ahead cum death", 
                                        targets[1]))
  })
  
  observe({
    abbreviations <- sort(unique(latest_tmt()$abbreviation))
    updateSelectInput(session, "abbreviation", choices = abbreviations, 
                      selected = ifelse("US" %in% abbreviations, 
                                        "US", 
                                        abbreviations[1]))
  })
  
  
  latest_t    <- reactive({ latest_plot_data %>% filter(team          == input$team) })
  latest_tm   <- reactive({ latest_t()       %>% filter(model         == input$model) })
  latest_tmt  <- reactive({ latest_tm()      %>% filter(simple_target == input$target) })
  latest_tmtl <- reactive({ latest_tmt()     %>% filter(abbreviation    == input$abbreviation) })
  
  truth_plot_data <- reactive({ 
    input_simple_target <- unique(paste(
      latest_tmtl()$unit, "ahead", latest_tmtl()$inc_cum, latest_tmtl()$death_cases))
    
    tmp = truth %>% 
      filter(abbreviation == input$abbreviation,
             grepl(input_simple_target, simple_target),
             source %in% input$sources)
  })
  
  

  
  output$latest_plot      <- shiny::renderPlot({
    d    <- latest_tmtl()
    team <- unique(d$team)
    model <- unique(d$model)
    forecast_date <- unique(d$forecast_date)
    
    ggplot(d, aes(x = target_end_date)) + 
      geom_ribbon(aes(ymin = `0.025`, ymax = `0.975`, fill = "95%")) +
      geom_ribbon(aes(ymin = `0.25`, ymax = `0.75`, fill = "50%")) +
      scale_fill_manual(name = "", values = c("95%" = "lightgray", "50%" = "gray")) +
      
      geom_point(aes(y=`0.5`, color = "median")) + geom_line( aes(y=`0.5`, color = "median")) + 
      geom_point(aes(y=point, color = "point")) + geom_line( aes(y=point, color = "point")) + 
      
      scale_color_manual(name = "", values = c("median" = "slategray", "point" = "black")) +
      
      ggnewscale::new_scale_color() +
      geom_line(data = truth_plot_data(),
                aes(x = date, y = value, 
                    linetype = source, color = source, group = source)) +
      
      scale_color_manual(values = c("JHU-CSSE" = "green",
                                    "USAFacts" = "seagreen",
                                    "NYTimes"  = "darkgreen")) +
      
      scale_linetype_manual(values = c("JHU-CSSE" = 1,
                                    "USAFacts" = 2,
                                    "NYTimes"  = 3)) +
      
      xlim(input$dates) + 
      
      labs(x = "Date", y="Number", 
           title = paste("Forecast date:", forecast_date)) +
      theme_bw() +
      theme(plot.title = element_text(color = ifelse(Sys.Date() - forecast_date > 6, "red", "black")))
  })
  
  output$all_data         <- DT::renderDT(all_data,         filter = "top")
}

# Run the application 
shinyApp(ui = ui, server = server)
