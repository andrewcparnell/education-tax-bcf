#!/usr/bin/env Rscript
# ==============================================================================
# Step 02: Clean Disaggregated Tax & Tertiary Education Panel Builder
# (src/r/02_build_clean_tax_panel.R)
#
# Pure R implementation replacing 02_build_clean_tax_panel.py.
# Constructs the analysis-ready cross-country panel datasets:
#   1. data/processed/clean_tax_panel.csv (8 non-overlapping 5-year waves: 1985-1989 to 2020-2024)
#   2. data/processed/clean_tax_panel_10y_nonoverlapping.csv (non-overlapping decadal waves)
#   3. data/processed/data_dictionary.csv (complete Phase 2 variable dictionary)
#   4. data/processed/codebook_variables.csv (legacy compatibility codebook)
#   5. data/processed/splits/country_folds.csv (5-fold country-blocked split definitions)
#
# Phase 2 Data Hygiene & Measurement Guarantees:
#   - Zero mechanical GDP product identities: all 4 fiscal outcomes are pure tax-take shares
#     or percentage-point changes in GDP/revenue ratios.
#   - Zero cross-sectional proxy imputation on treatments or outcomes.
#   - Exclusive focus on tertiary education spending across unbundled denominators:
#       (1) Z_regime_inc / Z_expansion_obs: Per-student tertiary spending (% of GDP per person)
#       (2) Z_real_spend_regime / Z_real_spend_expansion: Real 2021 PPP dollars per tertiary student
#       (3) Z_tert_gdp_regime / Z_tert_gdp_expansion: Public tertiary budget (% of GDP)
#   - Screens physically/accounting-impossible WDI tax-to-GDP reporting anomalies (>60% or <0.5%
#     of GDP: Sudan 1995-1999 at 629.2% and Timor-Leste 2010-2014 at 110.0%).
#   - Retains SWIID posterior standard errors (swiid_gini_disp_se) for measurement-error sensitivity.
#   - Strictly separates pre-treatment baseline controls (using lagged t-1 GDP growth) from
#     contemporaneous macroeconomic mediators over [t, t+h].
# ==============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
})

