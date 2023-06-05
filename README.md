# bargaining-upzone
How does bargaining between local governments and residential developers affect the housing market?

# TODO
Diff-in-diff:
- aggregate to quarterly
- use a synthetic control based on all other US counties (not just VA)

Data:
- Download parcel boundaries + local schema tables and read into R (https://vgin.vdem.virginia.gov/pages/cl-data-download)
- If necessary, look county-by-county for zoning data (e.g., https://www.albemarle.org/government/information-technology/geographic-information-system-gis-mapping/gis-data)

# Data
GIS Data:
- Parcel boundaries: https://vgin.vdem.virginia.gov/datasets/virginia-parcels/about

## Notes from John McGlennon on 6/5/2023
Questions:
In general, how much of a premium do you think local governments put on cash over in-kind proffers? 

There's been a huge increase in the amount of cash proffer revenue collected by VA localities in the last two decades. What's behind this trend, and is it likely to continue?

I understand that the bulk of reported cash proffer revenue comes from single-family residential uses. Is that correct? Do you have a ballpark guess on what fraction of proffer revenue comes from single-family residential, multi-family residential, and commercial development?

Do you have suggestions for how to collect data on individual rezoning negotiations? The DCHD survey has yearly totals, but it would be great to see more detail: the characteristics of the development, the non-cash proffers, the original land use, etc.

I've looked at whether the 2016 Proffer Reform Act had any effect on the number of approved single-family building permits for localities that routinely collected cash proffers. The diff-in-diff estimates are imprecise, but they indicate a ~10% decrease. Does that strike you as plausible?

I appreciate any insight into the political economy of the 2016 reform, the 2019 fix, and what might be next.

More broadly, I'm curious how Virginia conditional zoning policy differs from other states.



## Notes from Joe Lerch (VACo Director of Local Govt. Policy) on 4/5/2023
2016/2019 Reforms:
- 2016 "created some problems for approving new development"
- 2019 changes specifically affected NOVA
- Developers agreed that the post-2016 situation was unproductive

In general, eligibility status due to decennial Census growth rates is not an issue.

Most cash proffer revenue is from single-family development "is my guess"

Some possibility of surveying the Coalition of High Growth Communities.

APFO is VACo's preferred policy.

## Notes from Federico 3/13/2023
Consider using a 2nd price auction:
- Need to know who the possible builders are
- Need to consider strategic interactions


