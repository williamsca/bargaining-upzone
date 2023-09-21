# This script parses the Planning Commission's Annual Report from
# 2014, which includes useful details rezonings, including
# monetary equivalent of in-kind proffers

rm(list = ls())
library(here)
library(data.table)
library(pdftools)
library(stringr)
library(lubridate)

# Import PDF ----
s_path <- here("data", "SpotsylvaniaCo",
    "Agenda_2014_3_5_Meeting(142).pdf")

pdf_text <- pdf_text(s_path)

# Parse Units ----
pdf_units <- unlist(str_split(pdf_text[31], pattern = "\n"))
pdf_units <- gsub("\\s{2,}", "|", pdf_units[4:28])
pdf_units <- gsub("(\\d)\\s", "\\1|", pdf_units)

dt <- fread(paste0(pdf_units, collapse = "\n"), sep = "|", header = FALSE,
    fill = TRUE)

dt <- dt[V1 != "" & V2 != ""]

# Clean ----

# assume all 'by-right' units are single-family detached
dt[, n_sfd := V4 - V3]
dt[, final_date := mdy(V10)]

setnames(dt,
    c("V1", "V2", "V5", "V6"),
    c("Case.Number", "Project.Name", "n_sfa", "n_mfd")
)

dt[Case.Number == "R09-0006", final_date := mdy("6/11/2013")]

# age-restricted
dt[, n_age_restrict := 0]
dt[Case.Number == "R02-02", `:=`(
    n_age_restrict = 795, n_sfd = n_sfd - 795)]
dt[Case.Number == "R10-0005", `:=`(
    n_age_restrict = 184, n_sfa = n_sfa - 84, n_mfd = n_mfd - 100
)]
dt[Case.Number == "R13-0004", `:=`(
    n_age_restrict = 50, n_sfa = n_sfa - 50
)]
dt[Case.Number == "R13-0009", `:=`(
    n_age_restrict = 130, n_sfd = n_sfd - 130
)]

dt[, n_units := rowSums(.SD), .SDcols = c("n_sfd", "n_sfa",
    "n_mfd", "n_age_restrict")]



# Parse Proffers ----
pdf_proffers <- unlist(str_split(pdf_text[32:33], pattern = "\n"))

pdf_proffers <- gsub("SFD Shown", "SFD|Shown", pdf_proffers)
pdf_proffers <- gsub("Rt 1", "Route One", pdf_proffers)
pdf_proffers <- gsub("\\+", "", pdf_proffers)
pdf_proffers <- gsub("\\s{2,}", "|", pdf_proffers[12:85])
pdf_proffers <- gsub("(\\d)\\s", "\\1|", pdf_proffers)

dt_prof <- fread(paste0(pdf_proffers, collapse = "\n"),
    sep = "|", header = FALSE,
    fill = TRUE, nrows = 
)

dt_prof <- dt_prof[!(V1 %in% c("", "Case #")) & V2 != ""]

# Clean ----
dt_prof[, inkind_proffer := V10]
dt_prof[V1 == "R02-02", inkind_proffer := 29379100]
dt_prof[, inkind_proffer := as.numeric(
    gsub("[^0-9]", "", inkind_proffer))
]
dt_prof[is.na(inkind_proffer), inkind_proffer := 0]
dt_prof[V11 == "Unknown", inkind_proffer := NA]

setnames(dt_prof, c("V1", "V11"),
    c("Case.Number", "total_proffer")
)

dt_prof[, total_proffer := as.numeric(
    gsub("[^0-9]", "", total_proffer))
]

dt_prof[, share_affordable := as.numeric(
    gsub("[^0-9]", "", V14)) / 100
]

# Merge ----
dt <- merge(dt, dt_prof, by = c("Case.Number"), all.x = TRUE)

dt[, res_cash_proffer := (total_proffer - inkind_proffer) / n_units]
dt[, n_affordable := round(n_units * share_affordable)]
dt[, inkind_proffer := inkind_proffer / n_units]

dt[is.na(n_affordable), n_affordable := 0]
dt[is.na(res_cash_proffer), res_cash_proffer := 0]

v_cols <- c("Case.Number", "Project.Name", "n_sfd", "n_sfa", "n_mfd",
    "n_age_restrict", "n_affordable", "n_units", "final_date", "inkind_proffer",
    "res_cash_proffer")
dt <- dt[, ..v_cols]

dt[, FIPS := "51177"]
dt[, Status := "Approved"]
dt[, isResi := TRUE]
dt[, other_cash_proffer := 0]
dt[, n_unknown := 0]

saveRDS(dt, here("derived", "SpotsylvaniaCo",
    "Rezoning Approvals.Rds"))
