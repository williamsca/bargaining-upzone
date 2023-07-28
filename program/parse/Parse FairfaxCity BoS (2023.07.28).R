# This script parses information on rezonings from the Fairfax City
# Board of Supervisors meetings.

rm(list = ls())
pacman::p_load(here, data.table)

# Import ----
l_files <- list.files("data/FairfaxCity/BoS Reporter",
    full.names = TRUE, recursive = TRUE, pattern = "*.html"
)

ParseRezonings <- function(file_path) {
    l_lines <- readLines(file_path)

    l_lines <- gsub("<[^>]*>", "", l_lines)
    l_lines <- trimws(gsub("&nbsp;", "", l_lines))

    # Initialize variables
    Rezoning <- character()
    date <- NA

    for (line in l_lines) {
        # Date
        if (is.na(date) & !is.na(mdy(line))) {
            date <- mdy(line)
        }

        # Rezoning
        if (grepl("Rezoning", line)) {
            Rezoning <- c(Rezoning, line)
        }
    }

    dt <- data.table(date, Rezoning, path = file_path)
    return(dt)
}

dt <- rbindlist(lapply(l_files, ParseRezonings))

# TRUE --> data are unique by date (i.e., never more than one rezoning)
uniqueN(dt$date) == nrow(dt)

dt <- dt[!is.na(Rezoning)]

fwrite(dt, "derived/FairfaxCity/BoS Reporter Raw Rezonings.csv")
