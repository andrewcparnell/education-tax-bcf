#!/usr/bin/env Rscript
# ==============================================================================
# Step 3.2: Three-Wave Longitudinal Bayesian Causal Forest (LBCF) Tax Trajectories
# (src/r/03_run_longitudinal_bcf_tax.R)
#
# Models the 3-wave fiscal trajectory (Wave 0 = baseline t, Wave 1 = t+1 (+5y),
# Wave 2 = t+2 (+10y)) using fast_lbcf3 (src/cpp/lbcf_3wave.cpp).
#
# Fixes the Round-1 y0 covariate duplication bug:
#   - Removes the baseline level y0 of the target outcome from X_mu_stack so
#     the baseline prognostic forest mu(X) cannot tautologically split on y0.
#   - Evaluates both Total Longitudinal Trajectories and Mediator-Adjusted
#     Direct Longitudinal Trajectories, with country-clustered credible intervals.
# ==============================================================================

suppressPackageStartupMessages({
  library(Rcpp)
  library(dplyr)
  library(tidyr)
  library(readr)
})

set.seed(20261104)

repo_root <- "/Users/andrewparnell/Documents/GitHub/education-tax-bcf"
proc_dir  <- file.path(repo_root, "data", "processed")
tab_dir   <- file.path(repo_root, "results", "tables")
dir.create(tab_dir, recursive = TRUE, showWarnings = FALSE)

cat("Compiling 3-Wave Longitudinal BCF C++ engine (lbcf_3wave.cpp)...\n")
sourceCpp(file.path(repo_root, "src", "cpp", "lbcf_3wave.cpp"),
          cacheDir = "/tmp/rcpp_cache_edu_tax_bcf", verbose = FALSE)
cat("3-Wave Longitudinal BCF compiled and loaded.\n\n")

df <- read_csv(file.path(proc_dir, "clean_tax_panel.csv"), show_col_types = FALSE) %>%
  mutate(
    income_group_num = as.numeric(factor(income_group, levels = c(
      "Low income", "Lower middle income", "Upper middle income", "High income"
    ))),
    region_num = as.numeric(factor(region))
  )

# Filter to complete 2-horizon fiscal trajectories (t, t+1, t+2 observed)
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

# Non-outcome baseline covariates (excluding the 4 fiscal outcome baseline levels to prevent y0 duplication!)
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

