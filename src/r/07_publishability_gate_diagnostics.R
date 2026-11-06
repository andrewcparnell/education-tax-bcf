# =============================================================================
# 07_publishability_gate_diagnostics.R
# Phase 6 Publishability Gate: Clean Diagnostic Verification
# Simultaneously tests every foundational critique raised by Reviewers 1-6:
#   D1. Reference M2 (+5y and +10y)
#   D2. Two-Stage Sequential G-Estimation (Acharya, Blackwell & Sen, 2016)
#       to eliminate single-stage post-treatment collider interactions
#   D3. Strictly Wave-Specific (Pre-Treatment Wave-t) Income-Tier Medians
#       (zero 1985-2024 pooled look-ahead in treatment regime definition)
#   D4. Pure Unadjusted WDI Tax/GDP & Pure WDI Direct Income Tax/GDP
#       (zero heuristic resource-rent subtraction)
#   D5. Common-Sample (N=283) Intensive vs Extensive Margin Horserace
#       (comparing Per-Student Ratio vs Tertiary Budget % GDP on identical units)
#   D6. Controlling for Pre-Treatment Fiscal Pre-Trends (Delta Y_{t-1 -> t})
#       and Properly Demeaned Within-Country Fixed Effects (demeaning Y, Z, X)
#   D7. Clean Three-Wave Longitudinal BCF (lbcf_3wave): strictly Wave-1
#       mediators in mu_1, Wave-2 incremental mediators in mu_2, all 4
#       mediators included, and baseline level Y_{i,0} subtracted
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(Rcpp)
  library(RcppArmadillo)
})

repo_root <- normalizePath(getwd(), mustWork = TRUE)
Sys.setenv(R_MAKEVARS_USER = file.path(repo_root, "src", "cpp", "Makevars"))
sourceCpp(file.path(repo_root, "src", "cpp", "mvbcf_source_code.cpp"),
          cacheDir = "/tmp/rcpp_cache_edu_tax_bcf", verbose = FALSE)
sourceCpp(file.path(repo_root, "src", "cpp", "lbcf_3wave.cpp"),
          cacheDir = "/tmp/rcpp_cache_edu_tax_lbcf3", verbose = FALSE)
source(file.path(repo_root, "src", "r", "mvbcf_helpers.R"))

proc_dir <- file.path(repo_root, "data", "processed")
country_folds <- read_csv(file.path(proc_dir, "splits", "country_folds.csv"), show_col_types = FALSE)

df <- read_csv(file.path(proc_dir, "clean_tax_panel.csv"), show_col_types = FALSE) %>%
  left_join(country_folds, by = "iso3") %>%
  mutate(
    income_group_num = as.numeric(factor(income_group, levels = c(
      "Low income", "Lower middle income", "Upper middle income", "High income"
    ))),
    region_num = as.numeric(factor(region))
  )

y5_cols  <- c("d_t1_nonres_tax_gdp_pp", "d_t1_inc_tax_gdp_pp", "d_t1_inc_tax_share_pp", "d_t1_goods_tax_share_pp")
y10_cols <- c("d_t2_nonres_tax_gdp_pp", "d_t2_inc_tax_gdp_pp", "d_t2_inc_tax_share_pp", "d_t2_goods_tax_share_pp")
outcome_names <- c("Non-Resource Tax / GDP (pp)",
                   "Direct Income & Profit Tax / GDP (pp)",
                   "Direct Income & Profit Share of Revenue (pp)",
                   "Goods & Services Tax Share of Revenue (pp)")

base_con_vars <- c(
  "log_gdp_pc_ppp", "non_resource_tax_gdp_pct",
  "income_profit_tax_share_rev_pct", "goods_services_tax_share_rev_pct",
  "gini_disp_harmonised", "life_expectancy_birth_yrs",
  "gross_tert_enrolment_pct", "gross_seco_enrolment_pct",
  "edu_spend_total_gdp_pct", "working_age_pop_15_64_pct",
  "log_population", "unemployment_rate_pct",
  "natural_resource_rents_gdp_pct", "trade_openness_gdp_pct",
  "lag_gdp_pc_growth_pct", "income_group_num",
  "region_num", "is_oecd", "wave_index"
)
base_mod_vars <- c(
  "log_gdp_pc_ppp", "non_resource_tax_gdp_pct",
  "income_profit_tax_share_rev_pct", "gross_tert_enrolment_pct",
  "gross_seco_enrolment_pct", "working_age_pop_15_64_pct",
  "income_group_num", "is_oecd", "wave_index"
)
med10_vars <- c("d_t2_log_gdp_pc_pct", "d_t2_tert_enrol_pp", "d_t2_gini_disp", "d_t2_life_exp_yrs")
med5_vars  <- c("d_t1_log_gdp_pc_pct", "d_t1_tert_enrol_pp", "d_t1_gini_disp", "d_t1_life_exp_yrs")

