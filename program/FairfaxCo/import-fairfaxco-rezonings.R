# This file imports the Fairfax County rezoning application data
# posted on their webpage to compute the number of applications over time
# and joins them to GIS data that indicates the location of the rezoned
# parcel.

# GIS Downloaded on 8/4/2023 from:
# https://www.fairfaxcounty.gov/maps/open-geospatial-data

# Applications downloaded on  7/12/2023 using the script:
# 'program/scrape/Scrape Rezoning Applications (2023.07.12).py' #nolint

# There is more information contained in each application, but it
# would be difficult to scrape.

rm(list = ls())
pacman::p_load(here, data.table, lubridate, sf, stringr, httr, dplyr)

# Import Record Lists ----
l_files <- list.files("data/FairfaxCo/Record Lists/Rezoning",
    full.names = TRUE
)

dt <- rbindlist(lapply(l_files, fread, header = TRUE))
dt$V8 <- NULL
setnames(
    dt, "Record Number (xxTMP records have not been submitted)",
    "Record Number"
)

dt[, submit_date := mdy(`Submitted/ Initiated`)]
dt[, submit_month := floor_date(submit_date, "month")]

dt[, FIPS := 51059] # Fairfax County, VA

dt[, `Original Application` := gsub("\\s", "", `Original Application`)]
dt[, `Original Application` := gsub("RZ", "RZ-", `Original Application`)]
dt[, isOriginal := (`Record Number` == `Original Application`)]
dt[, original_submit := min(submit_date), by = `Original Application`]

# Sanity Checks ----
# True --> observations are unique on `Record Number`
nrow(dt) == uniqueN(dt$`Record Number`)

# Geocode ----
# Unique ID
setnames(dt, "Record Number", "Unique ID")

# City
v_cities <- c(
    "FAIRFAX", "SPRINGFIELD", "RESTON", "ANNANDALE",
    "CHANTILLY", "ALEXANDRIA", "LORTON", "VIENNA", "HERNDON",
    "FALLS CHURCH", "CENTREVILLE", "MCLEAN", "CLIFTON", "GREAT FALLS",
    "BURKE", "MC LEAN", "OAKTON", "ARLINGTON", "DUNN LORING",
    "FORT BELVOIR"
)
pattern_cities <- paste(v_cities, collapse = "|")

dt[, City := str_extract(Address, pattern_cities)]
dt[City == "MC LEAN", City := "MCLEAN"]
dt[Address == "8990 SILVERBROOK RD, VA", 
    City := "FAIRFAX STATION"]

nrow(dt[Address != "" & is.na(City)]) == 0
dt[, Address := gsub(pattern_cities, "", Address)]

# Street
dt[, `Street address` := trimws(str_extract(Address, "^[^,]+"))]
nrow(dt[is.na(`Street address`) & Address != ""]) == 0

# ZIP
dt[, ZIP := str_extract(Address, "\\d{5}-")]
dt[, ZIP := gsub("-", "", ZIP)]
dt[is.na(ZIP), ZIP := str_extract(Address, "\\d{5}")]
dt[Address == "8990 SILVERBROOK RD, VA", ZIP := "22039"]

nrow(dt[is.na(ZIP) & Address != ""]) == 0
nrow(dt[nchar(ZIP) != 5]) == 0

# State
dt[, State := "VA"]

file <- tempfile(fileext = ".csv")
write.csv(dt[!is.na(ZIP), .(
    `Unique ID`, `Street address`, City,
    State, ZIP
)], file, row.names = FALSE)

url <- "https://geocoding.geo.census.gov/geocoder/locations/addressbatch"

req <- POST(url,
    body = list(
        addressFile = upload_file(file),
        benchmark = "Public_AR_Current",
        vintage = "Current_Current",
        format = "json"
    ),
    encode = "multipart"
)
cnt <- content(req, "text", encoding = "UTF-8")
unlink(file)

dt_geo <- fread(cnt, header = FALSE, fill = TRUE)

setnames(
    dt_geo, c("V1", "V5", "V6"),
    c("Unique ID", "Exact Address", "Coordinates")
)

dt <- merge(dt,
    dt_geo[, .(`Unique ID`, `Exact Address`, `Coordinates`)], by = "Unique ID",
    all.x = TRUE
)

# Import GIS Rezoning Cases ----
sf <- st_read(
    dsn = "data/FairfaxCo/GIS/Zoning_Cases_(post-2000)/Zoning_Cases_(post-2000).shp")

# Merge ----
dt[, `Unique ID` := gsub("RZ-", "RZ", `Unique ID`)]
sf$`Unique ID` <- gsub("RZ-", "RZ", sf$CASE_NUMBE)

# m:1 (one rezoning case can correspond to multiple GIS records)
sf <- left_join(sf, dt, by = "Unique ID")

# TRUE --> all applications match to a GIS record (by construction)
nrow(subset(sf, is.na(OBJECTID))) == 0

subset(sf, `Unique ID` == "RZ2019-HM-016")

# The 'Status' variables aren't totally consistent
table(sf$STATUS, sf$Status)

sf$isResi <- (sf$ZONETYPE %in% c(
    "RESIDENTIAL", "PLANNED UNITS"
))

saveRDS(sf, paste0(
    "derived/FairfaxCo/Rezoning Applications (",
    paste(range(year(dt$submit_date)), collapse = "-"), ").Rds"
))
