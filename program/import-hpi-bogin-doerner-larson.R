# This script downloads the housing price index constructed in
# Bogin, Doerner, and Larson (2019). Data downloaded on
# 10/9/2023 from:
# https://www.fhfa.gov/PolicyProgramsResearch/Research/Pages/wp1601.aspx

rm(list = ls())
library(here)
library(data.table)
library(readxl)

CONSTANT_YEAR <- 2015

# Import ----
dt <- as.data.table(read_xlsx(here("data",
    "housing-prices", "bogin-doerner-larson-hpi",
    "HPI_AT_BDL_county.xlsx"), skip = 6))

dt[, Year := as.numeric(Year)]
dt[, HPI := as.numeric(HPI)]

# Deflate ----
dt_cpi <- as.data.table(read_xlsx(
    "crosswalks/CPI/CUUR0000SA0 CPI-U (1995-2022).xlsx",
    skip = 10
))

dt_cpi[, Annual := Annual / dt_cpi[Year == CONSTANT_YEAR, Annual]]
dt <- merge(dt, dt_cpi[, .(Year, Annual)],
    by = c("Year")
)
nrow(dt[is.na(Annual)]) == 0

dt[, HPI := HPI / Annual]

dt <- dt[, c("FIPS code", "Year", "HPI")]
setnames(dt, c("FIPS", "Year4", "HPI"))

saveRDS(dt, here("derived", "hpi-bogin-etal.Rds"))
