# This script parses the Henrico County approved proffers from 2010-2019.
# The proffer documents are linked at
# https://henrico.us/planning/downloadable-proffers/

rm(list = ls())
library(here)
library(data.table)
library(lubridate)
library(pdftools)

# Import ----
# Read in PDFs
l_minutes <- list.files(here("data", "HanoverCo", "BoS Minutes"),
    pattern = "*.pdf", full.names = TRUE, recursive = TRUE
)