# This file cleans the hand-parsed Frederick County Rezoning Resolutions

rm(list = ls())

library(data.table)
library(here)
library(lubridate)
library(units)

# Import ----
dt <- fread(here("derived", "FrederickCo", "resolutions.csv"))

# Note: the 'isResi' tag indicates the proposed use, so it can be FALSE
# even when 'zoning_new' allows residential uses.

# Clean ----
dt[, `:=`(
    final_date = mdy(final_date),
    submit_date = mdy(submit_date)
)]

dt[, FIPS := "51069"]
dt[, Area := set_units(Acres, acres)]

dt <- dt[Type == "Rezoning"]

# Impute the change in allowed units
if (!file.exists(here("data", "FrederickCo", "zoning-densities.csv"))) {
    dt_zon <- data.table(
        zoning = unique(c(dt$zoning_new, dt$zoning_old)),
        density_per_acre = NA_real_
    )
    fwrite(dt_zon, here("data", "FrederickCo", "zoning-densities.csv"))
}

# <copy ".../zoning-densities.csv" to "derived/FrederickCo/zoning-densities.csv">
# <add densities from https://ecode360.com/8707728>
# Note: the 'RP' code allowed density varies by lot size and the specific
# type of housing. Current value is for garden apartments and townhouses;
# multifamily and age-restricted can go higher.

dt_zon <- fread(here("derived", "FrederickCo", "zoning-densities.csv"))

dt <- merge(dt, dt_zon, by.x = "zoning_old", by.y = "zoning", all.x = TRUE)
dt[, old_units := Acres * density_per_acre]
dt$density_per_acre <- NULL
dt <- merge(dt, dt_zon, by.x = "zoning_new", by.y = "zoning", all.x = TRUE)
dt[, new_units := Acres * density_per_acre]
dt[, n_unknown := new_units - old_units]
dt[, n_units := n_unknown]

# Save ----
saveRDS(dt, here("derived", "FrederickCo", "rezoning-applications.Rds"))
