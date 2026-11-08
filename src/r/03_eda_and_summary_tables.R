#!/usr/bin/env Rscript
# ==============================================================================
# Step 03: Comprehensive Exploratory Data Analysis & Random Forest E[Z|X] Audit
# (src/r/03_eda_and_summary_tables.R)
#
# Strictly computed on the 80% Training Set (country_fold %in% 1:4; is_holdout_test == 0)
# while keeping the 20% Holdout Test Countries (country_fold == 5) locked until Phase 4.
#
# Generates all Phase 3 EDA tables and figures required by academic-paper-workflow:
#   - Table 0 (eda_table0_attrition_and_coverage.csv): Coverage, attrition & train/test split
#   - Table 1 (eda_table1_income_group_summary.csv): Unbundling continuous tertiary spending
#   - Table 2 (eda_table2_raw_fiscal_changes_by_regime.csv): Raw continuous slopes & tertile means
#   - Table 3 (eda_table3_positivity_and_overlap.csv): Random Forest E[Z|X] fit & residual support
#   - Table 4 (eda_table4_missingness_analysis.csv): Missing-data audit by variable & income tier
#   - Table 5 (eda_table5_temporal_and_spatial_structure.csv): ACF/PACF, stationarity & regional ICC
#   - Table 6 (eda_table6_vif_and_feature_correlations.csv): Baseline feature VIFs & target correlations
#   - Figures (eda_fig1, eda_fig2, eda_fig3) saved in outputs/figures/ and eda/figures/
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(ggplot2)
  library(ranger)
})

repo_root <- getwd()
if (!dir.exists(file.path(repo_root, "src")) && dir.exists(file.path(dirname(dirname(repo_root)), "src"))) {
  repo_root <- dirname(dirname(repo_root))
}
source(file.path(repo_root, "src", "r", "plot_theme.R"))

proc_dir    <- file.path(repo_root, "data", "processed")
out_tab_dir <- file.path(repo_root, "outputs", "tables")
out_fig_dir <- file.path(repo_root, "outputs", "figures")
eda_fig_dir <- file.path(repo_root, "eda", "figures")

for (d in c(out_tab_dir, out_fig_dir, eda_fig_dir)) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
}

save_both_tabs <- function(df_out, fname) {
  write_csv(df_out, file.path(out_tab_dir, fname))
}

save_eda_fig <- function(p, fname_base, width = 8.8, height = 5.2) {
  for (dir_path in c(out_fig_dir, eda_fig_dir)) {
    ggsave(file.path(dir_path, paste0(fname_base, ".pdf")), plot = p, width = width, height = height, dpi = 300)
    ggsave(file.path(dir_path, paste0(fname_base, ".png")), plot = p, width = width, height = height, dpi = 300)
  }
}

df_all <- read_csv(file.path(proc_dir, "clean_tax_panel.csv"), show_col_types = FALSE) %>%
  mutate(
    income_group = factor(income_group, levels = c(
      "Low income", "Lower middle income", "Upper middle income", "High income"
    )),
    income_group_num = as.numeric(income_group),
    region_num = as.numeric(factor(region))
  )

y5_cols  <- c("d_t1_nonres_tax_gdp_pp", "d_t1_inc_tax_gdp_pp", "d_t1_inc_tax_share_pp", "d_t1_goods_tax_share_pp")
y10_cols <- c("d_t2_nonres_tax_gdp_pp", "d_t2_inc_tax_gdp_pp", "d_t2_inc_tax_share_pp", "d_t2_goods_tax_share_pp")

# ==============================================================================
# 1. Coverage, Attrition & Train/Holdout Split Table (Table 0)
# ==============================================================================
df_all_5y  <- df_all %>% filter(complete.cases(across(all_of(c(y5_cols, "Z_cont_10pp", "Z_cont_log25pct")))))
df_all_10y <- df_all %>% filter(complete.cases(across(all_of(c(y10_cols, "Z_cont_10pp", "Z_cont_log25pct")))))

# Lock the 20% Holdout Test Set (is_holdout_test == 1, country_fold == 5);
# All subsequent Phase 3 EDA is restricted strictly to the 80% Training Set (is_holdout_test == 0)
df <- df_all %>% filter(is_holdout_test == 0L)
df_5y_comp  <- df_all_5y %>% filter(is_holdout_test == 0L)
df_10y_comp <- df_all_10y %>% filter(is_holdout_test == 0L)
df_5y_test  <- df_all_5y %>% filter(is_holdout_test == 1L)
df_10y_test <- df_all_10y %>% filter(is_holdout_test == 1L)

