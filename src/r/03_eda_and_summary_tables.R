#!/usr/bin/env Rscript
# ==============================================================================
# Step 03: Comprehensive Exploratory Data Analysis & Diagnostic Tables/Figures
# (src/r/03_eda_and_summary_tables.R)
#
# Generates all Phase 3 EDA tables and figures required by academic-paper-workflow:
#   - Table 0 (eda_table0_attrition_and_coverage.csv): Coverage & sample attrition
#   - Table 1 (eda_table1_income_group_summary.csv): Unbundling tertiary spending denominators
#   - Table 2 (eda_table2_raw_fiscal_changes_by_regime.csv): Raw unadjusted fiscal changes
#   - Table 3 (eda_table3_positivity_and_overlap.csv): Common support & propensity overlap
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
})

repo_root <- getwd()
if (!dir.exists(file.path(repo_root, "src")) && dir.exists(file.path(dirname(dirname(repo_root)), "src"))) {
  repo_root <- dirname(dirname(repo_root))
}
source(file.path(repo_root, "src", "r", "plot_theme.R"))

proc_dir    <- file.path(repo_root, "data", "processed")
out_tab_dir <- file.path(repo_root, "outputs", "tables")
res_tab_dir <- file.path(repo_root, "results", "tables")
out_fig_dir <- file.path(repo_root, "outputs", "figures")
eda_fig_dir <- file.path(repo_root, "eda", "figures")

for (d in c(out_tab_dir, res_tab_dir, out_fig_dir, eda_fig_dir)) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
}

save_both_tabs <- function(df_out, fname) {
  write_csv(df_out, file.path(out_tab_dir, fname))
  write_csv(df_out, file.path(res_tab_dir, fname))
}

save_eda_fig <- function(p, fname_base, width = 8.5, height = 4.8) {
  for (dir_path in c(out_fig_dir, eda_fig_dir)) {
    ggsave(file.path(dir_path, paste0(fname_base, ".pdf")), plot = p, width = width, height = height, dpi = 300)
    ggsave(file.path(dir_path, paste0(fname_base, ".png")), plot = p, width = width, height = height, dpi = 300)
  }
}

df <- read_csv(file.path(proc_dir, "clean_tax_panel.csv"), show_col_types = FALSE) %>%
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
# 1. Coverage & Attrition Table (Table 0)
# ==============================================================================
df_5y_comp  <- df %>% filter(complete.cases(across(all_of(c(y5_cols, "Z_regime_inc")))))
df_10y_comp <- df %>% filter(complete.cases(across(all_of(c(y10_cols, "Z_regime_inc")))))
df_3w_comp  <- df %>% filter(complete.cases(across(all_of(c(
  "Z_regime_inc", "non_resource_tax_gdp_pct", y5_cols, y10_cols
)))))

attrition_tbl <- tribble(
  ~stage_step, ~description, ~country_waves, ~countries, ~retention_pct,
  "1. Full Global 5-Year Panel", "217 sovereign territories x 8 non-overlapping 5y waves (1985-2024)", nrow(df), n_distinct(df$iso3), 100.0,
  "2. Observed Domestic Tax Revenue", "Country-waves with valid non-resource tax-to-GDP (after screening 4 WDI errors)", sum(!is.na(df$non_resource_tax_gdp_pct)), n_distinct(df$iso3[!is.na(df$non_resource_tax_gdp_pct)]), round(100 * mean(!is.na(df$non_resource_tax_gdp_pct)), 1),
  "3. Observed Four-Channel Tax Vector", "Country-waves with all 4 disaggregated tax outcomes at baseline t", sum(complete.cases(df[, c("non_resource_tax_gdp_pct", "inc_tax_gdp_pct", "income_profit_tax_share_rev_pct", "goods_services_tax_share_rev_pct")])), n_distinct(df$iso3[complete.cases(df[, c("non_resource_tax_gdp_pct", "inc_tax_gdp_pct", "income_profit_tax_share_rev_pct", "goods_services_tax_share_rev_pct")])]), round(100 * mean(complete.cases(df[, c("non_resource_tax_gdp_pct", "inc_tax_gdp_pct", "income_profit_tax_share_rev_pct", "goods_services_tax_share_rev_pct")])), 1),
  "4. Observed Per-Student Tertiary Spend", "Country-waves with observed UNESCO per-student tertiary spending (Z_regime_inc)", sum(!is.na(df$Z_regime_inc)), n_distinct(df$iso3[!is.na(df$Z_regime_inc)]), round(100 * mean(!is.na(df$Z_regime_inc)), 1),
  "5. Observed Public Tertiary Budget (% GDP)", "Country-waves with observed public tertiary budget share of GDP (Z_tert_gdp_regime)", sum(!is.na(df$Z_tert_gdp_regime)), n_distinct(df$iso3[!is.na(df$Z_tert_gdp_regime)]), round(100 * mean(!is.na(df$Z_tert_gdp_regime)), 1),
  "6. Complete +5y Estimation Sample (mvbcf)", "Complete 4-channel fiscal changes over [t, t+1] + observed per-student tertiary spend", nrow(df_5y_comp), n_distinct(df_5y_comp$iso3), round(100 * nrow(df_5y_comp) / nrow(df), 1),
  "7. Complete +10y Estimation Sample (mvbcf)", "Complete 4-channel fiscal changes over [t, t+2] + observed per-student tertiary spend", nrow(df_10y_comp), n_distinct(df_10y_comp$iso3), round(100 * nrow(df_10y_comp) / nrow(df), 1),
  "8. Complete 3-Wave Longitudinal Sample (lbcf)", "Complete 3-wave trajectory (t, t+1, t+2) across all 4 tax channels", nrow(df_3w_comp), n_distinct(df_3w_comp$iso3), round(100 * nrow(df_3w_comp) / nrow(df), 1)
)
save_both_tabs(attrition_tbl, "eda_table0_attrition_and_coverage.csv")

