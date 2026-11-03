#!/usr/bin/env Rscript
# ==============================================================================
# Step 3.1: Multivariate Bayesian Causal Forest (mvbcf) Tax-Take Analysis
# (src/r/02_run_mvbcf_tax_models.R)
#
# Fits the core mvbcf models on the 4-component disaggregated fiscal vector:
#   Y1: Non-Resource Domestic Tax-to-GDP Change (pp of GDP)
#   Y2: Direct Income, Profit & Capital Gains Tax-to-GDP Change (pp of GDP)
#   Y3: Direct Income & Profit Share of Total Revenue Change (pp of revenue)
#   Y4: Indirect Goods & Services (Consumption/VAT) Share of Revenue Change (pp)
#
# Models estimated at both +5 years (t+1) and +10 years (t+2):
#   - Model M1 (Total Fiscal Effect): Pre-treatment baseline controls only
#   - Model M2 (Mediator-Removed Direct Fiscal Effect): Controlling for forward
#     GDP per person growth, enrolment expansion, Gini change & life expectancy
#   - Model M3 (Unbundled Exposure Horse-Race): Comparing UNESCO Ratio Regime,
#     Observed Ratio Expansion (no proxy), Real PPP $/Student, Public University
#     Budget % of GDP, and Total Education Budget % of GDP
#   - Model M4 (OECD Public vs Private Financing Deep-Dive)
#   - Model M5 (Robustness Suite): Pure WDI Tax/GDP (no resource adjustment),
#     Non-Overlapping 10-Year Windows, Within-Country Demeaned Fixed Effects,
#     and Prior Hyperparameter Sensitivity
# ==============================================================================

suppressPackageStartupMessages({
  library(Rcpp)
  library(RcppArmadillo)
  library(dplyr)
  library(tidyr)
  library(readr)
})

set.seed(20261103)

