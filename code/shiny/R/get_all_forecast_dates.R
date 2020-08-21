get_all_forecast_dates = function (forecast_files){
  dataframes =list()
  for (file in forecast_files){
    items = unlist(str_split(file, pattern = "/|-|\\."))
    dataframes[[file]] = data.frame(team = items[3], model = items[4], forecast_date = as.Date(paste(items[5],items[6],items[7], sep='-')))
  }
  
  dplyr::bind_rows(dataframes)
}
