# Raw data files downloaded on 7/29/2023 from:
# https://www.apa.virginia.gov/APA_Reports/LG_ComparativeReports.aspx

rm(list = ls())
pacman::p_load(here, data.table, readxl)

l_files <- list.files("data/County Finances", full.names = TRUE,
    pattern = "*.xls"
)

dt <- read_xls(l_files[1], sheet = "Exhibit A", skip = 10)
