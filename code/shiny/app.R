library("drake")
library("tidyverse")
library("shiny")
library("tidyr")
library("dplyr")
library("DT")
library("shinyWidgets")
library("scales")

options(DT.options = list(pageLength = 50))

source("code/processing-fxns/get_next_saturday.R")

fourweek_date = get_next_saturday(Sys.Date() + 3*7)
loadd(truth)
truth_sources = unique(truth$source)
loadd(latest_locations)
loadd(latest_targets)
loadd(plot_submissions)
loadd(latest_quantiles)
loadd(latest_quantiles_summary)
loadd(latest_plot_data)

ui <- navbarPage(
  "Explore:",
  
  tabPanel("Latest locations", 
           DT::DTOutput("latest_locations")),
  
  tabPanel("Latest targets", 
           DT::DTOutput("latest_targets")),
  

  tabPanel("Submissions",  
           sidebarLayout(
             sidebarPanel(
               shinyWidgets::pickerInput("submissions_model_abbr","Model Abbreviation", 
                                         sort(unique(plot_submissions$model_abbr)),
                                         selected = sort(unique(plot_submissions$model_abbr)),
                                         options = list(`actions-box` = TRUE), multiple = TRUE),
               selectInput("submissions_type","Type", sort(unique(plot_submissions$type))),
               selectInput("submissions_target","Target", sort(unique(plot_submissions$target))),
               dateRangeInput("submissions_dates", "Date range", start = "2020-03-15", end = Sys.Date())
             ), 
             mainPanel(
               plotOutput("submissions")
             )
           )
  ),
  
  tabPanel("Latest quantiles", 
           h3("Quantiles collapsed over targets"),
           h5("all_full: the full set of 23 quantiles exists in all targets"),
           h5("any_full: the full set of 23 quantiles exists in at least one target"),
           h5("all_min: the minimum set of 9 quantiles exists in all targets"),
           h5("any_min: the minimum set of 9 quantiles exists in at least one target"),
           DT::DTOutput("latest_quantiles_summary"), 
           h3("Quantiles by target"),
           DT::DTOutput("latest_quantiles")),

  
  tabPanel("Latest Viz",
           sidebarLayout(
             sidebarPanel(
               selectInput("model_abbr","Model Abbreviation", sort(unique(latest_plot_data$model_abbr )), 
                           shiny::getShinyOption("default_model_abbr",default = "COVIDhub-ensemble")),
               selectInput("target","Target", sort(unique(latest_plot_data$simple_target))),
               selectInput("abbreviation","Location", sort(unique(latest_plot_data$abbreviation   ))),
               selectInput("county","County", sort(unique(latest_plot_data$location_name  ))),
               selectInput("sources","Truth sources", truth_sources, selected = "JHU-CSSE", multiple = TRUE),
               dateRangeInput("dates","Date range", start = "2020-03-01", end =  fourweek_date)
             ), 
             mainPanel(
               plotOutput("latest_plot")
             )
           )
  ),
  
  tabPanel("Latest Viz by Location",
           sidebarLayout(
             sidebarPanel (
               selectInput("loc_state", "State", sort(unique(latest_plot_data$abbreviation))),
               selectInput("loc_county", "County", sort(unique(latest_plot_data$location_name))),
               selectInput("loc_target", "Target", sort(unique(latest_plot_data$simple_target))),
               selectInput("loc_sources", "Truth sources", truth_sources, selected = "JHU-CSSE", multiple = TRUE),
               selectInput("loc_model_abbr", "Model Abbreviation", sort(unique(latest_plot_data$model_abbr)),
                           selected =c("COVIDhub-ensemble","UMass-MechBayes", "LANL-GrowthRate", "YYG-ParamSearch", "UCLA-SuEIR"), multiple = TRUE),
               dateRangeInput("loc_dates", "Date range", start = "2020-03-01", end = fourweek_date)
             ),
             mainPanel(
               plotOutput("latest_plot_by_location")
             )
           )
  ),

  tabPanel("Help",
           h3("Explore tabs"),
           h5("Latest locations: summarizes `Latest` to see which locations are included"),
           h5("Latest targets: summarizes `Latest` to see which targets are included"),
           h5("Submissions: summarizes forecasts submissions for each team and each target"),
           h5("Latest quantiles: summarizes `Latest` to see which quantiles are included"),
           h5("Latest Viz: shows visualization for forecast for a selected location"),
           h5("Latest Viz by Location: compares forecast visualization for a selected location for selected models"),
           h3("Usage"),
           h4("Each table has the capability to be searched and filtered")
  ),
  
  selected = "Latest Viz"
)


