# This script performs a power calculation to determine
# the number of counties needed to detect an X% decrease
# in residential rezoning activity.

rm(list = ls())
library(here)
library(data.table)

# Import ----
dt <- readRDS(here("derived", "county-rezonings.Rds"))

# Estimate moments ----
cp_mean <- mean(log(dt[res_cash_proffer > 0, res_cash_proffer]))
cp_sd <- sqrt(var(log(dt[res_cash_proffer > 0, res_cash_proffer])))

units_mean <- mean(log(dt[n_units > 0, n_units]))
units_sd <- sqrt(var(log(dt[n_units > 0, n_units])))

# Simulate ----
N_COUNTIES <- 10
N_YEARS <- 6
N_SIMS <- 1000
EFFECT <- -0.1

data <- CJ(
    county = seq(1:N_COUNTIES),
    year = seq(1:N_YEARS)
)

dt_county <- data.table(
    county = seq(1:N_COUNTIES),
    res_cash_proffer = rnorm(N_COUNTIES, cp_mean, cp_sd)
)

# Merge in pre-reform average log cash proffer level
data <- merge(data, dt_county, by = "county")

# Normalize cash proffer into standard deviation units
data[, res_cash_proffer := (res_cash_proffer - cp_mean) / cp_sd]

# Generate random log units and add reform effect
data$n_units <- rnorm(N_COUNTIES * N_YEARS, units_mean, units_sd)
data[year <= 3, n_units := n_units + EFFECT * res_cash_proffer]

# Estimate
lm(data = data, n_units ~ year + county + )
