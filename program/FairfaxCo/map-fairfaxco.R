# Mapping the location of rezonings and building permits

# Comprehensive Plan Units downloaded on 8/7/2023 from:
# https://data-fairfaxcountygis.opendata.arcgis.com/datasets/Fairfaxcountygis::comprehensive-plan-land-units/explore

rm(list = ls())
pacman::p_load(here, data.table, ggplot2, sf, tigris, lubridate)

options(tigris_use_cache = TRUE, tigris_class = "sf")

# Import ----
sf_ff_rezone <- readRDS(
    "derived/FairfaxCo/Rezoning GIS (2010-2020).Rds"
)
sf_va <- tigris::counties(state = "VA", cb = TRUE)
sf_ff_roads <- tigris::roads(state = "VA", county = "059",
    year = 2021)
sf_ff_exempt <- st_read(dsn = paste0(
    "data/FairfaxCo/GIS/Comprehensive_Plan_Land_Units/",
    "Comprehensive_Plan_Land_Units.shp"
))
sf_reston_tysons <- readRDS(
    "derived/FairfaxCo/Reston and Tysons SF.Rds")

# Clean ----
# Tagging resi/commercial rezonings
sf_ff_rezone <- subset(sf_ff_rezone, Status == "Approved")

sf_ff_rezone <- subset(sf_ff_rezone,
    select = c("Unique ID", "isExempt", "submit_date", "isResi",
    "geometry")
)

# Tagging exempt plan land areas
v_exempt17 <- c("Merrifield Suburban Center",
    "Franconia-Springfield TSA", "Springfield CBC",
    "Dulles Suburban Center", "Huntington TSA", "Vienna TSA",
    "Van Dorn TSA", "West Falls Church TSA", "Fairfax Center Area",
    "Annandale CBC", "Baileys Crossroads CBC", "Seven Corners CBC",
    "North Gateway CBC", "Penn Daw CBC", "Beacon/Groveton CBC",
    "Hybla Valley/Gum Springs CBC", "South County Center CBC",
    "Woodlawn CBC",
    "Dulles (Route 28 Corridor) Suburban Center")
v_exempt18 <- c("McLean CBC") # exempt from 3/14/2017
v_exempt19 <- c("Lincolnia CBC") # exempt from 3/6/2018

sf_ff_exempt <- subset(sf_ff_exempt,
    PRIMARY_PL %in% v_exempt17 | grepl("SNA", PRIMARY_PL))

# Maps ----
MapFairfax <- function(yr = NA) {
    if (is.na(yr)) {
        sf_rezone <- subset(sf_ff_rezone, isResi == TRUE)
        yr <- "2010-2020"
    } else {
        sf_rezone <- subset(sf_ff_rezone, isResi == TRUE &
            year(submit_date) == yr)
    }

    ggplot() +
        geom_sf(
            data = subset(sf_va, NAMELSAD == "Fairfax County"),
            fill = "white"
        ) +
        geom_sf(data = sf_ff_exempt, fill = "lightgray") +
        geom_sf(data = sf_reston_tysons, fill = "lightgray") +
        geom_sf(
            data = subset(sf_ff_roads, RTTYP %in% c("I", "S")),
            color = "gray", size = 0.5
        ) +
        geom_sf(data = sf_rezone, aes(fill = isExempt)) +
        labs(title = "Fairfax Co.",
             subtitle = paste0("Residential Rezonings (", yr, ")")) +
        scale_fill_discrete(name = "", labels = c("Affected", "Exempt")) +
        theme(
            axis.text.x = element_blank(), axis.text.y = element_blank(),
            axis.ticks.x = element_blank(), axis.ticks.y = element_blank(),
            panel.background = element_blank(),
            text = element_text(size = 14),
            legend.position = c(1, .8),
            plot.title = element_text(hjust = 0, vjust = -2) 
        )

        ggsave(paste0("paper/figures/fairfax/map_fairfax_", yr, ".png"),
            width = 7, height = 6)
}

print(MapFairfax())

for (yr in 2014:2019) {
    print(MapFairfax(yr))
}
