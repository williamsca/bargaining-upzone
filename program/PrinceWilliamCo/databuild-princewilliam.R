# This script combines rezoning application data and GIS data from
# Prince William County to create a panel dataset of rezonings.

# Merge Applications and GIS Data:
# 1. Construct a crosswalk between the GIS OBJECTID and the Main.Parcel
# identifier: Merge the application case data to the GIS data,
# which incicates the most recent zoning case relevant to the parcel,
# using the Zoning Case Number.
# 2. Use the crosswalk to merge the GIS data to the application data.

# Parse the 'Description': determine acres, old and new zoning codes

# Compare 'Description' info with GIS record as a sanity check

rm(list = ls())
library(here)
library(data.table)
library(stringr)
library(units)

# Import ----
dt_app <- readRDS(here("derived", "PrinceWilliamCo",
  "Rezoning Applications.Rds"))

dt_gis <- as.data.table(readRDS(here("derived", "PrinceWilliamCo",
  "Rezoning GIS.Rds")))

nrow(dt_gis[is.na(ACREAGE)]) == 0
uniqueN(dt_gis$OBJECTID) == nrow(dt_gis)

# Clean ----
# Strip quotes from application data
v_cols <- c("Case.Number", "Status", "Main.Parcel", "Type", "Address",
  "Description")
dt_app[, (v_cols) := lapply(.SD, function(x) gsub("\"", "", x)),
  .SDcols = v_cols]

# Filter to rezonings
# (exclude comp. plan amendments, proffer interpretations,
# minor modifications, etc.)
dt_app <- dt_app[
  Type %in% c(
    "Rezoning - Mixed Use",
    "Rezoning - Non-Residential",
    "Rezoning - Residential"
  )
]

dt_app[, Description := str_to_upper(Description)]

# Merge ----
dt_case <- merge(dt_app, dt_gis, by.x = "Case.Number",
  by.y = "ZONECASE1", all.x = TRUE)

# Object to Parcel Crosswalk (1:m)
dt_parcel <- dt_case[!is.na(OBJECTID), .(Main.Parcel, OBJECTID)]
uniqueN(dt_parcel$OBJECTID) == nrow(dt_parcel)

# Merge in OBJECTID to applications
dt_app <- merge(dt_app, dt_parcel, by = "Main.Parcel", all.x = TRUE)

dt <- merge(dt_app, dt_gis, by = "OBJECTID", all.x = TRUE)

uniqueN(dt[, .(OBJECTID, Case.Number)]) == nrow(dt)

# Parse ----
# Area
pattern <- "(?<=^|[^0-9.])([0-9.]+)(?:-?\\s*(AC|ACRE)S?\\b)"
dt[, acres := str_extract(Description, pattern)]
dt[, acres := as.numeric(gsub("[^0-9.]", "", acres))]

# Former zoning
pattern <- "(?i)FROM\\s+([\\w()]+(?:-[\\w()]+)?)"
dt[, zoning_old := str_extract(Description, pattern)]
dt[, zoning_old := gsub("FROM ", "", zoning_old)]

dt[zoning_old %in% c("A1", "AGRICULTURAL", "A-1(AGRICULTURAL)"),
  zoning_old := "A-1"]
dt[zoning_old == "(O)M", zoning_old := "O(M)"]

# New zoning
pattern <- "(?i)TO\\s+(\\w+(?:-\\w+)?)"
dt[, zoning_new := str_extract(Description, pattern)]
dt[, zoning_new := gsub("TO ", "", zoning_new)]

# TODO: check out non-standard zoning_new
table(dt$zoning_new)
table(dt_gis$CLASS)

# Manual
dt[startsWith(Description, "RIVERSIDE STATION LAND BAY A"), `:=`(
  zoning_old = "B-1",
  zoning_new = "PMD",
  acres = 6.3
)]

dt[startsWith(Description, "RIVERSIDE STATION LAND BAY B"), `:=`(
  zoning_old = "B-1",
  zoning_new = "PMD",
  acres = 12.95
)]

dt[startsWith(Description, "PALMAS GARDEN CENTER"), `:=`(
  zoning_old = "R-4",
  zoning_new = "B-1"
)]

dt[startsWith(Description, "REPUBLIC SERVICES MANASSAS FACILITIES"),
  `:=`(zoning_old = "M-1", zoning_new = "M/T")]

dt[startsWith(Description, "REZ - ORCHARD GLEN REZONING"),
  `:=`(zoning_old = "O(L)", zoning_new = "O(F)")]

dt[startsWith(Description, "REZ, FROM A1-M-1"), `:=`(
  zoning_old = "A-1",
  zoning_new = "M-1"
)]

# This case affects two parcels with different initial zoning
dt[, Part := 1]
tmp <- dt[Case.Number == "PLN2014-00190"]
tmp <- rbindlist(list(tmp, tmp))
tmp[1, `:=`(zoning_old = "PBD", acres = 74.35, Part = 1)]
tmp[2, `:=`(zoning_old = "A-1", acres = 53.91, Part = 2)]
tmp[, zoning_new := "PMR"]
dt <- rbindlist(list(dt[Case.Number != "PLN2014-00190"], tmp))

dt[zoning_old == "FIRE", `:=`(zoning_old = NA, zoning_new = NA)]

fwrite(dt[is.na(zoning_old),
         .(Case.Number, OBJECTID, Description, zoning_old, zoning_new, acres)],
  here("data", "PrinceWilliamCo", "missing-zoning.csv"))

# <manually add missing zoning codes>

dt_miss <- fread(here("derived", "PrinceWilliamCo", "missing-zoning.csv"))
dt_miss$Description <- NULL

dt <- merge(dt, dt_miss, by = c("Case.Number", "OBJECTID"),
  all.x = TRUE, all.y = TRUE)

dt[, zoning_old := fcoalesce(zoning_old.x, zoning_old.y)]
dt[, zoning_new := fcoalesce(zoning_new.x, zoning_new.y)]
dt[, acres := fcoalesce(acres.x, acres.y)]

dt[zoning_new == "" & !is.na(CLASS), zoning_new := CLASS]

# Sanity Checks ----
v_codes <- c(unique(dt$CLASS), "", "SRR-1")

v_codes_old <- str_split_1(paste0(unique(dt$zoning_old),
  collapse = ", "), ", ")
all(v_codes_old %in% v_codes)

v_codes_new <- str_split_1(paste0(unique(dt$zoning_new),
  collapse = ", "), ", ")
all(v_codes_new %in% v_codes)

View(dt[zoning_new != CLASS & ZONECASE1 == Case.Number])

# Export ----
dt[, Area := set_units(acres, "acres")]