# Analysis of cash proffer eligibility on building permits
# Author: Colin Williams
# Updated: 17 March 2023

rm(list = ls())

dir <- dirname(dirname(rstudioapi::getSourceEditorContext()$path))
setwd(dir)

pacman::p_load(data.table) 

DATA_PATH <- "data/DHCD Cash Proffer Reports/FY22-Tables.xlsx"

dt.elig <- readRDS("derived/County Eligibility (2000-2021).Rds")
dt.bp <- readRDS("derived/County Residential Building Permits (2000-2021).Rds")

# Prepare regression sample ----
dt.bp <- dt.bp[FIPS.Code.State %in% c("51", "24")] # filter to VA and MD counties

dt.bp[Name == "Bedford (Independent City)", `:=`(Name = "Bedford County", FIPS.Code.County = "019")] # Bedford City became a town on July 1, 2013. https://en.wikipedia.org/wiki/Bedford,_Virginia
dt.bp[Name == "Clifton Forge (Independent Cit",  `:=`(Name = "Alleghany County", FIPS.Code.County = "005")] # Clifton Forge became a town in 2001. https://en.wikipedia.org/wiki/Clifton_Forge,_Virginia

v.cols <- grep("(Bldgs|Value|Units)", names(dt.bp), value = TRUE)
v.cols <- grep("rep", v.cols, value =  TRUE, invert = TRUE)
dt.bp <- dt.bp[, lapply(.SD, sum), by = .(Year4, FIPS.Code.State, FIPS.Code.County, Name), .SDcols = v.cols] # combine Clifton Forge and Bedford with the surrounding county.

dt.bp[, Name := gsub("\\s*\\(.*", " City", Name)]

dt <- merge(dt.bp, dt.elig, by.x = c("Name", "Year4"), by.y = c("Jurisdiction", "Year4"), all.x = TRUE)

# Sanity checks ----
nrow(dt[FIPS.Code.State == "51" & is.na(isEligible)]) == 0 # TRUE --> every VA county has a known eligibility status

saveRDS(dt, "derived/Regression Sample.Rds")
