library(lubridate)
library(DT)
library(zoltr) ## devtools::install_github("reichlab/zoltr")
library(scico)
source("../processing-fxns/get_next_saturday.R")
library(tidyverse)
library(htmltools)
library(covidHubUtils)
theme_set(theme_bw())

# new libraries
library(crosstalk)
library(plotly)

# parallelizing report generation
library(foreach)
library(doParallel)

# use newer version of Pandoc if possible
rmarkdown::find_pandoc(version = "2.13")
print(rmarkdown::pandoc_version())

# a list of state fips code to generate report with
locs <- hub_locations %>%
  rename(Population = population)

# # for testing
# state_fips = c("60")

#run in chunks
# all_states <-locs[2:21,] #28,33 minutes
# # all_states <-locs[22:52,] # 42 minutes
# all_states <-locs[2:42,] # 67 minutes
# all_states <-locs[43:52,] # 13 minutes

# run without chunks
# all_states <-locs[2:52,] # 75 minutes
# all_states <-locs[54,] # Guam#
# all_states <-locs[56,] # PR#
# all_states <-locs[25,] # MN
all_states <-locs[58,] # VI#
# all_states <- locs[c(56, 58),] # PR, VI
# all_states <- locs[c(2:52, 54, 56, 58),] # all
#vall_states <- locs[c(2:52, 56, 58),] # all but Guam

state_fips <- all_states$fips
state_ab <- all_states$abbreviation
today_date <- Sys.Date()
# # # use fixed date
# today_date <-  as.Date("2021-01-26")

# render report based on a state fips code
render_state_weekly_report <- function(curr_state_fips, state_ab) {
  rmarkdown::render(
    'all-states-weekly-report.Rmd',
    # rename output file
    output_file = paste0(today_date, '-', as.character(state_ab), '-weekly-report.html'), 
    params = list(state = curr_state_fips)
  )
}

# render report all states
# parallelism
numCores <- 4 # change this number to the number of cores on your computer
registerDoParallel(numCores)
#foreach (i=seq_len(nrow(all_states))) %dopar% {
#  render_state_weekly_report(all_states[i,]$fips, all_states[i,]$abbreviation)
#}

# render report for national level
rmarkdown::render(
  'weekly-report.Rmd',
  output_file = paste0(today_date, '-weekly-report.html')
)
