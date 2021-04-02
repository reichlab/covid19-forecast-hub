#' Summarize submission counts in each week for each model and each target
#' 
#' @param submissions a data.frame with forecast dates, target and type for all forecasts
#' @return a data.frame with a weekly count
#' 
get_submissions = function (submissions){
  
  submissions = reshape2::melt(submissions, 
                               id.vars=c("model_abbr","type","target","max_n")) 
  dates = unique(submissions$value)
  dates_axis =list(seq(as.Date(min(dates))-1, Sys.Date(),"day"))
  
  submissions %>%
    dplyr:: group_by_all() %>% 
    nest %>% 
    dplyr:: mutate(data = dates_axis) %>%
    unnest (cols = c(data)) %>%
    dplyr:: mutate(color = if_else(as.Date(value) == as.Date(data), 1, 0)) %>%
    dplyr:: group_by(type, target, data, model_abbr) %>%
    dplyr:: summarise(color = sum(color)) %>%
    # start date is the sunday of previous week
    dplyr:: mutate(start_date = lubridate::ceiling_date
                   (lubridate::ymd(data), unit = "week") - 7) %>%
    # end date is the saturday of current week 
    dplyr:: mutate(end_date = lubridate::ceiling_date
                   (lubridate::ymd(data), unit = "week") - 1) %>%
    # if end_date is bigger than current system time, replace it with system time 
    #dplyr:: mutate(end_date = dplyr::if_else(end_date > Sys.Date(), Sys.Date(), end_date)) %>%
    dplyr:: mutate(width = as.numeric(end_date - start_date+1))%>%
    dplyr:: group_by(type, target, model_abbr, start_date, end_date,width) %>%
    # total submission count of the week 
    dplyr:: summarise(color = sum(color)) %>%
    # get total submission for each team for each target
    dplyr:: group_by(type, target, model_abbr) %>%
    dplyr:: mutate(total = sum(color)) %>%
    dplyr:: ungroup()
}