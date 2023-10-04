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
library(sf)
library(stringr)
library(units)

# Import ----
dt_app <- readRDS(here("derived", "PrinceWilliamCo",
  "Rezoning Applications.Rds"))

dt_gis <- as.data.table(st_read(here(
  "data", "PrinceWilliamCo", "GIS",
  "Zoning", "Zoning.shp"
)))

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

# Parse (Manually) ----

fwrite(
  dt[,
    .(Case.Number, OBJECTID, Description, zoning_old = "",
      zoning_new = "", acres = NA, n_units = NA)
  ],
  here("data", "PrinceWilliamCo", "missing-zoning.csv")
)

# <copy 'missing-zoning.csv' to ".../derived/PrinceWilliamCo">
# <manually add missing zoning codes>

dt_miss <- fread(here("derived", "PrinceWilliamCo", "missing-zoning.csv"))
dt_miss$Description <- NULL

dt <- merge(dt, dt_miss,
  by = c("Case.Number", "OBJECTID"),
  all.x = TRUE, all.y = TRUE
)

# Note: 'n_affordable' overlaps with other categories
# Note: need to distinguish between '0' (no change in units) and NA
# (unknown change, might impute based on zoning code change)
v_units <- grep("n_", names(dt), value = TRUE)
dt[, (v_units) := lapply(.SD, function(x) fifelse(is.na(x), 0, x)),
  .SDcols = v_units]

dt[, n_units := rowSums(.SD), .SDcols = c(
  "n_sfd", "n_sfa", "n_mfd", "n_unknown", "n_age_restrict"
)]

dt[is.na(Part), Part := 1]
dt[, Area := set_units(as.numeric(acres), "acres")]

# The 'Description' indicates that these applications are
# "NOT SUBJECT TO SB549"
dt[Case.Number == "REZ2017-00013", submit_date := ymd("2016-06-30")]
dt[Case.Number == "REZ2017-00011", submit_date := ymd("2016-06-29")]

# Sanity Checks ----
v_codes <- c(unique(dt_gis$CLASS), "", "PMR-HIGH")

v_codes_old <- unique(str_split_1(paste0(unique(dt$zoning_old),
  collapse = ", "), ", "))
all(v_codes_old %in% v_codes)

v_codes_new <- unique(str_split_1(paste0(unique(dt$zoning_new),
  collapse = ", "), ", "))
all(v_codes_new %in% v_codes)

nrow(dt[n_units < n_affordable]) == 0

# TODO: check acres, zoning_new, etc.
View(dt[zoning_new != CLASS & ZONECASE1 == Case.Number])

# Export ----
saveRDS(dt, here("derived", "PrinceWilliamCo", "Rezoning GIS.Rds"))
