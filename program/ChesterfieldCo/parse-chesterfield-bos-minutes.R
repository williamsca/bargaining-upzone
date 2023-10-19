# This script uses the OpenAI API to extract details about residential
# rezonings from the Chesterfield Board of Supervisor's meeting minutes.

rm(list = ls())
library(here)
library(data.table)
library(openai)
library(pdftools)
library(stringr)
library(lubridate)

Sys.getenv("OPENAI_API_KEY")
MODEL <- "gpt-3.5-turbo"
max_length <- 3500

# Import PDFs ----
l_files <- list.files(here("data", "ChesterfieldCo", "BoS Minutes"),
    recursive = TRUE, full.names = TRUE
)

# Extract zoning cases ----
extract_cases <- function(file_path) {
    pdf_text <- pdf_text(file_path)
    pdf_text <- gsub("\\s{2,}", " ", pdf_text)
    pdf_text <- gsub("\n", " ", pdf_text)

    pdf_lines <- unlist(str_split(pdf_text, pattern = "\\. "))

    # Group lines by zoning case
    line <- grep("In.*Magisterial.*District", pdf_lines,
                 ignore.case = TRUE)
    end_line <- max(grep("CITIZEN\\s+COMMENT", pdf_lines,
                    ignore.case = TRUE), length(pdf_lines))

    if (length(line) > 0) {
        line <- c(line, end_line)

        l_cases <- lapply(
            seq(1, length(line) - 1),
            function(x) pdf_lines[line[x]:line[x + 1] - 1]
        )
        # Combine each case into a single string
        l_cases <- lapply(l_cases, paste0, collapse = ". ")
    } else {
        l_cases <- list()
    }
    return(l_cases)
}

# Extract details using OpenAI API ----
pr_open <- "The following string has been extracted from county government minutes. "
pr_main <- "If the text describes a zoning case, identify the Case ID, case type (e.g., rezoning, conditional use permit, etc.), and outcome. "
pr_end <- "Limit your response to the requested information delimited by commas (e.g., XXREZ2023,Amendment,Approved). If you are unsure about a particular value, respond with 'NA' for that entry. If the text does not describe a zoning case, respond with 'Not relevant'.\""

# Scan the first part of the case minutes to determine if
# further parsing is warranted
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

# Loop over files ----
if (!file.exists(here("derived", "ChesterfieldCo", "bos-minutes.Rds"))) {
    l_dt <- list()
    for (i in seq_along(l_files)) {
        l_cases <- extract_cases(l_files[i])

        if (length(l_cases) > 0) {
            l_results <- lapply(l_cases, initial_scan)
            l_messages <- sapply(l_results,
                function(x) x$choices$message.content)

            if (grepl("2018", l_files[i])) {
                date = mdy(str_extract(l_files[i], "\\d{8}"))
            } else {
                date = ymd(str_extract(l_files[i], "\\d{4}-\\d{2}-\\d{2}"))
            }

            dt <- data.table(
                case_text = l_cases,
                gpt_response = l_messages,
                final_date = date
            )
        } else {
            dt <- data.table()
        }

        l_dt[[i]] <- dt

        Sys.sleep(60)
    }

    dt <- rbindlist(l_dt)

    v_cols <- c("Case.Number", "Case.Type", "Status")
    dt[
        str_count(gpt_response, pattern = ",") == 2,
        (v_cols) := tstrsplit(gpt_response, ",")
    ]

    dt[, (v_cols) := lapply(.SD, trimws), .SDcols = v_cols]

    # Status
    dt[grepl("Remanded", Status), Status := "Remanded"]
    dt[grepl("Not relevant", Status), Status := NA]
    dt[grepl("NA|Amendment", Status), Status := NA]
    table(dt$Status)

    # Case Type
    dt[
        grepl("Rezoning", Case.Type, ignore.case = TRUE),
        Case.Type := "Rezoning"
    ]
    dt[
        grepl("Amendment", Case.Type, ignore.case = TRUE),
        Case.Type := "Amendment"
    ]
    dt[
        grepl("Conditional", Case.Type, ignore.case = TRUE),
        Case.Type := "Conditional Use Permit"
    ]
    dt[
        !(Case.Type %in% c("Rezoning", "Amendment",
                           "Conditional Use Permit")),
        Case.Type := "Other"
    ]

    # Save ----
    saveRDS(dt, here("derived", "ChesterfieldCo", "bos-minutes.Rds"))

}

