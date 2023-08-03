rm(list = ls())
pacman::p_load(here, data.table, ggplot2, xtable)

v_palette <- c("#0072B2", "#D55E00", "#009E73", "#F0E460")

dt <- readRDS(here("derived", "Revenues (2004-2022).Rds"))

dt[, isTown := (locality_type == 3)]
dt[, `Proffer Share (%)` :=
    `Cash Proffer Revenue` / `Local Revenue` * 100]
dt[, Post := (FY >= 2017)]

dt_year <- dt[, .(`Cash Proffer Revenue` = sum(`Cash Proffer Revenue`),
    `Total Revenue` = sum(`Total Revenue`),
    `Local Revenue` = sum(`Local Revenue`)),
    by = .(FY, isTown)
]

# Proffer Revenues by FY ----
# (Excludes towns)
ggplot(
    data = dt_year[isTown == FALSE],
    aes(x = FY, y = `Cash Proffer Revenue` / 1000000)
) +
    geom_point(size = 3, color = v_palette[1]) +
    geom_line(linetype = "dashed", alpha = .6, color = v_palette[1]) +
    geom_vline(xintercept = 2016) +
    scale_y_continuous(breaks = seq(0, 120, 20), limits = c(0, 120)) +
    labs(y = "Proffer Revenues ($ millions)", x = "Fiscal Year") +
    theme_light(base_size = 12)
ggsave("paper/figures/proffer_revenues.pdf", width = 8, height = 6)

# % of Local
ggplot(
    data = dt_year[isTown == FALSE & !is.na(`Local Revenue`)],
    aes(x = FY, y = `Cash Proffer Revenue` / `Local Revenue` * 100)
) +
    geom_point(size = 3, color = v_palette[1]) +
    geom_line(linetype = "dashed", alpha = .6, color = v_palette[1]) +
    geom_vline(xintercept = 2016) +
    scale_y_continuous() +
    labs(y = "Proffer Revenue Share (%)", x = "Fiscal Year") +
    theme_light(base_size = 12)

# Top Proffer Localities ----
dt_top <- dt[FY < 2022]
dt_top <- dt_top[, .(`Cash Proffer Revenue` = sum(`Cash Proffer Revenue`),
    `Local Revenue` = sum(`Local Revenue`)), by = .(Name, Post, isTown)]

dt_top[, `Proffer Share (%)` := `Cash Proffer Revenue` / `Local Revenue` * 100]
setorder(dt_top, -`Proffer Share (%)`)

xtable(dt_top[isTown == FALSE & Post == FALSE & `Cash Proffer Revenue` > 0,
              .(Name, `Cash Proffer Revenue`, `Local Revenue`,
                `Proffer Share (%)`)],
       digits = c(0, 0, 0, 0, 1))
