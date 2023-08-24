# This script imports rezoning applications for a set
# of counties and cities in Virginia. It then standardizes
# the columns and exports a combined binary file for analysis.

rm(list = ls())
library(here)
library(data.table)
library(lubridate)

# Import ----
dt_loudoun <- readRDS(here("derived", "LoudounCo",
    "Rezoning Applications.Rds"))

dt_pwc <- readRDS(here("derived", "PrinceWilliamCo",
    "Rezoning Applications.Rds"))

# Sanity Checks ----
# Loudoun County
uniqueN(dt_loudoun$Case.Number) == nrow(dt_loudoun)
nrow(dt_loudoun[is.na(submit_date)]) == 0

# Prince William County
uniqueN(dt_pwc$Case.Number) == nrow(dt_pwc)
nrow(dt_pwc[is.na(submit_date)]) == 0

# Clean ----
# Drop minor modifications, comp plan amendments, proffer amendments
v_types <- c(
    "Rezoning - Mixed Use", "Rezoning - Non-Residential",
    "Rezoning - Residential"
)
dt <- dt[Type %in% v_types]

dt[, isResi := (Type != "Rezoning - Non-Residential")]
dt[, isApproved := (Status == "Approved")]

# TODO: parse 'Description' field to determine old and new
# zoning code