# This script parses the 'Description' field from the Prince William
# rezoning application data to determine the parcel's size, former
# zoning, and final zoning. It uses the Open AI API to extract
# data from unstructured text.

rm(list = ls())
library(here)
library(data.table)
library(openai)
library(stringr)
library(units)

# Sys.setenv(OPENAI_API_KEY = "")
Sys.getenv("OPENAI_API_KEY")

# Import ----
dt_app <- readRDS(here("derived", "PrinceWilliamCo",
    "Rezoning Applications.Rds"))

uniqueN(dt_app$Case.Number) == nrow(dt)

# Filter ----
dt_app <- dt_app[
    Type %in% c(
        "Rezoning - Mixed Use",
        "Rezoning - Non-Residential",
        "Rezoning - Residential"
    )
]

dt_app <- dt_app[, .(Case.Number, Description)]
dt_app[, Description := str_to_lower(Description)]

# Parse ----
# Area
pattern <- "(?<=^|[^0-9.])([0-9.]+)(?:-?\\s*(ac|acre)s?\\b)"
dt_app[, acres := str_extract(Description, pattern)]
dt_app[, acres := as.numeric(gsub("[^0-9.]", "", acres))]
dt_app[, Area := set_units(acres, "acres")]

# View(dt_app[is.na(acres)])

# Former zoning
pattern <- "(?i)from\\s+(\\w+(?:-\\w+)?)"
dt_app[, zoning_old := str_extract(Description, pattern)]
dt_app[, zoning_old := gsub("from ", "", zoning_old)]
table(dt_app$zoning_old)

# API_URL <- "https://api.openai.com/v1/engines/davinci-codex/completions"
MODEL <- "text-davinci-003"
PROMPT <- "The following string, enclosed in triple quotations, contains an approved rezoning application. 
Identify tax parcel ID, size, vote, and final zoning classification. Format your response as an R dictionary: 
c(ParcelID = '', Size = '', VotesFor = , VotesAgainst = , FinalZone = ''). No context."


s <- create_completion(model = MODEL,
                       prompt = paste0(PROMPT, "'''", pdf_text[1], "'''"),
                       max_tokens = 500)

