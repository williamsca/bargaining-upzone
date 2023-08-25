# This script imports rezoning applications for a set
# of counties and cities in Virginia. It then standardizes
# the columns and exports a combined binary file for analysis.

# TODO: parse 'Description' field for Loudoun, PWC to determine
# old and new zoning code

rm(list = ls())
library(here)
library(data.table)
library(lubridate)

v_cols <- c(
    "FIPS", "Case.Number", "submit_date",
    "Project.Name", "Status", "Acres", "Address", "Main.Parcel",
    "Description", "final_date", "isResi", "zoning_old",
    "zoning_new", "hasCashProffer", "isExempt"
)

# Import ----
# Loudoun County
dt_loudoun <- readRDS(here("derived", "LoudounCo",
    "Rezoning Applications.Rds"))

dt_loudoun <- dt_loudoun[Type == "Zoning Map Amendment - ZCASE"]

uniqueN(dt_loudoun$Case.Number) == nrow(dt_loudoun)
nrow(dt_loudoun[is.na(submit_date)]) == 0

# Prince William County
dt_pwc <- readRDS(here("derived", "PrinceWilliamCo",
    "Rezoning Applications.Rds"))

dt_pwc[, Type := gsub("\"", "", Type)]
dt_pwc <- dt_pwc[
    Type %in% c(
        "Rezoning - Mixed Use",
        "Rezoning - Non-Residential",
        "Rezoning - Residential"
    )
]
dt_pwc[, isResi := (Type != "Rezoning - Non-Residential")]

uniqueN(dt_pwc$Case.Number) == nrow(dt_pwc)
nrow(dt_pwc[is.na(submit_date)]) == 0

# Chesterfield County
dt_chesterfield <- readRDS(here("derived", "ChesterfieldCo",
    "GIS Rezonings (2023.07.28).RDS"))
dt_chesterfield_apps <- fread(here("data", "ChesterfieldCo",
    "Applications", "RecordList20230824.csv"), header = TRUE)

dt_chesterfield_apps <- unique(dt_chesterfield_apps)

dt_chesterfield <-
  merge(dt_chesterfield, dt_chesterfield_apps,
        by.x = c("CaseNum", "Status"),
        by.y = c("Record Number", "Status")
  )

dt_chesterfield[, FIPS := "51041"]

dt_chesterfield[, submit_date := mdy(Date)]

dt_chesterfield[, nObs := .N, by = CaseNum]
dt_chesterfield <- dt_chesterfield[
    nObs == 1 | Part %in% c("1 OF 2", "Part 1")
]

# AC: amend prior case
# ZO: rezoning
# CU: conditional use permit
# ZOR: renew zoning approval
# PD: planned development?
dt_chesterfield <- dt_chesterfield[grepl("ZO", RequestType)]

dt_chesterfield[grepl("^[0-9]", `Project Name`), Address := `Project Name`]
dt_chesterfield[Status %in% c("Denied", "Withdrawn"),
    zoning_old := AppZoning]

dt_chesterfield[, isResi := grepl("R", AppZoning)]

setnames(
    dt_chesterfield,
    c("CaseNum", "Date", "AppZoning", "CaseDescription",
      "CashProffer", "CaseName"),
    c("Case.Number", "Applied.Date", "zoning_new",
      "Description", "hasCashProffer", "Project.Name")
)

dt_chesterfield <- dt_chesterfield[, ..v_cols]


# TODO: define 'isResi' based on zoning_new

uniqueN(dt_chesterfield$Case.Number) == nrow(dt_chesterfield)
nrow(dt_chesterfield[is.na(submit_date)]) == 0

# Combine ----
dt <- rbindlist(list(dt_loudoun, dt_pwc, dt_chesterfield), fill = TRUE)

# Filter to standard columns
dt <- dt[, ..v_cols]

dt[, isApproved := grepl("Approved", Status)]


saveRDS(dt, here("derived", "County Rezonings.Rds"))