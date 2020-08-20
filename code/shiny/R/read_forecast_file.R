#' Get a forecast file
#' 
#' @param f file path
#' @return a data.frame of forecast data
#' 
read_forecast_file <- function(f) {
  data.table::fread(f,
                    colClasses =c(
                      "forecast_date"   = "Date",
                      "target"          = "character",
                      "target_end_date" = "Date",
                      "location"        = "character",
                      "type"            = "character",
                      "quantile"        = "double",
                      "value"           = "double"),
                    nThread = 1
  ) %>%
    dplyr::mutate(quantile = as.numeric(quantile),
                  type = tolower(type)) %>%
    dplyr::mutate(file = f) %>%
    tidyr::separate(file, into = c("period","processed","team","model",
                                   "year","month","day","team2","model_etc"), 
                    sep="-|/") %>%
    
    dplyr:: mutate(model_abbr = paste(team,model,sep="-")) %>%
    
    dplyr::select(model_abbr, forecast_date, type, location, target, quantile, 
                  value, target_end_date)   
}
