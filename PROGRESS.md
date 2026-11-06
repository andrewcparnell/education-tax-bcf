# Project Progress

## Current status
Phase: Phase 7 (Final Revision, Rebuttal & Reproducibility Release - Checkpoint 5)
Last updated: 2026-11-05
Next action: Wait for user approval at Checkpoint 5 (`paper/paper.pdf`, `paper/paper.tex`, `paper/paper.md`, `reviews/response_to_reviewers.md`, `run_all.sh`, `environment.yml`, and `tests/test_pipeline.R`).

## Decisions made
- 2026-11-05 (Checkpoint 0): **Coding language:** Exclusively **R and C++** (`Rcpp` / `RcppArmadillo`) for the project pipeline (`src/r/` and `src/cpp/`). All Python scripts in `src/python/` have been removed and replaced by pure R scripts (`01_download_tax_education_data.R` and `02_build_clean_tax_panel.R`).
- 2026-11-05 (Checkpoint 0): **Target venue:** **arXiv preprint** (to be shared on LinkedIn), formatted in a clean LaTeX template (`paper/paper.tex` + `paper/paper.pdf` + `paper/paper.md`) and subjected to rigorous adversarial LLM peer review (Phase 6) before upload.
- 2026-11-05 (Checkpoint 0): **Formal targets (Causal Estimands only; out-of-sample forecast evaluation skipped):**
  1. Total Fiscal Effect (`M1`: ATE and subgroup CATEs at $+5$ and $+10$ years).
  2. Mediator-Removed Direct Fiscal Effect (`M2`: isolating the fiscal dividend net of forward GDP growth, tertiary enrolment expansion, inequality changes, and life expectancy changes).
  3. Three-Wave Longitudinal BCF step and cumulative effects ($\tau_1, \tau_2, \tau_{\text{cum}}$).
- 2026-11-05 (Checkpoint 0): **Substantive scope:** Focus **exclusively on government spending on tertiary (university) education** across the unbundled tertiary spending definitions. Primary and secondary education spending will be discussed in the Discussion/Conclusions section as an avenue for future research.
- 2026-11-05 (Checkpoint 1a): **Approved Title (Option A):** *Does Increasing Government Spend on Tertiary Education Improve the Future Tax Take? A Bayesian Causal Inference Analysis*. Approved `literature/novelty_statement.md` and `literature/literature.csv` (46 verified references with resolved DOIs).
- 2026-11-05 (Phase 2 Data Audit Fix): Discovered that two placeholder WGI columns (`wgi_gov_effectiveness` and `wgi_rule_of_law`) in the legacy Python pipeline had never been downloaded and were 100% `NA` (silently imputed to constant zeros). Removed the two empty placeholder columns so that every variable in `data/processed/data_dictionary.csv` and `clean_tax_panel.csv` has verified, non-empty observations.
- 2026-11-05 (Checkpoint 1b): Approved EDA report (`eda/eda_report.pdf`) and pure R data pipeline (`src/r/01` to `03`).
- 2026-11-05 (Checkpoint 2): Approved Phase 4 causal modelling results, leakage audit, method benchmarks/ablations (`B1`-`B4`), moderator importance, and robustness checks (`R1`-`R8`).
- 2026-11-05 (Phase 5 Landmark Style Conventions): Following `McJames et al. (2024a, JRSS-A)` and `Hahn et al. (2020, Bayesian Analysis)`, we treat `data` as plural (`--data-plural error`), use mixed narrative (`\citet{}`) and parenthetical (`\citep{}`) citations with `abbrvnat`, and write in clear, intuition-first British English with zero em dashes and zero banned AI words (`check_style.py --warnings-as-errors --data-plural error --all .` passes with 0 errors across all prose files).
- 2026-11-05 (Checkpoint 4): Approved all Phase 7 revisions recommended by the 7 adversarial review reports, including updating the title to *"Does Increasing Government Spending on Tertiary Education Improve the Future Tax Take? A Bayesian Causal Inference Analysis"*, elevating the within-country per-student spending expansion (`M3b`) co-equally with the level-regime contrast (`M2`), fixing `lbcf_3wave` and the C++ Metropolis-Hastings tree transition ratio, adding `B5` (`TWFE`), `B6` (`Double-ML`), and `R9`-`R12` (`Sequential G-Estimation`, `Pre-Trend Controls`, `Non-Compositional Negative Control`, `Pre-COVID Sample`), reporting 95% CrIs uniformly, and making the repository 100% portable.

