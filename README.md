# COVID-19 Forecast Hub 
<img src="https://travis-ci.com/reichlab/covid19-forecast-hub.svg?branch=master">

The goal of this repository is to create a standardized set of data on forecasts from teams making projections of cumulative and incident deaths and incident hospitalizations due to COVID-19 in the United States. This repository is the data source for [the official CDC COVID-19 Forecasting page](https://www.cdc.gov/coronavirus/2019-ncov/covid-data/forecasting-us.html). This project to collect, standardize, visualize and synthesize forecast data has been led by the CDC-funded UMass-Amherst Influenza Forecasting Center of Excellence based at the [Reich Lab](https://reichlab.io/), with [contributions from many others](https://github.com/reichlab/covid19-forecast-hub/blob/master/README.md#the-covid-forecast-hub-team). 

This README provides an overview of the project. Additional specific links can be found in the list below:

* [Interactive Visualization](http://viz.covid19forecasthub.org)
* [Ensemble model](#ensemble-model)
* [Processed forecast data](https://github.com/reichlab/covid19-forecast-hub/tree/master/data-processed)
* [Truth data](https://github.com/reichlab/covid19-forecast-hub/blob/master/data-truth/)
* [Technical README with detailed submission instructions](https://github.com/reichlab/covid19-forecast-hub/blob/master/data-processed/README.md)

<a href = "http://viz.covid19forecasthub.org">
 <img src="https://github.com/reichlab/covid19-forecast-hub/blob/master/visualization/vis-master/chart.png" width="500" alt="chart">
</a>

## Data license and reuse
We are grateful to the teams who have generated these forecasts. They have spent a huge amount of time and effort in a short amount of time to operationalize these important real-time forecasts. The groups have graciously and courageously made their public data available under different terms and licenses. You will find the licenses (when provided) within the model-specific folders in the [data-processed](./data-processed/) directory. Please consult these licenses before using these data to ensure that you follow the terms under which these data were released.

All source code that is specific to this project, along with our [d3-foresight](http://reichlab.io/d3-foresight/) visualization tool is available under an open-source [MIT license](./LICENSE). We note that this license does NOT cover model code from the various teams (maybe available from them under other licenses) or model forecast data (available under specified licenses as described above). 

## What forecasts we are tracking, and for which locations
Different groups are making forecasts at different times, and for different geographic scales. The specifications below were created by consulting with collaborators at CDC and looking at what models forecasting teams were already building. 

**What do we consider to be "gold standard" data?**
We will use the daily reports containing
[case](https://github.com/CSSEGISandData/COVID-19/blob/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv) and
[death](https://github.com/CSSEGISandData/COVID-19/blob/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv) data from the JHU CSSE group as the gold standard reference data for deaths in the US. 
These data are the time-series version of the JHU data that do occasionally contain "revisions" of previous daily reports. Note that there are not insignificant differences (especially in daily incident death data) between the JHU data and another commonly used source, from the New York Times. The team at UTexas-Austin is tracking this issue on [a separate GitHub repository](https://github.com/spencerwoody/covid19-data-comparsion).

**When will forecast data be updated?** 
We will be storing new forecasts from each group as they are either provided to 
us directly via pull requests. 
Teams are encouraged to submit data as often has they have it available, 
although we only support one upload for each day. 
In general, "updates" to forecasts will not be permitted. 
Teams are responsible for checking that their forecasts are ready for public viewing upon submission. 
This can be done locally using our [interactive visualization tool](https://github.com/reichlab/covid19-forecast-hub/wiki/Interactive-Visualization).

**What locations will have forecasts?**
Currently, forecasts may be submitted for any state and county in the US and the US at the national level.

**How will probabilistic forecasts be represented?**
Forecasts will be represented in [a standard format](#data-model) using quantile-based representations of predictive distributions. We encourage all groups to make available the following 23 quantiles for each distribution: `c(0.01, 0.025, seq(0.05, 0.95, by = 0.05), 0.975, 0.99)`. One goal of this effort is to create probabilistic ensemble forecasts, and having high-resolution component distributions will provide data to create better ensembles. 

**What forecast targets will be stored?**
We will store forecasts for 
1 through 20 week-ahead _incident_ and _cumulative_ deaths, 
0 through 130 day-ahead _incident_ hospitalizations, and 
1 through 8 week-ahead _incident_ reported cases. 
Please refer to the [technical README](https://github.com/reichlab/covid19-forecast-hub/blob/master/data-processed/README.md) for details on aligning targets with forecast dates.

<!-- To be clear about how the time periods relate to the time at which a forecast was made, we provide the following specficiations (which are subject to change or re-evaluation as we get further into the project). Every submitted forecast will have an associated `forecast_date` that corresponds to the day the forecast was made. For day-ahead forecasts with a forecast date of a Monday, a 1 day ahead forecast corresponds to incident deaths on Tuesday or cumulative deaths by the end of Tuesday, 2 day ahead to Wednesday, etc.... 
<!-- For day-ahead forecasts collected on Thursdays, a 1 day ahead forecast corresponds to Friday, 2 day ahead to Saturday, etc.... 


For week-ahead forecasts with `forecast_date` of Sunday or Monday of EW12, a 1 week ahead forecast corresponds to EW12 and should have `target_end_date` of the Saturday of EW12. For week-ahead forecasts with `forecast_date` of Tuesday through Saturday of EW12, a 1 week ahead forecast corresponds to EW13 and should have `target_end_date` of the Saturday of EW13. A week-ahead forecast should represent the total number of incident deaths or hospitalizations within a given epiweek (from Sunday through Saturday, inclusive) or the cumulative number of deaths reported on the Saturday of a given epiweek. We have created [a csv file](template/covid19-death-forecast-dates.csv) describing forecast collection dates and dates for which forecasts refer to can be found.
-->

## Ensemble model
Every Monday at 6pm ET, we will update our [COVID Forecast Hub ensemble forecast](data-processed/COVIDhub-ensemble) and [interactive visualization](http://viz.covid19forecasthub.org) using the most recent forecast from each team as long as it was submitted before 6pm ET on Monday and has a `forecast_date` of any day since the previous Tuesday. All models meeting the above criteria will be considered for the ensemble. For inclusion in the ensemble, we additionally require that forecasts include a full set of 23 quantiles to be submitted (see [technical README](https://github.com/reichlab/covid19-forecast-hub/blob/master/data-processed/README.md#quantile) for details), and that the 10th quantile of the predictive distribution for a 1 week ahead forecast is not below the most recently observed data. Additionally, we perform manual visual inspection checks to ensure that forecasts are in alignment with the ground truth data. Details on which models were included each week in the ensemble are available in the [ensemble metadata](https://github.com/reichlab/covid19-forecast-hub/tree/master/ensemble-metadata) folder.

Depending on how the project evolves, we may add additional weekly builds for the ensemble and visualization. Currently, our ensemble is created by taking the arithmetic average of each quantile for all models that submit 1- through 4-week ahead cumulative death targets for a given location. Ensemble methods and inclusion criteria may evolve as more data becomes available. 

## Forecast files
Participating teams provide their 
[forecasts](https://github.com/reichlab/covid19-forecast-hub/tree/master/data-processed) 
in a quantile-based format. 
We have developed specifications that can be used to represent all of the 
forecasts in a simple, long-form data format. 
For details about this file format specifications, please see the 
[technical README](https://github.com/reichlab/covid19-forecast-hub/blob/master/data-processed/README.md).


## Teams and models
Our list of teams whose forecasts are currently standardized and in the 
repository are (with data reuse license):

 - [Auquan](https://covid19-infection-model.auquan.com/) (none given)
 - [CDDEP](https://cddep.org/covid-19/) (none given)
 - [Columbia University](https://github.com/shaman-lab/COVID-19Projection) (Apache 2.0)
 - [CovidActNow](https://covidactnow.org/) (none given)
 - [COVID-19 Simulator Consortium](https://covid19sim.org/) (CC-BY-4.0)
 - [Discrete Dynamical Systems](https://dds-covid19.github.io/) (MIT)
 - [epiforecasts](https://github.com/epiforecasts/covid-us-deaths) (MIT)
 - [GLEAM from Northeastern University](https://www.gleamproject.org/covid-19) (CC-BY-4.0)
 - [Georgia Institute of Technology](https://www.cc.gatech.edu/~badityap/covid.html) (none given)
 - [Georgia Institute of Technology - Center for Health and Humanitarian Systems](https://github.com/pkeskinocak/COVID19GA) (none given)
 - [IHME](https://covid19.healthdata.org/united-states-of-america) (CC-AT-NC-4.0)
 - [Iowa State University](http://www.covid19dashboard.us/) (none given)
 - [Iowa State University and Peking University](https://yumouqiu.shinyapps.io/covid-predict/) (none given)
 - [Karlen Working Group](https://pypm.github.io/home/) (gpl-3.0)
 - [LANL](https://covid-19.bsvgateway.org/) (see [license](./data-processed/LANL-GrowthRate/LICENSE.txt))
 - [Imperial](https://github.com/sangeetabhatia03/covid19-short-term-forecasts) (CC-BY-NC-ND 4.0)
 - [John Burant (JCB)](https://github.com/JohnBurant/COVID19-PRM) (CC-BY-4.0)
 - [Johns Hopkins ID Dynamics COVID-19 Working Group](https://github.com/HopkinsIDD/COVIDScenarioPipeline) (MIT)
 - [Massachusetts Institute of Technology](https://www.covidanalytics.io/) (Apache 2.0)
 - [Notre Dame](https://github.com/confunguido/covid19_ND_forecasting) (none given)
 - [Predictive Science Inc](https://predsci.com) (MIT)
 - [Areon Oliver Wyman](https://pandemicnavigator.oliverwyman.com/)(none given)
 - Quantori (none given)
 - Snyder Wilson Consulting (none given)
 - [STH](https://public.tableau.com/profile/covid19model#!/vizhome/COVID-19DeathProjections/USDeaths) (none given)
 - US Army Engineer Research and Development Center (ERDC) (see [license](./data-processed/USACE-ERDC_SEIR/LICENSE.txt))
 - University of Arizona (CC-BY-NC-SA 4.0)
 - [University of California, Los Angeles](https://covid19.uclaml.org/) (CC-BY-4.0)
 - [University of California Merced MESA Lab](http://mechatronics.ucmerced.edu/covid19)(CC-BY-4.0)
 - [University of Geneva / Swiss Data Science Center](https://renkulab.shinyapps.io/COVID-19-Epidemic-Forecasting/) (none given)
 - [University of Massachusetts - Expert Model](https://github.com/tomcm39/COVID19_expert_survey) (MIT)
 - [University of Massachusetts - Mechanistic Bayesian model](https://github.com/dsheldon/covid) (MIT)
 - [University of Michigan](https://gitlab.com/sabcorse/covid-19-collaboration) (cc-by-4.0)
 - [University of Texas-Austin](https://covid-19.tacc.utexas.edu/projections/) (BSD-3)
 - [University of Virginia](https://biocomplexity.virginia.edu/) (cc-by-4.0)
 - [YYG](http://covid19-projections.com) (MIT) 
 - COVIDhub ensemble forecast: this is a combination of the above models. 

Participating teams must provide a 
[metadata file](https://github.com/reichlab/covid19-forecast-hub/blob/master/data-processed/METADATA.md).

## The COVID Forecast Hub Team
Carefully curating these datasets into a standard format has taken a Herculean team effort. The following lists those who have helped out, in reverse alphabetical order: 

 - Nutcha Wattanachit (ensemble model, data processing)
 - Serena Wang (data curation)
 - Nicholas Reich (project lead, ensemble model, data processing)
 - Evan Ray (ensemble model)
 - Jarad Niemi (data processing and organization)
 - Khoa Le (validation, automation)
 - Ayush Khandelwal (architecture, data curation)
 - Abdul Hannan Kanji (architecture, data curation)
 - Katie House (visualization, validation, project management)
 - Estee Cramer (data curation, ensemble model)
 - Matt Cornell (validation, Zoltar integration)
 - Andrea Brennen (metadata curation)
 - Johannes Bracher (evaluation, data processing)
