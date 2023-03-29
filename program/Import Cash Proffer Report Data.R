# Read Cash Proffer Report data from .pdf into data.table
# TODO: import amounts from all pdf reports

rm(list = ls())

dir <- dirname(dirname(rstudioapi::getSourceEditorContext()$path))
setwd(dir)

pacman::p_load(data.table, pdftools, readxl) # tabulizer

DATA_PATH <- "data/DHCD Cash Proffer Reports/FY22-Tables.xlsx"

YEAR_MIN <- 2000
YEAR_MAX <- 2022
  
# Import cash proffer eligibility and amounts ----

# * Option 1: Use Excel to import tables first, then read into R and clean ----
# l.files <- list.files("data/DHCD Cash Proffer Reports/", pattern = "*.xlsx", full.names = TRUE)

l.sheets <- as.list(excel_sheets(DATA_PATH))
dt <- rbindlist(lapply(l.sheets, function(x) read_excel(DATA_PATH, sheet = x)), use.names = FALSE)

dt.1 <- dt[, paste0("Column", 1:4)]
dt.2 <- dt[, paste0("Column", c(5,7,8,9))]

setnames(dt.1, new = c("Jurisdiction", "2000", "2010", "2020"))
setnames(dt.2, new = c("Jurisdiction", "2000", "2010", "2020"))

dt <- rbindlist(list(dt.1, dt.2))

dt[grepl("CITIES", Jurisdiction), type := 1]
dt[grepl("COUNTIES", Jurisdiction), type := 2] 
dt[grepl("TOWNS", Jurisdiction), type := 3]
dt[, type := nafill(type, type = "locf")]

dt.l <- melt(dt, id.vars = c("Jurisdiction", "type"), variable.name = "FY", value.name = "Eligible")
dt.l[, FY := as.numeric(as.character(FY)) + 2]
dt.l[, isEligible := fifelse(is.na(Eligible), 0, 1)]

dt.l <- dt.l[!is.na(Jurisdiction) & !grepl("COUNTIES|CITIES|TOWNS", Jurisdiction)]
dt.l[type == 1, Jurisdiction := paste0(Jurisdiction, " City")]
dt.l[type == 2, Jurisdiction := paste0(Jurisdiction, " County")]

# Expand data to include intervening years
dt <- CJ(FY = YEAR_MIN:YEAR_MAX, Jurisdiction = unique(dt.l$Jurisdiction))
dt <- merge(dt, dt.l, by = c("FY", "Jurisdiction"), all.x = TRUE)

setorder(dt, Jurisdiction, FY)
dt[, isEligible := nafill(isEligible, type = "locf"), by = .(Jurisdiction)]
dt[, type := nafill(type, type = "locf"), by = .(Jurisdiction)]

saveRDS(dt, paste0("derived/County Eligibility (", YEAR_MIN, "-", YEAR_MAX, ").Rds"))
