# This script imports the rezoning applications from the
# Prince William County archive, downloaded on 8/15/2023 from:
# https://egcss.pwcgov.org/SelfService#/search?m=1&fm=1&ps=10&pn=1&em=true&st=rezoning

rm(list = ls())
library(here)
library(data.table)
library(lubridate)

# Import ----
dt_pwc <- fread(here(
    "data", "PrinceWilliamCo",
    "Applications", "Rezoning1-1000.csv"
))

names(dt_pwc) <- gsub(" ", ".", names(dt_pwc))

dt_pwc[, FIPS := 51153]

dt_pwc[, submit_date := mdy(Applied.Date)]

# Save ----
saveRDS(dt_pwc, here(
    "derived", "PrinceWilliamCo",
    "Rezoning Applications.Rds"
))