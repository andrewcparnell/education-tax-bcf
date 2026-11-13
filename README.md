# Does Increasing Government Spending on Tertiary Education Provide a Return on Investment?
## A Continuous-Treatment Bayesian Causal Inference Analysis Using Multivariate Bayesian Causal Forests

**Author:** Andrew C. Parnell (School of Mathematics and Statistics, University College Dublin)

### Overview
This repository contains the end-to-end R and C++ data pipeline, exploratory data analysis, continuous-treatment Multivariate Bayesian Causal Forest implementation (`mvbcf`), unseen-country holdout validation, publication figures, manuscript, and interactive policy web application investigating whether increased public investment in tertiary (university) education produces short-term ($+5$-year) and long-term ($+10$-year) improvements in a country's fiscal capacity and national tax take once mediating macroeconomic variables are separated out.

### One-Command Reproducibility (`run_all.sh`)
To rebuild the entire dataset, EDA tables, continuous-treatment causal forest models, publication figures, interactive app payload, automated verification tests, LaTeX PDF manuscript, and house-style check from scratch:
```bash
conda env create -f environment.yml
conda activate education-tax-bcf
bash run_all.sh
```

### Repository Structure
* **Data Pipeline (`src/r/` & `data/`):**
  * `src/r/01_download_tax_education_data.R`: Verifies disaggregated fiscal and tertiary education series from the World Bank WDI API and SWIID, and checks SHA-256 checksums (`data/raw/PROVENANCE.md` and `data/raw/checksums_sha256.json`).
  * `src/r/02_build_clean_tax_panel.R`: Constructs the 5-year panel (`data/processed/clean_tax_panel.csv`, 1,736 country-waves across 217 sovereign countries) and non-overlapping 10-year panel (`data/processed/clean_tax_panel_10y_nonoverlapping.csv`), creates the country-blocked 5-fold split (`data/processed/splits/country_folds.csv` with Folds 1 to 4 as the 80% training countries and Fold 5 as the 20% locked holdout test countries), constructs the continuous treatment doses `Z_cont_10pp` (Scaling A: $+10\text{ pp}$ of GDP per person per student) and `Z_cont_log25pct` (Scaling B: $+25\%$ relative per-student expansion), and exports the data dictionary (`data/processed/data_dictionary.csv`).
* **Exploratory Data Analysis (`eda/`):**
  * `src/r/03_eda_and_summary_tables.R`: Generates training-set summary tables, out-of-fold Random Forest expected-treatment conditioning $\hat{z}(X_{i,t}) = \mathbb{E}[Z_{i,t} \mid X_{i,t}]$ diagnostics, missingness checks, and temporal/spatial correlation summaries.
  * `eda/eda_report.qmd` (`eda/eda_report.pdf`, `eda/eda_report.html`): Standalone exploratory data analysis report on the training countries.
* **Continuous-Treatment Bayesian Causal Forest Engine & Benchmarks (`src/cpp/` & `src/r/`):**
  * `src/cpp/mvbcf_source_code.cpp` & `src/r/mvbcf_helpers.R`: C++ (`RcppArmadillo`) Multivariate Bayesian Causal Forest Gibbs sampler supporting continuous treatment doses $Z_{i,t}$ with Inverse-Wishart cross-outcome covariance $\Sigma$ and Chipman et al. (2010) reversible-jump Metropolis-Hastings tree transitions.
  * `src/r/04_run_mvbcf_tax_models.R`: Runs the Total Fiscal Effect (`M1`), Mediator-Removed Direct Fiscal Effect (`M2`), unbundled continuous tertiary spending exposures (`M3a`-`M3f`), Scaling A vs Scaling B model-fit and unseen-country holdout validation, subgroup CATE slopes, benchmark model comparisons (`B1`-`B6`), and robustness checks (`R1`-`R13`).
  * `src/r/06_generate_figures_and_diagnostics.R`: Generates all publication figures (`fig0`-`fig6`, `figA1`, `figA2`), MCMC convergence diagnostics (`outputs/tables/tableA1_convergence_and_fit_diagnostics.csv`), compute and LLM energy footprint (`outputs/tables/tableA2_compute_and_energy.csv`), continuous $\hat{z}(X)$ balance diagnostics (`outputs/tables/tableA3_propensity_overlap_and_balance.csv`), and latest-wave below-median country funding gap projections (`outputs/tables/tableA4_latest_z0_countries_costs_and_returns.csv`).
  * `tests/test_pipeline.R`: Automated verification tests checking panel invariants, country-blocked fold isolation, and 100% numerical synchronisation across CSV tables, `paper/paper.tex`, and `paper/paper.md`.
* **Outputs (`outputs/`):**
  * `outputs/figures/`: Vector PDF and high-resolution PNG figures.
  * `outputs/tables/`: CSV summary tables and diagnostic outputs.
  * `outputs/models/`: Fitted model run metadata (`outputs/models/mvbcf_run_metadata.json`).
* **Literature, Manuscript & Reviews (`literature/`, `paper/` & `reviews/`):**
  * `literature/novelty_statement.md` & `literature/literature.csv`: Novelty assessment and verified bibliography table with resolved DOIs.
  * `paper/paper.tex`, `paper/paper.pdf`, and `paper/paper.md`: arXiv-ready LaTeX manuscript, compiled PDF, and standalone Markdown version.
  * `paper/references.bib`: Verified BibTeX bibliography.
  * `reviews/`: Seven independent specialist referee reports (`reviewer1_methodology.md` through `reviewer7_citation_audit.md`) and point-by-point response letter (`response_to_reviewers.md`).
* **Interactive Web Application (`app/`):**
  * `app/index.html`, `app/app.js`, `app/styles.css`, and `app/app.R`: Three-tab interactive web application allowing users to scale a continuous funding dose slider ($+5\text{ pp}$ to $+30\text{ pp}$ of GDP per person per student), compare country-specific $+5$-year and $+10$-year fiscal effects, play a Gapminder-style animated trajectory of historical tertiary spending and tax revenue across the 8 five-year waves (`1985-1989` to `2020-2024`), and simulate custom policy and structural moderator scenarios (`CATE`).
  * `app/prepare_app_data.R`: Exports the self-contained data bundle in `app/data/`.

### Ethics, Licensing, and Data Redistribution
* **Ethics:** This study analyses aggregate national macroeconomic indicators for sovereign countries. No human subjects or personally identifiable information are involved, and institutional ethical approval is not required.
* **Data Licensing:** All raw data sources (World Bank WDI/UIS/GFS/WGI and SWIID v9.6) are licensed under **Creative Commons Attribution 4.0 International (CC BY 4.0)**, which explicitly permits redistribution with attribution. Exact source URLs, timestamps, file sizes, and SHA-256 checksums are recorded in `data/raw/PROVENANCE.md`.
* **Code Licence:** All R and C++ source code in this repository is released under the **MIT Licence** (`LICENSE`).
