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
