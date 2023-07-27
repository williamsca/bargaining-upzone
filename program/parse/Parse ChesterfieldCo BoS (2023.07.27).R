# Parse Chesterfield County Board of Supervisors summary minutes
# This file extracts every item under the "REQUESTS FOR MANUFACTURED
# HOME PERMITS AND REZONING" section and exports an excel file with
# the date, case number, and the summary of the board's action.

rm(list = ls())
pacman::p_load(here, data.table, pdftools, stringr, lubridate)

ExtractRezonings <- function(file_path) {
    pdf_text <- pdf_text(file_path)
    pdf_lines <- unlist(str_split(pdf_text, pattern = "\n"))

    if (!any(grepl("REZONING", pdf_lines))) {
        return(NULL)
    } else {
        return(pdf_lines)
    }
}

ParseRezonings <- function(lines) {
    # Extract the date
    date <- lines[grepl("SummaryofActionsTaken", lines)]
    date <- mdy(trimws(gsub("SummaryofActionsTakenbytheBoardon", "", date)))

    # Define empty vectors to hold the parsed fields
    CaseID <- character()
    Outcome <- character()
    isRezoning <- logical()
    TaxIDs <- character()

    # Initialize variables to hold the current values
    current_CaseID <- NA
    current_Outcome <- NA
    current_isRezoning <- FALSE
    current_TaxIDs <- NA
    parsing_IDs <- FALSE
    id_lines <- ""

    # Loop over each line
    for (line in lines) {
        # Start of a new case
        if (str_detect(line, "In.*MagisterialDistrict")) {
            current_CaseID <- NA
            current_Outcome <- NA
            current_isRezoning <- FALSE
            current_TaxIDs <- NA
        }

        # Case ID
        if (str_detect(line, "\\d{2}[A-Z]{2}\\d{4}") && is.na(current_CaseID)) {
            current_CaseID <- str_extract(line, "\\d{2}[A-Z]{2}\\d{4}")
        }

        # Outcomes
        if (str_detect(line, "Approved")) {
            current_Outcome <- "Approved"
        }
        if (str_detect(line, "Deferred")) {
            current_Outcome <- "Deferred"
        }
        if (str_detect(line, "Denied")) {
            current_Outcome <- "Denied"
        }

        # Rezoning?
        if (str_detect(line, "rezoning")) {
            current_isRezoning <- TRUE
        }

        # Tax IDs
        if (str_detect(line, "TaxID.*")) {
            parsing_IDs <- TRUE
        }

        if (parsing_IDs == TRUE) {
            id_lines <- paste0(id_lines, line)

            if (str_detect(line, "(TaxID.*\\.)|(^[^T]*\\.[^T]*$)")) {
                id_lines <- str_extract(id_lines, "(?<=TaxID)[^\\.]*")
                current_TaxIDs <- str_replace_all(id_lines, "s", "")
                id_lines <- ""

                parsing_IDs <- FALSE

                CaseID <- c(CaseID, current_CaseID)
                Outcome <- c(Outcome, current_Outcome)
                isRezoning <- c(isRezoning, current_isRezoning)
                TaxIDs <- c(TaxIDs, current_TaxIDs)
            }
        }
    }
    # Combine everything into a data table
    dt <- data.table(date, CaseID, Outcome, isRezoning, TaxIDs)
    return(dt)
}

l_paths <- list.files("data/ChesterfieldCo/BoS Summary",
    pattern = "*.pdf",
    full.names = TRUE
)

l_files <- lapply(l_paths, ExtractRezonings)

dt <- rbindlist(lapply(l_files, ParseRezonings))

dt[, TaxIDs := str_replace_all(TaxIDs, "\\s", "")]
dt <- dt[!is.na(CaseID)]

# Export ----
s_output <- "derived/ChesterfieldCo/BoS Summary Rezonings (2023.07.27).csv"
if (!file.exists(s_output)) {
    fwrite(dt, s_output)
} else {
    stop("The file already exists.")
}