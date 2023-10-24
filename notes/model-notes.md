# Models of Land Use
Aside from adapting the language of each model to my setting, I do not make any material edits.

## Static
### Suarez Serrato and Zidar (2016)


### Diamond (2017)
Consider a large number $N$ of cities indexed by $j = 1, \ldots, N$. The government of each city produces a public good according to 

$$Y_j^G = \alpha_jG_j$$

where $\alpha_j$ is an exogenous productivity and $G_j$ is the number of government employees. Let the average level of government services per household be denoted 

$$s_j = \alpha_jG_j/N_j$$

where $N_j$ is the number of households in city $j$. The Leviathan government maximizes its profits:

$$\max_{\tau_j, s_j} \tau_jN_j - \frac{w_js_jN_j}{\alpha_j}$$

where $\tau_j$ is a lump-sum tax rate and $w_j$ is the local wage.

Household utility is given by

$$U_j = w_j - r_j + A_j + g(s_j) - \tau_j = \bar{U}$$

where $r_j$ is the rental rate of housing, $A_j$ is the numeraire good, and $g(\cdot)$ is a concave function. Given homogenous households, spatial indifference implies that utility is the same in all cities.

Firms produce a numeraire good according to 

$$Y_j = (\theta_j + b(s_j))N_j^P$$

where $\theta_j$ is an exogenous productivity and $N_j^P$ is the number of private-sector employees. Note that labor demand is perfectly elastic. Labor market clearing implies $N_j = N_j^P + G_j$.

Under perfect competition, the wage is equal to the marginal product of labor:

$$w_j = \theta_j + b(s_j)$$

Housing supply is assumed to take the form 

$$r_j = a_j + \gamma x_j^{house}\log(N_j)$$

where $x_j^{house}$ is a vector of exogenous city characteristics, like topography, that affect the elasticity of housing supply. See Saiz (2010) for a microfoundation.

**Equilibrium**. Substitute in labor demand and housing supply to the worker's indifference condition to obtain

$$\theta_j + b(s_j) - a_j - \gamma x_j^{house}\log(N_j)+A_j+g(s_j) = \bar{U}$$

The government maximizes its profits subject to the above.

Diamond, Rebecca. "Housing supply elasticity and rent extraction by state and local governments." *American Economic Journal: Economic Policy* 9, no. 1 (2017): 74-111.

### Quigley (2007)
Consider a monocentric city such that $N$ identical households located at various distances $x$ from the city center must pay commuting costs $t$ dollars per mile to their employment location.

Households consume housing $q[x]$ and a numeraire good. Utility is

$$U(y - p[x]q[x] - tx, q[x]) = \bar{u}$$

where $p[x]$ is the price of housing.

Firms produce housing with a constant returns to scale production technology $h(\cdot)$. Let $S(x) = K(x) / L(x)$ be the capital to land ratio. The firm's problem is 

$$\max_{S(x)} \pi(x) = p(x)h(S[x]) - iS(x)$$

where $i$ is the cost of capital. Profit maximization implies

$$p(x)h'(S[x]) = i$$

A zero-profit condition pins down the price of land $r(x)$:

$$p(x)h(S[x]) - i(S[x]) = r(x)$$

The size of the city $\bar{x}$ is pinned down by the exogenous return to agricultural land

$$r(\bar{x}) = r_a$$

Housing market clearing then implies

$$\int_0^{\bar{x}} 2\pi x\left[\frac{h(s[x])}{q(x)}\right]dx = N$$

Zoning regulations may enter the model as a constraint on the amount of land available for development. See the paper for comparative statics.

### Souza-Rodrigues (2019)
For parcel $i$, on a subdivision of size $s$, in municipality $m$:

| Variable | Description |
| --- | --- |
|$P_{ims}$ | vector of input and output "farmgate" prices |
|$X_{ims}$ | parcel characteristics |
|$\Pi^z(P_{ims}, X_{ims})$ | expected present value of parcel rents under use $z \in \{a,f\}$|
|$Y_{ims}$ | indicator for whether the parcel is developed |
|$X_m$ | vector of municipality characteristics |
|$U_m(s)$ | unobserved municipal productivity shocks |
|$\varepsilon_{ims}^x$ | developers' unobserved abilities, effort, and preference for the parcel |
|$Y_m(s)$ | share of municipal land developed |

Parcel use is determined by

$$Y_{ims} = \mathbb{1}\{\pi^a(P_{ims}, X_{ims}) > \Pi^f(P_{ims}, X_{ims})\}$$

Decompose parcel characteristics as

$$X_{ims} = (X_m, U_m(s), \varepsilon_{ims}^x)$$

Municipal characteristics $X_m$ may include the distance to the nearest city, tax rates, school quality, transportation infrastructure, etc. Assume that (residualized) local prices are determined by the distance to the nearest city:

$$P_{ims} = \bar{P}_{ms} - TC_{ims}$$

The typical application estimates 

$$\ln\left(\frac{Y_m(s)}{1-Y_m(s)}\right) = X_m\beta_s - \alpha_sTC_m + U_m(s)$$

by OLS.

Consider using Bartik or network-based instruments for parcel demand. 

Souza-Rodrigues, Eduardo. "Deforestation in the Amazon: A unified framework for estimation and policy analysis." *The Review of Economic Studies* 86, no. 6 (2019): 2713-2744.

## Dynamic
### Scott (2014)
Agricultural land use is dynamic. There are both switching costs (e.g., clearing forest) and benefits (e.g., crop rotation). Therefore, static models of land use estimate a short-run elasticity that is substantially lower than the long-run elasticity.

For field $i$ in use $j$ in year $t$:

| Variable | Description |
| --- | --- |
| $k_{it}$| characteristics of the field |
| $\omega_{t}$ | market state (e.g., future prices, input costs) |
| $R_j(\omega_t)$ | observable component of expected returns |
| $\xi_{jk}(\omega_t)$ | unobservable aggregate shock to expected returns |
| $\nu_{jit}$ | idiosyncratic shock |

Expected payoffs to land use $j$ are

$$\pi(j, k, \omega_t, \nu_{it}) = \alpha_0(j,k) + \alpha_RR_j(\omega_t) + \xi_{jk}(\omega_t) + \nu_{jit}$$

Dynamics arise from the dependence of the intercept term $\alpha_0(j,k)$ on the field state $k$. 

Each field is assumed to be too small to affect the market state $\omega_t$. 

The field state is finite: planting crops is a *renewal action* that always results in the same state, while there many be dynamic effects from leaving the field fallow for $k$ years:

$$k^+(j,k) = \begin{cases} 0 & \text{if } j = crops \\ \min\{k+1, \bar{k}\} & \text{if } j = other \end{cases} $$

Assume that $\nu_{jit}$ is i.i.d. across $i$, $j$, and $t$, with T1EV distribution conditional on $\omega_t$ and $k_{it}$. 

Scott, Paul. "Dynamic discrete choice estimation of agricultural land use." (2014).


