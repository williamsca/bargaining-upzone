# This script imports the Wharton Land Use Regulatory Index
# Downloaded on 9/26/2023 from:
# https://real-faculty.wharton.upenn.edu/gyourko/land-use-survey/

rm(list = ls())
library(here)
library(data.table)
library(haven)

# Import ----
dt18 <- as.data.table(read_dta(here("data", "WRLURI",
    "WRLURI_01_15_2020.dta")))

dt06 <- as.data.table(read_dta(here("data", "WRLURI",
    "WHARTON LAND REGULATION DATA_1_24_2008.dta")))

# Inspect ----

table(dt$EI18)

sum(dt$EI18, na.rm = TRUE) / nrow(dt)

subset(dt, is.na(EI18))

# Save ----
saveRDS()