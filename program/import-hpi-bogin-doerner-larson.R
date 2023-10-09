# This script downloads the housing price index constructed in
# Bogin, Doerner, and Larson (2019). Data downloaded on
# 10/9/2023 from:
# https://www.fhfa.gov/PolicyProgramsResearch/Research/Pages/wp1601.aspx

rm(list = ls())
library(here)
library(data.table)
library(readxl)

# Import ----
dt <- read_xlsx(here("data", "housing-prices", "bogin-doerner-larson-hpi",
                     "HPI_AT_BDL_county.xlsx"), skip = 6)

dt <- dt[, c("FIPS code", "Year", "HPI")]
setnames(dt, c("FIPS", "Year4", "HPI"))

saveRDS(dt, here("derived", "hpi-boginetal.Rds"))
