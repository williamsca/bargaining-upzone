# This script imports the rezoning applications from the
# Prince William County archive, downloaded on 8/15/2023 from:
# https://egcss.pwcgov.org/SelfService#/search?m=1&fm=1&ps=10&pn=1&em=true&st=rezoning

rm(list = ls())

library(here)
library(data.table)
library(lubridate)

# Import ----
l_files <- list.files("data/PrinceWilliamCo/Applications",
    pattern = "*.csv", full.names = TRUE)

read_application <- function(file) {
    dt <- read.csv(file)
    dt$path <- file
    return(dt)
}

dt <- rbindlist(lapply(l_files, read_application), fill = TRUE)

# Clean ----
# Drop minor modifications, comp plan amendments, proffer amendments
v_types <- c("Rezoning - Mixed Use", "Rezoning - Non-Residential",
    "Rezoning - Residential")
dt <- dt[Type %in% v_types]

dt[, isResi := (Type != "Rezoning - Non-Residential")]
dt[, isApproved := (Status == "Approved")]

dt[, submit_date := mdy(Applied.Date)]
nrow(dt[is.na(submit_date)]) == 0

# Save ----
saveRDS(dt, paste0("derived/PrinceWilliamCo/Rezoning Applications (",
    paste(range(year(dt$submit_date)), collapse = "-"), ").Rds"))
