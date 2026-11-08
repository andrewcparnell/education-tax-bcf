# Point-by-Point Response to Referees (Phase 7 Final Revision)

**Manuscript Title:** Does Funding Universities Increase the Tax Take? A Global Causal Analysis  
**Author:** Andrew C. Parnell (University College Dublin)  
**Target Venue:** *Journal of the Royal Statistical Society: Series A (Statistics in Society)*  
**Revision Date:** 8 November 2026

We thank the seven referees for their constructive, thorough, and insightful assessment of our continuous-treatment manuscript, codebase, interactive web application, and bibliography. All seven referees recommended **Minor Revision** (with zero major flaws, zero data-leakage issues, and zero fabricated citations). In this revision, we have addressed every minor comment, synchronised the companion markdown version (`paper/paper.md`) with the master LaTeX manuscript (`paper/paper.tex`), removed all legacy files from the earlier binary-treatment exploratory phase, and expanded our automated pipeline test suite (`tests/test_pipeline.R`) to verify cross-file numerical and path consistency automatically.

---

## Response to Reviewer 1 (Methodology & Causal Inference Referee)

1. **Out-of-bag expected treatment conditioning vs cross-fitted DML (`B6`) and two-stage sequential g-estimation (`R9`):**  
   We thank the referee for highlighting the distinction between how linear Double Machine Learning (`B6`) and our continuous-treatment Multivariate Bayesian Causal Forest (MV-BCF) aggregate heterogeneous treatment slopes, as well as the linear first-stage demediation in `R9`. In Appendix B (`paper/paper.tex` lines 407-413 and `paper/paper.md` line 217), we now explicitly explain that linear Robinson-style DML weights observations by their squared residual treatment variation $\tilde{Z}_{i,t}^2 = (Z_{i,t} - \hat{z}_{i,t})^2$, which places disproportionate weight on low- and lower-middle-income country-waves where UNESCO per-student ratio variance is largest and aggregate tax-to-GDP gains are noisy, whereas MV-BCF estimates a non-parametric slope $\hat{\tau}(X_{i,t})$ for each country-wave and averages those slopes equally across all $N = 283$ observations. We also clarify in Appendix B that our two-stage sequential g-estimation check (`R9`) uses a linear additive first stage to purge the four post-treatment macroeconomic growth mediators before fitting the MV-BCF sampler in the second stage, yielding a $+0.45\text{ pp}$ ($P = 0.91$) shift in the direct income tax share that closely brackets our one-step direct specification (`M2b`, $+0.71\text{ pp}$, $P = 0.96$) and total-effect specification (`M1b`, $+0.54\text{ pp}$, $P = 0.92$).