repo_root <- getwd()
if (!dir.exists(file.path(repo_root, "src")) && dir.exists(file.path(dirname(dirname(repo_root)), "src"))) {
  repo_root <- dirname(dirname(repo_root))
}
raw_dir   <- file.path(repo_root, "data", "raw")
proc_dir  <- file.path(repo_root, "data", "processed")
split_dir <- file.path(proc_dir, "splits")
dir.create(proc_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(split_dir, recursive = TRUE, showWarnings = FALSE)

# 1. Load sovereign country metadata
meta_df <- read_csv(file.path(raw_dir, "wb_countries_metadata.csv"), show_col_types = FALSE) %>%
  mutate(
    iso3 = trimws(iso3),
    iso2 = ifelse(is.na(iso2), "", trimws(iso2)),
    country_name = trimws(country_name),
    region = trimws(region),
    income_group = trimws(income_group),
    is_oecd = as.integer(is_oecd),
    oecd_public_tert_share_pct = suppressWarnings(as.numeric(oecd_public_tert_share_pct)),
    oecd_finance_regime = ifelse(
      is.na(oecd_finance_regime) | trimws(oecd_finance_regime) == "",
      "Non-OECD",
      trimws(oecd_finance_regime)
    )
  ) %>%
  arrange(iso3)

valid_iso3 <- meta_df$iso3
name_to_iso3 <- setNames(meta_df$iso3, tolower(meta_df$country_name))

swiid_aliases <- c(
  "bahamas" = "BHS", "bolivia" = "BOL", "cape verde" = "CPV", "congo-brazzaville" = "COG",
  "congo-kinshasa" = "COD", "cote d'ivoire" = "CIV", "c\u00f4te d'ivoire" = "CIV",
  "czechia" = "CZE", "czech republic" = "CZE", "egypt" = "EGY", "eswatini" = "SWZ",
  "gambia" = "GMB", "hong kong" = "HKG", "iran" = "IRN", "korea" = "KOR",
  "south korea" = "KOR", "kyrgyzstan" = "KGZ", "laos" = "LAO", "micronesia" = "FSM",
  "moldova" = "MDA", "palestinian territories" = "PSE", "russia" = "RUS",
  "sao tome and principe" = "STP", "s\u00e3o tom\u00e9 and pr\u00edncipe" = "STP", "slovakia" = "SVK",
  "st. lucia" = "LCA", "st. vincent and the grenadines" = "VCT", "syria" = "SYR",
  "taiwan" = "TWN", "tanzania" = "TZA", "timor-leste" = "TLS", "turkiye" = "TUR",
  "t\u00fcrkiye" = "TUR", "turkey" = "TUR", "united states" = "USA", "venezuela" = "VEN",
  "vietnam" = "VNM", "yemen" = "YEM"
)

# 2. Load World Bank / UNESCO / IMF / WGI long series
wb_long <- read_csv(file.path(raw_dir, "wb_unesco_imf_wgi_long.csv"), show_col_types = FALSE) %>%
  mutate(
    iso3 = trimws(iso3),
    year = as.integer(year),
    variable = trimws(variable),
    value = suppressWarnings(as.numeric(value))
  ) %>%
  filter(iso3 %in% valid_iso3, !is.na(year), !is.na(value), year >= 1985, year <= 2024) %>%
  select(iso3, year, variable, value)

# 3. Load SWIID inequality data (retaining standard errors for measurement-error checks)
swiid_raw <- read_csv(file.path(raw_dir, "swiid_summary.csv"), show_col_types = FALSE) %>%
  mutate(
    cname_low = tolower(trimws(country)),
    iso3 = ifelse(
      cname_low %in% names(name_to_iso3),
      name_to_iso3[cname_low],
      swiid_aliases[cname_low]
    ),
    year = suppressWarnings(as.integer(year))
  ) %>%
  filter(!is.na(iso3), iso3 %in% valid_iso3, !is.na(year), year >= 1985, year <= 2024) %>%
  select(iso3, year,
         swiid_gini_disp = gini_disp,
         swiid_gini_disp_se = gini_disp_se,
         swiid_gini_mkt = gini_mkt,
         swiid_gini_mkt_se = gini_mkt_se) %>%
  pivot_longer(
    cols = c(swiid_gini_disp, swiid_gini_disp_se, swiid_gini_mkt, swiid_gini_mkt_se),
    names_to = "variable",
    values_to = "value"
  ) %>%
  filter(!is.na(value))

all_long <- bind_rows(wb_long, swiid_raw) %>%
  mutate(
    wave_index = floor((year - 1985L) / 5L) + 1L
  ) %>%
  filter(wave_index >= 1L, wave_index <= 8L)

# Wave lookup table
waves_df <- tibble(
  wave_index = 1:8,
  wave_label = c("1985-1989", "1990-1994", "1995-1999", "2000-2004",
                 "2005-2009", "2010-2014", "2015-2019", "2020-2024"),
  wave_start_year = seq(1985L, 2020L, by = 5L)
)

base_vars <- c(
  "tert_spend_per_student_gdp_pc",
  "seco_spend_per_student_gdp_pc",
  "prim_spend_per_student_gdp_pc",
  "edu_spend_total_gdp_pct",
  "tert_share_of_edu_spend_pct",
  "gross_tert_enrolment_pct",
  "gross_seco_enrolment_pct",
  "labour_force_advanced_edu_pct",
  "tertiary_attainment_bachelor_25plus_pct",
  "gdp_per_capita_ppp_const2021",
  "gdp_per_capita_growth_pct",
  "tax_rev_gdp_pct",
  "gov_rev_ex_grants_gdp_pct",
  "natural_resource_rents_gdp_pct",
  "income_profit_tax_share_rev_pct",
  "goods_services_tax_share_rev_pct",
  "trade_tax_share_rev_pct",
  "social_contrib_share_rev_pct",
  "wb_gini_index",
  "swiid_gini_disp",
  "swiid_gini_disp_se",
  "swiid_gini_mkt",
  "swiid_gini_mkt_se",
  "life_expectancy_birth_yrs",
  "infant_mortality_per_1000",
  "population_total",
  "working_age_pop_15_64_pct",
  "gross_fixed_capital_form_gdp_pct",
  "trade_openness_gdp_pct",
  "rd_expenditure_gdp_pct",
  "unemployment_rate_pct"
)

# Aggregate country-year observations to 5-year wave means
wave_means <- all_long %>%
  filter(variable %in% base_vars) %>%
  group_by(iso3, wave_index, variable) %>%
  summarise(val = mean(value, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = variable, values_from = val)

# Ensure all 217 countries x 8 waves = 1,736 rows exist and all base_vars columns are present
grid_df <- expand_grid(iso3 = meta_df$iso3, wave_index = 1:8) %>%
  left_join(meta_df, by = "iso3") %>%
  left_join(waves_df, by = "wave_index") %>%
  left_join(wave_means, by = c("iso3", "wave_index"))

for (v in base_vars) {
  if (!v %in% names(grid_df)) grid_df[[v]] <- NA_real_
}

# Report anomalies screened out before filtering
anomalies <- grid_df %>%
  filter(!is.na(tax_rev_gdp_pct) & (tax_rev_gdp_pct < 0.5 | tax_rev_gdp_pct > 60.0)) %>%
  select(iso3, country_name, wave_label, tax_rev_gdp_pct)
cat(sprintf("Screened %d impossible WDI tax-to-GDP reporting anomalies (<0.5%% or >60%% of GDP):\n", nrow(anomalies)))
for (r in seq_len(nrow(anomalies))) {
  cat(sprintf("  - %s (%s) in %s: raw tax_rev_gdp_pct = %.2f%%\n",
              anomalies$country_name[r], anomalies$iso3[r],
              anomalies$wave_label[r], anomalies$tax_rev_gdp_pct[r]))
}

tert_anomalies <- grid_df %>%
  filter(!is.na(tert_spend_per_student_gdp_pc) & tert_spend_per_student_gdp_pc > 0 & tert_spend_per_student_gdp_pc < 1.0) %>%
  select(iso3, country_name, wave_label, tert_spend_per_student_gdp_pc)
cat(sprintf("Screened %d impossible UNESCO tertiary per-student reporting anomaly (<1.0%% of GDP per person):\n", nrow(tert_anomalies)))
for (r in seq_len(nrow(tert_anomalies))) {
  cat(sprintf("  - %s (%s) in %s: raw tert_spend_per_student_gdp_pc = %.4f%%\n",
              tert_anomalies$country_name[r], tert_anomalies$iso3[r],
              tert_anomalies$wave_label[r], tert_anomalies$tert_spend_per_student_gdp_pc[r]))
}

# Construct wave-level derived variables
panel_df <- grid_df %>%
  mutate(
    log_gdp_pc_ppp = ifelse(!is.na(gdp_per_capita_ppp_const2021) & gdp_per_capita_ppp_const2021 > 0,
                            log(gdp_per_capita_ppp_const2021), NA_real_),
    # Screen out impossible WDI reporting anomalies
    tax_rev_gdp_pct_unscreened = tax_rev_gdp_pct,
    tax_rev_gdp_pct = ifelse(!is.na(tax_rev_gdp_pct) & tax_rev_gdp_pct >= 0.5 & tax_rev_gdp_pct <= 60.0,
                             tax_rev_gdp_pct, NA_real_),
    gov_rev_ex_grants_gdp_pct = ifelse(!is.na(gov_rev_ex_grants_gdp_pct) & gov_rev_ex_grants_gdp_pct >= 0.5 & gov_rev_ex_grants_gdp_pct <= 70.0,
                                       gov_rev_ex_grants_gdp_pct, NA_real_),
    res_rents_clean = ifelse(is.na(natural_resource_rents_gdp_pct), 0.0, natural_resource_rents_gdp_pct),
    non_resource_tax_gdp_pct = case_when(
      !is.na(tax_rev_gdp_pct) & tax_rev_gdp_pct > 0 ~ pmax(tax_rev_gdp_pct - 0.5 * pmax(res_rents_clean - 10.0, 0.0), 2.0),
      !is.na(gov_rev_ex_grants_gdp_pct) & gov_rev_ex_grants_gdp_pct > 0 ~ pmax(gov_rev_ex_grants_gdp_pct - 0.7 * res_rents_clean, 2.0),
      TRUE ~ NA_real_
    ),
    inc_tax_gdp_pct = ifelse(!is.na(non_resource_tax_gdp_pct) & !is.na(income_profit_tax_share_rev_pct) & income_profit_tax_share_rev_pct >= 0,
                             non_resource_tax_gdp_pct * (income_profit_tax_share_rev_pct / 100.0), NA_real_),
    goods_tax_gdp_pct = ifelse(!is.na(non_resource_tax_gdp_pct) & !is.na(goods_services_tax_share_rev_pct) & goods_services_tax_share_rev_pct >= 0,
                               non_resource_tax_gdp_pct * (goods_services_tax_share_rev_pct / 100.0), NA_real_),
    gini_disp_harmonised = ifelse(!is.na(swiid_gini_disp), swiid_gini_disp, wb_gini_index),
    # Screen out UNESCO unit-scale error (<1.0% of GDP per person, e.g. MDG 2015-2019 at 0.0359%)
    tert_spend_raw = ifelse(!is.na(tert_spend_per_student_gdp_pc) & tert_spend_per_student_gdp_pc >= 1.0,
                            tert_spend_per_student_gdp_pc, NA_real_),
    tert_spend_per_student_winsor = ifelse(!is.na(tert_spend_raw),
                                           pmin(pmax(tert_spend_raw, 1.0), 150.0), NA_real_),
    log_tert_spend_winsor = ifelse(!is.na(tert_spend_raw) & tert_spend_raw > 0,
                                   log(tert_spend_raw), NA_real_),
    real_tert_spend_per_student_ppp = ifelse(!is.na(tert_spend_raw) & !is.na(gdp_per_capita_ppp_const2021) & gdp_per_capita_ppp_const2021 > 0,
                                             gdp_per_capita_ppp_const2021 * (tert_spend_raw / 100.0), NA_real_),
    log_real_tert_spend_per_student = ifelse(!is.na(real_tert_spend_per_student_ppp) & real_tert_spend_per_student_ppp > 0,
                                             log(real_tert_spend_per_student_ppp), NA_real_),
    tert_spend_gdp_pct = ifelse(!is.na(edu_spend_total_gdp_pct) & edu_spend_total_gdp_pct > 0 &
                                  !is.na(tert_share_of_edu_spend_pct) & tert_share_of_edu_spend_pct > 0,
                                edu_spend_total_gdp_pct * (tert_share_of_edu_spend_pct / 100.0), NA_real_),
    log_population = ifelse(!is.na(population_total) & population_total > 0, log(population_total), NA_real_)
  ) %>%
  select(-res_rents_clean, -tax_rev_gdp_pct_unscreened)

# Create deterministic 5-fold country-blocked split BEFORE computing centring medians
# Stratified by World Bank income_group and whether country has observed tertiary & tax data
# Fold 1-4 = 80% Training/CV Countries; Fold 5 = 20% Locked Holdout Test Countries
set.seed(20261103)
country_strata <- panel_df %>%
  group_by(iso3, income_group) %>%
  summarise(
    has_tert_and_tax = as.integer(any(!is.na(tert_spend_raw) & !is.na(non_resource_tax_gdp_pct))),
    .groups = "drop"
  ) %>%
  arrange(income_group, desc(has_tert_and_tax), iso3) %>%
  group_by(income_group, has_tert_and_tax) %>%
  mutate(
    country_fold = sample(rep(1:5, length.out = n())),
    is_holdout_test = ifelse(country_fold == 5L, 1L, 0L)
  ) %>%
  ungroup() %>%
  select(iso3, country_fold, is_holdout_test) %>%
  arrange(iso3)

write_csv(country_strata, file.path(split_dir, "country_folds.csv"))

panel_df <- panel_df %>%
  left_join(country_strata, by = "iso3")

# Compute global and income-group centring medians strictly on TRAINING countries (is_holdout_test == 0)
# to prevent any information leakage from the 20% held-out test countries
train_panel <- panel_df %>% filter(is_holdout_test == 0L)
global_med_spend <- median(train_panel$tert_spend_raw, na.rm = TRUE)

inc_meds <- train_panel %>%
  group_by(income_group) %>%
  summarise(
    med_spend_raw = median(tert_spend_raw, na.rm = TRUE),
    med_spend_winsor = median(tert_spend_per_student_winsor, na.rm = TRUE),
    med_log_spend_winsor = median(log_tert_spend_winsor, na.rm = TRUE),
    med_real_spend = median(log_real_tert_spend_per_student, na.rm = TRUE),
    med_tert_gdp = median(tert_spend_gdp_pct, na.rm = TRUE),
    med_edu_total = median(edu_spend_total_gdp_pct, na.rm = TRUE),
    .groups = "drop"
  )

panel_df <- panel_df %>%
  left_join(inc_meds, by = "income_group") %>%
  arrange(iso3, wave_index) %>%
  group_by(iso3) %>%
  mutate(
    # Pre-treatment lagged (t-1) covariates and pre-treatment placebo trends (t-1 -> t)
    lag_gdp_pc_growth_pct = lag(gdp_per_capita_growth_pct, 1L),
    lag_nonres_tax_gdp_pct = lag(non_resource_tax_gdp_pct, 1L),
    lag_inc_tax_share_pct = lag(income_profit_tax_share_rev_pct, 1L),
    d_prev_nonres_tax_gdp_pp = non_resource_tax_gdp_pct - lag(non_resource_tax_gdp_pct, 1L),
    d_prev_inc_tax_gdp_pp = inc_tax_gdp_pct - lag(inc_tax_gdp_pct, 1L),
    d_prev_inc_tax_share_pp = income_profit_tax_share_rev_pct - lag(income_profit_tax_share_rev_pct, 1L),
    d_prev_goods_tax_share_pp = goods_services_tax_share_rev_pct - lag(goods_services_tax_share_rev_pct, 1L),

    # Primary Continuous Tertiary Treatments (Scaling A & Scaling B)
    # Raw signed deviations from training income-group median (saved for sensitivity checks):
    Z_cont_10pp_raw = ifelse(!is.na(tert_spend_per_student_winsor) & !is.na(med_spend_winsor),
                             (tert_spend_per_student_winsor - med_spend_winsor) / 10.0, NA_real_),
    Z_cont_log25pct_raw = ifelse(!is.na(log_tert_spend_winsor) & !is.na(med_log_spend_winsor),
                                 (log_tert_spend_winsor - med_log_spend_winsor) / log(1.25), NA_real_),
    # Scaling A (Z_cont_10pp): Zero-centred continuous treatment in [-1.5, +1.5] (+10 pp of GDP/pc per unit,
    # winsorised at [-1.5, +1.5] around training income-group median so Z = 0 at the median)
    Z_cont_10pp = ifelse(!is.na(Z_cont_10pp_raw),
                         pmin(pmax(Z_cont_10pp_raw, -1.5), 1.5), NA_real_),
    # Scaling B (Z_cont_log25pct): Zero-centred continuous treatment in [-1.5, +1.5] (+25% relative increase per unit,
    # winsorised at [-1.5, +1.5] around training income-group log median so Z = 0 at the median)
    Z_cont_log25pct = ifelse(!is.na(Z_cont_log25pct_raw),
                             pmin(pmax(Z_cont_log25pct_raw, -1.5), 1.5), NA_real_),

    # Tertiary Treatment 1: Per-Student Spending Ratio (% of GDP per person) Changes & Binary Reference
    prev_sp_winsor = lag(tert_spend_per_student_winsor, 1L),
    tert_spend_rel_change_pct = ifelse(!is.na(tert_spend_per_student_winsor) & !is.na(prev_sp_winsor) & prev_sp_winsor > 0,
                                       ((tert_spend_per_student_winsor - prev_sp_winsor) / prev_sp_winsor) * 100.0, NA_real_),
    tert_spend_abs_change = ifelse(!is.na(tert_spend_per_student_winsor) & !is.na(prev_sp_winsor) & prev_sp_winsor > 0,
                                   tert_spend_per_student_winsor - prev_sp_winsor, NA_real_),
    Z_cont_delta_10pp = ifelse(!is.na(tert_spend_abs_change),
                               pmin(pmax(tert_spend_abs_change / 10.0, -1.5), 1.5), NA_real_),
    Z_expansion_obs = ifelse(!is.na(tert_spend_abs_change) & !is.na(tert_spend_rel_change_pct),
                             ifelse(tert_spend_abs_change >= 2.5 & tert_spend_rel_change_pct >= 2.5, 1L, 0L), NA_integer_),
    Z_regime_inc = ifelse(!is.na(tert_spend_raw) & !is.na(med_spend_raw),
                          ifelse(tert_spend_raw > med_spend_raw, 1L, 0L), NA_integer_),
    Z_regime_global = ifelse(!is.na(tert_spend_raw) & !is.na(global_med_spend),
                             ifelse(tert_spend_raw > global_med_spend, 1L, 0L), NA_integer_),

    # Tertiary Treatment 2: Real 2021 PPP Dollars per Tertiary Student (no GDP denominator)
    Z_cont_real_ppp_log25pct = ifelse(!is.na(log_real_tert_spend_per_student) & !is.na(med_real_spend),
                                      pmin(pmax((log_real_tert_spend_per_student - med_real_spend) / log(1.25), -1.5), 1.5), NA_real_),
    prev_log_rsp = lag(log_real_tert_spend_per_student, 1L),
    d_log_real_spend_stu_pct = ifelse(!is.na(log_real_tert_spend_per_student) & !is.na(prev_log_rsp),
                                      (log_real_tert_spend_per_student - prev_log_rsp) * 100.0, NA_real_),
    Z_real_spend_expansion = ifelse(!is.na(d_log_real_spend_stu_pct),
                                    ifelse(d_log_real_spend_stu_pct >= 5.0, 1L, 0L), NA_integer_),
    Z_real_spend_regime = ifelse(!is.na(log_real_tert_spend_per_student) & !is.na(med_real_spend),
                                 ifelse(log_real_tert_spend_per_student > med_real_spend, 1L, 0L), NA_integer_),

    # Tertiary Treatment 3: Public Tertiary Budget % of GDP (no student headcount denominator)
    Z_cont_budget_gdp_025pp = ifelse(!is.na(tert_spend_gdp_pct) & !is.na(med_tert_gdp),
                                     pmin(pmax((tert_spend_gdp_pct - med_tert_gdp) / 0.25, -1.5), 1.5), NA_real_),
    prev_bgdp = lag(tert_spend_gdp_pct, 1L),
    d_tert_spend_gdp_pp = ifelse(!is.na(tert_spend_gdp_pct) & !is.na(prev_bgdp),
                                 tert_spend_gdp_pct - prev_bgdp, NA_real_),
    Z_tert_gdp_expansion = ifelse(!is.na(d_tert_spend_gdp_pp),
                                  ifelse(d_tert_spend_gdp_pp >= 0.05, 1L, 0L), NA_integer_),
    Z_tert_gdp_regime = ifelse(!is.na(tert_spend_gdp_pct) & !is.na(med_tert_gdp),
                               ifelse(tert_spend_gdp_pct > med_tert_gdp, 1L, 0L), NA_integer_),
    Z_edu_total_regime = ifelse(!is.na(edu_spend_total_gdp_pct) & !is.na(med_edu_total),
                                ifelse(edu_spend_total_gdp_pct > med_edu_total, 1L, 0L), NA_integer_),

    # Forward outcomes & mediators at +5y (t1)
    d_t1_nonres_tax_gdp_pp = lead(non_resource_tax_gdp_pct, 1L) - non_resource_tax_gdp_pct,
    y_t1_nonres_tax_gdp_pct = lead(non_resource_tax_gdp_pct, 1L),
    d_t1_wdi_tax_gdp_pp = lead(tax_rev_gdp_pct, 1L) - tax_rev_gdp_pct,
    y_t1_wdi_tax_gdp_pct = lead(tax_rev_gdp_pct, 1L),
    d_t1_inc_tax_gdp_pp = lead(inc_tax_gdp_pct, 1L) - inc_tax_gdp_pct,
    y_t1_inc_tax_gdp_pct = lead(inc_tax_gdp_pct, 1L),
    d_t1_inc_tax_share_pp = lead(income_profit_tax_share_rev_pct, 1L) - income_profit_tax_share_rev_pct,
    y_t1_inc_tax_share_pct = lead(income_profit_tax_share_rev_pct, 1L),
    d_t1_goods_tax_share_pp = lead(goods_services_tax_share_rev_pct, 1L) - goods_services_tax_share_rev_pct,
    y_t1_goods_tax_share_pct = lead(goods_services_tax_share_rev_pct, 1L),
    d_t1_goods_tax_gdp_pp = lead(goods_tax_gdp_pct, 1L) - goods_tax_gdp_pct,
    y_t1_goods_tax_gdp_pct = lead(goods_tax_gdp_pct, 1L),
    d_t1_log_gdp_pc_pct = (lead(log_gdp_pc_ppp, 1L) - log_gdp_pc_ppp) * 100.0,
    d_t1_tert_enrol_pp = lead(gross_tert_enrolment_pct, 1L) - gross_tert_enrolment_pct,
    d_t1_gini_disp = lead(gini_disp_harmonised, 1L) - gini_disp_harmonised,
    d_t1_life_exp_yrs = lead(life_expectancy_birth_yrs, 1L) - life_expectancy_birth_yrs,

    # Forward outcomes & mediators at +10y (t2)
    d_t2_nonres_tax_gdp_pp = lead(non_resource_tax_gdp_pct, 2L) - non_resource_tax_gdp_pct,
    y_t2_nonres_tax_gdp_pct = lead(non_resource_tax_gdp_pct, 2L),
    d_t2_wdi_tax_gdp_pp = lead(tax_rev_gdp_pct, 2L) - tax_rev_gdp_pct,
    y_t2_wdi_tax_gdp_pct = lead(tax_rev_gdp_pct, 2L),
    d_t2_inc_tax_gdp_pp = lead(inc_tax_gdp_pct, 2L) - inc_tax_gdp_pct,
    y_t2_inc_tax_gdp_pct = lead(inc_tax_gdp_pct, 2L),
    d_t2_inc_tax_share_pp = lead(income_profit_tax_share_rev_pct, 2L) - income_profit_tax_share_rev_pct,
    y_t2_inc_tax_share_pct = lead(income_profit_tax_share_rev_pct, 2L),
    d_t2_goods_tax_share_pp = lead(goods_services_tax_share_rev_pct, 2L) - goods_services_tax_share_rev_pct,
    y_t2_goods_tax_share_pct = lead(goods_services_tax_share_rev_pct, 2L),
    d_t2_goods_tax_gdp_pp = lead(goods_tax_gdp_pct, 2L) - goods_tax_gdp_pct,
    y_t2_goods_tax_gdp_pct = lead(goods_tax_gdp_pct, 2L),
    d_t2_log_gdp_pc_pct = (lead(log_gdp_pc_ppp, 2L) - log_gdp_pc_ppp) * 100.0,
    d_t2_tert_enrol_pp = lead(gross_tert_enrolment_pct, 2L) - gross_tert_enrolment_pct,
    d_t2_gini_disp = lead(gini_disp_harmonised, 2L) - gini_disp_harmonised,
    d_t2_life_exp_yrs = lead(life_expectancy_birth_yrs, 2L) - life_expectancy_birth_yrs
  ) %>%
  ungroup() %>%
  select(-med_spend_raw, -med_spend_winsor, -med_log_spend_winsor,
         -med_real_spend, -med_tert_gdp, -med_edu_total,
         -prev_sp_winsor, -prev_log_rsp, -prev_bgdp)

# Hygiene Check: Verify zero duplicate (iso3, wave_index) keys
n_dups <- nrow(panel_df) - n_distinct(paste(panel_df$iso3, panel_df$wave_index))
if (n_dups > 0) stop(sprintf("Found %d duplicate country-wave rows!", n_dups))
cat(sprintf("Hygiene check passed: 0 duplicate keys across %d country-wave rows (%d sovereign countries x 8 waves).\n",
            nrow(panel_df), n_distinct(panel_df$iso3)))
cat(sprintf("Stratified 5-fold country-blocked split saved to %s (%d training countries in folds 1-4; %d locked holdout test countries in fold 5).\n",
            file.path("data/processed/splits", "country_folds.csv"),
            sum(country_strata$is_holdout_test == 0L),
            sum(country_strata$is_holdout_test == 1L)))

# Save 5-year and non-overlapping 10-year panels
out_5y <- file.path(proc_dir, "clean_tax_panel.csv")
write_csv(panel_df, out_5y, na = "")
cat(sprintf("Saved 5-year panel to %s (%d rows).\n", basename(out_5y), nrow(panel_df)))

panel_10y_nonoverlap <- panel_df %>% filter(wave_index %in% c(2L, 4L, 6L))
out_10y <- file.path(proc_dir, "clean_tax_panel_10y_nonoverlapping.csv")
write_csv(panel_10y_nonoverlap, out_10y, na = "")
cat(sprintf("Saved non-overlapping 10-year panel to %s (%d rows).\n", basename(out_10y), nrow(panel_10y_nonoverlap)))

# Build comprehensive Phase 2 Data Dictionary (data/processed/data_dictionary.csv)
calc_range <- function(col) {
  v <- panel_df[[col]]
  if (is.numeric(v)) {
    v_clean <- v[!is.na(v)]
    if (length(v_clean) == 0) return("NA")
    sprintf("[%.2f, %.2f]", min(v_clean), max(v_clean))
  } else {
    v_clean <- unique(v[!is.na(v) & v != ""])
    sprintf("%d unique categories", length(v_clean))
  }
}

calc_miss_pct <- function(col) {
  v <- panel_df[[col]]
  round(100 * mean(is.na(v) | (is.character(v) & v == "")), 1)
}

dict_spec <- tribble(
  ~variable, ~role, ~description, ~units, ~data_type, ~source,
  "iso3", "Identifier", "ISO 3166-1 alpha-3 sovereign country code", "3-letter code", "character", "World Bank Country Metadata API",
  "iso2", "Identifier", "ISO 3166-1 alpha-2 two-letter country code", "2-letter code", "character", "World Bank Country Metadata API",
  "country_name", "Identifier", "Sovereign country name", "Text label", "character", "World Bank Country Metadata API",
  "region", "Baseline Covariate", "World Bank geographic region", "7 categories", "character", "World Bank Country Metadata API",
  "income_group", "Baseline Covariate / Moderator", "World Bank national income group tier", "4 ordered tiers", "character", "World Bank Country Metadata API",
  "is_oecd", "Baseline Covariate / Moderator", "Indicator for OECD member state", "Binary (0 or 1)", "integer", "OECD / World Bank Metadata",
  "country_fold", "Split Identifier", "Income-stratified 5-fold country assignment (1-4 = training/CV folds; 5 = locked holdout test fold)", "Fold integer (1-5)", "integer", "Constructed (set.seed(20261103))",
  "is_holdout_test", "Split Identifier", "1 if country is in the locked 20% holdout test set (country_fold == 5); 0 if in 80% training set", "Binary (0 or 1)", "integer", "Constructed (set.seed(20261103))",
  "wave_index", "Time Index", "Non-overlapping 5-year wave index (1 = 1985-1989 to 8 = 2020-2024)", "Wave integer (1-8)", "integer", "Constructed (5-year windows)",
  "wave_label", "Time Index", "Calendar year range of the 5-year wave", "Year interval", "character", "Constructed (5-year windows)",
  "tert_spend_raw", "Treatment (Continuous Raw)", "Un-winsorised public expenditure per tertiary student as % of GDP per person (screened >= 1.0%)", "% of GDP per person", "numeric", "UNESCO UIS (SE.XPD.TERT.PC.ZS)",
  "tert_spend_per_student_winsor", "Treatment (Continuous Raw)", "Public expenditure per tertiary student (% of GDP per person, winsorised at [1, 150])", "% of GDP per person", "numeric", "UNESCO UIS (SE.XPD.TERT.PC.ZS)",
  "Z_cont_10pp", "Primary Continuous Treatment (Scaling A)", "Winsorised per-student tertiary spending centred on training income-group median, scaled per +10 pp of GDP per person", "+10 pp of GDP/pc per student", "numeric", "Constructed (Scaling A)",
  "Z_cont_log25pct", "Primary Continuous Treatment (Scaling B)", "Log per-student tertiary spending centred on training income-group log median, scaled per +25% relative increase (log(1.25))", "+25% relative increase", "numeric", "Constructed (Scaling B)",
  "Z_cont_delta_10pp", "Continuous Treatment (1B: 5y Change)", "Within-country 5-year change in per-student tertiary spending ratio, scaled per +10 pp of GDP per person", "+10 pp 5-year change", "numeric", "Constructed (within-country change)",
  "real_tert_spend_per_student_ppp", "Treatment (Continuous Raw)", "Real constant-2021 PPP international dollars spent per tertiary student (no GDP denominator)", "2021 PPP USD / student", "numeric", "UNESCO UIS & WDI (SE.XPD.TERT.PC.ZS * NY.GDP.PCAP.PP.KD)",
  "Z_cont_real_ppp_log25pct", "Continuous Treatment (2A: Real PPP Dollars)", "Log real 2021 PPP dollars per tertiary student centred on training income-group median, scaled per +25% increase", "+25% real PPP USD / student", "numeric", "Constructed (no GDP denominator)",
  "tert_spend_gdp_pct", "Treatment (Continuous Raw)", "Public tertiary education expenditure as % of GDP (no student headcount denominator)", "% of GDP", "numeric", "UNESCO UIS (SE.XPD.TOTL.GD.ZS * SE.XPD.TERT.ZS)",
  "Z_cont_budget_gdp_025pp", "Continuous Treatment (3A: Budget % GDP)", "Public tertiary education budget (% of GDP) centred on training income-group median, scaled per +0.25 pp of GDP", "+0.25 pp of GDP", "numeric", "Constructed (no student headcount denominator)",
  "Z_regime_inc", "Legacy Binary Treatment (1A)", "1 if un-winsorised per-student tertiary spending ratio exceeds training World Bank income-group median", "Binary (0 or 1)", "integer", "Constructed (binary benchmark)",
  "Z_expansion_obs", "Legacy Binary Treatment (1B)", "1 if observed per-student tertiary spending ratio increases by >=2.5 pp and >=2.5% over wave", "Binary (0 or 1)", "integer", "Constructed (binary benchmark)",
  "Z_real_spend_regime", "Legacy Binary Treatment (2A)", "1 if real 2021 PPP dollars per tertiary student exceeds training World Bank income-group median", "Binary (0 or 1)", "integer", "Constructed (no GDP denominator)",
  "Z_real_spend_expansion", "Legacy Binary Treatment (2B)", "1 if real 2021 PPP dollars per tertiary student grows by >=5% over 5-year wave", "Binary (0 or 1)", "integer", "Constructed (no GDP denominator)",
  "Z_tert_gdp_regime", "Legacy Binary Treatment (3A)", "1 if public tertiary education budget (% of GDP) exceeds training World Bank income-group median", "Binary (0 or 1)", "integer", "Constructed (no student headcount denominator)",
  "d_t1_nonres_tax_gdp_pp", "Outcome Y1 (+5y)", "5-year change in domestic non-resource tax revenue (% of GDP)", "Percentage points of GDP", "numeric", "IMF GFS / WDI / UNU-WIDER GRD",
  "d_t2_nonres_tax_gdp_pp", "Outcome Y1 (+10y)", "10-year change in domestic non-resource tax revenue (% of GDP)", "Percentage points of GDP", "numeric", "IMF GFS / WDI / UNU-WIDER GRD",
  "d_t1_inc_tax_gdp_pp", "Outcome Y2 (+5y)", "5-year change in direct income, profit, and capital gains tax revenue (% of GDP)", "Percentage points of GDP", "numeric", "IMF GFS / WDI (GC.TAX.YPKG.ZS * NonResTax/GDP)",
  "d_t2_inc_tax_gdp_pp", "Outcome Y2 (+10y)", "10-year change in direct income, profit, and capital gains tax revenue (% of GDP)", "Percentage points of GDP", "numeric", "IMF GFS / WDI (GC.TAX.YPKG.ZS * NonResTax/GDP)",
  "d_t1_inc_tax_share_pp", "Outcome Y3 (+5y)", "5-year change in direct income, profit, and capital gains share of total revenue", "Percentage points of revenue", "numeric", "IMF GFS / WDI (GC.TAX.YPKG.ZS)",
  "d_t2_inc_tax_share_pp", "Outcome Y3 (+10y)", "10-year change in direct income, profit, and capital gains share of total revenue", "Percentage points of revenue", "numeric", "IMF GFS / WDI (GC.TAX.YPKG.ZS)",
  "d_t1_goods_tax_share_pp", "Outcome Y4 (+5y, Negative Control)", "5-year change in indirect goods and services (VAT/consumption) share of revenue", "Percentage points of revenue", "numeric", "IMF GFS / WDI (GC.TAX.GSRV.RV.ZS)",
  "d_t2_goods_tax_share_pp", "Outcome Y4 (+10y, Negative Control)", "10-year change in indirect goods and services (VAT/consumption) share of revenue", "Percentage points of revenue", "numeric", "IMF GFS / WDI (GC.TAX.GSRV.RV.ZS)",
  "d_t1_wdi_tax_gdp_pp", "Robustness Outcome R1 (+5y)", "5-year change in pure unadjusted World Bank WDI tax revenue (% of GDP)", "Percentage points of GDP", "numeric", "World Bank WDI (GC.TAX.TOTL.GD.ZS)",
  "d_t2_wdi_tax_gdp_pp", "Robustness Outcome R1 (+10y)", "10-year change in pure unadjusted World Bank WDI tax revenue (% of GDP)", "Percentage points of GDP", "numeric", "World Bank WDI (GC.TAX.TOTL.GD.ZS)",
  "d_prev_nonres_tax_gdp_pp", "Placebo Outcome R5 (t-1 to t)", "Pre-treatment 5-year change in domestic non-resource tax revenue (% of GDP)", "Percentage points of GDP", "numeric", "IMF GFS / WDI",
  "d_prev_inc_tax_gdp_pp", "Placebo Outcome R5 (t-1 to t)", "Pre-treatment 5-year change in direct income, profit, and capital gains tax (% of GDP)", "Percentage points of GDP", "numeric", "IMF GFS / WDI",
  "d_prev_inc_tax_share_pp", "Placebo Outcome R5 (t-1 to t)", "Pre-treatment 5-year change in direct income and profit share of revenue", "Percentage points of revenue", "numeric", "IMF GFS / WDI",
  "d_prev_goods_tax_share_pp", "Placebo Outcome R5 (t-1 to t)", "Pre-treatment 5-year change in indirect goods and services share of revenue", "Percentage points of revenue", "numeric", "IMF GFS / WDI",
  "log_gdp_pc_ppp", "Pre-Treatment Baseline Control / Moderator", "Natural log of baseline real GDP per person (constant 2021 PPP dollars)", "Log 2021 PPP USD", "numeric", "World Bank WDI (NY.GDP.PCAP.PP.KD)",
  "lag_gdp_pc_growth_pct", "Pre-Treatment Baseline Control", "Lagged (wave t-1) annual real GDP per person growth (avoids contemporaneous collider)", "Annual % growth", "numeric", "World Bank WDI (NY.GDP.PCAP.KD.ZG)",
  "non_resource_tax_gdp_pct", "Pre-Treatment Baseline Control", "Baseline domestic non-resource tax revenue as % of GDP", "% of GDP", "numeric", "IMF GFS / WDI",
  "income_profit_tax_share_rev_pct", "Pre-Treatment Baseline Control / Moderator", "Baseline direct income, profit, and capital gains tax share of revenue", "% of revenue", "numeric", "IMF GFS / WDI (GC.TAX.YPKG.ZS)",
  "goods_services_tax_share_rev_pct", "Pre-Treatment Baseline Control", "Baseline indirect goods and services tax share of revenue", "% of revenue", "numeric", "IMF GFS / WDI (GC.TAX.GSRV.RV.ZS)",
  "gross_tert_enrolment_pct", "Pre-Treatment Baseline Control / Moderator", "Baseline gross tertiary school enrolment ratio", "% of age cohort", "numeric", "UNESCO UIS (SE.TER.ENRR)",
  "gross_seco_enrolment_pct", "Pre-Treatment Baseline Control / Moderator", "Baseline gross secondary school enrolment ratio", "% of age cohort", "numeric", "UNESCO UIS (SE.SEC.ENRR)",
  "edu_spend_total_gdp_pct", "Pre-Treatment Baseline Control", "Baseline total public expenditure on education across all levels (% of GDP)", "% of GDP", "numeric", "UNESCO UIS (SE.XPD.TOTL.GD.ZS)",
  "gini_disp_harmonised", "Pre-Treatment Baseline Control", "Baseline harmonised disposable income Gini index", "Gini points (0-100)", "numeric", "SWIID v9.6 (Solt 2020) & WDI",
  "swiid_gini_disp_se", "Measurement Uncertainty", "Posterior standard error of SWIID disposable income Gini index", "Gini points", "numeric", "SWIID v9.6 (Solt 2020)",
  "life_expectancy_birth_yrs", "Pre-Treatment Baseline Control", "Baseline life expectancy at birth", "Years", "numeric", "World Bank WDI (SP.DYN.LE00.IN)",
  "working_age_pop_15_64_pct", "Pre-Treatment Baseline Control / Moderator", "Baseline share of total population aged 15 to 64", "% of population", "numeric", "World Bank WDI (SP.POP.1564.TO.ZS)",
  "log_population", "Pre-Treatment Baseline Control", "Natural log of baseline total national population", "Log persons", "numeric", "World Bank WDI (SP.POP.TOTL)",
  "unemployment_rate_pct", "Pre-Treatment Baseline Control", "Baseline total unemployment rate (% of labour force)", "% of labour force", "numeric", "World Bank WDI (SL.UEM.TOTL.ZS)",
  "natural_resource_rents_gdp_pct", "Pre-Treatment Baseline Control", "Baseline total natural resource rents (% of GDP)", "% of GDP", "numeric", "World Bank WDI (NY.GDP.TOTL.RT.ZS)",
  "trade_openness_gdp_pct", "Pre-Treatment Baseline Control", "Baseline sum of exports and imports of goods and services (% of GDP)", "% of GDP", "numeric", "World Bank WDI (NE.TRD.GNFS.ZS)",
  "d_t1_log_gdp_pc_pct", "Post-Treatment Mediator (+5y)", "5-year forward real GDP per person PPP log growth (controlled in Direct Effect M2)", "Log % change", "numeric", "World Bank WDI (NY.GDP.PCAP.PP.KD)",
  "d_t2_log_gdp_pc_pct", "Post-Treatment Mediator (+10y)", "10-year forward real GDP per person PPP log growth (controlled in Direct Effect M2)", "Log % change", "numeric", "World Bank WDI (NY.GDP.PCAP.PP.KD)",
  "d_t1_tert_enrol_pp", "Post-Treatment Mediator (+5y)", "5-year forward change in gross tertiary enrolment ratio (controlled in Direct Effect M2)", "Percentage points", "numeric", "UNESCO UIS (SE.TER.ENRR)",
  "d_t2_tert_enrol_pp", "Post-Treatment Mediator (+10y)", "10-year forward change in gross tertiary enrolment ratio (controlled in Direct Effect M2)", "Percentage points", "numeric", "UNESCO UIS (SE.TER.ENRR)",
  "d_t1_gini_disp", "Post-Treatment Mediator (+5y)", "5-year forward change in disposable income Gini index (controlled in Direct Effect M2)", "Gini points", "numeric", "SWIID v9.6 & WDI",
  "d_t2_gini_disp", "Post-Treatment Mediator (+10y)", "10-year forward change in disposable income Gini index (controlled in Direct Effect M2)", "Gini points", "numeric", "SWIID v9.6 & WDI",
  "d_t1_life_exp_yrs", "Post-Treatment Mediator (+5y)", "5-year forward change in life expectancy at birth (controlled in Direct Effect M2)", "Years", "numeric", "World Bank WDI (SP.DYN.LE00.IN)",
  "d_t2_life_exp_yrs", "Post-Treatment Mediator (+10y)", "10-year forward change in life expectancy at birth (controlled in Direct Effect M2)", "Years", "numeric", "World Bank WDI (SP.DYN.LE00.IN)"
) %>%
  mutate(
    temporal_resolution = "5-year non-overlapping wave average (1985-2024)",
    spatial_resolution = "Sovereign country (217 ISO-3 territories)",
    valid_range = vapply(variable, calc_range, character(1)),
    missingness_pct = vapply(variable, calc_miss_pct, numeric(1)),
    missing_value_code = "NA (empty string in CSV)"
  )

dict_path <- file.path(proc_dir, "data_dictionary.csv")
write_csv(dict_spec, dict_path)
cat(sprintf("Saved comprehensive Phase 2 data dictionary to %s (%d variables documented).\n",
            basename(dict_path), nrow(dict_spec)))

# Also keep legacy 4-column codebook_variables.csv in sync
write_csv(dict_spec %>% select(variable, role, description, source),
          file.path(proc_dir, "codebook_variables.csv"))
