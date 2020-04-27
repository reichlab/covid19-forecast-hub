

# UT-Austin forecast for US deaths from COVID-19

"Projections for first-wave COVID-19 deaths across the US using
social-distancing measures derived from mobile phones"

Spencer Woody, Mauricio Tec, Maytal Dahan, Kelly Gaither, Michael
Lachmann, Spencer J. Fox, Lauren Ancel Meyers, and James Scott

The University of Texas at Austin


## About the model

For each US state, we use local data from mobile-phone GPS traces made
available by [SafeGraph] to quantify the changing impact of
social-distancing measures on ``flattening the curve.''  SafeGraph is
a data company that aggregates anonymized location data from numerous
applications in order to provide insights about physical places. To
enhance privacy, SafeGraph excludes census block group information if
fewer than five devices visitedan establishment in a month from a
given census block group.

We use a Bayesian multilevel negative binomial regression model for
the number of deaths for each day, and implement the model in R using
the `[rstanarm]` package.

For more details, see the [technical report]. 


## Format of raw data

The file `[date]-UTexas-sdmetrics-raw.csv` contains the following columns

- `date`, the date for which to make forecasts
- `location_name`, the state name, or `"United States"` for a sum across all 50
  states + DC
- `location`, a FIPS code (string) for the state, or `"US"` for a sum
  across all 50 states + DC
- `quantile_x`, the `x`-level posterior quantile of *incident* deaths
  for a given date
- `quantilecm_x`, the `x`-level posterior quantile of *cumulative*
  deaths for a given date

Note that for our point estimate, we return the 50% posterior quantile
(posterior median). 


## Daily updates

Although this repo contains forecasts captured every Monday, [our
forecasts are updated daily here.][forecasts]



[SafeGraph]: https://www.safegraph.com/
[forecasts]: https://covid-19.tacc.utexas.edu/projections/
[technical report]: https://covid-19.tacc.utexas.edu/media/filer_public/87/63/87635a46-b060-4b5b-a3a5-1b31ab8e0bc6/ut_covid-19_mortality_forecasting_model_latest.pdf
[rstanarm]: https://mc-stan.org/users/interfaces/rstanarm
