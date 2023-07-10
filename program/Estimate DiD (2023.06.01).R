# Estimate the effect of the 2016 Proffer Reform Act on residential construction

rm(list = ls())

pacman::p_load(
  data.table, stargazer, ggplot2,
  fixest, devtools, lubridate, here
)

INTENSITY_THRESHOLD <- 0.01

dt <- readRDS("derived/Sample.Rds")

arcsinh <- function(x) log(x + sqrt(x^2 + 1))

# Treatment indicators ----
dt[FY == 2016, everTreated := fifelse(
  intensity12_16 > INTENSITY_THRESHOLD, 1, 0
)]
dt[is.na(everTreated), everTreated := 0]
dt[, everTreated := max(everTreated), by = FIPS]

dt[, Post := fifelse(Date >= as.Date("2017-01-01"), 1, 0)]

# lower bound on multi-family units
dt[, Units2p := Units2 + 3 * `Units3-4` + 5 * `Units5+`]

dt_qtr <- dt[, .(
  Units1 = sum(Units1), Units2p = sum(Units2p),
  ZHVI = mean(ZHVI)
),
by = .(FIPS,
  Date = quarter(Date, type = "date_first"), `Cash Proffer Revenue`,
  everTreated, Post, FY, intensity12_16
)
]

# TRUE --> data are unique on FIPS and quarter
nrow(dt_qtr) == uniqueN(dt_qtr[, .(FIPS, Date)])

# Summary statistics by treatment status ----
dt_fig1 <- dt[everTreated == 1 & Units1 <= 400]
ggplot(dt_fig1, aes(x = Units1)) +
  geom_histogram() +
  scale_x_continuous() +
  labs(title = "Distribution of Monthly Building Permits: Treated Counties",
       subtitle = paste0(min(year(dt_fig1$Date)), " - ",
       max(year(dt_fig1$Date))),
       x = "Single-Unit Permits", y = "Frequency",
       caption = paste0("Permits censored at ", max(dt_fig1$Units1),
       ". N = ", nrow(dt_fig1), "")) +
  theme_light() + theme(plot.caption = element_text(hjust = 0)) 
# ggsave("", device = "pdf")

# DiD ----
RHS_DID <- " ~ -1 + Post*everTreated | as.factor(Date) + as.factor(FIPS)"
RHS_DID_CONT <- " ~ -1 + Post*Intensity | as.factor(Date) + as.factor(FIPS)"

fmla.dd <- as.formula(paste0("Units1", RHS_DID))
fmla.dd_cont <- as.formula(paste0("Units1", RHS_DID_CONT))

# * Monthly ----
# ** Binary Treatment ----
fepois.did <- feglm(fmla.dd,
  cluster = "as.factor(FIPS)",
  data = dt[FY %between% c(2010, 2019)],
  family = "quasipoisson"
)
etable(fepois.did)

# ** Continuous Treatment ----
fepois.did <- feglm(fmla.dd_cont,
  cluster = "as.factor(FIPS)", data = dt[FY %between% c(2010, 2019)],
  family = "quasipoisson"
)
etable(fepois.did)


# Quarterly ----
# (Nearly identical to monthly results)
# ** Binary Treatment ----
fepois.did <- feglm(fmla.dd,
  cluster = "as.factor(FIPS)",
  data = dt_qtr[FY %between% c(2010, 2019)],
  family = "quasipoisson"
)
etable(fepois.did)

# ** Continuous Treatment ----
fepois.did <- feglm(fmla.dd_cont,
  cluster = "as.factor(FIPS)",
  data = dt_qtr[FY %between% c(2010, 2019)],
  family = "quasipoisson"
)
etable(fepois.did)



# Event Study ----
RHS_ES <- " ~ -1 + i(Date, everTreated, ref = \"2016-04-01\") | Date + FIPS"
fmla.es <- as.formula(paste0("log(Units1 + 1)", RHS_ES))

# * Monthly ----
# Poisson QMLE
fepois.es <- feglm(fmla.es,
  cluster = "as.factor(FIPS)",
  data = dt[FY %between% c(2010, 2019)], family = "quasipoisson"
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
fepois.es <- feglm(fmla.es,
  cluster = "as.factor(FIPS)", data = dt_qtr[FY %between% c(2012, 2019)],
  family = "quasipoisson"
)
etable(fepois.es)
iplot(fepois.es, lab.fit = "simple")
# OLS
feols.es <- feols(fmla.es,
  cluster = "as.factor(FIPS)", data = dt_qtr[FY %between% c(2012, 2019)]
)
etable(feols.es)
pdf(file = "paper/figures/eventstudy_units1.pdf")
iplot(feols.es, lab.fit = "simple")
dev.off()

feols.zhvi_qtr <- feols(as.formula(paste0("log(ZHVI)", RHS)), 
                 cluster = "as.factor(FIPS)", data = dt_qtr)
# etable(feols.un1_qtr)
iplot(feols.zhvi_qtr, lab.fit = "simple")


# Synthetic Diff-in-Diff (Arkhangelsky et al (2019) ----
devtools::install_github("synth-inference/synthdid")
library(synthdid)

# Define treatment indicator for synthdid
dt.synthdid <- dt_qtr[Date <= as.Date("2016-06-01"), isTreated := 0]
dt.synthdid[is.na(isTreated), isTreated := everTreated]

dt.synthdid <- dt.synthdid[
  FY %between% c(2012, 2019),
  .(
    FIPS = as.factor(FIPS), Date, Units1,
    arcsinhUnits1 = arcsinh(Units1),
    logUnits1 = log(Units1 + 1), isTreated = as.logical(isTreated)
  )
]

RunSynthDid <- function(dt, LHS) {
  setup <- panel.matrices(dt, unit = "FIPS", time = "Date",
                          outcome = LHS, treatment = "isTreated")
  return(synthdid_estimate(setup$Y, setup$N0, setup$T0))
}

# * Quantities ----
dt.synthdid[, nObs := sum(!is.infinite(logUnits1)), by = .(FIPS)]
# dt.synthdid[, nObs := sum(!is.na(Units1)), by = .(FIPS)]

tau.hat <- RunSynthDid(dt.synthdid[nObs == max(nObs)], "logUnits1")

plot(tau.hat, se.method = "jackknife", overlay = 1)
ggsave("paper/figures/synthdid_overlay.pdf", device = "pdf")

plot(tau.hat, se.method = "jackknife")
ggsave("paper/figures/synthdid.pdf", device = "pdf", width = 8, height = 6)

se <- sqrt(vcov(tau.hat, method = "jackknife")) # this should be a bootstrap
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
dt.synthdid[, nObs := sum(!is.na(lnZHVI)), by = .(FIPS)]

tau.hat <- RunSynthDid(dt.synthdid[nObs == max(nObs)], "lnZHVI")
plot(tau.hat, se.method = "jackknife")

se <- sqrt(vcov(tau.hat, method = "jackknife")) # this should be a bootstrap
sprintf("Point estimate: %1.2f", tau.hat)
sprintf("95%% CI (%1.2f, %1.2f)", tau.hat - 1.96*se, tau.hat + 1.96*se)

# Superseded ----
