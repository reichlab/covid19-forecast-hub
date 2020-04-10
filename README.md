# Repository of COVID-19 forecasts of deaths in the US

The goal of this repository is to create a standardized set of data on forecasts from experienced teams making projections of deaths due to COVID-19 in the United States.

## Data license and reuse
We are grateful to the teams who have generated these forecasts. They have no doubt spent a huge amount of time and effort in a short amount of time to operationalize these important real-time forecasts. The groups have graciously and courageously made their public data available under different terms and licenses. You will find the licenses within the model-specific folders in the [data-raw](./data-raw/) directory. Please consult these licenses before using these data to ensure that you follow the terms under which these data were released.

We have stored the raw datafiles here as they were made available on the various websites. We are working on creating standardized versions of these files and on building a queryable API for easy access to the data contained in the forecasts. 

## Data model
Most groups are providing their forecasts in a quantile-based format. We have developed a general data model that can be used to represent all of the forecasts that have been made publicly available. The tabular version of the data model is a simple, long-form data format, with five columns.

 - `target_id`: a unique id for the target
 - `location_id`: a unique id for the location
 - `type`: one of either `point` or `quantile`
 - `quantile`: a value between 0 and 1 (inclusive), representing the quantile displayed in this row. if `type=="point"` then `NULL`.
 - `value`: a numeric value representing the value of the cumulative distribution function evaluated at the specified `quantile`
 
For example, if `quantile` is 0.5 and `value` is 10, then this row is saying that the median is 10.

## Forecast file format
Raw data from the `data-raw` subfolders will be processed and put into corresponding subfolders in `data-processed`. Each file must have a specific naming scheme that represents when the forecast was made and what model made the forecast. Files will follow the following name scheme: `YYYY-MM-DD-[team]-[model].csv`. Where `YYYY-MM-DD` is the date on which the forecast was made. For now, we will only accept a single file for each day for a given model. For example, a forecast generated from the `CU` team for the `80contact` model on April 5, 2020, the filename would be `2020-04-05-CU-80contact.csv`.



