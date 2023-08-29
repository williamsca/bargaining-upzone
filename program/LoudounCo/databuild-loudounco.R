# This script merges the Loudoun GIS rezoning data
# (which includes the 'isExempt' tag) with the
# full list of rezoning applications.

rm(list = ls())
library(here)
library(data.table)
library(sf)
library(units)

# Import ----
sf <- readRDS(here("derived", "LoudounCo",
                   "Zoning GIS.Rds"))

sf$Area <- set_units(st_area(sf), acres)

dt <- readRDS(here("derived", "LoudounCo", "Rezoning Applications.Rds"))

# Merge ----
dt <- merge(dt, sf, by.x = "Case.Number", by.y = "ZO_PROJ_NU",
    all.x = TRUE)

# See email 8/29/2023 from C. Brian Patrick
dt[, final_date := ZO_UPD_DAT]

setnames(dt, c("ZO_ZONE"), c("zoning_new"))

nrow(dt[final_date < submit_date]) == 0

dt[, Part := rowid(Case.Number)]

saveRDS(dt, here("derived", "LoudounCo",
                 "Rezoning GIS.Rds"))