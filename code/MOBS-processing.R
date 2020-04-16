## NEU processing
## one-off updates for 4/13 file.

dat <- read_csv("data-raw/MOBS/2020-04-13-MOBS_NEU-GLEAM-COVID-19_v1.csv") %>%
    rename(target=target_id, location=location_id) %>%
    mutate(
        location = str_pad(as.character(location), width = 2, side = "left", pad = "0"),
        target = paste(target, "death"))

US_loc_idx <- which(dat$location=="00")
dat$location[US_loc_idx] <- "US"

dat$target <- sub("week", "wk", dat$target)

point_ests <- dat %>% 
    filter(quantile==0.5) %>% 
    mutate(quantile=NA, type="point")

all_dat <- bind_rows(dat, point_ests) %>%
    arrange(type, target, quantile) 

write_csv(all_dat, "data-processed/MOBS_NEU-GLEAM/2020-04-13-MOBS_NEU-GLEAM_COVID_19_v1.csv")