# ==============================================================================
# 2. Summary Table by Income Group (Table 1) & Raw Fiscal Changes (Table 2)
# ==============================================================================
eda_by_income <- df %>%
  filter(!is.na(tert_spend_per_student_winsor) | !is.na(tert_spend_gdp_pct)) %>%
  filter(!is.na(income_group)) %>%
  group_by(income_group) %>%
  summarise(
    countries = n_distinct(iso3),
    country_waves = n(),
    median_unesco_ratio_pct = round(median(tert_spend_per_student_winsor, na.rm = TRUE), 1),
    median_real_ppp_per_student = round(median(real_tert_spend_per_student_ppp, na.rm = TRUE), 0),
    median_tert_gdp_pct = round(median(tert_spend_gdp_pct, na.rm = TRUE), 2),
    median_tert_enrolment_pct = round(median(gross_tert_enrolment_pct, na.rm = TRUE), 1),
    mean_tax_gdp_pct = round(mean(non_resource_tax_gdp_pct, na.rm = TRUE), 1),
    mean_inc_tax_share_pct = round(mean(income_profit_tax_share_rev_pct, na.rm = TRUE), 1),
    mean_goods_tax_share_pct = round(mean(goods_services_tax_share_rev_pct, na.rm = TRUE), 1),
    .groups = "drop"
  )
save_both_tabs(eda_by_income, "eda_table1_income_group_summary.csv")

raw_diff_summary <- bind_rows(
  df_5y_comp %>%
    group_by(Z_regime_inc) %>%
    summarise(
      horizon = "+5 years (t+1)",
      n_obs = n(),
      n_countries = n_distinct(iso3),
      mean_d_tax_gdp_pp = round(mean(d_t1_nonres_tax_gdp_pp), 2),
      mean_d_inc_tax_gdp_pp = round(mean(d_t1_inc_tax_gdp_pp), 2),
      mean_d_inc_tax_share_pp = round(mean(d_t1_inc_tax_share_pp), 2),
      mean_d_goods_tax_share_pp = round(mean(d_t1_goods_tax_share_pp), 2),
      .groups = "drop"
    ),
  df_10y_comp %>%
    group_by(Z_regime_inc) %>%
    summarise(
      horizon = "+10 years (t+2)",
      n_obs = n(),
      n_countries = n_distinct(iso3),
      mean_d_tax_gdp_pp = round(mean(d_t2_nonres_tax_gdp_pp), 2),
      mean_d_inc_tax_gdp_pp = round(mean(d_t2_inc_tax_gdp_pp), 2),
      mean_d_inc_tax_share_pp = round(mean(d_t2_inc_tax_share_pp), 2),
      mean_d_goods_tax_share_pp = round(mean(d_t2_goods_tax_share_pp), 2),
      .groups = "drop"
    )
)
save_both_tabs(raw_diff_summary, "eda_table2_raw_fiscal_changes_by_regime.csv")

# ==============================================================================
# 3. Common Support & Positivity Audit (Table 3 & EDA Figure 2)
# ==============================================================================
base_con_vars <- c(
  "log_gdp_pc_ppp", "non_resource_tax_gdp_pct", "income_profit_tax_share_rev_pct",
  "goods_services_tax_share_rev_pct", "gini_disp_harmonised", "life_expectancy_birth_yrs",
  "gross_tert_enrolment_pct", "gross_seco_enrolment_pct", "edu_spend_total_gdp_pct",
  "working_age_pop_15_64_pct", "log_population", "unemployment_rate_pct",
  "natural_resource_rents_gdp_pct", "trade_openness_gdp_pct", "lag_gdp_pc_growth_pct",
  "income_group_num", "region_num", "is_oecd", "wave_index"
)

