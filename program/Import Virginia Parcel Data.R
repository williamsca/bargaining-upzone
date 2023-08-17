# Import Virginia Parcels: Local Schema Tables
# Source: https://vgin.vdem.virginia.gov/datasets/virginia-parcels-local-schema-tables/about

rm(list = ls())

dir <- dirname(dirname(rstudioapi::getSourceEditorContext()$path))
setwd(dir)

pacman::p_load(data.table, sf, ggplot2) # broom
pacman::p_load(rgdal)

# gdb.ls <- "data/Virginia_Parcel_Dataset_LocalSchemas_2023Q1.gdb"
gdb <- "data/Virginia_Parcel_Dataset_2023Q1.gdb"

proffers <- "data/Albemarle Proffers/PROFFERS.shp"

st_layers(gdb)

sf.test <- st_read(gdb, layer = "VA_Parcels")

sf.test <- readOGR(dsn = proffers)
