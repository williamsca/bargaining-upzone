# This script imports the Henrico County Planning Case Data,
# downloaded on 8/29/2023 from:
# https://data-henrico.opendata.arcgis.com/datasets/Henrico::planning-department-cases/about

rm(list = ls())
library(here)
library(data.table)
library(sf)
library(ggplot2)

# Import ----
sf <- st_read(here("data", "HenricoCo", "GIS",
    "Planning_Department_Cases",
    "Planning_Department_Cases.shp"))

sf$COMMENTS <- NULL

# Filter to rezoning cases
sf <- subset(sf, CASE_TYPE == "REZ")

# Guess the rezoning case year
sf$Year <- sub(".*-.*-(.*)", "\\1", sf$CASENO)

sf$Year <- ifelse(nchar(sf$Year) == 2,
    paste0("20", sf$Year), substr(sf$Year, 4, 7))
sf$Year <- as.numeric(sf$Year)

sf$Year <- ifelse(sf$Year > 2030, sf$Year - 100, sf$Year)

# Plot ----
ggplot(subset(sf, Year %between% c(2005, 2020)),
       aes(x = Year)) +
    geom_bar()
