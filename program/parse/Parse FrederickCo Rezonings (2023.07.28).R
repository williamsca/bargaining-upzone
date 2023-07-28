# This file parses the Rezoning Resolutions made by the
# Frederick County Board of Supervisors.

rm(list = ls())
pacman::p_load(here, data.table, pdftools, stringr, lubridate)

l_files <- list.files("data/FrederickCo/Resolutions",
    pattern = "*.pdf",
    full.names = TRUE, recursive = TRUE
)