prep_med <- function(d, cols) {
  out <- as.data.frame(d[, cols, drop = FALSE])
  for (cl in cols) {
    v <- as.numeric(out[[cl]])
    med <- median(v, na.rm = TRUE)
    if (is.na(med)) med <- 0
    out[[cl]] <- ifelse(is.na(v), med, v)
  }
  out
}

ps_dat <- prep_med(df_5y_comp, base_con_vars)
ps_dat$Z <- df_5y_comp$Z_regime_inc
ps_fit <- suppressWarnings(glm(Z ~ ., data = ps_dat, family = binomial()))
df_5y_comp$pi_hat <- pmin(pmax(predict(ps_fit, type = "response"), 0.02), 0.98)

positivity_tbl <- df_5y_comp %>%
  group_by(income_group) %>%
  summarise(
    n_waves = n(),
    treated_share_pct = round(100 * mean(Z_regime_inc == 1), 1),
    mean_pi_control = round(mean(pi_hat[Z_regime_inc == 0]), 3),
    mean_pi_treated = round(mean(pi_hat[Z_regime_inc == 1]), 3),
    min_pi = round(min(pi_hat), 3),
    max_pi = round(max(pi_hat), 3),
    common_support_pct = round(100 * mean(pi_hat >= 0.05 & pi_hat <= 0.95), 1),
    .groups = "drop"
  )
save_both_tabs(positivity_tbl, "eda_table3_positivity_and_overlap.csv")

# ==============================================================================
# 4. Missing Data Audit Across Core Variables & Income Groups (Table 4)
# ==============================================================================
audit_vars <- c(
  "tert_spend_per_student_winsor", "real_tert_spend_per_student_ppp", "tert_spend_gdp_pct",
  "non_resource_tax_gdp_pct", "income_profit_tax_share_rev_pct", "goods_services_tax_share_rev_pct",
  "log_gdp_pc_ppp", "lag_gdp_pc_growth_pct", "gross_tert_enrolment_pct",
  "gini_disp_harmonised", "trade_openness_gdp_pct", "unemployment_rate_pct"
)
audit_labels <- c(
  "Per-Student Tertiary Ratio (% GDP/pc)", "Real 2021 PPP $ per Tertiary Student",
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
    overall_miss_pct = round(100 * mean(is.na(df[[v]])), 1),
    miss_5y_sample_pct = round(100 * mean(is.na(df_5y_comp[[v]])), 1),
    low_inc_miss_pct = round(100 * mean(is.na(df[[v]][df$income_group == "Low income"])), 1),
    high_inc_miss_pct = round(100 * mean(is.na(df[[v]][df$income_group == "High income"])), 1)
  )
}
miss_tbl <- bind_rows(miss_rows)
save_both_tabs(miss_tbl, "eda_table4_missingness_analysis.csv")

# ==============================================================================
# 5. Temporal Autocorrelation, Stationarity & Spatial/Regional ICC (Table 5)
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

# Panel ADF-style autoregression t-statistic on delta_y ~ y_{t-1}
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
  "5. 5y Change Non-Resource Tax / GDP (pp)", "d_t1_nonres_tax_gdp_pp", "First Difference (Delta Y_t+1)",
  "6. 5y Change Direct Income Tax / GDP (pp)", "d_t1_inc_tax_gdp_pp", "First Difference (Delta Y_t+1)",
  "7. 5y Change Direct Income Tax Share (pp)", "d_t1_inc_tax_share_pp", "First Difference (Delta Y_t+1)",
  "8. 5y Change Goods & Services Share (pp)", "d_t1_goods_tax_share_pp", "First Difference (Delta Y_t+1)"
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
# 6. Feature Correlation Structure & Variance Inflation Factors (Table 6)
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

X_vif <- prep_med(df_5y_comp, vif_vars)
vif_vals <- numeric(length(vif_vars))
cor_y1 <- numeric(length(vif_vars))
cor_y3 <- numeric(length(vif_vars))

for (j in seq_along(vif_vars)) {
  fml <- as.formula(paste(vif_vars[j], "~ ."))
  r2_j <- summary(lm(fml, data = X_vif))$r.squared
  vif_vals[j] <- round(1 / max(1 - r2_j, 1e-4), 2)
  cor_y1[j] <- round(cor(X_vif[[vif_vars[j]]], df_5y_comp$d_t1_nonres_tax_gdp_pp), 3)
  cor_y3[j] <- round(cor(X_vif[[vif_vars[j]]], df_5y_comp$d_t1_inc_tax_share_pp), 3)
}

