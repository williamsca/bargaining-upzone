# This script imports rezoning applications for a set
# of counties and cities in Virginia. It then standardizes
# the columns and exports a combined binary file for analysis.

# TODO
# Loudoun
# - check that 'isResi' classifications are accurate

# PWC

rm(list = ls())
library(data.table)
library(lubridate)
library(sf)
library(units)
library(here)

v_cols <- c(
    "FIPS", "Case.Number", "Part", "submit_date",
    "Project.Name", "Status", "Area", "Address", "Main.Parcel",
    "Description", "final_date", "isResi", "zoning_old",
    "zoning_new", "hasCashProffer", "isExempt",
    "Coordinates", "gis_object", "bos_votes_for", "bos_votes_against",
    "n_sfd", "n_sfa", "n_mfd", "n_unknown", "n_affordable",
    "n_age_restrict", "n_units"
)

dt_cw <- fread(here("crosswalks", "va-counties.csv"),
    keepLeadingZeros = TRUE)
dt_cw[, FIPS := paste0("51", FIPS)]

# Import ----
# Loudoun County
dt_loudoun <- readRDS(here("derived", "LoudounCo",
    "Rezoning GIS.Rds"))

dt_loudoun$geometry <- NULL

dt_loudoun[, isResi := grepl("R[0-9|C]|PDH|AAAR|MUB", zoning_new)]
table(dt_loudoun$zoning_new)
table(dt_loudoun[isResi == TRUE, zoning_new])


uniqueN(dt_loudoun[, .(Case.Number, Part)]) == nrow(dt_loudoun)
nrow(dt_loudoun[is.na(submit_date)]) == 0

# Prince William County
dt_pwc <- readRDS(here("derived", "PrinceWilliamCo",
    "Rezoning GIS.Rds"))

dt_pwc[, isResi := (Type != "Rezoning - Non-Residential")]
setnames(dt_pwc, c("OBJECTID"), c("gis_object"))

View(dt_pwc[isResi == TRUE & submit_date > ymd("2016-07-01") & Status == "Approved"])

uniqueN(dt_pwc[, .(Case.Number, gis_object, Part)]) == nrow(dt_pwc)
nrow(dt_pwc[is.na(submit_date)]) == 0

# Chesterfield County
dt_chesterfield <- readRDS(here("derived", "ChesterfieldCo",
    "GIS Rezonings (2023.07.28).RDS"))
dt_chesterfield_apps <- fread(here("data", "ChesterfieldCo",
    "Applications", "RecordList20230824.csv"), header = TRUE)

dt_chesterfield_apps <- unique(dt_chesterfield_apps)

dt_chesterfield <-
  merge(dt_chesterfield, dt_chesterfield_apps,
        by.x = c("CaseNum", "Status"),
        by.y = c("Record Number", "Status")
  )

dt_chesterfield[, Area := set_units(Acres, acres)]

dt_chesterfield[, FIPS := "51041"]

dt_chesterfield[, submit_date := mdy(Date)]

# TODO: assign Part := {1,2} based on Part column
dt_chesterfield[, nObs := .N, by = CaseNum]
dt_chesterfield <- dt_chesterfield[
    nObs == 1 | Part %in% c("1 OF 2", "Part 1")
]

# AC: amend prior case
# ZO: rezoning
# CU: conditional use permit
# ZOR: renew zoning approval
# PD: planned development?
dt_chesterfield <- dt_chesterfield[grepl("ZO", RequestType)]

dt_chesterfield[grepl("^[0-9]", `Project Name`), Address := `Project Name`]
dt_chesterfield[Status %in% c("Denied", "Withdrawn"),
    zoning_old := AppZoning]

dt_chesterfield[, isResi := grepl("R", AppZoning)]

setnames(
    dt_chesterfield,
    c("CaseNum", "Date", "AppZoning", "CaseDescription",
      "CashProffer", "CaseName"),
    c("Case.Number", "Applied.Date", "zoning_new",
      "Description", "hasCashProffer", "Project.Name")
)

uniqueN(dt_chesterfield$Case.Number) == nrow(dt_chesterfield)
nrow(dt_chesterfield[is.na(submit_date)]) == 0

# Fairfax County
sf_ff <- readRDS(here("derived", "FairfaxCo",
    "Rezoning GIS (2010-2020).Rds"))

sf_ff$Area <- set_units(st_area(sf_ff), acres)
sf_ff$FIPS <- "51059"

dt_ff <- as.data.table(sf_ff)
dt_ff <- dt_ff[!is.na(submit_date)]

dt_ff[is.na(`Exact Address`)]

setnames(dt_ff,
    c("ZONECODE", "Unique ID", "Exact Address",
      "OBJECTID.x"),
    c("zoning_new", "Case.Number", "Address",
      "gis_object"))

uniqueN(dt_ff[, .(Case.Number, gis_object)]) == nrow(dt_ff)
nrow(dt_ff[is.na(submit_date)]) == 0

# Frederick County
dt_fred <- fread(here("derived", "FrederickCo", "resolutions.csv"))

dt_fred[, `:=`(final_date = mdy(final_date),
               submit_date = mdy(submit_date))]

dt_fred[, FIPS := "51069"]
dt_fred[, Area := set_units(Acres, acres)]

dt_fred <- dt_fred[Type == "Rezoning"]

# Combine ----
dt <- rbindlist(list(
    dt_loudoun, dt_pwc, dt_chesterfield, dt_ff, dt_fred
), fill = TRUE, use.names = TRUE)

# Filter to standard columns
dt <- dt[, ..v_cols]

# Merge in county names + population
dt <- merge(dt, dt_cw, by = "FIPS", all.x = TRUE)

dt[, isApproved := grepl("Approved", Status)]

dt[, FY := year(submit_date) +
    fifelse(month(submit_date) >= 7, 1, 0)]

dt[is.na(isExempt), isExempt := FALSE]

# Sanity Checks & Coverage ----
nrow(dt[is.na(submit_date)]) == 0
uniqueN(dt[, .(Case.Number, gis_object, Part)]) == nrow(dt)

count_missing <- function(x) {
    if (class(x) %in% c("units", "Date")) {
        x <- as.numeric(x)
    }

    return((1 - sum(is.na(x) | x == "") / length(x)) * 100)
}

dt_missing <- dt[, lapply(.SD, count_missing), by = County]
dt_range <- dt[, .(`First Submit` = year(min(submit_date)),
                   `Last Submit` = year(max(submit_date))), by = County]
dt_missing <- merge(dt_missing, dt_range, by = "County")

dt_missing <- melt(dt_missing, id.vars = c("County"),
    value.name = "pct_populated")

dt_missing <- dcast(dt_missing, variable ~ County,
    value.var = "pct_populated")
View(dt_missing)

saveRDS(dt, here("derived", "county-rezonings.Rds"))
