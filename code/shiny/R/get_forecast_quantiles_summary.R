#' Summarize prediction quantiles for a model
#' 
#' @param d a forecast data.frame
#' @return a data.frame with quantiles summaries
get_forecast_quantiles_summary <- function(d){
  d %>%
    dplyr::group_by(model_abbr, forecast_date) %>%
    dplyr::summarize(
      all_full = ifelse(all(full), "Yes", "-"),
      any_full = ifelse(any(full), "Yes", "-"),
      all_min  = ifelse(all(min),  "Yes", "-"),
      any_min  = ifelse(any(min),  "Yes", "-"),
      
      .groups = "keep")
}