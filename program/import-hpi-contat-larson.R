# This script imports the Contat and Larson (2023) housing
# price index and aggregates it to the county level.

# The data were downloaded on 10/5/2023 from:
# https://www.fhfa.gov/PolicyProgramsResearch/Research/Pages/wp2101.aspx

rm(list = ls())
library(here)
library(data.table)

# Import ----
dt <- fread(here("data", "housing-prices", "contat-larson-hpi",
                 "wp2101-data-tract.csv"), keepLeadingZeros = TRUE)


dt[, FIPS := substr(tract, 1, 5)]

# Data are unique by tract and year
nrow(dt) == uniqueN(dt[, .(tract, year)])

View(dt[1:1000])

# Aggregate ----
# TODO: import tract-level number of single-family housing units
# TODO: construct weights based on tract share of county housing units
# TODO: aggregate to county level