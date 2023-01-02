# Ground truth data for the COVID-19 Forecast Hub

The data-truth folder contains the "ground truth" data that forecasts 
are eventually compared to. 
The main files in this folder contain processed versions of data from 
JHU CSSE data while subfolders contain other data sources.

*Table of Contents*

-   [Data sources](#data-sources)
-   [Case and death data](#case-and-death-data)
-   [Hospitalization data](#hospitalization-data)
-   [Accessing truth data](#accessing-truth-data)
-   [Where truth data is used](#Where-truth-data-is-used)
-   [Reporting anomalies](#Reporting-anomalies)


Data sources
----------------------

The [COVID-19 Forecast Hub](http://covid19forecasthub.org/) 
collates 
[daily deaths](https://github.com/CSSEGISandData/COVID-19/blob/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv)
and [confirmed cases](https://github.com/CSSEGISandData/COVID-19/blob/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv) 
from the Johns Hopkins University's (JHU) 
[Center for System Science and Engineering (CSSE)](https://systems.jhu.edu/) group's 
[COVID-19 github repository](https://github.com/CSSEGISandData/COVID-19) 
as the gold standard reference data for deaths in the US. 

We also collate case and death data from
[NYTimes](https://github.com/nytimes/covid-19-data) and 
[USAFacts](https://usafacts.org/visualizations/coronavirus-covid-19-spread-map/) 
for comparison to JHU.

Hospitalization data are taken from the [HealthData.gov COVID-19 Reported Patient Impact and Hospital Capacity by State Timeseries](https://healthdata.gov/Hospital/COVID-19-Reported-Patient-Impact-and-Hospital-Capa/g62h-syeh. 
More details on how these data are used are available in the [technical README](https://github.com/reichlab/covid19-forecast-hub/blob/master/data-processed/README.md#hospitalizations).

Some of these data are also available progammatically through the [EpiData](https://cmu-delphi.github.io/delphi-epidata/) API. 

Case and death data
-------------

There are several different sources for death data. All forecasts will
be compared to the [daily reports containing death data from the JHU
CSSE
group](https://github.com/CSSEGISandData/COVID-19/blob/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv)
as the gold standard reference data for deaths in the US. Note that
there are significant differences (especially in daily incident death
data) between the JHU data and another commonly used source, from the
New York Times. The team at UTexas-Austin has tracked this issue on [a
separate GitHub
repository](https://github.com/spencerwoody/covid19-data-comparsion).

Data from a variety of sources are available via the [COVIDcast Epidata
API](https://cmu-delphi.github.io/delphi-epidata/api/covidcast.html).

### Daily Truth Data
We aggregate and format both [Cumulative Death](https://github.com/reichlab/covid19-forecast-hub/blob/master/data-truth/truth-Cumulative%20Deaths.csv) and [Incident Death](https://github.com/reichlab/covid19-forecast-hub/blob/master/data-truth/truth-Incident%20Deaths.csv) truth data from the JHU CSSE group. Although these `csv`s are not explicitly used in the visualization code, they match the "Actual" line in the visualization. This [method](https://github.com/reichlab/covidHubUtils/blob/master/R/get_truth.R#L232) in `covidHubUtils` package creates these truth data csvs.

There are also corresponding methods in `covidHubUtils`, for truths from [NYTimes](https://github.com/reichlab/covidHubUtils/blob/master/R/get_truth.R#L53) and [USAFacts](https://github.com/reichlab/covidHubUtils/blob/master/R/get_truth.R#L138), that downloads and perform aggregation. The data is stored in [data-truth/nytimes/](https://github.com/reichlab/covid19-forecast-hub/tree/master/data-truth/nytimes) and [data-truth/usafacts/](https://github.com/reichlab/covid19-forecast-hub/tree/master/data-truth/usafacts)

### Weekly Truth Data
Weekly cumulative counts are the reported values as of the Saturday of each week.  For example, the weekly cumulative count for the week ending Saturday, August 1, 2020 is equal to the reported daily cumulative count for Saturday, August 1, 2020.

Weekly incident counts are calculated as the difference between consecutive weekly cumulative counts. For example, the weekly incident count for the week ending Saturday, August 1, 2020 is the difference between the weekly cumulative count for Saturday, August 1, 2020 and the weekly cumulative count for Saturday, July 25, 2020.

### Aggregation to State and National Level
The cumulative and incident counts at the state level are calculated by summing reported cumulative and incident counts in the JHU data file across all locations with the same value for the `Province_State` field. This includes some "county-level" records for which we do not request forecasts. These are records with a five-digit FIPS code beginning with `80` or `90`, corresponding to "Out of State" or "Unassigned" locations.  For this reason, the counts at the state level may in general be larger than the sum of the counts for the counties within a given state.

Special case: DC is recorded in the truth data with both county code 11001 and state code 11. We have made the decision to omit the county level data since it is duplicated by the state level data.

The counts at the national level are calculated as the sum of counts for all locations in the JHU data file. This includes counts for the Diamond Princess cruise ship, and so the counts for the state level again do not sum to the counts for the national level.


Hospitalization data
------------

In the week of 16 Nov 2020, a proposal was been made to use
HealthData.gov confirmed hospital admissions as the ground truth for
hospitalizations. Prior to this week, no official source for
hospitalization ground truth data had been identified. On 1 Dec 2020, a
final determination of was made to treat this source as official for 
the Hub, as detailed below.

### HealthData.gov Hospitalization Timeseries

The truth data that hospitalization forecasts (`inc hosp` targets) will
be evaluated against are the [HealthData.gov COVID-19 Reported Patient
Impact and Hospital Capacity by State
Timeseries](https://healthdata.gov/Hospital/COVID-19-Reported-Patient-Impact-and-Hospital-Capa/g62h-syeh).
These data are typically updated daily. An archive of updates is available
on [this page](https://healthdata.gov/dataset/COVID-19-Reported-Patient-Impact-and-Hospital-Capa/qqte-vkut).

A supplemental data source with daily counts that but does not include the full time-series
is [HealthData.gov COVID-19 Reported Patient Impact and Hospital
Capacity by
State](https://healthdata.gov/dataset/COVID-19-Reported-Patient-Impact-and-Hospital-Capa/6xf2-c3ie).

### Resources for Accessing Hospitalization Data

1.  We are working with our collaborators at the [Delphi Group at
    CMU](https://delphi.cmu.edu/) to make these data available through
    their [Delphi Epidata
    API](https://cmu-delphi.github.io/delphi-epidata/api/README.html).
    The current weekly timeseries of the hospitalization data as well as
    prior versions of the data are available as the [`covid_hosp`
    endpoint of the
    API](https://cmu-delphi.github.io/delphi-epidata/api/covid_hosp.html).
    This endpoint is also available through the [COVIDcast
    Epidata
    API](https://cmu-delphi.github.io/delphi-epidata/api/covidcast-signals/hhs.html).

2.  The Forecast Hub has developed the [`covidData` R
    package](https://github.com/reichlab/covidData) which facilitates
    downloading and storing HealthData.gov data on hospitalizations 
    (as well as JHU data on cases and deaths). This package requires a bit of set-up with python and
    `make` but it does provide tools to access all ground truth data
    used by the Hub. A vignette showing some basic functionality for the
    package is available in
    [Rmarkdown](https://github.com/reichlab/covidData/blob/master/vignettes/covidData.Rmd)
    ([click here to view the HTML
    vignette](https://htmlpreview.github.io/?https://github.com/reichlab/covidData/blob/master/vignettes/covidData.html)).

### Data processing

The hospitalization truth data is computed as the sum of the columns
`previous_day_admission_adult_covid_confirmed` and
`previous_day_admission_pediatric_covid_confirmed` which provide the new
daily admission for adults and kids, respectively. (Other columns
represent “suspected” COVID-19 hospitalizations, however because
definitions and implementations of suspected cases vary widely, our
public health collaborators have recommended using the above columns
only.)

Since these admission data are listed as “previous day” admissions in
the raw data, the truth data shifts values in the `date` column one day
earlier so that `inc hosp` align with the date the admissions occurred.

As an example, the following data from HealthData.gov

       date    | previous_day_admission_adult_covid_confirmed | previous_day_admission_pediatric_covid_confirmed
    -----------|----------------------------------------------|-------------------------------------------------
    2020-10-30 |                  5                           |                       12                        

would turn into the following observed data for incident
hospitalizations

       date    | incident_hospitalizations
    -----------|----------------------------
    2020-10-29 |          17               

National hospitalization, i.e. US, data are constructed from these data
by summing the data across all 50 states, Washington DC (DC), Puerto
Rico(PR), and the US Virgin Islands (VI). The HHS data do not include
admissions for additional territories.

### Additional resources

Here are a few additional resources that describe these hospitalization
data:

-   the [official document describing the “guidance for hospital
    reporting”](https://www.hhs.gov/sites/default/files/covid-19-faqs-hospitals-hospital-laboratory-acute-care-facility-data-reporting.pdf)
-   [US Hospital Reporting
    Dashboard](https://protect-public.hhs.gov/pages/covid19-module)
    showing the percent of hospitals that report data into the
    hospitalization dataset, by state

Accessing truth data
----------
While we go to some pains at the Forecast Hub to create accurate, verified, clean versions of the truth data, all of these should be seen as secondary sources to the original data at the JHU CSSE, HHS, and other sites.

### CSV files
A set of comma-separated plain text files are automatically updated every week with the latest observed values for each of the following targets: Cumulative Cases, Cumlative Deaths, Cumulative Hospitalizations, Incident Cases, Incident Deaths, Incident Hospitalizations. For each of these six targets, a corresponding CSV file is created in `data-truth/truth-[target name].csv`. Details on the scripts that update and validate the contents of these files every week can be found on [the Developer Wiki](https://github.com/reichlab/covid19-forecast-hub/wiki/Truth-Data).

### covidData R package
The Forecast Hub has developed the [`covidData` R
package](https://github.com/reichlab/covidData) which facilitates
downloading and storing all data used by the Hub. This package 
requires a bit of set-up with python and
`make`. A vignette showing some basic functionality for the
package is available in
[Rmarkdown](https://github.com/reichlab/covidData/blob/master/vignettes/covidData.Rmd)
([click here to view the HTML
vignette](https://htmlpreview.github.io/?https://github.com/reichlab/covidData/blob/master/vignettes/covidData.html)).

### covidHubUtils R package
The Forecast Hub has developed the [`covidHubUtils` R package](https://github.com/reichlab/covidHubUtils)
to facilitate the basic operations with forecast data, especially
downloading, plotting, and scoring forecasts.
A vignette showing some basic functionality for the
package is available in
[Rmarkdown](https://github.com/reichlab/covidHubUtils/blob/master/vignettes/covidHubUtils-overview.Rmd)
([click here to view the HTML
vignette](https://htmlpreview.github.io/?https://github.com/reichlab/covidHubUtils/blob/master/vignettes/covidHubUtils-overview.html)).

Where truth data is used
--------------

Truth data is used primarily to support the hub in the following tasks:

- creating [the interactive visualization](https://viz.covid19forecasthub.org/)
- building [weekly forecast summary reports](https://covid19forecasthub.org/reports/single_page.html)
- writing [research papers](https://covid19forecasthub.org/doc/research/)
- keeping truth data updated in [the structured data repository for the Forecast Hub](https://zoltardata.com/project/44)
- conducting ongoing analyses on ensemble building and model comparisons

### Visualization Truth Data
The `Actual` line in the visualization is based on [the JHU CSSE group](https://github.com/CSSEGISandData/COVID-19/blob/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv) truth data. The visualization uses this [Cumulative Death JSON](https://github.com/reichlab/covid19-forecast-hub/blob/master/visualization/vis-master/covid-csv-tools/dist/truth/Cumulative%20Deaths.json), and this [Incident Death JSON](https://github.com/reichlab/covid19-forecast-hub/blob/master/visualization/vis-master/covid-csv-tools/dist/truth/Incident%20Deaths.json). This [python script creates](https://github.com/reichlab/covid19-forecast-hub/blob/master/data-truth/get_visualization_truth_json_from_csv.py) these JSONS.

The [actual data the visualization uses (Forecasts + Truth Data) is in this folder](https://github.com/reichlab/covid19-forecast-hub/tree/master/visualization/vis-master/src/assets/data). These JSONs are created with the commands in [0-init-vis.sh](https://github.com/reichlab/covid19-forecast-hub/blob/master/visualization/0-init-vis.sh) using [the truth data](https://github.com/reichlab/covid19-forecast-hub/tree/master/visualization/vis-master/covid-csv-tools/dist/truth) when the visualization is built. The file called "season-latest" is the default view, which is also Cumulative Deaths. For each State key in the JSON, there is an `Actual` object that contains the truth data in the visualization. [More on the JSON structure here](https://github.com/reichlab/covid19-forecast-hub/tree/master/visualization/vis-master/src/assets/data). 

### Zoltar Truth Data
The Zoltar truth data is created with this [method](https://github.com/reichlab/covidHubUtils/blob/master/R/get_truth.R#L417) in `covidHubUtils` and is stored[here](https://github.com/reichlab/covid19-forecast-hub/blob/master/data-truth/zoltar-truth.csv).


Reporting anomalies
--------------
Some of these data sources documented above are occasionally revised and/or contain outlying observations. We are working to create a comprehensive documentation of those instances. You can read about the resources we provide on this in [the data-anomalies README file](../data-anomalies/README.md)