attrition_tbl <- tribble(
  ~stage_step, ~description, ~country_waves, ~countries, ~retention_pct,
  "1. Full Global 5-Year Panel (All Folds)", "217 sovereign territories x 8 non-overlapping 5y waves (1985-2024)", nrow(df_all), n_distinct(df_all$iso3), 100.0,
  "2. Observed Domestic Tax Revenue (All Folds)", "Country-waves with valid non-resource tax-to-GDP (after screening 4 WDI errors)", sum(!is.na(df_all$non_resource_tax_gdp_pct)), n_distinct(df_all$iso3[!is.na(df_all$non_resource_tax_gdp_pct)]), round(100 * mean(!is.na(df_all$non_resource_tax_gdp_pct)), 1),
  "3. Observed Four-Channel Tax Vector (All Folds)", "Country-waves with all 4 disaggregated tax outcomes at baseline t", sum(complete.cases(df_all[, c("non_resource_tax_gdp_pct", "inc_tax_gdp_pct", "income_profit_tax_share_rev_pct", "goods_services_tax_share_rev_pct")])), n_distinct(df_all$iso3[complete.cases(df_all[, c("non_resource_tax_gdp_pct", "inc_tax_gdp_pct", "income_profit_tax_share_rev_pct", "goods_services_tax_share_rev_pct")])]), round(100 * mean(complete.cases(df_all[, c("non_resource_tax_gdp_pct", "inc_tax_gdp_pct", "income_profit_tax_share_rev_pct", "goods_services_tax_share_rev_pct")])), 1),
  "4. Observed Continuous Per-Student Spend (All Folds)", "Country-waves with valid UNESCO per-student tertiary spending >= 1% GDP/pc", sum(!is.na(df_all$Z_cont_10pp)), n_distinct(df_all$iso3[!is.na(df_all$Z_cont_10pp)]), round(100 * mean(!is.na(df_all$Z_cont_10pp)), 1),
  "5. Complete +5y Panel (All 121 Countries)", "Complete 4-channel fiscal changes over [t, t+1] + continuous Z", nrow(df_all_5y), n_distinct(df_all_5y$iso3), round(100 * nrow(df_all_5y) / nrow(df_all), 1),
  "6. Complete +5y Training Set (Folds 1-4, 80%)", "Training countries used for Phase 3 EDA and model fitting (+5y)", nrow(df_5y_comp), n_distinct(df_5y_comp$iso3), round(100 * nrow(df_5y_comp) / nrow(df_all_5y), 1),
  "7. Complete +5y Holdout Test Set (Fold 5, 20% Locked)", "Held-out unseen countries locked during EDA for out-of-sample validation (+5y)", nrow(df_5y_test), n_distinct(df_5y_test$iso3), round(100 * nrow(df_5y_test) / nrow(df_all_5y), 1),
  "8. Complete +10y Panel (All 112 Countries)", "Complete 4-channel fiscal changes over [t, t+2] + continuous Z", nrow(df_all_10y), n_distinct(df_all_10y$iso3), round(100 * nrow(df_all_10y) / nrow(df_all), 1),
  "9. Complete +10y Training Set (Folds 1-4, 80%)", "Training countries used for Phase 3 EDA and model fitting (+10y)", nrow(df_10y_comp), n_distinct(df_10y_comp$iso3), round(100 * nrow(df_10y_comp) / nrow(df_all_10y), 1),
  "10. Complete +10y Holdout Test Set (Fold 5, 20% Locked)", "Held-out unseen countries locked during EDA for out-of-sample validation (+10y)", nrow(df_10y_test), n_distinct(df_10y_test$iso3), round(100 * nrow(df_10y_test) / nrow(df_all_10y), 1)
)
save_both_tabs(attrition_tbl, "eda_table0_attrition_and_coverage.csv")

