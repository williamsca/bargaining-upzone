rm(list = ls())

library(data.table)
library(stargazer)
library(ggplot2)
library(lubridate)
library(here)

dt <- readRDS("derived/sample.Rds")

dt_app <- readRDS(here("derived", "county-rezonings.Rds"))
dt_app[, density := n_units / Area]

arcsinh <- function(x) log(x + sqrt(x^2 + 1))

# Exclude Fairfax, Loudoun for partial exemption
# dt <- dt[!(FIPS %in% c("51059", "51107"))]

# Treatment indicators ----
dt[, cp_share_local := rev_cp / rev_loc]

INTENSITY_THRESHOLD <- mean(dt[FY == 2016, cp_share_local], na.rm = TRUE)
# INTENSITY_THRESHOLD <- quantile(dt$cp_share_local, 0.8, na.rm = TRUE)

dt[FY == 2016, high_proffer := fifelse(
    cp_share_local > INTENSITY_THRESHOLD, 1, 0
)]
dt[FY == 2016, low_proffer := fifelse(
    cp_share_local <= INTENSITY_THRESHOLD & cp_share_local > 0, 1, 0
)]

dt[is.na(high_proffer), high_proffer := 0]
dt[is.na(low_proffer), low_proffer := 0]
dt[, high_proffer := max(high_proffer), by = FIPS]
dt[, low_proffer := max(low_proffer), by = FIPS]

dt[FY == 2016 & cp_share_local == 0, no_proffer := 1]
dt[is.na(no_proffer), no_proffer := 0]
dt[, no_proffer := max(no_proffer), by = FIPS]

dt[, Post := fifelse(Date >= ymd("2016-07-01"), 1, 0)]
dt[, State := substr(FIPS, 1, 2)]

# Total units in multi-family buildings
dt[, Units2p := Units2 + `Units3-4` + `Units5+`]

dt_fy <- dt[, .(
    Units1 = sum(Units1), Units2p = sum(Units2p), Units5 = sum(`Units5+`),
    ZHVI = mean(ZHVI), ZHVI_SFD = mean(ZHVI_SFD), n_units = sum(n_units),
    HPI = mean(HPI)
),
by = .(
    FIPS, PCT001001, State, rev_cp, rev_loc, high_proffer, Post, FY,
    no_proffer, low_proffer
)
]
dt_fy[, `:=`(rev_loc_pc = rev_loc / PCT001001,
    rev_cp_pc = rev_cp / PCT001001)]
dt_fy[, nObs := .N, by = .(FIPS)]

# TRUE --> data are unique on FIPS and quarter
nrow(dt_fy) == uniqueN(dt_fy[, .(FIPS, FY)])

# Summary statistics ----
dt_tab1 <- dt_fy[State == "51" & FY %between% c(2010, 2021) &
                 nObs == max(nObs)]

nrow(dt_tab1[high_proffer + no_proffer + low_proffer == 0]) == 0

dt_tab1 <- dt_tab1[, .(
    rev_loc_pc = mean(rev_loc_pc), rev_cp_pc = mean(rev_cp_pc),
    Units1 = mean(Units1), Units2p = mean(Units2p), Units5 = mean(Units5),
    ZHVI = mean(ZHVI, na.rm = TRUE), pop2010 = mean(PCT001001),
    ZHVI_SFD = mean(ZHVI_SFD, na.rm = TRUE)),
    by = .(high_proffer, no_proffer, low_proffer)
]

dt_tab1 <- dcast(melt(dt_tab1, id.vars = c(
        "high_proffer", "low_proffer", "no_proffer"
    ), measure.vars = c(
        "rev_loc_pc", "rev_cp_pc", "Units1", "Units2p",
        "Units5", "ZHVI", "ZHVI_SFD", "pop2010"
    )), variable ~ high_proffer + no_proffer + low_proffer,
    value.var = "value"
)

setnames(dt_tab1, c("Variable", "High Proffer", "Low Proffer",
                    "No Proffer"))

dt_tab1

# TODO: print prettily

# Proffer Regressions ----
# Proffer against density
# TODO: in-kind value as % of total proffer value histogram
dt_prof <- dt_app[!is.na(res_cash_proffer) &
    !is.na(density) & isApproved == TRUE & n_units > 5]

ggplot(dt_prof, aes(
    x = log(density),
    y = res_cash_proffer
)) +
    geom_point() +
    scale_x_continuous() +
    geom_smooth(method = "lm", formula = y ~ x + x^2)


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
