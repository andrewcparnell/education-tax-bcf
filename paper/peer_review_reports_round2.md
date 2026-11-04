# Second-Round Peer Review Reports & Author Response Log

**Manuscript Title:** *Does Public University Funding Pay for Itself? Isolating the Short- and Long-Run Tax Dividend Using Multivariate and Longitudinal Bayesian Causal Forests*  
**Date of Second-Round Review:** 4 November 2026  

---

## Executive Summary of Round-2 Decisions

Following the major revision (expanding the bibliography to 43 peer-reviewed references, adding Section 2 *Literature Review and Conceptual Framework*, removing the Table of Contents, consolidating the Abstract into a single paragraph, removing all repository paths and internal code identifiers, fixing the within-income-group treatment threshold to use raw un-winsorised observations, restricting the propensity score $\hat{\pi}(X_{i,t})$ strictly to pre-treatment variables, adding Worldwide Governance Indicators, and adding a pre-treatment placebo trend check), all three independent reviewers re-audited the manuscript and codebase:

| Reviewer | Role | Round-1 Decision | Round-2 Decision | Final Status After Minor Polish |
| :--- | :--- | :--- | :--- | :--- |
| **Reviewer 1** | Statistical & BCF Methodology | Major Revisions | **Accept with Minor Revisions** | All minor points resolved |
| **Reviewer 2** | Fiscal & Higher Education Economics | Major Revisions | **Accept with Minor Revisions** | All minor points resolved |
| **Reviewer 3** | Data & Reproducibility Auditor | Major Revisions | **Accept with Minor Revisions** | 100% table/CSV sync verified |

---

## 1. Reviewer 1 (Statistical & BCF Methodology)

### Summary Assessment
> **Recommendation: Accept with Minor Revisions**  
> The revised manuscript and statistical pipeline represent a substantial upgrade in methodological rigour. Every major statistical concern raised in the first round has been resolved both in the text and in the underlying R/C++ code (`02_run_mvbcf_tax_models.R`, `03_run_longitudinal_bcf_tax.R`, and `04_generate_figures_and_diagnostics.R`):
> 1. **Propensity Score Conditioning:** The propensity score $\hat{\pi}(X_{i,t})$ is now strictly estimated using pre-treatment baseline characteristics $X_{i,t}$, completely removing post-treatment mediators $M_{i,t+\Delta}$ from the treatment assignment model and avoiding collider conditioning.
> 2. **Expanded Literature on BART/BCF:** Section 2.3 and Section 4 integrate 10 core methodological citations (`Chipman2010`, `Hill2011`, `Linero2018`, `Hahn2020`, `Hill2020`, `Starling2020`, `Murray2021`, `Woody2021`, `Krantsevich2023`, `McJames2024`), clearly explaining regularisation-induced confounding (RIC) and shrinkage priors.
> 3. **Formal Mathematical Specification in Appendix A:** Appendix A now provides exact equations for both the $D=4$ Multivariate BCF (MVBCF) with an Inverse-Wishart residual covariance prior $\Sigma \sim \mathcal{IW}(\nu_0, \Lambda_0)$ and the 3-wave Longitudinal BCF (`lbcf_3wave`), matching the C++ Gibbs sampler line-for-line.
> 4. **Sequential G-Estimation & Controlled Direct Effects:** Section 4.1 explicitly frames the mediator-adjusted specification via sequential unconfoundedness (`Imai2010`, `Acharya2016`, `VanderWeele2016`) and reports an observational sensitivity bound (`R4`).

### Minor Revision Items & Resolution
1. **Synchronise Table 5 (`@tbl-lbcf`) with Updated `table5_longitudinal_bcf_trajectories.csv`:**
   - *Resolution:* Updated Table 5, the Abstract, and Section 5.4 so that all numbers match `results/tables/table5_longitudinal_bcf_trajectories.csv` (`+0.47` pp cumulative on Non-Resource Tax/GDP with $P = 0.90$ and `95.9%` compounding; `+0.31` pp on Direct Income Tax/GDP with $P = 0.95$ and `85.3%` compounding; `+1.27` pp on Direct Income Tax Share with $P = 0.95$ and `82.8%` compounding).
2. **Fix LaTeX `\underbrace` Grouping in Equation (Section 4.1):**
   - *Resolution:* Wrapped the prognostic forest term in explicit braces `{\mu(X_{i,t}, M_{i,t+\Delta}, \hat{\pi}(X_{i,t}))}` so the underbrace spans the entire function cleanly in both PDF and HTML outputs.

---

## 2. Reviewer 2 (Fiscal & Higher Education Economics)

