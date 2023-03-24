# Import Building Permit Survey Data
# Source: https://www2.census.gov/econ/bps/County/

rm(list = ls())

dir <- dirname(dirname(rstudioapi::getSourceEditorContext()$path))
setwd(dir)

pacman::p_load(data.table, bit64)

YEAR_MIN <- 2000
YEAR_MAX <- 2021

url <- "https://www2.census.gov/econ/bps/County/"
l.files <- paste0(url, "co", YEAR_MIN:YEAR_MAX, "a.txt") # annual data
l.files <- paste0(url, "co", format(seq(as.Date("2000-01-01"), as.Date("2021-12-31"), by = "month"), "%y%m"), "c.txt")

l.data <- list()
for (i in 1:5) { # length(l.files)
  print(l.files[i])
  l.data <- append(l.data, fread(l.files[i], header = FALSE, blank.lines.skip = TRUE, fill = TRUE, skip = 2, sep = ","))
  sys.sleep(2)
}

# dt <- rbindlist(lapply(l.files, fread, header = FALSE, blank.lines.skip = TRUE, 
#                        fill = TRUE, skip = 2, sep = ","))

colnames <- paste0(paste0(rep(c("Bldgs", "Units", "Value"), 4)), 
                   c(rep("1", 3), rep("2", 3), rep("3-4", 3), rep("5+", 3)))
colnames <- c(c("Date", "FIPS.Code.State", "FIPS.Code.County", "Region Code", "County Code", "Name"), 
              colnames, paste0(colnames, "-rep"))
setnames(dt, new = colnames)

dt[Date > 9000, Year4 := (Date - 99)/100 + 1900]
dt[is.na(Year4), Year4 := Date]

dt[, FIPS.Code.State := sprintf("%02d", FIPS.Code.State)]
dt[, FIPS.Code.County := sprintf("%03d", FIPS.Code.County)]

# Sanity checks ----
# The 2 and 3-4 checks fail for a handful of rows
nrow(dt[Bldgs1 != Units1]) == 0 # TRUE --> every 1-unit building has 1 unit
nrow(dt[2*Bldgs2 != Units2]) == 0 # TRUE --> every 2-unit building has 2 units (some errors in data here)
nrow(dt[between(`Units3-4`, 3*`Bldgs3-4`, 4*`Bldgs3-4`)]) == 0 # TRUE --> every 3-4 unit building has at least 3 units
nrow(dt[5*`Bldgs5+` > `Units5+`]) == 0 # TRUE --> every 5+ unit building has more than 5 units

# Verify that imputed values are larger than the reported values
for (val in c("Bldgs", "Units", "Value")) {
  for (units in c("1", "2", "3-4", "5+")) {
    var <- paste0(val, units)
    print(min(dt[[var]] >= dt[[paste0(var, "-rep")]])) # 1 --> imputed figures always exceed reported
  }
}

saveRDS(dt, file = paste0("derived/County Residential Building Permits (", YEAR_MIN, "-", YEAR_MAX, ").Rds"))