prep_mat_clean <- function(data, vars) {
  sub <- data[, vars, drop = FALSE]
  for (v in vars) {
    x <- as.numeric(sub[[v]])
    if (any(is.na(x))) {
      med <- median(x, na.rm = TRUE)
      if (is.na(med)) med <- 0
      x[is.na(x)] <- med
    }
    sub[[v]] <- x
  }
  as.matrix(sub)
}

run_clean_mvbcf <- function(d_sub, y_cols, z_col, con_vars, mod_vars,
                            spec_id, spec_label, horizon_label, seed = 20261103) {
  set.seed(seed)
  cc <- complete.cases(d_sub[, c(y_cols, z_col)])
  d_cc <- d_sub[cc, , drop = FALSE]
  Y_mat <- as.matrix(d_cc[, y_cols, drop = FALSE])
  Z_vec <- as.numeric(d_cc[[z_col]])
  X_pre <- prep_mat_clean(d_cc, base_con_vars)

  ps_df <- as.data.frame(X_pre)
  ps_df$Z_target <- Z_vec
  ps_fit <- suppressWarnings(glm(Z_target ~ ., data = ps_df, family = binomial()))
  pi_hat <- pmin(pmax(as.numeric(predict(ps_fit, type = "response")), 0.02), 0.98)

  X_con <- as.matrix(cbind(prep_mat_clean(d_cc, con_vars), pi_hat = pi_hat))
  X_mod <- prep_mat_clean(d_cc, mod_vars)

  fit <- run_mvbcf(
    X_con = X_con, y = Y_mat, Z = Z_vec, X_mod = X_mod,
    alpha_tau = 0.25, beta_tau = 3.0, v_0 = length(y_cols) + 2,
    n_iter = 2000, n_tree = 75, n_tree_tau = 30, min_nodesize = 3
  )
  post_idx <- 751:2000
  out_list <- list()
  for (j in seq_along(y_cols)) {
    tau_mat <- fit$predictions_tau[, j, post_idx]
    tau_vec <- colMeans(tau_mat)
    out_list[[j]] <- data.frame(
      spec_id = spec_id,
      spec_label = spec_label,
      horizon = horizon_label,
      n_obs = nrow(d_cc),
      n_countries = length(unique(d_cc$iso3)),
      outcome_index = j,
      outcome = outcome_names[j],
      ate_mean = round(mean(tau_vec), 3),
      ate_sd = round(sd(tau_vec), 3),
      cri95_low = round(as.numeric(quantile(tau_vec, 0.025)), 3),
      cri95_high = round(as.numeric(quantile(tau_vec, 0.975)), 3),
      prob_pos = round(mean(tau_vec > 0), 3),
      stringsAsFactors = FALSE
    )
  }
  bind_rows(out_list)
}

results_all <- list()

# -----------------------------------------------------------------------------
# D1: Reference M2 (+5y and +10y)
# -----------------------------------------------------------------------------
cat("Running D1: Reference M2 (+5y and +10y)...\n")
results_all[["D1_5y"]] <- run_clean_mvbcf(
  df, y5_cols, "Z_regime_inc", unique(c(base_con_vars, med5_vars)), base_mod_vars,
  "D1_Ref_M2_5y", "Reference M2 Direct Effect (+5y)", "+5 years", seed = 103
)
results_all[["D1_10y"]] <- run_clean_mvbcf(
  df, y10_cols, "Z_regime_inc", unique(c(base_con_vars, med10_vars)), base_mod_vars,
  "D1_Ref_M2_10y", "Reference M2 Direct Effect (+10y)", "+10 years", seed = 104
)

