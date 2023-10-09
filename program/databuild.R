# Analysis of cash proffer eligibility on building permits
# Author: Colin Williams
# Updated: 10 July 2023

rm(list = ls())

library(data.table)
library(here)
library(lubridate)

CONSTANT_YEAR <- 2015

# Import ----
dt_bp <- readRDS(
    "derived/County Residential Building Permits by Month (2000-2021).Rds"
)
dt_hpi <- readRDS("derived/hpi-zillow.Rds")
dt_hpi_rs <- readRDS("derived/hpi-boginetal.Rds")
dt_rev <- readRDS("derived/county-revenues-2004-2022.Rds")
dt_pop <- readRDS("derived/county-populations-2010.Rds")
dt_rezon <- readRDS("derived/county-rezonings-panel.Rds")
dt_wrluri <- readRDS("derived/county-wrluri.Rds")

# Building Permits ----
# Bedford City became a town on July 1, 2013.
# https://en.wikipedia.org/wiki/Bedford,_Virginia
dt_bp[Name == "Bedford (Independent City)",
    `:=`(Name = "Bedford County", FIPS.Code.County = "019")
]

# Clifton Forge became a town in 2001.
# https://en.wikipedia.org/wiki/Clifton_Forge,_Virginia
dt_bp[Name == "Clifton Forge (Independent Cit",
    `:=`(Name = "Alleghany County", FIPS.Code.County = "005")
]

v.cols <- grep("(Bldgs|Value|Units)", names(dt_bp), value = TRUE)
v.cols <- grep("rep", v.cols, value =  TRUE, invert = TRUE)

# Combine Clifton Forge and Bedford with the surrounding county.
dt_bp <- dt_bp[, lapply(.SD, sum),
    by = .(Year4, Month, FIPS.Code.State, FIPS.Code.County, Name),
    .SDcols = v.cols
]

dt_bp[, Name := gsub("\\s*\\(.*", " City", Name)]

# The VA fiscal year runs from July 1 to June 30
dt_bp[, FY := Year4 + fifelse(Month >= 7, 1, 0)]

# Note: some proffer-collecting jurisdictions are not
# covered in the county building permits survey
dt <- merge(dt_bp, dt_rev,
    by = c("Name", "FY", "FIPS.Code.State"),
    all.x = TRUE
)

dt[, Date := make_date(year = Year4, month = Month)]
dt[, FIPS := paste0(FIPS.Code.State, FIPS.Code.County)]

dt <- merge(dt, dt_hpi, by = c("Date", "FIPS"), all.x = TRUE)
dt <- merge(dt, dt_hpi_rs, by = c("Year", "FIPS"), all.x = TRUE)

dt <- merge(dt, dt_pop, by = c("FIPS"), all.x = TRUE)

dt <- merge(dt, dt_rezon, by.x = c("FIPS", "Date"),
            by.y = c("FIPS", "date"), all.x = TRUE)

# Note: many WRLURI counties are not covered in the building permits survey
dt <- merge(dt, dt_wrluri, by = c("FIPS"), all.x = TRUE)

# Sample is mostly EI=1 counties
# Will need to do balance tests
table(unique(dt[, .(FIPS, EI)])$EI)

# Filter ----
# exclude Alaska and Hawaii
dt <- dt[!(FIPS.Code.State %in% c("02", "15"))]

v_cols <- c("FIPS", "Date", "FY", "Name", "FIPS.Code.State",
    "PCT001001", "rev_cp",
    "rev_loc", "rev_tot", "Units1", "Units2", "Units3-4", "Units5+",
    "ZHVI", "ZHVI_SFD", "n_units", "Area", "EI")
dt <- dt[, ..v_cols]

# drop 24 duplicate entries
dt <- unique(dt, by = c("FIPS", "Date", "Units1"))

# exclude "Balance of State" entries from the BPS
dt <- dt[!is.na(PCT001001)]

# Sanity Checks ----
nrow(dt) == uniqueN(dt[, .(Date, FIPS)])

saveRDS(dt, here("derived", "sample.Rds"))