2. **Explicit citation to Hirano and Imbens (2004) in Section 2.3 and winsorisation boundary note in Section 6.2:**  
   We have added `\citep{hirano2004propensity}` directly in Section 2.3 (`paper/paper.tex` line 122 and `paper/paper.md` line 52) where we introduce the continuous-treatment generalisation of Bayesian Causal Forests and explain how the scalar out-of-bag expected dose $\hat{z}(X_{i,t}) = \hat{\mathbb{E}}[Z_{i,t} \mid X_{i,t}]$ replaces the binary propensity score. In Section 6.2 (Limitation 5) and the caption to Table 8 (`tab:z0_countries`), we also remind readers that because $Z^{\text{A}}_{i,t}$ is winsorised at $\pm 1.5$ dose units ($\pm 15\text{ pp}$ around each income group's training median), our continuous slope estimates represent the average marginal return over the central $\pm 15\text{ pp}$ policy range rather than an unbounded linear extrapolation to extreme multi-decade spending shocks.

---

## Response to Reviewer 2 (Public Economics & Higher Education Finance Referee)

1. **Reconciling the bilinear tax identity in the real PPP dollars per student specification (`M3b`, Row 3 of Table 3):**  
   We appreciate this helpful suggestion to walk readers through the exact fiscal accounting identity linking our three primary outcomes. In Section 5.2 (`paper/paper.tex` lines 253-256 and `paper/paper.md` line 154), we now explicitly show how the three positive $+10$-year slopes in Row 3 of Table 3 (`M3b`, real 2021 PPP dollars per student: $\tau_1 = +0.22\text{ pp}$ on total tax/GDP, $\tau_2 = +0.15\text{ pp}$ on direct income tax/GDP, and $\tau_3 = +0.47\text{ pp}$ on the direct income tax share) satisfy the bilinear identity $\text{Direct Income Tax / GDP} = \text{Total Tax / GDP} \times (\text{Income Tax Share} / 100)$. Evaluating the first-order approximation $\Delta(\text{Direct Income Tax / GDP}) \approx \tau_1 S_0 + T_0 \tau_3$ at the sample means ($T_0 \approx 16.5\%$ of GDP and $S_0 \approx 34.4\%$) yields $0.22 \times 0.344 + 0.165 \times 0.47 = 0.076 + 0.078 = +0.153\text{ pp}$, demonstrating that roughly half of the $+0.15\text{ pp}$ gain in direct income tax revenue as a share of GDP comes from expanding overall tax capacity and half comes from shifting the tax mix toward direct income taxation.

2. **Intensive-margin study duration and cohort gestation at $+5\text{ years}$ vs steady-state career horizons at $+10\text{ years}$:**  
   We have expanded Section 5.3 (`paper/paper.tex` lines 274-278 and `paper/paper.md` line 162) to clarify that even holding baseline gross enrolment fixed, higher per-student funding supports higher student retention, longer intensive-margin persistence into honours and postgraduate programmes, and fuller-time study (rather than part-time casual work) across a 3-to-4-year degree cycle before graduates reach their higher-earning late twenties. In Section 6.1 (`paper/paper.tex` lines 318-323 and `paper/paper.md` line 184), we also explicitly note that our 10-year fiscal return reflects just two five-year graduate cohorts in their late twenties and early thirties, whereas in a 40-year career steady state seven to eight five-year cohorts would be active in the labour force simultaneously.

3. **Clarifying the $+15\text{ pp}$ ($1.5$ dose unit) winsorisation cap in Appendix B Table 8 (`tab:z0_countries`):**  
   We have added an explicit explanatory note to the caption of Table 8 (`paper/paper.tex` lines 536-541) explaining that for the few developing economies sitting more than $15\text{ pp}$ below their income-group median (such as Rwanda, Guatemala, Cambodia, El Salvador, the Philippines, Peru, and Gabon), closing the entire raw distance to the median in a single step exceeds the $+15\text{ pp}$ ($1.5$ dose unit) winsorisation cap of the model, so the final two columns report the well-identified return to a standard $+10\text{ pp}$ ($+1.0$ dose unit) policy expansion alongside the cost of that $+10\text{ pp}$ step.

---

## Response to Reviewer 3 (Macro-Development & Fiscal Capacity Mechanisms Referee)

1. **Explaining why full-sample ($N = 283$) and training-only (`R13`, $N = 229$) estimates differ slightly in Section 3.1:**  
   We thank the referee for pointing out that readers benefit from a clear explanation of how the 5-fold country-blocked cross-fitting setup relates to the locked Fold 5 holdout test. In Section 3.1 (`paper/paper.tex` lines 163-167 and `paper/paper.md` line 66), we now state explicitly that our primary tables report 5-fold country-blocked cross-fitted estimates across the full sample ($N = 283$ at $+10\text{ years}$) to maximise statistical precision, whereas the locked 80% training-only fit (`R13`, Folds 1 to 4, $N = 229$, reported in Appendix B Table 7) excludes the 22 Fold 5 holdout countries entirely when generating the out-of-sample predictions in Section 5.4 and yields even stronger $+10$-year slopes ($+0.42\text{ pp}$ on total tax/GDP, $P = 0.99$, and $+0.22\text{ pp}$ on direct income tax/GDP, $P = 0.98$).

2. **Reporting horizon-specific sample sizes ($N = 371$ at $+5\text{y}$ and $N = 283$ at $+10\text{y}$) in Figure 6:**  
   We have updated Section 5.3 and the caption of Figure 6 (`paper/paper.tex` lines 281 and 286, and `paper/paper.md` line 164) to state both horizon sample sizes ($N = 371$ across 121 countries at $+5\text{ years}$ and $N = 283$ across 112 countries at $+10\text{ years}$) and to note that our balanced two-wave sub-panel sensitivity check (`R2`, $N = 283$ at both horizons) in Appendix B Table 7 confirms that the trajectory from $+5\text{ years}$ to $+10\text{ years}$ is not an artefact of wave attrition.

---

## Response to Reviewer 4 (Independent External Referee)

1. **Listing the five exact raw anomalies screened out in Section 3.1:**  
   We agree that naming the exact five country-wave observations screened out by our automated bounds check in `src/r/02_build_clean_tax_panel.R` strengthens transparency. In Section 3.1 (`paper/paper.tex` lines 155-158 and `paper/paper.md` line 66), we now name all five observations explicitly: four tax-to-GDP reporting anomalies outside $[0.5\%, 60.0\%]$ (`Sudan 1995-1999`, `Timor-Leste 2010-2014`, and `United Arab Emirates 2010-2014` and `2015-2019`) and one UNESCO tertiary spending recording error (`Madagascar 2015-2019` at $7{,}662\%$ of GDP per person).

2. **Reconciling the raw vs winsorised Low-Income group median ($183.8\%$ vs $150.0\%$) across Section 3.3 and Appendix B Table 8:**  
   We thank the referee for spotting this subtle distinction between the unwinsorised Low-Income training median ($183.8\%$) and the winsorised Scaling A reference median ($150.0\%$, because raw values are winsorised at $[5\%, 150\%]$ before centring). We have updated `src/r/03_eda_and_summary_tables.R` so that `tableA4_latest_z0_countries_costs_and_returns.csv` computes `med_spend_raw` from the winsorised series (`tert_spend_per_student_winsor`), aligning the Low-Income median in Appendix B Table 8 (`tab:z0_countries`) to $150.0\%$ (so Rwanda at $102.8\%$ has a gap of $+47.2\text{ pp}$ costing $0.31\%$ of GDP or EUR $0.12\text{B}$, vs $0.07\%$ of GDP or EUR $0.02\text{B}$ for a $+10\text{ pp}$ increase), and we explain both numbers explicitly in Section 3.3 (`paper/paper.tex` lines 191-194 and `paper/paper.md` line 117).

3. **Synchronising `paper/paper.md` with `paper/paper.tex` and sorting multi-reference citations chronologically:**  
   We have updated `paper/paper.md` across all sections and appendices so that every number, table, figure path, and CSV reference matches `paper/paper.tex` and `outputs/tables/*.csv` identically, and we have sorted all multi-reference parenthetical citations in both files in strict chronological order.

---

## Response to Reviewer 5 (Code, Data Hygiene & Leakage Auditor)

1. **Automated test coverage for `paper/paper.md` in `tests/test_pipeline.R`:**  
   We have updated `tests/test_pipeline.R` (Step 5) so that it automatically checks both `paper/paper.tex` and `paper/paper.md` against `outputs/tables/table1_mvbcf_ate_posteriors.csv` and `outputs/tables/table4_robustness_checks.csv` (`R13_TrainingSet_Only_10y`), and verifies that every `outputs/tables/*.csv` path referenced in `paper/paper.md` exists on disk.

2. **Replacing hardcoded `/tmp/rcpp_cache_edu_tax_bcf` with `file.path(tempdir(), ...)` and cleaning up legacy scripts:**  
   In `src/r/04_run_mvbcf_tax_models.R` (line 27), we have replaced `"/tmp/rcpp_cache_edu_tax_bcf"` with `file.path(tempdir(), "rcpp_cache_edu_tax_bcf")` for cross-platform safety on shared multi-user systems, and we have deleted the three unused legacy files from the earlier exploratory binary phase (`src/cpp/lbcf_3wave.cpp`, `src/r/05_run_longitudinal_bcf_tax.R`, and `src/r/07_publishability_gate_diagnostics.R`) along with the duplicate `results/` directory.

---

## Response to Reviewer 6 (Reproducibility & Open-Science Referee)

1. **Updating `environment.yml`, `README.md`, `CITATION.cff`, and `data/raw/PROVENANCE.md`:**  
   We have added `r-ggrepel>=0.9`, `r-patchwork>=1.2`, and `r-ranger>=1.16` to `environment.yml`, added `library(ggrepel)` explicitly at the top of `src/r/06_generate_figures_and_diagnostics.R`, and updated `README.md`, `CITATION.cff`, `run_all.sh`, and `data/raw/PROVENANCE.md` so that all documentation reflects the continuous-treatment MV-BCF pipeline and current file structure.

2. **Separating `fig0_panel_data_overview.{pdf,png}` from `eda_fig1_raw_distributions_and_bivariate.{pdf,png}`:**  
   We thank the referee for catching the filename collision between Step 03 (`03_eda_and_summary_tables.R`) and Step 06 (`06_generate_figures_and_diagnostics.R`). Step 06 now saves the Section 3 4-panel data overview figure to its own dedicated filename (`outputs/figures/fig0_panel_data_overview.{pdf,png}` and `paper/figures/fig0_panel_data_overview.{pdf,png}`), preserving the 2-panel training-set EDA diagnostic figure at `outputs/figures/eda_fig1_raw_distributions_and_bivariate.{pdf,png}` and `eda/figures/eda_fig1_raw_distributions_and_bivariate.{pdf,png}`.

---

## Response to Reviewer 7 (Citation & Bibliography Verification Referee)

1. **Chronological ordering of multi-reference `\citep{...}` commands:**  
   We have sorted all eight multi-reference `\citep{...}` commands in `paper/paper.tex` (and their parenthetical counterparts in `paper/paper.md`) in strict chronological order from oldest to newest.

2. **Bibliography metadata refinements (`mcjames2024mvbcf`, `ting2025estimating`, `chakrabarti2020state`, and `literature/literature.csv`):**  
   We have added `pages = {428--450}` to `mcjames2024mvbcf` and updated `ting2025estimating` to `author = {Ting, Angela and Linero, Antonio R.}` in `paper/references.bib`, refined our prose description of `chakrabarti2020state` in Section 2.2 (`paper/paper.tex` lines 96-99 and `paper/paper.md` line 40) to match the published NBER analysis of students' long-term financial outcomes and neighbourhood income into their thirties, removed the duplicate `data/references.bib` (`literature/references.bib`), and synchronised `literature/literature.csv` with all 36 references cited in `paper/references.bib`.
