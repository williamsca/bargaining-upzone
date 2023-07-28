# Scrape the Chesterfield County ArcGIS site for parcel, zoning data
# See 'Case Information' from:
# https://geospace.chesterfield.gov/pages/plans-zoning--development-application-gallery

# NOTE: This script does not extract the parcel geometry. To do so,
# change the 'returnGeometry=' option to 'true' in the URL below.

rm(list = ls())
pacman::p_load(here, data.table, httr, jsonlite, lubridate)

N_RECORDS <- 1500

# Scrape latest archived rezoning cases ----
for (offset in seq(375, N_RECORDS, 25)) { # 375 is roughly the start of 2020
    url <- paste0(
        "https://services3.arcgis.com/TsynfzBSE6sXfoLq/ArcGIS/rest/",
        "services/Planning/FeatureServer/22/query?f=json&where=",
        "(Status%20%3D%20%27Approved%27)%20OR%20(Status%20%3D%20%27Denied%27)",
        "%20OR%20(Status%20%3D%20%27Voided%27)%20OR%20",
        "(Status%20%3D%20%27NotAvailable%27)%20OR%20",
        "(Status%20%3D%20%27Withdrawn%27)%20OR%20(Status%20IS%20NULL)&",
        "returnGeometry=false&spatialRel=esriSpatialRelIntersects&outFields=*&",
        "orderByFields=FinalDate%20DESC&resultOffset=", offset,
        "&resultRecordCount=25"
    )

    response <- httr::GET(url)

    if (status_code(response) == 200) {

        content <- httr::content(response, as = "text")
        l_response <- jsonlite::fromJSON(content, simplifyVector = TRUE)

        if (offset == 375) { 
            dt <- as.data.table(l_response$features)
        } else {
            dt <- rbind(dt, as.data.table(l_response$features))
        }
    }

    Sys.sleep(2)
}

# Cleaning up ----
names(dt) <- gsub("attributes.", "", names(dt))
dt[, final_date := as_datetime(FinalDate / 1000)]

# Save ----
saveRDS(dt, "derived/ChesterfieldCo/GIS Rezonings (2023.07.28).RDS")

# Testing ----
url <- "https://services3.arcgis.com/TsynfzBSE6sXfoLq/ArcGIS/rest/services/Planning/FeatureServer/22/query?f=json&where=(Status%20%3D%20%27Approved%27)%20OR%20(Status%20%3D%20%27Denied%27)%20OR%20(Status%20%3D%20%27Voided%27)%20OR%20(Status%20%3D%20%27NotAvailable%27)%20OR%20(Status%20%3D%20%27Withdrawn%27)%20OR%20(Status%20IS%20NULL)&returnGeometry=false&spatialRel=esriSpatialRelIntersects&outFields=*&orderByFields=FinalDate%20DESC&resultOffset=0&resultRecordCount=25"

response <- httr::GET(url)

if (status_code(response) == 200) {
    content <- httr::content(response, as = "text")
    l_response <- jsonlite::fromJSON(content, simplifyVector = TRUE)
    dt <- as.data.table(l_response$features)
}