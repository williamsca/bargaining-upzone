# This script estimates DiD models for the Koontz decision

rm(list = ls())

library(data.table)
library(stargazer)
library(fixest)
library(ggplot2)
library(devtools)
library(lubridate)
library(here)

dt <- readRDS("derived/sample.Rds")
dt <- dt[!is.na(EI)]

# Koontz v. St. Johns River Water Management District (2013)
# Case decided on June 25, 2013
# Total units in multi-family buildings
dt[, Units2p := Units2 + `Units3-4` + `Units5+`]
dt[, Post := fifelse(Date >= ymd("2013-07-01"), 1, 0)]

dt_qtr <- dt[, .(
    Units1 = sum(Units1), Units2p = sum(Units2p),
    ZHVI = mean(ZHVI), n_units = sum(n_units)
),
by = .(FIPS, PCT001001, State = FIPS.Code.State,
    Date = quarter(Date, type = "date_first"), rev_cp,
    EI, Post, FY
)
]

nrow(dt_qtr[Units1 == 0]) / nrow(dt_qtr)

RHS_ES <- paste0(
    " ~ -1 + i(Date, EI, ref = I(ymd(\"2013-04-01\")))",
    # " + State:as.numeric(Date)",
    " | Date + FIPS"
)
fmla.es <- as.formula(paste0("log(Units1)", RHS_ES))

# Event Studies ----
# Housing Permits
feols.es <- feols(fmla.es,
    cluster = "as.factor(FIPS)",
    data = dt_qtr[year(Date) %between% c(2008, 2020)]
)
iplot(feols.es,
    lab.fit = "simple",
    value.lab = "", main = "Effect on single-family housing permits"
)

# Prices
fmla_zhvi <- as.formula(paste0("log(ZHVI)", RHS_ES))
feols_zhvi <- feols(fmla_zhvi,
    cluster = "as.factor(FIPS)",
    data = dt_qtr[year(Date) %between% c(2009, 2019)]
)
iplot(feols_zhvi,
    lab.fit = "simple",
    value.lab = "", main = "Effect on single-family housing permits"
)

# TODO: Revenues
# (can be done by jurisdiction, no need to aggregate to county)
