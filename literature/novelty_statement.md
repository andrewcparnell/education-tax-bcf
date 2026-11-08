# Novelty and Gap Statement (Continuous-Treatment MV-BCF & Country-Holdout Evaluation)

## 1. Closest Existing Papers and What Each Establishes

1. **Valero & Van Reenen (2019), *Economics of Education Review* (`valero2019economic`):**
   - *What it establishes:* Examines 15,000 universities across 1,500 sub-national regions in 78 countries and shows that expansions in university presence raise future regional GDP per person through skilled labour supply and innovation.
   - *What it leaves open:* Focuses exclusively on aggregate output (GDP per person) rather than national tax revenue or fiscal structure, and does not test whether government university funding expands the tax base or shifts the tax mix toward direct income taxation.

2. **Jensen (2022), *American Economic Review* (`jensen2022employment`), and Bachas, Gadenne & Jensen (2024), *Review of Economic Studies* (`bachas2024informality`):**
   - *What they establish:* Show across nearly 100 countries that the transition from informal self-employment into formal salaried employment is the foundational driver of modern income tax capacity (`jensen2022employment`), whereas informal retail sectors force lower-income states to rely on indirect consumption taxes (`bachas2024informality`).
   - *What they leave open:* Treat the skill and employment structure of the workforce as a secular developmental trend rather than testing whether national government investment in tertiary education causally accelerates this transition toward direct income and corporate profit taxation.

3. **Hendren & Sprung-Keyser (2020), *Quarterly Journal of Economics* (`hendren2020unified`), Trostel (2010), *Research in Higher Education* (`trostel2010fiscal`), and Chakrabarti, Gorton & Lovenheim (2020), *NBER Working Paper* (`chakrabarti2020state`):**
   - *What they establish:* Demonstrate within the United States that public expenditure on higher education and per-student state appropriations raise degree completion and generate substantial lifetime federal income tax receipts that recoup upfront public subsidies.
   - *What they leave open:* Rely on single-country (US) microeconomic cohort simulations rather than global cross-national fiscal data, and cannot test whether national tertiary spending shifts aggregate macroeconomic tax capacity or whether UNESCO's composite per-student spending ratio masks institutional crowding across countries.

4. **Methodological Foundations - Hahn, Murray & Carvalho (2020), *Bayesian Analysis* (`hahn2020bayesian`), McJames, O'Shea, Goh & Parnell (2025), *JRSS Series A* (`mcjames2024mvbcf`), Hirano & Imbens (2004) (`hirano2004propensity`), and Robinson (1988), *Econometrica* (`robinson1988root`):**
   - *What they establish:* Introduce Bayesian Causal Forests (`hahn2020bayesian`) to prevent regularisation-induced confounding via separate prognostic and treatment-effect forests, extend BCF to correlated multivariate outcomes (`mcjames2024mvbcf`), and establish continuous-treatment orthogonalisation and generalised propensity score conditioning (`robinson1988root`; `hirano2004propensity`).
   - *What they leave open:* Multivariate BCF has previously been applied only to binary treatments in student-level educational assessments (`mcjames2024mvbcf`) rather than continuous policy doses in cross-national macroeconomic panels with out-of-sample country-holdout validation.

---

## 2. Specific Gap Filled by This Paper

This paper bridges the economics of higher education, the political economy of fiscal capacity, and Bayesian nonparametric causal inference through four specific contributions:

1. **Continuous-Treatment Multivariate Bayesian Causal Forest (MV-BCF) with Random Forest Expected-Treatment Conditioning:** Rather than dichotomising university spending at an arbitrary threshold (which creates artificial step-function boundary jumps for countries sitting near the median), we model continuous tertiary education spending $Z_{i,t} \in \mathbb{R}$ directly in a four-outcome C++ MV-BCF sampler, conditioning the prognostic forest on out-of-bag / out-of-fold Random Forest expected-treatment predictions $\hat{z}(X_{i,t}) = \mathbb{E}[Z_{i,t} \mid X_{i,t}]$ (`breiman2001random`; `hirano2004propensity`; `wright2017ranger`) to guard against regularisation-induced confounding (`hahn2020bayesian`).
2. **Head-to-Head Comparison of Continuous Treatment Scalings and Unbundled Denominators:** We compare two complementary continuous scalings of per-student university spending - **Scaling A** (winsorised per-student ratio per $+10\text{ pp}$ of GDP per person) and **Scaling B** (log-relative scale per $+25\%$ increase in per-student funding) - alongside continuous within-country 5-year funding changes ($\Delta Z_{i,t}$), real 2021 PPP dollars per student, and aggregate university budgets (% of GDP), evaluating both causal estimates and residual diagnostics.
3. **Disaggregated Pure Tax Outcomes with a Built-In Negative Control:** We jointly model four percentage-point fiscal outcomes over $+5$ and $+10$ years: (i) domestic non-resource tax revenue (% of GDP), (ii) direct income, profit, and capital gains tax revenue (% of GDP), (iii) direct income and profit share of total revenue, and (iv) indirect goods and services (consumption/VAT) tax share of revenue.
4. **Strict Country-Blocked Holdout & Cross-Validation Evaluation on Unseen Countries:** We hold out 20% of sovereign countries completely during exploratory data analysis and model specification, and run 5-fold country-blocked cross-validation across all 121 countries to evaluate out-of-sample RMSE, MAE, $R^2$, Continuous Ranked Probability Score (CRPS; `gneiting2007strictly`), empirical 80%/95% interval calibration, and paired Diebold-Mariano / block-bootstrapped skill comparisons (`diebold1995comparing`) against competing machine learning and econometric baselines.

---

## 3. Single-Sentence Novelty Claim

> "We believe this is the first global study to use continuous-treatment Multivariate Bayesian Causal Forests to test whether public university funding increases future tax revenue and shifts the tax mix toward direct income taxation, validated through out-of-sample holdout testing on unseen countries."

---

## 4. Landmark Papers and Structural Blueprint

- **Chosen Landmark Papers:** `McJames et al. (2025, JRSS Series A, doi:10.1093/jrsssa/qnae140)` and `Hahn et al. (2020, Bayesian Analysis, doi:10.1214/19-BA1195)`.
- **Target Venue:** **arXiv preprint** (with *JRSS Series A* and *Economics of Education Review* as journal targets).
- **House Conventions:** Plural `data` (`--data-plural error`), British English throughout, zero em dashes, zero banned AI words, chronological multi-reference citations, self-contained figures and tables with takeaway sentences in captions.
