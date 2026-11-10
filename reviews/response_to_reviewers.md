# Point-by-Point Response to Referees (Phase 7 Final Revision)

**Manuscript Title:** Does Increasing Government Spending on Tertiary Education Improve the Future Tax Take? A Bayesian Causal Inference Analysis  
**Author:** Andrew C. Parnell (University College Dublin)  
**Target Venue:** *Journal of the Royal Statistical Society: Series A (Statistics in Society)*  
**Revision Date:** 10 November 2026

We thank the seven independent referees and the author review (Reviewer 8) for their constructive, thorough, and insightful assessment of our continuous-treatment manuscript, codebase, interactive web application, and bibliography. All referees recommended **Minor Revision** (with zero major flaws, zero data-leakage issues, and zero fabricated citations). In this revision, we have addressed every comment across all eight reviews, synchronised the companion markdown version (`paper/paper.md`) with the master LaTeX manuscript (`paper/paper.tex`), removed all legacy files from the earlier binary-treatment exploratory phase, and expanded our automated pipeline test suite (`tests/test_pipeline.R`) to verify cross-file numerical and path consistency automatically.

---

## Response to Reviewer 1 (Methodology & Causal Inference Referee)

1. **Out-of-fold predicted-funding conditioning vs cross-fitted DML (`B6`) and two-stage sequential g-estimation (`R9`):**  
   We thank the referee for highlighting the distinction between how linear Double Machine Learning (`B6`) and our continuous-treatment Multivariate Bayesian Causal Forest (MV-BCF) aggregate heterogeneous treatment slopes, as well as the linear first-stage demediation in `R9`. In Appendix B (`paper/paper.tex` and `paper/paper.md`), we now explicitly explain that linear Robinson-style DML weights observations by their squared residual treatment variation $\tilde{Z}_{i,t}^2 = (Z_{i,t} - \hat{z}_{i,t})^2$, which places disproportionate weight on low- and lower-middle-income country-waves where UNESCO per-student ratio variance is largest and aggregate tax-to-GDP gains are noisy, whereas MV-BCF estimates a nonparametric slope $\hat{\tau}(W_{i,t})$ for each country-wave and averages those slopes equally across all $N = 283$ observations. We also clarify in Appendix B that our two-stage sequential g-estimation check (`R9`) uses a linear additive first stage to purge the four post-treatment macroeconomic growth mediators before fitting the MV-BCF sampler in the second stage, yielding a $+0.45\text{ pp}$ ($P = 0.91$) shift in the direct income tax share ($Y_3$) that closely brackets our one-step direct specification (`M2b`, $+0.71\text{ pp}$, $P = 0.96$) and total-effect specification (`M1b`, $+0.54\text{ pp}$, $P = 0.92$).

