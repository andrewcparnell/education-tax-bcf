# Phase 6 Methodology Expert Review: Continuous-Treatment Redesign

**Manuscript Title:** *Does Increasing Government Spending on Tertiary Education Improve the Future Tax Take? A Bayesian Causal Inference Analysis*  
**Author:** Andrew C. Parnell  
**Overall Verdict:** **Accept (with minor non-blocking synchronisation notes between `paper.md` and `paper.tex`)**

---

### 1. Executive Summary and Overall Impression

The continuous-treatment redesign of the manuscript (`paper/paper.tex` and `paper/paper.md`) and codebase (`src/r/02_build_clean_tax_panel.R`, `src/r/04_run_mvbcf_tax_models.R`, `src/r/06_generate_figures_and_diagnostics.R`, and `src/cpp/mvbcf_source_code.cpp`) is a substantial methodological upgrade. Moving from a binary median-cutoff indicator to a continuous university funding dose $Z_{i,t} \in [0, 3.0]$ resolves the cliff-edge threshold artefact for near-median countries (such as New Zealand and Iceland at $26.1\%$ vs the $26.4\%$ high-income median in Table 8), preserves within-group variation in funding intensity, and aligns the empirical estimator with how finance ministries actually budget in percentage-point and purchasing-power increments.

I have audited the C++ sampler (`src/cpp/mvbcf_source_code.cpp`), the R data-construction and modelling pipeline (`02_build_clean_tax_panel.R` and `04_run_mvbcf_tax_models.R`), all CSV output tables (`outputs/tables/`), all nine figures (`outputs/figures/`), and both manuscript files (`paper/paper.tex` and `paper/paper.md`). Below I evaluate each of the four requested methodology checkpoints, confirm that there are **zero major concerns**, and list a small set of minor, easily fixed synchronisation items between `paper/paper.md` and `paper/paper.tex`.

---

### 2. Evaluation of Core Methodological Checkpoints

#### 2.1 Continuous-Treatment MV-BCF Identification, Conjugate Leaf Precision Updates, and Random Forest $\hat{z}(X_{i,t})$ Conditioning
* **Mathematical & C++ Sampler Verification:** In `src/cpp/mvbcf_source_code.cpp` (lines 515 - 576) and `src/r/mvbcf_helpers.R` (line 103), the treatment vector $Z \in \mathbb{R}^N$ is replicated across the $D = 4$ outcome columns (`Z_mat`) and enters the treatment-effect trees linearly as $Z_{i,t} \tau_{l,b}$. Inside each terminal leaf $b$ of treatment tree $l$, the C++ code computes `(node_z.t() * node_z) % arma::inv(sigma) + arma::inv(sigma_tau)`, which is the exact mathematical identity for the continuous-treatment conjugate precision update $\Omega_{\tau,b}^{-1} = \Sigma_\tau^{-1} + \bigl(\sum_{i \in b} Z_{i,t}^2\bigr)\Sigma^{-1}$, and computes the posterior mean via $\Omega_{\tau,b} \Sigma^{-1} \sum_{i \in b} Z_{i,t} R_i^{(l)}$. Both the collapsed Gaussian marginal likelihood (`get_likelihood_tau`, lines 557 - 566) and the reversible-jump Metropolis-Hastings tree transition ratio $r_{\text{grow}} = \frac{p_{\text{prune}} b(T)}{p_{\text{grow}} w(T^*)} \cdots$ (lines 808 - 817 and 888 - 897; Appendix A Equations 3 and 4 in `paper.tex`) are exact.
* **Non-Negative Anchoring of $Z_{i,t} \in [0, 3.0]$:** Shifting the winsorised deviation $Z_{\text{raw}} \in [-1.5, +1.5]$ by $+1.5$ so that $Z_{i,t} \in [0, 3.0]$ (with $1.5$ representing the training income-group median and $\text{SD}(Z_{i,t}) = 1.05$) is well motivated for BCF: it prevents sign-flipping invariance at $Z = 0$ from creating artificial heteroscedastic pinch points at the group median while keeping the partial derivative $\tau(W_{i,t}) = \partial \mathbb{E}[\Delta Y_{i,t+h} \mid X_{i,t}, Z_{i,t}] / \partial Z_{i,t}$ invariant to the additive $+1.5$ shift because the prognostic forest $\mu(X_{i,t}, \hat{z}_{i,t})$ absorbs the level intercept $-1.5 \tau(W_{i,t})$.
* **Country-Blocked Random Forest Expected Treatment $\hat{z}(X_{i,t}) = \mathbb{E}[Z_{i,t} \mid X_{i,t}]$:** In `src/r/04_run_mvbcf_tax_models.R` (`estimate_rf_z_hat`, lines 161 - 191), $\hat{z}(X_{i,t})$ is estimated using a 500-tree `ranger` random forest cross-fitted strictly across the five country-blocked folds (`country_fold`) using out-of-fold median-imputed pre-treatment covariates (`prep_matrix_oof`). Including $\hat{z}(X_{i,t})$ inside $\mu(\cdot)$ is the natural continuous-treatment generalisation of Hahn et al. (2020) and Robinson (1988). As shown in Appendix C Table 9 (`tab:balance` / `tableA3_propensity_overlap_and_balance.csv`), residualising $Z_{i,t}$ on $\hat{z}(X_{i,t})$ reduces the mean absolute correlation with the 19 pre-treatment confounders by more than 60% (from `0.155` to `0.061` under Scaling A, and from `0.143` to `0.056` under Scaling B), while row-wise OOB random forest predictions (`R8` in Table 7) yield virtually identical posterior slopes (`+0.31` pp on Total Tax/GDP, `+0.13` pp on Direct Income Tax/GDP, and `+0.62` pp on Direct Income Tax Share).

