# Does Public University Funding Increase the National Tax Take?
## Separating Direct Fiscal Capacity from Macroeconomic Mediation Using Bayesian Causal Forests

**Author:** Andrew C. Parnell (School of Mathematics and Statistics, University College Dublin)

### Overview
This repository contains the data pipeline, exploratory data analysis, C++/R Bayesian Causal Forest implementations (`mvbcf` and `lbcf`), and manuscript investigating whether increased public investment in university (tertiary) education produces short-term ($+5$-year) and long-term ($+10$-year) benefits to a country's tax take once mediating macroeconomic variables are separated out.

### Key Methodological Design Choices (Incorporating Round 1 Lessons)
1. **Pure Disaggregated Fiscal Outcome Vector (Zero Product Identities):**
   Instead of multiplying GDP per person into the fiscal outcome, the multivariate outcome vector $\mathbf{Y}_{i, t \to t+h}$ models four distinct fiscal channels directly:
   - $Y_1$: **Total Domestic Tax-to-GDP Ratio Change ($\Delta \text{Tax/GDP}$, percentage points of GDP)**
   - $Y_2$: **Direct Income, Profit, and Capital Gains Tax-to-GDP Change ($\Delta \text{IncomeTax/GDP}$, percentage points of GDP)**
   - $Y_3$: **Direct Income & Profit Tax Share of Revenue Change ($\Delta \text{IncomeTax/Rev}$, percentage points)**
   - $Y_4$: **Indirect Goods & Services / Consumption Tax Change ($\Delta \text{GoodsTax/GDP}$, percentage points of GDP)** (serving as a specificity / negative-control comparison channel)

2. **Unbundling the UNESCO Denominator Trap:**
   Compares three strictly observed treatment definitions side by side (with no cross-sectional proxy imputation and no post-hoc cell-median overwrites):
   - **Exposure 1 (`Z_real_spend_stu`):** Real PPP dollars spent per university student (cancelling the GDP-per-person denominator).
   - **Exposure 2 (`Z_tert_gdp`):** Total public university spending as a percentage of GDP and share of the public education budget (cancelling the student-headcount enrolment denominator).
   - **Exposure 3 (`Z_unesco_ratio`):** Standard UNESCO per-student spending ratio (`SE.XPD.TERT.PC.ZS`), demonstrating how shared GDP and enrolment denominators attenuate or invert naive estimates.

3. **Total Fiscal Effect vs Mediator-Removed Direct Effect:**
   Estimates both the **Total Fiscal Effect** (conditioning strictly on pre-treatment covariates and lagged $t-1$ GDP growth) and the **Controlled Direct Fiscal Effect** (conditioning on contemporaneous GDP per person growth, tertiary enrolment expansion, and labour-market mediators) to test whether university funding expands fiscal tax capacity beyond aggregate economic growth.

4. **Scale-Invariant Priors & Country-Clustered Inference:**
   All outcomes are $z$-score standardised inside the `mvbcf` Inverse-Wishart sampler before rescaling posterior draws to natural percentage-point units, with country-clustered posterior credible intervals and non-overlapping 10-year window checks.
