#' Combine all truth files
#' 
#' @param inc_jhu jhu inc data.frame
#' @param inc_usa usa inc data.frame
#' @param inc_nyt nyt inc data.frame
#' @param cum_jhu jhu cum data.frame
#' @param cum_usa usa cum data.frame
#' @param cum_nyt nyt cum data.frame
#' @param inc_cases_nyt nyt case inc data.frame
#' @param inc_cases_usa usa case inc data.frame
#' @param inc_cases_jhu jhu case inc data.frame
#' @return a data.frame with truth for county-level, state-level and national data
#' 
combine_truth = function(inc_jhu, inc_usa, inc_nyt, cum_jhu, cum_usa, cum_nyt, inc_cases_nyt, inc_cases_usa, inc_cases_jhu) {
  bind_rows(
    # deaths truth
    bind_rows(
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
      dplyr::mutate(death_cases = "death",
                    simple_target = paste(unit, "ahead", inc_cum, death_cases)),
    #cases truth
    bind_rows(
      bind_rows(inc_cases_nyt, inc_cases_usa,inc_cases_jhu) %>% dplyr::mutate(unit = "day"),
      
      bind_rows(inc_cases_nyt, inc_cases_usa,inc_cases_jhu) %>%
        dplyr::mutate(week = MMWRweek::MMWRweek(date)$MMWRweek) %>%
        dplyr::group_by(location, week, inc_cum, source) %>%
        dplyr::summarize(date = max(date),
                         value = sum(value, na.rm = TRUE)) %>%
        dplyr::ungroup() %>%
        dplyr::filter(weekdays(date) == "Saturday") %>%
        dplyr::mutate(unit = "wk") %>%
        dplyr::select(-week)
    ) %>%  dplyr::mutate(death_cases = "case",
                         simple_target = paste(unit, "ahead", inc_cum, death_cases))
    )
  
}
