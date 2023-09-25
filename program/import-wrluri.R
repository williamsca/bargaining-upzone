# This script imports the Wharton Land Use Regulatory Index

rm(list = ls())
library(here)
library(data.table)
library(haven)

# Import ----
dt <- read_dta(here("data", "WHARTONLANDREGULATIONDATA_1_15_2020",
    "WRLURI_01_15_2020.dta"))

table(dt$EI18)

sum(dt$EI18, na.rm = TRUE) / nrow(dt)

subset(dt, is.na(EI18))
