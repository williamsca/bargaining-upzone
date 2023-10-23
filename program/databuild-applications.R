# This script imports rezoning applications for a set
# of counties and cities in Virginia. It then standardizes
# the columns and exports a combined binary file for analysis.

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
    "n_age_restrict", "n_units", "res_cash_proffer", "other_cash_proffer",
    "inkind_proffer", "planning_hearing_date"
)

dt_cw <- fread(here("crosswalks", "va-counties.csv"),
    keepLeadingZeros = TRUE)
dt_cw[, FIPS := paste0("51", sprintf("%03d", FIPS))]
dt_cw[, `:=`(first_final = mdy(first_obs), last_final = mdy(last_obs))]
dt_cw[, c("first_obs", "last_obs") := NULL]

# Import ----
# Spotsylvania County
dt_spot <- readRDS(here("derived", "SpotsylvaniaCo",
    "Rezoning Approvals.Rds"))

# Hanover County
dt_han <- readRDS(here("derived", "HanoverCo", "Rezoning Approvals.Rds"))

uniqueN(dt_han[, .(Case.Number, Part)]) == nrow(dt_han)

# Goochland County
dt_gooch <- readRDS(here("derived", "GoochlandCo",
    "Rezoning Approvals.Rds"))

# Assume planning hearing is close enough to the submission date
# dt_gooch[, submit_date := planning_hearing_date]

uniqueN(dt_gooch$Case.Number) == nrow(dt_gooch)

# Loudoun County
dt_loudoun <- readRDS(here("derived", "LoudounCo",
    "Rezoning GIS.Rds"))

dt_loudoun$geometry <- NULL

uniqueN(dt_loudoun[, .(Case.Number, Part)]) == nrow(dt_loudoun)
nrow(dt_loudoun[is.na(submit_date)]) == 0

# Prince William County
dt_pwc <- readRDS(here("derived", "PrinceWilliamCo",
    "Rezoning GIS.Rds"))

dt_pwc[, isResi := (Type != "Rezoning - Non-Residential")]
setnames(dt_pwc, c("OBJECTID"), c("gis_object"))

uniqueN(dt_pwc[, .(Case.Number, gis_object, Part)]) == nrow(dt_pwc)
nrow(dt_pwc[is.na(submit_date)]) == 0

# Chesterfield County
dt_chesterfield <- readRDS(here("derived", "ChesterfieldCo",
    "rezoning-applications.Rds"))

uniqueN(dt_chesterfield[, .(Case.Number, gis_object)]) == nrow(dt_chesterfield)
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
dt_fred <- readRDS(here("derived", "FrederickCo", "rezoning-applications.Rds"))

# Combine ----
dt <- rbindlist(list(
    dt_loudoun, dt_pwc, dt_chesterfield, dt_ff, dt_fred, dt_gooch,
    dt_han, dt_spot
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

sum(unique(dt[, .(County, Population2022)]$Population2022)) / 8683619

nrow(dt[n_units != n_sfd + n_sfa + n_mfd + n_unknown + n_age_restrict]) == 0

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

# Save Applications ----

saveRDS(dt, here("derived", "county-rezonings.Rds"))

# Create Monthly Panel ----
# TODO: bring in average proffer rate
min_date <- ymd("2010-01-01")
max_date <- ymd("2020-06-30")

dt_res <- dt[isApproved == TRUE & isResi == TRUE]
dt_res[, `:=`(first_submit = min(submit_date), last_submit = max(submit_date)),
    by = FIPS
]
dt_res[is.na(first_final), `:=`(first_final = min(final_date),
    last_final = max(final_date)), by = FIPS]

dt_panel <- CJ(
    County = unique(dt_res$County),
    date = seq(min_date, max_date, by = "month")
)

dt_interval <- unique(dt_res[, .(
    FIPS, County, first_submit, last_submit,
    first_final, last_final, Population2022
)])
v_intervals <- c("first_final", "last_final", "first_submit", "last_submit")
dt_interval[, (v_intervals) := lapply(.SD, floor_date, "month"),
    .SDcols = v_intervals
]

dt_panel <- merge(dt_panel, dt_interval, by = c("County"), all.x = TRUE)

dt_submit <- dt_res[, .(Area = sum(Area), n_units = sum(n_units),
                        n_sfd = sum(n_sfd),
                        n_other = sum(n_sfa + n_mfd + n_unknown)),
    by = .(FIPS, date = floor_date(submit_date, "month"))
]
dt_submit <- merge(dt_panel, dt_submit,
    by = c("FIPS", "date"),
    all.x = TRUE
)
dt_submit$type <- "submit"
dt_submit <- dt_submit[!is.na(first_submit)]
dt_submit <- dt_submit[date >= first_submit & date <= last_submit]

# TODO: impute 0s for missing 'n_units' and 'Area' when those values are
# observed in any year for that county

dt_final <- dt_res[, .(Area = sum(Area), n_units = sum(n_units),
                       n_sfd = sum(n_sfd),
                       n_other = sum(n_sfa + n_mfd + n_unknown)),
    by = .(FIPS, date = floor_date(final_date, "month"))
]
dt_final <- merge(dt_panel, dt_final,
    by = c("FIPS", "date"),
    all.x = TRUE
)
dt_final$type <- "final"
dt_final <- dt_final[!is.na(first_final)]
dt_final <- dt_final[date >= first_final & date <= last_final]

dt_panel <- rbindlist(list(dt_submit, dt_final),
    fill = TRUE,
    use.names = TRUE
)

# TODO: fix this so that the panel has 0s and NAs as appropriate
dt_panel[, has_units := any(!is.na(n_units)), by = FIPS]
dt_panel[is.na(n_units) & has_units, n_units := 0]
dt_panel[is.na(n_sfd) & has_units, n_sfd := 0]
dt_panel[is.na(n_other) & has_units, n_other := 0]

dt_panel[, has_area := any(!is.na(Area)), by = FIPS]
dt_panel[is.na(Area) & has_area, Area := 0]

# Save Panel ----
saveRDS(dt_panel, here("derived", "county-rezonings-panel.Rds"))

