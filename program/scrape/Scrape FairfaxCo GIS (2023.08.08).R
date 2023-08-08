# This script downloads GIS data from Fairfax County
# that indicates areas which were exempt from the
# Proffer Reform Act of 2016.

rm(list = ls())
pacman::p_load(here, data.table, httr, jsonlite)

url <- "https://www.fairfaxcounty.gov/euclid/rest/services/DPZ/PZViewerLayers/MapServer/dynamicLayer/query?f=json&where=(1%3D1)%20AND%20(1%3D1)&returnGeometry=true&spatialRel=esriSpatialRelIntersects&outFields=*&orderByFields=OBJECTID%20ASC&outSR=102100&resultOffset=0&resultRecordCount=50&layer=%7B%22source%22%3A%7B%22type%22%3A%22mapLayer%22%2C%22mapLayerId%22%3A12%7D%7D"

response <- httr::GET(url)

if (status_code(response) == 200) {
    content <- httr::content(response, as = "text")
    l_response <- jsonlite::fromJSON(content, simplifyVector = TRUE)

    dt <- as.data.table(l_response$features)
}

# TODO: convert the geometry.rings column to a polygon that sf can read

sf <- st_as_sf(dt, wkt = "geometry.rings", crs = st_crs("ESRI:102100"))

