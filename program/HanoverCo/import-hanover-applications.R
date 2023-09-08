# This script downloads and filters the Hanover County
# rezoning application data, downloaded on 8/29/2023 from:
# https://communitydevelopment.hanovercounty.gov/eTRAKiT/Search/project.aspx

rm(list = ls())

library(here)
library(data.table)

# Import ----
l_files <- list.files(here(
    "data", "HanoverCo", "Applications"),
    pattern = "*.csv", full.names = TRUE)

dt <- rbindlist(lapply(l_files, fread))
