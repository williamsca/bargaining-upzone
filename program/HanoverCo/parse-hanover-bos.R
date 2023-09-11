# This script parses the Hanover County minutes
# into a CSV file for further manual processing.

rm(list = ls())
library(here)
library(data.table)
library(pdftools)
library(units)
library(stringr)
library(lubridate)

# Read in PDFs
l_minutes <- list.files(here("data", "HanoverCo", "BoS Minutes"),
    pattern = "pdf", full.names = TRUE, recursive = TRUE
)

ExtractRezonings <- function(file_path) {
    pdf_text <- pdf_text(file_path)
    pdf_lines <- unlist(str_split(pdf_text, pattern = "\n"))
    pdf_lines <- unlist(toupper(pdf_lines))

    dt <- data.table(
        line = pdf_lines, final_date = mdy(pdf_lines[1]),
        zoning_old = NA, zoning_new = NA, acres = NA,
        Status = "", bos_votes_for = NA, bos_votes_against = NA,
        n_sfd = NA, n_unknown = NA,
        n_mfd = NA, n_age_restrict = NA, res_cash_proffer = NA,
        other_cash_proffer = NA, submit_date = "",
        planning_hearing_date = "", Type = "", Description = ""
    )

    dt[, Case.Number := substr(trimws(line), 1, 13)]
    dt[, Case.Number := gsub(" ", "", Case.Number)]

    dt <- dt[grepl("REQUESTS? TO REZONE", line)]

    return(dt)

}

dt <- rbindlist(lapply(l_minutes, ExtractRezonings))

test <- ExtractRezonings(l_minutes[4])

