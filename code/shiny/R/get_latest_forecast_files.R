#' Get latest forecast files for each model
#' 
#' @param files a list of all forecast file names
#' @return a list of latest forecast file names
#' 
get_latest_forecast_files <- function(files) {
  data.frame(file = files) %>%
    tidyr::separate(file, 
                    into = c("data","processed","team_abbr","model_abbr",
                             "year","month","day","team_abbr2", "model_abbr2",
                             "csv"),
                    sep = "/|-|\\.", 
                    remove = FALSE) %>%
    dplyr::mutate(date = as.Date(paste(year,month,day,sep="-"))) %>%
    dplyr::select(date, team_abbr, model_abbr, file) %>%
    
    dplyr::group_by(team_abbr, model_abbr) %>%
    dplyr::filter(date == max(date)) %>%
    dplyr::ungroup() %>%
    dplyr::pull(file)
}
