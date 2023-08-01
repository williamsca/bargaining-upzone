# Analysis of cash proffer eligibility on building permits
# Author: Colin Williams
# Updated: 10 July 2023

rm(list = ls())

pacman::p_load(data.table, lubridate, here, readxl)

# Import ----
dt_bp <- readRDS(
    "derived/County Residential Building Permits by Month (2000-2021).Rds"
)
dt_zhvi <- readRDS("derived/Housing Price Index (Zillow).Rds")
dt_cp <- readRDS("derived/Cash Proffer Revenues.Rds")
dt_cpi <- read_xlsx() # TODO: defalate nominal values by CPI
dt_pop <- readRDS("derived/County Populations (2010).RDS")

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
dt <- merge(dt_bp, dt_cp[, FIPS.Code.State := "51"],
    by.x = c("Name", "FY", "FIPS.Code.State"),
    by.y = c("Jurisdiction", "Year", "FIPS.Code.State"),
    all.x = TRUE
)

dt[is.na(`Cash Proffer Revenue`), `Cash Proffer Revenue` := 0]

dt[, Date := make_date(year = Year4, month = Month)]
dt[, FIPS := as.numeric(FIPS.Code.State) * 1000 +
    as.numeric(FIPS.Code.County)
]
dt <- merge(
    dt, dt_zhvi[, .(Date, FIPS, ZHVI, RegionName)],
    by = c("Date", "FIPS"), all.x = TRUE
)

dt <- merge(dt, dt_pop, by = c("FIPS"), all.x = TRUE)

# TRUE --> merge of ZHVI is consistent with data
nrow(dt[RegionName != Name]) == 0
dt$RegionName <- NULL

# Treatment Intensity ----
# Cash proffer revenues per housing value before treatment
YEAR_RANGE <- c(2012, 2016)

# filter to VA counties
dt_VA <- dt[FIPS.Code.State == "51" & FY %between% YEAR_RANGE]

dt_VA[, Value := as.numeric(Value1 + Value2 + `Value3-4` + `Value5+`)]

dt_VA <- dt_VA[, .(Value = sum(Value), Units1 = sum(Units1)),
    by = .(FIPS.Code.State, FIPS.Code.County, Name, `Cash Proffer Revenue`, FY)
]

dt_VA <- dt_VA[, .(
    Value = sum(Value), Units1 = sum(Units1),
    cpRev = sum(`Cash Proffer Revenue`)
), by = .(FIPS.Code.State, FIPS.Code.County, Name)]

dt_VA[, intensity12_16 := cpRev / Value]
# ggplot(dt_VA, aes(x = intensity12_16)) +
#     geom_histogram() +
#     scale_x_log10()


dt <- merge(dt, dt_VA[, .(FIPS.Code.State, FIPS.Code.County, intensity12_16)],
    by = c("FIPS.Code.State", "FIPS.Code.County"), all.x = TRUE
)
dt[is.na(intensity12_16), intensity12_16 := 0]

# Filter ----
# exclude Alaska and Hawaii
dt <- dt[!(FIPS.Code.State %in% c("02", "15"))] 

# drop 24 duplicate entries
dt <- unique(dt, by = c("FIPS", "Date", "Units1"))

# exclude "Balance of State" entries from the BPS
dt <- dt[!is.na(PCT001001)]

# Sanity Checks ----
nrow(dt) == uniqueN(dt[, .(Date, FIPS)])

saveRDS(dt, "derived/Sample.Rds")
