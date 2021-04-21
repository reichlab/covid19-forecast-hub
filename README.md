
[![Hub logo](https://covid19forecasthub.org/images/forecast-hub-logo_DARKBLUE.png)](https://covid19forecasthub.org/)

![Node.js CI](https://github.com/reichlab/covid19-forecast-hub/workflows/Node.js%20CI/badge.svg) [![DOI](https://zenodo.org/badge/254453761.svg)](https://zenodo.org/badge/latestdoi/254453761)

This is the data repository for the [COVID-19 Forecast Hub](https://covid19forecasthub.org/), which is the data source for [the official CDC COVID-19 Forecasting page](https://www.cdc.gov/coronavirus/2019-ncov/covid-data/forecasting-us.html). 

If you are a modeling team interested in submitting to the Hub, please visit our [technical README with detailed submission instructions](https://github.com/reichlab/covid19-forecast-hub/blob/master/data-processed/README.md).

If you are interested in using the forecast data in a research project, you may clone this repo or use our [`covidHubUtils` R package](https://github.com/reichlab/covidHubUtils) to access the data through an API. Participating teams provide their 
[forecasts](https://github.com/reichlab/covid19-forecast-hub/tree/master/data-processed) 
in a [quantile-based format](https://github.com/reichlab/covid19-forecast-hub/blob/master/data-processed/README.md#Data-formatting). Please also follow the data license and citation guidelines below.

If you are a developer interested in the infrastructure here, we encourage you to check out [the Hub documentation wiki](https://github.com/reichlab/covid19-forecast-hub/wiki).

## Data license and reuse
We are grateful to the teams who have generated these and made their data public available under different terms and licenses. You will find the licenses (when provided) within the model-specific folders in the [data-processed](./data-processed/) directory. Please consult these licenses before using these data to ensure that you follow the terms under which these data were released.

All source code that is specific to this project, along with our [d3-foresight](http://reichlab.io/d3-foresight/) visualization tool is available under an open-source [MIT license](./LICENSE). We note that this license does NOT cover model code from the various teams (maybe available from them under other licenses) or model forecast data (available under specified licenses as described above). 

To cite the COVID-19 Forecast Hub, please use a [relevant research article or preprint produced by the group](https://covid19forecasthub.org/doc/research/) and a [permanent DOI for the GitHub repo](https://zenodo.org/badge/latestdoi/254453761) (the DOI is updated by Zenodo when we create a new "release" of this GitHub repository).