repo_root <- "/Users/andrewparnell/Documents/GitHub/education-tax-bcf"
proc_dir  <- file.path(repo_root, "data", "processed")
tab_dir   <- file.path(repo_root, "results", "tables")
mod_dir   <- file.path(repo_root, "results", "models")
dir.create(tab_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(mod_dir, recursive = TRUE, showWarnings = FALSE)

cat("Compiling mvbcf C++ sampler (with rescaled Gibbs covariance fix)...\n")
Sys.setenv(R_MAKEVARS_USER = file.path(repo_root, "src", "cpp", "Makevars"))
sourceCpp(file.path(repo_root, "src", "cpp", "mvbcf_source_code.cpp"),
          cacheDir = "/tmp/rcpp_cache_edu_tax_bcf", verbose = FALSE)
source(file.path(repo_root, "src", "r", "mvbcf_helpers.R"))
cat("mvbcf sampler compiled and loaded.\n\n")

# Load clean 5-year panel and non-overlapping 10-year panel
df <- read_csv(file.path(proc_dir, "clean_tax_panel.csv"), show_col_types = FALSE) %>%
  mutate(
    income_group_num = as.numeric(factor(income_group, levels = c(
      "Low income", "Lower middle income", "Upper middle income", "High income"
    ))),
    region_num = as.numeric(factor(region)),
    enrol_regime = case_when(
      gross_tert_enrolment_pct < 20 ~ "1. Elite (<20% enrolment)",
      gross_tert_enrolment_pct < 50 ~ "2. Massifying (20-50% enrolment)",
      TRUE                          ~ "3. High-Participation (>=50% enrolment)"
    )
  )

# Four core disaggregated fiscal outcomes (+5y and +10y)
y5_cols  <- c("d_t1_nonres_tax_gdp_pp", "d_t1_inc_tax_gdp_pp", "d_t1_inc_tax_share_pp", "d_t1_goods_tax_share_pp")
y10_cols <- c("d_t2_nonres_tax_gdp_pp", "d_t2_inc_tax_gdp_pp", "d_t2_inc_tax_share_pp", "d_t2_goods_tax_share_pp")

outcome_labels <- c(
  "Non-Resource Tax / GDP (pp)",
  "Direct Income & Profit Tax / GDP (pp)",
  "Direct Income & Profit Share of Revenue (pp)",
  "Goods & Services Tax Share of Revenue (pp)"
)
outcome_short <- c("tax_gdp_pp", "inc_tax_gdp_pp", "inc_tax_share_pp", "goods_tax_share_pp")
# For Y1, Y2, Y3 positive is direct fiscal expansion; for Y4 (indirect consumption tax reliance) we report P(tau > 0) and P(tau < 0)
beneficial_dir <- c(1, 1, 1, -1)

# Strictly pre-treatment baseline control variables (using lagged t-1 GDP growth)
base_con_vars <- c(
  "log_gdp_pc_ppp",
  "non_resource_tax_gdp_pct",
  "income_profit_tax_share_rev_pct",
  "goods_services_tax_share_rev_pct",
  "gini_disp_harmonised",
  "life_expectancy_birth_yrs",
  "gross_tert_enrolment_pct",
  "gross_seco_enrolment_pct",
  "edu_spend_total_gdp_pct",
  "working_age_pop_15_64_pct",
  "log_population",
  "unemployment_rate_pct",
  "natural_resource_rents_gdp_pct",
  "trade_openness_gdp_pct",
  "lag_gdp_pc_growth_pct",
  "income_group_num",
  "region_num",
  "is_oecd",
  "wave_index"
)

# Moderator variables in tau(X)
base_mod_vars <- c(
  "gross_tert_enrolment_pct",
  "log_gdp_pc_ppp",
  "gross_seco_enrolment_pct",
  "income_profit_tax_share_rev_pct",
  "working_age_pop_15_64_pct",
  "income_group_num",
  "is_oecd",
  "wave_index"
)

# Mediating macroeconomic variables over [t, t+h] for Direct Fiscal Effect models
mediators_5y  <- c("d_t1_log_gdp_pc_pct", "d_t1_tert_enrol_pp", "d_t1_gini_disp", "d_t1_life_exp_yrs")
mediators_10y <- c("d_t2_log_gdp_pc_pct", "d_t2_tert_enrol_pp", "d_t2_gini_disp", "d_t2_life_exp_yrs")

prep_matrix <- function(d, cols) {
  out_list <- list()
  for (col in cols) {
    v <- as.numeric(d[[col]])
    na_mask <- is.na(v)
    med <- median(v, na.rm = TRUE)
    if (is.na(med)) med <- 0.0
    out_list[[col]] <- ifelse(na_mask, med, v)
  }
  as.matrix(as.data.frame(out_list))
}

# Geweke convergence diagnostic z-score
calc_geweke_z <- function(x) {
  n <- length(x)
  n1 <- floor(0.1 * n)
  n2 <- floor(0.5 * n)
  x1 <- x[1:n1]
  x2 <- x[(n - n2 + 1):n]
  v1 <- var(x1) / n1
  v2 <- var(x2) / n2
  if ((v1 + v2) <= 0) return(0.0)
  (mean(x1) - mean(x2)) / sqrt(v1 + v2)
}

# Effective sample size (ESS) via lag-1 autocorrelation
calc_ess <- function(x) {
  n <- length(x)
  if (sd(x) == 0) return(n)
  r1 <- acf(x, lag.max = 1, plot = FALSE)$acf[2]
  if (is.na(r1)) return(n)
  r1 <- max(min(r1, 0.99), -0.99)
  n * (1 - r1) / (1 + r1)
}

# Fit mvbcf and compute both observation-level and country-clustered posterior summaries
fit_mvbcf_spec <- function(d_in, y_cols, z_col, extra_con = NULL, mod_cols = base_mod_vars,
                           n_iter = 2000, n_burn = 750, n_tree_mu = 75, n_tree_tau = 30,
                           min_nodesize = 3, seed = 20261103) {
  set.seed(seed)
  keep <- complete.cases(d_in[, c(y_cols, z_col)])
  d <- d_in[keep, , drop = FALSE]
  p <- length(y_cols)
  Y <- as.matrix(d[, y_cols, drop = FALSE])
  Z <- as.numeric(d[[z_col]])

  use_con <- unique(c(base_con_vars, extra_con))
  X_mu  <- prep_matrix(d, use_con)
  X_mod <- prep_matrix(d, mod_cols)

  # Estimate propensity score pi_hat(X)
  df_ps <- as.data.frame(X_mu)
  df_ps$Z_target <- Z
  ps_fit <- suppressWarnings(glm(Z_target ~ ., data = df_ps, family = binomial()))
  pi_hat <- pmin(pmax(predict(ps_fit, type = "response"), 0.02), 0.98)
  X_con  <- as.matrix(cbind(X_mu, pi_hat = pi_hat))

  fit <- run_mvbcf(
    X_con = X_con, y = Y, Z = Z, X_mod = X_mod,
    n_iter = n_iter, n_tree = n_tree_mu, n_tree_tau = n_tree_tau,
    min_nodesize = min_nodesize
  )

  post_idx <- (n_burn + 1):n_iter
  n_post   <- length(post_idx)

  # Country-clustered Bayesian bootstrap weights across sovereign countries
  clusters <- unique(d$iso3)
  n_clus   <- length(clusters)
  clus_idx <- match(d$iso3, clusters)
  # Generate C x n_post Dirichlet/Exponential cluster weights
  exp_mat  <- matrix(rexp(n_clus * n_post, rate = 1.0), nrow = n_clus, ncol = n_post)
  obs_w    <- exp_mat[clus_idx, , drop = FALSE]
  obs_w    <- sweep(obs_w, 2, colSums(obs_w), "/")

  list(
    data     = d,
    pi_hat   = pi_hat,
    fit      = fit,
    post_idx = post_idx,
    obs_w    = obs_w,
    n_obs    = nrow(d),
    n_countries = n_clus,
    treated_share = mean(Z == 1),
    y_cols   = y_cols,
    z_col    = z_col
  )
}

summarise_fit <- function(res, model_id, model_label, horizon_label, out_labels = outcome_labels) {
  rows <- list()
  for (j in seq_along(res$y_cols)) {
    tau_mat <- res$fit$predictions_tau[, j, res$post_idx]
    ate_draws <- colMeans(tau_mat)
    clu_draws <- colSums(tau_mat * res$obs_w)

    rows[[j]] <- tibble(
      model_id        = model_id,
      model_label     = model_label,
      horizon         = horizon_label,
      n_obs           = res$n_obs,
      n_countries     = res$n_countries,
      treated_pct     = round(100 * res$treated_share, 1),
      outcome_index   = j,
      outcome         = out_labels[j],
      ate_mean        = round(mean(ate_draws), 3),
      ate_sd          = round(sd(ate_draws), 3),
      ate_cri95_low   = round(quantile(ate_draws, 0.025), 3),
      ate_cri95_high  = round(quantile(ate_draws, 0.975), 3),
      ate_cri80_low   = round(quantile(ate_draws, 0.10), 3),
      ate_cri80_high  = round(quantile(ate_draws, 0.90), 3),
      prob_positive   = round(mean(ate_draws > 0), 3),
      clu_mean        = round(mean(clu_draws), 3),
      clu_cri95_low   = round(quantile(clu_draws, 0.025), 3),
      clu_cri95_high  = round(quantile(clu_draws, 0.975), 3),
      clu_prob_pos    = round(mean(clu_draws > 0), 3),
      ess             = round(calc_ess(ate_draws), 1),
      geweke_z        = round(calc_geweke_z(ate_draws), 2)
    )
  }
  bind_rows(rows)
}

# ==============================================================================
# 1. Fit Core Total Effect (M1) vs Mediator-Removed Direct Effect (M2) Models
# ==============================================================================
cat("1. Fitting M1 (Total Fiscal Effect) & M2 (Mediator-Removed Direct Fiscal Effect)...\n")

m1_5y  <- fit_mvbcf_spec(df, y5_cols,  "Z_regime_inc", extra_con = NULL)
m1_10y <- fit_mvbcf_spec(df, y10_cols, "Z_regime_inc", extra_con = NULL)

m2_5y  <- fit_mvbcf_spec(df, y5_cols,  "Z_regime_inc", extra_con = mediators_5y)
m2_10y <- fit_mvbcf_spec(df, y10_cols, "Z_regime_inc", extra_con = mediators_10y)

# ==============================================================================
# 2. Fit M3: Unbundled Treatment Exposures (Denominator Trap Horse-Race)
# ==============================================================================
cat("\n2. Fitting M3 (Unbundled University & Education Spending Exposures)...\n")

# M3a: Strictly Observed Per-Student Spending Ratio Expansion (No Proxy, Mediator-Adjusted)
m3_exp_5y  <- fit_mvbcf_spec(df, y5_cols,  "Z_expansion_obs", extra_con = mediators_5y)
m3_exp_10y <- fit_mvbcf_spec(df, y10_cols, "Z_expansion_obs", extra_con = mediators_10y)

# M3b: Real 2021 PPP Dollars per Student Regime (Removes GDP Denominator, Mediator-Adjusted)
m3_real_5y  <- fit_mvbcf_spec(df, y5_cols,  "Z_real_spend_regime", extra_con = mediators_5y)
m3_real_10y <- fit_mvbcf_spec(df, y10_cols, "Z_real_spend_regime", extra_con = mediators_10y)

# M3c: Public University Budget % of GDP Regime (Removes Enrolment Denominator, Mediator-Adjusted)
m3_tgdp_5y  <- fit_mvbcf_spec(df, y5_cols,  "Z_tert_gdp_regime", extra_con = mediators_5y)
m3_tgdp_10y <- fit_mvbcf_spec(df, y10_cols, "Z_tert_gdp_regime", extra_con = mediators_10y)

# M3d: Total Public Education Spending % of GDP Regime (All Education Levels Comparison)
m3_etot_5y  <- fit_mvbcf_spec(df, y5_cols,  "Z_edu_total_regime", extra_con = mediators_5y)
m3_etot_10y <- fit_mvbcf_spec(df, y10_cols, "Z_edu_total_regime", extra_con = mediators_10y)

# ==============================================================================
# 3. Compile Table 1 (Main ATE Posteriors) & Export Posterior Draws
# ==============================================================================
table1_main <- bind_rows(
  summarise_fit(m1_5y,       "M1a_Total_5y",        "Total Effect: Per-Student Ratio Regime",       "+5 years (t+1)"),
  summarise_fit(m1_10y,      "M1b_Total_10y",       "Total Effect: Per-Student Ratio Regime",       "+10 years (t+2)"),
  summarise_fit(m2_5y,       "M2a_Direct_5y",       "Direct Effect (Mediators Removed): Ratio",     "+5 years (t+1)"),
  summarise_fit(m2_10y,      "M2b_Direct_10y",      "Direct Effect (Mediators Removed): Ratio",     "+10 years (t+2)"),
  summarise_fit(m3_exp_5y,   "M3a_ObsExp_5y",       "Direct Effect: Observed Ratio Expansion",      "+5 years (t+1)"),
  summarise_fit(m3_exp_10y,  "M3b_ObsExp_10y",      "Direct Effect: Observed Ratio Expansion",      "+10 years (t+2)"),
  summarise_fit(m3_real_5y,  "M3c_RealPPP_5y",      "Direct Effect: Real PPP $/Student Regime",     "+5 years (t+1)"),
  summarise_fit(m3_real_10y, "M3d_RealPPP_10y",     "Direct Effect: Real PPP $/Student Regime",     "+10 years (t+2)"),
  summarise_fit(m3_tgdp_5y,  "M3e_TertGDP_5y",      "Direct Effect: University Budget % GDP",       "+5 years (t+1)"),
  summarise_fit(m3_tgdp_10y, "M3f_TertGDP_10y",     "Direct Effect: University Budget % GDP",       "+10 years (t+2)"),
  summarise_fit(m3_etot_5y,  "M3g_TotalEduGDP_5y",  "Direct Effect: Total Education Budget % GDP",  "+5 years (t+1)"),
  summarise_fit(m3_etot_10y, "M3h_TotalEduGDP_10y", "Direct Effect: Total Education Budget % GDP",  "+10 years (t+2)")
)

write_csv(table1_main, file.path(tab_dir, "table1_mvbcf_ate_posteriors.csv"))
cat("\n=== Table 1: mvbcf Posterior ATE Summaries (Observation & Country-Clustered) ===\n")
print(table1_main %>% select(model_id, horizon, outcome, ate_mean, ate_cri95_low, ate_cri95_high, prob_positive, clu_cri95_low, clu_cri95_high, clu_prob_pos), n = 48)

# ==============================================================================
# 4. Extract Residual Correlation Matrix Posterior (Table 2)
# ==============================================================================
extract_corr_table <- function(res, model_label, horizon_label) {
  rows <- list()
  idx <- 1
  for (j in 1:4) {
    for (k in j:4) {
      if (j == k) {
        sd_draws <- sqrt(res$fit$sigmas[j, j, res$post_idx])
        rows[[idx]] <- tibble(
          model = model_label,
          horizon = horizon_label,
          pair = paste0("Residual SD: ", outcome_labels[j]),
          param_type = "Residual_SD",
          post_mean = round(mean(sd_draws), 3),
          cri95_low = round(quantile(sd_draws, 0.025), 3),
          cri95_high = round(quantile(sd_draws, 0.975), 3)
        )
      } else {
        corr_draws <- res$fit$sigmas[j, k, res$post_idx] /
          sqrt(res$fit$sigmas[j, j, res$post_idx] * res$fit$sigmas[k, k, res$post_idx])
        rows[[idx]] <- tibble(
          model = model_label,
          horizon = horizon_label,
          pair = paste0(outcome_labels[j], " <-> ", outcome_labels[k]),
          param_type = "Residual_Correlation",
          post_mean = round(mean(corr_draws), 3),
          cri95_low = round(quantile(corr_draws, 0.025), 3),
          cri95_high = round(quantile(corr_draws, 0.975), 3)
        )
      }
      idx <- idx + 1
    }
  }
  bind_rows(rows)
}

table2_corr <- bind_rows(
  extract_corr_table(m2_5y,  "M2_Direct_Effect", "+5 years (t+1)"),
  extract_corr_table(m2_10y, "M2_Direct_Effect", "+10 years (t+2)")
)
write_csv(table2_corr, file.path(tab_dir, "table2_residual_correlations.csv"))
cat("\n=== Table 2: Residual Covariance & Correlation Matrix Posterior ===\n")
print(table2_corr, n = 20)

# ==============================================================================
# 5. Extract Subgroup CATEs by Enrolment Regime, Income Group & OECD Model (Table 3)
# ==============================================================================
attach_icates <- function(res, prefix) {
  d <- res$data
  for (j in 1:4) {
    tau_mat <- res$fit$predictions_tau[, j, res$post_idx]
    d[[paste0(prefix, "_tau_", outcome_short[j])]] <- rowMeans(tau_mat)
  }
  d
}

df_5y_icates  <- attach_icates(m2_5y,  "m2_5y")
df_10y_icates <- attach_icates(m2_10y, "m2_10y")

write_csv(df_5y_icates,  file.path(proc_dir, "panel_5y_with_icates.csv"))
write_csv(df_10y_icates, file.path(proc_dir, "panel_10y_with_icates.csv"))

# Compute subgroup CATEs with posterior 95% credible intervals across MCMC draws
compute_subgroup_cates <- function(res, group_col, dim_label, horizon_label) {
  d <- res$data
  levels_vec <- sort(unique(na.omit(d[[group_col]])))
  out_rows <- list()
  for (lv in levels_vec) {
    idx <- which(d[[group_col]] == lv)
    if (length(idx) < 5) next
    tau1 <- colMeans(res$fit$predictions_tau[idx, 1, res$post_idx, drop = FALSE])
    tau2 <- colMeans(res$fit$predictions_tau[idx, 2, res$post_idx, drop = FALSE])
    tau3 <- colMeans(res$fit$predictions_tau[idx, 3, res$post_idx, drop = FALSE])
    tau4 <- colMeans(res$fit$predictions_tau[idx, 4, res$post_idx, drop = FALSE])
    out_rows[[length(out_rows) + 1]] <- tibble(
      dimension = dim_label,
      horizon = horizon_label,
      subgroup = as.character(lv),
      n_obs = length(idx),
      n_countries = n_distinct(d$iso3[idx]),
      cate_tax_gdp_pp = round(mean(tau1), 2),
      cate_tax_gdp_low = round(quantile(tau1, 0.025), 2),
      cate_tax_gdp_high = round(quantile(tau1, 0.975), 2),
      cate_inc_gdp_pp = round(mean(tau2), 2),
      cate_inc_gdp_low = round(quantile(tau2, 0.025), 2),
      cate_inc_gdp_high = round(quantile(tau2, 0.975), 2),
      cate_inc_share_pp = round(mean(tau3), 2),
      cate_inc_share_low = round(quantile(tau3, 0.025), 2),
      cate_inc_share_high = round(quantile(tau3, 0.975), 2),
      prob_inc_share_pos = round(mean(tau3 > 0), 3),
      cate_goods_share_pp = round(mean(tau4), 2)
    )
  }
  bind_rows(out_rows)
}

# Fit OECD Public vs Private Financing Deep-Dive (Model M4)
df_oecd <- df %>% filter(is_oecd == 1)
oecd_mod_vars <- c(base_mod_vars, "oecd_public_tert_share_pct")
m4_oecd_5y  <- fit_mvbcf_spec(df_oecd, y5_cols,  "Z_regime_inc", extra_con = c("oecd_public_tert_share_pct", mediators_5y),
                              mod_cols = oecd_mod_vars, n_tree_mu = 50, n_tree_tau = 25, min_nodesize = 2)
m4_oecd_10y <- fit_mvbcf_spec(df_oecd, y10_cols, "Z_regime_inc", extra_con = c("oecd_public_tert_share_pct", mediators_10y),
                              mod_cols = oecd_mod_vars, n_tree_mu = 50, n_tree_tau = 25, min_nodesize = 2)

table3_subgroups <- bind_rows(
  compute_subgroup_cates(m2_5y,       "enrol_regime",        "University Enrolment Regime", "+5 years (t+1)"),
  compute_subgroup_cates(m2_10y,      "enrol_regime",        "University Enrolment Regime", "+10 years (t+2)"),
  compute_subgroup_cates(m2_10y,      "income_group",        "World Bank Income Group",     "+10 years (t+2)"),
  compute_subgroup_cates(m4_oecd_10y, "oecd_finance_regime", "OECD Financing Model",        "+10 years (t+2)")
)
write_csv(table3_subgroups, file.path(tab_dir, "table3_subgroup_cates.csv"))
cat("\n=== Table 3: Subgroup Conditional Average Treatment Effects (CATEs) ===\n")
print(table3_subgroups, n = 25)

# ==============================================================================
# 6. Fit Robustness & Identification Checks (Table 4)
# ==============================================================================
cat("\n3. Running Robustness & Identification Checks (Table 4)...\n")

# R1: Pure Unadjusted WDI Tax/GDP (d_t2_wdi_tax_gdp_pp instead of non-resource adjusted)
y10_pure_wdi <- c("d_t2_wdi_tax_gdp_pp", "d_t2_inc_tax_gdp_pp", "d_t2_inc_tax_share_pp", "d_t2_goods_tax_share_pp")
rob_pure_wdi <- fit_mvbcf_spec(df, y10_pure_wdi, "Z_regime_inc", extra_con = mediators_10y)

# R2: Non-Overlapping 10-Year Decadal Windows (waves 2, 4, 6 only)
df_nonoverlap <- df %>% filter(wave_index %in% c(2, 4, 6))
rob_nonoverlap <- fit_mvbcf_spec(df_nonoverlap, y10_cols, "Z_regime_inc", extra_con = mediators_10y)

# R3: Within-Country Demeaned Outcomes (Two-Way Country + Wave Fixed Effects)
df_fe <- df %>%
  group_by(iso3) %>%
  mutate(across(all_of(c(y5_cols, y10_cols)), ~ .x - mean(.x, na.rm = TRUE))) %>%
  ungroup()
rob_fe_5y  <- fit_mvbcf_spec(df_fe, y5_cols,  "Z_regime_inc", extra_con = mediators_5y)
rob_fe_10y <- fit_mvbcf_spec(df_fe, y10_cols, "Z_regime_inc", extra_con = mediators_10y)

# R4: Placebo Lead Check (Does future wave t+1 funding expansion predict past wave t-1 -> t tax change?)
df_placebo <- df %>%
  arrange(iso3, wave_index) %>%
  group_by(iso3) %>%
  mutate(Z_lead_regime = lead(Z_regime_inc, 1)) %>%
  ungroup()
rob_placebo <- fit_mvbcf_spec(df_placebo, y5_cols, "Z_lead_regime", extra_con = mediators_5y)

table4_robustness <- bind_rows(
  summarise_fit(rob_pure_wdi,   "R1_Pure_WDI_Tax_10y",      "Pure Unadjusted WDI Tax/GDP (+10y)",          "+10 years (t+2)"),
  summarise_fit(rob_nonoverlap, "R2_NonOverlap_10y",        "Non-Overlapping Decadal Waves (+10y)",        "+10 years (t+2)"),
  summarise_fit(rob_fe_5y,      "R3a_CountryFE_Demean_5y",  "Within-Country Demeaned Fixed Effects (+5y)", "+5 years (t+1)"),
  summarise_fit(rob_fe_10y,     "R3b_CountryFE_Demean_10y", "Within-Country Demeaned Fixed Effects (+10y)","+10 years (t+2)"),
  summarise_fit(m4_oecd_5y,     "R4a_OECD_Subsample_5y",    "OECD Member States Subsample (+5y)",          "+5 years (t+1)"),
  summarise_fit(m4_oecd_10y,    "R4b_OECD_Subsample_10y",   "OECD Member States Subsample (+10y)",         "+10 years (t+2)"),
  summarise_fit(rob_placebo,    "R5_Placebo_FutureZ_5y",    "Placebo Check: Future (t+1) Regime on Current Tax", "+5 years (t+1)")
)

write_csv(table4_robustness, file.path(tab_dir, "table4_robustness_checks.csv"))
cat("\n=== Table 4: Robustness & Identification Checks ===\n")
print(table4_robustness %>% select(model_id, n_obs, outcome, ate_mean, ate_cri95_low, ate_cri95_high, prob_positive, clu_prob_pos), n = 30)

# Save posterior ATE draws for plotting Figure 2 and Appendix trace plots
ate_draws_export <- bind_rows(
  tibble(
    draw = seq_along(m1_5y$post_idx),
    model = "Total Fiscal Effect (M1)",
    horizon = "+5 years",
    tax_gdp_pp = colMeans(m1_5y$fit$predictions_tau[, 1, m1_5y$post_idx]),
    inc_tax_gdp_pp = colMeans(m1_5y$fit$predictions_tau[, 2, m1_5y$post_idx]),
    inc_tax_share_pp = colMeans(m1_5y$fit$predictions_tau[, 3, m1_5y$post_idx]),
    goods_tax_share_pp = colMeans(m1_5y$fit$predictions_tau[, 4, m1_5y$post_idx])
  ),
  tibble(
    draw = seq_along(m1_10y$post_idx),
    model = "Total Fiscal Effect (M1)",
    horizon = "+10 years",
    tax_gdp_pp = colMeans(m1_10y$fit$predictions_tau[, 1, m1_10y$post_idx]),
    inc_tax_gdp_pp = colMeans(m1_10y$fit$predictions_tau[, 2, m1_10y$post_idx]),
    inc_tax_share_pp = colMeans(m1_10y$fit$predictions_tau[, 3, m1_10y$post_idx]),
    goods_tax_share_pp = colMeans(m1_10y$fit$predictions_tau[, 4, m1_10y$post_idx])
  ),
  tibble(
    draw = seq_along(m2_5y$post_idx),
    model = "Mediator-Removed Direct Effect (M2)",
    horizon = "+5 years",
    tax_gdp_pp = colMeans(m2_5y$fit$predictions_tau[, 1, m2_5y$post_idx]),
    inc_tax_gdp_pp = colMeans(m2_5y$fit$predictions_tau[, 2, m2_5y$post_idx]),
    inc_tax_share_pp = colMeans(m2_5y$fit$predictions_tau[, 3, m2_5y$post_idx]),
    goods_tax_share_pp = colMeans(m2_5y$fit$predictions_tau[, 4, m2_5y$post_idx])
  ),
  tibble(
    draw = seq_along(m2_10y$post_idx),
    model = "Mediator-Removed Direct Effect (M2)",
    horizon = "+10 years",
    tax_gdp_pp = colMeans(m2_10y$fit$predictions_tau[, 1, m2_10y$post_idx]),
    inc_tax_gdp_pp = colMeans(m2_10y$fit$predictions_tau[, 2, m2_10y$post_idx]),
    inc_tax_share_pp = colMeans(m2_10y$fit$predictions_tau[, 3, m2_10y$post_idx]),
    goods_tax_share_pp = colMeans(m2_10y$fit$predictions_tau[, 4, m2_10y$post_idx])
  )
)
write_csv(ate_draws_export, file.path(proc_dir, "mvbcf_ate_posterior_draws.csv"))

cat("\nStep 3.1 complete! All mvbcf models and robustness tables saved.\n")
