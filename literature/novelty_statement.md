# Novelty and Gap Statement

## 1. Closest Existing Papers and What Each Establishes

1. **Valero & Van Reenen (2019), *Economics of Education Review* (`valero2019economic`):**
   - *What it establishes:* Examines 15,000 universities across 1,500 sub-national regions in 78 countries and shows that expansions in university presence raise future regional GDP per person through skilled labour supply and innovation.
   - *What it leaves open:* Focuses exclusively on aggregate output (GDP per person) rather than national tax revenue or fiscal structure, and does not separate whether university funding expands the tax base directly above and beyond general GDP growth.

2. **Jensen (2022), *American Economic Review* (`jensen2022employment`), and Bachas, Gadenne & Jensen (2024), *Review of Economic Studies* (`bachas2024informality`):**
   - *What they establish:* Show across nearly 100 countries that the transition from informal self-employment into formal salaried employment is the foundational driver of modern income tax capacity (`jensen2022employment`), whereas informal retail sectors force lower-income states to rely on indirect consumption taxes (`bachas2024informality`).
   - *What they leave open:* Treat the skill and employment structure of the workforce as a given developmental trend rather than testing whether national government investment in tertiary education causally accelerates this transition toward direct income and corporate profit taxation.

3. **Hendren & Sprung-Keyser (2020), *Quarterly Journal of Economics* (`hendren2020unified`), Trostel (2010), *Research in Higher Education* (`trostel2010fiscal`), and Chakrabarti, Gorton & Lovenheim (2020), *NBER Working Paper* (`chakrabarti2020state`):**
   - *What they establish:* Demonstrate within the United States that public expenditure on higher education and per-student state appropriations raise degree completion and generate substantial lifetime federal income tax receipts that can recoup upfront public subsidies.
   - *What they leave open:* Rely on single-country (US) microeconomic cohort simulations rather than global cross-national fiscal data, and cannot test whether national tertiary spending shifts aggregate macroeconomic tax capacity or whether UNESCO's composite per-student spending ratio masks institutional crowding across countries.

4. **Methodological Foundations - Hahn, Murray & Carvalho (2020), *Bayesian Analysis* (`hahn2020bayesian`), McJames, O'Shea, Goh & Parnell (2024), *JRSS Series A* (`mcjames2024mvbcf`), and McJames, O'Shea & Parnell (2024), *arXiv* (`mcjames2024lbcf`):**
   - *What they establish:* Introduce Bayesian Causal Forests (`hahn2020bayesian`) to prevent regularisation-induced confounding via separate prognostic and treatment-effect forests, and extend BCF to correlated multivariate outcomes (`mcjames2024mvbcf`) and longitudinal growth trajectories (`mcjames2024lbcf`) in educational assessments.
   - *What they leave open:* Neither Multivariate BCF nor Longitudinal BCF has previously been combined with causal mediation analysis (`acharya2016explaining`) to isolate direct vs mediated fiscal returns in macroeconomic panel data.

---

## 2. Specific Gap Filled by This Paper

This paper bridges the economics of higher education, the political economy of fiscal capacity, and Bayesian nonparametric causal inference through four specific contributions:

1. **Disaggregated Pure Tax Outcomes with a Built-In Negative Control:** Instead of studying aggregate GDP or constructing mechanical GDP-multiplied tax variables, we jointly model four pure percentage-point fiscal outcomes over $+5$ and $+10$ years: (i) domestic non-resource tax revenue (% of GDP), (ii) direct income, profit, and capital gains tax revenue (% of GDP), (iii) direct income and profit share of total revenue, and (iv) indirect goods and services (consumption/VAT) tax share of revenue as a negative-control specificity channel.
2. **Unbundling Tertiary Education Spending Denominators:** Focussing exclusively on public tertiary education, we unbundle the standard UNESCO per-student ratio (% of GDP per person) into real 2021 PPP dollars per university student (removing GDP per person from the denominator), observed within-country per-student expansions, and aggregate public tertiary budgets (% of GDP, removing student headcount from the denominator). This directly tests the macroeconomic institutional-crowding hypothesis (`bound2010have`; `deming2017impact`).
3. **Isolating Mediator-Removed Direct Fiscal Effects:** We pair Multivariate BCF (`mvbcf`) with sequential causal mediation adjustments (`acharya2016explaining`; `vanderweele2016mediation`) to separate the **Total Fiscal Effect (`M1`)** from the **Mediator-Removed Direct Fiscal Effect (`M2`)** net of forward GDP growth, tertiary enrolment expansion, inequality changes, and life expectancy changes.
4. **Ten-Year Longitudinal Trajectory Decomposition:** Using a three-wave Longitudinal BCF (`lbcf`), we decompose the $+5$-year initial effect ($\tau_1$) and the $+5\text{ to }+10$-year maturation effect ($\tau_2$) across 282 complete country trajectories, quantifying the probability of decade-long fiscal compounding.

---

## 3. Single-Sentence Novelty Claim

> "To our knowledge, no previous study has estimated the joint short- and long-run causal effects of national government spending on tertiary education across disaggregated tax revenue channels while separating mediating macroeconomic growth using Multivariate and Longitudinal Bayesian Causal Forests."

---

## 4. Assessment of Novelty and Proposed Title Options for arXiv / LinkedIn

The substantive and methodological gap is clear, well-defended against existing macro-fiscal and higher-education literatures, and well-suited for a high-visibility arXiv working paper and LinkedIn release (as well as subsequent submission to an applied statistics or empirical economics journal such as *JRSS Series A*, *Annals of Applied Statistics*, or *Journal of Applied Econometrics*).

Building on your suggested title (*"Does Increasing Government Spend on Tertiary Education Improve Fiscal Policy for Governments: A Causal Inference Analysis"*), here are three refined options that sharpen the second half ("Fiscal Policy for Governments" $\to$ "Future Tax Take" or "Fiscal Capacity") while keeping the causal inference focus front and centre:

1. **Option A (Closest to your wording, sharper fiscal outcome):**
   *Does Increasing Government Spend on Tertiary Education Improve the Future Tax Take? A Bayesian Causal Inference Analysis*
2. **Option B (Highlighting fiscal capacity & longitudinal/multivariate BCF):**
   *Does Government Spending on Tertiary Education Improve Fiscal Capacity? A Multivariate and Longitudinal Bayesian Causal Forest Analysis*
3. **Option C (Direct policy question + causal mediation):**
   *Does Increasing Government Spend on Tertiary Education Pay Off in Future Tax Revenue? A Causal Inference Analysis*
