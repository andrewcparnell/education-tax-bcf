#!/usr/bin/env Rscript
# ==============================================================================
# Step 07: Extended Referee Diagnostics (Multi-Chain MCMC, tau=0 CV Ablation,
#          Out-of-Sample R^2, Wave/ACF/Heteroscedasticity Audits & Calibration)
# (src/r/07_extended_referee_diagnostics.R)
# ==============================================================================

suppressPackageStartupMessages({
  library(Rcpp)
  library(RcppArmadillo)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(ranger)
})

repo_root <- getwd()
if (!dir.exists(file.path(repo_root, "src")) && dir.exists(file.path(dirname(dirname(repo_root)), "src"))) {
  repo_root <- dirname(dirname(repo_root))
}
proc_dir    <- file.path(repo_root, "data", "processed")
out_tab_dir <- file.path(repo_root, "outputs", "tables")

cat("Compiling mvbcf C++ sampler for extended diagnostics...\n")
Sys.setenv(R_MAKEVARS_USER = file.path(repo_root, "src", "cpp", "Makevars"))
sourceCpp(file.path(repo_root, "src", "cpp", "mvbcf_source_code.cpp"),
          cacheDir = file.path(tempdir(), "rcpp_cache_edu_tax_bcf"), verbose = FALSE)
source(file.path(repo_root, "src", "r", "mvbcf_helpers.R"))

df <- read_csv(file.path(proc_dir, "clean_tax_panel.csv"), show_col_types = FALSE) %>%
  mutate(
    income_group_num = as.numeric(factor(income_group, levels = c(
      "Low income", "Lower middle income", "Upper middle income", "High income"
    ))),
    region_num = as.numeric(factor(region))
  )

y5_cols  <- c("d_t1_nonres_tax_gdp_pp", "d_t1_inc_tax_gdp_pp", "d_t1_inc_tax_share_pp", "d_t1_goods_tax_share_pp")
y10_cols <- c("d_t2_nonres_tax_gdp_pp", "d_t2_inc_tax_gdp_pp", "d_t2_inc_tax_share_pp", "d_t2_goods_tax_share_pp")
mediators_5y  <- c("d_t1_log_gdp_pc_pct", "d_t1_tert_enrol_pp", "d_t1_gini_disp", "d_t1_life_exp_yrs")
mediators_10y <- c("d_t2_log_gdp_pc_pct", "d_t2_tert_enrol_pp", "d_t2_gini_disp", "d_t2_life_exp_yrs")

outcome_labels <- c(
  "Non-Resource Tax / GDP (pp)",
  "Direct Income & Profit Tax / GDP (pp)",
  "Direct Income & Profit Share of Revenue (pp)",
  "Goods & Services Tax Share of Revenue (pp)"
)
outcome_short <- c("tax_gdp_pp", "inc_tax_gdp_pp", "inc_tax_share_pp", "goods_tax_share_pp")

base_con_vars <- c(
  "log_gdp_pc_ppp", "non_resource_tax_gdp_pct", "income_profit_tax_share_rev_pct",
  "goods_services_tax_share_rev_pct", "gini_disp_harmonised", "life_expectancy_birth_yrs",
  "gross_tert_enrolment_pct", "gross_seco_enrolment_pct", "edu_spend_total_gdp_pct",
  "working_age_pop_15_64_pct", "log_population", "unemployment_rate_pct",
  "natural_resource_rents_gdp_pct", "trade_openness_gdp_pct", "lag_gdp_pc_growth_pct",
  "income_group_num", "region_num", "is_oecd", "wave_index"
)
base_mod_vars <- c(
  "gross_tert_enrolment_pct", "log_gdp_pc_ppp", "gross_seco_enrolment_pct",
  "income_profit_tax_share_rev_pct", "working_age_pop_15_64_pct",
  "income_group_num", "is_oecd", "wave_index"
)

prep_matrix <- function(d, cols, ref_d = d) {
  out_list <- list()
  for (col in cols) {
    v <- as.numeric(d[[col]])
    v_ref <- as.numeric(ref_d[[col]])
    med <- median(v_ref, na.rm = TRUE)
    if (is.na(med)) med <- 0.0
    out_list[[col]] <- ifelse(is.na(v), med, v)
  }
  as.matrix(as.data.frame(out_list))
}

