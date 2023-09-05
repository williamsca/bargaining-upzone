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

dt <- dt[Type == "Zoning Map Amendment - ZCASE"] # exclude "Zoning Modification - ZCASE"

# See email 8/29/2023 from C. Brian Patrick
dt[, final_date := ZO_UPD_DAT]

setnames(dt, c("ZO_ZONE"), c("zoning_new"))

nrow(dt[final_date < submit_date]) == 0

dt[, Part := rowid(Case.Number)]

# Parse (Manually) ----
fwrite(
    dt[submit_date > ymd("2009-07-01"),
        .(Case.Number, Part, Description,
            zoning_old = "", zoning_new, acres = NA, n_unknown = NA,
            n_mfa = NA, n_sfa = NA, n_sfd, n_affordable = NA,
            n_age_restrict = NA
        )
    ],
    here("data", "LoudounCo", "missing-zoning-2009-2023.csv")
)

# <copy 'missing-zoning.csv' to ".../derived/PrinceWilliamCo">
# <manually add missing zoning codes>

dt_miss <- fread(here("derived", "LoudounCo", "missing-zoning-2009-2023.csv"))
dt_miss$Description <- NULL

dt <- merge(dt, dt_miss,
    by = c("Case.Number", "OBJECTID"),
    all.x = TRUE, all.y = TRUE
)

saveRDS(dt, here("derived", "LoudounCo",
                 "Rezoning GIS.Rds"))