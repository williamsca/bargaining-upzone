# Read Cash Proffer Report data from .pdf into data.table

rm(list = ls())

dir <- dirname(dirname(rstudioapi::getSourceEditorContext()$path))
setwd(dir)

pacman::p_load(data.table, pdftools, readxl) # tabulizer

# Import cash proffer eligibility and amounts ----

# * Option 1: Use Excel to import tables first, then read into R and clean ----
l.files <- list.files



# * Option 2: Use pdftools to extract text and then parse manually ----
l.files <- list.files("data/DHCD Cash Proffer Reports/", pattern = "*.pdf")
l.files <- paste0("data/DHCD Cash Proffer Reports/", l.files)

# dt <- rbindlist(lapply(l.files, pdf_text))

# pdftools
# dt <- data.table(pdf_text(l.files[1]))
