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
library(parallel)
library(foreach)
library(doParallel)

print(sprintf("weekly report generation, %s", Sys.Date()))

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
# all_states <-locs[58,] # VI#
# all_states <- locs[c(56, 58),] # PR, VI
# all_states <- locs[c(2:52, 54, 56, 58),] # all
# all_states <- locs[c(2, 58),] # AK and VI
all_states <- locs[c(2:52, 56, 58),] # all but Guam

state_fips <- all_states$fips
state_ab <- all_states$abbreviation
today_date <- Sys.Date()
# # # use fixed date
# today_date <-  as.Date("2021-06-08")

# make Zoltar connection here and reuse it throughout generation
print("trying to connect to Zoltar...")
zoltar_conn <- zoltr::new_connection()
num_tries <- 0
success <- FALSE
while(num_tries < 5 && !success) {
  tryCatch(
    # try to authenticate
    {
      zoltr::zoltar_authenticate(
        zoltar_conn,
        Sys.getenv("Z_USERNAME"),
        Sys.getenv("Z_PASSWORD")
      )
      # <<- superassignment: should only do if preceding scope have
      # such a variable!
      # this statement is reached only if authentication is successful
      success <<- TRUE
    },
    # authentication failed! retry
    error = function(c) {
      print(sprintf("Zoltar connection failed! %d retries remaining...", num_tries))
    },
    # add one to number of retries
    finally = function(c) {
      # <<- superassignment: should only do if preceding scope have
      # such a variable!
      num_tries <<- num_tries + 1
    }
  )
}
if (!success) {
  stop("could not make connection to Zoltar after 5 tries")
} else {
  print("connected to Zoltar!")
}

# render report based on a state fips code
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

# --- render report all states ---
print("rendering state-level reports...")

# attempt parallelism
# try to detect number of cores
# see https://stackoverflow.com/questions/50168647/multiprocessing-causes-python-to-crash-and-gives-an-error-may-have-been-in-progr/52230415
# for MacOS >10.13 multithreading issues
print("attempting to parallelize state-level report generation...")
numCores <- parallel::detectCores()
print(paste0("Number of logical cores: ", numCores))
if (!is.na(numCores) || numCores == 1) {
  print("multi-core system detected! starting state-level report generation in parallel...")
  registerDoParallel(numCores)
  
  # gather potential errors during generation
  errors <- foreach (i=seq_len(nrow(all_states)), .errorhandling = 'pass') %dopar% {
    render_state_weekly_report(all_states[i,]$fips, all_states[i,]$abbreviation, zoltar_conn)
  }
  
  # filter out NULL results (no errors)
  errors <- errors[-which(sapply(errors, is.null))]
  
  # handle any errors
  if (length(errors) > 0) {
    browser()
    for (i in seq_len(length(errors))) {
      print("error ", i)
      print(errors[i])
    }
  }
  
# default to non-parallelism
} else {
  print("single-core system or multi-core detection failed;")
  print("   starting state-level report generation in sequence")
  curr_state <- "--"
  tryCatch(
    {
      for (i in seq_len(nrow(all_states))) {
        curr_state <<- all_states[i,]$abbreviation
        render_state_weekly_report(all_states[i,]$fips, all_states[i,]$abbreviation, zoltar_conn)
      }
    },
    error = function(c) {
      print(sprintf("error while generating reports for %s", curr_state))
      print(c)
    }
  )
    
}

# --- try to re-render reports if some failed ---

# get all files from current (output) directory
curr_dir_files <- list.files()

# filter to get the report files (starts with today's date)
report_files <- curr_dir_files[
  which(sapply(
    curr_dir_files,
    function(s) {
      return(
        startsWith(s, toString(Sys.Date())) &
        endsWith(s, ".html")
      )
    }
  ))
]

# filter to get the failed reports

# the 4th element in the split filename is the state abbr.
# e.g. "2020-01-01-AK-weekly-report.html" split by "-" will
# give the state abbr. at the 4th index
successful_states <- lapply(
  report_files, function (fn) unlist(strsplit(fn, "-"))[4]
)

unsuccessful_states <- all_states$abbreviation[
  -which(sapply(all_states$abbreviation, function (st) { st %in% successful_states } ))
]

# re-render failed reports
curr_state <- "--"
tryCatch(
  {
    for (i in seq_len(nrow(all_states))) {
      if (all_states[i,]$abbreviation %in% unsuccessful_states) {
        curr_state <<- unsuccessful_states[i]
        render_state_weekly_report(all_states[i,]$fips, all_states[i,]$abbreviation, zoltar_conn)
      }
    }
  },
  error = function(c) {
    print(sprintf("error while generating reports for %s", curr_state))
    print(c)
  }
)

# --- render report for national level ---
print("rendering national-level report...")

tryCatch(
  {
    rmarkdown::render(
      'weekly-report.Rmd',
      output_file = paste0(today_date, '-weekly-report.html'),
      params = list(conn = zoltar_conn),
      quiet = TRUE
    )
  },
  error = function(c) {
    print("error while generating national-level report")
    print(c)
  }
)


print("weekly reports generation done!")
