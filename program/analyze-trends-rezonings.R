# Performs a preliminary analysis of trends in rezoning across
# the Virginia counties that collect the most revenue from cash
# proffers.

rm(list = ls())

library(data.table)
library(ggplot2)
library(gridExtra)
library(grid)
library(units)
library(lubridate)
library(here)

v_palette <- c("#0072B2", "#D55E00", "#009E73", "#F0E460")

# Import ----
dt <- readRDS(here("derived", "county-rezonings-panel.Rds"))

uniqueN(dt[, .(FIPS, date, type)]) == nrow(dt)

dt_hy_units <- dt[has_units == TRUE & County != "Spotsylvania County",
    .(tot_units = sum(n_units), n_sfd = sum(n_sfd), n_other = sum(n_other)),
    by = .(date = floor_date(date, "halfyear") + months(3), type)]
dt_hy_units[, n_units_pct := (tot_units / sum(tot_units)) * 100, by = type]
dt_hy_units <- melt(dt_hy_units, measure.vars = c("n_sfd", "n_other"),
                    variable.name = "type_units", value.name = "n_units")

# Plots ----
unique(dt[has_units == TRUE & type == "final", County])
unique(dt[has_units == TRUE & type == "submit", County])

ggplot(dt_hy_units[type == "submit"],
       aes(x = date, y = n_units, color = type_units)) +
    geom_rect(aes(xmin = ymd("2016/07/01"), xmax = ymd("2018/07/01"),
                  ymin = -Inf, ymax = Inf),
            fill = "lightgray", alpha = .2, color = "gray"
    ) +
    geom_hline(yintercept = 0, color = "gray") +
    geom_line(linetype = "dashed") + # color = v_palette[1]
    geom_point(size = 3) + # color = v_palette[1]
    scale_color_manual(values = v_palette,
                       breaks = c("n_sfd", "n_other"),
                       labels = c("Single-Family", "Other"),
                       name = "") +
    scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
    labs(y = "Approved Units (#)", x = "Submission Date",
         caption = "Source: Frederick, Loudoun, and Prince William Counties",
         title = "Approved Units by Submission Date") +
    theme_light(base_size = 12) +
    theme(plot.caption = element_text(hjust = 0, size = 10))
ggsave(here("paper", "figures", "plot_rezonings_submit.png"),
    width = 8, height = 4)

ggplot(
    dt_hy_units[type == "final" &
        date %between% c(ymd("2014/01/01", "2019/07/01"))],
    aes(x = date, y = n_units, color = type_units)
) +
    geom_rect(
        aes(
            xmin = ymd("2016/07/01"), xmax = ymd("2018/07/01"),
            ymin = -Inf, ymax = Inf
        ),
        fill = "lightgray", alpha = .2, color = "gray"
    ) +
    geom_hline(yintercept = 0, color = "gray") +
    geom_line(linetype = "dashed") +
    geom_point(size = 3) +
    scale_color_manual(values = v_palette,
                       breaks = c("n_sfd", "n_other"),
                       labels = c("Single-Family", "Other"),
                       name = "") +
    scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
    scale_y_continuous(limits = c(0, 1200)) +
    labs(
        y = "Approved Units (#)", x = "Approval Date",
        caption = "Source: Frederick, Goochland, Hanover, and Loudoun Counties",
        title = "Approved Units by Approval Date"
    ) +
    theme_light(base_size = 12) +
    theme(plot.caption = element_text(hjust = 0, size = 10))
ggsave(here("paper", "figures", "plot_rezonings_final.png"),
    width = 8, height = 4)

# Superseded ----
# Aggregate over parcels to application level
# Note: A Loudoun County rezonings application can be associated
# with distinct 'final_date' values, perhaps because the original proffers
# were later amended.
dt_app <- dt[,
    .(Area = sum(Area), isResi = any(isResi), isExempt = FALSE, # any(isExempt)
    n_units = sum(n_units), final_date = min(final_date)),
    by = .(FIPS, Case.Number, County, submit_date,
    Population2022, isApproved, FY, first_final, last_final)]

# Average time from submission to approval
dt_app[, time_to_approval := final_date - submit_date]
table(dt_app[!is.na(time_to_approval), County])

