# Import Zillow Home Value Index
# Downloaded on 4/6/2023 from
# https://www.zillow.com/research/data/

rm(list = ls())

library(data.table)
library(here)
library(readxl)

CONSTANT_YEAR <- 2015

# Import ----
dt <- fread("data/Housing Prices/Zillow Home Value Index.csv")

dt_cpi <- as.data.table(read_xlsx(
     "crosswalks/CPI/CUUR0000SA0 CPI-U (1995-2022).xlsx",
     skip = 10
))

# Clean ----
v_measure <- grep("-", names(dt), value = TRUE)

dt_l <- melt(dt, measure.vars = v_measure, variable.factor = FALSE,
             variable.name = "Date", value.name = "ZHVI")

dt_l[, FIPS := sprintf("%02d%03d", StateCodeFIPS, MunicipalCodeFIPS)]
dt_l[, Date := ymd(Date) + 1]

dt_l[, Year := year(Date)]

# Convert to 2015 dollars
dt_cpi[, Annual := Annual / dt_cpi[Year == CONSTANT_YEAR, Annual]]

dt_l <- merge(dt_l, dt_cpi[, .(Year, Annual)], by = "Year", all.x = TRUE)
dt_l[, ZHVI := ZHVI / Annual]

v_cols <- c("Date", "FIPS", "ZHVI")
dt_l <- dt_l[, ..v_cols]

saveRDS(dt_l, file = "derived/hpi-zillow.Rds")
