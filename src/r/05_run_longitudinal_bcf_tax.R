#!/usr/bin/env Rscript
# ==============================================================================
# Step 05: Three-Wave Longitudinal Bayesian Causal Forest (LBCF) Tax Trajectories
# (src/r/05_run_longitudinal_bcf_tax.R)
#
# Models the 3-wave fiscal trajectory (Wave 0 = baseline t, Wave 1 = t+1 (+5y),
# Wave 2 = t+2 (+10y)) using fast_lbcf3 (src/cpp/lbcf_3wave.cpp).
#   - Removes the baseline level y0 of the target outcome from X_mu_stack so
#     the baseline prognostic forest mu_0(X) cannot tautologically split on y0.
#   - Evaluates Mediator-Adjusted Direct Longitudinal Trajectories across all
#     four disaggregated tax channels with country-clustered credible intervals.
# ==============================================================================

t_start_lbcf <- Sys.time()

suppressPackageStartupMessages({
  library(Rcpp)
  library(dplyr)
  library(tidyr)
  library(readr)
})

set.seed(20261104)

repo_root <- getwd()
if (!dir.exists(file.path(repo_root, "src")) && dir.exists(file.path(dirname(dirname(repo_root)), "src"))) {
  repo_root <- dirname(dirname(repo_root))
}
Sys.setenv(R_MAKEVARS_USER = file.path(repo_root, "src", "cpp", "Makevars"))

proc_dir    <- file.path(repo_root, "data", "processed")
out_tab_dir <- file.path(repo_root, "outputs", "tables")
res_tab_dir <- file.path(repo_root, "results", "tables")
out_mod_dir <- file.path(repo_root, "outputs", "models")
res_mod_dir <- file.path(repo_root, "results", "models")

for (d in c(out_tab_dir, res_tab_dir, out_mod_dir, res_mod_dir)) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
}

cat("Compiling 3-Wave Longitudinal BCF C++ engine (lbcf_3wave.cpp)...\n")
sourceCpp(file.path(repo_root, "src", "cpp", "lbcf_3wave.cpp"),
          cacheDir = "/tmp/rcpp_cache_edu_tax_bcf", verbose = FALSE)
cat("3-Wave Longitudinal BCF compiled and loaded.\n\n")

df <- read_csv(file.path(proc_dir, "clean_tax_panel.csv"), show_col_types = FALSE) %>%
  mutate(
    income_group_num = as.numeric(factor(income_group, levels = c(
      "Low income", "Lower middle income", "Upper middle income", "High income"
    ))),
    region_num = as.numeric(factor(region)),
    d_inc_log_gdp_pc_pct = d_t2_log_gdp_pc_pct - d_t1_log_gdp_pc_pct,
    d_inc_tert_enrol_pp  = d_t2_tert_enrol_pp  - d_t1_tert_enrol_pp,
    d_inc_gini_disp      = d_t2_gini_disp      - d_t1_gini_disp,
    d_inc_life_exp_yrs   = d_t2_life_exp_yrs   - d_t1_life_exp_yrs
  )

req_cols <- c(
  "Z_regime_inc",
  "non_resource_tax_gdp_pct", "d_t1_nonres_tax_gdp_pp", "d_t2_nonres_tax_gdp_pp",
  "inc_tax_gdp_pct",          "d_t1_inc_tax_gdp_pp",    "d_t2_inc_tax_gdp_pp",
  "income_profit_tax_share_rev_pct", "d_t1_inc_tax_share_pp", "d_t2_inc_tax_share_pp",
  "goods_services_tax_share_rev_pct","d_t1_goods_tax_share_pp","d_t2_goods_tax_share_pp"
)

df_l <- df %>% filter(complete.cases(across(all_of(req_cols))))
n <- nrow(df_l)
cat(sprintf("Fitting 3-Wave Longitudinal BCF on N = %d country-wave trajectories across %d countries...\n",
            n, n_distinct(df_l$iso3)))

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

