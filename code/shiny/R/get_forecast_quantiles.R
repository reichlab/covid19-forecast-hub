#' Summarize prediction quantiles for a forecast
#' 
#' @param d a forecast data.frame
#' @return a data.frame with quantiles summaries
get_forecast_quantiles <- function(d){
  quantiles = list(
    full = sprintf("%.3f", c(0.01, 0.025, seq(0.05, 0.95, by = 0.05), 0.975, 0.99)),
    min  = sprintf("%.3f", c(0.01, 0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.99))
  )
  
  d %>%
    dplyr::filter(type == "quantile") %>%
    dplyr::mutate(quantile = sprintf("%.3f", as.double(quantile))) %>%
    dplyr::group_by(model_abbr, forecast_date, target) %>%
    dplyr::summarize(
      full = all(quantiles$full %in% quantile),
      min  = all(quantiles$min  %in% quantile),
      quantiles = paste(unique(quantile), collapse = " "),
      .groups = "keep") %>%
    dplyr::ungroup()
}
