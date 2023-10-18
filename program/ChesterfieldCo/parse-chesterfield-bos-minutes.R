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
readRenviron("~/.Renviron") # Reload .Renviron
Sys.getenv("OPENAI_API_KEY") # Check to see that the expected key is output in your R console

# Import PDFs ----
l_files <- list.files(here("data", "ChesterfieldCo", "BoS Minutes"),
    recursive = TRUE, full.names = TRUE
)

file_path <- l_files[4]

pdf_text <- pdf_text(file_path)
pdf_text <- gsub("\\s{2,}", " ", pdf_text)

pdf_lines <- unlist(str_split(pdf_text, pattern = "\n"))

row_start <- grep("16. Requests", pdf_lines, ignore.case = TRUE)
row_end <- max(grep("19. ", pdf_lines, ignore.case = TRUE))

pdf_lines <- pdf_lines[row_start:row_end]

line <- grep("In.*Magisterial.*District", pdf_lines, ignore.case = TRUE)

v_cases <- seq(1, length(line) - 1)

l_cases <- lapply(v_cases, function(x) pdf_lines[line[x]:line[x + 1]])

# Combine relevant lines into a single string
l_cases <- lapply(l_cases, paste0, collapse = " ")
 