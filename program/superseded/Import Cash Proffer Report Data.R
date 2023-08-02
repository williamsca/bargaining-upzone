# Read Cash Proffer Report data from .pdf into data.table

rm(list = ls())

dir <- dirname(dirname(rstudioapi::getSourceEditorContext()$path))
setwd(dir)

pacman::p_load(data.table, pdftools, readxl)

YEAR_MIN <- 2004
YEAR_MAX <- 2022

# Parse Cash Proffer Reports ----
# Revenues by locality and fiscal year
l.files <- paste0(
  "data/DHCD Cash Proffer Reports/Proffer Report FY",
  YEAR_MIN:YEAR_MAX, ".pdf"
)

GetAppendixD <- function(path) {
  txt <- pdf_text(path)
  return(txt[max(grep("Summary of Survey Responses from Localities", txt))])
}

l.pdf <- lapply(l.files, GetAppendixD)

ParseAppendixD <- function(fy, pdf_list) {
  if (fy <= 2021) {
    lines <- strsplit(unlist(l.pdf[grep(paste0(
      "Fiscal Year ", fy - 1, ".", fy
    ), pdf_list, ignore.case = TRUE)]), "\n")[[1]]
  } else { # format changes in 2022
    lines <- strsplit(unlist(l.pdf[grep(paste0(
      "Fiscal Year ", fy
    ), pdf_list, ignore.case = TRUE)]), "\n")[[1]]
  }

  lines <- trimws(gsub("\\$|,", "", lines))
  lines <- lines[lines != ""]

  # Split each line into parts
  parts <- strsplit(lines, "\\s{2,}")

  # Some lines have extra line breaks -->
  # filter to lines with more than one entry
  parts <- parts[unlist(lapply(parts, length)) >= 2]

  dt <- data.table(Locality = unlist(lapply(parts, "[[", 1)),
    `Cash Proffer Revenue` = lapply(parts, "[[", 2),
    FY = fy)

  # Convert columns to numeric
  dt[, `Cash Proffer Revenue` := as.numeric(gsub("[- ]", "",
    `Cash Proffer Revenue`))
  ]

  return(dt)
}

dt_cp <- rbindlist(lapply(YEAR_MIN:YEAR_MAX, ParseAppendixD, l.pdf))
dt_cp <- dt_cp[!is.na(`Cash Proffer Revenue`) & !grepl("[0-9]", Locality)]

# Clean Locality field
dt_cp[grepl("Fairfax", Locality), Locality := "Fairfax"]
dt_cp[Locality == "Isle o f Wight", Locality := "Isle of Wight"]
dt_cp[Locality == "M anassas P ark", Locality := "Manassas Park"]
dt_cp[Locality == "P rince William", Locality := "Prince William"]
dt_cp[Locality == "Go o chland", Locality := "Goochland"]
dt_cp[, Locality := sub("\\&", "and", Locality)]

dt_cp[!grepl("and|of|City|King|Park|Prince|Gap|New|Beach", Locality),
  Locality := gsub(" ", "", Locality)
]

# Tag counties, cities, and towns
dt_cp[, type := ifelse(.I == min(.I), 2, NA), by = FY]
dt_cp[grepl("Counties", Locality, ignore.case = TRUE), type := 1]
dt_cp[grepl("Cities", Locality, ignore.case = TRUE), type := 3]
dt_cp[, type := nafill(type, type = "locf")]

dt_cp[type == 1, Name := paste0(Locality, " City")]
dt_cp[type == 2, Name := paste0(Locality, " County")]
dt_cp[type == 3, Name := paste0(Locality, " Town")]
# TODO: aggregate towns within counties?

# * Sanity checks ----
dt_cp[, `Grand Total` := sum(`Cash Proffer Revenue` *
  (!grepl("Total", Locality, ignore.case = TRUE))),
   by = FY
]

# TRUE --> summing all rows matches with reported grand total
nrow(dt_cp[grepl("Grand", Locality, ignore.case = TRUE) &
  abs(`Cash Proffer Revenue` - `Grand Total`) > 2]) == 0

dt_cp <- dt_cp[!grepl("T ?o ?t ?a ?l", Locality, ignore.case = TRUE)
  & !is.na(Name)]
setorder(dt_cp, Jurisdiction, FY)



saveRDS(dt_cp[, .(Jurisdiction, FY, `Cash Proffer Revenue`)],
  paste0(
    "derived/Cash Proffer Revenues (",
    paste(range(dt$FY), collapse = "-"),
    ").Rds"
))