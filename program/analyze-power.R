# This script performs a power calculation to determine
# the number of counties needed to detect an X% decrease
# in residential rezoning activity fr eacg 

rm(list = ls())
library(here)
library(data.table)
library(ggplot2)
library(fixest)

# Import ----
dt <- readRDS(here("derived", "county-rezonings.Rds"))

# Estimate moments ----
# TODO: estimate means and standard deviations separately across
# years and counties
cp_mean <- mean(log(dt[res_cash_proffer > 0, res_cash_proffer]))
cp_sd <- sqrt(var(log(dt[res_cash_proffer > 0, res_cash_proffer])))

units_mean <- mean(log(dt[n_units > 0, n_units]))
units_sd <- sqrt(var(log(dt[n_units > 0, n_units])))

make_data <- function(years, counties, effect) {
    data <- CJ(
        county = seq(1:counties),
        year = seq(1:years)
    )

    dt_county <- data.table(
        county = seq(1:counties),
        res_cash_proffer = rnorm(counties, cp_mean, cp_sd)
    )

    # Merge in pre-reform average log cash proffer level
    data <- merge(data, dt_county, by = "county")

    # Normalize cash proffer into standard deviation units
    data[, res_cash_proffer := (res_cash_proffer - cp_mean) / cp_sd]

    # Generate random log units and add reform effect
    data$n_units <- rnorm(counties * years, units_mean, units_sd)
    data[, POST := fifelse(year > 3, 1, 0)]
    data[POST == TRUE, n_units := n_units + EFFECT * res_cash_proffer]

    return(data)
}

# Simulate ----
N_COUNTIES <- 50
N_YEARS <- 10
N_SIMS <- 1000
EFFECT <- -.2
coeffs <- rep(NA, N_SIMS)
sd <- rep(NA, N_SIMS)

for (i in 1:N_SIMS) {
    dt <- make_data(N_YEARS, N_COUNTIES, EFFECT)
    lm <- feols(data = dt, n_units ~ year + county + res_cash_proffer * POST,
        cluster = "county")
    coeffs[i] <- coeftable(lm)[6]
    sd[i] <- coeftable(lm)[12]
}

dt_sim <- data.table(run = seq(1:N_SIMS), estimate = coeffs, stddev = sd)

# Analyze ----
ggplot(dt_sim, aes(x = estimate)) +
    geom_histogram(bins = 50) +
    geom_vline(xintercept = 0, color = "red") +
    labs(
        title = "Distribution of estimated effects",
        subtitle = paste0(N_COUNTIES, " counties, ", N_YEARS, " years, ",
            N_SIMS, " simulations"),
        x = "Estimate",
        y = "Frequency"
    )

nrow(dt_sim[estimate < 0]) / N_SIMS

# Power
dt_sim[, t := pnorm(estimate, mean = 0, stddev)]

ggplot(dt_sim, aes(x = t)) +
    geom_histogram(bins = 50) +
    geom_vline(xintercept = .05, color = "red") +
    labs(
        title = "Distribution of t-statistics",
        subtitle = paste0(N_COUNTIES, " counties, ", N_YEARS, " years, ",
            N_SIMS, " simulations"),
        x = "t-statistic",
        y = "Frequency"
    )

nrow(dt_sim[t < .05]) / N_SIMS