# ==============================================================================
# 2. Training-Set Summary Table by Income Group (Table 1) & Raw Slopes (Table 2)
# ==============================================================================
eda_by_income <- df %>%
  filter(!is.na(tert_spend_per_student_winsor) | !is.na(tert_spend_gdp_pct)) %>%
  filter(!is.na(income_group)) %>%
  group_by(income_group) %>%
  summarise(
    train_countries = n_distinct(iso3),
    train_waves = n(),
    median_unesco_ratio_pct = round(median(tert_spend_raw, na.rm = TRUE), 1),
    iqr_unesco_ratio_pct = round(IQR(tert_spend_raw, na.rm = TRUE), 1),
    sd_Z_cont_10pp = round(sd(Z_cont_10pp, na.rm = TRUE), 2),
    sd_Z_cont_log25pct = round(sd(Z_cont_log25pct, na.rm = TRUE), 2),
    median_real_ppp_per_student = round(median(real_tert_spend_per_student_ppp, na.rm = TRUE), 0),
    median_tert_gdp_pct = round(median(tert_spend_gdp_pct, na.rm = TRUE), 2),
    median_tert_enrolment_pct = round(median(gross_tert_enrolment_pct, na.rm = TRUE), 1),
    mean_tax_gdp_pct = round(mean(non_resource_tax_gdp_pct, na.rm = TRUE), 1),
    mean_inc_tax_share_pct = round(mean(income_profit_tax_share_rev_pct, na.rm = TRUE), 1),
    mean_goods_tax_share_pct = round(mean(goods_services_tax_share_rev_pct, na.rm = TRUE), 1),
    .groups = "drop"
  )
save_both_tabs(eda_by_income, "eda_table1_income_group_summary.csv")

# Table 2: Unadjusted training-set continuous OLS slopes and tertile means for Scaling A & Scaling B
summarise_raw_continuous <- function(d, z_col, scaling_label, horizon_label, y_vec) {
  d_sub <- d %>%
    filter(!is.na(.data[[z_col]])) %>%
    mutate(z_tertile = ntile(.data[[z_col]], 3L))
  
  get_slope <- function(y_c) {
    fit <- lm(d_sub[[y_c]] ~ d_sub[[z_col]])
    round(coef(fit)[2], 3)
  }
  
  bind_rows(
    tibble(
      scaling = scaling_label,
      horizon = horizon_label,
      group = "Linear OLS Slope (per +1 unit Z)",
      n_obs = nrow(d_sub),
      n_countries = n_distinct(d_sub$iso3),
      d_tax_gdp_pp = get_slope(y_vec[1]),
      d_inc_tax_gdp_pp = get_slope(y_vec[2]),
      d_inc_tax_share_pp = get_slope(y_vec[3]),
      d_goods_tax_share_pp = get_slope(y_vec[4])
    ),
    d_sub %>%
      group_by(z_tertile) %>%
      summarise(
        scaling = scaling_label,
        horizon = horizon_label,
        group = paste0("Tertile ", first(z_tertile), ifelse(first(z_tertile) == 1L, " (Lowest Z)", ifelse(first(z_tertile) == 3L, " (Highest Z)", " (Middle Z)"))),
        n_obs = n(),
        n_countries = n_distinct(iso3),
        d_tax_gdp_pp = round(mean(.data[[y_vec[1]]]), 2),
        d_inc_tax_gdp_pp = round(mean(.data[[y_vec[2]]]), 2),
        d_inc_tax_share_pp = round(mean(.data[[y_vec[3]]]), 2),
        d_goods_tax_share_pp = round(mean(.data[[y_vec[4]]]), 2),
        .groups = "drop"
      ) %>%
      select(-z_tertile)
  )
}

raw_diff_summary <- bind_rows(
  summarise_raw_continuous(df_5y_comp, "Z_cont_10pp", "Scaling A (+10 pp GDP/pc)", "+5 years (t+1)", y5_cols),
  summarise_raw_continuous(df_10y_comp, "Z_cont_10pp", "Scaling A (+10 pp GDP/pc)", "+10 years (t+2)", y10_cols),
  summarise_raw_continuous(df_5y_comp, "Z_cont_log25pct", "Scaling B (+25% Log-Relative)", "+5 years (t+1)", y5_cols),
  summarise_raw_continuous(df_10y_comp, "Z_cont_log25pct", "Scaling B (+25% Log-Relative)", "+10 years (t+2)", y10_cols)
)
save_both_tabs(raw_diff_summary, "eda_table2_raw_fiscal_changes_by_regime.csv")

# ==============================================================================
# 3. Random Forest Expected-Treatment Fit E[Z|X] & Residual Overlap Audit (Table 3)
# ==============================================================================
base_con_vars <- c(
  "log_gdp_pc_ppp", "non_resource_tax_gdp_pct", "income_profit_tax_share_rev_pct",
  "goods_services_tax_share_rev_pct", "gini_disp_harmonised", "life_expectancy_birth_yrs",
  "gross_tert_enrolment_pct", "gross_seco_enrolment_pct", "edu_spend_total_gdp_pct",
  "working_age_pop_15_64_pct", "log_population", "unemployment_rate_pct",
  "natural_resource_rents_gdp_pct", "trade_openness_gdp_pct", "lag_gdp_pc_growth_pct",
  "income_group_num", "region_num", "is_oecd", "wave_index"
)

