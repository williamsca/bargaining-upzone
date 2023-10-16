rm(list = ls())

library(here)
library(data.table)
library(sf)
library(ggplot2)
library(tigris)

v_palette <- c("#D55E00", "#0072B2", "#F0E460", "#009E73")

PANEL_START <- 2010
PANEL_END <- 2021

# Import ----
sf_va <- counties(cb = TRUE, resolution = "20m", class = "sf",
                  state = "VA", year = 2019)

dt <- readRDS(here("derived", "sample.Rds"))

# Treatment indicators ----
dt[, cp_share_local := rev_cp / rev_loc]
INTENSITY_THRESHOLD <- mean(dt[FY == 2016, cp_share_local], na.rm = TRUE)

dt[FY == 2016 & cp_share_local >= INTENSITY_THRESHOLD, high_proffer := 1]
dt[FY == 2016 & between(cp_share_local, 0, INTENSITY_THRESHOLD,
    incbounds = FALSE
), low_proffer := 1]
dt[FY == 2016 & cp_share_local == 0, no_proffer := 1]

dt[is.na(high_proffer), high_proffer := 0]
dt[is.na(low_proffer), low_proffer := 0]
dt[is.na(no_proffer), no_proffer := 0]

dt[, high_proffer := max(high_proffer), by = FIPS]
dt[, low_proffer := max(low_proffer), by = FIPS]
dt[, no_proffer := max(no_proffer), by = FIPS]

dt[, group := fifelse(
    high_proffer == 1, "High Proffer",
    fifelse(low_proffer == 1, "Low Proffer", "No Proffer")
)]

dt[, Post := fifelse(Date >= ymd("2016-07-01"), 1, 0)]
dt[, State := substr(FIPS, 1, 2)]

# Total units in multi-family buildings
dt[, Units2p := Units2 + `Units3-4` + `Units5+`]

# Fiscal year aggregation
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
dt_fy[, `:=`(
    rev_loc_pc = rev_loc / PCT001001,
    rev_cp_pc = rev_cp / PCT001001
)]

# TRUE --> data are unique on FIPS and quarter
nrow(dt_fy) == uniqueN(dt_fy[, .(FIPS, FY)])

# Identify counties in balanced panel ----
dt_va <- dt_fy[!is.na(ZHVI) & between(FY, PANEL_START, PANEL_END)]
dt_va[, nObs := .N, by = .(FIPS)]
dt_va <- dt_va[State == "51" & nObs == max(nObs)]

dt_va <- merge(dt_va, sf_va, by.x = "FIPS", by.y = "GEOID")

table(dt_va$group)


# Maps ----
# * Virginia ----
ggplot(sf.dist) +
    geom_sf(aes(fill = as.factor(everElec))) +
    scale_fill_manual(values = v.palette, labels = c("0", ">= 1")) +
    labs(fill = "Bond Elections") +
    theme(
        axis.text.x = element_blank(), axis.text.y = element_blank(),
        axis.ticks.x = element_blank(), axis.ticks.y = element_blank(),
        panel.background = element_blank(), text = element_text(size = 14)
    )
