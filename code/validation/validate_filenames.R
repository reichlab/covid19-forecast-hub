
# Validate forecast filename equals forecast filepath
check_forecast_name_path <- function(forecast_file) {
    forecast_file_path <- basename(dirname(forecast_file))
    forecast_file_name <-  substring(basename(forecast_file), 
                                        12,
                                        nchar(basename(forecast_file)) - 4)
    if (forecast_file_path != forecast_file_name){
        error_message <- paste("\nERROR: Forecast file name: ",
                                forecast_file_name,
                                " does not match Forecast file path: ",
                                forecast_file_path)
        return(stop(error_message))
    }
    else{
        check_accepted <- paste("✔ Forecast file name = Forecast file path (",
                                    forecast_file_name,
                                    "=",
                                    forecast_file_path,
                                    ")")
        return(writeLines(check_accepted))
    }
    return(0)
}

ignore_files <- c("./data-processed/COVIDhub-ensemble/COVIDhub-ensemble-information.csv",
                    "./data-processed/zoltar-truth-cum-death.csv",
                    "./data-processed/truth-cum-death.csv")

# VERIFY forecasts filenames
forecasts <- list.files(path="./data-processed", pattern="*.csv", full.names=TRUE, recursive=TRUE)
for(i in forecasts){
    writeLines(paste("\nTesting", i, "..."))
    
    if(!(i %in% ignore_files)){ 
        # check if forecast file path = forecast file name
        check_forecast_name_path(i)
    }
    else{
       writeLines( "✔ Not a forecast file")
    }
    
}