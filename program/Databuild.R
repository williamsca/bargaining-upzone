# Analysis of cash proffer eligibility on building permits
# Author: Colin Williams
# Updated: 17 March 2023

rm(list = ls())

dir <- dirname(dirname(rstudioapi::getSourceEditorContext()$path))
setwd(dir)

pacman::p_load(data.table, lubridate) 

# Import ----
# dt.elig <- readRDS("derived/County Eligibility (2000-2022).Rds")
dt.bp <- readRDS("derived/County Residential Building Permits by Month (2000-2021).Rds")
dt.zhvi <- readRDS("derived/Housing Price Index (Zillow).Rds")
dt.cp <- readRDS("derived/Cash Proffer Revenues.Rds")

# Building Permits ----
dt.bp[Name == "Bedford (Independent City)", `:=`(Name = "Bedford County", FIPS.Code.County = "019")] # Bedford City became a town on July 1, 2013. https://en.wikipedia.org/wiki/Bedford,_Virginia
dt.bp[Name == "Clifton Forge (Independent Cit",  `:=`(Name = "Alleghany County", FIPS.Code.County = "005")] # Clifton Forge became a town in 2001. https://en.wikipedia.org/wiki/Clifton_Forge,_Virginia

v.cols <- grep("(Bldgs|Value|Units)", names(dt.bp), value = TRUE)
v.cols <- grep("rep", v.cols, value =  TRUE, invert = TRUE)
dt.bp <- dt.bp[, lapply(.SD, sum), by = .(Year4, Month, FIPS.Code.State, FIPS.Code.County, Name), .SDcols = v.cols] # combine Clifton Forge and Bedford with the surrounding county.

dt.bp[, Name := gsub("\\s*\\(.*", " City", Name)]

dt.bp[, FY := Year4 + fifelse(Month >= 7, 1, 0)] # The VA fiscal year runs from July 1 to June 30

# Note: some proffer-collecting jurisdictions are not covered in the county building permits survey
dt <- merge(dt.bp, dt.cp, by.x = c("Name", "FY"), by.y = c("Jurisdiction", "Year"), all.x = TRUE)
dt[is.na(`Cash Proffer Revenue`), `Cash Proffer Revenue` := 0]

dt[, Date := make_date(year = Year4, month = Month)][, FIPS := as.numeric(FIPS.Code.State)*1000 + as.numeric(FIPS.Code.County)]
dt <- merge(dt, dt.zhvi[, .(Date, FIPS, ZHVI, RegionName)], by = c("Date", "FIPS"), all.x = TRUE)

nrow(dt[RegionName != Name]) == 0 # TRUE --> merge of ZHVI is consistent with data
dt$RegionName <- NULL

# Treatment Intensity ----
# Cash proffer revenues per housing value before treatment
YEAR_RANGE <- c(2010, 2016)
dt.VA <- dt[FIPS.Code.State %in% c("51") & FY %between% YEAR_RANGE] # filter to VA and MD (24) counties
dt.VA[, Value := as.numeric(Value1 + Value2 + `Value3-4` + `Value5+`)]
dt.VA <- dt.VA[, .(Value = sum(Value), `Cash Proffer Revenue` = sum(`Cash Proffer Revenue`), # UnitsLB = sum(Units1 + 2*Units2 + 3*`Units3-4` + 5*`Units5+`),
                   Units1 = sum(Units1)), 
                   by = .(POST = ifelse(FY >= 2017, 1, 0), FIPS.Code.State, FIPS.Code.County, Name)]

# Impute zeros
dt.VA[is.na(`Cash Proffer Revenue`), `Cash Proffer Revenue` := 0]

dt.VA[, Intensity := `Cash Proffer Revenue` / Value]

dt <- merge(dt, dt.VA[POST == 0, .(FIPS.Code.State, FIPS.Code.County, Name, Intensity)],
            by = c("FIPS.Code.State", "FIPS.Code.County", "Name"), all.x = TRUE)
dt[is.na(Intensity), Intensity := 0]

# Filter ----
dt <- dt[!(FIPS.Code.State %in% c("02", "15"))] # exclude Alaska and Hawaii
dt <- unique(dt, by = c("FIPS", "Date", "Units1")) # drop 24 duplicate entries

# Sanity Checks ----
nrow(dt) == uniqueN(dt[, .(Date, FIPS)])

saveRDS(dt, "derived/Sample.Rds")
