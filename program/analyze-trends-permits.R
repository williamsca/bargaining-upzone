rm(list = ls())

library(data.table)
library(here)
library(lubridate)
library(ggplot)

# Import ----
dt <- readRDS("derived/sample.Rds")
dt_fairfax <- readRDS("derived/FairfaxCo/Building Permits (2012-2019).Rds")

# lower bound on multi-family units
dt[, Units2p := Units2 + `Units3-4` + `Units5+`]

# Treatment Indicator ----
INTENSITY_THRESHOLD <- 0.01

dt[FY == 2016, everTreated := fifelse(
    intensity12_16 > INTENSITY_THRESHOLD, 1, 0
)]
dt[is.na(everTreated), everTreated := 0]
dt[, everTreated := max(everTreated), by = FIPS]

# Quarterly Aggregates ----
dt_qtr <- dt[, .(
    Units1 = sum(Units1), Units2p = sum(Units2p),
    ZHVI = mean(ZHVI)
),
by = .(FIPS, Name,
    Date = quarter(Date, type = "date_first"), `Cash Proffer Revenue`,
    everTreated, FY, intensity12_16
)
]

# Single-Unit Building Permits by Month ----
c_treated <- unique(dt[everTreated == 1, Name])

for (county in c_treated) {
    print(ggplot(
        dt_qtr[Name == county & FY >= 2012],
        aes(x = Date, y = Units1)
    ) +
        geom_line(linetype = "dashed", color = "gray") +
        geom_point(size = 3, color = "black") +
        labs(
            title = "Single-Unit Building Permits",
            subtitle = paste0(county, ", VA"),
            x = "Date", y = "Permits"
        ) +
        geom_vline(
            xintercept = as.Date("2017-01-01"),
            linetype = "dashed"
        ) +
        theme_light() +
        theme(plot.caption = element_text(hjust = 0)))
}

# Fairfax County ----
ggplot(dt[Name == "Fairfax County" & Year4 %between% c(2012, 2019)],
       aes(x = Date, y = Units1)) +
geom_line() +
labs(
    title = "Single-Unit Building Permits",
    subtitle = "Fairfax County, VA",
    x = "Date", y = "Permits"
) +
theme_light() +
theme(plot.caption = element_text(hjust = 0))

ggplot(dt_fairfax, aes(x = submit_month, fill = `Record Type`)) +
    geom_bar(position = "stack") +
    labs(
        title = "Building Permits",
        subtitle = "Fairfax County, VA",
        x = "Date", y = "Permits"
    ) +
    theme_light() +
    theme(plot.caption = element_text(hjust = 0))