### Summary Assessment
> **Recommendation: Accept with Minor Revisions**  
> The revised paper reads like a mature field-journal submission in public economics and the economics of education. All major substantive and literature concerns from Round 1 have been addressed:
> 1. **Comprehensive 43-Paper Literature Review (Section 2):** The new Section 2 weaves 43 peer-reviewed references across three coherent strands: (i) fiscal capacity, informational enforcement, and formal employment (`Kleven2016`, `Pomeranz2019`, `Weigel2020`, `Jensen2022`, `Okunogbe2022`, `Bachas2024`); (ii) returns to higher education, human capital externalities, and Marginal Value of Public Funds (`Moretti2004`, `Bound2010`, `Trostel2010`, `Carneiro2011`, `Zimmerman2014`, `DemingWalters2017`, `Valero2019`, `Hendren2020`, `Chetty2020`, `Chakrabarti2020`, `Angrist2021`, `Deming2022`, `Mountjoy2022`); and (iii) causal mediation and Bayesian causal forests.
> 2. **Balanced Within-Income-Group Treatment Threshold:** Fixing the winsorisation-cap bug in `02_build_clean_tax_panel.py` restored an exact 50/50 split within every World Bank income group (Low `50.0%`, Lower-Middle `50.0%`, Upper-Middle `50.0%`, High `49.8%`), eliminating the previous mechanical exclusion of Low and Upper-Middle income countries.
> 3. **Institutional Capacity Controls & Placebo Pre-Trend Test:** Incorporating Worldwide Governance Indicators (`wgi_gov_effectiveness` and `wgi_rule_of_law`) and the 5-year pre-treatment placebo test (`R5`, showing `+0.03` pp, $P(\bar{\tau}>0) = 0.56$) directly addresses fiscal capacity confounding and parallel pre-trends.

### Minor Revision Items & Resolution
1. **Sync Table 5 with Re-Estimated Longitudinal BCF CSV:**
   - *Resolution:* Completed in Section 5.4, Table 5, and the Abstract.
2. **Add a One-Sentence Back-of-the-Envelope Fiscal Cost-vs-Return Comparison in Section 6.1:**
   - *Resolution:* Added an explicit quantitative comparison in Section 6.1 noting that shifting from the low to the high per-student funding regime costs approximately `0.35` to `0.50` percentage points of GDP in public tertiary expenditure while generating a `+0.39` pp direct-tax-plus-aggregate revenue dividend at year 10 (and `+0.47` pp under sustained 10-year investment), meaning the direct fiscal externality alone recoups the vast majority of the upfront budgetary outlay (`Trostel2010`, `Hendren2020`).

---

## 3. Reviewer 3 (Data & Reproducibility Auditor)

### Summary Assessment
> **Recommendation: Accept with Minor Revisions**  
> All four formatting and structural flaws flagged by the Editor have been verified as resolved:
> 1. **Table of Contents Removed:** Confirmed `toc: false` in YAML; the rendered PDF starts immediately with the Title, Abstract, and Section 1 on Page 1.
> 2. **Single-Paragraph Abstract:** Confirmed the Abstract is a single cohesive 225-word paragraph.
> 3. **Zero Internal Paths or Code Variable Names:** Verified zero occurrences of `github`, `src/`, `results/`, `.py`, `.R`, `.csv`, `Z_regime_inc`, or `cur_sp` anywhere in the manuscript prose or tables.
> 4. **Bibliography Integrity:** Verified 43 entries in `paper/references.bib`, with all 43 cited in `paper/education_tax_bcf_paper.qmd` and zero uncited or broken keys.
> 5. **Style & Language Audit:** Confirmed strict British English throughout (*analyse*, *enrolment*, *labour*, *modelled*, *winsorised*, *harmonised*, *programme*), zero em dashes (`—`), zero en dashes (`–`) in prose, and zero uses of *utilise* or its variants.

### Minor Revision Items & Resolution
1. **Synchronise Table 5 (`@tbl-lbcf`) with `results/tables/table5_longitudinal_bcf_trajectories.csv`:**
   - *Resolution:* Verified 100% numerical match across all 8 tables (`@tbl-summary`, `@tbl-ate-5y`, `@tbl-ate-10y`, `@tbl-mediation`, `@tbl-lbcf`, `@tbl-gates`, `@tbl-robust`, `@tbl-diagnostics`) against `results/tables/*.csv`.
2. **Note Outcome 4 Diagnostics in Table 8 Caption:**
   - *Resolution:* Added an explicit sentence in the caption of Table 8 (`@tbl-diagnostics`) reporting the Outcome 4 (Goods & Services Tax / GDP) diagnostics (`1.012` at $+5$ years and `1.009` at $+10$ years, ESS `950` and `965`).
