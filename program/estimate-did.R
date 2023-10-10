# Estimate the effect of the 2016 Proffer Reform Act on residential construction

# Reform goes into effect on July 1, 2016:
# https://www.williamsmullen.com/news/dissecting-proffer-reform-bill

rm(list = ls())

library(data.table)
library(fixest)
library(ggplot2)
library(lubridate)
library(here)

library(devtools)
devtools::install_github("synth-inference/synthdid")
library(synthdid)

dt <- readRDS("derived/sample.Rds")

# Treatment indicators ----
dt[, cp_share_local := rev_cp / rev_loc]

INTENSITY_THRESHOLD <- mean(dt$cp_share_local, na.rm = TRUE)
# INTENSITY_THRESHOLD <- quantile(dt$cp_share_local, 0.8, na.rm = TRUE)

dt[FY == 2016, everTreated := fifelse(
  cp_share_local > INTENSITY_THRESHOLD, 1, 0
)]

table(dt[everTreated == 1, Name])

dt[is.na(everTreated), everTreated := 0]
dt[, everTreated := max(everTreated), by = FIPS]

# Exclude Fairfax, Loudoun for partial exemption
# dt <- dt[!(FIPS %in% c("51059", "51107"))]

# Exclude untreated VA counties to avoid spillovers
dt[, notTreatedVA := (max(cp_share_local, na.rm = TRUE) == 0 &
                      FIPS.Code.State == "51"), by = FIPS]

table(dt[notTreatedVA == TRUE, Name])

dt[, Post := fifelse(Date >= ymd("2016-07-01"), 1, 0)]
dt[, State := substr(FIPS, 1, 2)]

# Total units in multi-family buildings
dt[, Units2p := Units2 + `Units3-4` + `Units5+`]

dt_qtr <- dt[, .(
  Units1 = sum(Units1), Units2p = sum(Units2p), Units5 = sum(`Units5+`),
  ZHVI = mean(ZHVI), ZHVI_SFD = mean(ZHVI_SFD), n_units = sum(n_units)
),
by = .(FIPS, PCT001001, State,
  Date = floor_date(Date, unit = "quarter"), rev_cp,
  everTreated, Post, FY)
]

dt_hy <- dt[, .(
  Units1 = sum(Units1), Units2p = sum(Units2p), Units5 = sum(`Units5+`),
  ZHVI = mean(ZHVI), ZHVI_SFD = mean(ZHVI_SFD), n_units = sum(n_units)
),
by = .(FIPS, PCT001001, State,
  Date = floor_date(Date, unit = "halfyear") + months(3), rev_cp,
  everTreated, Post, FY, notTreatedVA)]
dt_hy[, FY := FY - (month(Date) - 10) / 12]

dt_fy <- dt[, .(
  Units1 = sum(Units1), Units2p = sum(Units2p), Units5 = sum(`Units5+`),
  ZHVI = mean(ZHVI), ZHVI_SFD = mean(ZHVI_SFD), n_units = sum(n_units)
),
  by = .(FIPS, PCT001001, State, rev_cp, everTreated, Post, FY,
         notTreatedVA)
]

# Calendar year aggregation is messy (reform in effect on July 1) but
# necessary to use Bogin et. al (2019) HPI
# Note: calendar year is called 'FY' so code will run with minimal changes
dt_y <- dt[, .(
  Units1 = sum(Units1), Units2p = sum(Units2p), Units5 = sum(`Units5+`),
  ZHVI = mean(ZHVI), ZHVI_SFD = mean(ZHVI_SFD), n_units = sum(n_units),
  Post = min(Post), mean(rev_cp)
),
  by = .(FIPS, PCT001001, State, FY = year(Date), everTreated,
         notTreatedVA)
]

# TRUE --> data are unique on FIPS and quarter
nrow(dt_qtr) == uniqueN(dt_qtr[, .(FIPS, Date)])
nrow(dt_hy) == uniqueN(dt_hy[, .(FIPS, Date)])
nrow(dt_fy) == uniqueN(dt_fy[, .(FIPS, FY)])
nrow(dt_y) == uniqueN(dt_y[, .(FIPS, Year)])

# Synthetic Diff-in-Diff (Arkhangelsky et al (2019) ----

# Define treatment indicator for synthdid
# dt.synthdid <- dt_qtr[Date <= as.Date("2016-06-01"), isTreated := 0]
dt.synthdid <- copy(dt_y)
dt.synthdid[FY < 2017, isTreated := 0]
dt.synthdid[is.na(isTreated), isTreated := everTreated]

dt.synthdid <- dt.synthdid[
  FY %between% c(2010, 2022),
  .(
    FIPS = as.factor(FIPS), Date, FY, Units1,
    logZHVI = log(ZHVI), logZHVI_SFD = log(ZHVI_SFD),
    logUnits1 = log(Units1 + 1), logUnits2p = log(Units2p + 1),
    logUnits = log(Units1 + Units2p + 1), logUnits5 = log(Units5 + 1),
    logR = log((Units1 + 1) / (Units2p + 1)), notTreatedVA,
    everTreated, isTreated = as.logical(isTreated)
  )
]

RunSynthDid <- function(dt, LHS, period = "FY") {
  setup <- panel.matrices(dt,
    unit = "FIPS", time = period,
    outcome = LHS, treatment = "isTreated"
  )
  return(synthdid_estimate(setup$Y, setup$N0, setup$T0))
}

