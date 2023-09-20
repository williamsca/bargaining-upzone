---
title: Rezoning Data Collection
author: Colin Williams
---

 # Overview

 All data should (eventually) be uploaded to OneDrive.

## Virginia

 The table describes where and how I collected data on rezoning applications in Virginia counties. There are several types of data:
 - BoS Minutes/Summaries/Resolutions: details about the Board of Supervisor's decision on rezoning application
 - GIS: the current zoning map, which sometimes has information on the zoning history
 - Rezoning App: rezoning application submitted by developers
 - Rezoning Docs: documents (proffers, plans, planning department reports, etc.) related to a rezoning application
 - Rezoning GIS: polygons with associated zoning case numbers

 |County|Data|Span|Method|Link|Notes|
 |-|-|-|-|-|-|
 Albemarle|Rezoning Docs|Manual|2014-2019|[Archive](https://lfweb.albemarle.org/WebLink/Browse.aspx?id=107543&dbid=0&repo=CountyofAlbemarle)
 Caroline|BoS Minutes|Unavailable
 Chesterfield|Rezoning App|2009-2023 YTD|Manual|[Archive](https://aca-prod.accela.com/CHESTERFIELD/Cap/CapHome.aspx?module=Planning&TabName=Planning&TabList=Home%7C0%7CBuilding%7C1%7CEnforcement%7C2%7CEnvEngineering%7C3%7CPlanning%7C4%7CUtilities%7C5%7CeReview%7C6%7CCurrentTabIndex%7C4)
 Chesterfield|GIS||Webscrape|
 Chesterfield|BoS Summary|2014-2018|Manual|[Archive](https://documents.chesterfield.gov/Weblink_BOS/CustomSearch.aspx?SearchName=BoardDocumentsSearch)
 Fairfax City|BoS Summary|2014-2020m2 (no Special Meetings)|Manual|[Archive](https://www.fairfaxva.gov/services/about-us/city-meetings)
 Fairfax|Rezoning App|2010-2020|Webscrape|[Archive](https://plus.fairfaxcounty.gov/CitizenAccess/Default.aspx)
 Fairfax|BoS Minutes|2013-2020m2|Manual|[Archive](https://www.fairfaxcounty.gov/boardofsupervisors/board-meeting-summaries)
 Fairfax|GIS||Manual|[Archive](https://www.fairfaxcounty.gov/maps/open-geospatial-data)
 Fairfax|Small Area Plan||Manual|[Archive](https://www.fairfaxcounty.gov/maps/open-geospatial-data)
 Frederick|BoS Resolutions|FY2014-2020|Manual|[Archive](https://fclfweblinkpub.fcva.us/WebLink/?dbid=0&repo=Frederick-County-Admin)
 Frederick|BoS Minutes|FY2014-2015|Manual|[Archive](https://fclfweblinkpub.fcva.us/WebLink/?dbid=0&repo=Frederick-County-Admin)
 Goochland|BoS Minutes|FY2014-2019|Manual|[Archive](https://goochlandcountyva.iqm2.com/Citizens/calendar.aspx?From=1%2f1%2f2023&To=12%2f31%2f2023)
 Goochland|GIS||Email|
 Hanover|BoS Minutes|FY2013-2019|Manual|[Archive](http://weblink.mccinnovations.com/WebLink/?dbid=5)
 Isle of Wight|BoS Minutes|FY2013-2019|Manual|[Archive](https://lfweb.isleofwightus.net/WebLink/Browse.aspx?id=422&dbid=1&repo=CountyAdministration)
 Loudoun|BoS Minutes|||[Archive](https://www.loudoun.gov/3426/Board-of-Supervisors-Meetings-Packets)
 Loudoun|GIS||Email|
 Loudoun|Small Area Plan||Manual|[Archive](https://geohub-loudoungis.opendata.arcgis.com/datasets/LoudounGIS::loudoun-small-area-plans/about)
 Loudoun|Rezoning App|1994m3-2023m7|Manual|[Archive](https://loudouncountyvaeg.tylerhost.net/prod/selfservice#/search)
 Prince William|Rezoning App|2006m9-2023m7|Manual|[Archive](https://egcss.pwcgov.org/SelfService#/search)
 Prince William|GIS||Manual|[Archive](https://gisdata-pwcgov.opendata.arcgis.com/datasets/PWCGOV::zoning/about)
 Stafford|Rezoning App|||[Archive](https://pob.staffordcountyva.gov/PublicAccess/)
 Henrico|Rezoning GIS|1962-2023|Manual|[Archive](https://data-henrico.opendata.arcgis.com/datasets/Henrico::planning-department-cases/about)
 Stafford County|Rezoning App|||[Archive](https://staffordcountyva.gov/government/departments_p-z/planning_and_zoning/development_review/current_development_projects/index.php)
 Spotsylvania County|Rezoning App|||[Pending](https://www.spotsylvania.va.us/2074/Status-of-Applications)|Evidence that counties care about proffer legislation
 Spotsylvania County|BoS Minutes|||[Archive](https://www.spotsylvania.va.us/DocumentCenter/Index/574)|Only source for rezonings (see email), but no proffer details
 Spotsylvania County|Planning Commission Agendas||Manual|[Archive](https://spotsylvania.novusagenda.com/agendapublic/)|2014 annual report may be useful (".../Agenda_2014_3_5_Meeting(142).pdf")
 Hanover County|Rezoning App|||[Archive](https://communitydevelopment.hanovercounty.gov/eTRAKiT/Search/project.aspx)
 Montgomery County|BoS Minutes|||[Archive](https://go.boarddocs.com/va/montva/Board.nsf/Public)
 Williamsburg City|
 Prince George County|
 Manassas Park City|
 Manassas City|
 Chesapeake City|

 ## Maryland
|County|Type|Link|
|-|-|-|
|Montgomery|Council Actions|[Archive](https://www.montgomerycountymd.gov/OZAH/Zoning_council_actions.html)|

 # Details

 ## Loudoun County
  A large number of Loudoun rezonings are 'Zoning Conversions' (ZRTD), which evidently update the parcel from the 1972 Zoning Ordinance to a Revised 1993 Ordinance while preserving the same zone code. It is not clear whether this is a significant change. A superset of these cases are identified when 'zoning_old' == 'zoning_new'. 
