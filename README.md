## <img src="https://covid19forecasthub.org/images/forecast-hub-logo_DARKBLUE.png" alt="Hub logo" width="400"/>

[![Zoltar build status](https://github.com/reichlab/covid19-forecast-hub/actions/workflows/upload_to_zoltar.yml/badge.svg)](https://github.com/reichlab/covid19-forecast-hub/actions/workflows/upload_to_zoltar.yml) [![DOI](https://zenodo.org/badge/254453761.svg)](https://zenodo.org/badge/latestdoi/254453761)

## Note  
As of Wednesday, May 1, 2024, the US COVID-19 Forecast Hub is no longer accepting submissions. Current plans are to accept submissions starting in the fall, possibly in a different format. Information provided on forecast submissions are kept for historical record.
***

This is the data repository for the [COVID-19 Forecast Hub](https://covid19forecasthub.org/), which is the data source for [the official CDC COVID-19 Forecasting page](https://www.cdc.gov/coronavirus/2019-ncov/science/forecasting/forecasting-math-modeling.html). 

If you are a modeling team interested in submitting to the Hub, please visit our [technical README with detailed submission instructions](https://github.com/reichlab/covid19-forecast-hub/blob/master/data-processed/README.md).

If you are interested in using the forecast data in a research project, you may clone this repo or use our [`covidHubUtils` R package](https://github.com/reichlab/covidHubUtils) to access the data through an API. Participating teams provide their 
[forecasts](https://github.com/reichlab/covid19-forecast-hub/tree/master/data-processed) 
in a [quantile-based format](https://github.com/reichlab/covid19-forecast-hub/blob/master/data-processed/README.md#Data-formatting). Please also follow the data license and citation guidelines below.

If you are a developer interested in the infrastructure here, we encourage you to check out [the Hub documentation wiki](https://github.com/reichlab/covid19-forecast-hub/wiki).

## Citing the Forecast Hub

- To cite the US COVID-19 Forecast Hub dataset and project as a whole, please cite the dataset descriptor article:

Cramer EY, Huang Y, Wang Y, et al. The United States COVID-19 Forecast Hub dataset. Scientific Data, 2022, vol. 9, no 1, p. 462. URL: https://doi.org/10.1038/s41597-022-01517-w  
 
bibtex:
```
@article {Cramer2022-hub-dataset,
	author = {Cramer, Estee Y and Huang, Yuxin and Wang, Yijin and Ray, Evan L and Cornell, Matthew and Bracher, Johannes and Brennen, Andrea and Castro Rivadeneira, Alvaro J and Gerding, Aaron and House, Katie and Jayawardena, Dasuni and Kanji, Abdul H and Khandelwal, Ayush and Le, Khoa and Niemi, Jarad and Stark, Ariane and Shah, Apurv and Wattanachit, Nutcha and Zorn, Martha W and Reich, Nicholas G and US COVID-19 Forecast Hub Consortium},
	title = {The United States COVID-19 Forecast Hub dataset},
	year = {2022},
	doi = {10.1101/2021.11.04.21265886},
	URL = {https://doi.org/10.1038/s41597-022-01517-w},
	journal = {Scientific Data}
}
```

- To cite research results from the hub, please choose the relevant [research publication](https://covid19forecasthub.org/doc/research/) from the Hub to cite.

- To cite the dataset and GitHub repository directly, we ask that you cite the Data Descriptor paper (see first bullet point above) but you may also cite or refer to the [permanent DOI for the GitHub repo](https://zenodo.org/badge/latestdoi/254453761) (the DOI is updated by Zenodo when we create a new "release" of this GitHub repository).

## Data license and reuse
We are grateful to the teams who have generated these and made their data publicly available under different terms and licenses. You will find the licenses (when provided) within the model-specific folders in the [data-processed](./data-processed/) directory. Please consult these licenses before using these data to ensure that you follow the terms under which these data were released.

All source code that is specific to this project, along with our [d3-foresight](http://reichlab.io/d3-foresight/) visualization tool is available under an open-source [MIT license](./LICENSE). We note that this license does NOT cover model code from the various teams (maybe available from them under other licenses) or model forecast data (available under specified licenses as described above). 
