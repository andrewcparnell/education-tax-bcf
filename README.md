# Does Increasing Government Spending on Tertiary Education Improve the Future Tax Take?
## A Bayesian Causal Inference Analysis Using Multivariate and Longitudinal Bayesian Causal Forests

**Author:** Andrew C. Parnell (School of Mathematics and Statistics, University College Dublin)

### Overview
This repository contains the end-to-end R and C++ data pipeline, exploratory data analysis, Multivariate and Longitudinal Bayesian Causal Forest implementations (`mvbcf` and `lbcf_3wave`), publication figures, and manuscript investigating whether increased public investment in tertiary (university) education produces short-term ($+5$-year) and long-term ($+10$-year) improvements in a country's fiscal capacity and national tax take once mediating macroeconomic variables are separated out.

### One-Command Reproducibility (`run_all.sh`)
To rebuild the entire dataset, EDA tables, causal forest models, publication figures, automated verification tests, LaTeX PDF manuscript, and house-style check from scratch:
```bash
conda env create -f environment.yml
conda activate education-tax-bcf
bash run_all.sh
```

### Repository Structure
* **Data Pipeline (`src/r/` & `data/`):**
  * `src/r/01_download_tax_education_data.R`: Downloads disaggregated fiscal and tertiary education series from the World Bank WDI API and SWIID, and verifies SHA-256 checksums (`data/raw/PROVENANCE.md` and `data/raw/checksums_sha256.json`).
  * `src/r/02_build_clean_tax_panel.R`: Constructs the 5-year panel (`data/processed/clean_tax_panel.csv`, 1,736 country-waves across 217 sovereign countries), screens impossible raw WDI reporting errors (`tax_rev_gdp_pct > 60%` or `< 0.5%`), and exports the data dictionary (`data/processed/data_dictionary.csv`).
* **Exploratory Data Analysis (`eda/`):**
  * `src/r/03_eda_and_summary_tables.R`: Generates summary tables, positivity/overlap diagnostics, missingness checks, and temporal/spatial correlation summaries.
  * `eda/eda_report.qmd` (`eda/eda_report.pdf`, `eda/eda_report.html`): Standalone exploratory data analysis report.
* **Bayesian Causal Forest Engines & Benchmarks (`src/cpp/` & `src/r/`):**
  * `src/cpp/mvbcf_source_code.cpp`: C++ (`RcppArmadillo`) Multivariate Bayesian Causal Forest Gibbs sampler with Inverse-Wishart cross-outcome covariance $\Sigma$ and Chipman et al. (2010) Metropolis-Hastings tree transition ratio.
  * `src/cpp/lbcf_3wave.cpp`: C++ (`RcppArmadillo`) Three-Wave Longitudinal Bayesian Causal Forest sampler tracking $+5$-year ($\tau_1$) and $+5\text{ to }+10$-year ($\tau_2$) trajectories.
  * `src/r/04_run_mvbcf_tax_models.R`: Runs the Total Fiscal Effect (`M1`), Mediator-Removed Direct Fiscal Effect (`M2`), unbundled tertiary spending definitions (`M3`), subgroup CATEs, benchmark model comparisons (`B1`-`B6`), and robustness checks (`R1`-`R12`).
  * `src/r/05_run_longitudinal_bcf_tax.R`: Runs the three-wave Longitudinal BCF trajectory models across all four tax outcomes.
  * `src/r/06_generate_figures_and_diagnostics.R`: Generates all main publication figures (`fig1`-`fig5`), MCMC trace plots (`figA1`), and convergence diagnostics (`outputs/tables/tableA1_convergence_and_fit_diagnostics.csv`).
  * `tests/test_pipeline.R`: Automated verification tests checking panel invariants, fold isolation, and output completeness.
* **Outputs (`outputs/`):**
  * `outputs/figures/`: Vector PDF and high-resolution PNG figures.
  * `outputs/tables/`: CSV summary tables and diagnostic outputs.
  * `outputs/models/`: Fitted model logs and run metadata.
* **Literature & Manuscript (`literature/` & `paper/`):**
  * `literature/novelty_statement.md` & `literature/literature.csv`: Novelty assessment and verified bibliography table with resolved DOIs.
  * `paper/paper.tex`, `paper/paper.pdf`, and `paper/paper.md`: arXiv-ready LaTeX manuscript, compiled PDF, and standalone Markdown version.
  * `paper/references.bib`: Verified BibTeX bibliography.
* **Interactive Web Application (`app/`):**
  * `app/index.html`, `app/app.js`, `app/styles.css`, and `app/app.R`: Three-tab interactive web application allowing users to compare country-specific $+5$-year and $+10$-year fiscal effects ($Z = 0 \to 1$), play a Gapminder-style animated trajectory of historical tertiary spending and tax revenue across the 8 five-year waves (`1985-1989` to `2020-2024`), and simulate custom policy and structural moderator scenarios (`CATE`).
  * `app/prepare_app_data.R`: Exports the self-contained data bundle in `app/data/`.

### Ethics, Licensing, and Data Redistribution
* **Ethics:** This study analyses aggregate national macroeconomic indicators for sovereign countries. No human subjects or personally identifiable information are involved, and institutional ethical approval is not required.
* **Data Licensing:** All raw data sources (World Bank WDI/UIS/GFS/WGI and SWIID v9.6) are licensed under **Creative Commons Attribution 4.0 International (CC BY 4.0)**, which explicitly permits redistribution with attribution. Exact source URLs, timestamps, file sizes, and SHA-256 checksums are recorded in `data/raw/PROVENANCE.md`.
* **Code Licence:** All R and C++ source code in this repository is released under the **MIT Licence** (`LICENSE`).
