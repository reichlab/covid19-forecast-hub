plan = drake::drake_plan(
  locations = get_locations(file_in("data-locations/locations.csv")),
  
  
  ##############
  # Latest Forecasts
  
  latest_forecasts = target(
    read_forecast_file(file_in(file)) %>%
      dplyr::left_join(locations, by = c("location")) %>%
      tidyr::separate(target, into=c("n_unit","unit","ahead","inc_cum","death_cases"),
                      remove = FALSE),
    transform = map(file = !!latest_forecast_files,id_var = !!paste0(latest_ids,"_"), .id=id_var)
  ),
  
  latest = target(
    dplyr::bind_rows(latest_forecasts),
    transform = combine(latest_forecasts)
  ),

  ##############
  # Latest Locations
  latest_locations_by_model = target(
    get_forecast_locations(latest_forecasts),
    transform = map(latest_forecasts)
  ),

  latest_locations = target(
    dplyr::bind_rows(latest_locations_by_model),
    transform = combine(latest_locations_by_model)
  ),

  ##############
  # Latest Quantiles
  latest_quantiles_by_model = target(
    get_forecast_quantiles(latest_forecasts),
    transform = map(latest_forecasts)
  ),

  latest_quantiles_summary_by_model = target(
    get_forecast_quantiles_summary(latest_quantiles_by_model),
    transform = map(latest_quantiles_by_model)
  ),

  latest_quantiles = target(
    dplyr::bind_rows(latest_quantiles_by_model),
    transform = combine(latest_quantiles_by_model)
  ),

  latest_quantiles_summary = target(
    dplyr::bind_rows(latest_quantiles_summary_by_model),
    transform = combine(latest_quantiles_summary_by_model)
  ), 
  
  ##############
  # Latest Targets
  # Only include latest forecast from each model
  latest_targets_by_model = target(
     get_forecast_targets(latest_forecasts),
     transform = map(latest_forecasts)
  ),
   
  latest_targets = target(
    dplyr::bind_rows(latest_targets_by_model) %>%
      dplyr::select(model_abbr, forecast_date, type, max_n, target) %>%
      dplyr::arrange(model_abbr, forecast_date, type, target),
    transform = combine(latest_targets_by_model)
  ),
  
  ##############
  # Submissions
  # Include all forecasts from each model
  
  submissions_by_file = target(
    read_forecast_file(file_in(file)) %>%
      dplyr::left_join(locations, by = c("location"))%>%
      tidyr::separate(target, into=c("n_unit","unit","ahead","inc_cum","death_cases"),remove = FALSE) %>%
      get_forecast_targets(),
    
    # create id with forecast date and model_abbr name
    transform = map(file = !!forecast_files,times = !!ids_times, models = !!paste0(ids,"_"),.id = c(times,models))
  ),
  
  # Combine submissions by model_abbr name
  submissions_by_model = target(
    dplyr::bind_rows(submissions_by_file),
    transform = combine(submissions_by_file,.by = models)
  ),

  submissions = target(
    dplyr::bind_rows(submissions_by_model) %>% 
      dplyr::select(model_abbr, forecast_date, type, max_n, target) %>%
      dplyr::arrange(model_abbr, forecast_date, type, target),
    transform = combine(submissions_by_model)
  ),
  
  # Organize submissions to plot
  plot_submissions = get_submissions(submissions),

   
  ##############
  # Plot data
  latest_plot_data_by_model = target(
    get_latest_plot_data(latest_forecasts),
    transform = map(latest_forecasts)
  ),
   
  latest_plot_data = target(
    dplyr::bind_rows(latest_plot_data_by_model),
    transform = combine(latest_plot_data_by_model)
  ),
   
  ##############
  # Truth
  inc_jhu = get_truth(file_in("data-truth/truth-Incident Deaths.csv"),                     "inc", "JHU-CSSE"),
  cum_jhu = get_truth(file_in("data-truth/truth-Cumulative Deaths.csv"),                   "cum", "JHU-CSSE"),
  inc_usa = get_truth(file_in("data-truth/usafacts/truth_usafacts-Incident Deaths.csv"),   "inc", "USAFacts"),
  cum_usa = get_truth(file_in("data-truth/usafacts/truth_usafacts-Cumulative Deaths.csv"), "cum", "USAFacts"),
  inc_nyt = get_truth(file_in("data-truth/nytimes/truth_nytimes-Incident Deaths.csv"),     "inc", "NYTimes"),
  cum_nyt = get_truth(file_in("data-truth/nytimes/truth_nytimes-Cumulative Deaths.csv"),   "cum", "NYTimes"),
  inc_cases_nyt = get_truth(file_in("data-truth/nytimes/truth_nytimes-Incident Cases.csv"),     "inc", "NYTimes"),
  inc_cases_usa = get_truth(file_in("data-truth/usafacts/truth_usafacts-Incident Cases.csv"),   "inc", "USAFacts"),
  inc_cases_jhu = get_truth(file_in("data-truth/truth-Incident Cases.csv"),   "inc", "JHU-CSSE"),

  truth = combine_truth(inc_jhu, inc_usa, inc_nyt,
                        cum_jhu, cum_usa, cum_nyt,
                        inc_cases_nyt,inc_cases_usa,inc_cases_jhu) %>%
    dplyr::left_join(locations, by = c("location"))%>%
    dplyr::mutate(location_name = coalesce(location_name.x, location_name.y))
  ##############
)

shiny <- c("truth",
           "latest_locations",
           "latest_targets",
           "plot_submissions",
           "latest_quantiles",
           "latest_quantiles_summary",
           "latest_plot_data")

#all_forecasts <- c("all_forecasts")

latest <-c("latest")
