rm(list = ls())

pacman::p_load(data.table, pdftools, openai, here, lubridate)

# Read Files ----
l_files <- list.files(
    path = "data/Albemarle ZMAs",
    pattern = "*.pdf", full.names = TRUE, recursive = TRUE
)

# extract the text between the second and third '/' in each file path
c_zmas <- sapply(strsplit(l_files, "/"), "[", 4)
c_names <- sapply(strsplit(l_files, "/"), "[", 5)

dt <- data.table(
    ZMA = c_zmas,
    Paths = l_files,
    File = c_names
)

nrow(dt[is.na(File)]) == 0 # TRUE --> paths are all valid

# NOTE: these dates can conflict with the dates in the underlying PDF
dt[regexpr("\\b\\d{4}-", File) > 0, Date := ymd(substr(
    File, regexpr("\\b\\d{4}-", File),
    regexpr("\\b\\d{4}", File) + 9
), truncated = 1)]

dt[, isApproved := max(regexpr("Approv", File) > 0), by = ZMA]

dt[, appLength := max(Date, na.rm = TRUE) - min(Date, na.rm = TRUE),
    by = ZMA
]

# Read PDFs ----

# Identify ordinances
HasOrdinance <- function(file) {
    pdf_text <- pdf_text(file)
    return(max(regexpr("ORDINANCE", pdf_text, ignore.case = TRUE) > 0))
}

dt$isOrdinance <- sapply(dt$Paths, HasOrdinance)



pdf_text <- trimws(pdf_text(paste0(dir, "/data/Albemarle ZMAs/", file)))

ggplot(data = dt, mapping = aes(x = Date)) +
    geom_histogram() +
    scale_x_date(limits = c(date("2014-01-01"), date("2020-01-01")))

# Sys.setenv(OPENAI_API_KEY = "")
readRenviron("~/.Renviron") # Reload .Renviron
Sys.getenv("OPENAI_API_KEY") # Check to see that the expected key is output in your R console

# API_URL <- "https://api.openai.com/v1/engines/davinci-codex/completions"
MODEL <- "text-davinci-003"
PROMPT <- "The following string, enclosed in triple quotations, contains an approved rezoning application. 
Identify tax parcel ID, size, vote, and final zoning classification. Format your response as an R dictionary: 
c(ParcelID = '', Size = '', VotesFor = , VotesAgainst = , FinalZone = ''). No context."


s <- create_completion(model = MODEL,
                       prompt = paste0(PROMPT, "'''", pdf_text[1], "'''"),
                       max_tokens = 500)

