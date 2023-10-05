# This script imports Chesterfield GIS and rezoning application data
# It exports a list of residential rezonings for manual parsing
# using the zoning case materials available from the Chesterfield
# County archive.

rm(list = ls())
library(here)
library(data.table)

# Import ----
dt <- readRDS(here("derived", "ChesterfieldCo",
    "GIS Rezonings (2023.07.28).RDS"))
dt_apps <- fread(here("data", "ChesterfieldCo",
    "Applications", "RecordList20230824.csv"), header = TRUE)

dt_apps <- unique(dt_apps)

dt <-
  merge(dt, dt_apps,
        by.x = c("CaseNum", "Status"),
        by.y = c("Record Number", "Status")
  )

dt[, Area := set_units(Acres, acres)]

dt[, FIPS := "51041"]

dt[, submit_date := mdy(Date)]

# TODO: assign Part := {1,2} based on Part column
dt[, nObs := .N, by = CaseNum]
dt <- dt[
    nObs == 1 | Part %in% c("1 OF 2", "Part 1")
]

# AC: amend prior case
# ZO: rezoning
# CU: conditional use permit
# ZOR: renew zoning approval
# PD: planned development?
dt <- dt[grepl("ZO", RequestType)]

dt[grepl("^[0-9]", `Project Name`), Address := `Project Name`]
dt[Status %in% c("Denied", "Withdrawn"),
    zoning_old := AppZoning]

dt[, isResi := grepl("R", AppZoning)]

setnames(
    dt,
    c("CaseNum", "Date", "AppZoning", "CaseDescription",
      "CashProffer", "CaseName"),
    c("Case.Number", "Applied.Date", "zoning_new",
      "Description", "hasCashProffer", "Project.Name")
)

# TODO: export a list of residential rezonings for manual parsing
# Download Zoning Case information here:
# https://documents.chesterfield.gov/Weblink_BOS/Welcome.aspx



# Save ----
saveRDS(dt, here("derived", "ChesterfieldCo", "rezoning-applications.Rds"))