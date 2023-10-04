# Estimate the effect of the 2016 Proffer Reform Act on residential construction

# Reform goes into effect on July 1, 2016:
# https://www.williamsmullen.com/news/dissecting-proffer-reform-bill

rm(list = ls())

library(data.table)
library(stargazer)
library(fixest)
library(ggplot2)
library(devtools)
library(lubridate)
library(here)

dt <- readRDS("derived/sample.Rds")

arcsinh <- function(x) log(x + sqrt(x^2 + 1))

# Treatment indicators ----
dt[, cp_share_local := rev_cp / rev_loc]

INTENSITY_THRESHOLD <- mean(dt$cp_share_local, na.rm = TRUE)
INTENSITY_THRESHOLD <- quantile(dt$cp_share_local, 0.8, na.rm = TRUE)

dt[FY == 2016, everTreated := fifelse(
  cp_share_local > INTENSITY_THRESHOLD, 1, 0
)]

table(dt[everTreated == 1, Name])

dt[is.na(everTreated), everTreated := 0]
dt[, everTreated := max(everTreated), by = FIPS]

# Exclude Fairfax, Loudoun for partial exemption
dt <- dt[!(FIPS %in% c("51059", "51107"))]

# Exclude untreated VA counties to avoid spillovers
dt <- dt[!(everTreated == 0 & FIPS.Code.State == "51")]

dt[, Post := fifelse(Date >= ymd("2016-07-01"), 1, 0)]
dt[, State := substr(FIPS, 1, 2)]

# Total units in multi-family buildings
dt[, Units2p := Units2 + `Units3-4` + `Units5+`]

dt_qtr <- dt[, .(
  Units1 = sum(Units1), Units2p = sum(Units2p),
  ZHVI = mean(ZHVI), n_units = sum(n_units)
),
by = .(FIPS, PCT001001, State,
  Date = floor_date(Date, unit = "quarter"), rev_cp,
  everTreated, Post, FY)
]

dt_hy <- dt[, .(
  Units1 = sum(Units1), Units2p = sum(Units2p),
  ZHVI = mean(ZHVI), n_units = sum(n_units)
),
by = .(FIPS, PCT001001, State,
  Date = floor_date(Date, unit = "halfyear") + months(3), rev_cp,
  everTreated, Post, FY)]

# TRUE --> data are unique on FIPS and quarter
nrow(dt_qtr) == uniqueN(dt_qtr[, .(FIPS, Date)])
nrow(dt_hy) == uniqueN(dt_hy[, .(FIPS, Date)])

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


# Synthetic Diff-in-Diff (Arkhangelsky et al (2019) ----
devtools::install_github("synth-inference/synthdid")
library(synthdid)

# Define treatment indicator for synthdid
# dt.synthdid <- dt_qtr[Date <= as.Date("2016-06-01"), isTreated := 0]
dt.synthdid <- dt_hy[Date <= as.Date("2016-06-01"), isTreated := 0]
dt.synthdid[is.na(isTreated), isTreated := everTreated]

dt.synthdid <- dt.synthdid[
  Date %between% as.Date(c("2012-01-01", "2021-10-01")),
  .(
    FIPS = as.factor(FIPS), Date, Units1,
    arcsinhUnits1 = arcsinh(Units1), logZHVI = log(ZHVI),
    logUnits1 = log(Units1 + 1), logUnits2p = log(Units2p + 1),
    everTreated, isTreated = as.logical(isTreated)
  )
]

RunSynthDid <- function(dt, LHS) {
  setup <- panel.matrices(dt, unit = "FIPS", time = "Date",
                          outcome = LHS, treatment = "isTreated")
  return(synthdid_estimate(setup$Y, setup$N0, setup$T0))
}

# * Quantities ----
dt.synthdid[, nObs := sum(!is.infinite(logUnits2p)), by = .(FIPS)]

tau.hat <- RunSynthDid(dt.synthdid[nObs == max(nObs)], "logUnits2p")


plot(tau.hat, se.method = "jackknife", overlay = 1)
ggsave("paper/figures/synthdid_overlay.pdf", device = "pdf")

plot(tau.hat, se.method = "jackknife")
ggsave("paper/figures/synthdid.pdf", device = "pdf", width = 8, height = 6)

# this should be a bootstrap
se <- sqrt(vcov(tau.hat, method = "jackknife"))
sprintf("Point estimate: %1.2f", tau.hat)
sprintf("95%% CI (%1.2f, %1.2f)", tau.hat - 1.96 * se, tau.hat + 1.96 * se)
sprintf("90%% CI (%1.2f, %1.2f)", tau.hat - 1.64 * se, tau.hat + 1.64 * se)


tau_hat_inhs <- RunSynthDid(dt.synthdid[nObs == max(nObs)], "arcsinhUnits1")
plot(tau_hat_inhs, se.method = "jackknife", overlay = 0)

se <- sqrt(vcov(tau_hat_inhs, method = "jackknife")) # this should be a bootstrap
sprintf("Point estimate: %1.2f", tau_hat_inhs)
sprintf("95%% CI (%1.2f, %1.2f)", tau_hat_inhs - 1.96 * se, tau_hat_inhs + 1.96 * se)
sprintf("90%% CI (%1.2f, %1.2f)", tau_hat_inhs - 1.64 * se, tau_hat_inhs + 1.64 * se)


# * Prices ----
# VA HPI falls after reform?
dt.synthdid[, nObs := sum(!is.na(logZHVI)), by = .(FIPS)]

tau.hat <- RunSynthDid(dt.synthdid[nObs == max(nObs)], "logZHVI")
plot(tau.hat, se.method = "jackknife", overlay = 1)

se <- sqrt(vcov(tau.hat, method = "jackknife")) # this should be a bootstrap
sprintf("Point estimate: %1.2f", tau.hat)
sprintf("95%% CI (%1.2f, %1.2f)", tau.hat - 1.96 * se, tau.hat + 1.96 * se)

