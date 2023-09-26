# This script imports the Wharton Land Use Regulatory Index
# and aggregates it to the county level.

# WRLURI downloaded on 9/26/2023 from:
# https://real-faculty.wharton.upenn.edu/gyourko/land-use-survey/

rm(list = ls())
library(here)
library(data.table)
library(haven)
library(readxl)

# Import ----
# WRLURI
dt18 <- as.data.table(read_dta(here("data", "WRLURI",
    "WRLURI_01_15_2020.dta")))

dt06 <- as.data.table(read_dta(here("data", "WRLURI",
    "WHARTON LAND REGULATION DATA_1_24_2008.dta")))

# Place/County Subdivision to County Crosswalks
s_places <- paste0("https://www2.census.gov/geo/docs/reference",
                   "/codes2020/national_place_by_county2020.txt")
dt_places <- fread(s_places)
dt_places[, ufips := sprintf("%05d", PLACEFP)]

uniqueN(dt_places[, .(STATEFP, ufips, COUNTYFP)]) == nrow(dt_places)

s_subdiv <- paste0("https://www2.census.gov/geo/docs/reference",
                   "/codes2020/national_cousub2020.txt")
dt_subdiv <- fread(s_subdiv)
dt_subdiv[, ufips := sprintf("%05d", COUSUBFP)]

uniqueN(dt_subdiv[, .(STATEFP, ufips, COUNTYFP)]) == nrow(dt_subdiv)

dt_cw <- rbindlist(list(dt_places, dt_subdiv), use.names = TRUE, fill = TRUE)
dt_cw <- unique(dt_cw[, .(STATE, STATEFP, COUNTYFP, COUNTYNAME, ufips)])

uniqueN(dt_cw[, .(STATEFP, ufips, COUNTYFP)]) == nrow(dt_cw)
dt_cw[, n_counties := .N, by = .(STATEFP, ufips)]

# Merge ----
dt <- dt06[, .(
    EI, WRLURI, weight, weight_metro, id, name,
    type, ufips, statename
)]
dt[, ufips := sprintf("%05d", ufips)]

dt <- merge(dt, dt_cw, by.x = c("ufips", "statename"),
    by.y = c("ufips", "STATE"), all.x = TRUE)

# Note: a handful of WRLURI observations are not matched to any county
# Ignore for now, but come back and fix!
nrow(dt[is.na(COUNTYFP)])
dt <- dt[!is.na(COUNTYFP)]

# Aggregate ----
dt <- dt[, .(EI = max(EI)), by = .(COUNTYFP, STATEFP, COUNTYNAME,
    STATENAME = statename)]

dt[, FIPS := paste0(sprintf("%02d", STATEFP), sprintf("%03d", COUNTYFP))]

nrow(dt) == uniqueN(dt$FIPS)

# Save ----
saveRDS(dt, here("derived", "county-wrluri.Rds"))