# Define server logic 
server <- function(input, output, session) {
  
  output$latest_locations <- DT::renderDT(latest_locations, filter = "top")
  output$latest_targets   <- DT::renderDT(latest_targets,   filter = "top")
  output$latest_quantiles <- DT::renderDT(latest_quantiles, filter = "top")
  output$latest_quantiles_summary <- DT::renderDT(latest_quantiles_summary, filter = "top")
  
  #############################################################################
  # Latest viz: Filter data based on user input
  
  observe({
    targets <- sort(unique(latest_t()$simple_target))
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
  
  observe({
    counties <- unique(latest_tmtl()[order(latest_tmtl()$location),]$location_name)
    updateSelectInput(session, "county", choices = list(
      "All" = c(counties[1],""),
      "County" = counties[-1]
    ), selected =counties[1])
  })
  
  latest_t    <- reactive({ latest_plot_data %>% filter(model_abbr    == input$model_abbr) })
  latest_tmt  <- reactive({ latest_t()       %>% filter(simple_target == input$target) })
  latest_tmtl <- reactive({ latest_tmt()     %>% filter(abbreviation  == input$abbreviation) })
  latest_tmtlc <- reactive({ latest_tmtl()   %>% filter(location_name == input$county) })

  truth_plot_data <- reactive({ 
    input_simple_target <- unique(paste(
      latest_tmtlc()$unit, "ahead", latest_tmtlc()$inc_cum, latest_tmtlc()$death_cases))
    
    tmp = truth %>% 
      filter(abbreviation == input$abbreviation,
             location_name == input$county,
             grepl(input_simple_target, simple_target),
             source %in% input$sources)
  })
  
  output$latest_plot      <- shiny::renderPlot({
    d <- latest_tmtlc()
    model_abbr <- unique(d$model_abbr)
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
  
  #############################################################################
  # Latest viz by Location: Filter data based on user input
  latest_loc_l <- reactive({ latest_plot_data       %>% filter(abbreviation    == input$loc_state) })
  latest_loc_lc <- reactive({ latest_loc_l()        %>% filter(location_name   == input$loc_county) })
  latest_loc_ltc <- reactive({ latest_loc_lc()      %>% filter(simple_target   == input$loc_target) })
  latest_loc_ltct <- reactive({ latest_loc_ltc()    %>% filter(model_abbr     %in% input$loc_model_abbr) })
  
  observe({
    counties <- unique(latest_loc_l()[order(latest_loc_l()$location),]$location_name)
    updateSelectInput(session, "loc_county", choices = list(
      "All" = c(counties[1],""),
      "County" = counties[-1]
    ), selected =counties[1])
  })
  
  observe({
    targets <- sort(unique(latest_loc_lc()$simple_target))
    updateSelectInput(session, "loc_target", choices = targets, 
                      selected = ifelse("wk ahead cum death" %in% targets, 
                                        "wk ahead cum death", 
                                        targets[1]))
  })
  
  observe({
    model_abbrs <- sort(unique(latest_loc_ltc()$model_abbr))
    updateSelectInput(session, "loc_model_abbr", choices = model_abbrs, 
                      selected = ifelse(
                        c("COVIDhub-ensemble", "UMass-MechBayes","LANL-GrowthRate",
                          "YYG-ParamSearch","UCLA-SuEIR") %in% model_abbrs,
                        c("COVIDhub-ensemble", "UMass-MechBayes","LANL-GrowthRate",
                          "YYG-ParamSearch","UCLA-SuEIR"),
                        model_abbrs[1]))
  })
  
  truth_loc_plot_data <- reactive({ 
    input_simple_target <- unique(paste(
      latest_loc_ltct()$unit, "ahead", latest_loc_ltct()$inc_cum, 
      latest_loc_ltct()$death_cases))
    
    tmp = truth %>% 
      filter(abbreviation == input$loc_state,
             location_name == input$loc_county,
             grepl(input_simple_target, simple_target),
             source %in% input$loc_sources)
  })
  
  output$latest_plot_by_location      <- shiny::renderPlot({
    d <- latest_loc_ltct()
    model_abbr <- unique(d$model_abbr)
    forecast_date <- unique(d$forecast_date)
  
    ggplot(d, aes(x = target_end_date)) + 
      geom_ribbon(aes(ymin = `0.025`, ymax = `0.975`, fill = "95%")) +
      geom_ribbon(aes(ymin = `0.25`, ymax = `0.75`, fill = "50%")) +
      scale_fill_manual(name = "", values = c("95%" = "lightgray", "50%" = "gray")) +
        
      geom_point(aes(y=`0.5`, color = "median")) + geom_line( aes(y=`0.5`, color = "median")) + 
      geom_point(aes(y=point, color = "point")) + geom_line( aes(y=point, color = "point")) + 
        
      scale_color_manual(name = "", values = c("median" = "slategray", "point" = "black")) +
        
      ggnewscale::new_scale_color() +
      geom_line(data = truth_loc_plot_data(),
                aes(x = date, y = value, 
                    linetype = source, color = source, group = source)) +
      scale_color_manual(values = c("JHU-CSSE" = "green",
                                    "USAFacts" = "seagreen",
                                    "NYTimes"  = "darkgreen")) +
      
      scale_linetype_manual(values = c("JHU-CSSE" = 1,
                                       "USAFacts" = 2,
                                       "NYTimes"  = 3)) +
      xlim(input$loc_dates) + 
      facet_wrap(~model_abbr,ncol = 3,labeller = label_wrap_gen(multi_line=FALSE))+
      labs(x = "Date", y="Number", title = paste("Forecast date:", forecast_date)) +
      theme_bw() +
      theme(strip.text.x = element_text(size = 8),
            plot.title = element_text(
              color = ifelse(Sys.Date() - forecast_date > 6, "red", "black")))
  },height ="auto")

  #############################################################################
  # Submissions: Filter data based on user input
   latest_s_t <- reactive({ plot_submissions     %>% filter(model_abbr %in% input$submissions_model_abbr) })
   latest_s_tmty <- reactive({ latest_s_t()      %>% filter(type       %in%  input$submissions_type) })
   latest_s_tmtyt <- reactive({ latest_s_tmty()  %>% filter(target     %in% input$submissions_target) })
   
   observe({
     types <- sort(unique(latest_s_t()$type))
     updateSelectInput(session, "submissions_type", choices = types, selected = types[1])
   })
  
   observe({
     targets <- sort(unique(latest_s_tmty()$target))
     updateSelectInput(session, "submissions_target", choices = targets, 
                       selected = ifelse("wk ahead cum death" %in% targets, 
                                         "wk ahead cum death", 
                                         targets[1]))
   })
   
   set_shiny_plot_height <- function(session, output_width_name){
     function() { 
       session$clientData[[output_width_name]] 
     }
   }
   
  output$submissions <-shiny::renderPlot({
    d <- latest_s_tmtyt()
                        
    ggplot(d,aes(x = start_date, y = reorder(model_abbr, total)))+
      geom_tile(aes(fill = color, width = width), colour = "black", size = 0.25) +
      scale_fill_gradientn("Submission Counts",
                           colours = c("white", "chartreuse4"),
                           values = scales::rescale(c(0,1,7)),
                           breaks = c(0:7), 
                           limits = c(0,7))+
      scale_x_date(expand = c(0,0),
                   breaks = d$start_date,
                   labels = function(x) paste(format(x, format = "%m-%d"),
                                              format(d$end_date,format = "%m-%d"),
                                              sep = '-'),
                   # Take off offset because geom_tile plots on the center of each date
                   limits = c(lubridate::ceiling_date
                            (lubridate::ymd(input$submissions_dates[1]), 
                              unit = "week") - 7-3.5, 
                            lubridate::ceiling_date
                            (lubridate::ymd(input$submissions_dates[2]), 
                              unit = "week") - 1-2))+
      labs(x = "Forecast Dates", y="Model Abbreviation")+
      theme(axis.text.x = element_text(angle = 60, vjust = 0.5),
            legend.position="bottom")
  },height = set_shiny_plot_height(session, "output_submissions_width"))
}

shinyApp(ui = ui, server = server)