prep_med_train <- function(d, cols) {
  out <- as.data.frame(d[, cols, drop = FALSE])
  for (cl in cols) {
    v <- as.numeric(out[[cl]])
    med <- median(v, na.rm = TRUE)
    if (is.na(med)) med <- 0
    out[[cl]] <- ifelse(is.na(v), med, v)
  }
  out
}

audit_rf_z_hat <- function(d_train, z_col, scaling_label) {
  X_tr <- prep_med_train(d_train, base_con_vars)
  z_vec <- as.numeric(d_train[[z_col]])
  rf_df <- cbind(Z = z_vec, X_tr)

  set.seed(20261108)
  rf_fit <- ranger(
    Z ~ .,
    data = rf_df,
    num.trees = 500,
    mtry = floor(sqrt(ncol(X_tr))),
    min.node.size = 5,
    importance = "permutation",
    seed = 20261108
  )
  z_hat_oob <- as.numeric(rf_fit$predictions)

  # Also compute 4-fold country-blocked out-of-fold predictions within the training set (folds 1..4)
  z_hat_cv <- numeric(nrow(d_train))
  folds <- sort(unique(d_train$country_fold))
  for (f in folds) {
    idx_val <- which(d_train$country_fold == f)
    idx_sub <- which(d_train$country_fold != f)
    X_sub <- prep_med_train(d_train[idx_sub, ], base_con_vars)
    # Apply training fold medians to validation fold
    X_val <- as.data.frame(d_train[idx_val, base_con_vars, drop = FALSE])
    for (cl in base_con_vars) {
      med_f <- median(as.numeric(d_train[[cl]][idx_sub]), na.rm = TRUE)
      if (is.na(med_f)) med_f <- 0
      v_val <- as.numeric(X_val[[cl]])
      X_val[[cl]] <- ifelse(is.na(v_val), med_f, v_val)
    }
    rf_sub <- ranger(
      Z ~ .,
      data = cbind(Z = z_vec[idx_sub], X_sub),
      num.trees = 500,
      mtry = floor(sqrt(ncol(X_sub))),
      min.node.size = 5,
      seed = 20261108 + f
    )
    z_hat_cv[idx_val] <- as.numeric(predict(rf_sub, data = X_val)$predictions)
  }

  d_out <- d_train %>%
    mutate(
      scaling = scaling_label,
      z_obs = z_vec,
      z_hat_oob = z_hat_oob,
      z_hat_cv = z_hat_cv,
      z_resid_oob = z_vec - z_hat_oob,
      z_resid_cv = z_vec - z_hat_cv
    )

  overall_sd_res <- sd(d_out$z_resid_oob)

  summarise_grp <- function(sub_df, grp_name) {
    sst <- sum((sub_df$z_obs - mean(sub_df$z_obs))^2)
    sse_oob <- sum((sub_df$z_obs - sub_df$z_hat_oob)^2)
    sse_cv  <- sum((sub_df$z_obs - sub_df$z_hat_cv)^2)
    tibble(
      scaling = scaling_label,
      income_group = grp_name,
      n_waves = nrow(sub_df),
      n_countries = n_distinct(sub_df$iso3),
      obs_sd_Z = round(sd(sub_df$z_obs), 2),
      rf_oob_r2 = round(max(1 - sse_oob / sst, 0), 3),
      rf_cv_r2 = round(max(1 - sse_cv / sst, 0), 3),
      rf_oob_rmse = round(sqrt(mean((sub_df$z_obs - sub_df$z_hat_oob)^2)), 2),
      rf_cv_rmse = round(sqrt(mean((sub_df$z_obs - sub_df$z_hat_cv)^2)), 2),
      resid_sd = round(sd(sub_df$z_resid_oob), 2),
      resid_iqr = round(IQR(sub_df$z_resid_oob), 2),
      common_support_pct = round(100 * mean(abs(sub_df$z_resid_oob) <= 2.5 * overall_sd_res), 1)
    )
  }

  tbl <- bind_rows(
    summarise_grp(d_out, "All Training Countries (Folds 1-4)"),
    bind_rows(lapply(levels(d_out$income_group), function(g) {
      summarise_grp(d_out %>% filter(income_group == g), g)
    }))
  )

  list(table = tbl, data = d_out, importance = rf_fit$variable.importance)
}

rf_audit_A <- audit_rf_z_hat(df_5y_comp, "Z_cont_10pp", "Scaling A (+10 pp GDP/pc)")
rf_audit_B <- audit_rf_z_hat(df_5y_comp, "Z_cont_log25pct", "Scaling B (+25% Log-Relative)")

