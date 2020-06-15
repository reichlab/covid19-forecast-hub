# Metadata dictionary

Each model is required to have metadata in yaml format.
This file describes each of the variables (keys) in the yaml document.

## Required variables

### team_name

The name of your team. 

### team_abbr

An abbreviated name for your team that is less than 15 characters and cannot 
inlucde a dash (-). 

### model_name

The name of your model.

### model_abbr

An abbreviated name for your model that is less than 15 characters and cannot
include a dash (-).

### methods

A brief description of your forecasting methodology that is less than 200 
characters.


## Optional

### institional_affil

You institutional affiliation, if you have one. 

### team_funding 

Like an acknowledgement in a manuscript, you can acknowledge funding here.

### team_experience

???  what is expected here?

### model_output

A url for a dashboard, or similar, for your model forecasts. 

??? is this accurate?


### model_repo

A repository for your model code and forecasts. 

### model_contributors

A list of individuals involved in the forecasting effort.

### Model_targets

A subset of the [model targets](https://github.com/reichlab/covid19-forecast-hub/tree/master/data-processed#target)
that your model provides forecasts for.

??? formatting

??? why is this key capitalized

??? Do we need this field? We can just extract this information from the 
forecasts themselves.

### target_loc

The locations this model provides forecasts for. 

??? format

??? Do we need this field? We can just extract this information from the 
forecasts themselves.

### Data_format

??? what is this?

??? why is this capitalized

### forecast_startdate

The earliest date forecasts were provided from this model. 

??? Is the earliest on the Hub or earliest on their website?

??? Do we need this field? We can just extract this information from the 
forecasts themselves.

### forecast_frequency

The frequency of forecasts from this model, e.g. daily, weekly. 

??? Is the frequency on the Hub or frequency on their website?

??? Do we need this field? We can just extract this information from the 
forecasts themselves.


### data_inputs_known

A description of the data sources used to inform the model, 
e.g. deaths, cases, mobile, etc. 


### data_source_known

A description of the source of the data in the previous key. 


### this_model_is_an_ensemble

true/false indicating whether the model here is a combination of a set of other
models


### this_model_is_unconditional

true/false indicating whether this model assumes a particular future scenario
(false) or whether it is trying to predict the future that will occur (true). 

??? is this accurate


### methods_long

An extended description of the methods used in the model. 
If the model is modified, this field can be used to provide the date of the 
modification and a description of the change.


### citation

A url to an extended description of your model. 
