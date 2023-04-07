# Regression analysis of cash proffer eligibility on building permits
# Author: Colin Williams
# Updated: 24 March 2023

rm(list = ls())

dir <- dirname(dirname(rstudioapi::getSourceEditorContext()$path))
setwd(dir)

pacman::p_load(data.table, stargazer, ggplot2, fixest) 

dt <- readRDS("derived/Regression Sample.Rds")

arcsinh <- function(x) log(x + sqrt(x^2+1))

# Counties and cities that collected >50k in cash proffer revenue in FY2016
v.collected2016 <- c("Accomack", "Albemarle", "Amelia", "Caroline", "Chesterfield", 
                     "Fairfax", "Fauquier", "Frederick", "Gloucester", "Goochland", 
                     "Hanover", "Isle of Wight", "James City", "King William",
                     "Loudoun", "New Kent", "Powhatan", "Prince William",
                     "Rockingham", "Spotsylvania", "Stafford", "Warren", "York")
v.collected2016 <- c(paste0(v.collected2016, " County"), "Charlottesville City",
                     "Chesapeake City", "Fairfax City", "Fredericksburg City",
                     "Manassas City", "Manassas Park City", "Suffolk City")

v.collected2016m <- c("Albemarle County", "Chesterfield County", "Fairfax County",
                      "Frederick County", "Hanover County", "Loudoun County", "Prince William County",
                      "Spotsylvania County", "Stafford County", "Chesapeake City",
                      "Manassas Park City")

dt[FIPS.Code.State == "51", treated := (Name %in% v.collected2016m)]

dt[, avgPermits1 := mean(Units1), by = .(FIPS.Code.State, Name)]
dt[FIPS.Code.State == "24", treated := (avgPermits1 >= 30)] # high-growth counties in MD

ggplot(data = dt[FIPS.Code.State == "51"], mapping = aes(x = Units1, color = treated)) +
  stat_ecdf()


# Summary statistics by treatment status ----
dt[, Units2p := Units2 + 3*`Units3-4` + 5*`Units5+`] # lower bound on multi-family units
dt[, Value2p := Value2 + `Value3-4` + `Value5+`]

stargazer(dt[FIPS.Code.State == "51" & treated == TRUE], summary = TRUE, 
          keep = c("Units1", "Value1", "Units2p", "Value2p"),
          type = "text", digits = 0)

stargazer(dt[FIPS.Code.State == "51" & treated == FALSE], summary = TRUE, 
          keep = c("Units1", "Value1", "Units2p", "Value2p"),
          type = "text", digits = 0)

stargazer(dt[FIPS.Code.State == "24"], summary = TRUE, keep = c("isEligible", "Units1", "Value1", "Units2p", "Value2p"),
          type = "text", digits = 0)


# Diff-in-Diff using 2016 reform ----

# * Graphical analysis ----
feols <- feols(log(Units1+1) ~ -1 + i(Date, treated, ref = as.Date("2016-06-01")) |
                 Date + as.factor(FIPS), cluster = "as.factor(FIPS)", data = dt[FIPS.Code.State == "51" & Year4 >= 2012])
etable(feols)
iplot(feols, lab.fit = "simple")

feols.zhvi <- feols(ZHVI ~ -1 + i(Date, treated, ref = as.Date("2016-06-01")) |
                 Date + as.factor(FIPS), cluster = "as.factor(FIPS)", data = dt[FIPS.Code.State == "51" & Year4 >= 2012])
etable(feols)
iplot(feols.zhvi, lab.fit = "simple")

# Triple-diff using MD high-growth counties as comparison ----
feols.trip <- feols(Units1 ~ -1 + as.factor(Date)*treated*FIPS.Code.State |
                      Name, data = dt, cluster = "Name")
etable(feols.trip)