positivity_tbl <- bind_rows(rf_audit_A$table, rf_audit_B$table)
save_both_tabs(positivity_tbl, "eda_table3_positivity_and_overlap.csv")

# ==============================================================================
# 4. Missing Data Audit Across Core Variables & Income Groups in Training Set (Table 4)
# ==============================================================================
audit_vars <- c(
  "tert_spend_per_student_winsor", "Z_cont_10pp", "Z_cont_log25pct",
  "real_tert_spend_per_student_ppp", "tert_spend_gdp_pct",
  "non_resource_tax_gdp_pct", "income_profit_tax_share_rev_pct", "goods_services_tax_share_rev_pct",
  "log_gdp_pc_ppp", "lag_gdp_pc_growth_pct", "gross_tert_enrolment_pct",
  "gini_disp_harmonised", "trade_openness_gdp_pct", "unemployment_rate_pct"
)
audit_labels <- c(
  "Per-Student Tertiary Ratio (% GDP/pc)", "Continuous Z Scaling A (+10 pp GDP/pc)",
  "Continuous Z Scaling B (+25% Log-Rel)", "Real 2021 PPP $ per Tertiary Student",
  "Public Tertiary Budget (% of GDP)", "Non-Resource Tax Revenue (% of GDP)",
  "Direct Income & Profit Share (% Rev)", "Goods & Services Tax Share (% Rev)",
  "Log Real GDP per Person (PPP)", "Lagged (t-1) GDP per Person Growth (%)",
  "Gross Tertiary Enrolment (%)", "Harmonised Disposable Gini Index",
  "Trade Openness (% of GDP)", "Total Unemployment Rate (%)"
)

miss_rows <- list()
for (i in seq_along(audit_vars)) {
  v <- audit_vars[i]
  miss_rows[[i]] <- tibble(
    variable = audit_labels[i],
    overall_train_miss_pct = round(100 * mean(is.na(df[[v]])), 1),
    miss_5y_train_sample_pct = round(100 * mean(is.na(df_5y_comp[[v]])), 1),
    low_inc_train_miss_pct = round(100 * mean(is.na(df[[v]][df$income_group == "Low income"])), 1),
    high_inc_train_miss_pct = round(100 * mean(is.na(df[[v]][df$income_group == "High income"])), 1)
  )
}
miss_tbl <- bind_rows(miss_rows)
save_both_tabs(miss_tbl, "eda_table4_missingness_analysis.csv")

# ==============================================================================
# 5. Temporal Autocorrelation, Stationarity & Spatial/Regional ICC on Training Set (Table 5)
# ==============================================================================
calc_within_acf <- function(d, col, lag_k = 1L) {
  d_lag <- d %>%
    arrange(iso3, wave_index) %>%
    group_by(iso3) %>%
    mutate(v_lag = lag(.data[[col]], lag_k)) %>%
    ungroup() %>%
    filter(!is.na(.data[[col]]), !is.na(v_lag))
  round(cor(d_lag[[col]], d_lag$v_lag), 3)
}

calc_icc <- function(d, col, grp_col) {
  sub <- d %>% filter(!is.na(.data[[col]]), !is.na(.data[[grp_col]]))
  fit_aov <- aov(sub[[col]] ~ factor(sub[[grp_col]]))
  s <- summary(fit_aov)[[1]]
  msb <- s["factor(sub[[grp_col]])", "Mean Sq"]
  msw <- s["Residuals", "Mean Sq"]
  k_bar <- nrow(sub) / n_distinct(sub[[grp_col]])
  icc <- (msb - msw) / (msb + (k_bar - 1) * msw)
  round(max(min(icc, 1.0), 0.0), 3)
}

calc_panel_adf_p <- function(d, col) {
  d_sub <- d %>%
    arrange(iso3, wave_index) %>%
    group_by(iso3) %>%
    mutate(
      y_lag = lag(.data[[col]], 1L),
      dy = .data[[col]] - y_lag
    ) %>%
    ungroup() %>%
    filter(!is.na(dy), !is.na(y_lag))
  fit <- lm(dy ~ y_lag, data = d_sub)
  p_val <- summary(fit)$coefficients["y_lag", "Pr(>|t|)"]
  ifelse(p_val < 0.001, "<0.001 (Stationary)", sprintf("%.3f", p_val))
}

