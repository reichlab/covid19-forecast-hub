## make template

library(tidyverse)

## shared parameters/data across state/national templates
death_targets <- c("1 day ahead inc death", "2 wk ahead cum death")
qntls <- c(0.01, 0.025, seq(0.05, 0.95, by = 0.05), 0.975, 0.99)

template <- tibble(
    target = rep(death_targets, each=length(qntls)+1),
    location = "01",
    type = rep(c("point", rep("quantile", each=length(qntls))),2),
    quantile = rep(c(NA, qntls), 2), 
    value = c(qpois(c(.5, qntls), 40), qpois(c(.5, qntls), 487))
)

write_csv(template, "template/2020-04-13-TeamName-ModelName.csv")
