# This script uses the OpenAI API to extract details about residential
# rezonings from the Chesterfield Board of Supervisor's meeting minutes.

rm(list = ls())
library(here)
library(data.table)
library(openai)
library(pdftools)

# Sys.setenv(OPENAI_API_KEY = "")
readRenviron("~/.Renviron") # Reload .Renviron
Sys.getenv("OPENAI_API_KEY") # Check to see that the expected key is output in your R console

# API_URL <- "https://api.openai.com/v1/engines/davinci-codex/completions"
MODEL <- "text-davinci-003"
PROMPT <- "The following string, enclosed in triple quotations, contains an approved rezoning application.
Identify tax parcel ID, size, vote, and final zoning classification. Format your response as an R dictionary:
c(ParcelID = '', Size = '', VotesFor = , VotesAgainst = , FinalZone = ''). No context."


s <- create_completion(
    model = MODEL,
    prompt = paste0(PROMPT, "'''", pdf_text[1], "'''"),
    max_tokens = 500
)
