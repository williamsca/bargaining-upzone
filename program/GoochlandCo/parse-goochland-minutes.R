# This script parses the Goochland County minutes
# into a CSV file for further manual processing.

rm(list = ls())
library(here)
library(data.table)
library(pdftools)
library(units)

# Read in PDFs
l_minutes <- list.files(here("data", "GoochlandCo", "BoS Minutes"),
    pattern = "pdf", full.names = TRUE, recursive = TRUE)

v_dates <- substr(
    l_minutes, regexpr("\\d{4}-\\d{2}", l_minutes),
    regexpr("\\d{4}-\\d{2}", l_minutes) + 9
)

ExtractRezonings <- function(file_path) {
    pdf_text <- pdf_text(file_path)
    pdf_lines <- unlist(toupper(str_split(pdf_text, pattern = "\n")))

    return(sum(grepl(
        "ORDINANCE AMENDING|ORDINANCE TO AMEND THE GOOCHLAND COUNTY ZONING",
        pdf_lines)))
}



if (!file.exists(here("data", "GoochlandCo", "rezonings.csv"))) {
    v_times <- lapply(l_minutes, ExtractRezonings)

    v_dates <- rep(v_dates, times = v_times)

    dt_min <- data.table(
        final_date = v_dates, Case.Number = "",
        acres = NA, Status = "", bos_votes_for = NA,
        bos_votes_against = NA,
        zoning_old = NA, zoning_new = NA, n_sfd = NA, n_unknown = NA,
        n_mfd = NA, n_age_restrict = NA, res_cash_proffer = NA,
        other_cash_proffer = NA, submit_date = "",
        planning_hearing_date = "", Type = "", Description = ""
    )

    fwrite(
        dt_min, here("data", "GoochlandCo", "rezonings.csv")
    )
}

# <copy 'rezonings.csv' to ".../derived/GoochlandCo/rezonings.csv">
# <parse rezonings.csv manually in Excel>

dt <- fread(here("derived", "GoochlandCo", "rezonings.csv"))

# Clean ----
dt <- dt[Type == "Rezoning"]

dt[, final_date := ymd(final_date)]
dt[, planning_hearing_date := mdy(planning_hearing_date)]
dt[, Area := set_units(acres, acres)]
dt[, FIPS := "51075"]
dt[, submit_date := as.Date(submit_date)]

# TODO: estimate change in units from zoning codes
dt[, n_units := rowSums(.SD, na.rm = TRUE),
    .SDcols = c("n_sfd", "n_mfd", "n_unknown")]

# TODO: assign 'isResi' based on new zoning code
dt[, isResi := grepl("R|A", zoning_new)]

saveRDS(dt, here("derived", "GoochlandCo", "Rezoning Approvals.Rds"))
