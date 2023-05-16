# Read Cash Proffer Report data from .pdf into data.table

rm(list = ls())

dir <- dirname(dirname(rstudioapi::getSourceEditorContext()$path))
setwd(dir)

pacman::p_load(data.table, pdftools, readxl)

YEAR_MIN <- 2004
YEAR_MAX <- 2022
  
# Parse Cash Proffer Reports ----
# Revenues by locality and year
l.files <- paste0("data/DHCD Cash Proffer Reports/Proffer Report FY", YEAR_MIN:YEAR_MAX, ".pdf")

GetAppendixD <- function(path) {
  txt <- pdf_text(path)
  return(txt[max(grep("Summary of Survey Responses from Localities", txt))])
}

l.pdf <- lapply(l.files, GetAppendixD)

ParseAppendixD <- function(fy, pdf_list) {
  if (fy <= 2021) {
    lines <- strsplit(unlist(l.pdf[grep(paste0("Fiscal Year ", fy-1, ".", fy), pdf_list, ignore.case = TRUE)]), "\n")[[1]]    
  } else { # format changes in 2022
    lines <- strsplit(unlist(l.pdf[grep(paste0("Fiscal Year ", fy), pdf_list, ignore.case = TRUE)]), "\n")[[1]]    
  }

  # Remove unnecessary lines (headings, footers, empty lines)
  # firstLine <- grep("A ?lbemarle", lines)-1
  # lastLine <- grep("G ?r ?a ?n ?d T ?o ?t ?a ?l", lines, ignore.case = TRUE)+1
  # lines <- lines[-c(1:firstLine, lastLine:length(lines))]
  
  lines <- trimws(gsub("\\$|,", "", lines))
  lines <- lines[lines != ""]
  
  # Split each line into parts
  parts <- strsplit(lines, "\\s{2,}")
  
  # Some lines have extra line breaks --> filter to lines with more than one entry
  parts <- parts[unlist(lapply(parts, length)) >= 2] 
  
  
  dt <- data.table(Locality = unlist(lapply(parts, "[[", 1)),
                   `Cash Proffer Revenue` = lapply(parts, "[[", 2),
                   Year = fy)
  
  # Convert columns to numeric
  dt[, `Cash Proffer Revenue` := as.numeric(gsub("[- ]", "", `Cash Proffer Revenue`))]
  
  return(dt)
}

dt <- rbindlist(lapply(YEAR_MIN:YEAR_MAX, ParseAppendixD, l.pdf))
dt <- dt[!is.na(`Cash Proffer Revenue`) & !grepl("[0-9]", Locality)]

# Clean Locality field
dt[grepl("Fairfax", Locality), Locality := "Fairfax"]
dt[Locality == "Isle o f Wight", Locality := "Isle of Wight"]
dt[Locality == "M anassas P ark", Locality := "Manassas Park"]
dt[Locality == "P rince William", Locality := "Prince William"]
dt[Locality == "Go o chland", Locality := "Goochland"]
dt[, Locality := sub("\\&", "and", Locality)]

dt[!grepl("and|of|City|King|Park|Prince|Gap|New|Beach", Locality), Locality := gsub(" ", "", Locality)]

# Tag counties, cities, and towns
dt[, type := ifelse(.I == min(.I), 2, NA), by = Year]
dt[grepl("Counties", Locality, ignore.case = TRUE), type := 1]
dt[grepl("Cities", Locality, ignore.case = TRUE), type := 3]
dt[, type := nafill(type, type = "locf")]

dt[type == 1, Jurisdiction := paste0(Locality, " City")]
dt[type == 2, Jurisdiction := paste0(Locality, " County")]
# dt[type == 3, Jurisdiction := Locality]
# TODO: map towns to counties

# * Sanity checks ----
dt[, `Grand Total` := sum(`Cash Proffer Revenue`*(!grepl("Total", Locality, ignore.case = TRUE))), 
   by = .(Year)]
