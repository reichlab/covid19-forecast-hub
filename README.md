# COVID-19 Forecast Hub
<img src="https://travis-ci.com/reichlab/covid19-forecast-hub.svg?branch=master">

The goal of this repository is to create a standardized set of data on forecasts from teams making projections of cumulative and incident deaths and incident hospitalizations due to COVID-19 in the United States. This repository is the data source for [the official CDC COVID-19 Forecasting page](https://www.cdc.gov/coronavirus/2019-ncov/covid-data/forecasting-us.html). This project to collect, standardize, visualize and synthesize forecast data has been led by the CDC-funded UMass-Amherst Influenza Forecasting Center of Excellence based at the [Reich Lab](https://reichlab.io/), with [contributions from many others](https://github.com/reichlab/covid19-forecast-hub/blob/master/README.md#the-covid-forecast-hub-team). 

This README provides an overview of the project. Additional specific links can be found in the list below:

* [Interactive Visualization](https://reichlab.io/covid19-forecast-hub/)
* [Ensemble model](#ensemble-model)
* [Raw forecast data](https://github.com/reichlab/covid19-forecast-hub/tree/master/data-raw)
* [Processed forecast data](https://github.com/reichlab/covid19-forecast-hub/tree/master/data-processed)
* [Truth data](https://github.com/reichlab/covid19-forecast-hub/blob/master/data-truth/truth-cum-death.csv)
* [Technical README with detailed submission instructions](https://github.com/reichlab/covid19-forecast-hub/blob/master/data-processed/README.md)

<a href = "https://reichlab.io/covid19-forecast-hub/">
 <img src="https://github.com/reichlab/covid19-forecast-hub/blob/master/visualization/vis-master/chart.png" width="500" alt="chart">
</a>

## Data license and reuse
We are grateful to the teams who have generated these forecasts. They have spent a huge amount of time and effort in a short amount of time to operationalize these important real-time forecasts. The groups have graciously and courageously made their public data available under different terms and licenses. You will find the licenses (when provided) within the model-specific folders in the [data-raw](./data-raw/) directory. Please consult these licenses before using these data to ensure that you follow the terms under which these data were released.

We have stored the raw datafiles here as they were made available on the various websites or provided directly to us. We are working on creating standardized versions of these files and on building a queryable API for easy access to the data contained in the forecasts. 

All source code that is specific to this project, along with our [d3-foresight](http://reichlab.io/d3-foresight/) visualization tool is available under an open-source [MIT license](./LICENSE). We note that this license does NOT cover model code from the various teams (maybe available from them under other licenses) or model forecast data (available under specified licenses as described above). 

## What forecasts we are tracking, and for which locations
Different groups are making forecasts at different times, and for different geographic scales. The specifications below were created by consulting with collaborators at CDC and looking at what models forecasting teams were already building. 

**What do we consider to be "gold standard" death data?**
We will use the [daily reports containing death data from the JHU CSSE group](https://github.com/CSSEGISandData/COVID-19/blob/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv) as the gold standard reference data for deaths in the US. Note that there are not insignificant differences (especially in daily incident death data) between the JHU data and another commonly used source, from the New York Times. The team at UTexas-Austin is tracking this issue on [a separate GitHub repository](https://github.com/spencerwoody/covid19-data-comparsion).

**When will forecast data be updated?** 
We will be storing any new forecasts from each group as they are either provided to us directly (by pull request) or available for download online. We will attempt to make every version of each team's forecasts available in "processed" form in the GitHub repo. Teams are encouraged to submit data as often has they have it available, although we only support one upload for each day. 

**What locations will have forecasts?**
Currently, forecasts may be submitted for any state in the US and the US at the national level. At a future date, we may expand to include smaller geographic scales within the US and/or other international locations. 

**How will probabilistic forecasts be represented?**
Forecasts will be represented in [a standard format](#data-model) using quantile-based representations of predictive distributions. We encourage all groups to make available the following 23 quantiles for each distribution: `c(0.01, 0.025, seq(0.05, 0.95, by = 0.05), 0.975, 0.99)`. If this is infeasible, we ask teams to prioritize making  available at least the following quantiles: `c(0.01, 0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.99)`. One goal of this effort is to create probabilistic ensemble forecasts, and having high-resolution component distributions will provide data to create better ensembles. 

**What forecast targets will be stored?**
We will store forecasts on 0 through 130 day-ahead _incident_ and _cumulative_ deaths, 1 through 20 week-ahead _incident_ and _cumulative_ deaths, and 0 through 130 day-ahead _incident_ hospitalizations. The targets should be labeled in files as, e.g., `"1 day ahead inc death"`, `"1 day ahead cum death"`, `"1 wk ahead inc death"`, `"1 wk ahead cum death"`, or `"1 wk ahead inc hosp"`. Please refer to the [technical README](https://github.com/reichlab/covid19-forecast-hub/blob/master/data-processed/README.md) for details on aligning targets with forecast dates.

<!-- To be clear about how the time periods relate to the time at which a forecast was made, we provide the following specficiations (which are subject to change or re-evaluation as we get further into the project). Every submitted forecast will have an associated `forecast_date` that corresponds to the day the forecast was made. For day-ahead forecasts with a forecast date of a Monday, a 1 day ahead forecast corresponds to incident deaths on Tuesday or cumulative deaths by the end of Tuesday, 2 day ahead to Wednesday, etc.... 
<!-- For day-ahead forecasts collected on Thursdays, a 1 day ahead forecast corresponds to Friday, 2 day ahead to Saturday, etc.... 


For week-ahead forecasts with `forecast_date` of Sunday or Monday of EW12, a 1 week ahead forecast corresponds to EW12 and should have `target_end_date` of the Saturday of EW12. For week-ahead forecasts with `forecast_date` of Tuesday through Saturday of EW12, a 1 week ahead forecast corresponds to EW13 and should have `target_end_date` of the Saturday of EW13. A week-ahead forecast should represent the total number of incident deaths or hospitalizations within a given epiweek (from Sunday through Saturday, inclusive) or the cumulative number of deaths reported on the Saturday of a given epiweek. We have created [a csv file](template/covid19-death-forecast-dates.csv) describing forecast collection dates and dates for which forecasts refer to can be found.
-->

## Ensemble model
Every Monday at 6pm ET, we will upate our [COVID Forecast Hub ensemble forecast](data-processed/COVIDhub-ensemble) and [interactive visualization](https://reichlab.io/covid19-forecast-hub/) using the most recent forecast from each team. Therefore, at the very least we encourage teams to provide a new forecast on Mondays that uses the most recent data. Depending on how the project evolves, we may add additional weekly builds for the ensemble and visualization. Currently, our ensemble is created by taking the arithmetic average of each quantile for all models that submit 1- through 4-week ahead targets for a given location. Ensemble methods may evolve as more data becomes available. 

## Data model
Most groups are providing their forecasts in a quantile-based format. We have developed a general data model that can be used to represent all of the forecasts that have been made publicly available. The tabular version of the data model is a simple, long-form data format, with six required columns and several optional columns.

 - `forecast_date`: the date on which the submitted forecast data was made available in `YYYY-MM-DD` format. In general, this will typically be the date on which the model finishes running and produces the standard formatted file. `forecast_date` should correspond and be redundant with the date in the filename, but is included here by request from some analysts. We will enforce that the `forecast_date` for a file must be either the date on which the file was submitted to the repository or the previous day. Exceptions will be made for legitimate extenuating circumstances.
 - `target`: a unique id for the target
 - `target_end_date`: the date corresponding to the end time of the target, in `YYYY-MM-DD` format. E.g. if the target is `"1 wk ahead inc hosp"` and this forecast is submitted on Monday `2020-04-20`, then this field should correspond to the Saturday that ends the current week `2020-04-25`. See details about date formatting in the [technical README](https://github.com/reichlab/covid19-forecast-hub/blob/master/data-processed/README.md).
 - `location`: a unique id for the location (we have standardized to FIPS codes, see details in the [technical README](https://github.com/reichlab/covid19-forecast-hub/blob/master/data-processed/README.md).)
 - `location_name`: (optional) if desired to have a human-readable name for the location, this column may be specified. Note that the `location` column will be considered to be authoritative and for programmatic reading and importing of data, this column will be ignored.
 - `type`: one of either `"point"` or `"quantile"`.
 - `quantile`: a value between 0 and 1 (inclusive), stating which quantile is displayed in this row. if `type=="point"` then `NA`.
 - `value`: a numeric value representing the value of the quantile function evaluated at the probability specified in `quantile`
 
For example, if `quantile` is 0.3 and `value` is 10, then this row is saying that the 30th percentile of the distribution is 10. If `type` is `"point"` and `value` is 15, then this row is saying that the point estimate from this model is 15. 

## Forecast file format
Raw data from the `data-raw` subfolders will be processed and put into corresponding subfolders in `data-processed`. All files must follow the format outlined above. Teams can use [this file](data-processed/YYG-ParamSearch/2020-04-27-YYG-ParamSearch.csv) as an example or template to follow. 

Each file must have a specific naming scheme that represents when the forecast was made and what model made the forecast. Files will follow the following name scheme: `YYYY-MM-DD-[team]-[model].csv`. Where `YYYY-MM-DD` is the `forecast_date` as defined above. Teams are welcome to submit up to one file a day to be stored in the repository.

## Teams and models
So far, we have identified a number of groups that are creating forecasts of COVID-19-related deaths in the US and globally. Our list of groups whose forecasts are currently standardized and in the repository are (with data reuse license):

 - [Columbia University](https://github.com/shaman-lab/COVID-19Projection) (Apache2.0)
 - [GLEAM from Northeastern University](https://www.gleamproject.org/covid-19) (CC-BY-4.0)
 - [IHME](https://covid19.healthdata.org/united-states-of-america) (CC-AT-NC4.0)
 - [LANL](https://covid-19.bsvgateway.org/) ([custom](data-raw/LANL/LICENSE-LANL.txt))
 - [Imperial](https://github.com/sangeetabhatia03/covid19-short-term-forecasts) (none given)
 - [MIT](https://www.covidanalytics.io/) (Apache 2.0)
 - [Notre Dame](https://github.com/confunguido/covid19_ND_forecasting) (none given)
 - [University of Geneva / Swiss Data Science Center](https://renkulab.shinyapps.io/COVID-19-Epidemic-Forecasting/) (none given)
 - [University of Massachusetts - Expert Model](https://github.com/tomcm39/COVID19_expert_survey) (MIT)
 - [University of Massachusetts - Mechanistic Bayesian model](https://github.com/dsheldon/covid) (MIT)
 - [University of Texas-Austin](https://covid-19.tacc.utexas.edu/projections/) (BSD-3)
 - [YYG](http://covid19-projections.com) (MIT) 
 - COVIDhub ensemble forecast: this is a combination of the above models. 

Participating teams must provide a metadata file (see [example](data-processed/UMass-ExpertCrowd/metadata-UMass-ExpertCrowd.txt)), including methodological detail about their approach and a link to a file (or a file itself) describing the methods used. 

## The COVID Forecast Hub Team
Carefully curating these datasets into a standard format has taken a Herculean team effort. The following lists those who have helped out, in reverse alphabetical order:

 - Nutcha Wattanachit (ensemble model, data processing)
 - Nicholas Reich (project lead, ensemble model, data processing)
 - Jarad Niemi (data processing and organization)
 - Khoa Le (validation, automation)
 - Katie House (visualization, validation, project management)
 - Matt Cornell (validation, Zoltar integration)
 - Andrea Brennen (metadata curation)
 - Johannes Bracher (evaluation, data processing)