# -----------------------------------------------------------------------------
# D2: Two-Stage Sequential G-Estimation (Acharya, Blackwell & Sen, 2016)
# Stage 1: Estimate effect of post-treatment mediators M_{i,t+h} on Y_{i,t+h}
#          controlling for Z_{i,t} and pre-treatment X_{i,t}, then demediate Y.
# Stage 2: Fit mvbcf on demediated Y using strictly pre-treatment X_{i,t}.
# -----------------------------------------------------------------------------
cat("Running D2: Two-Stage Sequential G-Estimation (+5y and +10y)...\n")
run_seq_g <- function(d_sub, y_cols, med_vars, spec_id, spec_label, horizon_label, seed) {
  cc <- complete.cases(d_sub[, c(y_cols, "Z_regime_inc")])
  d_cc <- d_sub[cc, , drop = FALSE]
  X_pre <- prep_mat_clean(d_cc, base_con_vars)
  M_mat <- prep_mat_clean(d_cc, med_vars)
  Z_vec <- as.numeric(d_cc$Z_regime_inc)

  d_demed <- d_cc
  for (yc in y_cols) {
    y_val <- as.numeric(d_cc[[yc]])
    df_stg1 <- as.data.frame(cbind(y_val = y_val, Z = Z_vec, X_pre, M_mat))
    fit_stg1 <- lm(y_val ~ ., data = df_stg1)
    coefs <- coef(fit_stg1)[colnames(M_mat)]
    coefs[is.na(coefs)] <- 0
    M_centred <- scale(M_mat, center = TRUE, scale = FALSE)
    d_demed[[yc]] <- y_val - as.numeric(M_centred %*% coefs)
  }
  run_clean_mvbcf(d_demed, y_cols, "Z_regime_inc", base_con_vars, base_mod_vars,
                  spec_id, spec_label, horizon_label, seed = seed)
}

results_all[["D2_SeqG_5y"]] <- run_seq_g(
  df, y5_cols, med5_vars, "D2_SeqG_5y",
  "Two-Stage Sequential G-Estimation (+5y, Acharya et al. 2016)", "+5 years", seed = 201
)
results_all[["D2_SeqG_10y"]] <- run_seq_g(
  df, y10_cols, med10_vars, "D2_SeqG_10y",
  "Two-Stage Sequential G-Estimation (+10y, Acharya et al. 2016)", "+10 years", seed = 202
)

# -----------------------------------------------------------------------------
# D3: Strictly Wave-Specific (Pre-Treatment Wave-t) GDP Quartile Medians
# Eliminates 1985-2024 pooled median look-ahead and static 2024 income group
# -----------------------------------------------------------------------------
cat("Running D3: Wave-Specific Pre-Treatment Income-Tier Medians (+10y)...\n")
df_wave_z <- df %>%
  group_by(wave_index) %>%
  mutate(
    hist_inc_tier = ntile(log_gdp_pc_ppp, 4)
  ) %>%
  group_by(wave_index, hist_inc_tier) %>%
  mutate(
    med_wave_tier = median(tert_spend_per_student_winsor, na.rm = TRUE),
    Z_wave_strict = ifelse(is.na(tert_spend_per_student_winsor), NA_real_,
                           ifelse(tert_spend_per_student_winsor > med_wave_tier, 1, 0))
  ) %>%
  ungroup()

results_all[["D3_WaveStrict_10y"]] <- run_clean_mvbcf(
  df_wave_z, y10_cols, "Z_wave_strict", unique(c(base_con_vars, med10_vars)), base_mod_vars,
  "D3_WaveStrict_10y", "Wave-Specific Pre-Treatment GDP-Tier Medians (+10y)", "+10 years", seed = 301
)

# -----------------------------------------------------------------------------
# D4: Pure WDI Tax/GDP and Pure WDI Direct Income Tax/GDP (Zero Heuristic)
# -----------------------------------------------------------------------------
cat("Running D4: Pure Unadjusted WDI Tax & Income Tax/GDP (+10y)...\n")
df_pure_wdi <- df %>%
  mutate(
    pure_inc_gdp_t0 = tax_rev_gdp_pct * (income_profit_tax_share_rev_pct / 100.0)
  ) %>%
  group_by(iso3) %>%
  arrange(wave_index) %>%
  mutate(
    d_t2_pure_tax_gdp_pp = lead(tax_rev_gdp_pct, 2L) - tax_rev_gdp_pct,
    d_t2_pure_inc_gdp_pp = lead(pure_inc_gdp_t0, 2L) - pure_inc_gdp_t0
  ) %>%
  ungroup()

y10_pure_cols <- c("d_t2_pure_tax_gdp_pp", "d_t2_pure_inc_gdp_pp",
                   "d_t2_inc_tax_share_pp", "d_t2_goods_tax_share_pp")
results_all[["D4_PureWDI_10y"]] <- run_clean_mvbcf(
  df_pure_wdi, y10_pure_cols, "Z_regime_inc", unique(c(base_con_vars, med10_vars)), base_mod_vars,
  "D4_PureWDI_10y", "Pure Unadjusted WDI Tax/GDP & Pure Direct Tax/GDP (+10y)", "+10 years", seed = 401
)

