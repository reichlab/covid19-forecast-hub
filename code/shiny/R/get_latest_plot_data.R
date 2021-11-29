#' Get forecast data.frame to plot
#' 
#' @param d a data.frame with the latest forecast from each model
#' @return a data.frame with forecast, quantiles and targets
#' 
get_latest_plot_data <- function(d){
  d %>%
    filter(quantile %in% c(.025,.25,.5,.75,.975) | type == "point") %>%
    
    mutate(quantile = ifelse(type == "point", "point", quantile),
           simple_target = paste(unit, ahead, inc_cum, death_cases)) %>%
    select(-type) %>%
    tidyr::pivot_wider(
      names_from = quantile,
      values_from = value
    )
}
