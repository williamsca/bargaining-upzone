# This script constructs two datasets:
# 1. Areas of the county which were exempt from the
#    2016 Proffer Reform Act (PRA16)
# 2. Rezoning applications with a flag that indicates whether
#    the application was subject to PRA16.

# It depends on the file:
# 'program/import/Import FairfaxCo Rezonings (2023.07.20).R' # nolint

rm(list = ls())
pacman::p_load(here, data.table, sf, lubridate, lwgeom, dplyr)

# Import ----
sf_ff_rezone <- readRDS(
    "derived/FairfaxCo/Rezoning Applications (2010-2020).Rds"
)
sf_ff_exempt <- st_read(dsn = paste0(
    "data/FairfaxCo/GIS/Comprehensive_Plan_Land_Units/",
    "Comprehensive_Plan_Land_Units.shp"
))
sf_reston_tysons <- readRDS(
    "derived/FairfaxCo/Reston and Tysons SF.Rds")


# Exempt Areas ----
# TODO: filter sf_ff_exempt to include only exempt areas (see 'Maps (2023.08.04).R')
names(sf_ff_exempt)[names(sf_ff_exempt) == "PRIMARY_PL"] <- "LABEL"
names(sf_ff_exempt)[names(sf_ff_exempt) == "SHAPE_Leng"] <-
 "SHAPE_Length"
sf_exempt <- subset(sf_ff_exempt, select = names(sf_reston_tysons))

sf_reston_tysons$geometry <- st_cast(sf_reston_tysons$geometry,
    "MULTIPOLYGON")

sf_exempt <- rbind(sf_exempt, sf_reston_tysons)

# Spatial Join ----
sf_exempt <- st_make_valid(sf_exempt)
sf_ff_rezone <- st_make_valid(sf_ff_rezone)

sf <- st_join(sf_ff_rezone, sf_exempt, join = st_intersects)

# TRUE and FALSE --> left join
nrow(subset(sf, is.na(OBJECTID.x))) == 0
nrow(subset(sf, is.na(OBJECTID.y))) == 0

sf$isExempt <- (!is.na(sf$OBJECTID.y) | !sf$isResi)

sf <- subset(sf, select = c("OBJECTID.x", "STATUS", "ZONECODE",
    "PROFFER", "ZONETYPE", "PUBLIC_LAN", "Unique ID",
    "Shape__Are", "Shape__Len", "Status", "submit_date",
    "submit_month", "isOriginal", "Exact Address", "Coordinates",
    "isResi", "isExempt", "geometry"))
sf <- unique(sf)

# TRUE --> all rezonings either exempt or not
nrow(sf) == nrow(sf_ff_rezone)

saveRDS(sf, paste0("derived/FairfaxCo/Rezoning GIS (",
    paste(range(year(sf$submit_date), na.rm = TRUE), collapse = "-"),
    ").Rds"))

