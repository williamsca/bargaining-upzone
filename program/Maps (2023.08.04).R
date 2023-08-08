# Mapping the location of rezonings and building permits

# Comprehensive Plan Units downloaded on 8/7/2023 from:
# https://data-fairfaxcountygis.opendata.arcgis.com/datasets/Fairfaxcountygis::comprehensive-plan-land-units/explore

rm(list = ls())
pacman::p_load(here, data.table, ggplot2, sf, tigris, lubridate)

options(tigris_use_cache = TRUE, tigris_class = "sf")

# Import ----
sf_ff_rezone <- readRDS(
    "derived/FairfaxCo/Rezoning Applications (2010-2020).Rds"
)
sf_va <- tigris::counties(state = "VA", cb = TRUE)
sf_ff_roads <- tigris::roads(state = "VA", county = "059",
    year = 2021)
sf_ff_exempt <- st_read(dsn = paste0(
    "data/FairfaxCo/GIS/Comprehensive_Plan_Land_Units/",
    "Comprehensive_Plan_Land_Units.shp"
))
sf_reston_tysons <- readRDS("derived/FairfaxCo/Reston and Tysons SF.Rds")

# Clean ----
# Tagging resi/commercial rezonings
sf_ff_rezone <- subset(sf_ff_rezone, Status == "Approved")

sf_ff_rezone <- subset(sf_ff_rezone,
    select = c("CASE_NUMBE", "submit_date", "isResi", "geometry"))

sf_ff_rezone <- sf_ff_rezone[!duplicated(
    st_drop_geometry(sf_ff_rezone)
), ]

# Sanity Check ----
dt_ff_rezone <- as.data.table(sf_ff_rezone)
dt_ff_rezone[, nDup := .N, by = .(CASE_NUMBE)]

# TRUE --> no rezoning case is amended from resi to non-resi use
nrow(dt_ff_rezone[nDup > 1]) == 0

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
    PRIMARY_PL %in% v_exempt16 | grepl("SNA", PRIMARY_PL))

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
            fill = "white"
        ) +
        geom_sf(data = sf_ff_exempt, fill = "lightgray") +
        geom_sf(data = sf_reston_tysons, fill = "lightgray") +
        geom_sf(
            data = subset(sf_ff_roads, RTTYP %in% c("I", "S")),
            color = "gray", size = 0.5
        ) +
        geom_sf(data = sf_rezone, aes(fill = isResi)) +
        labs(title = "Fairfax Rezonings",
             subtitle = paste0("Application Year ", yr)) +
        scale_fill_discrete(name = "",
            labels = c("Commercial", "Residential or Mixed")) +
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