temp_spat_tbl <- tribble(
  ~series_label, ~series_col, ~type,
  "1. Non-Resource Tax / GDP (Level %)", "non_resource_tax_gdp_pct", "Baseline Level (Y_t)",
  "2. Direct Income Tax / GDP (Level %)", "inc_tax_gdp_pct", "Baseline Level (Y_t)",
  "3. Direct Income Tax Share (Level %)", "income_profit_tax_share_rev_pct", "Baseline Level (Y_t)",
  "4. Goods & Services Share (Level %)", "goods_services_tax_share_rev_pct", "Baseline Level (Y_t)",
  "5. Continuous Z Scaling A (+10 pp GDP/pc)", "Z_cont_10pp", "Continuous Treatment (Z_t)",
  "6. Continuous Z Scaling B (+25% Log-Rel)", "Z_cont_log25pct", "Continuous Treatment (Z_t)",
  "7. 5y Change Non-Resource Tax / GDP (pp)", "d_t1_nonres_tax_gdp_pp", "First Difference (Delta Y_t+1)",
  "8. 5y Change Direct Income Tax / GDP (pp)", "d_t1_inc_tax_gdp_pp", "First Difference (Delta Y_t+1)",
  "9. 5y Change Direct Income Tax Share (pp)", "d_t1_inc_tax_share_pp", "First Difference (Delta Y_t+1)",
  "10. 5y Change Goods & Services Share (pp)", "d_t1_goods_tax_share_pp", "First Difference (Delta Y_t+1)"
) %>%
  rowwise() %>%
  mutate(
    lag1_acf = calc_within_acf(df, series_col, 1L),
    lag2_acf = calc_within_acf(df, series_col, 2L),
    country_icc = calc_icc(df, series_col, "iso3"),
    region_icc = calc_icc(df, series_col, "region"),
    panel_convergence_p = calc_panel_adf_p(df, series_col)
  ) %>%
  ungroup() %>%
  select(-series_col)

save_both_tabs(temp_spat_tbl, "eda_table5_temporal_and_spatial_structure.csv")

# ==============================================================================
# 6. Feature Correlation Structure & Variance Inflation Factors on Training Set (Table 6)
# ==============================================================================
vif_vars <- c(
  "log_gdp_pc_ppp", "non_resource_tax_gdp_pct", "income_profit_tax_share_rev_pct",
  "goods_services_tax_share_rev_pct", "gini_disp_harmonised", "life_expectancy_birth_yrs",
  "gross_tert_enrolment_pct", "gross_seco_enrolment_pct", "edu_spend_total_gdp_pct",
  "working_age_pop_15_64_pct", "log_population", "unemployment_rate_pct",
  "natural_resource_rents_gdp_pct", "trade_openness_gdp_pct", "lag_gdp_pc_growth_pct"
)
vif_labels <- c(
  "Log Real GDP per Person (PPP)", "Baseline Non-Resource Tax / GDP (%)",
  "Baseline Direct Income Tax Share (%)", "Baseline Goods & Services Share (%)",
  "Baseline Disposable Gini Index", "Baseline Life Expectancy (Years)",
  "Baseline Gross Tertiary Enrolment (%)", "Baseline Gross Secondary Enrolment (%)",
  "Baseline Total Education Spend (% GDP)", "Working-Age Population Share (%)",
  "Log Population Size", "Unemployment Rate (%)",
  "Natural Resource Rents (% GDP)", "Trade Openness (% GDP)",
  "Lagged (t-1) GDP per Person Growth (%)"
)

X_vif <- prep_med_train(df_5y_comp, vif_vars)
vif_vals <- numeric(length(vif_vars))
cor_zA <- numeric(length(vif_vars))
cor_zB <- numeric(length(vif_vars))
cor_y1 <- numeric(length(vif_vars))
cor_y3 <- numeric(length(vif_vars))

for (j in seq_along(vif_vars)) {
  fml <- as.formula(paste(vif_vars[j], "~ ."))
  r2_j <- summary(lm(fml, data = X_vif))$r.squared
  vif_vals[j] <- round(1 / max(1 - r2_j, 1e-4), 2)
  cor_zA[j] <- round(cor(X_vif[[vif_vars[j]]], df_5y_comp$Z_cont_10pp), 3)
  cor_zB[j] <- round(cor(X_vif[[vif_vars[j]]], df_5y_comp$Z_cont_log25pct), 3)
  cor_y1[j] <- round(cor(X_vif[[vif_vars[j]]], df_5y_comp$d_t1_nonres_tax_gdp_pp), 3)
  cor_y3[j] <- round(cor(X_vif[[vif_vars[j]]], df_5y_comp$d_t1_inc_tax_share_pp), 3)
}

