---
marp: true
theme: default
class: _lead
paginate: true
backgroundColor: #fff
title: Taxing the Upzone
author: Colin Williams
math: mathjax
---
# **Municipal Responses to Zoning Reform:**

### **Evidence from Virginia's Proffer Reform Act of 2016**

---

# Abstract
Statewide zoning reforms may fail to increase housing supply if local governments respond along unregulated margins. I study the policy response of Virginia municipalities to a reform that restricted their ability to charge developers for residential upzonings. I find that upzoning is highly price elastic: after the reform, the number of new units allowed by residential upzonings fell by [X]\%. In counties which were partially exempted from the reform, however, aggregate rezoning remained constant as localities substituted from affected to exempt areas. Rather than playing ``whack-a-mole'' with local zoning ordinances, states should subsidize the number of newly-permitted housing units to increase housing supply.

---

# Virginia Proffer Reform Act of 2016

Impact fees broadly illegal in VA $\implies$ municipalities rely on "voluntary" proffers (i.e., prices) tied to a rezoning application
&nbsp;

In 2016, developers were uphappy with large cash proffers, lobbied state legislature for reform:
- Proffers must address impacts which are *specifically attributable* to the proposed development $\implies$ **no standard proffer schedule**
- Applies to all **residential** rezoning applications filed after **July 1, 2016**
- Exemptions for parcels **near transit** in NOVA
- Reform is partially unwound in **2019**

---

## Prince William County Suggested Proffers (2014)

|Unit| Service | Amount ($)|
|---|---|---:|
SFD|Schools|20,649|
SFD|Parks & Libraries|6,403|
SFD|Fire and Rescue|1,053|
SFD|Transportation|16,780|
**SFD**|**Total**|**44,930**
**Townhouse**|**Total**|**39,837**
**MFD**|**Total**|**26,778**

---
# Proffer Administration
- Proffers often paid out **as building permits are issued** $\implies$ reform's impact on revenues will be **gradual**, especially for single family dwellings
- Payments **indexed to CPI/PPI (!)**


---

![bg cover 100%](https://raw.githubusercontent.com/williamsca/bargaining-upzone/main/paper/figures/proffer_revenues.png)

---

![bg cover 100%](https://raw.githubusercontent.com/williamsca/bargaining-upzone/main/paper/figures/proffer_share.png)

---

### Top Proffer Counties (2004-2015)

<!-- html table generated in R 4.2.1 by xtable 1.8-4 package -->
<!-- Wed Aug 23 15:39:50 2023 -->
<table border=1>
<tr> <th> Rank </th> <th> Name </th> <th> Proffer Revenue Share (%) </th>  </tr>
  <tr> <td align="right"> 1 </td> <td> Manassas Park City </td> <td align="right"> 4.2 </td> </tr>
  <tr> <td align="right"> 2 </td> <td> Loudoun County </td> <td align="right"> 2.4 </td> </tr>
  <tr> <td align="right"> 3 </td> <td> Prince William County </td> <td align="right"> 2.0 </td> </tr>
  <tr> <td align="right"> 4 </td> <td> Chesterfield County </td> <td align="right"> 1.2 </td> </tr>
  <tr> <td align="right"> 5 </td> <td> Goochland County </td> <td align="right"> 0.9 </td> </tr>
  <tr> <td align="right"> 6 </td> <td> Caroline County </td> <td align="right"> 0.9 </td> </tr>
  <tr> <td align="right"> 7 </td> <td> Powhatan County </td> <td align="right"> 0.8 </td> </tr>
  <tr> <td align="right"> 8 </td> <td> Frederick County </td> <td align="right"> 0.8 </td> </tr>
  <tr> <td align="right"> 9 </td> <td> Hanover County </td> <td align="right"> 0.8 </td> </tr>
  <tr> <td align="right"> 10 </td> <td> Williamsburg City </td> <td align="right"> 0.8 </td> </tr>
   </table>

---

# Case Study: Fairfax County

---

![bg cover 70%](https://raw.githubusercontent.com/williamsca/bargaining-upzone/main/paper/figures/fairfax/map_fairfax_2010-2020.png)

---

![bg cover 100%](https://raw.githubusercontent.com/williamsca/bargaining-upzone/main/paper/figures/fairfax/plot_fairfax_exempt_counts.png)

---

![bg cover 100%](https://raw.githubusercontent.com/williamsca/bargaining-upzone/main/paper/figures/fairfax/plot_fairfax_exempt_areas.png)

---
# Discussion
Fairfax cares about **proffer revenues** and **total approved units**, not where development occurs.

&nbsp;

What happens if state mandates **upzoning near transit** (e.g., NY Housing Compact, CA SB50)?
- Municipalities substitute away from upzoning in other areas?
- More places to build $\implies$ proffer rates fall?

Need a model!


---

# Poor Man's Model
Locality chooses vector $\vec{a}$ of upzonings over parcels $j \in \{1, ..., J\}$ to maximize welfare: 
$$U = \max_{\vec{a}} \sum_{j=1}^J a_jq_j(p_j + v_{j}) - C\left(\sum_{j=1}^Ja_jq_j\right)$$

where 
- $p_j$ is proffer amount,
- $v_{j}$ is idiosyncratic value of upzoning parcel $j$,
- $q_j$ is parcel area, and
- $C(\cdot)$ is a disutility function with $C'(\cdot) > 0$

---

# Optimal Upzoning
Optimum characterized by $J$ inequalities: 
$$a_j = 1 \iff p_j + v_{j}q_j > C(q_j + Q_{-j}) - C(Q_{-j})$$

Assume $v_j \sim N(0, \sigma^2)$ and $C(q) = k_1 q + k_2 q^2$.

### Assumptions
- Ignores dynamics (upzoning is irreversible)
- Hard (impossible?) to know $p_j$ for parcels that are not upzoned
- Locality may have market power $\implies$ $p_j$ is endogenous to $\vec{a}$

---

# Next Steps

1. Collect systematic data on proffers ($p_j$) and upzonings ($a_j$) for VA counties
2. Ask IO faculty how to model developer demand, municipality supply of upzoning
3. Are there more typical Public Econ questions here?