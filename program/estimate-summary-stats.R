rm(list = ls())

library(data.table)
library(stargazer)
library(ggplot2)
library(lubridate)
library(here)

dt <- readRDS("derived/sample.Rds")

dt_app <- readRDS(here("derived", "county-rezonings.Rds"))

arcsinh <- function(x) log(x + sqrt(x^2 + 1))

# Exclude Fairfax, Loudoun for partial exemption
# dt <- dt[!(FIPS %in% c("51059", "51107"))]

# Proffer Covariates ----
dt_prof <- dt_app[!is.na(res_cash_proffer) & isApproved == TRUE & n_units > 5]
lm_prof <- 


# Treatment indicators ----
dt[, cp_share_local := rev_cp / rev_loc]

INTENSITY_THRESHOLD <- mean(dt$cp_share_local, na.rm = TRUE)

dt[FY == 2016, everTreated := fifelse(
    cp_share_local > INTENSITY_THRESHOLD, 1, 0
)]

dt[is.na(everTreated), everTreated := 0]
dt[, everTreated := max(everTreated), by = FIPS]

dt[, Post := fifelse(Date >= ymd("2016-07-01"), 1, 0)]
dt[, State := substr(FIPS, 1, 2)]

# Total units in multi-family buildings
dt[, Units2p := Units2 + `Units3-4` + `Units5+`]

dt_qtr <- dt[, .(
    Units1 = sum(Units1), Units2p = sum(Units2p),
    ZHVI = mean(ZHVI), n_units = sum(n_units)
),
by = .(FIPS, PCT001001, State,
    Date = quarter(Date, type = "date_first"), rev_cp,
    everTreated, Post, FY
)
]

# TRUE --> data are unique on FIPS and quarter
nrow(dt_qtr) == uniqueN(dt_qtr[, .(FIPS, Date)])

# HPI Trends
v_counties <- unique(dt[!is.na(n_units), FIPS])

dt[, ZHVI_base := max(ZHVI * (Date == ymd("2012-07-01")), na.rm = TRUE),
    by = FIPS]
dt[, ZHVI_index := ZHVI / ZHVI_base * 100]

ggplot(dt[FIPS %in% v_counties & FY %between% c(2013, 2019)],
       aes(x = Date, y = ZHVI_index, color = Name)) +
    geom_line() +
    theme_light() +
    theme()

# Approved Units vs Building Permits
dt[, Units1p := Units1 + Units2 + `Units3-4` + `Units5+`]

dt[!is.na(n_units), firstObs := min(year(Date)), by = FIPS]
dt[, firstObs := max(firstObs, na.rm = TRUE), by = FIPS]
dt[year(Date) >= firstObs & !is.infinite(firstObs) & is.na(n_units),
    n_units := 0]
View(dt[!is.infinite(firstObs)])

dt_units <- melt(dt[FIPS %in% v_counties],
    id.vars = c("FIPS", "Date", "FY", "Name", "State", "firstObs"),
    measure.vars = c("Units1p", "n_units"), variable.name = "Measure",
    value.name = "Units"
)

dt_units[Measure == "Units1p", Measure := "Permitted Units"]
dt_units[Measure == "n_units", Measure := "Rezoned Units"]

dt_units <- dt_units[, .(Units = sum(Units)), by = .(FIPS, FY, Name,
    State, Measure)]

ggplot(dt_units[FY %between% c(2013, 2019)],
       aes(x = FY, y = Units, color = Measure)) +
    geom_line() +
    facet_wrap(~ Name, ncol = 2) +
    theme_light() +
    theme()


# Summary statistics by treatment status ----
dt_fig1 <- dt[everTreated == 1 & Units1 <= 400]
ggplot(dt_fig1, aes(x = Units1)) +
    geom_histogram() +
    scale_x_continuous() +
    labs(
        title = "Distribution of Monthly Building Permits: Treated Counties",
        subtitle = paste0(
            min(year(dt_fig1$Date)), " - ",
            max(year(dt_fig1$Date))
        ),
        x = "Single-Unit Permits", y = "Frequency",
        caption = paste0(
            "Permits censored at ", max(dt_fig1$Units1),
            ". N = ", nrow(dt_fig1), ""
        )
    ) +
    theme_light() +
    theme(plot.caption = element_text(hjust = 0))
# ggsave("", device = "pdf")
