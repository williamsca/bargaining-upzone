# Performs a preliminary analysis of trends in rezoning across
# the Virginia counties that collect the most revenue from cash
# proffers.

rm(list = ls())
pacman::p_load(here, data.table, ggplot2, lubridate)

# Import ----
dt_chesterfield <- readRDS(
    "derived/ChesterfieldCo/GIS Rezonings (2023.07.28).RDS"
)
dt_fairfax <- readRDS("derived/FairfaxCo/Rezoning Applications (2010-2020).Rds")

# Chesterfield County ----
dt_chesterfield[, final_date_yq := floor_date(final_date, "quarter")]

# All Rezoning Applications by Month
ggplot(dt_chesterfield, aes(x = final_date_yq, fill = Status)) +
    geom_bar(position = "stack") +
    theme_light() +
    scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
    labs(y = "Number of Rezoning Applications", x = "")

# Approved Rezonings, w/ and w/o Cash Proffers, by Year
ggplot(
    dt_chesterfield[Status == "Approved" & year(final_date) >= 2013],
    aes(x = final_date_yq, fill = as.factor(CashProffer))
) +
    geom_bar(position = "stack") +
    theme_light() +
    geom_vline(
        xintercept = as.numeric(ymd("2016-07-01")),
        color = "gray", size = 1, linetype = "dashed"
    ) +
    scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
    labs(y = "Number of Approved Rezonings", x = "") +
    scale_fill_discrete(name = "Cash Proffer", labels = c("No", "Yes"))

# Fairfax County ----
dt_fairfax[, submit_quarter := floor_date(submit_date, "quarter")]
dt_fairfax <- dt_fairfax[submit_date == original_submit]

ggplot(dt_fairfax[year(submit_quarter) >= 2014],
    aes(x = submit_quarter, fill = Status)
) +
    geom_bar() +
    scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
    labs(y = "Number of Rezoning Applications", x = "") +
    geom_vline(xintercept = as.numeric(ymd("2016-07-01")),
        color = "gray", linetype = "dashed") +
    theme_light()