# Non-outcome baseline covariates (excluding the 4 fiscal outcome baseline levels to prevent y0 duplication)
clean_mu_vars <- c(
  "log_gdp_pc_ppp",
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

# Wave 1 growth forest receives ONLY Wave 1 (+5y) mediators (no Wave 2 future leakage)
growth_vars_w1 <- c(
  clean_mu_vars,
  "d_t1_log_gdp_pc_pct", "d_t1_tert_enrol_pp",
  "d_t1_gini_disp", "d_t1_life_exp_yrs"
)

# Wave 2 growth forest receives Wave 1 mediators + Wave 2 incremental (+5y to +10y) mediators
growth_vars_w2 <- c(
  clean_mu_vars,
  "d_t1_log_gdp_pc_pct", "d_t1_tert_enrol_pp",
  "d_t1_gini_disp", "d_t1_life_exp_yrs",
  "d_inc_log_gdp_pc_pct", "d_inc_tert_enrol_pp",
  "d_inc_gini_disp", "d_inc_life_exp_yrs"
)

treat_vars <- c(
  "gross_tert_enrolment_pct",
  "log_gdp_pc_ppp",
  "gross_seco_enrolment_pct",
  "working_age_pop_15_64_pct",
  "income_group_num",
  "is_oecd",
  "wave_index"
)

X_mu_base    <- prep_matrix(df_l, clean_mu_vars)
X_grow_w1    <- prep_matrix(df_l, growth_vars_w1)
X_grow_w2    <- prep_matrix(df_l, growth_vars_w2)
X_treat_base <- prep_matrix(df_l, treat_vars)

# Pre-treatment propensity score pi_hat(X)
df_ps <- as.data.frame(X_mu_base)
df_ps$Z_target <- as.numeric(df_l$Z_regime_inc)
ps_fit <- suppressWarnings(glm(Z_target ~ ., data = df_ps, family = binomial()))
pi_hat <- pmin(pmax(predict(ps_fit, type = "response"), 0.02), 0.98)

X_grow_w1_ps <- as.matrix(cbind(X_grow_w1, pi_hat = pi_hat))
X_grow_w2_ps <- as.matrix(cbind(X_grow_w2, pi_hat = pi_hat))

# Stack ONLY the two active stochastic transition waves (Wave 1 = +5y change, Wave 2 = +10y change;
# 2 * n = 564 rows total), completely excluding the degenerate Wave 0 (Y_{i,0} - Y_{i,0} = 0) rows
# from the likelihood and residual variance estimation:
#   Wave 1 (w=1): Delta Y_{i,t+1} = mu_1(X_{i,t}, pi_hat, M_{i,1}) + tau_1(W_{i,t}) Z_{i,t} + eps_{i,1}
#   Wave 2 (w=2): Delta Y_{i,t+2} = mu_1(...) + tau_1(...) Z_{i,t} + mu_2(X_{i,t}, pi_hat, M_{i,1}, M_{i,2}) + tau_2(W_{i,t}) Z_{i,t} + eps_{i,2}
X_mu_stack      <- rbind(X_grow_w1_ps, X_grow_w1_ps)
X_growth_stack1 <- rbind(X_grow_w1_ps, X_grow_w1_ps)
X_growth_stack2 <- rbind(X_grow_w2_ps, X_grow_w2_ps)
X_treat_stack   <- rbind(X_treat_base, X_treat_base)

Z_vec     <- as.numeric(df_l$Z_regime_inc)
Z_growth1 <- rep(0, 2 * n)
Z_growth2 <- c(rep(0, n), rep(1, n))
Z_treat1  <- c(Z_vec, Z_vec)
Z_treat2  <- c(rep(0, n), Z_vec)

# Unified ESS, split-Rhat, and Geweke diagnostics for LBCF
calc_ess <- function(x) {
  len <- length(x)
  if (sd(x) == 0) return(len)
  ac <- acf(x, lag.max = min(50, floor(len / 4)), plot = FALSE)$acf[-1]
  pos_ac <- ac[seq_len(which(c(ac < 0, TRUE))[1] - 1)]
  max(10, min(len, len / (1 + 2 * sum(pos_ac))))
}

calc_split_rhat <- function(x) {
  len <- length(x)
  half <- floor(len / 2)
  c1 <- x[1:half]
  c2 <- x[(half + 1):(2 * half)]
  W <- 0.5 * (var(c1) + var(c2))
  if (W <= 0) return(1.0)
  B <- half * var(c(mean(c1), mean(c2)))
  var_hat <- ((half - 1) / half) * W + (1 / half) * B
  sqrt(var_hat / W)
}

calc_geweke_z <- function(x) {
  len <- length(x)
  n1 <- floor(0.1 * len)
  n2 <- floor(0.5 * len)
  x1 <- x[1:n1]
  x2 <- x[(len - n2 + 1):len]
  se1 <- sd(x1) / sqrt(calc_ess(x1))
  se2 <- sd(x2) / sqrt(calc_ess(x2))
  if ((se1^2 + se2^2) <= 0) return(0.0)
  (mean(x1) - mean(x2)) / sqrt(se1^2 + se2^2)
}

outcomes_spec <- list(
  list(
    code  = "tax_gdp_pp",
    label = "Non-Resource Tax / GDP (pp)",
    y1    = df_l$d_t1_nonres_tax_gdp_pp,
    y2    = df_l$d_t2_nonres_tax_gdp_pp
  ),
  list(
    code  = "inc_tax_gdp_pp",
    label = "Direct Income & Profit Tax / GDP (pp)",
    y1    = df_l$d_t1_inc_tax_gdp_pp,
    y2    = df_l$d_t2_inc_tax_gdp_pp
  ),
  list(
    code  = "inc_tax_share_pp",
    label = "Direct Income & Profit Share of Revenue (pp)",
    y1    = df_l$d_t1_inc_tax_share_pp,
    y2    = df_l$d_t2_inc_tax_share_pp
  ),
  list(
    code  = "goods_tax_share_pp",
    label = "Goods & Services Tax Share of Revenue (pp)",
    y1    = df_l$d_t1_goods_tax_share_pp,
    y2    = df_l$d_t2_goods_tax_share_pp
  )
)

n_iter        <- 2500
n_burn        <- 1000
post_idx      <- (n_burn + 1):n_iter
n_post        <- length(post_idx)
n_tree_mu     <- 75
n_tree_growth <- 45
n_tree_treat  <- 30
growth_sigma  <- 0.50
treat_sigma   <- 0.25

clusters <- unique(df_l$iso3)
n_clus   <- length(clusters)
clus_idx <- match(df_l$iso3, clusters)
exp_mat  <- matrix(rexp(n_clus * n_post, rate = 1.0), nrow = n_clus, ncol = n_post)
obs_w    <- exp_mat[clus_idx, , drop = FALSE]
obs_w    <- sweep(obs_w, 2, colSums(obs_w), "/")

lbcf_rows  <- list()
lbcf_draws <- list()

for (k in seq_along(outcomes_spec)) {
  set.seed(20261104 + k * 101)
  spec   <- outcomes_spec[[k]]
  y_vals <- c(spec$y1, spec$y2)

  cat(sprintf("Running Non-Degenerate Two-Increment LBCF for Outcome %d/4: %s...\n", k, spec$label))
  fit_lbcf <- fast_lbcf3(
    X_mu_stack, y_vals,
    Z_growth1, Z_treat1, X_growth_stack1, X_treat_stack,
    Z_growth2, Z_treat2, X_growth_stack2, X_treat_stack,
    X_mu_stack, X_growth_stack1, X_treat_stack, X_growth_stack2, X_treat_stack,
    0.95, 2.0,
    0.95, 2.0,
    0.25, 3.0,
    n_tree_mu,
    n_tree_growth / (growth_sigma^2),
    n_tree_treat / (treat_sigma^2),
    3.0, 0.1,
    n_iter,
    n_tree_mu, n_tree_growth, n_tree_treat,
    3
  )

  idx_w1 <- 1:n
  idx_w2 <- (n + 1):(2 * n)

  tau1_mat    <- fit_lbcf$predictions_treat[idx_w1, post_idx]
  tau2_mat    <- fit_lbcf$predictions_treat2[idx_w2, post_idx]
  tau_cum_mat <- tau1_mat + tau2_mat

  ate_w1_draws  <- colMeans(tau1_mat)
  ate_w2_draws  <- colMeans(tau2_mat)
  ate_cum_draws <- colMeans(tau_cum_mat)
  sig_draws     <- fit_lbcf$sigmas[post_idx]

  # Posterior predictive check on cumulative 10y transition (idx_w2)
  pred_w2_mat <- fit_lbcf$predictions_mu[idx_w2, post_idx] +
                 Z_vec * tau1_mat +
                 fit_lbcf$predictions_growth2[idx_w2, post_idx] +
                 Z_vec * tau2_mat
  y_w2_obs    <- spec$y2
  y_w2_hat    <- rowMeans(pred_w2_mat)
  ppc_rmse    <- sqrt(mean((y_w2_obs - y_w2_hat)^2))
  ppc_r2      <- max(0, 1 - sum((y_w2_obs - y_w2_hat)^2) / sum((y_w2_obs - mean(y_w2_obs))^2))
  eps_mat     <- matrix(rnorm(n * n_post), nrow = n, ncol = n_post)
  y_rep_mat   <- pred_w2_mat + sweep(eps_mat, 2, sig_draws, "*")
  q_low       <- apply(y_rep_mat, 1, quantile, probs = 0.025)
  q_high      <- apply(y_rep_mat, 1, quantile, probs = 0.975)
  ppc_cov95   <- round(100 * mean(y_w2_obs >= q_low & y_w2_obs <= q_high), 1)

  lbcf_draws[[spec$code]] <- list(
    ate_w1_draws  = ate_w1_draws,
    ate_w2_draws  = ate_w2_draws,
    ate_cum_draws = ate_cum_draws,
    tau1_mat      = tau1_mat,
    tau2_mat      = tau2_mat,
    tau_cum_mat   = tau_cum_mat,
    sigmas        = sig_draws,
    ppc_rmse      = round(ppc_rmse, 2),
    ppc_r2        = round(ppc_r2, 3),
    ppc_cov95_pct = ppc_cov95
  )

  clu_w1_draws  <- colSums(tau1_mat * obs_w)
  clu_w2_draws  <- colSums(tau2_mat * obs_w)
  clu_cum_draws <- colSums(tau_cum_mat * obs_w)

  df_l[[paste0("lbcf_tau1_", spec$code)]]          <- rowMeans(tau1_mat)
  df_l[[paste0("lbcf_tau1_sd_", spec$code)]]       <- apply(tau1_mat, 1, sd)
  df_l[[paste0("lbcf_tau1_low80_", spec$code)]]    <- apply(tau1_mat, 1, quantile, probs = 0.10)
  df_l[[paste0("lbcf_tau1_high80_", spec$code)]]   <- apply(tau1_mat, 1, quantile, probs = 0.90)
  df_l[[paste0("lbcf_tau1_low95_", spec$code)]]    <- apply(tau1_mat, 1, quantile, probs = 0.025)
  df_l[[paste0("lbcf_tau1_high95_", spec$code)]]   <- apply(tau1_mat, 1, quantile, probs = 0.975)

  df_l[[paste0("lbcf_tau2_", spec$code)]]          <- rowMeans(tau2_mat)
  df_l[[paste0("lbcf_tau_cum_", spec$code)]]       <- rowMeans(tau_cum_mat)
  df_l[[paste0("lbcf_tau_cum_sd_", spec$code)]]    <- apply(tau_cum_mat, 1, sd)
  df_l[[paste0("lbcf_tau_cum_low80_", spec$code)]] <- apply(tau_cum_mat, 1, quantile, probs = 0.10)
  df_l[[paste0("lbcf_tau_cum_high80_", spec$code)]]<- apply(tau_cum_mat, 1, quantile, probs = 0.90)
  df_l[[paste0("lbcf_tau_cum_low95_", spec$code)]] <- apply(tau_cum_mat, 1, quantile, probs = 0.025)
  df_l[[paste0("lbcf_tau_cum_high95_", spec$code)]]<- apply(tau_cum_mat, 1, quantile, probs = 0.975)

  ess_cum <- calc_ess(ate_cum_draws)
  lbcf_rows[[k]] <- tibble(
    outcome_code       = spec$code,
    outcome            = spec$label,
    n_trajectories     = n,
    n_countries        = n_clus,
    ate_5y_mean        = round(mean(ate_w1_draws), 3),
    ate_5y_sd          = round(sd(ate_w1_draws), 3),
    ate_5y_low80       = round(quantile(ate_w1_draws, 0.10), 3),
    ate_5y_high80      = round(quantile(ate_w1_draws, 0.90), 3),
    ate_5y_low         = round(quantile(ate_w1_draws, 0.025), 3),
    ate_5y_high        = round(quantile(ate_w1_draws, 0.975), 3),
    prob_5y_pos        = round(mean(ate_w1_draws > 0), 3),
    ate_inc_5to10_mean = round(mean(ate_w2_draws), 3),
    ate_inc_5to10_sd   = round(sd(ate_w2_draws), 3),
    ate_inc_5to10_low80  = round(quantile(ate_w2_draws, 0.10), 3),
    ate_inc_5to10_high80 = round(quantile(ate_w2_draws, 0.90), 3),
    ate_inc_5to10_low  = round(quantile(ate_w2_draws, 0.025), 3),
    ate_inc_5to10_high = round(quantile(ate_w2_draws, 0.975), 3),
    prob_inc_pos       = round(mean(ate_w2_draws > 0), 3),
    ate_cum_10y_mean   = round(mean(ate_cum_draws), 3),
    ate_cum_10y_sd     = round(sd(ate_cum_draws), 3),
    ate_cum_10y_low80  = round(quantile(ate_cum_draws, 0.10), 3),
    ate_cum_10y_high80 = round(quantile(ate_cum_draws, 0.90), 3),
    ate_cum_10y_low    = round(quantile(ate_cum_draws, 0.025), 3),
    ate_cum_10y_high   = round(quantile(ate_cum_draws, 0.975), 3),
    prob_cum_10y_pos   = round(mean(ate_cum_draws > 0), 3),
    clu_cum_10y_low    = round(quantile(clu_cum_draws, 0.025), 3),
    clu_cum_10y_high   = round(quantile(clu_cum_draws, 0.975), 3),
    clu_prob_cum_pos   = round(mean(clu_cum_draws > 0), 3),
    prob_both_steps_pos = round(mean(ate_w1_draws > 0 & ate_w2_draws > 0), 3),
    prob_compounding   = round(mean(ate_w1_draws > 0 & ate_w2_draws > 0), 3),
    split_rhat         = round(calc_split_rhat(ate_cum_draws), 3),
    ess_cum            = round(ess_cum, 0),
    mcse_cum           = round(sd(ate_cum_draws) / sqrt(ess_cum), 3),
    geweke_z_cum       = round(calc_geweke_z(ate_cum_draws), 2),
    ppc_rmse           = round(ppc_rmse, 2),
    ppc_r2             = round(ppc_r2, 3),
    ppc_cov95_pct      = ppc_cov95
  )
}

table5_lbcf <- bind_rows(lbcf_rows)
write_csv(table5_lbcf, file.path(out_tab_dir, "table5_longitudinal_bcf_trajectories.csv"))
write_csv(table5_lbcf, file.path(res_tab_dir, "table5_longitudinal_bcf_trajectories.csv"))
write_csv(df_l, file.path(proc_dir, "panel_longitudinal_3wave_predictions.csv"))
saveRDS(lbcf_draws, file.path(out_mod_dir, "lbcf_posterior_draws.rds"))
saveRDS(lbcf_draws, file.path(res_mod_dir, "lbcf_posterior_draws.rds"))

t_elapsed_lbcf <- as.numeric(difftime(Sys.time(), t_start_lbcf, units = "secs"))
meta_lines <- c(
  "{",
  '  "script": "src/r/05_run_longitudinal_bcf_tax.R",',
  '  "seed": 20261104,',
  sprintf('  "r_version": "%s",', R.version.string),
  sprintf('  "wall_clock_seconds": %.2f,', t_elapsed_lbcf),
  sprintf('  "timestamp_utc": "%s"', format(Sys.time(), tz = "UTC", usetz = TRUE)),
  "}"
)
writeLines(meta_lines, file.path(out_mod_dir, "lbcf_run_metadata.json"))
writeLines(meta_lines, file.path(res_mod_dir, "lbcf_run_metadata.json"))

cat("\n=== Table 5: Clean 3-Wave Longitudinal BCF Trajectory Summaries ===\n")
print(table5_lbcf)
cat(sprintf("\nStep 05 complete in %.1f seconds!\n", t_elapsed_lbcf))