vif_tbl <- tibble(
  feature_label = vif_labels,
  vif = vif_vals,
  cor_with_Z_10pp = cor_zA,
  cor_with_Z_log25pct = cor_zB,
  cor_with_5y_tax_gdp_chg = cor_y1,
  cor_with_5y_inc_share_chg = cor_y3
) %>%
  arrange(desc(vif))
save_both_tabs(vif_tbl, "eda_table6_vif_and_feature_correlations.csv")

# ==============================================================================
# 7. Generate EDA Figures on Training Set (Saved to outputs/figures/ and eda/figures/)
# ==============================================================================

# EDA Figure 1: Bivariate Dose-Response Relationships of 10y Tax Outcomes vs Continuous Z (Training Set)
plot_df_10y <- bind_rows(
  df_10y_comp %>%
    transmute(
      iso3, income_group,
      Scaling = "Scaling A (+10 pp)",
      Z_val = Z_cont_10pp,
      `1. Non-Resource Tax / GDP (pp)` = d_t2_nonres_tax_gdp_pp,
      `2. Direct Income Tax / GDP (pp)` = d_t2_inc_tax_gdp_pp,
      `3. Direct Income Tax Share (pp)` = d_t2_inc_tax_share_pp,
      `4. Goods & Services Share (pp)` = d_t2_goods_tax_share_pp
    ),
  df_10y_comp %>%
    transmute(
      iso3, income_group,
      Scaling = "Scaling B (+25% Log)",
      Z_val = Z_cont_log25pct,
      `1. Non-Resource Tax / GDP (pp)` = d_t2_nonres_tax_gdp_pp,
      `2. Direct Income Tax / GDP (pp)` = d_t2_inc_tax_gdp_pp,
      `3. Direct Income Tax Share (pp)` = d_t2_inc_tax_share_pp,
      `4. Goods & Services Share (pp)` = d_t2_goods_tax_share_pp
    )
) %>%
  pivot_longer(
    cols = starts_with(c("1.", "2.", "3.", "4.")),
    names_to = "Outcome",
    values_to = "Change_pp"
  )

p_eda1 <- ggplot(plot_df_10y, aes(x = Z_val, y = Change_pp, colour = income_group)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "#666666", linewidth = 0.45) +
  geom_vline(xintercept = 0, linetype = "dotted", colour = "#666666", linewidth = 0.45) +
  geom_point(alpha = 0.55, size = 1.4) +
  geom_smooth(aes(group = 1), method = "lm", formula = y ~ x, colour = "#111111", fill = "#999999", linewidth = 0.85, alpha = 0.22) +
  facet_grid(Scaling ~ Outcome, scales = "free") +
  scale_colour_manual(values = c(
    "Low income" = okabe_ito[["orange"]],
    "Lower middle income" = okabe_ito[["sky"]],
    "Upper middle income" = okabe_ito[["teal"]],
    "High income" = okabe_ito[["navy"]]
  )) +
  labs(
    title = "Training-Set Bivariate Dose-Response of 10-Year Fiscal Changes vs Continuous Z",
    subtitle = sprintf("Unadjusted 10-year fiscal changes across N = %d training country-waves (%d training countries; 20%% holdout locked)", nrow(df_10y_comp), n_distinct(df_10y_comp$iso3)),
    x = "Continuous University Funding Intensity Z (Centred on Training Income-Group Median)",
    y = "10-Year Fiscal Change (Percentage Points)",
    colour = "World Bank Income Tier:"
  ) +
  theme_pub(base_size = 9.8)

save_eda_fig(p_eda1, "eda_fig1_raw_distributions_and_bivariate", width = 10.5, height = 5.6)

# EDA Figure 2: Random Forest Expected-Treatment Fit z_hat(X) & Residual Overlap (Scaling A vs Scaling B)
rf_plot_df <- bind_rows(
  rf_audit_A$data %>%
    transmute(
      iso3, income_group,
      Scaling = sprintf("Scaling A: Z_cont_10pp (OOB R2 = %.2f, CV R2 = %.2f)", rf_audit_A$table$rf_oob_r2[1], rf_audit_A$table$rf_cv_r2[1]),
      z_obs, z_hat_oob, z_resid_oob
    ),
  rf_audit_B$data %>%
    transmute(
      iso3, income_group,
      Scaling = sprintf("Scaling B: Z_cont_log25pct (OOB R2 = %.2f, CV R2 = %.2f)", rf_audit_B$table$rf_oob_r2[1], rf_audit_B$table$rf_cv_r2[1]),
      z_obs, z_hat_oob, z_resid_oob
    )
)

