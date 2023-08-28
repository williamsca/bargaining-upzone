# Data requested from Loudoun Couty Office of Mapping and GIS on 8/7/2023
# mapping@loudoun.gov

# Public mapping portal:
# https://www.loudoun.gov/3362/LOLA

rm(list = ls())
library(here)
library(data.table)
library(sf)
library(ggplot2)
library(lubridate)
library(stringr)

# Import ----
sf_zone <- st_read(here("data", "LoudounCo",
    "GIS", "Zoning_Shp_20230809", "ZONING_POLY.shp")
)

sf_sap <- st_union(st_read(here(
    "data", "LoudounCo", "GIS",
    "Loudoun_Small_Area_Plans",
    "Loudoun_Small_Area_Plans.shp"
)))

sf_sap <- st_transform(sf_sap, st_crs(sf_zone))
sf_sap <- st_sf(Name = "Loudoun Small Area Plans",
    geometry = sf_sap)

sf <- st_join(sf_zone, st_buffer(sf_sap, dist = 200),
    join = st_covered_by)

# Exempt after Loudoun Small Area Plans adopted
# on 12/6/2016
sf$isExempt <- (!is.na(sf$Name))

saveRDS(sf, here("derived", "LoudounCo",
                 "Zoning GIS.Rds"))
