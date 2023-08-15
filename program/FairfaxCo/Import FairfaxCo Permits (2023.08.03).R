# Data downloaded on 8/3/2023 from:
# https://plus.fairfaxcounty.gov/CitizenAccess/Cap/CapHome.aspx?module=Building&TabName=Building&TabList=Home%7C0%7CBuilding%7C1%7CEnforcement%7C2%7CEnvHealth%7C3%7CFire%7C4%7CPlanning%7C5%7CSite%7C6%7CZoning%7C7%7CCurrentTabIndex%7C1
# 'Building' --> Record Type = {Residential New, Commercial New}

rm(list = ls())
pacman::p_load(here, data.table, lubridate, httr, jsonlite, stringr)

# Import ----
l_files <- list.files("data/FairfaxCo/Record Lists/Building", full.names = TRUE,
                      recursive = TRUE)

dt <- rbindlist(lapply(l_files, fread, header = TRUE))
dt$V7 <- NULL

dt[, submit_date := mdy(Submitted)]
dt[, submit_month := floor_date(submit_date, "month")]

dt[, FIPS := 51059] # Fairfax County, VA

# Drop three duplicate rows
dt <- unique(dt)
nrow(dt) == uniqueN(dt$`Record Number`)

# Geocode ----
# Use the CEnsus Geocoder API to geocode the addresses
# https://geocoding.geo.census.gov/geocoder/Geocoding_Services_API.pdf

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
nrow(dt[Address != "" & is.na(City) & Status != "Voided"]) == 0
dt[, Address := gsub(pattern_cities, "", Address)]

# Street
dt[, `Street address` := trimws(str_extract(Address, "^[^,]+"))]
nrow(dt[is.na(`Street address`) & Address != ""]) == 0

# ZIP
dt[, ZIP := str_extract(Address, "\\d{5}-")]
dt[, ZIP := gsub("-", "", ZIP)]
dt[is.na(ZIP), ZIP := str_extract(Address, "\\d{5}")]

nrow(dt[is.na(ZIP) & Address != "" & Status != "Voided"]) == 0
nrow(dt[nchar(ZIP) != 5]) == 0

# State
dt[, State := "VA"]

dt[!is.na(ZIP), .(
    `Unique ID`, `Street address`, City,
    State, ZIP
)]

file <- tempfile(fileext = ".csv")
write.csv(dt[!is.na(ZIP), .(`Unique ID`, `Street address`, City,
    State, ZIP)], file, row.names = FALSE)

url <- "https://geocoding.geo.census.gov/geocoder/locations/addressbatch"
req <- POST(url, body = list(addressFile = upload_file(file),
                             benchmark = "Public_AR_Current",
                             vintage = "Current_Current",
                             format = "json"),
            encode = "multipart")
cnt <- content(req, "text", encoding = "UTF-8")
unlink(file)

dt_geo <- fread(input = cnt, header = FALSE, fill = TRUE)
setnames(dt_geo, c("V1", "V5", "V6"),
    c("Unique ID", "Exact Address", "Coordinates"))

dt <- merge(dt, dt_geo[, .(`Unique ID`, Coordinates, `Exact Address`)],
            by = "Unique ID", all.x = TRUE)

saveRDS(dt, paste0(
    "derived/FairfaxCo/Building Permits (",
    paste(range(year(dt$submit_date)), collapse = "-"),
    ").Rds"))
