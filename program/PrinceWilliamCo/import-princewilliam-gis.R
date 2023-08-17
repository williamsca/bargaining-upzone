# This script imports Prince William County's zoning layer from:
# https://gisdata-pwcgov.opendata.arcgis.com/datasets/PWCGOV::zoning/about

rm(list = ls())
pacman::p_load(here, data.table, sf, ggplot2)

# Import ----
sf <- st_read("data\\PrinceWilliamCo\\GIS\\Zoning\\Zoning.shp")

# Clean ----
sf$application_year <- as.numeric(substr(gsub("\\D", "", sf$ZONECASE1), 1, 4))
sf$application_num <- as.numeric(substring(gsub("\\D", "", sf$ZONECASE1), 5))

# Inspect ----

# TODO: email PWC to check this is the application year
ggplot(data = sf, aes(x = application_year)) +
    geom_bar() +
    scale_x_continuous(limits = c(2010, 2023)) +
    theme_light()

table(sf$ZONE_TYPE, sf$CLASS)

table(sf$PROFFERS)
table(sf$BUILT_OUT)



table(sf$FLEXIBLE_U) # flexible use, rarely populated

table(sf$ESTIMATED_) # unclear, rarely population

summary(sf$TOTAL_UNIT) # unclear what this is

summary(sf$SFD) # single-family dwelling
summary(sf$SFA) # single-family attached?
summary(sf$MFA) # multi-family attached?


