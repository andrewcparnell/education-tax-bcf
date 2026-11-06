# Does Increasing Government Spending on Tertiary Education Improve the Future Tax Take? A Bayesian Causal Inference Analysis

**Andrew C. Parnell**  
School of Mathematics and Statistics, University College Dublin (`andrew.parnell1@ucd.ie`)  
*6 November 2026*

---

## Abstract

When a national government increases public spending on tertiary (university) education, does that investment strengthen the country's future tax take once general macroeconomic growth is separated out? Answering this in cross-country panels is hard because faster-growing economies naturally collect more taxes, international indicators divide per-student spending by gross domestic product (GDP) per person and student headcount, and university cohorts take years to enter peak tax brackets. I construct a harmonised panel across 217 sovereign countries from 1985 to 2024 (372 five-year waves across 121 countries at $+5$ years; 283 across 112 countries at $+10$ years) and estimate Multivariate and Longitudinal Bayesian Causal Forests, separating baseline conditions from mediating macroeconomic changes (forward GDP growth, enrolment expansion, inequality, and life expectancy). Above-median per-student tertiary funding shifts revenue composition toward direct income, profit, and capital gains taxation by `+1.24` percentage points (pp; `95% CI [+0.24, +2.40]`, $P = 0.99$, where $P$ is the posterior probability of an effect greater than zero given the data) after 5 years and `+1.48` pp (`95% CI [-0.11, +3.03]`, $P = 0.97$) after 10 years, whilst overall non-resource tax revenue changes by `+0.45` pp of GDP (`95% CI [-0.35, +1.24]`, $P = 0.86$) and their product, direct income tax revenue, rises by `+0.34` pp of GDP (`95% CI [-0.06, +0.76]`, $P = 0.95$) at $+10$ years. Within-country per-student expansions ($\ge +2.5$ pp) raise 10-year direct income taxes by `+0.81` pp of GDP (`95% CI [+0.29, +1.33]`, $P = 1.00$), real PPP dollars per student raise 10-year non-resource tax revenue by `+0.94` pp of GDP (`95% CI [+0.09, +1.88]`, $P = 0.99$), and longitudinal trajectories ($N = 282$) show 10-year gains of `+1.94` pp on direct income tax share (`95% CI [+0.76, +3.22]`, $P = 1.00$) and `+0.41` pp of GDP on direct income taxes (`95% CI [+0.09, +0.71]`, $P = 1.00$).

**Keywords:** Bayesian Causal Forests; tertiary education spending; fiscal capacity; direct income taxation; causal mediation; longitudinal panel data.

---

## 1. Introduction

Public debates over higher education finance frequently centre on a simple, practical question: is government spending on tertiary (university) education a net drain on the public purse, or is it a productive investment that expands a country's future tax base? At the individual level, decades of labour economics research have shown that university graduates earn higher wages, experience lower unemployment, and work in more formalised firms than non-graduates (Carneiro et al., 2011; Zimmerman, 2014; Psacharopoulos and Patrinos, 2018; Deming, 2022). Welfare analyses of public expenditure in the United States also suggest that college spending and financial aid policies pay back a large fraction of their upfront budgetary cost when long-term income tax receipts are counted (Trostel, 2010; Hendren and Sprung-Keyser, 2020; Chakrabarti et al., 2020). In principle, as university-educated cohorts enter the labour market and raise firm productivity (Moretti, 2004; Valero and Van Reenen, 2019), those private wage gains and corporate spillovers should show up at the national level as stronger income, payroll, and corporate profit tax receipts.

Yet working out whether, and over what time horizon, national government spending on tertiary education actually improves a country's tax take is surprisingly tricky. Cross-country fiscal studies run into three main obstacles:

1. **Separating Direct Fiscal Returns from General Economic Growth:** If a country's tax take rises over the decade following an increase in university funding, is that because universities specifically strengthened the formal tax base, or simply because the whole economy grew richer? Worse still, if an analyst constructs a national "tax take per person" variable by multiplying the tax-to-GDP ratio by GDP per person, any positive effect of education on GDP automatically inflates the tax outcome by mathematical identity. Isolating the genuine fiscal dividend requires modelling pure tax shares and tax-to-GDP ratios whilst separating starting economic conditions from post-treatment mediating macroeconomic growth (Imai et al., 2010; Acharya et al., 2016; VanderWeele, 2016).
2. **The UNESCO Denominator Trap:** The most widely used international indicator of tertiary funding intensity, compiled by the UNESCO Institute for Statistics and the World Bank, measures public expenditure per tertiary student as a percentage of GDP per person. Because this composite ratio places both student headcount and GDP per person in the denominator, a low-income country with a tiny, elite university sector (such as Malawi or Uganda in the 1990s, enrolling fewer than 2% of young adults) can appear to spend `150%` of GDP per person per student, whereas a high-income country enrolling 60% of its young adults (such as Denmark or South Korea) appears to spend `27%`, even though the high-income country spends nearly three times as many real dollars per student. I return to this running example throughout the paper.
3. **Maturation Lags and Tax Structure Specificity:** University investments take time to mature. A funding increase in wave $t$ immediately pays formal university salaries and supports student cohorts who take three to five years to graduate and another five years to reach peak tax-paying brackets. Furthermore, public finance theory tells us that as economies accumulate skilled workers and formal employers, they shift away from indirect consumption and customs taxes toward direct personal income and corporate profit taxes (Gordon and Li, 2009; Besley and Persson, 2014; Kleven et al., 2016; Jensen, 2022). Looking only at a single aggregate tax number hides this compositional shift.

![Study design showing how I compare four observed measures of government tertiary education spending, separate baseline country context (Pathway 2A) from mediating macroeconomic changes (Pathway 2B), and track four disaggregated tax outcomes over +5 and +10 years.](../outputs/figures/fig1_structural_schematic.png)

Figure 1 shows how I set up this study to tackle all three obstacles:

* **Four Pure Disaggregated Tax Outcomes:** Rather than multiplying tax ratios by GDP, I model four percentage-point fiscal outcomes jointly: (1) overall domestic non-resource tax revenue as a share of GDP ($\Delta \text{Tax/GDP}$), (2) direct income, profit, and capital gains tax revenue as a share of GDP ($\Delta \text{IncomeTax/GDP}$), (3) direct income and profit taxes as a share of total revenue ($\Delta \text{IncomeTax/Rev}$), and (4) indirect goods and services (consumption and value-added) taxes as a share of total revenue ($\Delta \text{GoodsTax/Rev}$). The fourth outcome acts as a built-in specificity check (negative control), which I also check in Section 5.5 using non-compositional goods and services tax revenue as a share of GDP. If tertiary funding strengthens the tax take by creating high-skill formal jobs and profitable firms (Kleven et al., 2016; Jensen, 2022), it should raise direct income and profit taxes (Outcomes 2 and 3) rather than indirect consumption tax reliance (Outcome 4).
* **Unbundling the Tertiary Spending Denominators:** Instead of relying on a single composite ratio, I compare four strictly observed measures of tertiary funding side by side (with zero proxy imputation): the per-student tertiary spending ratio (% of GDP per person), observed within-country per-student tertiary funding expansions ($\ge +2.5$ percentage points over a five-year wave), real 2021 purchasing-power-parity (PPP) dollars per tertiary student (removing GDP from the denominator), and the public tertiary budget as a percentage of GDP (removing student headcount from the denominator).
* **Isolating the Mediator-Removed Direct Effect:** Using Multivariate Bayesian Causal Forests (Hahn et al., 2020; McJames et al., 2024a) and a three-wave Longitudinal Bayesian Causal Forest (McJames et al., 2024b), I compare a **Total Fiscal Effect Model (`M1`)** (conditioning strictly on pre-treatment baseline covariates including lagged economic growth) against a **Mediator-Removed Direct Fiscal Effect Model (`M2`)**, which additionally removes the mediating pathways of forward GDP per person growth, tertiary enrolment expansion, income inequality changes, and life expectancy changes over the follow-up window. I also check these direct effect estimates using Two-Stage Sequential G-Estimation (Acharya et al., 2016).

