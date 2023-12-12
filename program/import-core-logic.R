# This script imports the CoreLogic property basic historical
# snapshots from 2012 through the present. The data are combined
# to create a panel of residential property and the associated zoning
# designation.

rm(list = ls())
library(here)
library(data.table)

# Import ----
cols_basic <- c(
    "CLIP", "FIPS CODE", "CENSUS ID",
    "EFFECTIVE YEAR BUILT", "BEDROOMS - ALL BUILDINGS", "STORIES NUMBER",
    "NUMBER OF UNITS", "RESIDENTIAL MODEL INDICATOR", "PROPERTY INDICATOR CODE",
    "BUILDING CODE", "LAND USE CODE"
)
dt_prop <- fread(here(
    "data", "core-logic", "property-basic",
    "university_of_virginia_property_basic2_dpc_01468308_20230817_141501_VA.txt"
), select = cols_basic)

dt_prop <- dt_prop[`RESIDENTIAL MODEL INDICATOR` == "Y"]

dt_prop[, isVacant := `PROPERTY INDICATOR CODE` == 80]

# Append ----

# Clean ----

# Export ----
saveRDS(dt, here("derived", "parcel-zoning-panel.Rds"))