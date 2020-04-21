# Repository of COVID-19 forecasts in the US
The goal of this repository is to create a standardized set of data on forecasts from experienced teams making projections of cumulative and incident deaths and incident hospitalizations due to COVID-19 in the United States. As time goes on, we hope to add other targets and other locations as well.

* [Raw data](https://github.com/reichlab/covid19-forecast-hub/tree/master/data-raw)
* [Processed data](https://github.com/reichlab/covid19-forecast-hub/tree/master/data-processed)
* [Truth data](https://github.com/reichlab/covid19-forecast-hub/blob/master/data-processed/truth-cum-death.csv)
* [Ensemble model](https://github.com/reichlab/covid19-forecast-hub/tree/master/data-processed/COVIDhub-ensemble)
* [Interactive Visualization](https://reichlab.io/covid19-forecast-hub/)

<a href = "https://reichlab.io/covid19-forecast-hub/">
 <img src="https://github.com/reichlab/covid19-forecast-hub/blob/readme-changes/chart.png" width="500" alt="chart">
</a>

## Data license and reuse
We are grateful to the teams who have generated these forecasts. They have spent a huge amount of time and effort in a short amount of time to operationalize these important real-time forecasts. The groups have graciously and courageously made their public data available under different terms and licenses. You will find the licenses (when provided) within the model-specific folders in the [data-raw](./data-raw/) directory. Please consult these licenses before using these data to ensure that you follow the terms under which these data were released.

We have stored the raw datafiles here as they were made available on the various websites or provided directly to us. We are working on creating standardized versions of these files and on building a queryable API for easy access to the data contained in the forecasts. 

## What forecasts we are tracking, and for which locations
Different groups are making forecasts at different times, and for different geographic scales. After looking over what groups are doing, we have settled (for the time being) on the following specifications, although not all models make forecast for each of the following locations and targets. 

**What do we consider to be "gold standard" death data?**
We will use the [daily reports containing death data from the JHU CSSE group](https://github.com/CSSEGISandData/COVID-19/blob/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv) as the gold standard reference data for deaths in the US.

**When will forecast data be updated?** 
We will be storing any new forecasts from each group as they are either provided to us directly (by pull request) or available for download online. We will attempt to make every version of each team's forecasts available in "processed" form in the GitHub repo. Every Monday at 6pm ET, we will upate our [ensemble forecast](data-processed/COVIDhub-ensemble) and [interactive visualization](https://reichlab.io/covid19-forecast-hub/) using the most recent forecast from each team. Therefore, we encourage teams to provide a new forecast on Mondays that uses the most recent data. Depending on how the project evolves, we may add additional weekly builds for the ensemble and visualization.

**What locations will have forecasts?**
Forecasts may be submitted for any location that can be tagged with a FIPS code. Currently, our focus is on cataloguing forecasts for the United States, although we are starting to look at global forecast data as well. For the US, we are collecting forecast data at the national level (e.g., FIPS code = "US") and state level (FIPS code 2-digit character string). A file with FIPS codes for states and counties in the US is available through the `fips_code` dataset in the `tigris` R package, and saved as a [public CSV file](./template/state_fips_codes.csv). Please note that when reading in FIPS codes, they should be read in as characters to preserve any leading zeroes.

**How will probabilistic forecasts be represented?**
Forecasts will be represented in [a standard format](#data-model) using quantile-based representations of predictive distributions. We encourage all groups to make available the following 23 quantiles for each distribution: `c(0.01, 0.025, seq(0.05, 0.95, by = 0.05), 0.975, 0.99)`. If this is infeasible, we ask teams to prioritize making  available at least the following quantiles: `c(0.01, 0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.99)`. One goal of this effort is to create probabilistic ensemble forecasts, and having high-resolution component distributions will provide data to create better ensembles. 

**What forecast targets will be stored?**
We will store forecasts on 1 through 7 day ahead _incident_ and _cumulative_ deaths, 1 through 6 week ahead _incident_ and _cumulative_ deaths, and 1 through 6 week ahead _incident_ hospital demand. The targets should be labeled in files as, e.g., "1 day ahead inc death", "1 day ahead cum death", "1 wk ahead inc death", "1 wk ahead cum death", or "1 wk ahead inc hosp". To be clear about how the time periods relate to the time at which a forecast was made, we provide the following specficiations (which are subject to change or re-evaluation as we get further into the project). 

Every submitted forecast will have an associated `forecast_date` that corresponds to the day the forecast was made. For day-ahead forecasts with a forecast date of a Monday, a 1 day ahead forecast corresponds to incident deaths on Tuesday or cumulative deaths by the end of Tuesday, 2 day ahead to Wednesday, etc.... 
<!-- For day-ahead forecasts collected on Thursdays, a 1 day ahead forecast corresponds to Friday, 2 day ahead to Saturday, etc.... -->

For week-ahead forecasts, we will use the specification of epidemiological weeks (EWs) [defined by the US CDC](https://wwwn.cdc.gov/nndss/document/MMWR_Week_overview.pdf). 
There are standard software packages to convert from dates to epidemic weeks and vice versa. E.g. [MMWRweek](https://cran.r-project.org/web/packages/MMWRweek/) for R and [pymmwr](https://pypi.org/project/pymmwr/) and [epiweeks](https://pypi.org/project/epiweeks/) for python.

For week-ahead forecasts collected on Monday of EW12, a 1 week ahead forecast corresponds to EW12, 2 week ahead to EW13. A week-ahead forecast should represent the total number of incident deaths or hospitalizations within a given epiweek (from Sunday through Saturday, inclusive) or the cumulative number of deaths reported on the Saturday of a given epiweek. We have created [a csv file](template/covid19-death-forecast-dates.csv) describing forecast collection dates and dates for which forecasts refer to can be found.


## Data model
Most groups are providing their forecasts in a quantile-based format. We have developed a general data model that can be used to represent all of the forecasts that have been made publicly available. The tabular version of the data model is a simple, long-form data format, with four required columns and several optional columns.

 - `forecast_date`: (optional) the date on which the forecast was made in `YYYY-MM-DD` format. should correspond and be redundant with the date in the filename, but included here by request from some analysts
 - `target`: a unique id for the target
 - `target_end_date`: (optional) the date corresponding to the end time of the target, in `YYYY-MM-DD` format. E.g. if the target is "1 wk ahead inc hosp" and this forecast is submitted on Monday `2020-04-20`, then this field should correspond to the Saturday that ends the current week `2020-04-25`. 
 - `location`: a unique id for the location (we have standardized to FIPS codes)
 - `location_name`: (optional) if desired to have a human-readable name for the location, this column may be specified. Note that the `location` column will be considered to be authoritative and for programmatic reading and importing of data, this column will be ignored.
 - `type`: one of either `"point"` or `"quantile"`
 - `quantile`: a value between 0 and 1 (inclusive), stating which quantile is displayed in this row. if `type=="point"` then `NA`.
 - `value`: a numeric value representing the value of the quantile function evaluated at the probability specified in `quantile`
 
For example, if `quantile` is 0.3 and `value` is 10, then this row is saying that the 30th percentile of the distribution is 10. If `type` is `"point"` and `value` is 15, then this row is saying that the point estimate from this model is 15. 

## Forecast file format
Raw data from the `data-raw` subfolders will be processed and put into corresponding subfolders in `data-processed`. All files must follow the format outlined above. A [template file](template/2020-04-13-TeamName-ModelName.csv) in the correct format for two targets in a single location has been included for clarity. 

Each file must have a specific naming scheme that represents when the forecast was made and what model made the forecast. Files will follow the following name scheme: `YYYY-MM-DD-[team]-[model].csv`. Where `YYYY-MM-DD` is the date for the Monday on which the forecast was collected. For now, we will only accept a single file for each Monday for a given model (in general, this will be the most recent file generated by that team). For example, a forecast generated from the `CU` team for the `80contact` model on Sunday April 5, 2020, the filename would be `2020-04-06-CU-80contact.csv`.

## Teams and models
So far, we have identified a number of experienced teams that are creating forecasts of COVID-19-related deaths in the US and globally. Our list of groups whose forecasts are currently standardized and in the repository are (with data reuse license):

 - [Columbia University](https://github.com/shaman-lab/COVID-19Projection) (Apache2.0)
 - [GLEAM from Northeastern University](https://www.gleamproject.org/covid-19) (CC-BY-4.0)
 - [IHME](https://covid19.healthdata.org/united-states-of-america) (CC-AT-NC4.0)
 - [LANL](https://covid-19.bsvgateway.org/) ([custom](data-raw/LANL/LICENSE-LANL.txt))
 - [Imperial](https://github.com/sangeetabhatia03/covid19-short-term-forecasts) (none given)
 - [University of Geneva / Swiss Data Science Center](https://renkulab.shinyapps.io/COVID-19-Epidemic-Forecasting/) (none given)
 - UMass-Amherst ensemble forecast: this is a combination of some of the above models. 

Participating teams must provide methodological detail about their approach including a brief description of the methodology and a link to a file (or a file itself) describing the methods used. 