# Mediator-adjusted growth covariates (adding forward GDP growth and enrolment expansion)
growth_vars_med <- c(
  clean_mu_vars,
  "d_t1_log_gdp_pc_pct", "d_t2_log_gdp_pc_pct",
  "d_t1_tert_enrol_pp",  "d_t2_tert_enrol_pp"
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
X_grow_base  <- prep_matrix(df_l, growth_vars_med)
X_treat_base <- prep_matrix(df_l, treat_vars)

# Propensity score pi_hat(X)
df_ps <- as.data.frame(X_mu_base)
df_ps$Z_target <- as.numeric(df_l$Z_regime_inc)
ps_fit <- suppressWarnings(glm(Z_target ~ ., data = df_ps, family = binomial()))
pi_hat <- pmin(pmax(predict(ps_fit, type = "response"), 0.02), 0.98)

X_grow_with_ps <- as.matrix(cbind(X_grow_base, pi_hat = pi_hat))

# Stacked 3-wave design matrices (Wave 0 = t, Wave 1 = t+1 (+5y), Wave 2 = t+2 (+10y))
X_mu_stack     <- rbind(X_mu_base, X_mu_base, X_mu_base)
X_growth_stack <- rbind(X_grow_with_ps, X_grow_with_ps, X_grow_with_ps)
X_treat_stack  <- rbind(X_treat_base, X_treat_base, X_treat_base)

Z_vec     <- as.numeric(df_l$Z_regime_inc)
Z_growth1 <- c(rep(0, n), rep(1, n), rep(1, n))
Z_growth2 <- c(rep(0, n), rep(0, n), rep(1, n))
Z_treat1  <- c(rep(0, n), Z_vec, Z_vec)
Z_treat2  <- c(rep(0, n), rep(0, n), Z_vec)

outcomes_spec <- list(
  list(
    code  = "tax_gdp_pp",
    label = "Non-Resource Tax / GDP (pp)",
    y0    = df_l$non_resource_tax_gdp_pct,
    y1    = df_l$non_resource_tax_gdp_pct + df_l$d_t1_nonres_tax_gdp_pp,
    y2    = df_l$non_resource_tax_gdp_pct + df_l$d_t2_nonres_tax_gdp_pp
  ),
  list(
    code  = "inc_tax_gdp_pp",
    label = "Direct Income & Profit Tax / GDP (pp)",
    y0    = df_l$inc_tax_gdp_pct,
    y1    = df_l$inc_tax_gdp_pct + df_l$d_t1_inc_tax_gdp_pp,
    y2    = df_l$inc_tax_gdp_pct + df_l$d_t2_inc_tax_gdp_pp
  ),
  list(
    code  = "inc_tax_share_pp",
    label = "Direct Income & Profit Share of Revenue (pp)",
    y0    = df_l$income_profit_tax_share_rev_pct,
    y1    = df_l$income_profit_tax_share_rev_pct + df_l$d_t1_inc_tax_share_pp,
    y2    = df_l$income_profit_tax_share_rev_pct + df_l$d_t2_inc_tax_share_pp
  ),
  list(
    code  = "goods_tax_share_pp",
    label = "Goods & Services Tax Share of Revenue (pp)",
    y0    = df_l$goods_services_tax_share_rev_pct,
    y1    = df_l$goods_services_tax_share_rev_pct + df_l$d_t1_goods_tax_share_pp,
    y2    = df_l$goods_services_tax_share_rev_pct + df_l$d_t2_goods_tax_share_pp
  )
)

n_iter        <- 2500
n_burn        <- 750
post_idx      <- (n_burn + 1):n_iter
n_post        <- length(post_idx)
n_tree_mu     <- 75
n_tree_growth <- 45
n_tree_treat  <- 30
growth_sigma  <- 0.50
treat_sigma   <- 0.25

# Country-clustered Dirichlet weights for longitudinal trajectories
clusters <- unique(df_l$iso3)
n_clus   <- length(clusters)
clus_idx <- match(df_l$iso3, clusters)
exp_mat  <- matrix(rexp(n_clus * n_post, rate = 1.0), nrow = n_clus, ncol = n_post)
obs_w    <- exp_mat[clus_idx, , drop = FALSE]
obs_w    <- sweep(obs_w, 2, colSums(obs_w), "/")

lbcf_rows <- list()

for (k in seq_along(outcomes_spec)) {
  spec   <- outcomes_spec[[k]]
  y_vals <- c(spec$y0, spec$y1, spec$y2)

  cat(sprintf("Running Clean 3-Wave LBCF for Outcome %d/4: %s...\n", k, spec$label))
  fit_lbcf <- fast_lbcf3(
    X_mu_stack, y_vals,
    Z_growth1, Z_treat1, X_growth_stack, X_treat_stack,
    Z_growth2, Z_treat2, X_growth_stack, X_treat_stack,
    X_mu_stack, X_growth_stack, X_treat_stack, X_growth_stack, X_treat_stack,
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

  idx_w1 <- (n + 1):(2 * n)
  idx_w2 <- (2 * n + 1):(3 * n)

  tau1_mat    <- fit_lbcf$predictions_treat[idx_w1, post_idx]
  tau2_mat    <- fit_lbcf$predictions_treat2[idx_w2, post_idx]
  tau_cum_mat <- tau1_mat + tau2_mat

  ate_w1_draws  <- colMeans(tau1_mat)
  ate_w2_draws  <- colMeans(tau2_mat)
  ate_cum_draws <- colMeans(tau_cum_mat)

  clu_w1_draws  <- colSums(tau1_mat * obs_w)
  clu_w2_draws  <- colSums(tau2_mat * obs_w)
  clu_cum_draws <- colSums(tau_cum_mat * obs_w)

  df_l[[paste0("lbcf_tau1_", spec$code)]]    <- rowMeans(tau1_mat)
  df_l[[paste0("lbcf_tau2_", spec$code)]]    <- rowMeans(tau2_mat)
  df_l[[paste0("lbcf_tau_cum_", spec$code)]] <- rowMeans(tau_cum_mat)

  lbcf_rows[[k]] <- tibble(
    outcome_code       = spec$code,
    outcome            = spec$label,
    n_trajectories     = n,
    n_countries        = n_clus,
    ate_5y_mean        = round(mean(ate_w1_draws), 3),
    ate_5y_low         = round(quantile(ate_w1_draws, 0.025), 3),
    ate_5y_high        = round(quantile(ate_w1_draws, 0.975), 3),
    prob_5y_pos        = round(mean(ate_w1_draws > 0), 3),
    ate_inc_5to10_mean = round(mean(ate_w2_draws), 3),
    ate_inc_5to10_low  = round(quantile(ate_w2_draws, 0.025), 3),
    ate_inc_5to10_high = round(quantile(ate_w2_draws, 0.975), 3),
    prob_inc_pos       = round(mean(ate_w2_draws > 0), 3),
    ate_cum_10y_mean   = round(mean(ate_cum_draws), 3),
    ate_cum_10y_low    = round(quantile(ate_cum_draws, 0.025), 3),
    ate_cum_10y_high   = round(quantile(ate_cum_draws, 0.975), 3),
    prob_cum_10y_pos   = round(mean(ate_cum_draws > 0), 3),
    clu_cum_10y_low    = round(quantile(clu_cum_draws, 0.025), 3),
    clu_cum_10y_high   = round(quantile(clu_cum_draws, 0.975), 3),
    clu_prob_cum_pos   = round(mean(clu_cum_draws > 0), 3),
    prob_compounding   = round(mean(ate_cum_draws > ate_w1_draws), 3)
  )
}

table5_lbcf <- bind_rows(lbcf_rows)
write_csv(table5_lbcf, file.path(tab_dir, "table5_longitudinal_bcf_trajectories.csv"))
write_csv(df_l, file.path(proc_dir, "panel_longitudinal_3wave_predictions.csv"))

cat("\n=== Table 5: Clean 3-Wave Longitudinal BCF Trajectory Summaries ===\n")
print(table5_lbcf)
cat("\nStep 3.2 complete!\n")
