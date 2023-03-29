# Regression analysis of cash proffer eligibility on building permits
# Author: Colin Williams
# Updated: 24 March 2023

rm(list = ls())

dir <- dirname(dirname(rstudioapi::getSourceEditorContext()$path))
setwd(dir)

pacman::p_load(data.table, stargazer, ggplot2) 

dt <- readRDS("derived/Regression Sample.Rds")

# Counties and cities that collected >50k in cash proffer revenue in FY2016
v.collected2016 <- c("Accomack", "Albemarle", "Amelia", "Caroline", "Chesterfield", 
                     "Fairfax", "Fauquier", "Frederick", "Gloucester", "Goochland", 
                     "Hanover", "Isle of Wight", "James City", "King William",
                     "Loudoun", "New Kent", "Powhatan", "Prince William",
                     "Rockingham", "Spotsylvania", "Stafford", "Warren", "York")
v.collected2016 <- c(paste0(v.collected2016, " County"), "Charlottesville City",
                     "Chesapeake City", "Fairfax City", "Fredericksburg City",
                     "Manassas City", "Manassas Park City", "Suffolk City")

dt[, collect2016 := (Name %in% v.collected2016)]

# Summary statistics by treatment status ----
dt[, Units2p := Units2 + `Units3-4` + `Units5+`]
dt[, Value2p := Value2 + `Value3-4` + `Value5+`]

stargazer(dt, summary = TRUE, keep = c("isEligible", "Units1", "Value1", "Units2p", "Value2p"),
          type = "text", digits = 0)

# Diff-in-Diff using 2016 reform ----

# * Graphical analysis ----
dt.sample <- dt[FY %between% c(2012, 2022)]

lm <- lm(Value2p ~ as.factor(collect2016) + as.factor(Date), dt.sample)
# stargazer(lm, type = "text")

dt.sample$res <- residuals(lm)

dt.means <- dt.sample[, .(meanRes = mean(res)), by = .(Date, Year4, Month, collect2016)]

ggplot(dt.means[Year4 >= 2012], mapping = aes(x = Date, y = meanRes, group = collect2016, color = as.factor(collect2016))) + 
  geom_point() +
  geom_line() +
  geom_vline(xintercept = as.Date("2016-07-01")) # Policy in effect July 1, 2016 (https://lis.virginia.gov/cgi-bin/legp604.exe?191+ful+SB1373ER+pdf)

dt.means <- dt[, .(Units1 = mean(Units1), Units2p = mean(Units2p), Units5p = mean(`Units5+`)), 
               by = .(Date, Year4, Month, collect2016)] 

ggplot(dt.means[Year4 >= 2012], mapping = aes(x = Date, y = Units2p, group = collect2016, 
                                              color = as.factor(collect2016))) + 
  geom_point() +
  geom_line() +
  geom_vline(xintercept = as.Date("2016-07-01")) # Policy in effect July 1, 2016 (https://lis.virginia.gov/cgi-bin/legp604.exe?191+ful+SB1373ER+pdf)

