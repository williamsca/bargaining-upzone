# This script performs a power calculation to determine
# the number of counties needed to detect an X% decrease
# in residential rezoning activity.

rm(list = ls())
library(here)
library(data.table)
library(pwr)

# Import ----
dt <- readRDS(here("derived", "county-rezonings.Rds"))

M1 <- mean(dt[year(submit_date) %in% c(2015, 2016)]$n_units, na.rm = TRUE)

M2 <- mean(dt[year(submit_date) %in% c(2017, 2018)]$n_units, na.rm = TRUE)