prep_matrix_oof <- function(d, cols, fold_col = "country_fold") {
  out_mat <- matrix(NA_real_, nrow = nrow(d), ncol = length(cols))
  colnames(out_mat) <- cols
  folds <- sort(unique(d[[fold_col]]))
  for (f in folds) {
    tr_idx <- which(d[[fold_col]] != f)
    te_idx <- which(d[[fold_col]] == f)
    for (j in seq_along(cols)) {
      col <- cols[j]
      v_tr <- as.numeric(d[[col]][tr_idx])
      v_te <- as.numeric(d[[col]][te_idx])
      med_tr <- median(v_tr, na.rm = TRUE)
      if (is.na(med_tr)) med_tr <- 0.0
      out_mat[te_idx, j] <- ifelse(is.na(v_te), med_tr, v_te)
    }
  }
  out_mat
}

estimate_rf_z_hat <- function(d, Z, ps_cols = base_con_vars, country_cv = TRUE, seed = 20261103) {
  if (country_cv && length(unique(d$country_fold)) > 1) {
    X_ps <- prep_matrix_oof(d, ps_cols)
    z_hat <- numeric(nrow(d))
    for (f in sort(unique(d$country_fold))) {
      tr <- which(d$country_fold != f)
      te <- which(d$country_fold == f)
      rf_f <- ranger(
        Z_target ~ .,
        data = data.frame(Z_target = Z[tr], X_ps[tr, , drop = FALSE]),
        num.trees = 500, mtry = floor(sqrt(ncol(X_ps))), min.node.size = 15, seed = seed + f
      )
      z_hat[te] <- as.numeric(predict(rf_f, data = data.frame(X_ps[te, , drop = FALSE]))$predictions)
    }
    return(z_hat)
  } else {
    X_ps <- prep_matrix(d, ps_cols)
    rf_fit <- ranger(
      Z_target ~ .,
      data = data.frame(Z_target = Z, X_ps),
      num.trees = 500, mtry = floor(sqrt(ncol(X_ps))), min.node.size = 15, seed = seed
    )
    return(as.numeric(rf_fit$predictions))
  }
}

calc_ess_single <- function(x) {
  n <- length(x)
  if (sd(x) == 0) return(n)
  ac <- acf(x, lag.max = min(80, floor(n / 4)), plot = FALSE)$acf[-1]
  pos_ac <- ac[seq_len(which(c(ac < 0, TRUE))[1] - 1)]
  max(10, min(n, n / (1 + 2 * sum(pos_ac))))
}

calc_gelman_rubin <- function(chains_mat) {
  # chains_mat: M chains (rows) x N_post draws (cols)
  M <- nrow(chains_mat)
  N <- ncol(chains_mat)
  chain_means <- rowMeans(chains_mat)
  chain_vars  <- apply(chains_mat, 1, var)
  W <- mean(chain_vars)
  B <- N * var(chain_means)
  var_hat <- ((N - 1) / N) * W + (1 / N) * B
  sqrt(var_hat / max(W, 1e-12))
}

calc_gaussian_crps <- function(y_true, mu_pred, sd_pred) {
  z <- (y_true - mu_pred) / pmax(sd_pred, 1e-6)
  sd_pred * (z * (2 * pnorm(z) - 1) + 2 * dnorm(z) - 1 / sqrt(pi))
}

# ==============================================================================
# 1. Four-Chain Multi-Chain MCMC Verification (4 chains x 3,000 iter = 8,000 post-burn-in draws)
# ==============================================================================
cat("\n1. Running 4-chain dispersed MCMC verification (4 x 3,000 iterations = 8,000 retained draws)...\n")

