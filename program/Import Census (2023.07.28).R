rm(list = ls())
pacman::p_load(here, data.table, censusapi)

# Add key to .Renviron
Sys.setenv(CENSUS_KEY = "1cc02abe8c0e40482642650aaf4f230e511c650c")

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

    df$year <- year
    return(as.data.table(df))
}

dt <- getDecCensus(2010)
dt[, FIPS := as.numeric(paste0(state, county))]

saveRDS(dt, "derived/County Populations (2010).RDS")