## Environment Check (Recorded 2026-11-05)
- **R:** `R version 4.6.1 (2026-06-24)` with `Rcpp`, `RcppArmadillo`, `dplyr`, `tidyr`, `readr`, `ggplot2`
- **C++ compiler:** Apple clang with `RcppArmadillo` (`src/cpp/Makevars`)
- **LaTeX:** `pdfTeX 3.141592653-2.6-1.40.29 (TeX Live 2026)` and `bibtex` (`/Library/TeX/texbin/bibtex`)
- **Quarto:** `/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto`
- **Git:** `/usr/bin/git`

## Open questions for the user (Checkpoint 5)
1. Are you happy with the final compiled manuscript (`paper/paper.pdf`), point-by-point response to reviewers (`reviews/response_to_reviewers.md`), and one-command reproducibility suite (`run_all.sh`, `environment.yml`, and `tests/test_pipeline.R`) for arXiv submission?

## Phase log
- Phase 0: complete (2026-11-05). Output: `PROGRESS.md`, `LICENSE`, `CITATION.cff`, `README.md`, `data/raw/PROVENANCE.md`, `scripts/check_style.py`, `outputs/` directory structure.
- Phase 1: complete (2026-11-05). Output: `literature/novelty_statement.md`, `literature/literature.csv`, and verified `paper/references.bib` (49 entries with resolved DOIs).
- Phase 2: complete (2026-11-05). Output: Pure R scripts `src/r/01_download_tax_education_data.R` and `src/r/02_build_clean_tax_panel.R`, `data/processed/clean_tax_panel.csv` (exact numeric match to original panel), `data/processed/data_dictionary.csv` (55 variables with units, ranges, and missingness), and `data/processed/splits/country_folds.csv`.
- Phase 3: complete (2026-11-05). Output: `src/r/03_eda_and_summary_tables.R`, `eda/eda_report.qmd`, `eda/eda_report.pdf`, `eda/eda_report.html`, `outputs/tables/eda_table0` to `eda_table6`, and `outputs/figures/eda_fig1` to `eda_fig3`.
- Phase 4: complete (2026-11-05). Output: `src/r/04_run_mvbcf_tax_models.R`, `src/r/05_run_longitudinal_bcf_tax.R`, `src/r/06_generate_figures_and_diagnostics.R`, `outputs/tables/leakage_audit.csv`, `table1_mvbcf_ate_posteriors.csv`, `table2_residual_correlations.csv`, `table3_subgroup_cates.csv`, `table_method_benchmarks.csv`, `table_moderator_importance.csv`, `table4_robustness_checks.csv`, `table5_longitudinal_bcf_trajectories.csv`, `tableA1_convergence_and_fit_diagnostics.csv`, `tableA2_compute_and_energy.csv`, and `outputs/figures/fig1` to `fig5` + `figA1`.
- Phase 5: complete (2026-11-05). Output: `paper/paper.tex`, `paper/paper.pdf`, `paper/paper.md`, and `paper/journal_template/README.md`.
- Phase 6: complete (2026-11-05). Output: Seven adversarial referee reports (`reviews/reviewer1_methodology.md` through `reviews/reviewer6_reproducibility.md` plus `reviews/reviewer4_LLM.md`), Publishability Gate diagnostic script (`src/r/07_publishability_gate_diagnostics.R`) and table (`outputs/tables/publishability_gate_diagnostics.csv`), and editorial synthesis (`reviews/editorial_synthesis.md`).
- Phase 7: complete, awaiting Checkpoint 5 approval (2026-11-05). Output: Revised C++ samplers (`src/cpp/mvbcf_source_code.cpp`, `src/cpp/lbcf_3wave.cpp`), portable `src/cpp/Makevars`, portable R pipeline (`src/r/01` through `06`), regenerated tables (`outputs/tables/`) and figures (`outputs/figures/`, `paper/figures/`), updated manuscript (`paper/paper.tex`, `paper/paper.pdf` - 24 pages, 0 warnings/overfull boxes, `paper/paper.md`), point-by-point response (`reviews/response_to_reviewers.md`), and reproducibility release files (`run_all.sh`, `environment.yml`, `tests/test_pipeline.R`).
