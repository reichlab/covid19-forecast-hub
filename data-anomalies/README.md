## Data anomalies 

This folder contains information on data anomalies identified within [the datasets that are treated as ground truth](https://github.com/reichlab/covid19-forecast-hub/tree/master/data-truth#data-sources) by the COVID-19 Forecast Hub. Specifically, the Hub has specific standardized processes, described below, to classify an observed data point value as either an "anomaly" or an "outlier". These classifications are made for a particular location, target variable (cases, hospitalizations and deaths), date corresponding to the observed value, and date on which the value was reported.

The processes documented below are open, transparent, and viewable by the public. We welcome collaboration or other contributions to these efforts, as well as others re-using the data that result from the procedures described below.

### Outlying data 

Outliers are defined as points that are dramatically different from the prevailing trends in a region, due to known or unknown factors that may drive changes in reporting. In our definition of outliers, we attempt to capture points that represent departures from trends that models should not be attempting to capture. Sometimes natural variation in observations occurs that is hard to distinguish from outlying observations. Researchers at the Hub have spent many hours trying to build automated anomaly detection methods to define outlying observations, however, the results from these experiments have never yielded consistently satisfactory results that improve over human judgment. Therefore, the Hub uses a process of human review that involves two individuals looking at data for each state each week to identify outlying points. The reviews are conducted independently of one another and merged into a single dataset. The reviews are publicly available at [this Google Spreadsheet](https://docs.google.com/spreadsheets/d/1Vw1Oakr-KdLB8RJoZNF7u6MRXMzg6iSJLpT_PpaKi2Y/edit?usp=sharing). 

Outliers are tabulated manually once a week, typically on Mondays. The reviews are based on the data in [the JHU CSSE data repository](https://github.com/CSSEGISandData/COVID-19) as of the last commit on Sunday (UTC time). Outliers are assessed for the state and national level for COVID-19 cases, hospitalizations and deaths.

### Revisions to data

Data that are initially reported by JHU CSSE and later revised are said to have been "revised". Data revisions can lead to models being "misled" by data that will later be changed or to computed evaluations of models going stale if the most recent version of data is desired. 

Revisions to reported COVID-19 case, death, and hospitalization data are compiled automatically using [an R script](create-revisions-csv.R). Revisions are tabulated at the county, state, and national level for cases, and at the state and national level for deaths and hospitalizations. This script is typically run once a week on Mondays, and it generates one file for each of the target variables ([cases](revisions-inc-case.csv), [deaths](revisions-inc-death.csv), [hospitalizations](revisions-inc-hosp.csv). Each file has the following columns:

- `location`: the FIPS code for the location that had the revision
- `location_name`: the name of the `location`
- `date`: the date of the observation that was revised
- `orig_obs`: the value of the original observed data point
- `issue` date: the date on which the revision was first observed
- `real_diff`: the difference between the `orig_obs` and the updated observation, computed as (revised observation - original observation)
- `relative_diff`: a computed measure of the relative difference defined as `real_diff / abs(orig_obs)` when `orig_obs!=0` and `real_diff` when `orig_obs==0`

