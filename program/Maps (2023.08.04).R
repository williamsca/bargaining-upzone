# Mapping the location of rezonings and building permits

rm(list = ls())
pacman::p_load(here, data.table, ggplot2, sf, tigris, lubridate)

options(tigris_use_cache = TRUE, tigris_class = "sf")

# Import ----
sf_ff_rezone <- readRDS(
    "derived/FairfaxCo/Rezoning Applications (2010-2020).Rds"
)
sf_ff_rezone <- subset(sf_ff_rezone, Status == "Approved")
sf_va <- tigris::counties(state = "VA", cb = TRUE)
sf_ff_roads <- tigris::roads(state = "VA", county = "059", year = 2021)

# Maps ----
MapFairfax <- function(yr = NA) {
    if (is.na(yr)) {
        sf_rezone <- sf_ff_rezone
    } else {
        sf_rezone <- subset(sf_ff_rezone, year(submit_date) == yr)
    }

    ggplot() +
        geom_sf(
            data = subset(sf_va, NAMELSAD == "Fairfax County"),
            fill = "lightgray"
        ) +
        geom_sf(
            data = subset(sf_ff_roads, RTTYP %in% c("I", "S")),
            color = "gray", size = 0.5
        ) +
        geom_sf(data = sf_rezone, aes(fill = ZONETYPE)) +
        labs(title = "Fairfax Rezonings",
             subtitle = paste0("Application Year ", yr)) +
        theme(
            axis.text.x = element_blank(), axis.text.y = element_blank(),
            axis.ticks.x = element_blank(), axis.ticks.y = element_blank(),
            panel.background = element_blank(), text = element_text(size = 14)
        )
}

print(MapFairfax())

for (yr in 2014:2018) {
    print(MapFairfax(yr))
}

# Superseded ----
dt_fairfax <- dt_fairfax[Coordinates != "" & Status == "Approved"]
dt_fairfax[, c("lon", "lat") := tstrsplit(Coordinates, ",")]
sf_fairfax <- st_as_sf(dt_fairfax, coords = c("lon", "lat"), crs = 4326)
