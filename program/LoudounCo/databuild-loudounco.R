# This script merges the Loudoun GIS rezoning data
# (which includes the 'isExempt' tag) with the
# full list of rezoning applications.

# See the Loudoun 1993 Zoning Ordinance for classification details:
# https://www.loudoun.gov/zoningordinance

rm(list = ls())
library(here)
library(data.table)
library(sf)
library(units)
library(stringr)

# Import ----
sf <- readRDS(here("derived", "LoudounCo",
                   "Zoning GIS.Rds"))

sf$Area <- set_units(st_area(sf), acres)

dt <- readRDS(here("derived", "LoudounCo", "Rezoning Applications.Rds"))

# Merge ----
dt <- merge(dt, sf, by.x = "Case.Number", by.y = "ZO_PROJ_NU",
    all.x = TRUE)

# (exclude "Zoning Modification - ZCASE")
dt <- dt[Type == "Zoning Map Amendment - ZCASE"]

# Every merged record is for an approved application
nrow(dt[!is.na(Area) & Status != "Approved"]) == 0

# See email 8/29/2023 (C. Brian Patrick)
# Note: only approved applications have a final_date
dt[, final_date := ZO_UPD_DAT]

# A few records have a final date before the submit date
nrow(dt[final_date < submit_date])

setnames(dt, c("ZO_ZONE"), c("zoning_new"))

dt[, Part := rowid(Case.Number)]

# Parse (Manually) ----
if (!file.exists(here("data", "LoudounCo", "missing-zoning-2009-2023.csv"))) {
    fwrite(
        dt[
            submit_date > ymd("2009-07-01"),
            .(Case.Number, Part, Description,
                zoning_old = "", zoning_new, acres = NA, n_unknown = NA,
                n_mfa = NA, n_sfa = NA, n_sfd, n_affordable = NA,
                n_age_restrict = NA
            )
        ],
        here("data", "LoudounCo", "missing-zoning-2009-2023.csv")
    )
}

# <copy 'missing-zoning.csv' to ".../derived/PrinceWilliamCo">
# <manually add missing zoning codes>

dt_miss <- fread(here("derived", "LoudounCo", "missing-zoning-2009-2023.csv"))
dt_miss$Description <- NULL

dt <- merge(dt, dt_miss,
    by = c("Case.Number", "Part"),
    all.x = TRUE, all.y = TRUE
)

uniqueN(dt[, .(Case.Number, Part)]) == nrow(dt)

# Clean ----
dt[is.na(Area), Area := set_units(acres, acres)]
dt[, zoning_new := fifelse(is.na(zoning_new.x), zoning_new.y, zoning_new.x)]

# Standardize zoning codes
dt[, zoning_new := toupper(gsub("-", "", zoning_new))]
dt[, zoning_old := toupper(gsub("-", "", zoning_old))]

v_codes_old <- unique(str_split_1(paste0(unique(dt$zoning_old),
    collapse = ", "
), ", "))
v_codes_new <- unique(str_split_1(paste0(unique(dt$zoning_new),
    collapse = ", "
), ", "))

dt[, isResi := grepl("R[0-9|C]|PDH|AAAR|MUB", zoning_new)]

# Save ----
saveRDS(dt, here("derived", "LoudounCo",
                 "Rezoning GIS.Rds"))