run_multichain_audit <- function(y_cols, extra_con, horizon_label, seeds = c(20261103, 20262207, 20263311, 20264419)) {
  keep <- complete.cases(df[, c(y_cols, "Z_cont_10pp")])
  d <- df[keep, , drop = FALSE]
  Y <- as.matrix(d[, y_cols, drop = FALSE])
  Z <- as.numeric(d$Z_cont_10pp)
  use_con <- unique(c(base_con_vars, extra_con))
  X_mu  <- prep_matrix_oof(d, use_con)
  X_mod <- prep_matrix_oof(d, base_mod_vars)
  z_hat <- estimate_rf_z_hat(d, Z, base_con_vars, country_cv = TRUE, seed = seeds[1])
  X_con <- as.matrix(cbind(X_mu, z_hat = z_hat))

  n_iter <- 3000
  n_burn <- 1000
  post_idx <- (n_burn + 1):n_iter
  n_post <- length(post_idx)
  M <- length(seeds)

  ate_chains <- array(NA_real_, dim = c(M, 4, n_post))
  for (m in seq_len(M)) {
    cat(sprintf("   Fitting %s chain %d/%d (seed %d)...\n", horizon_label, m, M, seeds[m]))
    set.seed(seeds[m])
    fit_m <- run_mvbcf(
      X_con = X_con, y = Y, Z = Z, X_mod = X_mod,
      alpha_tau = 0.25, beta_tau = 3.0, v_0 = 6,
      n_iter = n_iter, n_tree = 75, n_tree_tau = 30, min_nodesize = 3
    )
    for (j in 1:4) {
      ate_chains[m, j, ] <- colMeans(fit_m$predictions_tau[, j, post_idx, drop = FALSE])
    }
  }

  out_rows <- list()
  for (j in 1:4) {
    ch_mat <- ate_chains[, j, ]
    pooled <- as.numeric(t(ch_mat))
    rhat_mc <- calc_gelman_rubin(ch_mat)
    ess_mc  <- sum(apply(ch_mat, 1, calc_ess_single))
    mn <- mean(pooled)
    sd_p <- sd(pooled)
    p_pos <- mean(pooled > 0)
    mcse_mean <- sd_p / sqrt(ess_mc)
    mcse_prob <- sqrt(max(p_pos * (1 - p_pos), 1e-6) / ess_mc)
    out_rows[[j]] <- tibble(
      horizon = horizon_label,
      n_obs = nrow(d),
      n_chains = M,
      n_iter_per_chain = n_iter,
      n_retained_total = M * n_post,
      outcome_index = j,
      outcome = outcome_labels[j],
      outcome_code = outcome_short[j],
      ate_mean_4chain = round(mn, 3),
      ate_sd_4chain = round(sd_p, 3),
      ci95_low_4chain = round(as.numeric(quantile(pooled, 0.025)), 3),
      ci95_high_4chain = round(as.numeric(quantile(pooled, 0.975)), 3),
      prob_pos_4chain = round(p_pos, 3),
      rhat_4chain = round(rhat_mc, 3),
      ess_4chain = round(ess_mc, 0),
      mcse_mean_4chain = round(mcse_mean, 4),
      mcse_prob_4chain = round(mcse_prob, 3)
    )
  }
  bind_rows(out_rows)
}

mc_5y  <- run_multichain_audit(y5_cols, mediators_5y, "+5y (N=371)")
mc_10y <- run_multichain_audit(y10_cols, mediators_10y, "+10y (N=283)")
multichain_tbl <- bind_rows(mc_5y, mc_10y)
write_csv(multichain_tbl, file.path(out_tab_dir, "tableA5_multichain_mcmc_diagnostics.csv"))
print(multichain_tbl)

# ==============================================================================
# 2. Prognostic-Only (tau == 0) MV-BCF CV & Holdout Ablation + Out-of-Sample R^2
# ==============================================================================
cat("\n2. Running Prognostic-Only MV-BCF (tau = 0, treatment forest switched off) across CV & Holdout splits...\n")

