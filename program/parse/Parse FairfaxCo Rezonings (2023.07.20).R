# See 'Scrape Rezoning Applications (2023.07.12).py' for data collection.
# This file imports the Fairfax County rezoning application data
# posted on their webpage to compute the number of applications over time.

# It may be necessary to later scrape the relevant documents individually,
# but this would take many hours.

rm(list = ls())
pacman::p_load(here, data.table, lubridate)

# Import Record Lists ----
l_files <- list.files("data/FairfaxCo/Record Lists", full.names = TRUE)

dt <- rbindlist(lapply(l_files, fread, header = TRUE))
dt$V8 <- NULL
setnames(
    dt, "Record Number (xxTMP records have not been submitted)",
    "Record Number"
)

dt[, submit_date := mdy(`Submitted/ Initiated`)]
dt[, submit_month := floor_date(submit_date, "month")]

dt[, FIPS := 51059] # Fairfax County, VA

dt[, `Original Application` := gsub("\\s", "", `Original Application`)]
dt[, `Original Application` := gsub("RZ", "RZ-", `Original Application`)]
dt[, isOriginal := (`Record Number` == `Original Application`)]
dt[, original_submit := min(submit_date), by = `Original Application`]

# Sanity Checks ----
# TRUE --> original application has the earliest submit date
nrow(dt[isOriginal == TRUE & submit_date != original_submit]) == 0

dt[`Original Application` == "RZ-2010-PR-023"]

# True --> observations are unique on `Record Number`
nrow(dt) == uniqueN(dt$`Record Number`)

dt[`Original Application` == "RZ-2010-PR-023"]

# Save ----
saveRDS(dt, paste0(
    "derived/FairfaxCo/Rezoning Applications (",
    paste(range(year(dt$submit_date)), collapse = "-"), ").Rds"
))
