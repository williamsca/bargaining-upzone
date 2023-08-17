# This script imports the rezoning applications from the Prince William County
# archive:
# https://egcss.pwcgov.org/SelfService#/search?m=1&fm=1&ps=10&pn=1&em=true&st=rezoning

# Note: I had to open these .csv files with Excel and re-save them to
# get 'fread' to work.

rm(list = ls())
pacman::p_load(here, data.table)

# Import ----
dt <- fread("data/PrinceWilliamCo/Applications/Rezoning1-1000.csv", fill = TRUE)


