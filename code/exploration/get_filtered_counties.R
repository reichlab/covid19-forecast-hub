#' Extract top N US counties by size
#'
#' @param n_top number of counties to extract
#'
#' @return a data frame based on JHU CSSE data with info on population
#'
#' @examples
get_filtered_counties <- function(n_top=100, include_US=TRUE) {
    require(tidyverse)
    fips_codes <- read_csv("data-locations/locations.csv")
    dat <- read_csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/UID_ISO_FIPS_LookUp_Table.csv")
    exclude_counties = c('Kings, New York, US', 
        'Queens, New York, US', 
        'Bronx, New York, US', 
        'Richmond, New York, US')
    
    # Subset to locations: 
    #   (1) in US,
    idx_us <- dat$iso2=="US"
    #   (2) with county name,
    idx_county_name <- !is.na(dat$Admin2)
    #   (3) with FIPS code recognized by forecast hub
    idx_recognized_fips <- dat$FIPS %in% fips_codes$location
    #   (4) not in list of NYC counties with no data on JHU
    idx_nyc <- !(dat$`Combined_Key` %in% exclude_counties)
    
    dat_filtered <- dat[idx_us & idx_county_name & idx_recognized_fips & idx_nyc,] %>%
        mutate(state_fips = substr(FIPS, 0, 2)) %>%
        left_join(select(fips_codes, -location_name), by=c("state_fips" = "location")) %>%
        mutate(loc_name = reorder(factor(paste(Admin2, abbreviation, sep=", ")), X=-Population))
    
    dat_return <- slice_max(dat_filtered, order_by = Population, n=n_top)
    
    if(include_US) {
        dat_us <- dat[dat$UID==840,]
        dat_us$FIPS <- dat_us$Admin2 <- dat_us$loc_name <- "US"
        dat_return <- bind_rows(dat_return, dat_us) %>%
            mutate(loc_name = reorder(loc_name, X=-Population))
    }
    
    return(dat_return)
}
