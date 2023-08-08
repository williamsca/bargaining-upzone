# This script downloads GIS data from Fairfax County
# that indicates areas which were exempt from the
# Proffer Reform Act of 2016.

# Tysons Tracker:
# https://tysons-tracker-fairfaxcountygis.hub.arcgis.com/search?collection=Dataset
# Search for "Tysons Urban Development Area"

rm(list = ls())
pacman::p_load(here, data.table, httr, jsonlite, sf)

# Reston ----
url <- "https://www.fairfaxcounty.gov/euclid/rest/services/DPZ/PZViewerLayers/MapServer/dynamicLayer/query?f=geojson&where=(1%3D1)%20AND%20(1%3D1)&returnGeometry=true&spatialRel=esriSpatialRelIntersects&outFields=*&orderByFields=OBJECTID%20ASC&outSR=102100&resultOffset=0&resultRecordCount=50&layer=%7B%22source%22%3A%7B%22type%22%3A%22mapLayer%22%2C%22mapLayerId%22%3A12%7D%7D"

response <- httr::GET(url)

if (status_code(response) == 200) {
    content <- httr::content(response, as = "text")

    sf <- sf::st_read(content)
}

# Tysons ----
sf_tysons <- st_read(paste0("data/FairfaxCo/GIS/Tysons_Urban_Development_Area/",
  "Tysons_Urban_Development_Area.shp"))

v_names <- c(
  "OBJECTID", "LABEL", "SHAPE_Area",
  "SHAPE_Length", "geometry"
)

# Stack ----
names(sf_tysons) <- v_names
sf <- subset(sf, select = v_names)

sf <- st_transform(sf, crs = 4326)

sf <- rbind(sf, sf_tysons)

saveRDS(sf, "derived/FairfaxCo/Reston and Tysons SF.Rds")
