# Truth data

This folder contains the truth data that forecasts are compared to. 
The main files in this folder contain the JHU data while subfolders
contain other data sources.
As described in the 
[technical README](../data-processed/README.md),
the JHU data is being used as the "gold standard" for forecasts. 

## Truth generation scripts
There are multiple truth data generation scripts for multiple endpoints that consume this data: 
- **Visualization**: `get-truth-data.py` is the script used to generate the truth file that is consumed by the visualization. Here, the Incidence forecasts are lower bounded to 0.  
- **Zoltar** - `zoltar-truth-data.py` is the script used for uploading teh truth data to Zoltar. Here, the Incidence forecasts are *not* lower bounded to 0.  

## Weeks and locations with documented reporting errors
Due to reporting errors, there are weeks where large increases in deaths or cases are reported for a given state. Because these additions are factors of data reporting and therefore could not be forecasted, we are keeping track of these places so we do not include them in our forecast evaluations. A list of all reported errors can be found in the [JHU CSSE Repository](https://github.com/CSSEGISandData/COVID-19/tree/master/csse_covid_19_data). A modified list of locations we have removed prior to scoring can be found [here](https://github.com/reichlab/covid19-forecast-hub/blob/master/data-truth/Dates_edit_evaluation.csv). We will continue to update our list when new reporting errors arise.
