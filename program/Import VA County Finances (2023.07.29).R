# Raw financedata files downloaded on 7/29/2023 from:
# https://www.apa.virginia.gov/APA_Reports/LG_ComparativeReports.aspx

# Cash Proffer Reports from LIS website and email:
# https://rga.lis.virginia.gov/Published/

rm(list = ls())
pacman::p_load(here, data.table, readxl)

pacman::p_load(data.table, pdftools, readxl)

YEAR_MIN <- 2004
YEAR_MAX <- 2022

CONSTANT_YEAR <- 2015

dt_cpi <- as.data.table(read_xlsx(
    "crosswalks/CPI/CUUR0000SA0 CPI-U (1995-2022).xlsx",
    skip = 10
))

# Parse Cash Proffer Reports ----
l.files <- paste0(
    "data/DHCD Cash Proffer Reports/Proffer Report FY",
    YEAR_MIN:YEAR_MAX, ".pdf"
)

GetAppendixD <- function(path) {
    txt <- pdf_text(path)
    return(txt[max(grep("Summary of Survey Responses from Localities", txt))])
}

l.pdf <- lapply(l.files, GetAppendixD)

ParseAppendixD <- function(fy, pdf_list) {
    if (fy <= 2021) {
        lines <- strsplit(unlist(l.pdf[grep(paste0(
            "Fiscal Year ", fy - 1, ".", fy
        ), pdf_list, ignore.case = TRUE)]), "\n")[[1]]
    } else { # format changes in 2022
        lines <- strsplit(unlist(l.pdf[grep(paste0(
            "Fiscal Year ", fy
        ), pdf_list, ignore.case = TRUE)]), "\n")[[1]]
    }

    lines <- trimws(gsub("\\$|,", "", lines))
    lines <- lines[lines != ""]

    # Split each line into parts
    parts <- strsplit(lines, "\\s{2,}")

    # Some lines have extra line breaks -->
    # filter to lines with more than one entry
    parts <- parts[unlist(lapply(parts, length)) >= 2]

    dt <- data.table(
        Locality = unlist(lapply(parts, "[[", 1)),
        `Cash Proffer Revenue` = lapply(parts, "[[", 2),
        FY = fy
    )

    # Convert columns to numeric
    dt[, `Cash Proffer Revenue` := as.numeric(gsub(
        "[- ]", "",
        `Cash Proffer Revenue`
    ))]

    return(dt)
}

dt_cp <- rbindlist(lapply(YEAR_MIN:YEAR_MAX, ParseAppendixD, l.pdf))
dt_cp <- dt_cp[!is.na(`Cash Proffer Revenue`) & !grepl("[0-9]", Locality)]

# Clean Locality field
dt_cp[grepl("Fairfax", Locality), Locality := "Fairfax"]
dt_cp[Locality == "Isle o f Wight", Locality := "Isle of Wight"]
dt_cp[Locality == "M anassas P ark", Locality := "Manassas Park"]
dt_cp[Locality == "P rince William", Locality := "Prince William"]
dt_cp[Locality == "Go o chland", Locality := "Goochland"]
dt_cp[, Locality := sub("\\&", "and", Locality)]

dt_cp[
    !grepl("and|of|City|King|Park|Prince|Gap|New|Beach", Locality),
    Locality := gsub(" ", "", Locality)
]

# Tag counties, cities, and towns
dt_cp[, locality_type := ifelse(.I == min(.I), 2, NA), by = FY]
dt_cp[grepl("Counties", Locality, ignore.case = TRUE), locality_type := 1]
dt_cp[grepl("Cities", Locality, ignore.case = TRUE), locality_type := 3]
dt_cp[, locality_type := nafill(locality_type, type = "locf")]

dt_cp[locality_type == 1, Name := paste0(Locality, " City")]
dt_cp[locality_type == 2, Name := paste0(Locality, " County")]
dt_cp[locality_type == 3, Name := paste0(Locality, " Town")]
# TODO: aggregate towns within counties?

