# This file parses the Rezoning Resolutions made by the
# Frederick County Board of Supervisors.

rm(list = ls())
pacman::p_load(here, data.table, pdftools, stringr, lubridate, tesseract)

l_files <- list.files("data/FrederickCo/Resolutions",
    pattern = "*.pdf",
    full.names = TRUE, recursive = TRUE
)

pdf_bitmap <- pdf_convert(l_files[3])

pdf_text <- pdf_text(l_files[3])
pdf_lines <- unlist(str_split(pdf_text, pattern = "\n"))

pdf_lines[1:100]

pdf_text[112]

pdf_text[grepl("Denied", pdf_text)]

pdf_text[1:3]

length(pdf_text)
