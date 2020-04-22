# Determine what the most recent processed data from each group is
# run from the directory this file is found in

library("dplyr")
library("tidyr")
library("readr")

read_my_csv = function(f, into) {
  readr::read_csv(f) %>%
    dplyr::mutate(file = f) %>%
    tidyr::separate(file, into, sep="-|/") 
}

read_my_dir = function(path, pattern, into, exclude) {
  files = list.files(path       = path,
                     pattern    = pattern,
                     recursive  = TRUE,
                     full.names = TRUE) %>%
    setdiff(exclude)
  plyr::ldply(files, read_my_csv, into = into)
}

# above from https://gist.github.com/jarad/8f3b79b33489828ab8244e82a4a0c5b3
#############################################################################

d = read_my_dir(".", "*.csv",
                into = c("period","group","model",
                         "year","month","day","group2","model_etc"),
                exclude = c("./COVIDhub-ensemble/COVIDhub-ensemble-information.csv",
                            "./truth-cum-death.csv",
                            "./zoltar-truth-cum-death.csv",
                            "./Imperial-ensemble1/Imperial-forecast-dates.csv",
                            "./Imperial-ensemble2/Imperial-forecast-dates.csv")) 

d2 = d %>%  
  
  mutate(date = as.Date(paste(year,month,day, sep="-"))) %>%
  group_by(group, model, date) %>%
  
  summarize(
    has_US     = ifelse(any(location == "US"), "Yes", "-"),
    all_states = ifelse(all(state.name %in% location_name),"Yes","-"),
    cd1d = ifelse(any(target == "1 day ahead cum death"),"Yes","-"),
    cd2d = ifelse(any(target == "2 day ahead cum death"),"Yes","-"),
    cd3d = ifelse(any(target == "3 day ahead cum death"),"Yes","-"),
    cd4d = ifelse(any(target == "4 day ahead cum death"),"Yes","-"),
    cd5d = ifelse(any(target == "5 day ahead cum death"),"Yes","-"),
    cd6d = ifelse(any(target == "6 day ahead cum death"),"Yes","-"),
    cd7d = ifelse(any(target == "7 day ahead cum death"),"Yes","-")
  ) %>%
  arrange(group, model)


# d2 %>% filter(group == "UTexas")

d2 %>% filter(date == max(date))
