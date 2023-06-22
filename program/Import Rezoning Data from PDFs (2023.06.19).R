rm(list = ls())

pacman::p_load(data.table, pdftools, openai, here)

file <- "ZMA201100010 Approval - County 2012-09-25.pdf"
# Read 'Approval' PDFs as strings
l_approvals <- list.files(
    path = "data/Albemarle ZMAs",
    pattern = "*Approv*", full.names = TRUE, recursive = TRUE
)

# Sys.setenv(OPENAI_API_KEY = "")
readRenviron("~/.Renviron") # Reload .Renviron
Sys.getenv("OPENAI_API_KEY") # Check to see that the expected key is output in your R console

# API_URL <- "https://api.openai.com/v1/engines/davinci-codex/completions"
MODEL <- "text-davinci-003"
PROMPT <- "The following string, enclosed in triple quotations, contains an approved rezoning application. 
Identify tax parcel ID, size, vote, and final zoning classification. Format your response as an R dictionary: 
c(ParcelID = '', Size = '', VotesFor = , VotesAgainst = , FinalZone = ''). No context."

# Read PDF as string
pdf_text <- trimws(pdf_text(paste0(dir, "/data/Albemarle ZMAs/", file)))

s <- create_completion(model = MODEL,
                       prompt = paste0(PROMPT, "'''", pdf_text[1], "'''"),
                       max_tokens = 500)

