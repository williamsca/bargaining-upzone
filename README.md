# bargaining-upzone
How does bargaining between local governments and residential developers affect the housing market?

# Proffer Reform Act of 2016
Great background article: https://www.williamsmullen.com/news/dissecting-proffer-reform-bill

# Goal
Create a panel of all rezoning applications in Virginia counties. Each rezoning should, at minimum, include:
- Submission date
- Type (residential, commercial, etc.)
- Address or polygon
- Status (approved, denied, withdrawn, etc.)

# TODO
- Power calculations?
- Import Loudoun value of in-kind proffer data, look at trends and compare to cash proffers (See 'Proffer Fund' or 'PUBLIC FACILITIES FUND' [here](https://www.loudoun.gov/1474/Budget-Archives))
- Literature review. Connect PRA16 to other policies to buttress part one results. See [Bethany Berger (2009)](https://proxy1.library.virginia.edu/login?url=https://heinonline.org/HOL/P?h=hein.journals/flr78&i=1287) on Measure 37, an Oregon initiative that called for compensation for land regulations (Fischel 2005, 6.14-15)
- Figure out how 'Applied.Date' can different from the date the rezoning request was recieved for PWC, Loudoun (e.g., see PWC Case.Number == REZ2017-00024 and read the Description)
- Parse 'Description' for PWC and Loudoun to get zoning codes. (For PWC, Type == "Rezoning - Mixed Use" does not always include housing.) See TODO in 'databuild-princewilliam.R'

# Done
- Add Fairfax to combined application file
- hand parse Frederick resolutions (see '.../derived/FrederickCo/resolutions.csv')
- Determine whether Loudoun rezonings are in exempt areas using GIS file



## Data:

See [Data Notes](notes/rezoning-data-notes.md) for details on how I collected the data.

# Abstract
> Statewide zoning reforms may fail to increase housing supply if local governments can respond along unregulated margins. I study the policy response of Virginia counties to a 2016 statewide reform that restricted their ability to charge developers for residential upzonings. I find that upzoning is highly price elastic: after the reform, the number of housing units allowed through residential upzonings fell by [X]\%. In counties which were partially exempted from the reform, however, total activity remained constant as localities substituted upzoning from affected to exempt areas. Rather than playing ``whack-a-mole'' with local zoning ordinances, states should directly subsidize the number of newly-permitted housing units.


# Model
## Version 1
Locality chooses vector $\vec{a}$ of upzonings over parcels $j \in \{1, ..., J\}$ to maximize welfare: 
$$U = \max_{\vec{a}} \sum_{j=1}^J a_j(p_j + v_{j}q_j) - C\left(\sum_{j=1}^Ja_jq_j\right)$$

where $p_j$ is the dollar value of the proffer, $v_{j}$ is a stochastic shock to the value of upzoning the parcel, $q_j$ is the area of the parcel, and $C(\cdot)$ is a cost function that is increasing in the total area of upzoned land across the locality.

Let $Q_{-j}$ be the total area of upzoned land not counting parcel $j$. The optimum is characterized by $J$ inequalities: 
$$p_j + v_{j}q_j > C(q_j + Q_{-j}) - C(Q_{-j})$$

Estimate by GMM where $p_j$, $q_j$ are data, $v_j$ is T1EV, and assume a parametric form for $C(\cdot)$. (See IO notes on inequality estimation.)

Simplifications:
- Myopic planner ignores dynamics. Land uses are exhaustible resource $\implies$ Hotelling Rule: planner indifferent to upzoning parcel now or later. To avoid, assume large endowment of agricultural land such that long-run considerations are irrelevant (there is always somewhere new to upzone).
- Can't observe $p_j$ for parcels that are not upzoned (but might look at denied applications)
- Locality may have market power $\implies$ $p_j$ is endogenous to $\vec{a}$

## Version 2
Differentiated products Nash-Bertrand. Products are land use rights on a particular parcel. Characteristics include coordinates, adjacent uses, the zoning code, and the county itself (the "brand"). Estimate markups to assess locality market power.

# Data
GIS Data:
- Parcel boundaries: https://vgin.vdem.virginia.gov/datasets/virginia-parcels/about

This paper may be a useful reference for outcomes:
- https://ishanbhatt42.github.io/files/paper_adu.pdf


## Meetings
Julie (9/6/2023)
"All durable goods monopolist papers wind up being about intertemporal price discrimination."

Reform bites due to "stochastic court enforcement"

Dynamics are key -- need to explain why upzoning happens when it does, or make a strong case why a static analysis is sufficient.

1. Need to know if commercial/office/industrial uses are complements or substitutes for residential. Check what happens after PRA16 and see Matt Gentzkow.
2. Draft questions for Cailinn Slattery to fix ideas; once you are further along, consider asking for a meeting.
3. See [Souza-Rodriguez (2018)](https://doi.org/10.1093/restud/rdy070) for ideas.


Lee (9/1/2023)
Seems OK to focus on a static analysis by assuming an endowment of undeveloped land large enough that the planner does not worry about boundary conditions.

1. Do power calculations to make sure "part one" results will be convincing
2. Tie PRA16 to other policies and tap into the research on the effects of those policies -- this will help if results are more suggestive than definitive
3. Check how value of in-kind proffers compares to cash and how it changes after PRA16 in Loudoun (need to import data)

Probably best to refer to cash proffers as a price, not a tax. Taxes usually refer to payments to a 3rd party that are proportional to the value of the transaction.

Leora (8/15/2023)
- Is this a first-stage for something?
- Try to write an abstract, research question (not just "Effect of Policy on ...")

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


