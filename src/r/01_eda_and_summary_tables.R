#!/usr/bin/env Rscript
# ==============================================================================
# Step 2: Exploratory Data Analysis & Descriptive Summary Tables
# (src/r/01_eda_and_summary_tables.R)
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(ggplot2)
})

repo_root <- "/Users/andrewparnell/Documents/GitHub/education-tax-bcf"
proc_dir  <- file.path(repo_root, "data", "processed")
tab_dir   <- file.path(repo_root, "results", "tables")
fig_dir   <- file.path(repo_root, "results", "figures")
dir.create(tab_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

df <- read_csv(file.path(proc_dir, "clean_tax_panel.csv"), show_col_types = FALSE)

# 1. Summary Table by Income Group (Table EDA 1)
eda_by_income <- df %>%
  filter(!is.na(tert_spend_per_student_winsor) | !is.na(tert_spend_gdp_pct)) %>%
  mutate(income_group = factor(income_group, levels = c(
    "Low income", "Lower middle income", "Upper middle income", "High income"
  ))) %>%
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

write_csv(eda_by_income, file.path(tab_dir, "eda_table1_income_group_summary.csv"))
cat("\n=== EDA Table 1: University Spending & Fiscal Structure by Income Group ===\n")
print(eda_by_income)

# 2. Sample Sizes & Raw Mean Changes for the 4 Fiscal Outcomes (+5y and +10y)
y5_cols  <- c("d_t1_nonres_tax_gdp_pp", "d_t1_inc_tax_gdp_pp", "d_t1_inc_tax_share_pp", "d_t1_goods_tax_share_pp")
y10_cols <- c("d_t2_nonres_tax_gdp_pp", "d_t2_inc_tax_gdp_pp", "d_t2_inc_tax_share_pp", "d_t2_goods_tax_share_pp")

df_5y_complete <- df %>%
  filter(complete.cases( across(all_of(c(y5_cols, "Z_regime_inc"))) ))
df_10y_complete <- df %>%
  filter(complete.cases( across(all_of(c(y10_cols, "Z_regime_inc"))) ))

cat(sprintf("\nComplete 4-Outcome Fiscal Sample (+5y): N = %d country-waves across %d countries.\n",
            nrow(df_5y_complete), n_distinct(df_5y_complete$iso3)))
cat(sprintf("Complete 4-Outcome Fiscal Sample (+10y): N = %d country-waves across %d countries.\n",
            nrow(df_10y_complete), n_distinct(df_10y_complete$iso3)))

raw_diff_summary <- bind_rows(
  df_5y_complete %>%
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
  df_10y_complete %>%
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

write_csv(raw_diff_summary, file.path(tab_dir, "eda_table2_raw_fiscal_changes_by_regime.csv"))
cat("\n=== EDA Table 2: Unadjusted Fiscal Changes by University Funding Regime ===\n")
print(raw_diff_summary)