2. **Explicit citation to Hirano and Imbens (2004) in Section 2.3 and winsorisation boundary note in Section 6.2:**  
   We have added `\citep{hirano2004propensity}` directly in Section 2.3 (`paper/paper.tex` and `paper/paper.md`) where we introduce the continuous-treatment generalisation of Bayesian Causal Forests and explain how the predicted continuous funding level $\hat{z}(X_{i,t}) = \hat{\mathbb{E}}[Z_{i,t} \mid X_{i,t}]$ replaces the binary propensity score. In Section 6.2 (Limitation 5) and the caption to Table 6 (`tab:z0_countries`), we also remind readers that because $Z_{1,i,t}$ is winsorised at $\pm 1.5$ units ($\pm 15\text{ pp}$ around each income group's training median), our continuous slope estimates represent the average marginal return over the central $\pm 15\text{ pp}$ policy range rather than an unbounded linear extrapolation to extreme multi-decade spending shocks.

---

## Response to Reviewer 2 (Public Economics & Higher Education Finance Referee)

1. **Reconciling the bilinear tax identity in the real PPP dollars per student specification (`M3b`, $Z_3$):**  
   We appreciate this helpful suggestion to walk readers through the exact fiscal accounting identity linking our primary outcomes. In Section 3.2 and Section 5.2 (`paper/paper.tex` and `paper/paper.md`), we show how the three positive $+10$-year slopes under $Z_3$ (`M3b`, real 2021 PPP dollars per student: $\tau_1 = +0.22\text{ pp}$ on total tax/GDP $Y_1$, $\tau_2 = +0.15\text{ pp}$ on direct income tax/GDP $Y_2$, and $\tau_3 = +0.47\text{ pp}$ on the direct income tax share $Y_3$) satisfy the bilinear identity $Y_2 = Y_1 \times Y_3 / 100$. Evaluating the first-order approximation $\Delta Y_2 \approx \tau_1 S_0 + T_0 \tau_3$ at the sample means ($T_0 \approx 16.5\%$ of GDP and $S_0 \approx 34.4\%$) yields $0.22 \times 0.344 + 0.165 \times 0.47 = 0.076 + 0.078 = +0.153\text{ pp}$, demonstrating that roughly half of the $+0.15\text{ pp}$ gain in direct income tax revenue as a share of GDP comes from expanding overall tax capacity and half comes from shifting the tax mix toward direct income taxation.

2. **Intensive-margin study duration and cohort gestation at $+5\text{ years}$ vs steady-state career horizons at $+10\text{ years}$:**  
   We have expanded Section 5.3 (`paper/paper.tex` and `paper/paper.md`) to clarify that even holding follow-up enrolment headcount fixed, higher per-student funding supports higher student retention, full-time study persistence, and degree completion before graduates reach their higher-earning late twenties. In Section 6.1 and Section 6.2 (`paper/paper.tex` and `paper/paper.md`), we also explicitly show how our 10-year fiscal return reflects just the first two five-year graduate cohorts entering the workforce, whereas across a 40-year (eight-wave) working career eight educated cohorts are active simultaneously per cohort currently in university.

3. **Clarifying the $+15\text{ pp}$ ($1.5$ unit) winsorisation cap in Appendix B Table 6 (`tab:z0_countries`):**  
   We have added an explicit explanatory note to the caption of Table 6 (`tab:z0_countries`) explaining that for the few developing economies sitting more than $15\text{ pp}$ below their income-group median (such as Rwanda, Guatemala, Cambodia, El Salvador, the Philippines, Peru, and Gabon), closing the entire raw distance to the median in a single step exceeds the $+15\text{ pp}$ ($1.5$ unit) winsorisation cap of the model, so the final two columns report the well-identified return to a standard $+10\text{ pp}$ ($+1.0$ unit) policy expansion alongside the cost of that $+10\text{ pp}$ step.

---

## Response to Reviewer 3 (Macro-Development & Fiscal Capacity Mechanisms Referee)

1. **Explaining why full-sample ($N = 283$) and training-only (`R13`, $N = 229$) estimates differ slightly in Section 3.1:**  
   We thank the referee for pointing out that readers benefit from a clear explanation of how the 5-fold country-blocked cross-fitting setup relates to the locked Fold 5 holdout test. In Section 3.1 (`paper/paper.tex` and `paper/paper.md`), we state explicitly that Sections 5.1 to 5.3 report 5-fold country-blocked cross-fitted estimates across the full sample ($N = 283$ at $+10\text{ years}$) to maximise statistical precision, whereas the locked 80% training-only fit (`R13`, Folds 1 to 4, $N = 229$, reported in Appendix B Table 5) excludes the 22 Fold 5 holdout countries entirely when generating the out-of-sample predictions in Section 5.4 and yields even stronger $+10$-year slopes ($+0.42\text{ pp}$ on total tax/GDP $Y_1$, $P = 0.99$, and $+0.22\text{ pp}$ on direct income tax/GDP $Y_2$, $P = 0.98$).

2. **Reporting horizon-specific sample sizes ($N = 371$ at $+5\text{y}$ and $N = 283$ at $+10\text{y}$) in Figure 6:**  
   We have updated Section 5.3 and the caption of Figure 6 (`fig5_longitudinal_country_trajectories.pdf`) to state both horizon sample sizes ($N = 371$ across 121 countries at $+5\text{ years}$ and $N = 283$ across 112 countries at $+10\text{ years}$) and to note that our balanced two-wave sub-panel sensitivity check (`R2`, $N = 283$ at both horizons) in Appendix B Table 5 confirms that the trajectory from $+5\text{ years}$ to $+10\text{ years}$ is not an artefact of wave attrition.

---

## Response to Reviewer 4 (Independent External Referee)

1. **Listing the five exact raw anomalies screened out in Section 3.1:**  
   We agree that naming the exact five country-wave observations screened out by our automated bounds check in `src/r/02_build_clean_tax_panel.R` strengthens transparency. In Section 3.1 (`paper/paper.tex` and `paper/paper.md`), we name all five observations explicitly: Sudan in `1995-1999`, Timor-Leste in `2010-2014`, the United Arab Emirates in `2010-2014` and `2015-2019`, and Madagascar in `2015-2019`.

2. **Reconciling the raw vs winsorised Low-Income group median ($183.8\%$ vs $150.0\%$) across Section 3.3 and Appendix B Table 6:**  
   We thank the referee for spotting this subtle distinction between the unwinsorised Low-Income training median ($183.8\%$) and the winsorised Scaling A reference median ($150.0\%$, because raw values are winsorised at $[5\%, 150\%]$ before centring). We updated `src/r/03_eda_and_summary_tables.R` so that `tableA4_latest_z0_countries_costs_and_returns.csv` computes `med_spend_raw` from the winsorised series (`tert_spend_per_student_winsor`), aligning the Low-Income median in Appendix B Table 6 (`tab:z0_countries`) to $150.0\%$, and we explain both numbers explicitly in Section 3.3 (`paper/paper.tex` and `paper/paper.md`).

3. **Synchronising `paper/paper.md` with `paper/paper.tex` and sorting multi-reference citations chronologically:**  
   We have updated `paper/paper.md` across all sections and appendices so that every number, table, figure path, and CSV reference matches `paper/paper.tex` and `outputs/tables/*.csv` identically, and we have sorted all multi-reference parenthetical citations in both files in strict chronological order.

---

## Response to Reviewer 5 (Code, Data Hygiene & Leakage Auditor)

1. **Automated test coverage for `paper/paper.md` in `tests/test_pipeline.R`:**  
   We have updated `tests/test_pipeline.R` (Step 5) so that it automatically checks both `paper/paper.tex` and `paper/paper.md` against `outputs/tables/table1_mvbcf_ate_posteriors.csv` and `outputs/tables/table4_robustness_checks.csv` (`R13_TrainingSet_Only_10y` and `R15_Same_X_and_W_10y`), and verifies that every `outputs/tables/*.csv` path referenced in `paper/paper.md` exists on disk.

2. **Replacing hardcoded `/tmp/rcpp_cache_edu_tax_bcf` with `file.path(tempdir(), ...)` and cleaning up legacy scripts:**  
   In `src/r/04_run_mvbcf_tax_models.R`, we replaced `"/tmp/rcpp_cache_edu_tax_bcf"` with `file.path(tempdir(), "rcpp_cache_edu_tax_bcf")` for cross-platform safety on shared multi-user systems, and we deleted the three unused legacy files from the earlier exploratory binary phase along with the duplicate `results/` directory.

---

## Response to Reviewer 6 (Reproducibility & Open-Science Referee)

1. **Updating `environment.yml`, `README.md`, `CITATION.cff`, and `data/raw/PROVENANCE.md`:**  
   We added `r-ggrepel>=0.9`, `r-patchwork>=1.2`, and `r-ranger>=1.16` to `environment.yml`, added `library(ggrepel)` explicitly at the top of `src/r/06_generate_figures_and_diagnostics.R`, and updated `README.md`, `CITATION.cff`, `run_all.sh`, and `data/raw/PROVENANCE.md` so that all documentation reflects the continuous-treatment MV-BCF pipeline and current file structure.

2. **Separating `fig0_panel_data_overview.{pdf,png}` from `eda_fig1_raw_distributions_and_bivariate.{pdf,png}`:**  
   Step 06 (`06_generate_figures_and_diagnostics.R`) saves the Section 3 4-panel data overview figure to its own dedicated filename (`outputs/figures/fig0_panel_data_overview.{pdf,png}` and `paper/figures/fig0_panel_data_overview.{pdf,png}`), preserving the 2-panel training-set EDA diagnostic figure at `outputs/figures/eda_fig1_raw_distributions_and_bivariate.{pdf,png}` and `eda/figures/eda_fig1_raw_distributions_and_bivariate.{pdf,png}`.

---

## Response to Reviewer 7 (Citation & Bibliography Verification Referee)

1. **Chronological ordering of multi-reference `\citep{...}` commands:**  
   We sorted all multi-reference `\citep{...}` commands in `paper/paper.tex` (and their parenthetical counterparts in `paper/paper.md`) in strict chronological order from oldest to newest.

2. **Bibliography metadata refinements (`mcjames2024mvbcf`, `ting2025estimating`, `chakrabarti2020state`, and `literature/literature.csv`):**  
   We added `pages = {428--450}` to `mcjames2024mvbcf` and updated `ting2025estimating` to `author = {Ting, Angela and Linero, Antonio R.}` in `paper/references.bib`, refined our prose description of `chakrabarti2020state` in Section 2.2 to match the published NBER analysis, removed the duplicate `data/references.bib`, and synchronised `literature/literature.csv` with all 36 references cited in `paper/references.bib`.

---

## Response to Reviewer 8 (Author Pre-Submission Review: 21 Action Items)

1. **Short, clear sentences containing one fact:**  
   We have rewritten the prose across the Abstract, Sections 1 to 6, and Appendices A to E in both `paper/paper.tex` and `paper/paper.md` so that sentences are short, clear, and convey one main fact at a time.

2. **Paragraph length (minimum 3 sentences, maximum 1/3 page, 4 to 6 short sentences ideal):**  
   We have audited and restructured every paragraph across `paper/paper.tex` and `paper/paper.md`. Every prose paragraph now contains 3 to 7 short sentences (typically 4 to 6 sentences) and occupies well under one-third of a page.

3. **Non-linearity and diminishing returns of university spending:**  
   We now address this directly in the Abstract, Section 1 (Paragraph 3), Section 3.3, Section 5.3, Section 6.2 (Point 5), and Appendix D. Specifically, we explain how our causal framework captures non-linearity and diminishing returns in three complementary ways: (a) we evaluate local changes within a central $\pm 15\text{ pp}$ ($\pm 1.5$ unit) policy window around each income group's median and condition the baseline forest $\mu(\cdot)$ on each country's predicted funding level $\hat{z}(X_{i,t}) = \mathbb{E}[Z_{i,t} \mid X_{i,t}]$, (b) the treatment-effect trees $\tau(W_{i,t})$ split on university enrolment and national income, showing that aggregate tax-to-GDP gains taper off as university systems mature (from $+0.48\text{ pp}$ in low-income and $+0.32\text{ pp}$ in lower-middle-income economies to $+0.19\text{ pp}$ in high-income economies), and (c) our logarithmic funding specifications ($Z_3$ in Section 5.2 and Scaling B in Appendix D) build concave diminishing marginal returns directly into the dollar and ratio transformations.

4. **Remove the term "dose" from the paper and figures:**  
   We have removed all occurrences of "dose", "doses", and "dose-response" from `paper/paper.tex`, `paper/paper.md`, and all figure scripts and labels (`src/r/06_generate_figures_and_diagnostics.R`), replacing them with natural policy terms ("university funding", "spending level", "funding measure $Z$", "per $+10\text{ pp}$ increase").

5. **Simplify Figure 1 (`fig1_structural_schematic.pdf`) headings and items:**  
   We redesigned Figure 1 in `src/r/06_generate_figures_and_diagnostics.R` and regenerated `outputs/figures/fig1_structural_schematic.{pdf,png}` and `paper/figures/fig1_structural_schematic.{pdf,png}`. Box 1 is now titled **"1. Four Ways of Measuring University Funding (Z1 to Z4)"** with sub-note *"(Tested in turn in separate models)"*, Box 2A is titled **"2A. Starting Country Conditions (X)"**, Box 2B is titled **"2B. Follow-Up Economic Growth (X)"**, and Box 3 is titled **"3. Four Tax Revenue Outcomes (Y1 to Y4)"** with sub-note *"(Modelled jointly in every run)"*.

6. **Fix paragraph transition around Figure 1 in Section 1:**  
   We moved *"Figure 1 summarises our study design for addressing these challenges across 121 countries from 1985 to 2024."* to the start of Paragraph 4 of Section 1 and merged it smoothly with the explanation of Boxes 1, 2, and 3.

7. **Remove unexplained jargon `"Expected Dose E[Z | X] (RF)"` from Figure 1:**  
   We replaced `"Expected Dose E[Z | X] (RF)"` in Box 2A of Figure 1 with the plain-English label **"Predicted Funding from History"**, and we explain $Z$, $\hat{z}(X_{i,t}) = \mathbb{E}[Z_{i,t} \mid X_{i,t}]$, and random forests clearly in the text when introduced.

8. **Label the four tax outcomes $Y_1, \dots, Y_4$, the four funding measures $Z_1, \dots, Z_4$, and covariates $X$:**  
   Throughout `paper/paper.tex`, `paper/paper.md`, and Figures 1, 3, 4, 5, 6, 7, A1, and A2, we now explicitly label the four jointly modelled tax outcomes $Y_1, Y_2, Y_3, Y_4$, the four funding measures tested in turn $Z_1, Z_2, Z_3, Z_4$, and the baseline and mediating controls $X$.

9. **Expand the "first global study" paragraph in Section 1 and separate the paper outline:**  
   We expanded the paragraph beginning *"We believe this is the first global study to use modern causal inference techniques to test whether public university funding increases future national tax revenue."* into a dedicated 5-sentence comparison against single-country microeconomic lifecycle studies (Trostel, 2010; Chakrabarti et al., 2020; Hendren and Sprung-Keyser, 2020) and linear macro-panel regressions (Besley and Persson, 2014; Valero and Van Reenen, 2019; Jensen, 2022), followed by a separate paragraph giving the section-by-section outline of the paper.

10. **New paragraph for `"Readers will note that the Multivariate Bayesian Causal Forest..."` in Section 2.3:**  
    We broke this disclosure out as its own 4-sentence paragraph at the end of Section 2.3.

11. **Clarify prognostic tree depth in Section 4:**  
    In Section 4 (`paper/paper.tex` line 186 and `paper/paper.md` line 108), we replaced *"an ensemble of 75 shallow decision trees (many having only one or two splits)"* with *"an ensemble of 75 decision trees"*, stating explicitly that whether these trees are shallow or deep is not fixed in advance, but is learned directly from the data during MCMC sampling.

12. **Introduce the binary propensity score before contrasting it with continuous $Z$ in Section 4:**  
    In Section 4 (`paper/paper.tex` line 188 and `paper/paper.md` line 110), we added the introductory sentence: *"In standard Bayesian Causal Forests (Hahn et al., 2020), the treatment variable $Z$ is binary and a propensity score $P(Z = 1 \mid X)$ is included inside $\mu(\cdot)$ to control for selection bias. However, in our approach the university funding variable $Z_{i,t} \in [0, 3.0]$ is continuous rather than binary, so a binary propensity score no longer applies."*

13. **Explain regularisation priors on $\tau(\cdot)$ trees in Section 4:**  
    In Section 4 (`paper/paper.tex` line 190 and `paper/paper.md` line 112), we replaced *"smaller ensemble of 30 shallower trees"` with an explanation that we use 30 decision trees whose structures and depths are chosen by the data during MCMC sampling, and that following Hahn et al. (2020) we place stronger regularisation priors on the $\tau$ tree shapes than on the $\mu$ tree shapes, with full hyperparameter details in Appendix A.

14. **Explain and test separating $X$ (in $\mu$) and $W$ (in $\tau$) via Sensitivity Check `R15` ($W = X$):**  
    We added a dedicated paragraph in Section 4 (`paper/paper.tex` line 192 and `paper/paper.md` line 114) explaining why separating the 19 baseline covariates $X$ in $\mu(\cdot)$ from the 8 structural moderators $W \subset X$ in $\tau(\cdot)$ prevents the 30 treatment trees from splitting on noisy short-term nuisance variables in a moderate sample ($N = 283$ to $371$), while acknowledging that one could reasonably argue for using the exact same covariates in both forests ($W = X$). We also implemented and ran Sensitivity Check `R15_Same_X_and_W_10y` in `src/r/04_run_mvbcf_tax_models.R` (`outputs/tables/table4_robustness_checks.csv` and Row 17 of Appendix Table 5), confirming that setting $W = X$ yields virtually identical $+10$-year slopes ($+0.33\text{ pp}$ on $Y_1$, $P = 0.97$; $+0.12\text{ pp}$ on $Y_2$, $P = 0.85$; and $+0.51\text{ pp}$ on $Y_3$, $P = 0.91$).

15. **Drop Table 2 from Section 5.1 and clean up Figure 3 (`fig2_total_vs_direct_tax_posteriors.pdf`):**  
    We removed Table 2 from Section 5.1, kept Figure 3 (`fig:posteriors`), removed the grey subtitle and bottom caption clutter from Figure 3, and placed the explanation of the 80% and 95% credible intervals and $P = P(\tau > 0 \mid \text{data})$ cleanly inside Figure 3's caption.

16. **New paragraph and cost-vs-return timing explanation for `"To put these continuous slopes..."` in Section 5.1:**  
    We broke `"To put these continuous slopes..."` into its own 5-sentence paragraph in Section 5.1 (`paper/paper.tex` line 213 and `paper/paper.md` line 126), explaining that because the data are averaged into five-year waves, a $+10\text{ pp}$ increase in $Z_1$ represents an annual spending commitment sustained over the five-year wave while a student cohort is at university, explaining why comparing one year of tuition costs for the whole student body against one year of tax receipts at Year 10 can make the annual cost look larger than the Year-10 return in high-enrolment countries, and adding an explicit forward reference to Sections 6.1 and 6.2 and Appendix Table 6 (`tab:z0_countries`).

17. **Drop Table 3 from Section 5.2 and clean up Figure 4 (`fig3_denominator_unbundling_horserace.pdf`):**  
    We removed Table 3 from Section 5.2, kept Figure 4 (`fig:horserace`), removed the grey subtitle and bottom caption text from Figure 4, and moved those details into Figure 4's caption.

18. **Streamline Section 5.4 to two short paragraphs and one out-of-sample figure (`fig6_scaling_fit_and_holdout_validation.pdf`):**  
    We condensed Section 5.4 (`sec:holdout`) into two short paragraphs covering MCMC convergence and 5-fold country-blocked out-of-sample validation, updated `fig6_scaling_fit_and_holdout_validation.pdf` (Figure 7) to a clean single-row 3-panel out-of-sample cross-validation figure across $Y_1, Y_2, Y_3$, and moved the standardised residual plot and Fold 5 holdout scatter plot to Appendix D (`figA2_scaling_a_vs_b_comparison.pdf`).

19. **Show the $+5$-year negative point estimates (243 out of 371 country-waves, 65.5%) visually in Figure 6 (`fig5_longitudinal_country_trajectories.pdf`):**  
    We updated `fig5_longitudinal_country_trajectories.pdf` (Figure 6) to plot the individual country-wave posterior point estimates at $+5\text{ years}$ ($N = 371$) and $+10\text{ years}$ ($N = 283$) alongside the income-group trajectory lines and credible fan, with an explicit callout in Panel A showing that 243 of 371 country-waves (65.5%) are negative at $+5\text{ years}$ due to student lock-in, and referenced Panel A of Figure 6 directly in Section 5.3.

20. **Clarify Point 5 in Section 6.2 and include Ireland explicitly:**  
    We rewrote Point 5 in Section 6.2 (`paper/paper.tex` line 286 and `paper/paper.md` line 154) and included Ireland explicitly in both Section 6.2 and Appendix Table 6 (`tab:z0_countries`). We explain in clear, short sentences why in high-enrolment countries like Ireland (where closing the $9.1\text{ pp}$ gap to the high-income median costs EUR $2.16\text{ billion}$ per year and a full $+10\text{ pp}$ increase costs EUR $2.37\text{ billion}$ per year, vs a Year-10 annual return of EUR $0.33\text{--}0.55\text{ billion}$ in direct income tax $Y_2$ and EUR $1.05\text{ billion}$ in total tax $Y_1$) or New Zealand, the single-year tuition cost exceeds the single-year Year-10 return: each five-year cohort only requires university funding for one five-year period while studying, but then pays higher taxes across a 40-year (eight-wave) working career (accumulating to EUR $1.4\text{--}4.2\text{ billion}$ across an eight-cohort steady state in Ireland, while in developing countries with smaller cohorts such as Indonesia or Rwanda even the single-year return at Year 10 already exceeds the annual funding cost).

21. **Add Dedication to Robert Christopher Parnell in Declarations and Statements:**  
    We added a **Dedication** subsection at the top of **Declarations and Statements** (`paper/paper.tex` lines 291-292 and `paper/paper.md` line 162) reading: *"This paper is dedicated to the memory of Robert Christopher Parnell."*
