# This script combines rezoning application data and GIS data from
# Prince William County to create a panel dataset of rezonings

rm(list = ls())
library(here)
library(data.table)

# Import ----
dt_app <- readRDS(
  "derived\PrinceWilliamCo\Rezoning Applications (1958-2023).Rds)"
)
sf <- readRDS("derived/PrinceWilliamCo/Rezoning GIS.Rds")

# Merge ----
