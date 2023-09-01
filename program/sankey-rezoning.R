# This script constructs a Sankey Diagram to show
# flows of land use over time

# See the following for details:
# https://plotly.com/r/sankey-diagram/

rm(list = ls())
library(here)
library(data.table)
library(networkD3)

# Import ----
dt <- readRDS(here("derived", "county-rezonings.Rds"))

# Prince William ----
dt_pwc <- dt[County == "Prince William County" &
             isApproved == TRUE &
             zoning_new != "" & zoning_old != ""]

# Assume first code applies to the majority of the parcel
dt_pwc[grepl(",", zoning_old),
    zoning_old := substr(zoning_old, 1, regexpr(",", zoning_old) - 1)]
dt_pwc[grepl(",", zoning_new),
    zoning_new := substr(zoning_new, 1, regexpr(",", zoning_new) - 1)]

# Aggregate codes
v_zoning <- c("zoning_old", "zoning_new")

for (col in v_zoning) {
    dt_pwc[get(col) %in% c("O(F)", "O(H)", "O(L)", "O(M)"), (col) := "O"]
    dt_pwc[get(col) %in% c("M-1", "M-2", "M/T"), (col) := "M"]
    dt_pwc[get(col) %in% c("B-1", "B-2", "PBD"), (col) := "B"]
    dt_pwc[get(col) %in% c("SR-1", "SR-5", "SR-1C"), (col) := "SR"]
    dt_pwc[get(col) %in% c("R-16", "R-4", "R-6", "R-30", "RPC"),
        (col) := "R"]
    dt_pwc[get(col) %in% c("PMR", "PMD", "V"), (col) := "Mixed"]
}

dt_sankey <- dt_pwc[, .(Area = sum(Area, na.rm = TRUE)),
                    by = .(zoning_old, zoning_new)]

v_nodes <- c("O", "M", "B", "SR", "R", "Mixed", "A-1")
dt_nodes <- data.table(name = v_nodes)

dt_sankey[, source_index := match(zoning_old, v_nodes) - 1]
dt_sankey[, target_index := match(zoning_new, v_nodes) - 1]

sankey <- sankeyNetwork(Links = dt_sankey, Nodes = dt_nodes,
    Source = "source_index", Target = "target_index", NodeID = "name",
    Value = "Area", units = "Acres")

sankey