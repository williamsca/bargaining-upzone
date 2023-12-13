rm(list = ls())

library(data.table)
library(fixest)
library(ggplot2)
library(lubridate)
library(here)
library(xtable)

dt <- readRDS("derived/sample.Rds")

dt_app <- readRDS(here("derived", "county-rezonings.Rds"))
dt_app[, density := n_units / Area]

v_palette <- c("#D55E00", "#0072B2", "#009E73", "#F0E460")

# Exclude Fairfax, Loudoun for partial exemption
# dt <- dt[!(FIPS %in% c("51059", "51107"))]

# Treatment indicators ----
dt[, cp_share_local := rev_cp / rev_loc]
INTENSITY_THRESHOLD <- mean(dt[FY == 2016, cp_share_local], na.rm = TRUE)

dt[FY == 2016 & cp_share_local >= INTENSITY_THRESHOLD, high_proffer := 1]
dt[FY == 2016 & between(cp_share_local, 0, INTENSITY_THRESHOLD,
    incbounds = FALSE), low_proffer := 1]
dt[FY == 2016 & cp_share_local == 0, no_proffer := 1]

dt[is.na(high_proffer), high_proffer := 0]
dt[is.na(low_proffer), low_proffer := 0]
dt[is.na(no_proffer), no_proffer := 0]

dt[, high_proffer := max(high_proffer), by = FIPS]
dt[, low_proffer := max(low_proffer), by = FIPS]
dt[, no_proffer := max(no_proffer), by = FIPS]

dt[, group := fifelse(high_proffer == 1, "High Proffer",
    fifelse(low_proffer == 1, "Low Proffer", "No Proffer"))]

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
    FIPS, PCT001001, State, rev_cp, rev_loc, group, Post, FY, high_proffer,
    low_proffer, no_proffer
)
]
dt_fy[, `:=`(rev_loc_pc = rev_loc / PCT001001,
    rev_cp_pc = rev_cp / PCT001001)]

# TRUE --> data are unique on FIPS and quarter
nrow(dt_fy) == uniqueN(dt_fy[, .(FIPS, FY)])

# Summary statistics ----
# TODO: can make this more robust by passing a vector of variables
# and using lapply plus .SD to compute means and std deviations
dt_tab1 <- dt_fy[!is.na(ZHVI) & between(FY, 2010, 2021)]
dt_tab1[, nObs := .N, by = .(FIPS)]
dt_tab1[, `:=`(cum_units1 = cumsum(Units1), cum_units2 = cumsum(Units2p)),
        by = FIPS]
dt_tab1 <- dt_tab1[State == "51" & nObs == max(nObs) & FY == 2016]

nrow(dt_tab1[high_proffer + no_proffer + low_proffer == 0]) == 0

dt_tab1 <- dt_tab1[, .(
        `Local Revenue ($/capita)` = mean(rev_loc_pc),
        `Proffer Revenue ($/capita)` = mean(rev_cp_pc),
        `Single-Family Permits Per Thousand (2010-2016)` = mean(1000 * Units1 / PCT001001),
        `Multi-Family Permits Per Thousand (2010-2016)` = mean(1000 * Units2p / PCT001001),
        `Zillow HVI ($)` = mean(ZHVI, na.rm = TRUE),
        `HPI (2000 = 100)` = mean(HPI),
        `Population` = mean(PCT001001),
        `Number of Counties` = uniqueN(FIPS),
        `sd_loc_rev_pc` = sd(rev_loc_pc),
        `sd_rev_cp_pc` = sd(rev_cp_pc),
        `sd_units1` = sd(1000 * Units1 / PCT001001),
        `sd_units2p` = sd(1000 * Units2p / PCT001001),
        `sd_zhvi` = sd(ZHVI, na.rm = TRUE),
        `sd_hpi` = sd(HPI),
        `sd_pop2010` = sd(PCT001001)
    ),
    by = group
]

dt_tab1 <- dcast(melt(dt_tab1, id.vars = c("group"),
    measure.vars = c(
        "Number of Counties",
        "Population", "sd_pop2010",
        "Zillow HVI ($)", "sd_zhvi",
        "HPI (2000 = 100)", "sd_hpi",
        "Local Revenue ($/capita)", "sd_loc_rev_pc",
        "Proffer Revenue ($/capita)", "sd_rev_cp_pc",
        "Single-Family Permits Per Thousand (2010-2016)", "sd_units1",
        "Multi-Family Permits Per Thousand (2010-2016)", "sd_units2p"
    )), variable ~ group,
    value.var = "value"
)

setnames(dt_tab1, c("Variable", "High Proffer", "Low Proffer",
                    "No Proffer"))

v_sum <- c("High Proffer", "Low Proffer", "No Proffer")
dt_tab1[, (v_sum) := lapply(.SD, function(x) formatC(
    x, format = "f", big.mark = ",", digits = 0)
), .SDcols = v_sum]

dt_tab1[, (v_sum) := lapply(.SD, as.character), .SDcols = v_sum]

dt_tab1[grepl("sd", Variable), (v_sum) := lapply(.SD, function(x) paste0(
    "(", x, ")")), .SDcols = v_sum
]

dt_tab1[grepl("sd", Variable), Variable := ""]

xtab1 <- xtable(dt_tab1, digits = 0, caption = "Summary Statistics")
print.xtable(xtab1, type = "html", file = here("paper", "tables", "tab1.html"),
             include.rownames = FALSE)

# Proffers ----
dt_prof <- dt_app[!is.na(res_cash_proffer) & n_units > 0 & !isExempt]
dt_prof[, tot_proffer := res_cash_proffer * n_units]
v_units <- c(
    "n_sfa", "n_mfd", "n_unknown", "n_age_restrict",
    "n_affordable"
)
v_shares <- gsub("n_", "share_", v_units)
dt_prof[, (v_shares) := lapply(.SD, function(x) x / n_units), .SDcols = v_units]


# Scatterplots
ggplot(dt_prof[FIPS != "51177" & n_age_restrict == 0],
       aes(x = final_date, y = res_cash_proffer)) +
    geom_point(aes(size = n_units), color = v_palette[2]) +
    theme_light(base_size = 14) +
    geom_smooth(method = "lm", formula = y ~ x + I(x^2) + I(x^3), se = FALSE,
                aes(weight = n_units), color = v_palette[2], linetype = "dashed") +
    scale_color_manual(values = v_palette) +
    labs(y = "Cash Proffer\n($/unit)", x = "Approval Date",
         caption = "Note: Chart plots per-unit average cash proffer collected by Chesterfield, Goochland, and\nHanover Counties. Size of dot is proportional to the number of units allowed by the rezoning.\nDashed line shows a fitted 3rd order polynomial.") +
    theme(legend.position = "none", plot.caption = element_text(hjust = 0))
ggsave(here("paper", "figures", "plot_proffers.png"), width = 8, height = 4)

ggplot(dt_prof, aes(
    x = log(density),
    y = res_cash_proffer
)) +
    geom_point() +
    scale_x_continuous() +
    geom_smooth(method = "lm", formula = y ~ x + x^2)


# Regressions
# Note: sfd is omitted factor
v_rhs <- c("-1", v_shares, "FIPS")
fmla_prof <- as.formula(paste0("res_cash_proffer", " ~ ",
                       paste0(v_rhs, collapse = " + ")))
feols_prof <- feols(fmla_prof, dt_prof)
etable(feols_prof)



# TODO: in-kind value as % of total proffer value histogram

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
