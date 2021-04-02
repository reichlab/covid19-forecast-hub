#' Getting some human readable PIs out of a Zoltar query
#'
#' @param data an object returned from a Zoltar query
#' @param forecast_date a character interpretable as a date
#' @param targets a list of valid targets for the project
#' @param location a FIPS code
#' @param alpha the alpha level of interest
#'
#' @return just prints some text
#'
#' @examples
get_zoltar_PI <- function(data, forecast_date, targets, location, alpha) {
    locs <- read_csv("data-locations/locations.csv")
    loc_name <- locs$location_name[locs$location==location]
    target_end_dates <- get_next_saturday(forecast_date)+7*c(0:3)
    alpha_low <- alpha/2
    alpha_high <- 1-alpha/2
    pi_level <- (1-alpha)*100
    
    for(target in targets) {
        step_ahead <- as.numeric(substr(target, 0,1))
        format(round(as.numeric(1000.64)), big.mark=",")
        print(paste0("The forecasted ", target, " for ", loc_name, " by ", target_end_dates[step_ahead], " is ", 
            format(round(data$value[data$target==target & data$class=="point" & data$unit==location]), big.mark=","), " with a ",
            pi_level, "% PI of ",
            format(round(data$value[data$target==target & data$class=="quantile" & data$unit==location & data$quantile==alpha_low]), big.mark=","), 
            "-",
            format(round(data$value[data$target==target & data$class=="quantile" & data$unit==location & data$quantile==alpha_high]), big.mark=","),
            "."))
    }
}
