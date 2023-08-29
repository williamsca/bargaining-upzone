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

# Approved Residential Rezonings by Application Year

plot_rezonings <- function(county, data, outcome = "nApproved") {
    dt_graph <- data[isResi == TRUE & isApproved == TRUE &
                     County == county]

    min_year <- max(min(data$FY), 2010)
    max_year <- min(max(data$FY), 2020)

    dt_yr <- CJ(
        FY = seq(min_year, max_year),
        isExempt = c(TRUE, FALSE)
    )

    dt_graph <- dt_graph[, .(nApproved = .N, Area = sum(Area)),
        by = .(FY, isExempt)
    ]

    dt_yr <- merge(dt_yr, dt_graph,
        by = c("FY", "isExempt"),
        all.x = TRUE)

    dt_yr[is.na(nApproved), nApproved := 0]
    dt_yr[is.na(Area), Area := 0]

    y_lab <- fifelse(outcome == "nApproved",
        "Rezonings [#]",
        "Rezonings")

    g <- ggplot(
        dt_yr,
        aes(
            x = FY, y = .data[[outcome]], group = isExempt,
            color = isExempt
        )
    ) +
        geom_rect(aes(xmin = 2017, xmax = 2019, ymin = -Inf, ymax = Inf),
            fill = "lightgray", alpha = .2
        ) +    
        geom_line(linetype = "dashed") +
        geom_point(size = 3) +
        scale_x_continuous(breaks = seq(2010, 2020, 2)) +
        labs(
            y = y_lab,
            x = "Submit FY",
            title = county) +
        
        scale_color_discrete(name = "", labels = c("Affected", "Exempt")) +
        theme_light(base_size = 12) +
        theme(legend.pos = c(.1, .9))

    return(g)
}

# Counts
l_counts <- lapply(v_counties, plot_rezonings,
    data = dt_app, outcome = "nApproved")

g_counts <- do.call(grid.arrange, l_counts)

ggsave(here("paper", "figures", "plot_rezonings_exempt_counts.png"),
    width = 8, height = 4.25)

# Areas
l_areas <- lapply(v_counties, plot_rezonings,
    data = dt_app, outcome = "Area")

g_areas <- do.call(grid.arrange, l_areas)


# Fairfax
print(plot_rezonings(dt_app, "Fairfax County", "nApproved"))
ggsave("paper/figures/fairfax/plot_fairfax_exempt_counts.png",
    width = 8, height = 4.25)

print(plot_rezonings(dt_app, "Fairfax County", "Area"))
ggsave("paper/figures/fairfax/plot_fairfax_exempt_areas.png",
    width = 8, height = 4.25)
