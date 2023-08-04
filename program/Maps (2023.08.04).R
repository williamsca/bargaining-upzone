# Mapping the location of rezonings and building permits

rm(list = ls())
pacman::p_load(here, data.table, ggplot2, sf)

# Import ----
dt_fairfax <- readRDS(
    "derived/FairfaxCo/Rezoning Applications (2010-2020).Rds"
)

# Map ----