Throughout the remainder of this paper, I use **CI** to mean a Bayesian posterior **credible interval** (unless explicitly flagged as a frequentist confidence interval for linear benchmarks in Section 5.4), and I use **$P = P(\tau > 0 \mid \text{data})$** to mean the posterior probability that the causal treatment effect $\tau$ is strictly greater than zero given the observed data.

**Paper Structure and Contributions.** To my knowledge, this is the first global causal inference study to jointly model overall non-resource tax revenue, direct income and profit taxation, and indirect consumption taxation using Multivariate and Three-Wave Longitudinal Bayesian Causal Forests whilst separating the mediator-removed direct fiscal effect from general economic growth and unbundling the UNESCO per-student spending ratio across 121 countries. The paper is structured as follows. Section 2 reviews the relevant public finance, higher education, and Bayesian causal forest literatures. Section 3 describes the 40-year global panel and illustrates the UNESCO denominator trap. Section 4 introduces the Multivariate and Longitudinal Bayesian Causal Forest models in plain language (with full mathematical and algorithmic details in Appendix A). Section 5 presents the empirical results, method benchmarks, and robustness checks. Section 6 discusses cohort maturation mechanisms, names the main limitations of my approach, and suggests avenues for future work.

---

## 2. Literature Review and Conceptual Framework

In this section I briefly review three strands of research that have largely developed in parallel: the political economy of tax structure modernisation, the economics of per-student university resources, and Bayesian tree ensembles for causal mediation analysis. Those interested in more detailed surveys of each field may refer to Besley and Persson (2014), Deming (2022), and Hill et al. (2020).

### 2.1 Fiscal Capacity, Formal Employment, and Tax Structure Modernisation

A classic puzzle in public finance is why rich countries collect 30% to 45% of GDP in tax revenue (mostly through direct personal income taxes, social contributions, and corporate profit taxes), whereas low- and middle-income countries often collect less than 15% of GDP and rely heavily on indirect consumption taxes and trade duties (Gordon and Li, 2009; Besley and Persson, 2009, 2014). Early macro-fiscal studies emphasised political institutions, property rights, and state capacity (Besley and Persson, 2009; Kaufmann et al., 2011), alongside better cross-national accounting to separate domestic taxes from volatile natural resource royalties (Prichard, 2016; ICTD/UNU-WIDER, 2023).

More recently, empirical public finance has focussed on the microeconomic mechanics of tax enforcement, paper trails, and formal employment (Kleven et al., 2016; Keen and Slemrod, 2017; Pomeranz and Vila-Belda, 2019). Kleven et al. (2016) show that modern governments can enforce high direct tax compliance at low audit cost because large, formal firms act as third-party tax collectors: complex businesses need internal accounting records shared amongst managers and skilled staff, which makes colluding to hide wages and profits very difficult. Building on this idea, Jensen (2022) assembles household micro-data across nearly 100 countries and shows that the shift from informal self-employment into salaried employee jobs is the main driver of income tax growth as countries develop. Field experiments and administrative studies confirm that electronic tax filing and third-party reporting curb evasion when paired with capable firms and literate taxpayers (Pomeranz and Vila-Belda, 2019; Okunogbe and Pouliquen, 2022), whilst broader direct taxation can also encourage citizens to hold governments accountable (Weigel, 2020). By contrast, in developing economies with large informal sectors, consumption taxes such as value-added tax (VAT) remain the fallback option because formal retail chains only gradually replace informal street vendors as incomes rise (Bachas et al., 2024).

I think this fiscal-capacity literature points to a direct link between university funding and the tax base that goes well beyond headline GDP growth. Universities are themselves large formal employers whose staff pay income tax through automatic payroll withholding, and they train the professional, managerial, scientific, and accounting workers needed by formal firms (Kleven et al., 2016; Valero and Van Reenen, 2019), moving workers into salaried jobs above national income tax exemption thresholds (Jensen, 2022). If this mechanism operates at the national level, higher public spending per university student should specifically boost **direct income, profit, and capital gains taxation** as a share of total revenue and as a share of GDP, whilst reducing relative reliance on indirect goods and services taxes.

### 2.2 Returns to Tertiary Education, Per-Student Resources, and Fiscal Externalities

A large microeconometric literature finds strong private wage returns to university education across both rich and poor countries (Carneiro et al., 2011; Zimmerman, 2014; Psacharopoulos and Patrinos, 2018; Chetty et al., 2020; Mountjoy, 2022). Reviewing this evidence, Deming (2022) notes that human capital explains at least one-third of within-country wage variation and at least half of cross-country income gaps, with higher-order problem-solving skills playing a central role in economic growth (Hanushek and Woessmann, 2012; Angrist et al., 2021), even after accounting for skilled emigration from developing countries (Beine et al., 2008). Beyond private earnings, university graduates create local productivity spillovers: Moretti (2004) finds that a higher share of college graduates in a city raises the wages of both graduates and non-graduates, whilst Valero and Van Reenen (2019) examine 15,000 universities across 1,500 sub-national regions in 78 countries and find that university expansions raise future regional GDP through skilled labour supply and innovation.

Crucially for my analysis, recent higher education research shows that economic returns depend heavily on **per-student instructional resources** rather than student headcounts alone. Bound et al. (2010) and Deming and Walters (2017) show that when public colleges expand student numbers whilst state funding per student stagnates or falls (often called "institutional crowding"), completion rates drop and time-to-degree lengthens. Conversely, Chakrabarti et al. (2020) find that increases in state appropriations to public universities raise bachelor's degree completion and improve long-run earnings into students' thirties. When students graduate and enter well-paid formal careers, the fiscal return to the government is substantial: Trostel (2010) estimates that lifetime additional income and payroll taxes paid by college graduates exceed direct government subsidies several times over, and Hendren and Sprung-Keyser (2020) show within their Marginal Value of Public Funds (MVPF) framework that public investments in higher education can pay for themselves over the lifecycle through higher future tax receipts.

### 2.3 Causal Mediation Analysis and Bayesian Regression Tree Ensembles

