# Regression analysis of cash proffer eligibility on building permits
# Author: Colin Williams
# Updated: 24 March 2023

rm(list = ls())

dir <- dirname(dirname(rstudioapi::getSourceEditorContext()$path))
setwd(dir)

pacman::p_load(data.table, stargazer, ggplot2, fixest, devtools, lubridate) 

dt <- readRDS("derived/Regression Sample.Rds")

arcsinh <- function(x) log(x + sqrt(x^2+1))

# Create treatment indicator ----

dt <- dt[!(FIPS.Code.State %in% c("02", "15")) & Year4 %between% c(2000, 2019)] # exclude Alaska and Hawaii
dt <- unique(dt, by = c("FIPS", "Date", "Units1")) # drop 24 duplicate entries

# Counties and cities that collected >50k in cash proffer revenue in FY2016
v.collected2016 <- c("Accomack", "Albemarle", "Amelia", "Caroline", "Chesterfield", 
                     "Fairfax", "Fauquier", "Frederick", "Gloucester", "Goochland", 
                     "Hanover", "Isle of Wight", "James City", "King William",
                     "Loudoun", "New Kent", "Powhatan", "Prince William",
                     "Rockingham", "Spotsylvania", "Stafford", "Warren", "York")
v.collected2016 <- c(paste0(v.collected2016, " County"), "Charlottesville City",
                     "Chesapeake City", "Fairfax City", "Fredericksburg City",
                     "Manassas City", "Manassas Park City", "Suffolk City")

v.collected2016m <- c("Albemarle County", "Chesterfield County", "Fairfax County",
                      "Frederick County", "Hanover County", "Loudoun County", "Prince William County",
                      "Spotsylvania County", "Stafford County", "Chesapeake City",
                      "Manassas Park City")

dt[, treated := fifelse(Name %in% v.collected2016m & FIPS.Code.State == "51", 1, 0)]


dt[, Units2p := Units2 + 3*`Units3-4` + 5*`Units5+`] # lower bound on multi-family units
dt[, Value2p := Value2 + `Value3-4` + `Value5+`]

dt.qtr <- dt[, .(Units1 = sum(Units1), Units2p = sum(Units2p), ZHVI = mean(ZHVI)), 
               by = .(FIPS, Date = quarter(Date, type = "date_first"), treated)]

# Summary statistics by treatment status ----
dt.fig1 <- dt[treated == 1 & Units1 <= 400]
ggplot(dt.fig1, aes(x = Units1)) + 
  geom_histogram() +
  scale_x_continuous() +
  labs(title = "", # Distribution of Bond Elections by Vote Share
       x = "Construction Permits for One-Unit Housing", y = "Frequency",
       caption = paste0("N = ", nrow(dt.fig1), "")) +
  theme_light() + theme(plot.caption = element_text(hjust = 0)) # left-align caption
# ggsave("", device = "pdf")

# Diff-in-Diff using 2016 reform ----
RHS <- " ~ -1 + i(Date, treated, ref = \"2016-07-01\") | Date + as.factor(FIPS)"

<<<<<<< HEAD
# Monthly TWFE regression ----
feols.un1 <- feols(as.formula(paste0("arcsinh(Units1)", RHS)), 
                 cluster = "as.factor(FIPS)", data = dt)
# etable(feols.un1)
iplot(feols.un1, lab.fit = "simple")

feols.zhvi <- feols(as.formula(paste0("log(ZHVI)", RHS)), 
                 cluster = "as.factor(FIPS)", data = dt)
# etable(feols)
=======
# * Graphical analysis ----
feols <- feols(arcsinh(Units1) ~ -1 + i(Date, treated, ref = as.Date("2016-06-01")) |
                 Date + as.factor(FIPS), cluster = "as.factor(FIPS)", 
               data = dt[FIPS.Code.State == "51" & Year4 <= 2019])
etable(feols)
pdf(file = "results/eventstudy_units1.pdf")
iplot(feols, lab.fit = "simple", value.lab = "", main = "Effect on single-family housing permits")
dev.off()

feols.zhvi <- feols(log(ZHVI) ~ -1 + i(Date, treated, ref = as.Date("2016-06-01")) |
                 Date + as.factor(FIPS), cluster = "as.factor(FIPS)", 
                 data = dt[FIPS.Code.State == "51" & Year4 <= 2019])
etable(feols)
>>>>>>> c033dd582608428c569a615a646a13dbebd515b7
iplot(feols.zhvi, lab.fit = "simple")


# Quarterly TWFE regression ----
feols.un1_qtr <- feols(as.formula(paste0("arcsinh(Units1)", RHS)), 
                 cluster = "as.factor(FIPS)", data = dt.qtr)
# etable(feols.un1_qtr)
iplot(feols.un1_qtr, lab.fit = "simple")

feols.zhvi_qtr <- feols(as.formula(paste0("log(ZHVI)", RHS)), 
                 cluster = "as.factor(FIPS)", data = dt.qtr)
# etable(feols.un1_qtr)
iplot(feols.zhvi_qtr, lab.fit = "simple")


# Synthetic Diff-in-Diff (Arkhangelsky et al (2019) ----
devtools::install_github("synth-inference/synthdid")
library(synthdid)

dt.synthdid <- dt.qtr[Date <= as.Date("2016-06-01"), treated := 0] # redefine treatment indicator for synthdid

dt.synthdid <- dt.synthdid[Date %between% c(as.Date("2005-01-01"), as.Date("2019-06-01")), 
                           .(FIPS = as.factor(FIPS), Date, 
                             arcsinhUnits1 = arcsinh(Units1), 
                             lnZHVI = log(ZHVI), treated)]

RunSynthDid <- function(dt, LHS) {
  setup <- panel.matrices(dt, unit = "FIPS", time = "Date", 
                          outcome = LHS, treatment = "treated")
  return(synthdid_estimate(setup$Y, setup$N0, setup$T0))
}

# Quantities
dt.synthdid[, nObs := sum(!is.na(arcsinhUnits1)), by = .(FIPS)]

tau.hat <- RunSynthDid(dt.synthdid[nObs == max(nObs)], "arcsinhUnits1")
plot(tau.hat, se.method = "jackknife")

se <- sqrt(vcov(tau.hat, method = "bootstrap")) # this should be a bootstrap
sprintf("Point estimate: %1.2f", tau.hat)
sprintf("95%% CI (%1.2f, %1.2f)", tau.hat - 1.96*se, tau.hat + 1.96*se)

# Prices
dt.synthdid[, nObs := sum(!is.na(lnZHVI)), by = .(FIPS)]

tau.hat <- RunSynthDid(dt.synthdid[nObs == max(nObs)], "lnZHVI")
plot(tau.hat, se.method = "jackknife")

se <- sqrt(vcov(tau.hat, method = "jackknife")) # this should be a bootstrap
sprintf("Point estimate: %1.2f", tau.hat)
sprintf("95%% CI (%1.2f, %1.2f)", tau.hat - 1.96*se, tau.hat + 1.96*se)



