# This script imports the CoreLogic property basic historical
# snapshots from 2012 through the present. The data are combined
# to create a panel of residential property and the associated zoning
# designation.

# Note: the intended use -- identifying upzoned parcels -- is not
# possible because the data do not include agricultural parcels.

rm(list = ls())
library(here)
library(data.table)
library(lubridate)
library(ggplot2)

# Import ----
# Not in historical data: "RESIDENTIAL MODEL INDICATOR"
cols_basic <- c(
    "CLIP", "PREVIOUS CLIP", "FIPS CODE",
    "TAXROLL CERTIFICATION DATE",
    # "LAST ASSESSOR UPDATE DATE",
    # "EFFECTIVE YEAR BUILT", "STORIES NUMBER",
    "NUMBER OF UNITS", "PROPERTY INDICATOR CODE",
    "BUILDING CODE", "LAND USE CODE",
    "TOTAL VALUE CALCULATED", "LAND VALUE CALCULATED"
)

l_files <- list.files(here("data", "core-logic"),
    pattern = "hist", full.names = TRUE, recursive = TRUE)

dt <- rbindlist(lapply(l_files, fread, select = cols_basic))

nrow(dt[!is.na(`PREVIOUS CLIP`)]) == 0
dt$`PREVIOUS CLIP` <- NULL

# Clean ----
dt <- dt[!is.na(CLIP) & !is.na(`TAXROLL CERTIFICATION DATE`)]
dt <- unique(dt)

v_by <- grep("VALUE", names(dt), value = TRUE, invert = TRUE)
dt <- dt[, .(tot_value = mean(`TOTAL VALUE CALCULATED`),
    tot_land = mean(`LAND VALUE CALCULATED`)),
    by = v_by]

setkey(dt, CLIP, `TAXROLL CERTIFICATION DATE`)

# Drop remaining duplicates (~10,000)
dt[, isDup := .N, by = .(CLIP, `TAXROLL CERTIFICATION DATE`)]
dt <- dt[isDup == 1]
dt$isDup <- NULL

uniqueN(dt[, .(CLIP, `TAXROLL CERTIFICATION DATE`)]) == nrow(dt)

ggplot(data = dt, aes(x = `TAXROLL CERTIFICATION DATE`)) +
    geom_histogram(binwidth = 30)

View(dt[`FIPS CODE` == "51049" &
    `TAXROLL CERTIFICATION DATE` %between% c(ymd("2013-01-01"),
        ymd("2014-01-01"))])

# Construct rezoning panel ----
table(dt$`LAND USE CODE`) # only residential codes

dt_county <- dt[!is.na(`LAND USE CODE`)]

# Exclude changes from 100 (Unclassified Residential)
dt_county[, isRezoned := (`LAND USE CODE` != shift(`LAND USE CODE`) &
    shift(`LAND USE CODE`) != 100), by = CLIP]

dt_county <- dt_county[, .(pctRezoned = 100 *
    sum(isRezoned, na.rm = TRUE) / .N, nParcels = .N),
by = .(Date = floor_date(`TAXROLL CERTIFICATION DATE`, unit = "month"),
    `FIPS CODE`)
]

setkey(dt_county, `FIPS CODE`, `TAXROLL CERTIFICATION DATE`)

dt_county[, n_yr_since_cert := (Date - shift(Date)) / 365, by = `FIPS CODE`]
dt_county[, pct_rezoned_per_yr := pctRezoned / as.numeric(n_yr_since_cert)]

dt_panel <- CJ(
    Date = seq.Date(
        from = min(dt_county$Date),
        to = max(dt_county$Date), by = "month"
    ),
    `FIPS CODE` = unique(dt_county$`FIPS CODE`)
)

dt_panel <- merge(dt_panel, dt_county, by = c("Date", "FIPS CODE"),
                  all.x = TRUE)

View(dt_panel[pct_rezoned_per_yr > 50])
summary(dt_panel$pct_rezoned_per_yr)
# TODO: figure out why n_yr_since_cert is sometimes negative

# Export ----
saveRDS(dt, here("derived", "parcel-zoning-panel.Rds"))
saveRDS(dt_panel, here("derived", "county-rezonings-panel-corelogic.Rds"))

uniqueN(dt_panel[, .(Date, `FIPS CODE`)]) == nrow(dt_panel)