# * Sanity checks ----
dt_cp[, `Grand Total` := sum(`Cash Proffer Revenue` *
    (!grepl("Total", Locality, ignore.case = TRUE))),
by = FY
]

# TRUE --> summing all rows matches with reported grand total
nrow(dt_cp[grepl("Grand", Locality, ignore.case = TRUE) &
    abs(`Cash Proffer Revenue` - `Grand Total`) > 2]) == 0

dt_cp <- dt_cp[!grepl("T ?o ?t ?a ?l", Locality, ignore.case = TRUE) &
    !is.na(Name)]

# Parse County Finances ----
l_files <- list.files("data/County Finances", full.names = TRUE,
    pattern = "*.xls"
)

ImportRevenue <- function(file_path) {
    dt <- as.data.table(read_excel(file_path, sheet = "Exhibit A",
        skip = 10)
    )

    dt[, FY := as.numeric(gsub("[^0-9]", "", file_path)) + 2000]

    dt[grepl("City", `...4`) | Locality == "Alexandria",
        locality_type := 1]
    dt[grepl("County", `...4`) | Locality == "Accomack",
        locality_type := 2]
    dt[grepl("Town", `...4`) | Locality == "Abingdon",
        locality_type := 3]
    dt[, locality_type := nafill(locality_type, "locf")]

    v_revenues <- c("Local Revenue", "Total Revenue")
    setnames(dt, c("Amount...7", "Revenue"), v_revenues)

    dt[locality_type == 1, Name := paste0(Locality, " City")]
    dt[locality_type == 2, Name := paste0(Locality, " County")]
    dt[locality_type == 3, Name := paste0(Locality, " Town")]

    dt[, (v_revenues) := lapply(.SD, as.numeric), .SDcols = v_revenues]

    dt <- dt[
        !is.na(`Total Revenue`) & !grepl("Total", Locality),
        .(FY, Name, locality_type, `Total Revenue`, `Local Revenue`)
    ]

    return(dt)
}

dt_rev <- rbindlist(lapply(l_files, ImportRevenue))

# * Sanity Checks ----
# TRUE --> Total revenues always exceed local revenues
nrow(dt_rev[`Total Revenue` < `Local Revenue`]) == 0

# TRUE --> Data are unique by FY and Locality
nrow(dt_rev) == uniqueN(dt_rev[, .(FY, Name)])

# Merge ----
dt_rev[Name == "King & Queen County", Name := "King and Queen County"]

dt <- merge(dt_cp[, .(FY, Name, `Cash Proffer Revenue`, locality_type)],
    dt_rev, by = c("FY", "Name", "locality_type"), all = TRUE
)

# TRUE --> all cash proffer revenue is matched
nrow(dt[FY %between% c(2014, 2016) & `Cash Proffer Revenue` > 0 &
    is.na(`Total Revenue`)]
) == 0
nrow(dt[is.na(Name)]) == 0
nrow(dt) == uniqueN(dt[, .(FY, Name)])

dt[, FIPS.Code.State := "51"]

dt[is.na(`Cash Proffer Revenue`), `Cash Proffer Revenue` := 0]

# Deflate to constant-year dollars
dt_cpi[, Annual := Annual / dt_cpi[Year == CONSTANT_YEAR, Annual]]
dt <- merge(dt, dt_cpi[, .(Year, Annual)],
    by.x = c("FY"),
    by.y = c("Year"), all.x = TRUE
)
nrow(dt[is.na(Annual)]) == 0

v_dollars <- grep("Revenue", names(dt), value = TRUE)
dt[, (v_dollars) := lapply(.SD, "/", Annual), .SDcols = v_dollars]

# Save ----
saveRDS(dt, paste0("derived/Revenues (",
    paste(range(dt$FY), collapse = "-"), ").Rds")
)