vif_tbl <- tibble(
  feature_label = vif_labels,
  vif = vif_vals,
  cor_with_5y_tax_gdp_chg = cor_y1,
  cor_with_5y_inc_share_chg = cor_y3
) %>%
  arrange(desc(vif))
save_both_tabs(vif_tbl, "eda_table6_vif_and_feature_correlations.csv")

# ==============================================================================
# 7. Generate EDA Figures (Saved to outputs/figures/ and eda/figures/)
# ==============================================================================

# EDA Figure 1: Marginal & Bivariate Distributions of 10y Tax Outcomes by Tertiary Regime
plot_df_10y <- df_10y_comp %>%
  mutate(
    Regime = ifelse(Z_regime_inc == 1,
                    "High Per-Student Tertiary Spend (> Income-Group Median)",
                    "Low Per-Student Tertiary Spend (<= Income-Group Median)")
  ) %>%
  select(iso3, income_group, Regime,
         `1. Non-Resource Tax / GDP (pp)` = d_t2_nonres_tax_gdp_pp,
         `2. Direct Income Tax / GDP (pp)` = d_t2_inc_tax_gdp_pp,
         `3. Direct Income Tax Share (pp)` = d_t2_inc_tax_share_pp,
         `4. Goods & Services Share (pp)` = d_t2_goods_tax_share_pp) %>%
  pivot_longer(
    cols = starts_with(c("1.", "2.", "3.", "4.")),
    names_to = "Outcome",
    values_to = "Change_pp"
  )

p_eda1 <- ggplot(plot_df_10y, aes(x = Change_pp, fill = Regime, colour = Regime)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "#555555", linewidth = 0.5) +
  geom_density(alpha = 0.35, linewidth = 0.7) +
  facet_wrap(~ Outcome, scales = "free", ncol = 2) +
  scale_fill_manual(values = c(okabe_ito[["navy"]], okabe_ito[["teal"]])) +
  scale_colour_manual(values = c(okabe_ito[["navy"]], okabe_ito[["teal"]])) +
  labs(
    title = "Marginal Distributions of 10-Year Fiscal Changes by Tertiary Funding Regime",
    subtitle = "Observed 10-year percentage-point changes across N = 283 country-waves (112 sovereign countries)",
    x = "10-Year Fiscal Change (Percentage Points)",
    y = "Kernel Density",
    fill = "Tertiary Funding Regime:",
    colour = "Tertiary Funding Regime:"
  ) +
  theme_pub(base_size = 10.5)

save_eda_fig(p_eda1, "eda_fig1_raw_distributions_and_bivariate", width = 8.8, height = 5.2)

# EDA Figure 2: Propensity Score Common Support & Positivity Across Income Groups
p_eda2 <- df_5y_comp %>%
  mutate(
    Regime = ifelse(Z_regime_inc == 1,
                    "High Per-Student Tertiary Spend (Z = 1)",
                    "Low Per-Student Tertiary Spend (Z = 0)")
  ) %>%
  ggplot(aes(x = pi_hat, fill = Regime, colour = Regime)) +
  geom_histogram(aes(y = after_stat(density)), position = "identity", bins = 22, alpha = 0.40) +
  geom_density(linewidth = 0.8, fill = NA) +
  facet_wrap(~ income_group, ncol = 2, scales = "free_y") +
  scale_fill_manual(values = c(okabe_ito[["orange"]], okabe_ito[["navy"]])) +
  scale_colour_manual(values = c(okabe_ito[["orange"]], okabe_ito[["navy"]])) +
  labs(
    title = "Propensity Score Overlap Across World Bank Income Groups",
    subtitle = "Pre-treatment propensity score pi_hat(X_i,t) across N = 372 country-waves (121 countries)",
    x = "Estimated Pre-Treatment Propensity Score pi_hat(X_i,t)",
    y = "Density",
    fill = "Treatment Assignment:",
    colour = "Treatment Assignment:"
  ) +
  theme_pub(base_size = 10.5)

save_eda_fig(p_eda2, "eda_fig2_propensity_overlap", width = 8.8, height = 5.0)

# EDA Figure 3: Baseline Feature Correlation Heatmap
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
    title = "Pre-Treatment Baseline Covariate Correlation Matrix",
    subtitle = "Pairwise correlations across the 17 continuous baseline confounders (N = 372 country-waves)",
    x = NULL,
    y = NULL,
    fill = "Pearson r"
  ) +
  theme_pub(base_size = 10) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

save_eda_fig(p_eda3, "eda_fig3_feature_correlation_heatmap", width = 8.5, height = 6.2)

cat("Phase 3 EDA tables (Tables 0-6) and figures (eda_fig1-eda_fig3) successfully generated.\n")