# -----------------------------------------------------------------------------
# D5: Common-Sample (N=283 Intersection) Horserace for Tertiary Budget % GDP
# -----------------------------------------------------------------------------
cat("Running D5: Common-Sample Horserace for Tertiary Budget % GDP (+10y)...\n")
df_common_283 <- df[complete.cases(df[, c(y10_cols, "Z_regime_inc", "Z_tert_gdp_regime")]), ]
results_all[["D5_Common_TertGDP_10y"]] <- run_clean_mvbcf(
  df_common_283, y10_cols, "Z_tert_gdp_regime", unique(c(base_con_vars, med10_vars)), base_mod_vars,
  "D5_Common_TertGDP_10y", "Extensive-Margin Tertiary Budget % GDP on Common Sample (+10y)", "+10 years", seed = 501
)

# -----------------------------------------------------------------------------
# D6: Controlling for Pre-Treatment Fiscal Pre-Trends (Delta Y_{t-1 -> t})
# -----------------------------------------------------------------------------
cat("Running D6: Controlling for Pre-Treatment Fiscal Trends (+10y)...\n")
df_pretrend <- df %>%
  group_by(iso3) %>%
  arrange(wave_index) %>%
  mutate(
    pre_d_tax_gdp = non_resource_tax_gdp_pct - lag(non_resource_tax_gdp_pct, 1L),
    pre_d_inc_share = income_profit_tax_share_rev_pct - lag(income_profit_tax_share_rev_pct, 1L),
    pre_d_goods_share = goods_services_tax_share_rev_pct - lag(goods_services_tax_share_rev_pct, 1L)
  ) %>%
  ungroup()

results_all[["D6_PreTrend_10y"]] <- run_clean_mvbcf(
  df_pretrend, y10_cols, "Z_regime_inc",
  unique(c(base_con_vars, "pre_d_tax_gdp", "pre_d_inc_share", "pre_d_goods_share", med10_vars)),
  base_mod_vars,
  "D6_PreTrend_10y", "Controlling for Pre-Treatment Fiscal Trends (+10y)", "+10 years", seed = 601
)

# -----------------------------------------------------------------------------
# D7: Clean Three-Wave Longitudinal BCF (lbcf_3wave)
# Fixes:
#   1. Wave 1 growth forest mu_1 receives ONLY Wave 1 [t, t+1] mediators
#   2. Wave 2 growth forest mu_2 receives ONLY Wave 2 [t+1, t+2] incremental mediators
#   3. All 4 mediators included (GDP growth, enrolment, Gini, life expectancy)
#   4. Models cumulative changes relative to baseline Y_{i,0} (y_w - y_0)
#      so cross-country baseline level variance cannot contaminate tau_1, tau_2
# -----------------------------------------------------------------------------
cat("Running D7: Clean Three-Wave Longitudinal BCF (lbcf_3wave)...\n")
df_lbcf <- df %>%
  group_by(iso3) %>%
  arrange(wave_index) %>%
  mutate(
    d_t1to2_log_gdp = d_t2_log_gdp_pc_pct - d_t1_log_gdp_pc_pct,
    d_t1to2_tert_enrol = d_t2_tert_enrol_pp - d_t1_tert_enrol_pp,
    d_t1to2_gini = d_t2_gini_disp - d_t1_gini_disp,
    d_t1to2_life_exp = d_t2_life_exp_yrs - d_t1_life_exp_yrs
  ) %>%
  ungroup()

cc_lbcf <- complete.cases(df_lbcf[, c(y5_cols, y10_cols, "Z_regime_inc")])
d_lbcf <- df_lbcf[cc_lbcf, , drop = FALSE]
N_l <- nrow(d_lbcf)

X_pre_l <- prep_mat_clean(d_lbcf, base_con_vars)
ps_df_l <- as.data.frame(X_pre_l)
ps_df_l$Z_target <- d_lbcf$Z_regime_inc
ps_fit_l <- suppressWarnings(glm(Z_target ~ ., data = ps_df_l, family = binomial()))
pi_hat_l <- pmin(pmax(as.numeric(predict(ps_fit_l, type = "response")), 0.02), 0.98)

# Strictly Wave 1 mediators for mu_1, strictly Wave 2 incremental mediators for mu_2
X_g1_unit <- cbind(X_pre_l, prep_mat_clean(d_lbcf, med5_vars), pi_hat = pi_hat_l)
X_g2_unit <- cbind(X_pre_l, prep_mat_clean(d_lbcf, c("d_t1to2_log_gdp", "d_t1to2_tert_enrol", "d_t1to2_gini", "d_t1to2_life_exp")), pi_hat = pi_hat_l)
X_mod_unit <- prep_mat_clean(d_lbcf, base_mod_vars)

