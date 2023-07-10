rm(list = ls())
pacman::p_load(here, data.table, ggplot2)

v_palette <- c("#0072B2", "#D55E00", "#009E73", "#F0E460")

dt <- readRDS(here("derived", "Sample.Rds"))

dt_va <- unique(dt[
    FIPS.Code.State == "51",
    .(FY, `Cash Proffer Revenue`, FIPS.Code.County)
])
dt_va <- dt_va[, .(`Cash Proffer Revenue` = sum(`Cash Proffer Revenue`)),
    by = .(FY)
]

# Proffer Revenues by FY ----
# (Excludes towns)
ggplot(
    data = dt_va[FY > 2003],
    aes(x = FY, y = `Cash Proffer Revenue` / 1000000)
) +
    geom_point(size = 3, color = v_palette[1]) +
    geom_line(linetype = "dashed", alpha = .6, color = v_palette[1]) +
    geom_vline(xintercept = 2016) +
    scale_y_continuous(breaks = seq(0, 120, 20), limits = c(0, 120)) +
    labs(y = "Cash Proffer Revenues ($ millions)", x = "Fiscal Year") +
    theme_light(base_size = 12)
ggsave("paper/figures/proffer_revenues.pdf", width = 8, height = 6)