eval_tau0_split <- function(d_full, y_cols, extra_con, test_mask, split_label, seed = 20261103) {
  keep <- complete.cases(d_full[, c(y_cols, "Z_cont_10pp", "Z_cont_log25pct")])
  d <- d_full[keep, , drop = FALSE]
  tr_idx <- which(!test_mask[keep])
  te_idx <- which(test_mask[keep])
  d_tr <- d[tr_idx, , drop = FALSE]
  d_te <- d[te_idx, , drop = FALSE]

  use_con <- unique(c(base_con_vars, extra_con))
  X_mu_tr <- prep_matrix(d_tr, use_con, ref_d = d_tr)
  X_mu_te <- prep_matrix(d_te, use_con, ref_d = d_tr)
  X_ps_tr <- prep_matrix(d_tr, base_con_vars, ref_d = d_tr)
  X_ps_te <- prep_matrix(d_te, base_con_vars, ref_d = d_tr)

  Y_tr <- as.matrix(d_tr[, y_cols, drop = FALSE])
  Y_te <- as.matrix(d_te[, y_cols, drop = FALSE])
  ZA_tr <- as.numeric(d_tr$Z_cont_10pp)

  z_hat_tr <- estimate_rf_z_hat(d_tr, ZA_tr, base_con_vars, country_cv = TRUE, seed = seed)
  rf_full_tr <- ranger(
    Z_target ~ ., data = data.frame(Z_target = ZA_tr, X_ps_tr),
    num.trees = 500, mtry = floor(sqrt(ncol(X_ps_tr))), min.node.size = 15, seed = seed
  )
  z_hat_te <- as.numeric(predict(rf_full_tr, data = data.frame(X_ps_te))$predictions)

  X_con_A_tr <- cbind(X_mu_tr, z_hat = z_hat_tr)
  X_con_A_te <- cbind(X_mu_te, z_hat = z_hat_te)
  X_mod_dum_tr <- matrix(1, nrow = nrow(d_tr), ncol = 1)
  X_mod_dum_te <- matrix(1, nrow = nrow(d_te), ncol = 1)

  # Identical 75 prognostic trees on (X, M, z_hat) with treatment forest switched off (Z = 0)
  set.seed(seed + 500)
  fit_tau0 <- run_mvbcf(
    X_con = X_con_A_tr, y = Y_tr, Z = rep(0, nrow(d_tr)), X_mod = X_mod_dum_tr,
    X_con_test = X_con_A_te, X_mod_test = X_mod_dum_te,
    n_iter = 1500, n_tree = 75, n_tree_tau = 1, min_nodesize = 3
  )
  post <- 501:1500

  rows <- list()
  for (j in 1:4) {
    y_true <- Y_te[, j]
    pred_mat <- fit_tau0$predictions_test[, j, post]
    sig_v <- sqrt(fit_tau0$sigmas[j, j, post])
    yh <- rowMeans(pred_mat)
    sdh <- sqrt(apply(pred_mat, 1, var) + mean(sig_v^2))
    rows[[j]] <- tibble(
      split_type = split_label,
      iso3 = d_te$iso3,
      wave_label = d_te$wave_label,
      model = "9. MV-BCF Prognostic-Only (tau = 0)",
      outcome_index = j,
      outcome = outcome_labels[j],
      outcome_code = outcome_short[j],
      sq_err = (y_true - yh)^2,
      abs_err = abs(y_true - yh),
      crps = calc_gaussian_crps(y_true, yh, sdh),
      cov80 = as.numeric(abs(y_true - yh) <= 1.28155 * sdh),
      cov95 = as.numeric(abs(y_true - yh) <= 1.95996 * sdh)
    )
  }
  bind_rows(rows)
}

t0_h10 <- eval_tau0_split(df, y10_cols, mediators_10y, df$is_holdout_test == 1L,
                          "Locked 20% Holdout Test Countries (Fold 5, +10y)", seed = 20261103)
t0_h5  <- eval_tau0_split(df, y5_cols, mediators_5y, df$is_holdout_test == 1L,
                          "Locked 20% Holdout Test Countries (Fold 5, +5y)", seed = 20261150)
t0_cv5 <- bind_rows(lapply(1:5, function(f) {
  eval_tau0_split(df, y10_cols, mediators_10y, df$country_fold == f,
                  "5-Fold Country-Blocked CV (All 112 Countries, +10y)", seed = 20261200 + f)
}))

t0_all <- bind_rows(t0_cv5, t0_h10, t0_h5)

hv_existing <- read_csv(file.path(out_tab_dir, "table_holdout_country_validation.csv"), show_col_types = FALSE) %>%
  filter(model != "9. MV-BCF Prognostic-Only (tau = 0)") %>%
  select(-any_of(c("r2_oos_vs_mean", "r2_oos_vs_zero")))

ref_mvA <- hv_existing %>%
  filter(model == "1. MV-BCF Scaling A (Z_cont_10pp)") %>%
  select(split_type, outcome_index, ref_crps_mean = crps)

t0_sum <- t0_all %>%
  group_by(split_type, model, outcome_index, outcome, outcome_code) %>%
  summarise(
    n_obs = n(),
    n_countries = n_distinct(iso3),
    rmse = round(sqrt(mean(sq_err)), 3),
    mae = round(mean(abs_err), 3),
    crps = round(mean(crps), 3),
    cov80_pct = round(100 * mean(cov80), 1),
    cov95_pct = round(100 * mean(cov95), 1),
    mean_tau_pred = 0.0,
    .groups = "drop"
  ) %>%
  left_join(ref_mvA, by = c("split_type", "outcome_index")) %>%
  mutate(
    crps_diff_vs_mvbcf_A = round(crps - ref_crps_mean, 3),
    dm_p_val = NA_real_
  ) %>%
  select(-ref_crps_mean)

