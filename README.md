# bargaining-upzone
How does bargaining between local governments and residential developers affect the housing market?

# Proffer Reform Act of 2016
Great background article: https://www.williamsmullen.com/news/dissecting-proffer-reform-bill

# TODO
- Convert pdf files to text and save locally; upload raw pdfs to OneDrive
- Weight regressions by 2010 population
- Experiment with different treatment designations 
- Consider Ring Method (Diamond & McQuade (2019)) using location of large upzonings. Compare results to Hector Fernandez and Noemie Sportiche (2023).


## Data:
Albemarle County
- Archive: https://lfweb.albemarle.org/WebLink/Browse.aspx?id=107543&dbid=0&repo=CountyofAlbemarle
- Downloaded all ZMA files (staff reports, correspondence, and ordinances) 

Caroline County
- Archive: https://co.caroline.va.us/AgendaCenter/Board-of-Supervisors-2
- No BoS minutes
- Can get Planning Commission Actions: https://co.caroline.va.us/636/2014-Summary-of-Actions

Chesapeake City
- Archive: https://www.cityofchesapeake.net/1162/Agendas-Video
- BoS Minutes archive begins in 2020

Chesterfield County
- Archive: https://documents.chesterfield.gov/Weblink_BOS/CustomSearch.aspx?SearchName=BoardDocumentsSearch
- Downloaded all 'Summary' files for 2014-2019. May need to download 'Minutes' for further information. 
- Parsed 'Summary' files to get rezoning cases (see '.../derived/BoS Summary Raw Rezonings.csv'). TODO: filter to actual rezonings and manually input relevant details: old and new zoning codes, acreage, proffers, etc.

Fairfax City
- Archive: https://www.fairfaxva.gov/services/about-us/city-meetings
- Downloaded "Reporter" html files for 2014-2020m2
- TODO: "Reporter" files are parsed in '.../derived/FairfaxCity/BoS Reporter Raw Rezonings'. There are only five. Details are scant --> need to look in official minutes.
- NOTE: Only comprehensive for 'Regular Meetings'. May need to go back for 'Special Meetings'.

Fairfax County
- Rezoning Applications Archive: https://plus.fairfaxcounty.gov/CitizenAccess/Default.aspx. See '.../program/Scrape Rezoning Applications (2023.07.12).py'
- Downloaded BoS minutes for 2013-2020m2: https://www.fairfaxcounty.gov/boardofsupervisors/board-meeting-summaries
- Downloaded Rezoning GIS files: https://www.fairfaxcounty.gov/maps/open-geospatial-data

Frederick County
- Archive: https://fclfweblinkpub.fcva.us/WebLink/?dbid=0&repo=Frederick-County-Admin
- Downloaded all "Rezoning" resolutions for FY2014-2020
- Downloaded BOS minutes for 2014 and 2015
- TODO: use 'tesseract' to parse pdfs, see ".../program/Parse FrederickCo Rezonings (2023.07.28).R'

Goochland County
- Archive: https://goochlandcountyva.iqm2.com/Citizens/calendar.aspx?From=1%2f1%2f2023&To=12%2f31%2f2023
- Downloaded BoS minutes for 2014-2019

Hanover County
- Archive: http://weblink.mccinnovations.com/WebLink/?dbid=5
- Downloaded BoS minutes for 2014-2019

Isle of Wight County
- Archive: https://lfweb.isleofwightus.net/WebLink/Browse.aspx?id=422&dbid=1&repo=CountyAdministration
- Downloaded BoS minutes for 2013-2019

Loudoun County
- BoS Minutes: https://www.loudoun.gov/3426/Board-of-Supervisors-Meetings-Packets
- GIS data: https://www.loudoun.gov/3362/LOLA
- 8/7/2023: Emailed Loudoun Co Office of Mapping and GIS to request zoning map amendment database. Downloaded budget documents that map proffer revenue to rezoning cases. Conveniently, it looks like they track whether a zoning application is exempt from the 2016 reform or not, but need to confirm.

Manasses City

Manasses Park City

Prince George County

Prince William County
- Archive: https://www.pwcva.gov/department/planning-office/proffer-administration

Stafford County 
- Rezonings: https://pob.staffordcountyva.gov/PublicAccess/
- Search "Planning Department (Conditional Use Permits.....)" 
- Care: date filter appears not to work properly

Williamsburg City







# Data
GIS Data:
- Parcel boundaries: https://vgin.vdem.virginia.gov/datasets/virginia-parcels/about

