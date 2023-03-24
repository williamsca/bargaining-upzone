# Regression analysis of cash proffer eligibility on building permits
# Author: Colin Williams
# Updated: 24 March 2023

rm(list = ls())

dir <- dirname(dirname(rstudioapi::getSourceEditorContext()$path))
setwd(dir)

pacman::p_load(data.table, stargazer, ggplot2) 

dt <- readRDS("derived/Regression Sample.Rds")

# Summary statistics by treatment status ----
dt[, Units2p := Units2 + `Units3-4` + `Units5+`]
dt[, Value2p := Value2 + `Value3-4` + `Value5+`]

stargazer(dt, summary = TRUE, keep = c("isEligible", "Units1", "Value1", "Units2p", "Value2p"),
          type = "text", digits = 0)

# Diff-in-Diff using 2016 reform ----

# * Graphical analysis ----
dt.means <- dt[, .(Units1 = mean(Units1), Units2p = mean(Units2p), Units5p = mean(`Units5+`)), by = .(Year4, FIPS.Code.State)] # isEligible

ggplot(dt.means, mapping = aes(x = Year4, y = Units5p, color = FIPS.Code.State)) + # group = FIPS.Code.State
  geom_point() +
  geom_line() +
  geom_vline(xintercept = 2016) # Policy in effect July 1, 2016 (https://lis.virginia.gov/cgi-bin/legp604.exe?191+ful+SB1373ER+pdf)