# Import ----
dt <- readRDS(here("derived", "ChesterfieldCo", "bos-minutes.Rds"))

# Filter to approved or denied rezonings
dt <- dt[Case.Type == "Rezoning" & Status != "Deferred"]

uniqueN(dt$Case.Number) == nrow(dt)

nchar(dt$case_text)

# Extract more details about rezoning cases ----
# Zoning codes, acreages, and housing units
prompt <- "The following string describes an approved rezoning case. Identify the following details: former zoning code(s), new zoning code(s), parcel acreage, and a short description of the proposed change which includes the number and type of housing units that would be built, if any. Limit your response to the requested information delimited by pipes (e.g., A-1|R-3|33.5 acres|Rezoning from agricultural to low-density residential will allow 40 single-family detached units and 5 affordable townhouses). If you cannot find a particular detail, respond with 'NA' for that entry."

rezoning_details <- function(case_text) {
    messages <- list(
        list(role = "system", content = prompt),
        list(role = "user", content = substr(case_text, 1, max_length))
    )

    return(create_chat_completion(
        model = MODEL, messages = messages,
        max_tokens = 500, temperature = 0
    ))
}

l_details <- list()
for (i in seq_along(dt$case_text)) {
    message <- rezoning_details(dt$case_text[i])
    l_details[[i]] <- message$choices$message.content

    Sys.sleep(5)
}

dt$parcel_details <- l_details

v_details <- c("zoning_old", "zoning_new", "acres", "n_units_desc")
dt[
    str_count(parcel_details, pattern = "\\|") == 3,
    (v_details) := tstrsplit(parcel_details, "\\|")
]

# This data will be re-written after I've ironed out the
# cash proffer detail parsing section
saveRDS(dt, here("derived", "ChesterfieldCo", "bos-minutes-rezonings.Rds"))

dt <- readRDS(here("derived", "ChesterfieldCo", "bos-minutes-rezonings.Rds"))

# Cash proffer details
# This prompt fails to return anything at all. Need to identify cases with
# proffers and experiment with the language. There may be an issue
# related to chunking the case into smaller pieces to fit into the
# context window.
prompt_proffer <- "The following string describes an approved rezoning case. Provide a brief summary of any cash proffer contributions made by the developer. If no cash proffers are described in the passage, respond with an empty string."

proffer_details <- function(case_text) {

    # Break the case text into chunks of roughly max_length
    # characters and start each chunk at a new sentence.
    start_pos <- seq(1, nchar(case_text), max_length)
    sentence_pos <- unlist(gregexpr("\\. ", case_text))

    for (i in seq_along(start_pos)) {
        tmp <- sentence_pos[sentence_pos < start_pos[i]]
        start_pos[i] <- ifelse(length(tmp) == 0, 1, max(tmp))
    }

    case_text_chunks <- substring(
        case_text, start_pos,
        start_pos + max_length - 1
    )

    response <- ""
    for (chunk in case_text_chunks) {
        messages <- list(
            list(role = "system", content = prompt_proffer),
            list(role = "user", content = chunk)
        )

        s <- create_chat_completion(
            model = MODEL, messages = messages,
            max_tokens = 500, temperature = 0
        )

        response <- paste(response, s$choices$message.content, sep = "")
    }
}

l_proffers <- list()
for (i in seq_along(dt$case_text)) {
    l_proffers[[i]] <- proffer_details(dt$case_text[i])

    Sys.sleep(5)
}
