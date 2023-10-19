# This script uses the OpenAI API to extract details about residential
# rezonings from the Chesterfield Board of Supervisor's meeting minutes.

rm(list = ls())
library(here)
library(data.table)
library(openai)
library(pdftools)
library(tesseract)
library(stringr)
library(lubridate)

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
pdf_text <- gsub("\n", " ", pdf_text)

pdf_lines <- unlist(str_split(pdf_text, pattern = "\\. "))

# Group lines by zoning case
line <- grep("In.*Magisterial.*District", pdf_lines, ignore.case = TRUE)
end_line <- max(grep("CITIZEN\\s+COMMENT", pdf_lines, ignore.case = TRUE))
line <- c(line, end_line)

l_cases <- lapply(seq(1, length(line) - 1),
                  function(x) pdf_lines[line[x]:line[x + 1] - 1])

# Combine each case into a single string
l_cases <- lapply(l_cases, paste0, collapse = ". ")

# Extract details using OpenAI API ----
pr_open <- "The following string contains the minutes of a county board's zoning case. "
pr_main <-  "Identify the Case ID, case type (e.g., rezoning, conditional use permit, etc.), and outcome. "
pr_end <- "Limit your response to the requested information delimited by commas (e.g., XXREZ2023,Amendment,Approved). If you are unsure about a value, respond with NA.\""

# Scan the first part of the case minutes to determine if
# further parsing is warranted
max_length <- 3500
initial_scan <- function(case_text) {
    messages <- list(
        list(role = "system", content = pr_open),
        list(role = "user", content = paste(pr_main, pr_end, sep = " ")),
        list(role = "user", content = substr(case_text, 1, max_length))
    )

    return(create_chat_completion(
        model = MODEL, messages = messages,
        max_tokens = 500, temperature = 0
    ))
}

l_results <- lapply(l_cases, initial_scan)
l_messages <- sapply(l_results, function(x) x$choices$message.content)

dt <- data.table(
    case_text = l_cases,
    gpt_response = l_messages,
    date = ymd(str_extract(file_path, "\\d{4}-\\d{2}-\\d{2}"))
)

# TODO: parse GPT response


# Superseded ----
# Filter to relevant section of minutes
row_start <- grep("REQUEST", pdf_lines, fixed = TRUE)
row_end <- max(grep("19. ", pdf_lines, ignore.case = TRUE))

pdf_lines <- pdf_lines[row_start:row_end]
