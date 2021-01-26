# a list of state fips code to generate report with
locs <- hub_locations %>%
  rename(Population = population)

# # for testing
# state_fips = c("25","42","19")

#run in chunks
# all_states <-locs[2:21,] #28,33 minutes
# # all_states <-locs[22:52,] # 42 minutes
# all_states <-locs[2:42,] # 67 minutes
# all_states <-locs[43:52,] # 13 minutes

# run without chunks
all_states <-locs[2:52,] # 75 minutes


state_fips<-all_states$fips
today_date<-Sys.Date()

# render report based on a state fips code
render_weekly_report <- function(curr_state_fips){
  rmarkdown::render(
    'all-states-weekly-report.Rmd',
    # rename output file, CHANGE DATE
    output_file = paste0(today_date,'-', curr_state_fips, '-weekly-report.html'), 
    params = list(state = curr_state_fips)
  )
}

# render report all states
for (state in state_fips){
  render_weekly_report(state)
}


