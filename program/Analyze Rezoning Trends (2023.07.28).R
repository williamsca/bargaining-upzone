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

# All Rezoning Applications by Quarter
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
    labs(y = "Number of Approved Rezonings", x = "Approval Date") +
    scale_fill_discrete(name = "Cash Proffer", labels = c("No", "Yes"))

ggsave("paper/figures/plot_chesterfield_approvals.pdf",
    width = 8, height = 4.25
)

# Fairfax County ----
dt_fairfax[, submit_quarter := floor_date(submit_date, "quarter")]
dt_fairfax <- dt_fairfax[submit_date == original_submit]

# All Rezoning Applications by Quarter
ggplot(dt_fairfax[year(submit_quarter) >= 2014],
    aes(x = submit_quarter, fill = Status)
) +
    geom_bar() +
    scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
    labs(y = "Number of Rezoning Applications", x = "Submission Date") +
    geom_vline(xintercept = as.numeric(ymd("2016-07-01")),
        color = "gray", linetype = "dashed") +
    theme_light()

ggsave("paper/figures/plot_fairfaxco_submissions.pdf",
    width = 8, height = 4.25
)

# Approved Rezonings by Quarter
ggplot(
    dt_fairfax[year(submit_quarter) >= 2014 & Status == "Approved"],
    aes(x = submit_quarter)
) +
    geom_bar() +
    scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
    labs(y = "Number of Rezoning Applications", x = "Submission Date") +
    geom_vline(
        xintercept = as.numeric(ymd("2016-07-01")),
        color = "gray", linetype = "dashed"
    ) +
    theme_light()

