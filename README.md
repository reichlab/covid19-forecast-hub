# Repository of COVID-19 forecasts of deaths in the US

The goal of this repository is to create a standardized set of data on forecasts from experienced teams making projections of deaths due to COVID-19 in the United States.

## Data license and reuse
We are grateful to the teams who have generated these forecasts. They have no doubt spent a huge amount of time and effort in a short amount of time to operationalize these important real-time forecasts. The groups have graciously and courageously made their public data available under different terms and licenses. You will find the licenses within the model-specific folders in the [data-raw](./data-raw/) directory. Please consult these licenses before using these data to ensure that you follow the terms under which these data were released.

We have stored the raw datafiles here as they were made available on the various websites. We are working on creating standardized versions of these files and on building a queryable API for easy access to the data contained in the forecasts. 

## What forecasts we are tracking, and for which locations
Different groups are making forecasts at different times, and for different geographic scales. After looking over what groups are doing, we have settled (for the time being) on the following specifications, although not all models make forecast for each of the following locations and targets. 

**What do we consider to be "gold standard" death data?**
We will use the [daily reports containing death data from the JHU CSSE group](https://github.com/CSSEGISandData/COVID-19/tree/master/csse_covid_19_data/csse_covid_19_daily_reports) as the gold standard reference data for deaths in the US.

**When will forecast data be updated?** 
We will be accessing any new forecasts from each group on Mondays and Thursdays and on those days, we will regenerate the standardized forecast data.

**What locations will have forecasts?**
Forecasts will be catalogued for the national level (FIPS code = "US") and state level (FIPS code 2-digit character string). A file with FIPS codes for states and counties is available through the `fips_code` dataset in the `tigris` R package, and saved as a [public CSV file](./template/state_fips_codes.csv). Please note that when reading in FIPS codes, they should be read in as characters to preserve any leading zeroes.

**What forecast targets will be stored?**
We will store forecasts on 1 through 7 day ahead _incident_ deaths and 1 through 6 week ahead _incident_ deaths. The targets should be labeled in files as "1 wk ahead", "2 wk ahead", etc... and "1 day ahead", "2 day ahead", etc... To be clear about how the time periods relate to the time at which a forecast was made, we provide the following specficiations (which are subject to change or re-evaluation as we get further into the project). 

For day-ahead forecasts collected on Monday, a 1 day ahead forecast corresponds to Tuesday, 2 day ahead to Wednesday, etc.... 
For day-ahead forecasts collected on Thursdays, a 1 day ahead forecast corresponds to Friday, 2 day ahead to Saturday, etc.... 

For week-ahead forecasts, we will use the specification of epidemiological weeks (EWs) [defined by the US CDC](https://wwwn.cdc.gov/nndss/document/MMWR_Week_overview.pdf). 
There are standard software packages to convert from dates to epidemic weeks and vice versa. E.g. [MMWRweek](https://cran.r-project.org/web/packages/MMWRweek/) for R and [pymmwr](https://pypi.org/project/pymmwr/) and [epiweeks](https://pypi.org/project/epiweeks/) for python.

For week-ahead forecasts collected on Monday or Thursday  of EW12, a 1 week ahead forecast corresponds to EW12, 2 week ahead to EW13.


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




