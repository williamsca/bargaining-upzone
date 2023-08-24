# Data requested from Loudoun Couty Office of Mapping and GIS on 8/7/2023
# mapping@loudoun.gov

# Public mapping portal:
# https://www.loudoun.gov/3362/LOLA

rm(list = ls())
library(here)
library(data.table)
library(sf)
library(ggplot2)
library(lubridate)
library(stringr)

# Import ----
sf <- st_read(here("data", "LoudounCo",
    "GIS", "Zoning_Shp_20230809", "ZONING_POLY.shp")
)

# Clean ----
names(sf) <- c("zone", "ordinance", "spec_code", "project_number",
    "update_number", "approval_date", "zone_ord", "maint_task_id",
    "gis_start_date", "gis_end_date", "upd_sou", "upd_use", "upd_date",
    "shape_star", "shape_stle", "geometry")

sf$approval_quarter <- floor_date(sf$approval_date, "quarter")

sf$year_zmap <- str_extract(sf$project_number, "\\d{4}")

View(subset(sf, select = c("project_number", "year_zmap", "approval_date")))

# Inspect ----

# Map
ggplot() +
    geom_sf(data = sf, fill = "lightgray") +
    theme(
        axis.text.x = element_blank(), axis.text.y = element_blank(),
        axis.ticks.x = element_blank(), axis.ticks.y = element_blank(),
        panel.background = element_blank()
    )

# Unique ID (none)
dt <- as.data.table(sf)
dt[, c("geometry", "shape_star", "shape_stle") := NULL]

uniqueN(dt)
nrow(sf)

# Approval Date Histogram
ggplot(data = sf) +
    geom_bar(aes(x = approval_quarter)) +
    scale_x_date(limits = c(ymd("2010/01/01", "2023/08/09")),
        date_breaks = "1 year", date_labels = "%Y") +
    geom_vline(
        xintercept = as.numeric(ymd("2016-07-01")),
        color = "gray", linewidth = 1, linetype = "dashed"
    ) +
    labs(y = "Number of Approved Rezonings", x = "Approval Date") +
    theme_light()