# TRUE --> summing all rows matches with reported grand total
nrow(dt[grepl("Grand", Locality, ignore.case = TRUE) & abs(`Cash Proffer Revenue` - `Grand Total`) > 2]) == 0 

dt <- dt[!grepl("T ?o ?t ?a ?l", Locality, ignore.case = TRUE) & !is.na(Jurisdiction)]
setorder(dt, Jurisdiction, Year)

saveRDS(dt[, .(Jurisdiction, Year, `Cash Proffer Revenue`)], "derived/Cash Proffer Revenues.Rds")

# Superseded ----
# dt <- as.data.table(do.call(rbind, parts))
# 
# # Set the column names
# setnames(dt, c("Locality", "Total Cash Proffer Revenue Collected", 
#                "Total Pledged But Payment Conditioned Only on Time", 
#                "Total Cash Proffer Revenue Expended", 
#                "Schools", "Roads and Other Transportation Improvements", 
#                "Fire, Rescue, and Public Safety", "Library", 
#                "Parks, Recreation, and Open Space", "Water and Sewer Service Extension", 
#                "Community Centers", "Stormwater Management", 
#                "Special Needs Housing", "Affordable Housing", 
#                "Miscellaneous"))
# 
# numeric_cols <- colnames(dt)[-1]  # Excluding 'Locality'
# dt[, (numeric_cols) := lapply(.SD, function(x) as.numeric(gsub("-", "", x))), .SDcols = numeric_cols]

# * Parse eligibility ----
# Use Excel to import tables first, then read into R and clean 
# DATA_PATH <- "data/DHCD Cash Proffer Reports/FY22-Tables.xlsx"
# l.sheets <- as.list(excel_sheets(DATA_PATH))
# dt <- rbindlist(lapply(l.sheets, function(x) read_excel(DATA_PATH, sheet = x)), use.names = FALSE)
# 
# dt.1 <- dt[, paste0("Column", 1:4)]
# dt.2 <- dt[, paste0("Column", c(5,7,8,9))]
# 
# setnames(dt.1, new = c("Jurisdiction", "2000", "2010", "2020"))
# setnames(dt.2, new = c("Jurisdiction", "2000", "2010", "2020"))
# 
# dt <- rbindlist(list(dt.1, dt.2))
# 
# dt[grepl("CITIES", Jurisdiction), type := 1]
# dt[grepl("COUNTIES", Jurisdiction), type := 2] 
# dt[grepl("TOWNS", Jurisdiction), type := 3]
# dt[, type := nafill(type, type = "locf")]
# 
# dt.l <- melt(dt, id.vars = c("Jurisdiction", "type"), variable.name = "FY", value.name = "Eligible")
# dt.l[, FY := as.numeric(as.character(FY)) + 2]
# dt.l[, isEligible := fifelse(is.na(Eligible), 0, 1)]
# 
# dt.l <- dt.l[!is.na(Jurisdiction) & !grepl("COUNTIES|CITIES|TOWNS", Jurisdiction)]
# dt.l[type == 1, Jurisdiction := paste0(Jurisdiction, " City")]
# dt.l[type == 2, Jurisdiction := paste0(Jurisdiction, " County")]
# 
# # Expand data to include intervening years
# dt <- CJ(FY = YEAR_MIN:YEAR_MAX, Jurisdiction = unique(dt.l$Jurisdiction))
# dt <- merge(dt, dt.l, by = c("FY", "Jurisdiction"), all.x = TRUE)
# 
# setorder(dt, Jurisdiction, FY)
# dt[, isEligible := nafill(isEligible, type = "locf"), by = .(Jurisdiction)]
# dt[, type := nafill(type, type = "locf"), by = .(Jurisdiction)]
# 
# saveRDS(dt, paste0("derived/County Eligibility (", YEAR_MIN, "-", YEAR_MAX, ").Rds"))