p_eda2_scatter <- ggplot(rf_plot_df, aes(x = z_hat_oob, y = z_obs, colour = income_group)) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", colour = "#444444", linewidth = 0.6) +
  geom_point(alpha = 0.65, size = 1.6) +
  geom_smooth(aes(group = 1), method = "loess", formula = y ~ x, se = FALSE, colour = "#111111", linewidth = 0.8) +
  facet_wrap(~ Scaling, scales = "free", ncol = 2) +
  scale_colour_manual(values = c(
    "Low income" = okabe_ito[["orange"]],
    "Lower middle income" = okabe_ito[["sky"]],
    "Upper middle income" = okabe_ito[["teal"]],
    "High income" = okabe_ito[["navy"]]
  )) +
  labs(
    title = "Random Forest Expected-Treatment Fit: Observed Z vs Out-of-Bag Predicted E[Z | X]",
    subtitle = sprintf("500-tree Random Forest across 19 pre-treatment covariates on training set (N = %d country-waves, %d countries)", nrow(df_5y_comp), n_distinct(df_5y_comp$iso3)),
    x = "Random Forest Out-of-Bag Expected Treatment z_hat(X_i,t) = E[Z_i,t | X_i,t]",
    y = "Observed Continuous Treatment Z_i,t",
    colour = "Income Group:"
  ) +
  theme_pub(base_size = 10.2)

save_eda_fig(p_eda2_scatter, "eda_fig2_propensity_overlap", width = 9.2, height = 4.6)

# Also save residual overlap density plot for the EDA report
p_eda2_resid <- ggplot(rf_plot_df, aes(x = z_resid_oob, fill = income_group, colour = income_group)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "#444444", linewidth = 0.55) +
  geom_density(alpha = 0.30, linewidth = 0.75) +
  facet_wrap(~ Scaling, scales = "free", ncol = 2) +
  scale_fill_manual(values = c(
    "Low income" = okabe_ito[["orange"]],
    "Lower middle income" = okabe_ito[["sky"]],
    "Upper middle income" = okabe_ito[["teal"]],
    "High income" = okabe_ito[["navy"]]
  )) +
  scale_colour_manual(values = c(
    "Low income" = okabe_ito[["orange"]],
    "Lower middle income" = okabe_ito[["sky"]],
    "Upper middle income" = okabe_ito[["teal"]],
    "High income" = okabe_ito[["navy"]]
  )) +
  labs(
    title = "Orthogonal Treatment Residual Overlap (Z_i,t - z_hat(X_i,t)) Across Income Tiers",
    subtitle = "Centred residual variation available for causal identification after Random Forest conditioning",
    x = "Orthogonal Treatment Residual: Z_i,t - z_hat(X_i,t)",
    y = "Kernel Density",
    fill = "Income Group:",
    colour = "Income Group:"
  ) +
  theme_pub(base_size = 10.2)

save_eda_fig(p_eda2_resid, "eda_fig2b_residual_overlap", width = 9.2, height = 4.6)

# EDA Figure 3: Baseline Feature Correlation Heatmap (Training Set)
short_names <- c(
  "Log GDP/pc", "Tax/GDP", "IncTax Share", "GoodsTax Share", "Gini",
  "Life Exp", "Tert Enrol", "Seco Enrol", "Edu % GDP", "Work-Age %",
  "Log Pop", "Unemp %", "Resource Rents", "Trade % GDP", "Lag GDP Growth"
)
cor_mat <- cor(X_vif, use = "pairwise.complete.obs")
colnames(cor_mat) <- short_names
rownames(cor_mat) <- short_names

cor_long <- as.data.frame(as.table(cor_mat)) %>%
  rename(Var1 = Var1, Var2 = Var2, Correlation = Freq)

p_eda3 <- ggplot(cor_long, aes(x = Var1, y = Var2, fill = Correlation)) +
  geom_tile(colour = "white", linewidth = 0.25) +
  scale_fill_gradient2(low = okabe_ito[["navy"]], mid = "white", high = okabe_ito[["red"]],
                       midpoint = 0, limits = c(-1, 1)) +
  labs(
    title = "Pre-Treatment Baseline Covariate Correlation Matrix (Training Set)",
    subtitle = sprintf("Pairwise correlations across 15 continuous baseline confounders (N = %d training country-waves)", nrow(df_5y_comp)),
    x = NULL,
    y = NULL,
    fill = "Pearson r"
  ) +
  theme_pub(base_size = 10) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

save_eda_fig(p_eda3, "eda_fig3_feature_correlation_heatmap", width = 8.5, height = 6.2)

cat("Phase 3 Training-Set EDA tables (Tables 0-6) and figures (eda_fig1-eda_fig3) successfully generated.\n")
