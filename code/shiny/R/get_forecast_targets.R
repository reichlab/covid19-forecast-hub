#' Get forecast target
#' 
#' @param d a forecast data.frame
#' @return a data.frame with a count for the number of forecasts for each target
#' 
get_forecast_targets <- function(d) {
  d %>%
    # add location
    dplyr::group_by(model_abbr, forecast_date, type, unit, ahead, inc_cum, death_cases) %>%
    dplyr::summarize(max_n = max(as.numeric(n_unit)), .groups = "keep") %>%
    dplyr::ungroup() %>%
    dplyr::mutate(target = paste(unit, ahead, inc_cum, death_cases)) 
}
