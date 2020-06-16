# Metadata dictionary

Each model is required to have metadata in yaml format.
This file describes each of the variables (keys) in the yaml document.

## Required variables

### team_name

The name of your team that is less than 50 characters.

### team_abbr

An abbreviated name for your team that is less than 15 alphanumeric characters and cannot 
inlucde a dash (-) or a whitespace. 

### model_name

The name of your model that is less than 50 characters.

### model_abbr

An abbreviated name for your model that is less than 15 alphanumeric characters and cannot
include a dash (-) or a whitespace.

### methods

A brief description of your forecasting methodology that is less than 200 
characters.

## model_url

A url to a website that has additional data about your model. We encourage teams to 
submit a url to the most user-friendly version of your model, e.g. a dashboard, 
or similar, that displays your model forecasts. If you have additionally a data repository
where you store forecasts and other model code, please include that in your methods
section below. If you only have a more technical site, please include that link here.


## Optional

### institional_affil

You institutional affiliation, if you have one. 

### team_funding 

Like an acknowledgement in a manuscript, you can acknowledge funding here.


### model_contributors

A list of individuals involved in the forecasting effort. At least one contributor
needs to have a valid email address. Any email addresses provided will be added to 
an email distribution list for model contributors.


### data_inputs_known

A description of the data sources used to inform the model, 
e.g. "NYTimes death data", "JHU CSSE case and death data", mobility data, etc. 


### this_model_is_an_ensemble

true/false indicating whether the model here is a combination of a set of other
models


### methods_long

An extended description of the methods used in the model. 
If the model is modified, this field can be used to provide the date of the 
modification and a description of the change.


### citation

A url to an extended description of your model,
e.g. blog post, website, preprint, or peer-reviewed manuscript. 
