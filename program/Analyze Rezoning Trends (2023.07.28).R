# Performs a preliminary analysis of trends in rezoning across
# the Virginia counties that collect the most revenue from cash
# proffers.

rm(list = ls())
pacman::p_load(here, data.table, ggplot2)

# Import ----
dt_chesterfield <- readRDS(
    "derived/ChesterfieldCo/GIS Rezonings (2023.07.28).RDS"
)
dt_fairfax <- readRDS("derived/FairfaxCo/Rezoning Applications (2010-2020).Rds")

# Chesterfield County ----
# All Rezoning Applications by Year
ggplot(dt_chesterfield, aes(x = year(final_date), fill = Status)) +
    geom_bar(position = "stack") +
    theme_light()

# Approved Rezonings, w/ and w/o Cash Proffers, by Year
ggplot(
    dt_chesterfield[Status == "Approved"],
    aes(x = format(final_date, "%Y-%m"), fill = as.factor(CashProffer))
) +
    geom_bar(position = "stack") +
        theme_light()
