# This script imports Chesterfield GIS and rezoning application data
# It exports a list of residential rezonings for manual parsing
# using the zoning case materials available from the Chesterfield
# County archive.

rm(list = ls())
library(here)
library(data.table)
library(lubridate)
library(units)

v_cols <- c(
  "FIPS", "Case.Number", "Part", "submit_date",
  "Project.Name", "Status", "Area", "Address", "Main.Parcel",
  "Description", "final_date", "isResi", "zoning_old",
  "zoning_new", "hasCashProffer", "isExempt",
  "Coordinates", "gis_object", "bos_votes_for", "bos_votes_against",
  "n_sfd", "n_sfa", "n_mfd", "n_unknown", "n_affordable",
  "n_age_restrict", "n_units", "res_cash_proffer", "other_cash_proffer",
  "inkind_proffer", "planning_hearing_date"
)

# Import ----
# GIS
dt_gis <- readRDS(here("derived", "ChesterfieldCo",
    "GIS Rezonings (2023.07.28).RDS"))

# Applications (base data)
dt_app <- fread(here("data", "ChesterfieldCo", "Applications",
                     "RecordList20230824.csv"), header = TRUE)
dt_app[, submit_date := mdy(Date)]
dt_app <- unique(dt_app)

# BOS Minutes
dt_bos <- fread(here("derived", "ChesterfieldCo",
                       "bos-minutes-rezonings.csv"))

# Merge ----
dt <-
  merge(dt_app, dt_gis,
        by.x = c("Record Number", "Status"),
        by.y = c("CaseNum", "Status"),
        all.x = TRUE
  )

# Master only
nrow(dt[is.na(OBJECTID)]) / nrow(dt)

# BoS minutes (still a work in progress)
# TODO: extract details from Zoning Case information, not minutes
# https://documents.chesterfield.gov/Weblink_BOS/Welcome.aspx
uniqueN(dt_bos$Case.Number) == nrow(dt_bos)

dt <- merge(dt, dt_bos,
            by.x = c("Record Number"), by.y = c("Case.Number"),
            all.x = TRUE)

# Clean ----
dt[!is.na(n_unknown_pacre), n_unknown := n_unknown_pacre * Acres]
v_units <- c("n_sfd", "n_sfa", "n_mfd", "n_unknown", "n_age_restrict")

dt[, n_units := rowSums(.SD, na.rm = TRUE), .SDcols = v_units]
dt[n_units == 0, n_units := NA]
dt[!is.na(n_units), (v_units) := 0]
dt[!is.na(n_units), n_affordable := 0]
dt[is.na(res_cash_proffer), res_cash_proffer := 0] # this is not 100% true

dt[, Area := set_units(Acres, acres)]
dt[, FIPS := "51041"]
dt[, Part := NULL]

# AC: amend prior case
# ZO: rezoning
# CU: conditional use permit
# ZOR: renew zoning approval
# PD: planned development
# dt <- dt[grepl("ZOFinalDate", RequestType)]

dt[grepl("^[0-9]", `Project Name`), Address := `Project Name`]
dt[Status %in% c("Denied", "Withdrawn"),
    zoning_old := AppZoning]

dt[, isResi := grepl("R", AppZoning)]
dt[, isExempt := FALSE]

setnames(
    dt,
    c("Record Number", "AppZoning", "CaseDescription",
      "CashProffer", "CaseName", "OBJECTID"),
    c("Case.Number", "zoning_new",
      "Description", "hasCashProffer", "Project.Name", "gis_object")
)

v_final <- names(dt) %in% v_cols

dt <- dt[, ..v_final]

# Sanity Checks
nrow(dt[final_date < submit_date])
uniqueN(dt[, .(Case.Number, gis_object)]) == nrow(dt)

# Save ----
saveRDS(dt, here("derived", "ChesterfieldCo", "rezoning-applications.Rds"))
