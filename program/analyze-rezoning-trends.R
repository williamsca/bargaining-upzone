# Performs a preliminary analysis of trends in rezoning across
# the Virginia counties that collect the most revenue from cash
# proffers.

rm(list = ls())
library(data.table)
library(ggplot2)
library(gridExtra)
library(units)
library(here)

# Import ----
dt <- readRDS(here("derived", "county-rezonings.Rds"))

# Aggregate over parcels to application level
dt_app <- dt[,
    .(Area = sum(Area), isResi = any(isResi), isExempt = any(isExempt)),
    by = .(FIPS, Case.Number, County, submit_date,
    Population2022, isApproved, FY)]

uniqueN(dt_app$Case.Number) == nrow(dt_app)

# Plots ----
v_counties <- unique(dt$County)

# Approved Rezonings by Application Year

data <- dt
resi <- TRUE
county <- "Fairfax County"

sum_to_fy <- function(county, data, resi = TRUE) {
    if (resi == TRUE) {
        dt_graph <- subset(data, isResi == TRUE)
        dt_graph[, comparison := isExempt]
    } else {
        dt_graph <- data
        dt_graph[, comparison := isResi]
    }

    dt_graph <- subset(dt_graph,
        isApproved == TRUE & County == county)

    min_year <- max(min(data$FY), 2010)
    max_year <- min(max(data$FY), 2020)

    dt_yr <- CJ(
        FY = seq(min_year, max_year),
        comparison = c(TRUE, FALSE)
    )

    dt_graph <- dt_graph[
        , .(nApproved = .N, Area = sum(Area)),
        by = .(FY, comparison)
    ]

    dt_yr <- merge(dt_yr, dt_graph,
        by = c("FY", "comparison"),
        all.x = TRUE
    )

    dt_yr[is.na(nApproved), nApproved := 0]
    dt_yr[is.na(Area), Area := 0]

    return(dt_yr)
}

plot_rezonings <- function(county, data, outcome = "nApproved",
    resi = TRUE) {

    dt_yr <- sum_to_fy(county, data, resi)

    y_lab <- fifelse(
        outcome == "nApproved",
        "Rezonings [#]",
        "Rezonings"
    )

    if (resi == TRUE) {
        comp_labels <- c("Affected", "Exempt")
    } else {
        comp_labels <- c("Residential", "Non-Residential")
    }

    g <- ggplot(
        dt_yr,
        aes(
            x = FY, y = .data[[outcome]], group = comparison,
            color = comparison
        )
    ) +
        geom_line(linetype = "dashed") +
        geom_point(size = 3) +
        scale_x_continuous(breaks = seq(2010, 2020, 2)) +
        labs(
            y = y_lab,
            x = "Submit FY",
            title = county
        ) +
        geom_vline(
            xintercept = 2017, color = "gray",
            linetype = "dashed"
        ) +
        scale_color_discrete(name = "", labels = comp_labels) +
        theme_light(base_size = 11) +
        theme(legend.pos = c(.1, .88))

    return(g)
}

plot_rezonings("Fairfax County", dt,
    outcome = "nApproved", resi = TRUE)

# Counts
# * Residential
l_counts_resi <- lapply(v_counties, plot_rezonings,
    data = dt_app, outcome = "nApproved", resi = TRUE)
g_counts_resi <- do.call(grid.arrange, l_counts)

# * All
l_counts_all <- lapply(v_counties, plot_rezonings,
    data = dt_app, outcome = "nApproved", resi = FALSE)
g_counts_all <- do.call(grid.arrange, l_counts_all)


# Areas
# * Residential
l_areas <- lapply(v_counties, plot_rezonings,
    data = dt_app, outcome = "Area")
g_areas <- do.call(grid.arrange, l_areas)

# * All
l_areas_all <- lapply(v_counties, plot_rezonings,
    data = dt_app, outcome = "Area", resi = FALSE)
g_areas_all <- do.call(grid.arrange, l_areas_all)

# Fairfax
print(plot_rezonings(dt_app, "Fairfax County", "nApproved"))
ggsave("paper/figures/fairfax/plot_fairfax_exempt_counts.png",
    width = 8, height = 4.25)

print(plot_rezonings(dt_app, "Fairfax County", "Area"))
ggsave("paper/figures/fairfax/plot_fairfax_exempt_areas.png",
    width = 8, height = 4.25)
