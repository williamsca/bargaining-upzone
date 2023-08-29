# This script downloads parcel data for Hanover County,
# downloaded on 8/29/2023 from:
# https://parcelmap.hanovercounty.gov/

rm(list = ls())
library(here)
library(data.table)

# Import ----
dt <- fread(here(
    "data", "HanoverCo", "Parcels",
    "1171d8ccfa5a444f876e6a8b7c3d8b01.csv"
))

nrow(dt)
uniqueN(dt$`GPIN #`)
