# Import Zillow Home Value Index
# Downloaded on 4/6/2023 from
# https://www.zillow.com/research/data/

rm(list = ls())

dir <- dirname(dirname(rstudioapi::getSourceEditorContext()$path))
setwd(dir)

pacman::p_load(data.table, lubridate) 

dt <- fread("data/Housing Prices/Zillow Home Value Index.csv")

dt <- dt[State == "VA"]

v.measure <- grep("-", names(dt), value = TRUE)
dt.l <- melt(dt, id.vars = c("RegionName", "RegionType", "State", "StateCodeFIPS", 
                             "MunicipalCodeFIPS"), measure.vars = v.measure,
             variable.name = "Date", value.name = "ZHVI")

dt.l[, Date := ymd(Date) + 1][, FIPS := StateCodeFIPS * 1000 + MunicipalCodeFIPS]

saveRDS(dt.l, file = "derived/Housing Price Index (Zillow).Rds")

