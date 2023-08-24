# This script imports rezoning applications for a set
# of counties and cities in Virginia. It then standardizes
# the columns and exports a combined binary file for analysis.

rm(list = ls())
library(here)
library(data.table)
library(lubridate)

# Import ----
# Loudoun County
dt_loudoun <- readRDS(here("derived", "LoudounCo",
    "Rezoning Applications.Rds"))

uniqueN(dt_loudoun$Case.Number) == nrow(dt_loudoun)
nrow(dt_loudoun[is.na(submit_date)]) == 0


# Prince William County
dt_pwc <- readRDS(here("derived", "PrinceWilliamCo",
    "Rezoning Applications.Rds"))

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

dt_chesterfield[, submit_date := mdy(Date)]

nrow(dt_chesterfield[date > submit_date])

dt_chesterfield[, nObs := .N, by = CaseNum]
dt_chesterfield <- dt_chesterfield[
    nObs == 1 | Part %in% c("1 OF 2", "Part 1")
]

names(dt_chesterfield)
dt_chesterfield[,
  c("AnticipatedDate", "Part", "SignPostingNum",
    "Shape__Area", "Shape__Length", "nObs", "V6",
    "Record Type", "LandUseCaseType") := NULL
]

setnames(
    dt_chesterfield,
    c("CaseNum", "Date", "Project Name"),
    c("Case.Number", "Applied.Date", "Project.Name")
)

# TODO: determine 'Type' (i.e., residential, commercial, etc.) based on "AppZoning" and "CaseDescription"
# TODO: create vector of standard columns names for all counties

uniqueN(dt_chesterfield$Case.Number) == nrow(dt_chesterfield)
nrow(dt_chesterfield[is.na(submit_date)]) == 0

# Sanity Checks ----
# Loudoun County

# Prince William County

# Chesterfield County


# Clean ----
# Drop minor modifications, comp plan amendments, proffer amendments
v_types <- c(
    "Rezoning - Mixed Use", "Rezoning - Non-Residential",
    "Rezoning - Residential"
)
dt <- dt[Type %in% v_types]

dt[, isResi := (Type != "Rezoning - Non-Residential")]
dt[, isApproved := (Status == "Approved")]

# TODO: parse 'Description' field to determine old and new
# zoning code