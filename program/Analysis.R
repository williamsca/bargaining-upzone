# Analysis of cash proffer eligibility on building permits
# Author: Colin Williams
# Updated: 17 March 2023

rm(list = ls())

dir <- dirname(dirname(rstudioapi::getSourceEditorContext()$path))
setwd(dir)

pacman::p_load(data.table, pdftools, readxl) # tabulizer

DATA_PATH <- "data/DHCD Cash Proffer Reports/FY22-Tables.xlsx"

dt.elig <- readRDS("derived/County Eligibility (2000-2021).Rds")
dt.bp <- readRDS("derived/County Residential Building Permits (2000-2021).Rds")

# TODO: merge data

# Prepare regression sample ----
dt.bp <- dt.bp[FIPS.Code.State == "51"]
dt.bp[, Jurisdiction := gsub(" County|\\s*\\(.*", "", Name)]

dt.bp[, nObs := .N, by = .(Jurisdiction, Year4)]

dt <- merge(dt.bp, dt.elig, by = c("Jurisdiction", "Year4"), all.x = TRUE)

# TODO: implement TWFE estimator