median(dt_app[isApproved == TRUE & time_to_approval >= 0]$time_to_approval, na.rm = TRUE)

# Approved Rezonings by Application Year
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

    min_year <- max(min(data[County == county]$FY), 2010)
    max_year <- min(max(data[County == county]$FY), 2020)

    if (any(dt_graph$isExempt) || resi == FALSE) {
        dt_yr <- CJ(
            FY = seq(min_year, max_year),
            comparison = c(TRUE, FALSE)
        )
    } else {
        dt_yr <- data.table(FY = seq(min_year, max_year),
            comparison = FALSE)
    }


    dt_graph <- dt_graph[
        , .(nApproved = .N, Area = drop_units(sum(Area)),
            n_units = sum(n_units)),
        by = .(FY, comparison)
    ]

    dt_yr <- merge(dt_yr, dt_graph,
        by = c("FY", "comparison"),
        all.x = TRUE
    )

    dt_yr[is.na(nApproved), nApproved := 0]
    dt_yr[is.na(Area), Area := 0]
    dt_yr[is.na(n_units), n_units := 0]

    return(dt_yr)
}

plot_rezonings <- function(county, data, outcome = "nApproved",
    resi = TRUE) {

    dt_yr <- sum_to_fy(county, data, resi)

    y_lab <- fcase(
        outcome == "nApproved", "Rezonings [#]",
        outcome == "Area", "Rezonings [acres]",
        outcome == "n_units", "Rezonings [units]"
    )

    if (resi == TRUE) {
        comp_labels <- c("Exempt", "Affected")
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
        geom_rect(aes(xmin = 2016.5, xmax = 2018.5, ymin = -Inf, ymax = Inf),
            fill = "lightgray", alpha = .2, color = "gray"
        ) +
        geom_line(linetype = "dashed") +
        geom_point(size = 3) +
        scale_x_continuous(breaks = seq(2009, 2019, 2),
            limits = c(2009, 2020)) +
        labs(
            y = y_lab,
            x = "Submit FY",
            title = county) +

        scale_color_discrete(name = "", labels = comp_labels,
            breaks = c(TRUE, FALSE)) +
        theme_light(base_size = 12) +
        theme(legend.pos = "none") # c(.1, .9)

    return(g)
}

plot_rezonings("Hanover County", dt_app,
    outcome = "n_units", resi = TRUE)

v_counties <- unique(dt$County)

# Counts
# * Residential
l_counts_resi <- lapply(v_counties, plot_rezonings,
    data = dt_app, outcome = "nApproved", resi = TRUE)
g_counts_resi <- do.call(grid.arrange, l_counts_resi)

# * All
l_counts_all <- lapply(v_counties, plot_rezonings,
    data = dt_app, outcome = "nApproved", resi = FALSE)
g_counts_all <- do.call(grid.arrange, l_counts_all)

ggsave(here("paper", "figures", "plot_rezonings_exempt_counts.png"),
    width = 8, height = 4.25)

# Areas
# * Residential
l_areas_resi <- lapply(v_counties, plot_rezonings,
    data = dt_app, outcome = "Area")
g_areas_resi <- do.call(grid.arrange, l_areas_resi)

# * All
l_areas_all <- lapply(v_counties, plot_rezonings,
    data = dt_app, outcome = "Area", resi = FALSE)
g_areas_all <- do.call(grid.arrange, l_areas_all)

# Units
v_counties <- c("Goochland County", "Prince William County", "Loudoun County", "Hanover County")
l_units_resi <- lapply(v_counties, plot_rezonings,
    data = dt_app, outcome = "n_units")
g_units_resi <- do.call(grid.arrange, l_units_resi)

# Fairfax
print(plot_rezonings(dt_app, "Fairfax County", "nApproved"))
ggsave("paper/figures/fairfax/plot_fairfax_exempt_counts.png",
    width = 8, height = 4.25)

print(plot_rezonings(dt_app, "Fairfax County", "Area"))
ggsave("paper/figures/fairfax/plot_fairfax_exempt_areas.png",
    width = 8, height = 4.25)
