# Models of Land Use
Aside from adapting the language of each model to my setting, I do not make any material edits.

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


## Static
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