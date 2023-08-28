# Performs a preliminary analysis of trends in rezoning across
# the Virginia counties that collect the most revenue from cash
# proffers.

rm(list = ls())
library(data.table)
library(ggplot2)
library(units)
library(here)

# Import ----
dt <- readRDS(here("derived", "county-rezonings.Rds"))

# Aggregate over parcels to application level
dt_app <- dt[,
    .(Area = sum(Area), isResi = max(isResi), isExempt = max(isExempt)),
    by = .(FIPS, Case.Number, Status,
           County, submit_date, County, Population2022,
           isApproved, FY)]

uniqueN(dt_app$Case.Number) == nrow(dt_app)


# Plots ----
v_counties <- unique(dt$County)

# Approved Residential Rezonings by Application Year
ggplot(
    dt[isApproved == TRUE & FY %between% c(2010, 2020) & isResi == TRUE],
    aes(x = FY, group = isExempt)) +
    geom_bar(aes(fill = isExempt), position = "stack") +
    geom_vline(xintercept = 2016, color = "gray",
        linetype = "dashed") +
    labs(
        y = "Number of Approved Rezonings",
        x = "Submission Fiscal Year"
    ) +
    scale_x_continuous(breaks = seq(2010, 2020, 2))
    theme_light()


# Prince William County ----
dt_pwc[, FY := year(submit_date) +
    fifelse(month(submit_date) >= 7, 1, 0)]

dt_pwc <- dt_pwc[, .(nCases = .N), by = .(isResi, isApproved, FY)]

ggplot(
    dt_pwc[isApproved == TRUE & FY %between% c(2010, 2020)],
    aes(x = FY, y = nCases, group = isResi, color = isResi)
) +
    geom_line(linetype = "dashed") +
    scale_x_continuous(breaks = seq(2010, 2020, 2)) +
    geom_point() +
    theme_light() +
    geom_vline(
        xintercept = 2016,
        color = "gray",
        linewidth = 1, linetype = "dashed"
    ) +
    labs(y = "Approved Rezonings (#)", x = "Submission Fiscal Year")


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
        color = "gray", linewidth = 1, linetype = "dashed"
    ) +
    scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
    labs(y = "Number of Approved Rezonings", x = "Approval Date") +
    scale_fill_discrete(name = "Cash Proffer", labels = c("No", "Yes"))

ggsave("paper/figures/plot_chesterfield_approvals.pdf",
    width = 8, height = 4.25
)

# Fairfax County ----
sf_fairfax$submit_quarter <- floor_date(
    sf_fairfax$submit_date, "quarter")

sf_fairfax$Area <- st_area(sf_fairfax)

dt_fairfax <- as.data.table(sf_fairfax)
dt_fairfax <- dt_fairfax[, .(Area = sum(Area)),
    by = .(submit_quarter, submit_date, isResi, isExempt, Status,
           `Unique ID`)]

# Note: there are a handful of duplicates on `Unique ID` which are
# all either missing `submit_quarter` or have Status == "Dismissed"

dt_fairfax[, FY := year(submit_date) +
    fifelse(month(submit_date) >= 7, 1, 0)]

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

ggsave("paper/figures/fairfax/plot_fairfaxco_submissions.pdf",
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

# Exempt and non-exempt by fiscal year
dt_fairfax_yr <- CJ(
    FY = seq(2010, 2020),
    isExempt = c(TRUE, FALSE),
    isResi = c(TRUE, FALSE)
)

dt_fairfax_yr <- merge(dt_fairfax_yr,
    dt_fairfax[Status == "Approved", .(nApproved = .N, Area = sum(Area)),
        by = .(FY, isExempt, isResi)
    ]
, by = c("FY", "isExempt", "isResi"),
    all.x = TRUE)
dt_fairfax_yr[is.na(nApproved), nApproved := 0]
dt_fairfax_yr[is.na(Area), Area := 0]
dt_fairfax_yr[, Area := set_units(Area, "acre")]

# Counts
ggplot(dt_fairfax_yr[isResi == TRUE],
    aes(x = FY, y = nApproved, group = isExempt,
        color = isExempt)) +
    geom_line(linetype = "dashed") +
    geom_point() +
    scale_x_continuous(breaks = seq(2010, 2020, 2)) +
    labs(y = "Approved Rezonings (#)", x = "Submission Fiscal Year") +
    geom_vline(xintercept = 2016, color = "gray",
        linetype = "dashed") +
    scale_color_discrete(name = "", labels = c("Affected", "Exempt")) +
    theme_light(base_size = 12) +
    theme(legend.pos = c(.1, .9))
ggsave("paper/figures/fairfax/plot_fairfax_exempt_counts.png",
    width = 8, height = 4.25)

# Areas
ggplot(
    dt_fairfax_yr[isResi == TRUE],
    aes(
        x = FY, y = Area, group = isExempt, color = isExempt
    )
) +
    geom_line(linetype = "dashed") +
    geom_point() +
    labs(x = "Submission Fiscal Year", y = "Approved Rezonings") +
    scale_x_continuous(breaks = seq(2010, 2020, 2)) +
    geom_vline(
        xintercept = 2016, color = "gray",
        linetype = "dashed"
    ) +
    scale_color_discrete(name = "", labels = c("Affected", "Exempt")) +
    theme_light(base_size = 12) +
    theme(legend.position = c(.1, .9))
ggsave("paper/figures/fairfax/plot_fairfax_exempt_areas.png",
    width = 8, height = 4.25)
