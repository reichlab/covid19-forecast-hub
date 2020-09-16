#' Summarize locations for forecasts
#' 
#' @param d a forecast data.frame
#' @return a data.frame with location summaries
get_forecast_locations <- function(d) {
  d %>% 
    dplyr::group_by(model_abbr, forecast_date) %>%
    dplyr::summarize(
      US = ifelse(any(abbreviation == "US"), "Yes", "-"),
      n_states = sum(state.abb %in% abbreviation),
      other = paste(unique(setdiff(abbreviation, c(state.abb,"US"))),
                    collapse = " "),
      missing_states = paste(unique(setdiff(state.abb, abbreviation)),
                             collapse = " "),
      missing_states = ifelse(missing_states == paste(state.abb, collapse = " "), 
                              "all", missing_states),
      missing_states = ifelse(nchar(missing_states) > 7, 
                              "...lots...", missing_states),
      .groups = "drop_last"
    )
  
}