hv_combined <- bind_rows(hv_existing, t0_sum)

mean_lookup <- hv_combined %>%
  filter(model == "7. Historical Training Mean") %>%
  select(split_type, outcome_index, rmse_mean = rmse)

zero_lookup <- hv_combined %>%
  filter(model == "8. Zero-Change Baseline (Delta Y = 0)") %>%
  select(split_type, outcome_index, rmse_zero = rmse)

hv_final <- hv_combined %>%
  left_join(mean_lookup, by = c("split_type", "outcome_index")) %>%
  left_join(zero_lookup, by = c("split_type", "outcome_index")) %>%
  mutate(
    r2_oos_vs_mean = round(1 - (rmse^2 / rmse_mean^2), 3),
    r2_oos_vs_zero = round(1 - (rmse^2 / rmse_zero^2), 3)
  ) %>%
  select(-rmse_mean, -rmse_zero) %>%
  arrange(split_type, outcome_index, model)

write_csv(hv_final, file.path(out_tab_dir, "table_holdout_country_validation.csv"))
cat("\n=== Prognostic-Only (tau = 0) vs Full MV-BCF Summary ===\n")
print(hv_final %>% filter(grepl("MV-BCF|Historical", model)) %>%
        select(split_type, model, outcome_index, outcome_code, rmse, r2_oos_vs_mean, crps, cov95_pct), n = 40)

# ==============================================================================
# 3. Export Extended Residual Diagnostics (Wave ANOVA, Lag-1 ACF, Income-Tier SD, Calibration)
# ==============================================================================
res_df <- read_csv(file.path(proc_dir, "mvbcf_residuals_and_fit.csv"), show_col_types = FALSE)
d10 <- res_df %>% filter(scaling == "Scaling A (+10 pp GDP/pc)", grepl("Mediator", specification), horizon == "+10 years")
d5  <- res_df %>% filter(scaling == "Scaling A (+10 pp GDP/pc)", grepl("Mediator", specification), horizon == "+5 years")

diag_rows <- list()
for (oc in outcome_short) {
  s10 <- d10 %>% filter(outcome_code == oc) %>% arrange(iso3, wave_label)
  s5  <- d5  %>% filter(outcome_code == oc) %>% arrange(iso3, wave_label)

  p_wave_10 <- summary(aov(resid ~ factor(wave_label), data = s10))[[1]][["Pr(>F)"]][1]
  p_wave_5  <- summary(aov(resid ~ factor(wave_label), data = s5))[[1]][["Pr(>F)"]][1]

  s10_lag <- s10 %>% group_by(iso3) %>% mutate(lr = lag(resid)) %>% ungroup() %>% filter(!is.na(lr))
  s5_lag  <- s5  %>% group_by(iso3) %>% mutate(lr = lag(resid)) %>% ungroup() %>% filter(!is.na(lr))

  ig_sds <- s10 %>% group_by(income_group) %>% summarise(s = round(sd(resid), 2), .groups = "drop")
  sd_map <- setNames(ig_sds$s, ig_sds$income_group)

  diag_rows[[length(diag_rows) + 1]] <- tibble(
    outcome_code = oc,
    wave_anova_p_5y = round(p_wave_5, 3),
    wave_anova_p_10y = round(p_wave_10, 3),
    max_abs_wave_mean_10y = round(max(abs(tapply(s10$resid, s10$wave_label, mean))), 2),
    lag1_acf_5y_nonoverlap = round(cor(s5_lag$resid, s5_lag$lr), 3),
    lag1_acf_5y_p = round(cor.test(s5_lag$resid, s5_lag$lr)$p.value, 3),
    lag1_acf_10y_overlap = round(cor(s10_lag$resid, s10_lag$lr), 3),
    lag1_acf_10y_p = round(cor.test(s10_lag$resid, s10_lag$lr)$p.value, 3),
    sd_low_10y = sd_map[["Low income"]],
    sd_lowermid_10y = sd_map[["Lower middle income"]],
    sd_uppermid_10y = sd_map[["Upper middle income"]],
    sd_high_10y = sd_map[["High income"]]
  )
}
ext_diag_tbl <- bind_rows(diag_rows)
write_csv(ext_diag_tbl, file.path(out_tab_dir, "tableA6_extended_residual_diagnostics.csv"))
cat("\n=== Extended Residual Diagnostics Summary ===\n")
print(ext_diag_tbl)
