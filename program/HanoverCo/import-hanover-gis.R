# This script imports the Hanover County Zoning Data
# downloaded on 8/29/2023 from:
# https://data-hanovercounty.hub.arcgis.com/datasets/hanovercounty::zoning/about

rm(list = ls())
library(here)
library(data.table)
library(sf)
library(ggplot2)

# Import ----
sf <- st_read(here(
    "data", "HanoverCo", "GIS",
    "Zoning",
    "Zoning.shp"
))
