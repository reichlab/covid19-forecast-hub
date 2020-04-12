## reformat Imperial forecasts
## Nicholas Reich
## April 2020

library(tidyverse)

#' Transform matrix of samples for one location into a quantile-format data_frame
#'
#' @param sample_mat matrix of samples, columns are horizons, rows are samples
#' @param location_id the FIPS code for the location for this matrix
#' @param qntls set of quantiles for which forecasts will be computed, defaults to c(0.025, 0.1, 0.2, .5, 0.8, .9, 0.975)
#'
#' @return long-format data_frame with quantiles
#' 
#' @details Assumes that the matrix gives 1 through 7 day ahead forecasts
#'
lengthen_qntl_dat <- function(sample_mat, location_id, qntls=c(0.01, 0.025, seq(0.05, 0.95, by=0.05), 0.975, 0.99)) {
    require(tidyverse)
    cols_to_include <- paste(1:7, "day ahead")
    
    ## choosing quantile type=1 b/c more compatible with discrete samples
    ## other choices gave decimal answers
    qntl_dat <- apply(sample_mat, FUN=function(x) quantile(x, qntls, type=1), MAR=2) 
    colnames(qntl_dat) <- cols_to_include
    
    qntl_dat_long <- as_tibble(qntl_dat) %>%
        mutate(location_id=location_id, quantile = qntls, type="quantile") %>%
        pivot_longer(cols=cols_to_include, names_to = "target_id") 
    
    point_ests <- qntl_dat_long %>% 
        filter(quantile==0.5) %>% 
        mutate(quantile=NA, type="point")
    
    all_dat <- bind_rows(qntl_dat_long, point_ests) %>%
        arrange(type, target_id, quantile) %>%
        mutate(quantile = round(quantile, 3))
        
    return(all_dat)
}


## this reads in an RDS file provided by the Imperial team  on April 11
ens_preds <- readRDS("./data-raw/Imperial/20200405-ensemble_model_predictions.rds")

## the object is a big list, with one element for each of the 5 times forecasts were made
## each of those elements is itself a list, with one element for each country
## each of the country-specific items is a list with two ensemble forecasts, one for each serial interval assumption
## each forecast itself is a matrix with rows as samples (30K) and columns representing days in the future

## this code produces the mean predicted incident deaths for seven day-ahead
colMeans(ens_preds$`2020-04-05`$United_States_of_America[[1]])
# 2020-04-06 2020-04-07 2020-04-08 2020-04-09 2020-04-10 2020-04-11 2020-04-12 
# 1686.197   1928.872   2225.703   2574.990   2987.386   3469.986   4028.954 

## transform and write the files for each date
qntl_mdl_1_20200405 <- lengthen_qntl_dat(ens_preds$`2020-04-05`$United_States_of_America[[1]], location_id="US")
qntl_mdl_2_20200405 <- lengthen_qntl_dat(ens_preds$`2020-04-05`$United_States_of_America[[2]], location_id="US")
write_csv(qntl_mdl_1_20200405, path = "data-processed/Imperial-ensemble1/2020-04-05-Imperial-ensemble1.csv")
write_csv(qntl_mdl_2_20200405, path = "data-processed/Imperial-ensemble2/2020-04-05-Imperial-ensemble2.csv")

qntl_mdl_1_20200329 <- lengthen_qntl_dat(ens_preds$`2020-03-29`$United_States_of_America[[1]], location_id="US")
qntl_mdl_2_20200329 <- lengthen_qntl_dat(ens_preds$`2020-03-29`$United_States_of_America[[2]], location_id="US")
write_csv(qntl_mdl_1_20200329, path = "data-processed/Imperial-ensemble1/2020-03-29-Imperial-ensemble1.csv")
write_csv(qntl_mdl_2_20200329, path = "data-processed/Imperial-ensemble2/2020-03-29-Imperial-ensemble2.csv")

qntl_mdl_1_20200322 <- lengthen_qntl_dat(ens_preds$`2020-03-22`$United_States_of_America[[1]], location_id="US")
qntl_mdl_2_20200322 <- lengthen_qntl_dat(ens_preds$`2020-03-22`$United_States_of_America[[2]], location_id="US")
write_csv(qntl_mdl_1_20200322, path = "data-processed/Imperial-ensemble1/2020-03-22-Imperial-ensemble1.csv")
write_csv(qntl_mdl_2_20200322, path = "data-processed/Imperial-ensemble2/2020-03-22-Imperial-ensemble2.csv")

qntl_mdl_1_20200315 <- lengthen_qntl_dat(ens_preds$`2020-03-15`$United_States_of_America[[1]], location_id="US")
qntl_mdl_2_20200315 <- lengthen_qntl_dat(ens_preds$`2020-03-15`$United_States_of_America[[2]], location_id="US")
write_csv(qntl_mdl_1_20200315, path = "data-processed/Imperial-ensemble1/2020-03-15-Imperial-ensemble1.csv")
write_csv(qntl_mdl_2_20200315, path = "data-processed/Imperial-ensemble2/2020-03-15-Imperial-ensemble2.csv")

