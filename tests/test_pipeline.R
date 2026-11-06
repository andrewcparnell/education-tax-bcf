#!/usr/bin/env Rscript
# ==============================================================================
# Automated Pipeline & Reproducibility Test Suite (tests/test_pipeline.R)
#
# Verifies:
#   1. Panel structure, zero duplicate (iso3, wave_index) keys, and anomaly screening.
#   2. Country-blocked fold isolation (each sovereign country appears in 1 fold).
#   3. Existence and non-emptiness of all required output CSV tables and PDF/PNG figures.
#   4. Numerical invariants across mvbcf (Table 1) and lbcf_3wave (Table 5).
# ==============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

repo_root <- getwd()
if (!dir.exists(file.path(repo_root, "src")) && dir.exists(file.path(dirname(repo_root), "src"))) {
  repo_root <- dirname(repo_root)
}

cat("Running automated pipeline verification tests...\n")

# 1. Verify processed panel invariants
panel_path <- file.path(repo_root, "data", "processed", "clean_tax_panel.csv")
stopifnot("clean_tax_panel.csv missing" = file.exists(panel_path))
df <- read_csv(panel_path, show_col_types = FALSE)

stopifnot("Expected 1,736 rows (217 countries x 8 waves)" = nrow(df) == 1736)
stopifnot("Expected 217 sovereign countries" = n_distinct(df$iso3) == 217)
dup_keys <- df %>% count(iso3, wave_index) %>% filter(n > 1)
stopifnot("Duplicate (iso3, wave_index) keys found" = nrow(dup_keys) == 0)

# Verify tax-to-GDP anomaly bounds [0.5%, 60.0%]
valid_tax <- na.omit(df$non_resource_tax_gdp_pct)
stopifnot("Tax-to-GDP values outside [0.5, 60.0] found" = all(valid_tax >= 0.5 & valid_tax <= 60.0))

# 2. Verify country-blocked fold isolation
folds_path <- file.path(repo_root, "data", "processed", "splits", "country_folds.csv")
stopifnot("country_folds.csv missing" = file.exists(folds_path))
folds_df <- read_csv(folds_path, show_col_types = FALSE)
max_folds <- folds_df %>% group_by(iso3) %>% summarise(nf = n_distinct(country_fold)) %>% pull(nf) %>% max()
stopifnot("Country fold leakage detected" = max_folds == 1)

# 3. Verify all output tables exist and are non-empty
req_tables <- c(
  "leakage_audit.csv",
  "table1_mvbcf_ate_posteriors.csv",
  "table2_residual_correlations.csv",
  "table3_subgroup_cates.csv",
  "table_method_benchmarks.csv",
  "table_moderator_importance.csv",
  "table4_robustness_checks.csv",
  "table5_longitudinal_bcf_trajectories.csv",
  "tableA1_convergence_and_fit_diagnostics.csv",
  "tableA2_compute_and_energy.csv",
  "tableA3_propensity_overlap_and_balance.csv"
)

for (tb in req_tables) {
  tb_path <- file.path(repo_root, "outputs", "tables", tb)
  stopifnot( file.exists(tb_path))
  tb_df <- read_csv(tb_path, show_col_types = FALSE)
  stopifnot(nrow(tb_df) > 0)
}

# 4. Verify all publication figures exist in paper/figures/
req_figs <- c(
  "fig1_structural_schematic.pdf",
  "eda_fig1_raw_distributions_and_bivariate.pdf",
  "fig2_total_vs_direct_tax_posteriors.pdf",
  "fig3_denominator_unbundling_horserace.pdf",
  "fig4_enrolment_and_oecd_moderation.pdf",
  "fig5_longitudinal_country_trajectories.pdf",
  "figA1_mcmc_convergence_traces.pdf"
)

for (fg in req_figs) {
  fg_path <- file.path(repo_root, "paper", "figures", fg)
  stopifnot(file.exists(fg_path))
}

# 4b. Verify interactive app files exist in app/
req_app <- c(
  "index.html",
  "app.js",
  "styles.css",
  "app.R",
  "prepare_app_data.R",
  "README.md",
  "data/country_cates.csv",
  "data/historical_waves.csv",
  "data/app_data.json",
  "data/app_data.js"
)
for (af in req_app) {
  af_path <- file.path(repo_root, "app", af)
  stopifnot(file.exists(af_path))
}

# 5. Verify numerical consistency between CSV tables and paper.tex / paper.md
tex_str <- paste(readLines(file.path(repo_root, "paper", "paper.tex"), warn = FALSE), collapse = "\n")
md_str  <- paste(readLines(file.path(repo_root, "paper", "paper.md"), warn = FALSE), collapse = "\n")

tab1 <- read_csv(file.path(repo_root, "outputs", "tables", "table1_mvbcf_ate_posteriors.csv"), show_col_types = FALSE)
for (m_id in c("M1b_Total_10y", "M2a_Direct_5y", "M2b_Direct_10y", "M3b_ObsExp_10y", "M3d_RealPPP_10y")) {
  sub <- tab1 %>% filter(model_id == m_id, outcome_index %in% c(1, 2, 3))
  for (val in sprintf("%+.2f", sub$ate_mean)) {
    stopifnot("Missing ATE number in paper.tex" = grepl(val, tex_str, fixed = TRUE))
    stopifnot("Missing ATE number in paper.md"  = grepl(val, md_str, fixed = TRUE))
  }
}

tab5 <- read_csv(file.path(repo_root, "outputs", "tables", "table5_longitudinal_bcf_trajectories.csv"), show_col_types = FALSE)
for (val in sprintf("%+.2f", tab5$ate_cum_10y_mean)) {
  stopifnot("Missing lbcf cumulative ATE in paper.tex" = grepl(val, tex_str, fixed = TRUE))
  stopifnot("Missing lbcf cumulative ATE in paper.md"  = grepl(val, md_str, fixed = TRUE))
}

cat("ALL AUTOMATED PIPELINE TESTS PASSED (0 errors)!\n")
