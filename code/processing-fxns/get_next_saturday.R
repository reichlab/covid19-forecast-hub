#' Calculate the date of the next Saturday
#'
#' @param date date for calculation
#'
#' @return a date of the subsequent Saturday. if date is a Saturday, it will return this day itself.
get_next_saturday <- function(date) {
    require(lubridate)
    date <- as.Date(date)
    ## calculate days until saturday (day 7)
    diff <- 7 - wday(date)
    ## add to given date
    new_date <- diff + date
    return(new_date)
}