# * Prices ----
outcome <- "logZHVI"
dt.synthdid[, nObs := sum(!is.infinite(get(outcome)) &
                          !is.na(get(outcome))), by = .(FIPS)]

tau.hat <- RunSynthDid(dt.synthdid[nObs == max(nObs)], outcome)

plot(tau.hat, overlay = 1) +
  scale_x_continuous(breaks = seq(
    floor(min(dt.synthdid$FY)),
    ceiling(max(dt.synthdid$FY)), 1
  )) +
    geom_vline(xintercept = 2016.5, linetype = "dashed") +
    theme_light(base_size = 14) +
    theme(legend.position = c(0.85, 0.18)) +
    labs(y = "Log House Price Index",
         title = "The Effect of the Proffer Reform Act on Housing Prices")
ggsave(here("paper", "figures", "synthdid_zhvi.png"),
       width = 8, height = 4)

# Placebo
dt.synthdid[FY >= 2017, isTreated := notTreatedVA]
table(dt.synthdid[isTreated == TRUE, Name])

tau.hat <- RunSynthDid(dt.synthdid[nObs == max(nObs)], outcome)

plot(tau.hat, overlay = 1) +
  scale_x_continuous(breaks = seq(
    floor(min(dt.synthdid$FY)),
    ceiling(max(dt.synthdid$FY)), 1
  )) +
  geom_vline(xintercept = 2016.5, linetype = "dashed") +
  theme_light(base_size = 14) +
  theme(legend.position = c(0.85, 0.18)) +
  labs(
    y = "Log House Price Index",
    title = "The Effect of the Proffer Reform Act on Housing Prices"
  )
ggsave(here("paper", "figures", "synthdid_zhvi.png"),
  width = 8, height = 4
)


synthdid_placebo_plot(tau.hat, overlay = 0)

# this should be a bootstrap
se <- sqrt(vcov(tau.hat, method = "jackknife"))
sprintf("Point estimate: %1.2f", tau.hat)
sprintf("95%% CI (%1.2f, %1.2f)", tau.hat - 1.96 * se, tau.hat + 1.96 * se)
sprintf("90%% CI (%1.2f, %1.2f)", tau.hat - 1.64 * se, tau.hat + 1.64 * se)

# * Prices ----
# HPI falls after reform?
# Note: effect is much larger if post period is extended through 2022
dt.synthdid[, nObs := sum(!is.na(logZHVI)), by = .(FIPS)]

tau.hat <- RunSynthDid(dt.synthdid[nObs == max(nObs)], "logZHVI")

plot(tau.hat, se.method = "jackknife", overlay = 1) +
  scale_x_continuous(breaks = seq(floor(min(dt.synthdid$FY)),
                                  ceiling(max(dt.synthdid$FY)), 1)) +
  geom_vline(xintercept = 2016.5, linetype = "dashed") +
  theme_light(base_size = 14) +
  theme(legend.position = "bottom")

# this should be a bootstrap
se <- sqrt(vcov(tau.hat, method = "jackknife"))
sprintf("Point estimate: %1.2f", tau.hat)
sprintf("95%% CI (%1.2f, %1.2f)", tau.hat - 1.96 * se, tau.hat + 1.96 * se)

exp(mean(dt.synthdid[isTreated == 1 & FY == 2017, logZHVI],
  na.rm = TRUE))



top.controls <- synthdid_controls(tau.hat)[1:10, , drop = FALSE]


# Event Study ----
RHS_ES <- paste0(
  " ~ -1 + i(Date, everTreated, ref = I(ymd(\"2016-04-01\")))",
  # " + State:as.numeric(Date)",
  " | Date + FIPS"
)
fmla.es <- as.formula(paste0("Units1", RHS_ES))

# * Monthly ----
# Poisson QMLE
fepois.es <- feglm(fmla.es,
  cluster = "as.factor(FIPS)",
  data = dt[FY %between% c(2010, 2019)], family = "quasipoisson" #, weights = ~PCT001001
)
etable(fepois.es)
iplot(fepois.es,
  lab.fit = "simple", value.lab = "",
  main = "Effect on single-family housing permits"
)

# OLS
feols.es <- feols(fmla.es,
  cluster = "as.factor(FIPS)", data = dt[FY %between% c(2010, 2019)]
)
iplot(feols.es,
  lab.fit = "simple",
  value.lab = "", main = "Effect on single-family housing permits"
)


# Quarterly ----
# Poisson QMLE
fepois.es <- feglm(as.formula(paste0("Units1", RHS_ES)),
  cluster = "as.factor(FIPS)", data = dt_qtr[FY %between% c(2010, 2019)],
  family = "quasipoisson", weights = ~PCT001001
)
etable(fepois.es)
iplot(fepois.es, lab.fit = "simple")

# OLS
feols.es <- feols(as.formula(paste0("log(Units1 + 1)", RHS_ES)),
  cluster = "as.factor(FIPS)", data = dt_qtr[FY %between% c(2010, 2019)],
  weights = ~PCT001001
)
etable(feols.es)
pdf(file = "paper/figures/eventstudy_units1.pdf")
iplot(feols.es, lab.fit = "simple")
dev.off()

feols.zhvi_qtr <- feols(as.formula(paste0("log(ZHVI)", RHS_ES)),
                 cluster = "as.factor(FIPS)", data = dt_qtr,
                 weights = ~PCT001001)
# etable(feols.un1_qtr)
iplot(feols.zhvi_qtr, lab.fit = "simple")


