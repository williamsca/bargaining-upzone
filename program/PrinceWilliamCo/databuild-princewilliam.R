# This script combines rezoning application data and GIS data from
# Prince William County to create a panel dataset of rezonings

rm(list = ls())
library(here)
library(data.table)

# Import ----
dt_app <- readRDS(
  "derived\\PrinceWilliamCo\\Rezoning Applications (1958-2023).Rds)"
)
sf <- readRDS("derived/PrinceWilliamCo/Rezoning GIS.Rds")

dt_app <- dt_app[, .(Case.Number, Type, Status, Address, Main.Parcel,
                     isResi, isApproved, submit_date)]

# Merge ----
nrow(subset(sf, is.na(ZONECASE1)))
nrow(sf) 
uniqueN(sf$ZONECASE1)

tmp <- merge(sf, dt_app, by.x = "ZONECASE1", by.y = "Case.Number", all.x = TRUE)

tmp[is.na(Case.Number)]

head(dt_app)
