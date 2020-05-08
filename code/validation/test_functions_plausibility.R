# A modest attempt at testing the R functions for plausibility checks
# Keep in mind that the checks in Python are authoritative.

# Johannes Bracher, April 2020

# make sure locale is English US
Sys.setlocale(category = "LC_TIME", locale = "en_US.UTF8")

source("code/validation/functions_plausibility.R")

#---------------------------------------
# verify_filename

# correct:
print(verify_filename("2020-04-23-CU-nointerv.csv"))

# wrong file type:
print(verify_filename("2020-04-23-CU-nointerv.txt"))

# does not start with date in right format:
print(verify_filename("2020-Apr-23-CU-nointerv.csv"))
print(verify_filename("2020-02-23-CU-nointerv.csv"))



# get an example data set:
dat <- read.csv("data-processed/CU-80contact/2020-04-26-CU-80contact.csv", stringsAsFactors = FALSE)

#-----------------------------------------
# verify_colnames
dat_modified <- dat

# correct:
print(verify_colnames(dat))

# missing colname
dat_modified <- dat[, -1]
print(verify_colnames(dat_modified))

# additional colname
dat_modified <- cbind(dat, catch_me = 1)
print(verify_colnames(dat_modified))
# should not cause warning anymore

# wrong colname:
dat_modified <- dat
colnames(dat_modified)[1] <- "catch me"
print(verify_colnames(dat_modified))

# colnames in wrong order
dat_modified <- dat
colnames(dat_modified) <- colnames(dat)[c(2:1, 3:ncol(dat_modified))]
print(verify_colnames(dat_modified))

#------------------------------------------
# verify entries of `quantile`

# correct:
print(verify_quantile_levels("data-processed/CU-80contact/2020-04-26-CU-80contact.csv"))

# containing a disallowed entry in `quantile`:
dat_modified <- dat
dat_modified$quantile[1] <- 0.5000000000001
write.csv(dat_modified, file = "test_verify_quantile_levels.csv")
print(verify_quantile_levels("test_verify_quantile_levels.csv"))
file.remove("test_verify_quantile_levels.csv")


#------------------------------------------
# check_agreement_forecast_date

# correct:
print(check_agreement_forecast_date(file = "2020-04-26-CU-nointerv.csv", entry = dat))

# change file name:
print(check_agreement_forecast_date(file = "2020-04-24-CU-nointerv.csv", entry = dat))

# change one entry of forecast_date:
dat_modified <- dat
dat_modified$forecast_date[1] <- "2019-04-19"
print(check_agreement_forecast_date(file = "2020-04-24-CU-nointerv.csv", entry = dat_modified))

#------------------------------------------
# verify_no_na

# correct:
verify_no_na(dat)

# add NA to column other than quantile:
dat_modified <- dat
dat_modified$target[1] <- NA
print(verify_no_na(dat_modified))


# add NA to quantile column despite type == "quantile:
dat_modified <- dat
dat_modified$quantile[min(which(dat_modified$type == "quantile"))] <- NA
verify_no_na(dat_modified)

#------------------------------------------
# verify_targets

# correct:
print(verify_targets(dat))

# wrong target:
dat_modified <- dat
dat_modified$target[1] <- "wrong target"
print(verify_targets(dat_modified))

#------------------------------------------
# verify date formats:

# correct:
print(verify_date_format(dat))

# wrong format in forecast_date:
dat_modified <- dat
dat_modified$forecast_date[1] <- "2020/07/08"
print(verify_date_format(dat_modified))

# wrong format in target_end_date:
dat_modified <- dat
dat_modified$target_end_date[1] <- "2020/07/08"
print(verify_date_format(dat_modified))

# NA
dat_modified$forecast_date[1] <- NA
print(verify_date_format(dat_modified))

#------------------------------------------
# verify other aspects concerning dates: verify_forecast_date_end_date

# correct:
verify_forecast_date_end_date(dat)

# target_end_date not a Saturday for a week-ahead forecast
dat_modified <- dat
dat_modified$target_end_date[which(dat_modified$target == "1 wk ahead cum death")[1]] <-
  "2020-05-04"
print(verify_forecast_date_end_date(dat_modified))

# target_end_date one week too late by one week
dat_modified <- dat
dat_modified$target_end_date[which(dat_modified$target == "1 wk ahead cum death")[1]] <-
  as.character(as.Date(dat_modified$target_end_date[which(dat_modified$target == "1 wk ahead cum death")[1]]) + 7)
print(verify_forecast_date_end_date(dat_modified))

# target_end_date one week too early by one week
dat_modified <- dat
dat_modified$target_end_date[which(dat_modified$target == "1 wk ahead cum death")[1]] <-
  as.character(as.Date(dat_modified$target_end_date[which(dat_modified$target == "1 wk ahead cum death")[1]]) - 7)
print(verify_forecast_date_end_date(dat_modified))

# incoherence between forecast_date, target and target_end_date
dat_modified <- dat
dat_modified$target_end_date[which(dat_modified$target == "1 day ahead cum death")[1]] <-
  "2020-05-13"
print(verify_forecast_date_end_date(dat_modified))

# NA values:
dat_modified <- dat
dat_modified$target_end_date[1] <- NA
print(verify_forecast_date_end_date(dat_modified))

#-----------------------------------------
# verify_no_quantile_crossings

# correct:
print(verify_no_quantile_crossings(dat))

# quantile crossing in daily forecast:
dat_modified <- dat
dat_modified$value[min(which(dat_modified$quantile == 0.75 & dat_modified$target == "1 day ahead inc death"))] <- 100000
print(verify_no_quantile_crossings(dat_modified))

# quantile crossing in weekly forecast:
dat_modified <- dat
dat_modified$value[min(which(dat_modified$quantile == 0.75 & dat_modified$target == "1 wk ahead cum death"))] <- 100000
print(verify_no_quantile_crossings(dat_modified))

#-----------------------------------------
# verify_monotonicity_cumulative

# correct:
print(verify_monotonicity_cumulative(dat))

# add temporal non-monotonicity in daily forecasts:
dat_modified <- dat
dat_modified$value[min(which(dat_modified$quantile == 0.75 & dat_modified$target == "2 day ahead cum death"))] <- 0
print(verify_monotonicity_cumulative(dat_modified))

# add temporal non-monotonicity in weekly forecasts:
dat_modified <- dat
dat_modified$value[min(which(dat_modified$quantile == 0.75 & dat_modified$target == "2 wk ahead cum death"))] <- 0
print(verify_monotonicity_cumulative(dat_modified))

#------------------------------------------
# verify_cumulative_geq_incident

# correct:
print(verify_cumulative_geq_incident(dat))

# incidence exceeds cumulative:
dat_modified <- dat
dat_modified$value[min(which(dat_modified$quantile == 0.75 & dat_modified$target == "2 day ahead inc death"))] <- 10000000
print(verify_cumulative_geq_incident(dat_modified))
