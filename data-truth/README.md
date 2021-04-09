# Truth data

This folder contains the truth data that forecasts are compared to. 
The main files in this folder contain the JHU data while subfolders
contain other data sources.
As described in the 
[technical README](../data-processed/README.md),
the JHU data is being used as the "gold standard" for forecasts. 

## Truth generation schedule and scripts
The automated GitHub Action updates the truth weekly at 12pm on Sundays. The configuration for the workflow can be found [here](https://github.com/reichlab/covid19-forecast-hub/blob/master/.github/workflows/active_update_truth_weekly.yml). This workflow calls multiple packages and their functions, as well as stand alone scripts to generate multiple truth data files to be consumed by different endpoints:
- **Deaths and Cases truths**: We use the [covidData](https://github.com/reichlab/covidData) package to get the most recent time series data for COVID-19 from the JHU data repository, then use the [preprocess_jhu()](https://github.com/reichlab/covidHubUtils/blob/master/R/get_truth.R#L232) method in the `covidHubUtils` package to transform these data into CSVs `truth-Cumulative Deaths.csv`, `truth-Incident Deaths.csv`, `truth-Cumulative Cases.csv` and `truth-Incident Cases.csv`.
- **Hospitalization truths**: We use the [covidData](https://github.com/reichlab/covidData) package to get the most recent time series data for hospitalization, then use the [preprocess_hospitalization()](https://github.com/reichlab/covidHubUtils/blob/master/R/get_truth.R#L291) method in the `covidHubUtils` package to transform these data into CSVs `truth-Cumulative Hospitalizations.csv` and `truth-Incident Hospitalizations.csv`.
- **Visualization truth**: `get_visualization_truth_json_from_csv.py` is the script used to generate the JSON truth file from the CSVs, so they can be consumed by the visualization. Here, the Incidence forecasts are lower bounded to 0. 
- **Zoltar truth**: [save_truth_for_zoltar](https://github.com/reichlab/covidHubUtils/blob/master/R/get_truth.R#L417) is the method in `covidHubUtils` used for generating the truth data for Zoltar. Here, the Incidence forecasts are *not* lower bounded to 0. 

## Weeks and locations with documented reporting errors
Due to reporting errors, there are weeks where large increases in deaths or cases are reported for a given state. Because these additions are factors of data reporting and therefore could not be forecasted, we are keeping track of these places so we do not include them in our forecast evaluations. A list of all reported errors can be found in the [JHU CSSE Repository](https://github.com/CSSEGISandData/COVID-19/tree/master/csse_covid_19_data). A modified list of locations we have removed prior to scoring can be found [here](https://github.com/reichlab/covid19-forecast-hub/blob/master/data-truth/Dates_edit_evaluation.csv). We will continue to update our list when new reporting errors arise.
