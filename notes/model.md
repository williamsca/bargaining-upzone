# Models of Land Use
Aside from adapting the language of each model to my setting, I do not make any material edits.

## Souza-Rodrigues (2019)
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