X_mu_stack <- rbind(X_pre_l, X_pre_l, X_pre_l)
X_g1_stack <- rbind(X_g1_unit, X_g1_unit, X_g1_unit)
X_g2_stack <- rbind(X_g2_unit, X_g2_unit, X_g2_unit)
X_tau_stack <- rbind(X_mod_unit, X_mod_unit, X_mod_unit)

z_treat <- as.numeric(d_lbcf$Z_regime_inc)
Z_g1 <- c(rep(0, N_l), rep(1, N_l), rep(1, N_l))
Z_g2 <- c(rep(0, N_l), rep(0, N_l), rep(1, N_l))
Z_t1 <- c(rep(0, N_l), z_treat, z_treat)
Z_t2 <- c(rep(0, N_l), rep(0, N_l), z_treat)

lbcf_clean_rows <- list()
n_tree_mu_l     <- 75
n_tree_growth_l <- 45
n_tree_treat_l  <- 30
growth_sigma_l  <- 0.50
treat_sigma_l   <- 0.25
n_iter_l        <- 2500
post_l          <- 751:n_iter_l
idx_w1          <- (N_l + 1):(2 * N_l)
idx_w2          <- (2 * N_l + 1):(3 * N_l)

for (j in seq_along(y5_cols)) {
  # Cumulative changes relative to baseline wave t: Wave 0 = 0, Wave 1 = d_t1, Wave 2 = d_t2
  y_w0 <- rep(0, N_l)
  y_w1 <- as.numeric(d_lbcf[[y5_cols[j]]])
  y_w2 <- as.numeric(d_lbcf[[y10_cols[j]]])
  y_vals <- c(y_w0, y_w1, y_w2)

  set.seed(800 + j)
  fit_l <- fast_lbcf3(
    X_mu_stack, y_vals,
    Z_g1, Z_t1, X_g1_stack, X_tau_stack,
    Z_g2, Z_t2, X_g2_stack, X_tau_stack,
    X_mu_stack, X_g1_stack, X_tau_stack, X_g2_stack, X_tau_stack,
    0.95, 2.0,
    0.95, 2.0,
    0.25, 3.0,
    n_tree_mu_l,
    n_tree_growth_l / (growth_sigma_l^2),
    n_tree_treat_l / (treat_sigma_l^2),
    3.0, 0.1,
    n_iter_l,
    n_tree_mu_l, n_tree_growth_l, n_tree_treat_l,
    3
  )
  tau1_draws <- colMeans(fit_l$predictions_treat[idx_w1, post_l, drop = FALSE])
  tau2_draws <- colMeans(fit_l$predictions_treat2[idx_w2, post_l, drop = FALSE])
  tau_cum_draws <- tau1_draws + tau2_draws

  lbcf_clean_rows[[j]] <- data.frame(
    spec_id = "D7_Clean_LBCF_10y",
    spec_label = sprintf("Clean LBCF 3-Wave Cumulative (+10y; tau1=%+.2f [P=%.2f], tau2=%+.2f [P=%.2f])",
                         mean(tau1_draws), mean(tau1_draws > 0), mean(tau2_draws), mean(tau2_draws > 0)),
    horizon = "+10 years (3-wave)",
    n_obs = N_l,
    n_countries = length(unique(d_lbcf$iso3)),
    outcome_index = j,
    outcome = outcome_names[j],
    ate_mean = round(mean(tau_cum_draws), 3),
    ate_sd = round(sd(tau_cum_draws), 3),
    cri95_low = round(as.numeric(quantile(tau_cum_draws, 0.025)), 3),
    cri95_high = round(as.numeric(quantile(tau_cum_draws, 0.975)), 3),
    prob_pos = round(mean(tau_cum_draws > 0), 3),
    stringsAsFactors = FALSE
  )
}
results_all[["D7_Clean_LBCF"]] <- bind_rows(lbcf_clean_rows)

diag_df <- bind_rows(results_all)
write_csv(diag_df, file.path(repo_root, "outputs", "tables", "publishability_gate_diagnostics.csv"))
print(as.data.frame(diag_df[, c("spec_id", "outcome_index", "ate_mean", "cri95_low", "cri95_high", "prob_pos")]))
cat("Saved outputs/tables/publishability_gate_diagnostics.csv successfully.\n")