This paper may be a useful reference for outcomes:
- https://ishanbhatt42.github.io/files/paper_adu.pdf

## Meetings
Leora (8/1/2023)
- Need to know if building is happening on recently rezoning properties
- Call up neighborhood services in Charlottesville and ask about the process of rezoning
- Would be nice to see the full process -- from planning committee to staff to board of supervisors
- Look at impact fees in other states

Ben (7/19/2023)
- The [NLCD](https://www.usgs.gov/centers/eros/science/national-land-cover-database) has data on the % of impervious land and distinguishes between low, medium, and high density land uses. In general, it is safe to assume that low and medium densities are single-family residential. Need to think about how policy will affect intensive and extensive margins of development.
- Is there leakage from high to low proffer counties?
- How much development did not happen? How much cash proffer revenue was lost?
- Think of policy as mandating a $0 price on rezoning
- What are the long-run impacts on urban structure? Do the effects persist?
- Need to collect rezoning applications in control counties. Choose a handful like Greene and Louisa with non-zero development but minimal proffer revenue.
- It is reasonable to think that the 2019 "fix" would not total reverse the effect of the reform, especially if there is hysteresis in land development.

## Notes from John McGlennon on 6/5/2023

### Questions:
Are high-growth counties satisfied with the current legal regime around cash proffers?
- The high-growth counties are generally happy to think about other ways to address the impact of growth. Constrained by a system that's been in place for decades.

In general, how much of a premium do you think local governments put on cash over in-kind proffers?
- Hard to judge because counties are so different.
- Potential for shifting from cash proffers to impact fees or offering developers a choice. Some localities are very happy with the existing system. Others, which have already rezoned lots of property but expect lots of development, would be happy to collect impact fees.
- e.g., proposed development scale is very different. "one size doesn't fit all". 

There's been a huge increase in the amount of cash proffer revenue collected by VA localities in the last two decades. What's behind this trend, and is it likely to continue?
- There is interest in impact fee legislation. One of the problems we had the last time that was proposed was that the Homebuilder's wanted the fees to be capped at such a low level that they wouldn't help localities pay for the infrastructure. There is interest in impact fees in addition to, or in lieu of, cash proffers.
- Yes, and probably because localities have been more systematic in looking at the costs incurred of new development. Localities experiencing pushback by existing residents who do not want their taxes to go up.
- Folks who are thinking about how to address these issues: in James City County, we have tried to address the impact of new residential development on affordable housing. We have one proffer on a fairly large development that includes \$1,000 per unit that goes towards affordable housing. Two million dollars into a housing trust fund to provide local housing voucher program. 

I understand that the bulk of reported cash proffer revenue comes from single-family residential uses. Is that correct? Do you have a ballpark guess on what fraction of proffer revenue comes from single-family residential, multi-family residential, and commercial development?
- The bulk probably comes from residential. Commercial is less expensive to provide public servies to. Typically, VDOT regulations require commercial developers to provide those.

Do you have suggestions for how to collect data on individual rezoning negotiations? The DCHD survey has yearly totals, but it would be great to see more detail: the characteristics of the development, the non-cash proffers, the original land use, etc.
- The challenge here is that this is not centrally collected. Will have to come from the localities. In July (13)?, Coalition of High-Growth Communities is sponsoring a workshop looking at infrastructure and housing committee regulation of zoning. Meeting is in Culpeper. Session from 9am-2:30pm.

I've looked at whether the 2016 Proffer Reform Act had any effect on the number of approved single-family building permits for localities that routinely collected cash proffers. The diff-in-diff estimates are imprecise, but they indicate a ~10% decrease. Does that strike you as plausible? Do you think there is any substitution between single- and multi-family housing?
- Primarily driven by homebuilders, who decided that they didn't want to have to deal with proffers any more. They "over-reached significantly" in terms of making it impossible for county elected officials to discuss any impacts a new development would have with developers. Created an imbalance where if localities suggest an impact, it would trigger "almost automatic approval".
- Local government officials were advised "don't talk to developers"
- What ultimately happened was that the legislation was changed so a developer could opt for the old system. My understanding is that developers recognize the their proposals will generate significant local costs and they made a mistake with the reform act.
- Fix occurred in 2018 or 2019.

I appreciate any insight into the political economy of the 2016 reform, the 2019 fix, and what might be next.

More broadly, I'm curious how Virginia conditional zoning policy differs from other states.
- Virginia does not allow impact fees, which are commonly used elsewhere. Proffers are only available when there is a rezoning, while impact fees can be applied to any new development. 

[Cash proffer revenue as a share of all revenue]


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


