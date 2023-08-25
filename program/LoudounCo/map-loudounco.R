rm(list = ls())
library(here)
library(data.table)
library(ggplot2)
library(sf)
library(tigris)

# Import ----
sf_sap <- st_read(here("data", "LoudounCo",
    "GIS", "Loudoun_Small_Area_Plans",
    "Loudoun_Small_Area_Plans.shp")
)

sf <- readRDS(here("derived", "LoudounCo",
                   "Rezoning GIS.Rds"))

sf_recent <- subset(sf, ZO_ZONE_DA > ymd("2000-01-01"))

# Map
ggplot() +
    geom_sf(data = sf_sap, fill = "lightgray") +
    geom_sf(data = sf_recent, aes(fill = isExempt)) +
    theme(
        axis.text.x = element_blank(), axis.text.y = element_blank(),
        axis.ticks.x = element_blank(), axis.ticks.y = element_blank(),
        panel.background = element_blank()
    )