Separating the direct fiscal effect of tertiary funding from general macroeconomic development involves two statistical hurdles: post-treatment mediation bias and non-linear confounding. In cross-country panels, policies affect outcomes through several intermediate channels, and standard linear two-way fixed effects regressions can suffer from negative weighting when treatment effects vary across countries and time (Jordà, 2005; Acemoglu et al., 2019; de Chaisemartin and D'Haultfœuille, 2020). As shown in the causal mediation literature (Imai et al., 2010; VanderWeele, 2016; Acharya et al., 2016), comparing a total treatment effect (conditioned only on pre-treatment covariates) against a mediator-adjusted direct effect (additionally conditioned on post-treatment mediators such as forward GDP growth, enrolment expansion, inequality, and health) helps us work out whether an intervention works purely through aggregate economic growth or through a specific structural channel. At the same time, Acharya et al. (2016) warn that single-stage regression adjustments for post-treatment mediators can introduce bias if baseline covariates and mediator effects are misspecified, motivating their two-stage sequential g-estimation procedure (which I implement in Section 5.5).

Bayesian Additive Regression Trees (BART) (Chipman et al., 2010; Hill, 2011; Hill et al., 2020) and **Bayesian Causal Forests (BCF)** (Hahn et al., 2020) offer a flexible nonparametric alternative to linear panel regressions, sitting alongside frequentist causal forests and double/debiased machine learning (Chernozhukov et al., 2018; Athey et al., 2019). BART ensembles automatically pick up non-linear relationships and multi-way interactions amongst covariates, with recent extensions handling high-dimensional predictors (Linero, 2018), functional smoothing (Starling et al., 2020), non-Gaussian outcomes (Murray, 2021), faster stochastic tree search (Krantsevich et al., 2023), and interpretable posterior summaries (Woody et al., 2021). Crucially, Hahn et al. (2020) show that standard single-forest BART models can suffer from *regularisation-induced confounding* (RIC) when strong baseline predictors of the outcome also predict which units receive treatment. BCF solves this by splitting the outcome into a prognostic forest $\mu(X, \hat{\pi})$ (which explicitly includes the pre-treatment propensity score $\hat{\pi}(X)$) and a more heavily regularised treatment-effect forest $\tau(W)$.

Readers will note that the Multivariate and Longitudinal Bayesian Causal Forest extensions on which I am focussing (McJames et al., 2025, 2024b) are methods which I co-developed with Nathan McJames and Ann O'Shea. Given this, I should make it clear from the outset that this paper is not written in an attempt to endorse one particular causal model over all others. In Section 5.4, I compare my four-outcome Multivariate Bayesian Causal Forest (`mvbcf`) directly against univariate BCFs, single-forest BART, linear local projections, two-way fixed effects, and cross-fitted double machine learning, and I discuss the disadvantages of the BCF approach alongside its strengths.

---

## 3. Data and Measurement

### 3.1 Global Five-Year Panel Structure and Quality Screening

Following standard practice in empirical growth and fiscal panel studies (Acemoglu et al., 2019), I average annual observations from the World Bank World Development Indicators (WDI, May 2024 release), the UNESCO Institute for Statistics (UIS, May 2024 release), the International Monetary Fund (IMF) Fiscal Monitor, the Worldwide Governance Indicators (WGI), the Standardized World Income Inequality Database (SWIID version 9.6; Solt, 2020), and the OECD Education at a Glance financing taxonomy into eight non-overlapping five-year waves spanning 40 years: `1985-1989`, `1990-1994`, `1995-1999`, `2000-2004`, `2005-2009`, `2010-2014`, `2015-2019`, and `2020-2024`, using the fixed FY2024 World Bank analytical income classification. The data are indexed by sovereign ISO-3 country code and five-year wave start year (with no spatial coordinate transformation required). <!-- style-check: ignore -->

The complete rectangular country-wave grid spans $217 \times 8 = 1,736$ country-waves across 217 sovereign territories, of which 808 country-waves have observed tertiary spending indicators and 742 have observed tax revenue series. One practical difficulty when working with raw international fiscal archives is that occasional currency-unit or offshore-fund accounting errors produce impossible tax ratios. To prevent extreme reporting errors from distorting the tree ensembles, I screen out impossible tax-to-GDP observations exceeding 60% of GDP (or below 0.5% of GDP), catching Sudan in `1995-1999` (`629.2%` of GDP) and Timor-Leste in `2010-2014` (`110.0%` of non-oil GDP). After screening these two anomalies and requiring strictly observed treatment and four-outcome fiscal vectors (with zero imputation on treatments or outcomes), the primary estimation sample comprises **372 country-waves across 121 sovereign countries** at the $+5$-year horizon ($t \to t+1$) and **283 country-waves across 112 sovereign countries** at the $+10$-year horizon ($t \to t+2$).

### 3.2 Disaggregated Fiscal Outcomes and Outcome Algebra

To work out how tertiary funding affects public finances without introducing mechanical GDP product identities, I track four percentage-point (pp) changes over both $+5$ years ($t+1$) and $+10$ years ($t+2$):

1. **Overall Domestic Non-Resource Tax Revenue ($\Delta \text{Tax/GDP}$, pp of GDP):** Total tax revenue as a percentage of GDP, adjusted to remove volatile natural resource rents in petro-states and mineral exporters where oil or mining royalties otherwise mask domestic tax effort (Prichard, 2016; ICTD/UNU-WIDER, 2023). Stated in words first: when WDI tax-to-GDP is available, I subtract half of natural resource rents above 10% of GDP (bounded below at 2% of GDP); when only total government revenue excluding grants is available, I subtract 70% of natural resource rents. Using WDI total tax revenue ($\text{Tax/GDP}_{i,t}$), government revenue excluding grants ($\text{GovRev/GDP}_{i,t}$), and natural resource rents ($\text{ResRents}_{i,t}$), this is $\max(\text{Tax/GDP}_{i,t} - 0.5\max(\text{ResRents}_{i,t} - 10, 0), 2.0)$ when $\text{Tax/GDP}_{i,t} > 0$, and $\max(\text{GovRev/GDP}_{i,t} - 0.7\,\text{ResRents}_{i,t}, 2.0)$ otherwise. In both primary estimation samples ($N = 372$ at $+5\text{y}$ and $N = 283$ at $+10\text{y}$), 100% of observations (`372/372` and `283/283`) have observed WDI $\text{Tax/GDP}_{i,t} > 0$ and fall into the first branch; zero estimation-sample waves rely on the fallback branch, and I verify all results on raw WDI tax-to-GDP in Robustness Check `R1`.
2. **Direct Income, Profit, and Capital Gains Tax Revenue ($\Delta \text{IncomeTax/GDP}$, pp of GDP):** Revenue collected directly from individual wages, salaries, and corporate profits, expressed as a percentage of GDP ($\text{NonResTax}_{i,t} \times \text{IncomeTax/Rev}_{i,t} / 100$).
3. **Direct Income and Profit Share of Revenue ($\Delta \text{IncomeTax/Rev}$, pp of total revenue):** The share of government revenue coming from direct taxes on income, profits, and capital gains (Besley and Persson, 2014; Jensen, 2022).
4. **Indirect Goods and Services Tax Share ($\Delta \text{GoodsTax/Rev}$, pp of total revenue):** The share of revenue coming from indirect consumption taxes such as VAT, sales taxes, and excise duties (Bachas et al., 2024), serving as a compositional specificity check (tested in non-compositional GDP levels in `R11`).

**Two Independent Structural Dimensions and the Product Decomposition.** Because Outcome 2 is constructed as $\text{IncomeTax/GDP} = \text{NonResTax/GDP} \times \text{IncomeTax/Rev} / 100$ (Outcome 1 multiplied by Outcome 3 and divided by 100) and Outcome 4 competes in the same revenue denominator as Outcome 3, the four channels span **two independent structural dimensions**: (i) the aggregate domestic tax level (Outcome 1) and (ii) the revenue-share composition between direct and indirect taxes (Outcomes 3 and 4), whilst Outcome 2 is their policy-relevant product. A first-order Taylor decomposition at the sample baseline means ($\overline{\text{NonResTax/GDP}} = 16.5\%$, $\overline{\text{IncomeTax/Rev}} = 30.8\%$) shows that at $+5$ years ($\hat{\tau}_1 = +0.02\text{ pp}$, $\hat{\tau}_3 = +1.24\text{ pp}$, $\hat{\tau}_2 = +0.21\text{ pp}$), virtually $100\%$ of the $+0.21\text{ pp}$ gain in Direct Income Tax / GDP comes from the compositional shift, whereas at $+10$ years ($\hat{\tau}_1 = +0.45\text{ pp}$, $\hat{\tau}_3 = +1.48\text{ pp}$, $\hat{\tau}_2 = +0.34\text{ pp}$), the compositional shift contributes `+0.24 pp` (`71%`) and aggregate tax-level expansion contributes `+0.14 pp` (`29%`, less `-0.04 pp` covariance).

### 3.3 Unbundling the UNESCO Denominator Trap

In plain words, the standard UNESCO indicator of per-student tertiary spending intensity (World Bank and UNESCO, 2024) can be stated as: public spending per university student divided by GDP per person, which is mathematically identical to the public university budget as a share of GDP divided by the number of university students per person:

$$
\text{UNESCO Ratio}_{i,t} = \frac{\text{Tertiary Spend per Student}_{i,t}}{\text{GDP per Person}_{i,t}} \times 100 = \frac{\text{Tertiary Budget (\% GDP)}_{i,t}}{\text{Students per Person}_{i,t}}.
$$

Table 1 compares this ratio across the four World Bank income groups alongside two unbundled tertiary level measures: **Real 2021 PPP Dollars per Tertiary Student** (which removes GDP per person from the denominator) and **Public Tertiary Budget as a % of GDP** (which removes student headcount from the denominator).

| Income Group (Countries, Waves) | UNESCO Ratio (% GDP/pc) | **Real PPP \$ / Student** | **Tertiary Budget (% GDP)** | Tertiary Enrolment (%) | Direct Income Tax Share (%) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Low income** (21, 80) | **150.0%** (205.2%) | \$3,957 | 0.47% | 2.3% | 29.2% |
| **Lower middle income** (41, 172) | 76.5% | \$3,258 | 0.65% | 7.4% | 30.8% |
| **Upper middle income** (54, 219) | 26.8% | \$3,521 | 0.64% | 25.5% | 33.1% |
| **High income** (69, 337) | 26.9% | **\$11,148** | **0.94%** | **58.3%** | **38.4%** |

*Table 1: Tertiary spending indicators and baseline tax structure across World Bank income groups (group medians for skewed spending and enrolment variables; group means for direct income tax share; for Low income, both the winsorised 150.0% display value and the unwinsorised 205.2% raw median are reported).*

Recall my running example from Section 1. In **Low income** countries (such as Uganda or Malawi), only 2.3% of young adults attend university; dividing a modest university budget (0.47% of GDP) by a tiny student headcount and a low GDP per person produces an unwinsorised median UNESCO ratio of 205.2% (150.0% when capped at the display winsorisation limit). That tiny elite headcount also explains why the median real PPP spending per student in Low income countries (\$3,957) slightly exceeds that of Lower middle income countries (\$3,258), where enrolment is over three times higher (7.4% median, 11.7% mean). Once I unbundle the denominators in Table 1, **High income** countries (such as Denmark or South Korea) actually spend nearly three times as much per student in real purchasing power (\$11,148 vs \$3,957) and twice as much of their national income (0.94% vs 0.47% of GDP), whilst collecting a much larger share of their revenue from direct income and profit taxes (38.4% vs 29.2%).

I urge caution in using the raw UNESCO ratio in a naive global regression without accounting for this inversion. My primary per-student regime indicator ($Z_{i,t} = 1$) compares each country's unwinsorised per-student tertiary spending ratio strictly against the median of **its own World Bank income group** (yielding balanced treatment prevalence of `47.3%` treated at $+5\text{y}$ and `49.8%` treated at $+10\text{y}$), paired co-equally with **observed within-country per-student tertiary spending expansions** ($\ge +2.5\text{ pp}$ and $\ge +2.5\%$, Models `M3a`/`M3b`), and I compare all four tertiary spending definitions side by side in Section 5.2.

---

## 4. Methodology

### 4.1 Intuition: Separating Baseline Trajectories from Causal Effects

In this section I explain the intuition behind my modelling strategy. Those interested in more detailed mathematical derivations and full Gibbs sampling steps may refer to Appendix A.

**Bayesian Causal Forests (BCF)** (Hahn et al., 2020) split the prediction of future tax changes into two distinct tree ensembles. Stated simply in words first: future tax change equals a baseline prognostic trajectory (what would have happened naturally given starting conditions) plus a causal treatment effect (which depends on country moderators) multiplied by the treatment indicator:

$$
\Delta Y_{i, t+h} = \underbrace{\mu\bigl(X_{i,t}, \hat{\pi}(X_{i,t})\bigr)}_{\text{Baseline Trajectory}} + \underbrace{\tau\bigl(W_{i,t}\bigr)}_{\text{Causal Effect}} \cdot Z_{i,t} + \varepsilon_{i, t+h}, \qquad \varepsilon_{i, t+h} \stackrel{\text{i.i.d.}}{\sim} \mathcal{N}_4(0, \Sigma).
$$

1. **Prognostic trajectory $\mu(X_{i,t}, \hat{\pi}_{i,t})$:** The idea that we must first work out how a country's tax take would evolve naturally over the next 5 or 10 years without high tertiary funding. I use a flexible forest of $M_\mu = 75$ four-dimensional regression trees ($\alpha_\mu = 0.95, \beta_\mu = 2.0$) fed with 19 pre-treatment baseline covariates $X_{i,t}$ (starting log real GDP per person in PPP dollars, starting non-resource tax-to-GDP ratio, starting direct income tax share, starting goods and services tax share, harmonised SWIID disposable income Gini inequality, life expectancy at birth, gross tertiary enrolment ratio, gross secondary enrolment ratio, total public education spending as % of GDP, working-age population share aged 15 to 64, log total population, unemployment rate, natural resource rents as % of GDP, trade openness as % of GDP, lagged $t-1$ GDP per person growth rate, World Bank income group tier, geographic region, OECD membership indicator, and five-year wave time index), incorporating the pre-treatment propensity score $\hat{\pi}(X_{i,t})$ directly inside $\mu(\cdot)$ to guard against regularisation-induced confounding.
2. **Treatment moderation $\tau(W_{i,t})$:** The idea that the fiscal return to university spending is not the same in every country. A second, more conservatively regularised forest of $M_\tau = 30$ trees ($\alpha_\tau = 0.25, \beta_\tau = 3.0$) estimates how the causal return varies across 8 country moderators $W_{i,t}$ (gross tertiary enrolment ratio, log real GDP per person, gross secondary enrolment ratio, starting direct income tax share, working-age population share, World Bank income group tier, OECD membership indicator, and five-year wave time index).
3. **Joint covariance (`mvbcf`) and longitudinal trajectories (`lbcf`):** The idea that tax outcomes move together across channels and build over time. My **Multivariate BCF (`mvbcf`)** models all four tax outcomes jointly with an Inverse-Wishart prior $\Sigma \sim \mathcal{IW}(\nu_0, \Psi_0)$ ($\nu_0 = 6$) on the $4 \times 4$ residual covariance matrix (McJames et al., 2024a), whilst my **Three-Wave Longitudinal BCF (`lbcf`)** (McJames et al., 2024b) models the baseline-differenced three-wave trajectory ($0$, $\Delta Y_{i, t+1}$, $\Delta Y_{i, t+2}$) from baseline ($t$) to $+5$ years ($t+1$) and $+10$ years ($t+2$).

The key advantage of the `mvbcf` and `lbcf` framework is that it captures non-linear confounding and shares information across correlated tax channels whilst shrinking spurious heterogeneity toward the overall average treatment effect. The main disadvantage, however, is that tree ensembles do not automatically difference out time-invariant country fixed effects in the way a linear within-country regression does, and they rely on MCMC sampling and conditional ignorability assumptions. I test both of these vulnerabilities explicitly in Sections 5.4 and 5.5.

### 4.2 Total Fiscal Effect (`M1`) vs Mediator-Removed Direct Effect (`M2`)

Thus, put succinctly, my task is as follows: I want to test whether tertiary funding improves the tax take *once mediating macroeconomic variables are separated out* (Imai et al., 2010; Acharya et al., 2016; VanderWeele, 2016).

* **Model `M1` (Total Fiscal Effect):** Controls strictly for the 19 pre-treatment baseline covariates measured at or before wave $t$ (using lagged $t-1$ GDP per person growth).
* **Model `M2` (Mediator-Removed Direct Fiscal Effect):** Controls for all 19 pre-treatment baseline covariates in `M1` **plus four contemporaneous macroeconomic mediators** measured over $[t, t+h]$: (i) forward log GDP per person growth, (ii) forward change in gross tertiary enrolment, (iii) forward change in disposable income inequality (Gini), and (iv) forward change in life expectancy, whilst keeping $\hat{\pi}(X_{i,t})$ estimated strictly from pre-treatment covariates. I also check `M2` using **Two-Stage Sequential G-Estimation** (`R9`; Acharya et al., 2016), which demediates $\Delta Y_{i,t+h}$ prior to fitting `mvbcf`.

---

## 5. Empirical Results

### 5.1 Total vs Mediator-Removed Direct Effects Across Tax Channels

In this section I present the main empirical findings. Recall that throughout all tables and text, **CI** denotes a Bayesian posterior credible interval and **$P = P(\tau > 0 \mid \text{data})$** denotes the posterior probability that the causal effect is greater than zero given the data. Table 2 and Figure 2 compare the **Total Fiscal Effect (`M1`)** and the **Mediator-Removed Direct Fiscal Effect (`M2`)** across all four tax channels at $+5$ years ($N = 372$, 121 countries) and $+10$ years ($N = 283$, 112 countries).

| Disaggregated Tax Outcome | $+5\text{y}$ Total (`M1`) | **$+5\text{y}$ Direct (`M2`)** | $+10\text{y}$ Total (`M1`) | **$+10\text{y}$ Direct (`M2`)** |
| :--- | :---: | :---: | :---: | :---: |
| **1. Non-Resource Tax / GDP (pp)** | `+0.01` (`[-0.49, +0.52]`, $P=0.51$) | `+0.02` (`[-0.46, +0.49]`, $P=0.55$) | `+0.45` (`[-0.29, +1.21]`, $P=0.87$) | `+0.45` (`[-0.35, +1.24]`, $P=0.86$) |
| **2. Direct Income Tax / GDP (pp)** | **`+0.19` (`[-0.06, +0.45]`, $P=0.92$)** | **`+0.21` (`[-0.04, +0.47]`, $P=0.95$)** | `+0.25` (`[-0.16, +0.67]`, $P=0.88$) | **`+0.34` (`[-0.06, +0.76]`, $P=0.95$)** |
| **3. Direct Income Tax Share (pp)** | **`+1.02` (`[-0.01, +2.07]`, $P=0.97$)** | **`+1.24` (`[+0.24, +2.40]`, $P=0.99$)** | **`+1.36` (`[-0.21, +2.92]`, $P=0.96$)** | **`+1.48` (`[-0.11, +3.03]`, $P=0.97$)** |
| **4. Goods & Services Share (pp)** | `-0.19` (`[-1.37, +0.93]`, $P=0.39$) | `-0.29` (`[-1.41, +0.73]`, $P=0.31$) | `-0.55` (`[-2.11, +0.96]`, $P=0.25$) | `-0.56` (`[-2.02, +1.05]`, $P=0.24$) |

*Table 2: Posterior mean treatment effects (in percentage points), 95% credible intervals (CIs), and posterior probabilities $P = P(\tau > 0 \mid \text{data})$ from the joint Multivariate Bayesian Causal Forest (`mvbcf`).*

![Posterior mean treatment effects (with thick 80% and thin 95% credible intervals, CIs) comparing the Total Fiscal Effect (M1, blue) and the Mediator-Removed Direct Fiscal Effect (M2, green) across the four tax outcomes at +5 and +10 years.](../outputs/figures/fig2_total_vs_direct_tax_posteriors.png)

### 5.2 Unbundling the Tertiary Denominator Trap

Table 3 and Figure 3 compare my four unbundled tertiary spending definitions side by side at the $+10$-year horizon under the Mediator-Removed Direct Effect specification (`M2`). Restricting `M2b`, `M3d`, and `M3f` to their exact common intersection ($N = 272$ across 108 countries) preserves the same ordering.

| Tertiary Spending Exposure ($+10\text{y}$ Direct) | $N$ (Countries) | **Non-Resource Tax / GDP (pp)** | **Direct Income Tax / GDP (pp)** | **Direct Income Tax Share (pp)** |
| :--- | :---: | :---: | :---: | :---: |
| **1. Per-Student Tertiary Ratio (`M2b`)** | 283 (112) | `+0.45` (`[-0.35, +1.24]`, $P=0.86$) | **`+0.34` (`[-0.06, +0.76]`, $P=0.95$)** | **`+1.48` (`[-0.11, +3.03]`, $P=0.97$)** |
| **2. Observed Expansion $\ge +2.5\text{ pp}$ (`M3b`)** | 176 (86) | `+0.53` (`[-0.53, +1.67]`, $P=0.82$) | **`+0.81` (`[+0.29, +1.33]`, $P=1.00$)** | **`+2.33` (`[+0.29, +4.36]`, $P=0.99$)** |
| **3. Real 2021 PPP \$ / Student (`M3d`)** | 283 (112) | **`+0.94` (`[+0.09, +1.88]`, $P=0.99$)** | **`+0.39` (`[-0.01, +0.78]`, $P=0.97$)** | `+0.80` (`[-0.91, +2.47]`, $P=0.81$) |
| **4. Public Tertiary Budget % GDP (`M3f`)** | 403 (123) | `+0.17` (`[-0.59, +0.83]`, $P=0.70$) | `+0.11` (`[-0.27, +0.47]`, $P=0.73$) | **`+0.94` (`[-0.37, +2.45]`, $P=0.91$)** |

*Table 3: Comparison of $+10$-year Mediator-Removed Direct Fiscal Effects across the four tertiary education spending definitions (with 95% CIs and posterior probabilities $P = P(\tau > 0 \mid \text{data})$).*

![Comparison of +10-year Mediator-Removed Direct Fiscal Effects across the four tertiary spending definitions (with country-clustered 95% and 80% credible intervals, CIs).](../outputs/figures/fig3_denominator_unbundling_horserace.png)

### 5.3 Heterogeneity by Enrolment Access and Ten-Year Longitudinal Trajectories

Figure 4 and Table 4 examine how $+10$-year direct fiscal returns vary across baseline gross tertiary enrolment regimes ($N = 244$ observed out of $283$; $39$ waves lack baseline gross enrolment), all four World Bank income groups ($N = 283$), and all five OECD public-versus-private financing regimes ($N = 119$).

![Unit-level +10-year Mediator-Removed Direct Effect on Direct Income and Profit Tax Share (percentage points, with vertical 80% posterior CI bars) across baseline gross tertiary enrolment ratios and World Bank income groups.](../outputs/figures/fig4_enrolment_and_oecd_moderation.png)

| Country Subgroup ($+10\text{y}$ Direct) | $N$ (Countries) | **Non-Resource Tax / GDP (pp)** | **Direct Income Tax / GDP (pp)** | **Direct Income Tax Share (pp)** |
| :--- | :---: | :---: | :---: | :---: |
| **1. Elite Enrolment (`<20%`)** | 74 (43) | **`+0.77` (`[-0.22, +1.79]`, $P=0.93$)** | **`+0.47` (`[+0.003, +0.96]`, $P=0.97$)** | `+0.90` (`[-1.07, +2.76]`, $P=0.83$) |
| **2. Massifying (`20-50%`)** | 73 (42) | **`+0.52` (`[-0.32, +1.33]`, $P=0.90$)** | **`+0.35` (`[-0.07, +0.76]`, $P=0.94$)** | **`+1.53` (`[-0.16, +3.18]`, $P=0.96$)** |
| **3. High-Participation (`>=50%`)** | 97 (44) | `+0.22` (`[-0.77, +1.19]`, $P=0.68$) | `+0.25` (`[-0.23, +0.71]`, $P=0.85$) | **`+1.87` (`[+0.16, +3.63]`, $P=0.99$)** |
| **4. Low Income (exploratory)** | 15 (9) | `+0.86` (`[-0.54, +2.18]`, $P=0.88$) | **`+0.56` (`[-0.01, +1.23]`, $P=0.97$)** | `-0.03` (`[-3.31, +2.67]`, $P=0.54$) |
| **5. Lower Middle Income** | 47 (21) | **`+0.79` (`[-0.23, +1.86]`, $P=0.94$)** | **`+0.46` (`[-0.02, +0.96]`, $P=0.97$)** | `+1.06` (`[-0.88, +3.04]`, $P=0.86$) |
| **6. Upper Middle Income** | 76 (35) | **`+0.61` (`[-0.22, +1.46]`, $P=0.93$)** | **`+0.35` (`[-0.09, +0.78]`, $P=0.94$)** | **`+1.50` (`[-0.26, +3.23]`, $P=0.95$)** |
| **7. High Income** | 145 (47) | `+0.21` (`[-0.75, +1.09]`, $P=0.68$) | `+0.28` (`[-0.18, +0.74]`, $P=0.88$) | **`+1.76` (`[+0.12, +3.55]`, $P=0.99$)** |
| **8. OECD Nordic High-Public** | 20 (5) | `-0.72` (`[-1.46, +0.04]`, $P=0.03$) | `-0.01` (`[-0.68, +0.63]`, $P=0.50$) | **`+1.72` (`[-0.69, +4.11]`, $P=0.92$)** |
| **9. OECD Low-Tuition Public** | 46 (15) | `-0.70` (`[-1.41, +0.03]`, $P=0.03$) | `-0.01` (`[-0.69, +0.62]`, $P=0.51$) | **`+1.69` (`[-0.49, +4.06]`, $P=0.92$)** |
| **10. OECD Hybrid Public-Fee** | 29 (8) | `-0.69` (`[-1.38, +0.05]`, $P=0.03$) | `-0.03` (`[-0.71, +0.60]`, $P=0.48$) | **`+1.67` (`[-0.58, +3.99]`, $P=0.92$)** |
| **11. OECD High-Tuition High-Subsidy** | 11 (5) | `-0.69` (`[-1.45, +0.08]`, $P=0.04$) | `-0.03` (`[-0.70, +0.62]`, $P=0.48$) | **`+1.67` (`[-0.71, +4.06]`, $P=0.92$)** |
| **12. OECD High-Tuition Low-Subsidy** | 13 (4) | `-0.63` (`[-1.45, +0.10]`, $P=0.04$) | `+0.01` (`[-0.65, +0.66]`, $P=0.53$) | **`+1.65` (`[-0.76, +4.05]`, $P=0.91$)** |

*Table 4: Subgroup conditional average treatment effects (CATEs, with 95% CIs and posterior probabilities $P = P(\tau > 0 \mid \text{data})$) at the $+10$-year horizon.*

Table 5 and Figure 5 report results from my **Longitudinal Bayesian Causal Forest (`lbcf`)** fitted on the two stochastic post-baseline transition waves ($+5\text{y}$ and $+10\text{y}$, $2N = 564$ rows) across $N = 282$ trajectories (112 countries).

| Tax Outcome ($N = 282$, 112 Countries) | $+5\text{y}$ Step ($\tau_1$) | **$+5\text{y} \to +10\text{y}$ ($\tau_2$)** | **Cumulative $+10\text{y}$ ($\tau_{\text{cum}}$)** | Joint Prob. $P(\tau_1>0, \tau_2>0)$ |
| :--- | :---: | :---: | :---: | :---: |
| **1. Non-Resource Tax / GDP (pp)** | `+0.11` (`[-0.47, +0.66]`, $P=0.65$) | `+0.35` (`[-0.29, +1.02]`, $P=0.86$) | **`+0.46` (`[-0.14, +1.09]`, $P=0.92$)** | 52.7% |
| **2. Direct Income Tax / GDP (pp)** | **`+0.25` (`[-0.04, +0.53]`, $P=0.96$)** | `+0.16` (`[-0.15, +0.50]`, $P=0.83$) | **`+0.41` (`[+0.09, +0.71]`, $P=1.00$)** | **78.8%** |
| **3. Direct Income Tax Share (pp)** | **`+1.26` (`[+0.12, +2.51]`, $P=0.98$)** | `+0.68` (`[-0.61, +2.05]`, $P=0.85$) | **`+1.94` (`[+0.76, +3.22]`, $P=1.00$)** | **83.5%** |
| **4. Goods & Services Share (pp)** | `-0.59` (`[-1.81, +0.79]`, $P=0.18$) | `-0.28` (`[-1.62, +1.20]`, $P=0.34$) | `-0.87` (`[-2.22, +0.53]`, $P=0.10$) | 2.0% |

*Table 5: Longitudinal Bayesian Causal Forest decomposition of the initial $+5$-year effect ($\tau_1$), the incremental $+5\text{ to }+10$-year maturation effect ($\tau_2$), the cumulative $+10$-year effect ($\tau_{\text{cum}} = \tau_1 + \tau_2$), and the joint compounding probability $P(\tau_1 > 0 \cap \tau_2 > 0)$, with 95% CIs.*

![Cumulative 10-year trajectories of the Direct Income and Profit Tax Share effect across seven illustrative countries from the Longitudinal Bayesian Causal Forest, showing country-specific 80% posterior CIs and the global average 80% and 95% posterior CI fan.](../outputs/figures/fig5_longitudinal_country_trajectories.png)

Figure 5 illustrates this ten-year compounding trajectory for my running examples of Denmark (`DK`, `+2.0` pp, 80% CI `[+1.0, +3.0]`), South Korea (`KR`, `+2.0` pp, 80% CI `[+1.0, +3.1]`), and Brazil (`BR`, `+2.3` pp, 80% CI `[+1.2, +3.4]`), alongside Germany (`DE`, `+2.1` pp, 80% CI `[+1.1, +3.2]`), the United States (`US`, `+2.1` pp, 80% CI `[+1.0, +3.2]`), South Africa (`ZA`, `+2.0` pp, 80% CI `[+0.9, +3.0]`), and Chile (`CL`, `+1.9` pp, 80% CI `[+1.0, +2.9]`). Because the conservative $\tau_1$ and $\tau_2$ priors shrink country-level trajectories strongly toward the global curve, the seven country paths cluster tightly between `+1.9` and `+2.3` pp and are statistically indistinguishable from one another.

### 5.4 Causal Method Benchmarks, Ablations, and Moderator Importance

As promised in Section 2.3, I do not want readers to take the performance of the `mvbcf` model on trust. Table 6 compares my primary joint four-outcome `mvbcf` specification (`M2b`) at the $+10$-year horizon against two internal ablations and four competing causal estimators on the identical common sample ($N = 283$, 112 countries).

| Estimator / Ablation Specification ($+10\text{y}$, $N = 283$) | **Non-Resource Tax / GDP** | **Direct Income Tax / GDP** | **Direct Income Tax Share** | **Goods & Services Share** |
| :--- | :---: | :---: | :---: | :---: |
| **Primary: Joint `mvbcf` ($D=4$, with $\hat{\pi}$)** | `+0.45` (`[-0.35, +1.24]`, $P=0.86$) | **`+0.34` (`[-0.06, +0.76]`, $P=0.95$)** | **`+1.48` (`[-0.11, +3.03]`, $P=0.97$)** | `-0.56` (`[-2.02, +1.05]`, $P=0.24$) |
| **`B1`: Separate Univariate BCFs ($D=1$)** | **`+0.57` (`[-0.31, +1.37]`, $P=0.91$)** | **`+0.39` (`[-0.01, +0.78]`, $P=0.97$)** | **`+1.60` (`[-0.02, +3.28]`, $P=0.97$)** | `-0.32` (`[-2.14, +1.49]`, $P=0.37$) |
| **`B2`: Joint `mvbcf` without $\hat{\pi}(X)$** | `+0.45` (`[-0.31, +1.23]`, $P=0.87$) | **`+0.28` (`[-0.09, +0.64]`, $P=0.93$)** | **`+1.54` (`[+0.09, +3.04]`, $P=0.98$)** | `-0.54` (`[-1.96, +0.97]`, $P=0.25$) |
| **`B3`: Single-Forest BART (with $\hat{\pi}$)** | `+0.28` (`[-0.34, +0.91]`, $P=0.80$) | `+0.17` (`[-0.15, +0.53]`, $P=0.81$) | **`+1.05` (`[-0.14, +2.46]`, $P=0.94$)** | `-0.38` (`[-1.92, +1.02]`, $P=0.30$) |
| **`B4`: Linear Local Projections (Clustered SE)** | **`+0.80` (`[-0.18, +1.79]`, $P=0.95$)** | `+0.29` (`[-0.21, +0.79]`, $P=0.87$) | **`+1.19` (`[-0.56, +2.94]`, $P=0.91$)** | `+0.72` (`[-0.97, +2.41]`, $P=0.80$) |
| **`B5`: Two-Way Fixed Effects (Country + Wave FE)** | `-0.26` (`[-1.40, +0.88]`, $P=0.33$) | `+0.34` (`[-0.34, +1.01]`, $P=0.84$) | **`+1.55` (`[-0.60, +3.69]`, $P=0.92$)** | `-0.13` (`[-2.79, +2.54]`, $P=0.46$) |
| **`B6`: Cross-Fitted Double/Debiased ML (5 Folds)** | **`+1.13` (`[+0.21, +2.05]`, $P=0.99$)** | **`+0.40` (`[-0.06, +0.85]`, $P=0.96$)** | **`+1.34` (`[-0.30, +2.98]`, $P=0.95$)** | `+0.50` (`[-1.34, +2.34]`, $P=0.70$) |

*Table 6: Method benchmark and ablation comparison at the $+10$-year horizon ($N = 283$, 112 countries). Posterior means and 95% Bayesian CIs are shown for `mvbcf` and `B1`-`B3`; frequentist point estimates and 95% country-clustered confidence intervals (also labelled CI) are shown for `B4`-`B6`.*

Projecting the unit-level CATE posterior draws onto the moderator matrix $W_{i,t}$ (Woody et al., 2021) achieves a surrogate $R^2 = 58.4\%$, led by **baseline log real GDP per person** (`8.1%` of heterogeneity variance), **working-age population share** (`6.1%`), **baseline gross tertiary enrolment** (`3.7%`), **OECD membership** (`3.7%`), and **baseline direct income tax share** (`3.4%`).

### 5.5 Robustness, Sensitivity, and Falsification Checks (`R1` to `R12`)

Table 7 summarises all 13 sensitivity, identification, and falsification checks.

| Robustness Specification | Horizon ($N$, Countries) | **Non-Resource Tax / GDP (pp)** | **Direct Income Tax / GDP (pp)** | **Direct Income Tax Share (pp)** |
| :--- | :---: | :---: | :---: | :---: |
| **`R1`. Pure Unadjusted WDI Tax / GDP** | $+10\text{y}$ (283, 112) | `+0.34` (`[-0.42, +1.08]`, $P=0.79$) | **`+0.30` (`[-0.10, +0.70]`, $P=0.94$)** | **`+1.48` (`[-0.04, +3.01]`, $P=0.97$)** |
| **`R2`. Non-Overlapping 10y Waves** | $+10\text{y}$ (154, 105) | **`+0.64` (`[-0.31, +1.56]`, $P=0.91$)** | **`+0.36` (`[-0.10, +0.81]`, $P=0.93$)** | **`+1.96` (`[+0.09, +3.92]`, $P=0.98$)** |
| **`R3a`. Within-Country Fixed Effects ($+5\text{y}$)** | $+5\text{y}$ (372, 121) | `+0.08` (`[-0.43, +0.56]`, $P=0.62$) | **`+0.19` (`[-0.06, +0.43]`, $P=0.93$)** | **`+0.96` (`[-0.06, +2.00]`, $P=0.97$)** |
| **`R3b`. Within-Country Fixed Effects ($+10\text{y}$)** | $+10\text{y}$ (283, 112) | `+0.32` (`[-0.34, +0.97]`, $P=0.82$) | `+0.15` (`[-0.20, +0.51]`, $P=0.79$) | `+0.69` (`[-0.63, +2.06]`, $P=0.84$) |
| **`R4`. Strictly Observed Covariates** | $+10\text{y}$ (238, 107) | **`+0.56` (`[-0.22, +1.30]`, $P=0.92$)** | **`+0.38` (`[+0.01, +0.81]`, $P=0.98$)** | **`+1.94` (`[+0.36, +3.60]`, $P=0.99$)** |
| **`R5`. Placebo Pre-Trend ($\Delta Y_{t-1\to t}$)** | Pre-$t$ (348, 117) | `+0.24` (`[-0.34, +0.79]`, $P=0.79$) | `+0.07` (`[-0.21, +0.35]`, $P=0.66$) | `+0.59` (`[-0.55, +1.68]`, $P=0.83$) |
| **`R6`. Diffuse $\tau$ Prior ($\alpha=0.5, M_\tau=50$)** | $+10\text{y}$ (283, 112) | `+0.47` (`[-0.27, +1.19]`, $P=0.89$) | **`+0.29` (`[-0.13, +0.71]`, $P=0.91$)** | **`+1.67` (`[+0.03, +3.16]`, $P=0.98$)** |
| **`R7`. SWIID Measurement-Error Perturb.** | $+10\text{y}$ (283, 112) | **`+0.55` (`[-0.27, +1.38]`, $P=0.90$)** | **`+0.26` (`[-0.14, +0.66]`, $P=0.90$)** | **`+1.49` (`[-0.01, +2.99]`, $P=0.97$)** |
| **`R8`. Country-Blocked Out-of-Fold PS** | $+10\text{y}$ (283, 112) | **`+0.55` (`[-0.15, +1.28]`, $P=0.93$)** | **`+0.26` (`[-0.14, +0.64]`, $P=0.91$)** | **`+1.49` (`[+0.04, +2.94]`, $P=0.98$)** |
| **`R9`. Two-Stage Sequential G-Estimation** | $+10\text{y}$ (283, 112) | **`+0.70` (`[-0.02, +1.47]`, $P=0.97$)** | **`+0.39` (`[-0.00, +0.78]`, $P=0.97$)** | **`+1.51` (`[+0.18, +2.97]`, $P=0.99$)** |
| **`R10`. Pre-Treatment Fiscal Trend Controls** | $+10\text{y}$ (283, 112) | `+0.44` (`[-0.37, +1.21]`, $P=0.85$) | **`+0.32` (`[-0.08, +0.72]`, $P=0.93$)** | **`+1.68` (`[+0.11, +3.14]`, $P=0.98$)** |
| **`R11`. Non-Compositional Goods Tax / GDP** | $+10\text{y}$ (283, 112) | **`+0.54` (`[-0.23, +1.33]`, $P=0.92$)** | **`+0.30` (`[-0.09, +0.73]`, $P=0.94$)** | **`+1.42` (`[-0.21, +3.13]`, $P=0.96$)** |
| **`R12`. Pre-COVID Sample ($<2020$)** | $+10\text{y}$ (187, 90) | **`+0.71` (`[-0.30, +1.75]`, $P=0.92$)** | `+0.17` (`[-0.35, +0.70]`, $P=0.71$) | `+0.74` (`[-1.30, +2.71]`, $P=0.77$) |

*Table 7: Summary of robustness, identification, and falsification checks across the primary fiscal outcomes (with 95% CIs and posterior probabilities $P = P(\tau > 0 \mid \text{data})$).*

---

## 6. Mechanisms, Limitations, and Future Directions

### 6.1 Cohort Maturation Timelines and Practical Policy Lessons

How does government spending on universities start shifting tax composition within $+5$ years (`+1.24` pp on Direct Income Tax Share; `+0.21` pp on Direct Income Tax / GDP) before building over $+10$ years (`+0.34` to `+0.81` pp on Direct Income Tax / GDP and `+0.45` to `+0.94` pp on Non-Resource Tax / GDP)? Three mechanisms help explain the pattern of results across horizons and samples:

1. **Immediate Institutional Withholding ($+5$ Years), Graduate Career Maturation ($+10$ Years), and Pandemic Resilience (`R12`):** In the first five-year follow-up window, higher per-student university spending immediately expands formal university payrolls (academic staff, researchers, and administrators whose salaries are subject to automatic PAYE income tax withholding) whilst students in three-year bachelor's and one-to-two-year master's programmes enter their first formal jobs. By $+10$ years (years 10 to 14 after initial wave entry), two university cohorts have graduated and moved into prime-age formal careers. At the same time, `R12` shows that dropping the `2020-2024` outcome wave roughly halves the $+10$-year Direct Income Tax Share effect (from `+1.48` pp, $P=0.97$ to `+0.74` pp, $P=0.77$) and Direct Income Tax / GDP (from `+0.34` pp, $P=0.95$ to `+0.17` pp, $P=0.71$) whilst strengthening aggregate Non-Resource Tax / GDP (from `+0.45` pp to `+0.71` pp, $P=0.92$). During the 2020-2021 COVID-19 pandemic, retail lockdowns depressed VAT receipts while salaried graduate and professional employment shifted to remote work and was protected by wage-subsidy schemes and automatic withholding, amplifying the compositional shift in `2020-2024`.
2. **Protecting Per-Student Resources and Comparing Fiscal Magnitudes:** Expanding total university budgets without protecting per-student funding intensity yields weak fiscal returns (`+0.11` pp on Direct Income Tax / GDP in `M3f`). Countries that maintain or expand real resources *per student* (`M2b`, `M3b`, `M3d`) avoid institutional crowding (Bound et al., 2010; Deming and Walters, 2017; Chakrabarti et al., 2020) and collect more future direct tax. Because median public tertiary budgets stand at `0.47%` to `0.94%` of GDP (Table 1), a `25%` to `35%` relative expansion in per-student funding corresponds to roughly `0.15` to `0.30` pp of GDP in annual public expenditure, which is of the **same order of magnitude** as the estimated 10-year direct tax gains (`+0.34` to `+0.81` pp of GDP), suggestive of substantial partial fiscal recoupment.
3. **Where the Upside Is Largest:** Developing and massifying countries (like Brazil, Chile, or South Africa) expanding from elite (`<20%`) to massifying (`20-50%`) tertiary systems see the largest point estimates in direct income tax capacity (`+0.35` to `+0.56` pp of GDP) and total non-resource tax capacity (`+0.52` to `+0.86` pp of GDP), whereas mature high-income economies (like Denmark) exhibit a compositional shift toward direct income taxation (`+1.76` pp of revenue) with no detectable change in the aggregate tax-to-GDP level (`+0.21` pp, `95% CI [-0.75, +1.09]`, $P = 0.68$).

### 6.2 Limitations and Future Research

Several caveats apply when interpreting observational cross-country macro panels:

1. **Reverse causality and fiscal-capacity feedback:** A central threat in macro-fiscal panels is that growing tax capacity enables governments to spend more on higher education rather than the other way round (Baumol, 1967; World Bank, 2024; World Bank and UNESCO, 2024). Whilst I condition on baseline tax-to-GDP, baseline income and goods tax shares, lagged GDP growth, and explicit pre-treatment fiscal trends $\Delta Y_{i, t-1 \to t}$ (`R10`), observational conditioning cannot completely rule out multi-decade fiscal-capacity feedback loops.
2. **Unobserved concurrent reforms:** My identification of the total effect (`M1`) relies on conditional ignorability given the 19 baseline covariates and lagged growth, whilst the mediator-removed direct effect (`M2`) and sequential g-estimator (`R9`) assume sequential ignorability of the four post-treatment mediators (Imai et al., 2010; Acharya et al., 2016).
3. **Skilled emigration (brain drain):** In small low- and lower-middle-income countries, skilled emigration (Beine et al., 2008) can shift direct income tax receipts to destination countries whilst untaxed remittances support domestic consumption taxes.
4. **Central versus general government tax boundaries and five-year wave coarseness:** WDI fiscal series mainly record central government budgetary revenue, and averaging annual series into five-year waves blurs exact year-by-year timing and restricts the complete four-outcome sample to 121 countries.

These limitations point to several concrete avenues for future work:

* Extending longitudinal Bayesian causal forests to 15-to-25-year horizons so that researchers can compare government spending on early childhood, primary, and secondary schooling (Hanushek and Woessmann, 2012; Angrist et al., 2021) directly against tertiary education as school-age cohorts reach adulthood.
* Incorporating bilateral skilled migration matrices (Beine et al., 2008) as an explicit moderator in $\tau(W_{i,t})$ to measure how brain drain alters the fiscal return to public university subsidies in developing economies.
* Linking university funding cohorts directly to administrative employer-employee tax registers within individual countries to track graduate earnings and firm corporate tax payments year by year.

---

## Appendix A: Residual Covariance, MCMC Convergence, and Posterior Predictive Checks

| Residual Parameter Pair (`M2` Direct Model) | **$+5\text{y}$ Mean [95% CI]** | **$+10\text{y}$ Mean [95% CI]** |
| :--- | :---: | :---: |
| **1. Non-Resource Tax / GDP $\leftrightarrow$ Direct Income Tax / GDP** | **`+0.60` `[+0.51, +0.67]`** | **`+0.62` `[+0.53, +0.71]`** |
| **2. Direct Income Tax / GDP $\leftrightarrow$ Direct Income Tax Share** | **`+0.71` `[+0.65, +0.77]`** | **`+0.75` `[+0.68, +0.82]`** |
| **3. Direct Income Tax Share $\leftrightarrow$ Goods & Services Share** | **`-0.42` `[-0.52, -0.32]`** | **`-0.58` `[-0.69, -0.47]`** |
| **4. Direct Income Tax / GDP $\leftrightarrow$ Goods & Services Share** | **`-0.25` `[-0.35, -0.13]`** | **`-0.25` `[-0.38, -0.11]`** |
| **5. Non-Resource Tax / GDP $\leftrightarrow$ Goods & Services Share** | `+0.14` `[+0.02, +0.26]` | `+0.35` `[+0.20, +0.48]` |
| **6. Non-Resource Tax / GDP $\leftrightarrow$ Direct Income Tax Share** | `-0.04` `[-0.15, +0.08]` | `+0.05` `[-0.10, +0.21]` |
| **7. Residual SDs ($\sigma_1, \sigma_2, \sigma_3, \sigma_4$, pp)** | 1.86, 1.01, 4.08, 4.23 pp | 2.59, 1.38, 5.00, 4.98 pp |

*Table A1: Posterior mean cross-outcome residual correlations (with 95% CIs) and residual standard deviations from the four-outcome Multivariate Bayesian Causal Forest (`M2`).*

| Model & Tax Outcome | Horizon ($N$) | ATE Mean (SD) | **Split $\hat{R}$** | **ESS** | **MCSE** | Geweke $z$ | PPC $R^2$ | PPC Cov95 |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **1. `mvbcf` Non-Resource Tax / GDP** | $+5\text{y}$ (372) | `+0.020` (0.239) | **1.001** | 265 | 0.015 | `-1.15` | 0.338 | 96.0% |
| **2. `mvbcf` Direct Income Tax / GDP** | $+5\text{y}$ (372) | `+0.210` (0.131) | **1.000** | 267 | 0.008 | `-0.62` | 0.192 | 96.5% |
| **3. `mvbcf` Direct Income Tax Share** | $+5\text{y}$ (372) | `+1.241` (0.551) | **1.002** | 223 | 0.037 | `-3.03` | 0.293 | 95.4% |
| **4. `mvbcf` Goods & Services Share** | $+5\text{y}$ (372) | `-0.287` (0.544) | **1.005** | 182 | 0.040 | `+0.37` | 0.408 | 97.3% |
| **5. `mvbcf` Non-Resource Tax / GDP** | $+10\text{y}$ (283) | `+0.446` (0.409) | **1.002** | 202 | 0.029 | `-1.29` | 0.327 | 95.8% |
| **6. `mvbcf` Direct Income Tax / GDP** | $+10\text{y}$ (283) | `+0.344` (0.216) | **1.015** | 198 | 0.015 | `+1.86` | 0.270 | 96.5% |
| **7. `mvbcf` Direct Income Tax Share** | $+10\text{y}$ (283) | `+1.479` (0.793) | **1.003** | 198 | 0.056 | `+0.99` | 0.453 | 97.2% |
| **8. `mvbcf` Goods & Services Share** | $+10\text{y}$ (283) | `-0.559` (0.805) | **1.020** | 135 | 0.069 | `-0.56` | 0.592 | 97.5% |
| **9. `lbcf` Non-Resource Tax / GDP** | $+10\text{y}$ cum. (282) | `+0.460` (0.324) | **1.001** | 387 | 0.016 | `+0.98` | 0.580 | 95.7% |
| **10. `lbcf` Direct Income Tax / GDP** | $+10\text{y}$ cum. (282) | `+0.406` (0.158) | **1.002** | 389 | 0.008 | `+0.25` | 0.579 | 95.4% |
| **11. `lbcf` Direct Income Tax Share** | $+10\text{y}$ cum. (282) | `+1.937` (0.639) | **1.002** | 377 | 0.033 | `+1.38` | 0.605 | 96.5% |
| **12. `lbcf` Goods & Services Share** | $+10\text{y}$ cum. (282) | `-0.871` (0.687) | **1.004** | 348 | 0.037 | `+0.23` | 0.684 | 97.5% |

*Table A2: Post-burn-in MCMC convergence diagnostics and in-sample posterior predictive check (PPC) accuracy and 95% CI coverage across both `mvbcf` and `lbcf`.*

![Post-burn-in MCMC trace plots for the Mediator-Removed Direct Fiscal Effect across all four tax outcomes from both single-horizon mvbcf and longitudinal lbcf.](../outputs/figures/figA1_mcmc_convergence_traces.png)

## Appendix B: Computational Environment and Energy Report

| Pipeline Stage | Models Fitted | Wall-Clock (s) | Energy (Wh) | $\text{CO}_2\text{e}$ (g) |
| :--- | :--- | :---: | :---: | :---: |
| Step 04: `mvbcf` & Benchmarks | 30 four-outcome fits (2,000 iter) | 611.4 | 4.25 | 1.06 |
| Step 05: Longitudinal `lbcf` | 4 two-increment fits (2,500 iter) | 204.5 | 1.42 | 0.36 |
| **Total Modelling Pipeline** | **All 34 model fits** | **815.9** | **5.67** | **1.42** |

*Table B1: Computational wall-clock time, energy use, and estimated carbon footprint across the modelling pipeline.*
