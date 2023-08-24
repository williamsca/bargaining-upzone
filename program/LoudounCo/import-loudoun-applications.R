# Import Loudoun County Rezoning Applications
# Downloaded on 8/24/2023 from:
# https://loudouncountyvaeg.tylerhost.net/prod/selfservice#/search?m=1&fm=3&ps=10&pn=1&em=true&st=rezoning

rm(list = ls())
library(here)
library(data.table)
library(lubridate)

# Import ----
dt_loudoun <- fread(here(
    "data", "LoudounCo",
    "Applications", "Rezoning1-1000.csv"
))

names(dt_loudoun) <- gsub(" ", ".", names(dt_loudoun))

dt_loudoun[, FIPS := 51107]

dt_loudoun[, submit_date := mdy(Applied.Date)]

# Save ----
saveRDS(dt_loudoun, here("derived", "LoudounCo",
    "Rezoning Applications.Rds"))