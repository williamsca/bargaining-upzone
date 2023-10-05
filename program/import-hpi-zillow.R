# Import Zillow Home Value Index
# Downloaded on 4/6/2023 from
# https://www.zillow.com/research/data/

rm(list = ls())

library(data.table)
library(here)
library(lubridate)
library(readxl)

CONSTANT_YEAR <- 2015

# Import ----
dt <- fread(here("data", "housing-prices", "zillow", "zhvi.csv"))
dt_sfd <- fread(here("data", "housing-prices", "zillow", "zhvi-sfd.csv"))

dt_cpi <- as.data.table(read_xlsx(
     "crosswalks/CPI/CUUR0000SA0 CPI-U (1995-2022).xlsx",
     skip = 10
))

nrow(dt) == uniqueN(dt[, .(StateCodeFIPS, MunicipalCodeFIPS)])
nrow(dt_sfd) == uniqueN(dt_sfd[, .(StateCodeFIPS, MunicipalCodeFIPS)])

# Clean ----
## ZHVI
v_measure <- grep("-", names(dt), value = TRUE)

dt_l <- melt(dt, measure.vars = v_measure, variable.factor = FALSE,
             variable.name = "Date", value.name = "ZHVI")

## ZHVI SFD
v_measure <- grep("-", names(dt_sfd), value = TRUE)

dt_sfd_l <- melt(dt_sfd,
     measure.vars = v_measure, variable.factor = FALSE,
     variable.name = "Date", value.name = "ZHVI_SFD"
)

dt_l <- merge(dt_l, dt_sfd_l,
              by = c("StateCodeFIPS", "MunicipalCodeFIPS", "Date"),
              all.x = TRUE)

dt_l[xor(is.na(ZHVI_SFD), is.na(ZHVI))]

dt_l[, FIPS := sprintf("%02d%03d", StateCodeFIPS, MunicipalCodeFIPS)]
dt_l[, Date := floor_date(ymd(Date), "month")]

dt_l[, Year := year(Date)]

# Convert to 2015 dollars
dt_cpi[, Annual := Annual / dt_cpi[Year == CONSTANT_YEAR, Annual]]

dt_l <- merge(dt_l, dt_cpi[, .(Year, Annual)], by = "Year", all.x = TRUE)
dt_l[, c("ZHVI", "ZHVI_SFD") := lapply(.SD, function(x) x / Annual),
     .SDcols = c("ZHVI", "ZHVI_SFD")]

v_cols <- c("Date", "FIPS", "ZHVI", "ZHVI_SFD")
dt_l <- dt_l[, ..v_cols]

saveRDS(dt_l, file = "derived/hpi-zillow.Rds")
