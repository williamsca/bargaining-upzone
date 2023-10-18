# This script uses the OpenAI API to extract details about residential
# rezonings from the Chesterfield Board of Supervisor's meeting minutes.

rm(list = ls())
library(here)
library(data.table)
library(openai)
library(pdftools)
library(tesseract)
library(stringr)

# Sys.setenv(OPENAI_API_KEY = "")
Sys.getenv("OPENAI_API_KEY")
MODEL <- "gpt-3.5-turbo"

# Import PDFs ----
l_files <- list.files(here("data", "ChesterfieldCo", "BoS Minutes"),
    recursive = TRUE, full.names = TRUE
)

file_path <- l_files[4]

pdf_text <- pdf_text(file_path)
pdf_text <- gsub("\\s{2,}", " ", pdf_text)

pdf_lines <- unlist(str_split(pdf_text, pattern = "\n"))

# Filter to relevant section of minutes
row_start <- grep("16. Requests", pdf_lines, ignore.case = TRUE)
row_end <- max(grep("19. ", pdf_lines, ignore.case = TRUE))

pdf_lines <- pdf_lines[row_start:row_end]

# Group lines by zoning case
line <- grep("In.*Magisterial.*District", pdf_lines, ignore.case = TRUE)

l_cases <- lapply(seq(1, length(line) - 1),
                  function(x) pdf_lines[line[x]:line[x + 1]])

# Combine each case into a single string
l_cases <- lapply(l_cases, paste0, collapse = " ")

# TODO: Divide long cases into smaller chunks
l_cases <- lapply(l_cases, function(x) {
    if (nchar(x) > 4000) {
        l_chunks <- str_split(x, pattern = "\\. ")
        l_chunks <- lapply(l_chunks, paste0, collapse = ". ")
        return(l_chunks)
    } else {
        return(x)
    }
})

# Extract details using OpenAI API ----
pr_open <- "The following string contains the minutes of a county board's zoning case. "
pr_main <-  "Identify the Case ID, case type (e.g., rezoning, conditional use permit, etc.), and outcome. "
pr_end <- "Limit your response to the requested information delimited by commas. If you are unsure about a value, respond with NA.\""

initial_scan <- function(case_text) {
    messages <- list(
        list(role = "system", content = pr_open),
        list(role = "user", content = paste(pr_main, pr_end, sep = " ")),
        list(role = "user", content = case_text)
    )

    return(create_chat_completion(
        model = MODEL, messages = messages,
        max_tokens = 1500, temperature = 0
    ))
}

l_results <- lapply(l_cases, initial_scan)
