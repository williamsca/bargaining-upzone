# This script parses the Hanover County minutes
# into a CSV file for further manual processing.

rm(list = ls())
library(here)
library(data.table)
library(pdftools)
library(units)

# Read in PDFs
l_minutes <- list.files(here("data", "HanoverCo", "BoS Minutes"),
    pattern = "pdf", full.names = TRUE, recursive = TRUE
)


