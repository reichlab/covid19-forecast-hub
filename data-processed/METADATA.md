# Metadata file structure

Each model is required to have metadata in 
[yaml format](https://docs.ansible.com/ansible/latest/reference_appendices/YAMLSyntax.html), 
e.g. [see this metadata file](https://github.com/reichlab/covid19-forecast-hub/blob/master/data-processed/JHU_IDD-CovidSP/metadata-JHU_IDD-CovidSP.txt).
This file describes each of the variables (keys) in the yaml document.
Please order the variables in this order.


## Required variables

### team_name
The name of your team that is less than 50 characters.

### model_name
The name of your model that is less than 50 characters.

### model_abbr
An abbreviated name for your model that is less than 30 alphanumeric characters. The model abbreviation must be in the format of `[team_abbr]-[model_abbr]`. where each of the `[team_abbr]` and `[model_abbr]` are text strings that are each less than 15 alphanumeric characters that do not include a hyphen or whitespace  Note that this is a uniquely identifying field in our system, so please choose this name carefully, as it may not be changed once defined. An example of a valid `model_abbr` is `UMass-MechBayes` or `UCLA-SuEIR`. 

### model_contributors

A list of all individuals involved in the forecasting effort
affiliations, and email address.
At least one contributor needs to have a valid email address. 
All email addresses provided will be added to 
an email distribution list for model contributors.

The syntax of this field should be 

    name1 (affiliation1) <user@address>, name2 (affiliation2) <user2@address2>

### website_url

(previously named `model_output`)

A url to a website that has additional data about your model. 
We encourage teams to submit the most user-friendly version of your 
model, e.g. a dashboard, or similar, that displays your model forecasts. 
If you have additionally a data repository
where you store forecasts and other model code, 
please include that in your methods section below. 
If you only have a more technical site, e.g. github repo, 
please include that link here.

### license

One of [licenses](https://github.com/reichlab/covid19-forecast-hub/blob/master/code/validation/accepted-licenses.csv).

We encourage teams to submit as a "cc-by-4.0" to allow the broadest possible uses
including private vaccine production 
(which would be excluded by the "cc-by-nc-4.0" license). 
If the value is "LICENSE.txt", 
then a LICENSE.txt file must exist within the folder and provide a license.

### team_model_designation 

Upon initial submission this field should be one of “primary”, “proposed” or “other”. 
For teams submitting only one model, this should be “primary”. 
For each team, only one model can be designated as “primary”. 

*Primary* means the model will be scored in evaluations, eligible for inclusion
in the [ensemble](https://github.com/reichlab/covid19-forecast-hub/tree/master/data-processed/COVIDhub-ensemble), 
and [visualized](https://viz.covid19forecasthub.org/).

*Proposed* means the team would like the model to be considered as a "secondary"
model rather than an "other" model. 
The Hub team will determine whether the model's
methodology is distinct enough that the model should be included in the ensemble 
in which case the model will get the "secondary" designation.
If the methodology is not distinct enough, e.g. it differs from the primary model
by setting certain parameters to specific values, then the model will be 
designated as "other". 

*Secondary* means the forecasts will be [visualized](https://viz.covid19forecasthub.org/) and eligible for inclusion
in the [ensemble](https://github.com/reichlab/covid19-forecast-hub/tree/master/data-processed/COVIDhub-ensemble), but will not be scored in evaluations. 

*Other* means the forecasts will not be visualized, included in the ensemble, 
nor scored in evaluations.


### methods

A brief description of your forecasting methodology that is less than 200 
characters.

### ensemble_of_hub_models

A boolean value (`true` or `false`) that indicates whether a model combines multiple hub models into an ensemble.


## Optional

### institutional_affil

University or company names, if relevant. 

### team_funding 

Like an acknowledgement in a manuscript, you can acknowledge funding here.

### repo_url

(previously `model_repo`)

A github (or similar) repository url. 

### twitter_handles

One or more twitter handles (without the @) separated by commas.


### data_inputs

A description of the data sources used to inform the model and the truth data
targetted by model forecasts. 
Common data sources are 
[NYTimes](https://github.com/nytimes/covid-19-data), 
[JHU CSSE](https://github.com/CSSEGISandData/COVID-19), 
[COVIDTracking](https://covidtracking.com/data), 
[Google mobility](https://www.google.com/covid19/mobility/), 
[HHS hospitalization](https://healthdata.gov/dataset/covid-19-reported-patient-impact-and-hospital-capacity-state-timeseries), etc. 

An example description could be 

> cases forecasts use NYTimes data and target JHU CSSE truth data,
> hospitalization forecasts use and target HHS hospitalization data





### citation

A url (doi link preferred) to an extended description of your model,
e.g. blog post, website, preprint, or peer-reviewed manuscript. 



### methods_long

An extended description of the methods used in the model. 
If the model is modified, this field can be used to provide the date of the 
modification and a description of the change.
