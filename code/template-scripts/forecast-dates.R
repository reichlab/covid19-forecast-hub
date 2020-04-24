## table with important dates

## due dates: Mondays
forecasts_collected <- seq(as.Date("2020-03-16"), as.Date("2020-10-30"), by="1 week")
forecasts_collected_ew <- paste0(
    MMWRweek(forecasts_collected)$MMWRyear, 
    "-ew",
    MMWRweek(forecasts_collected)$MMWRweek
)

## 1-week ahead
forecast_1_wk_ahead_start <- forecasts_collected-1
forecast_1_wk_ahead_end <- forecasts_collected+5

forecast_info <- tibble(
    timezero=forecasts_collected, forecasts_collected_ew, forecast_1_wk_ahead_start, forecast_1_wk_ahead_end
)

write_csv(forecast_info, path="template/covid19-death-forecast-dates.csv")
