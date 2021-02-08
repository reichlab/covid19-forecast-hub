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
# all_states <-locs[2:3,] # test

state_fips<-all_states$fips
state_ab<-all_states$abbreviation
today_date<-Sys.Date()
# # # use fixed date
# today_date <-  as.Date("2021-01-26")

# render report based on a state fips code
render_weekly_report <- function(curr_state_fips,state_ab){
  rmarkdown::render(
    'all-states-weekly-report.Rmd',
    # rename output file
    output_file = paste0(today_date,'-', as.character(state_ab), '-weekly-report.html'), 
    params = list(state = curr_state_fips)
  )
}

# render report all states
for  (i in seq_len(nrow(all_states))) {
  render_weekly_report(all_states[i,]$fips, all_states[i,]$abbreviation)
}


