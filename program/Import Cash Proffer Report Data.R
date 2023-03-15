# Read Cash Proffer Report data from .pdf into data.table

rm(list = ls())

dir <- dirname(dirname(rstudioapi::getSourceEditorContext()$path))
setwd(dir)

pacman::p_load(data.table, pdftools, readxl) # tabulizer

# Import cash proffer eligibility and amounts ----

# * Option 1: Use Excel to import tables first, then read into R and clean ----
l.files <- list.files("data/DHCD Cash Proffer Reports/", pattern = "*.xlsx", full.names = TRUE)

dt <- as.data.table(read_xlsx(l.files[1], sheet = "Table008 (Page 13)", skip = 1, col_names = FALSE))

dt.1 <- dt[, paste0("...", 1:4)]
dt.2 <- dt[, paste0("...", 5:8)]

setnames(dt.1, new = c("Jurisdiction", "y2000", "y2010", "y2020"))
setnames(dt.2, new = c("Jurisdiction", "y2000", "y2010", "y2020"))

dt <- rbindlist(list(dt.1, dt.2))

dt[grepl(Jurisdiction, "CITIES",), type := 1]
dt[grepl(Jurisdiction, "COUNTIES"), type := 2] 
dt[grepl(Jurisdiction, "TOWNS"), type := 3]


# * Option 2: Use pdftools to extract text and then parse manually ----
l.files <- list.files("data/DHCD Cash Proffer Reports/", pattern = "*.pdf")
l.files <- paste0("data/DHCD Cash Proffer Reports/", l.files)

# dt <- rbindlist(lapply(l.files, pdf_text))

# pdftools
dt <- data.table(pdf_text(l.files[1]))
