rm(list = ls())

library(data.table)
library(here)
library(censusapi)

# Sys.setenv(CENSUS_KEY = "")

# Reload .Renviron
readRenviron("~/.Renviron")

# Check to see that the expected key is output in your R console
Sys.getenv("CENSUS_KEY")

getDecCensus <- function(year) {
    df <- getCensus(
        name = "dec/sf2", vintage = year, # regionin = "state:51",
        region = "county:*",
        vars = c("PCT001001")
    )

    df$Year <- year
    return(as.data.table(df))
}

dt <- getDecCensus(2010)
dt[, FIPS := paste0(state, county)]
dt <- dt[, .(FIPS, PCT001001)]

saveRDS(dt, "derived/county-populations-2010.Rds")
