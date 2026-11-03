# Does Public University Funding Pay for Itself?
## Isolating the Short- and Long-Run Tax Dividend Using Multivariate and Longitudinal Bayesian Causal Forests

**Author:** Andrew C. Parnell (School of Mathematics and Statistics, University College Dublin)

### Overview
This repository contains the end-to-end data pipeline, exploratory data analysis, C++/R Multivariate and Longitudinal Bayesian Causal Forest implementations (`mvbcf` and `lbcf_3wave`), publication figures, and manuscript investigating whether increased public investment in university (tertiary) education produces short-term ($+5$-year) and long-term ($+10$-year) benefits to a country's tax take once mediating macroeconomic variables are separated out.

### Repository Structure
* **Data Pipeline (`src/python/` & `data/`):**
  * `src/python/01_download_tax_education_data.py`: Downloads disaggregated fiscal and education series from the World Bank WDI API and verifies SHA-256 checksums (`data/raw/checksums_sha256.json`).
  * `src/python/02_build_clean_tax_panel.py`: Constructs the 5-year panel (`data/processed/clean_tax_panel.csv`, 1,736 country-waves across 217 countries), screens impossible raw WDI reporting errors (`tax_rev_gdp_pct > 60%`), and exports the variable codebook (`data/processed/codebook_variables.csv`).
* **Exploratory Data Analysis (`eda/`):**
  * `src/r/01_eda_and_summary_tables.R`: Generates summary tables across World Bank income groups and university funding regimes.
  * `eda/eda_report.qmd` (`eda/eda_report.pdf`, `eda/eda_report.html`): Standalone exploratory data analysis report.
* **Bayesian Causal Forest Engines (`src/cpp/` & `src/r/`):**
  * `src/cpp/mvbcf_source_code.cpp`: C++ (`RcppArmadillo`) Multivariate Bayesian Causal Forest Gibbs sampler with Inverse-Wishart cross-outcome covariance $\Sigma$.
  * `src/cpp/lbcf_3wave.cpp`: C++ (`RcppArmadillo`) Three-Wave Longitudinal Bayesian Causal Forest sampler tracking $+5$-year ($\tau_1$) and $+5\text{ to }+10$-year ($\tau_2$) trajectories.
  * `src/r/02_run_mvbcf_tax_models.R`: Runs the Total Fiscal Effect (`M1`), Mediator-Removed Direct Fiscal Effect (`M2`), unbundled spending definitions (`M3`), subgroup CATEs, and five robustness checks (`R1`-`R5`).
  * `src/r/03_run_longitudinal_bcf_tax.R`: Runs the three-wave Longitudinal BCF trajectory models across all four tax outcomes.
  * `src/r/04_generate_figures_and_diagnostics.R`: Generates all main publication figures (`fig1`-`fig5`), MCMC trace plots (`figA1`), and convergence diagnostics (`tableA1_convergence_and_fit_diagnostics.csv`).
* **Manuscript (`paper/`):**
  * `paper/education_tax_bcf_paper.qmd`: Quarto source manuscript (including Appendices A and B).
  * `paper/education_tax_bcf_paper.pdf`: Rendered 20-page PDF manuscript.
  * `paper/education_tax_bcf_paper.md` & `paper/education_tax_bcf_paper.html`: Standalone Markdown and HTML versions of the manuscript.
  * `paper/references.bib`: BibTeX bibliography.