#### 2.2 Five-Fold Country-Blocked Splitting Protocol, Leakage Hygiene, and Out-of-Sample Holdout Validation
* **Zero Country or Test-Set Leakage:** In `src/r/02_build_clean_tax_panel.R` (lines 241 - 285), the 217 sovereign territories are partitioned deterministically (`set.seed(20261103)`) into five country-blocked folds stratified by World Bank income group and data availability before any centring statistics are computed. Every wave of a given country `iso3` sits in the same fold (`max_folds_per_country = 1` in `leakage_audit.csv`), and the income-group centring medians (`med_spend_winsor`, `med_log_spend_winsor`, `med_real_spend`, `med_tert_gdp`) are computed strictly on Folds 1 to 4 (`is_holdout_test == 0L`).
* **Out-of-Sample Validation & Uncertainty Quantification:** In `src/r/04_run_mvbcf_tax_models.R` (`evaluate_country_split`, lines 515 - 768), all covariate imputation medians and the random forest model for $\hat{z}(X_{i,t})$ are fitted strictly on the training countries (`d_tr`) and projected onto the held-out countries (`d_te`). Predictive standard deviations combine posterior epistemic variance across MCMC draws with the posterior mean residual variance in quadrature (`sd_A <- sqrt(apply(pred_A_mat, 1, var) + mean(sig_A^2))`), which produces well-calibrated out-of-sample predictive intervals: across the 22 unseen countries in Fold 5 ($N = 54$ waves at $+10$ years), empirical 80% coverage is `75.9% - 85.2%` and empirical 95% coverage is `88.9% - 96.3%`. Moreover, the Diebold-Mariano loss-differential $p$-values (`summarise_holdout_perf`, lines 755 - 764) are properly clustered at the country level (`cl_means <- tapply(d_loss, iso3, mean)`), accounting for within-country correlation across waves.
* **Alignment of Claims with Posterior Uncertainty:** The manuscript is careful and transparent in how it reports posterior uncertainty: where 80% credible intervals exclude zero and $P = P(\tau > 0 \mid \text{data}) \in [0.89, 0.96]$ while 95% credible intervals slightly straddle zero, the text reports both the 80% and 95% CIs explicitly alongside $P$, and highlights where 95% CIs strictly exclude zero.

#### 2.3 Head-to-Head Comparison of Scaling A (+10 pp Ratio Dose) vs Scaling B (+25% Relative Log Dose)
* **Verification in Section 5.4 and Appendix D (`tab:scaling_ab` and `figA2_scaling_a_vs_b_comparison.pdf`):** The head-to-head comparison in Appendix D is thorough and balanced, showing that both scalings exhibit flat, zero-centred LOESS residual curves across $Z \in [0, 3.0]$ with $93.3\%$ to $95.8\%$ of standardised residuals within $\pm 2\text{ SD}$.

---

### 3. Major Concerns

**None.** All statistical, mathematical, causal identification, and holdout validation components are sound and verified in the code and outputs.

---

### 4. Minor Concerns (Synchronisation and Polish Only)

1. **Synchronising Remaining Numbers in `paper/paper.md` with `paper/paper.tex` and the CSV Tables:**  
   Synchronise lines 98, 128-131, 137, 217, 223, and 231 in `paper/paper.md` so that all numbers and CSV file references in `paper/paper.md` match `paper/paper.tex` and `outputs/tables/`.
2. **Minor Clarification of Leaf Prior Scaling in Appendix A (`paper/paper.tex` line 373):**  
   Mention that $Z_{i,t}$ is already scaled to approximately unit variance ($\text{SD}(Z_{i,t}) \approx 1.05$) so that $\Sigma_\tau = \text{diag}(1/M_\tau)$ on the standardised outcome scale is well calibrated.
3. **Standalone Readability Audit of All Figures and Tables:**  
   All 9 figures (`outputs/figures/*.png` and `.pdf`) and all 14 tables in `paper/paper.tex` pass the standalone readability audit with clear axis labels, defined acronyms, and informative captions. In Figure 9 (`figA2_scaling_a_vs_b_comparison.png`), align the rounding of `0.1048` (`+0.10` vs `+0.11`) and `3.235` (`3.23` vs `3.24`) if desired.
