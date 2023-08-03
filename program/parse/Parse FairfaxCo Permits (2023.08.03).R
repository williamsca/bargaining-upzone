# Data downloaded on 8/3/2023 from:
# https://plus.fairfaxcounty.gov/CitizenAccess/Cap/CapHome.aspx?module=Building&TabName=Building&TabList=Home%7C0%7CBuilding%7C1%7CEnforcement%7C2%7CEnvHealth%7C3%7CFire%7C4%7CPlanning%7C5%7CSite%7C6%7CZoning%7C7%7CCurrentTabIndex%7C1
# 'Building' --> Record Type = {Residential New, Commercial New}

rm(list = ls())
pacman::p_load(here, data.table, lubridate, httr, jsonlite)

# Import ----
l_files <- list.files("data/FairfaxCo/Record Lists/Building", full.names = TRUE,
                      recursive = TRUE)

dt <- rbindlist(lapply(l_files, fread, header = TRUE))
dt$V7 <- NULL

dt[, submit_date := mdy(Submitted)]
dt[, submit_month := floor_date(submit_date, "month")]

dt[, FIPS := 51059] # Fairfax County, VA

# Geocode ----
# Use the CEnsus Geocoder API to geocode the addresses
# https://geocoding.geo.census.gov/geocoder/Geocoding_Services_API.pdf
url <- "https://geocoding.geo.census.gov/geocoder/locations/addressbatch"

file <- tempfile(fileext = ".csv")
write.csv(dt$Address, file, row.names = FALSE)
req <- POST(url, body = list(addressFile = upload_file(file),
                             benchmark = "Public_AR_Current",
                             vintage = "Current_Current",
                             format = "json"),
            encode = "multipart")
cnt <- content(req, "text", encoding = "UTF-8")
unlink(file)




saveRDS(dt, "derived/FairfaxCo/Building Permits (2012-2019).Rds")
