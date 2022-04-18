library(lubridate)
library(DT)
library(zoltr) ## devtools::install_github("reichlab/zoltr")
library(scico)
source("../processing-fxns/get_next_saturday.R")
library(tidyverse)
library(htmltools)
library(covidHubUtils)
theme_set(theme_bw())
library(crosstalk)
library(plotly)

print(sprintf("weekly report generation, %s", Sys.Date()))

# use newer version of Pandoc if possible
rmarkdown::find_pandoc(version = "2.13")
print(rmarkdown::pandoc_version())


#
# check for the required COVIDhub-ensemble forecast file
#

next_saturday <- as.Date(covidHubUtils::calc_target_week_end_date(lubridate::today(), horizon = 0))
this_monday <- next_saturday - 5
ensemble_file <- paste0("../../data-processed/COVIDhub-ensemble/", this_monday, "-COVIDhub-ensemble.csv")
if (!file.exists(ensemble_file)) {
  print(paste0("ensemble file not found: ", ensemble_file))
  quit(save = "default", status = 2, runLast = FALSE)  # error: No such file or directory
} else {
  print(paste0("ensemble file found: ", ensemble_file))
}


#
# a list of state fips code to generate report with
#

locs <- hub_locations %>%
  rename(Population = population)

all_states <- locs[c(2:52, 56, 58),] # all but Guam
state_fips <- all_states$fips
state_ab <- all_states$abbreviation

today_date <- Sys.Date()


#
# render report based on a state fips code
#

render_state_weekly_report <- function(curr_state_fips, state_ab, conn) {
  print(sprintf("    generating report for %s...", state_ab))
  rmarkdown::render(
    'all-states-weekly-report.Rmd',
    # rename output file
    output_file = paste0(today_date, '-', as.character(state_ab), '-weekly-report.html'),
    params = list(state = curr_state_fips, conn = conn),
    quiet = TRUE
  )
  print("        done!")
}


#
# render report all states
#

print("rendering state-level reports...")

zoltar_conn <- zoltr::new_connection()
zoltr::zoltar_authenticate(zoltar_conn, Sys.getenv("Z_USERNAME"), Sys.getenv("Z_PASSWORD"))
retries <- 0
success <- FALSE
for (i in seq_len(nrow(all_states))) {
  retries <<- 0
  success <<- FALSE
  tryCatch({
    while (retries < 5 && !success) {
      render_state_weekly_report(all_states[i,]$fips, all_states[i,]$abbreviation, zoltar_conn)
      success <<- TRUE
    }
  },
    error = function(c) {
      print(sprintf("error while generating reports for %s", all_states[i,]$abbreviation))
      print(c)
      retries <<- retries + 1
    })
  if (!success) {
    print("quitting because one or more state reports failed to generate")
    quit(save = "default", status = 1, runLast = FALSE)  # error
  }
}


#
# render report for national level
#

print("rendering national-level report...")

retries <- 0
success <- FALSE
tryCatch(
{
  while (retries < 5 && !success) {
    rmarkdown::render(
      'weekly-report.Rmd',
      output_file = paste0(today_date, '-weekly-report.html'),
      params = list(conn = zoltar_conn),
      quiet = TRUE
    )
    success <<- TRUE
  }
},
  error = function(c) {
    print("error while generating national-level report")
    print(c)
    retries <<- retries + 1
  }
)
if (!success) {
  print("quitting because national report failed to generate")
  quit(save = "default", status = 1, runLast = FALSE)  # error
}


#
# done!
#

print("weekly reports generation done!")
quit(save = "default", status = 0, runLast = FALSE)  # Success
