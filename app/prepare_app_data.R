# ==============================================================================
# Script: app/prepare_app_data.R
# Purpose: Export clean, self-contained datasets (CSV, JSON, and JS bundle)
#          for the 3-tab interactive exploration app in app/
# Author: Andrew C. Parnell
# ==============================================================================

suppressPackageStartupMessages({
  library(jsonlite)
})

dir.create("app/data", recursive = TRUE, showWarnings = FALSE)

df_full <- read.csv("data/processed/clean_tax_panel.csv", stringsAsFactors = FALSE)
df_5y   <- read.csv("data/processed/panel_5y_with_icates.csv", stringsAsFactors = FALSE)
df_10y  <- read.csv("data/processed/panel_10y_with_icates.csv", stringsAsFactors = FALSE)
tab_ate <- read.csv("outputs/tables/table1_mvbcf_ate_posteriors.csv", stringsAsFactors = FALSE)
tab_sub <- read.csv("outputs/tables/table3_subgroup_cates.csv", stringsAsFactors = FALSE)

# ------------------------------------------------------------------------------
# 1. Country-Level Continuous CATE Slopes (+5y and +10y) + Baseline Moderators
# ------------------------------------------------------------------------------
all_isos <- sort(unique(c(df_5y$iso3, df_10y$iso3)))

mean_na <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) == 0) return(NA_real_)
  round(mean(x), 3)
}

country_rows <- lapply(all_isos, function(iso) {
  sub5  <- df_5y[df_5y$iso3 == iso, , drop = FALSE]
  sub10 <- df_10y[df_10y$iso3 == iso, , drop = FALSE]
  subf  <- df_full[df_full$iso3 == iso, , drop = FALSE]
  subf  <- subf[order(subf$wave_start_year), , drop = FALSE]

  ref <- if (nrow(sub10) > 0) sub10[nrow(sub10), ] else if (nrow(sub5) > 0) sub5[nrow(sub5), ] else subf[nrow(subf), ]

  data.frame(
    iso3 = iso,
    country_name = ref$country_name[1],
    region = ref$region[1],
    income_group = ref$income_group[1],
    is_oecd = as.integer(ref$is_oecd[1]),
    oecd_finance_regime = ifelse(is.na(ref$oecd_finance_regime[1]), "Non-OECD", ref$oecd_finance_regime[1]),
    n_waves_5y = nrow(sub5),
    n_waves_10y = nrow(sub10),
    # Baseline context (country average across estimation waves)
    tert_spend_per_student_gdp_pc = mean_na(subf$tert_spend_per_student_winsor),
    z_cont_10pp = mean_na(subf$Z_cont_10pp),
    z_cont_log25pct = mean_na(subf$Z_cont_log25pct),
    real_tert_spend_per_student_ppp = mean_na(subf$real_tert_spend_per_student_ppp),
    tert_spend_gdp_pct = mean_na(subf$tert_spend_gdp_pct),
    gross_tert_enrolment_pct = mean_na(subf$gross_tert_enrolment_pct),
    gross_seco_enrolment_pct = mean_na(subf$gross_seco_enrolment_pct),
    gdp_per_capita_ppp = mean_na(subf$gdp_per_capita_ppp_const2021),
    gdp_per_capita_latest = mean_na(tail(na.omit(subf$gdp_per_capita_ppp_const2021), 1)),
    population_latest = mean_na(tail(na.omit(subf$population_total), 1)),
    log_gdp_pc_ppp = mean_na(subf$log_gdp_pc_ppp),
    working_age_pop_pct = mean_na(subf$working_age_pop_15_64_pct),
    non_resource_tax_gdp_pct = mean_na(subf$non_resource_tax_gdp_pct),
    inc_tax_gdp_pct = mean_na(subf$inc_tax_gdp_pct),
    inc_tax_share_pct = mean_na(subf$income_profit_tax_share_rev_pct),
    goods_tax_share_pct = mean_na(subf$goods_services_tax_share_rev_pct),
    gini_disp = mean_na(subf$gini_disp_harmonised),
    life_expectancy_yrs = mean_na(subf$life_expectancy_birth_yrs),
    # +5y Continuous Slopes per +10 pp (Model M2a, Scaling A)
    tau5_tax_gdp = mean_na(sub5$m2_5y_tau_tax_gdp_pp),
    tau5_tax_gdp_low80 = mean_na(sub5$m2_5y_tau_low80_tax_gdp_pp),
    tau5_tax_gdp_high80 = mean_na(sub5$m2_5y_tau_high80_tax_gdp_pp),
    tau5_tax_gdp_low95 = mean_na(sub5$m2_5y_tau_low95_tax_gdp_pp),
    tau5_tax_gdp_high95 = mean_na(sub5$m2_5y_tau_high95_tax_gdp_pp),
    tau5_inc_gdp = mean_na(sub5$m2_5y_tau_inc_tax_gdp_pp),
    tau5_inc_gdp_low80 = mean_na(sub5$m2_5y_tau_low80_inc_tax_gdp_pp),
    tau5_inc_gdp_high80 = mean_na(sub5$m2_5y_tau_high80_inc_tax_gdp_pp),
    tau5_inc_gdp_low95 = mean_na(sub5$m2_5y_tau_low95_inc_tax_gdp_pp),
    tau5_inc_gdp_high95 = mean_na(sub5$m2_5y_tau_high95_inc_tax_gdp_pp),
    tau5_inc_share = mean_na(sub5$m2_5y_tau_inc_tax_share_pp),
    tau5_inc_share_low80 = mean_na(sub5$m2_5y_tau_low80_inc_tax_share_pp),
    tau5_inc_share_high80 = mean_na(sub5$m2_5y_tau_high80_inc_tax_share_pp),
    tau5_inc_share_low95 = mean_na(sub5$m2_5y_tau_low95_inc_tax_share_pp),
    tau5_inc_share_high95 = mean_na(sub5$m2_5y_tau_high95_inc_tax_share_pp),
    tau5_goods_share = mean_na(sub5$m2_5y_tau_goods_tax_share_pp),
    tau5_goods_share_low80 = mean_na(sub5$m2_5y_tau_low80_goods_tax_share_pp),
    tau5_goods_share_high80 = mean_na(sub5$m2_5y_tau_high80_goods_tax_share_pp),
    tau5_goods_share_low95 = mean_na(sub5$m2_5y_tau_low95_goods_tax_share_pp),
    tau5_goods_share_high95 = mean_na(sub5$m2_5y_tau_high95_goods_tax_share_pp),
    # +10y Continuous Slopes per +10 pp (Model M2b, Scaling A)
    tau10_tax_gdp = mean_na(sub10$m2_10y_tau_tax_gdp_pp),
    tau10_tax_gdp_low80 = mean_na(sub10$m2_10y_tau_low80_tax_gdp_pp),
    tau10_tax_gdp_high80 = mean_na(sub10$m2_10y_tau_high80_tax_gdp_pp),
    tau10_tax_gdp_low95 = mean_na(sub10$m2_10y_tau_low95_tax_gdp_pp),
    tau10_tax_gdp_high95 = mean_na(sub10$m2_10y_tau_high95_tax_gdp_pp),
    tau10_inc_gdp = mean_na(sub10$m2_10y_tau_inc_tax_gdp_pp),
    tau10_inc_gdp_low80 = mean_na(sub10$m2_10y_tau_low80_inc_tax_gdp_pp),
    tau10_inc_gdp_high80 = mean_na(sub10$m2_10y_tau_high80_inc_tax_gdp_pp),
    tau10_inc_gdp_low95 = mean_na(sub10$m2_10y_tau_low95_inc_tax_gdp_pp),
    tau10_inc_gdp_high95 = mean_na(sub10$m2_10y_tau_high95_inc_tax_gdp_pp),
    tau10_inc_share = mean_na(sub10$m2_10y_tau_inc_tax_share_pp),
    tau10_inc_share_low80 = mean_na(sub10$m2_10y_tau_low80_inc_tax_share_pp),
    tau10_inc_share_high80 = mean_na(sub10$m2_10y_tau_high80_inc_tax_share_pp),
    tau10_inc_share_low95 = mean_na(sub10$m2_10y_tau_low95_inc_tax_share_pp),
    tau10_inc_share_high95 = mean_na(sub10$m2_10y_tau_high95_inc_tax_share_pp),
    tau10_goods_share = mean_na(sub10$m2_10y_tau_goods_tax_share_pp),
    tau10_goods_share_low80 = mean_na(sub10$m2_10y_tau_low80_goods_tax_share_pp),
    tau10_goods_share_high80 = mean_na(sub10$m2_10y_tau_high80_goods_tax_share_pp),
    tau10_goods_share_low95 = mean_na(sub10$m2_10y_tau_low95_goods_tax_share_pp),
    tau10_goods_share_high95 = mean_na(sub10$m2_10y_tau_high95_goods_tax_share_pp),
    stringsAsFactors = FALSE
  )
})

df_countries <- do.call(rbind, country_rows)
df_countries <- df_countries[order(df_countries$country_name), ]
write.csv(df_countries, "app/data/country_cates.csv", row.names = FALSE)

# ------------------------------------------------------------------------------
# 2. Historical Wave-by-Wave Panel Data (Tab 2 Gapminder-Style Explorer)
# ------------------------------------------------------------------------------
keep_hist <- !is.na(df_full$non_resource_tax_gdp_pct) | !is.na(df_full$tert_spend_per_student_winsor) |
             !is.na(df_full$tert_spend_gdp_pct) | !is.na(df_full$real_tert_spend_per_student_ppp)
df_hist <- df_full[keep_hist, c(
  "iso3", "country_name", "region", "income_group", "is_oecd",
  "wave_index", "wave_label", "wave_start_year",
  "population_total", "gdp_per_capita_ppp_const2021",
  "tert_spend_per_student_winsor", "real_tert_spend_per_student_ppp", "tert_spend_gdp_pct",
  "tert_spend_abs_change", "d_log_real_spend_stu_pct", "d_tert_spend_gdp_pp",
  "gross_tert_enrolment_pct",
  "non_resource_tax_gdp_pct", "inc_tax_gdp_pct",
  "income_profit_tax_share_rev_pct", "goods_services_tax_share_rev_pct",
  "d_prev_nonres_tax_gdp_pp", "d_prev_inc_tax_gdp_pp",
  "d_prev_inc_tax_share_pp", "d_prev_goods_tax_share_pp",
  "d_t1_nonres_tax_gdp_pp", "d_t1_inc_tax_gdp_pp", "d_t1_inc_tax_share_pp",
  "d_t2_nonres_tax_gdp_pp", "d_t2_inc_tax_gdp_pp", "d_t2_inc_tax_share_pp"
)]

num_cols <- sapply(df_hist, is.numeric)
df_hist[num_cols] <- lapply(df_hist[num_cols], function(col) round(col, 3))
write.csv(df_hist, "app/data/historical_waves.csv", row.names = FALSE)

# ------------------------------------------------------------------------------
# 3. Surrogate Linear CATE Response Surface for Tab 3 Scenario Simulator
# ------------------------------------------------------------------------------
# Fit surrogate models predicting unit-level CATEs at +5y and +10y from the
# baseline moderators so users can smoothly adjust moderator sliders in Tab 3.
mod_vars <- c("gross_tert_enrolment_pct", "log_gdp_pc_ppp", "gross_seco_enrolment_pct",
              "income_profit_tax_share_rev_pct", "working_age_pop_15_64_pct",
              "gini_disp_harmonised", "life_expectancy_birth_yrs")

prep_mod_df <- function(df) {
  out <- df[, mod_vars, drop = FALSE]
  for (v in mod_vars) {
    med <- median(out[[v]], na.rm = TRUE)
    out[[v]][!is.finite(out[[v]])] <- med
  }
  out
}

X5  <- prep_mod_df(df_5y)
X10 <- prep_mod_df(df_10y)

fit_surrogate <- function(y, X, sd_vec) {
  dat <- cbind(y = y, X)
  m <- lm(y ~ ., data = dat)
  list(
    coefs = as.list(round(coef(m), 6)),
    r2 = round(summary(m)$r.squared, 3),
    mean_sd = round(mean(sd_vec, na.rm = TRUE), 3)
  )
}

surrogates <- list(
  h5 = list(
    tax_gdp     = fit_surrogate(df_5y$m2_5y_tau_tax_gdp_pp, X5, df_5y$m2_5y_tau_sd_tax_gdp_pp),
    inc_gdp     = fit_surrogate(df_5y$m2_5y_tau_inc_tax_gdp_pp, X5, df_5y$m2_5y_tau_sd_inc_tax_gdp_pp),
    inc_share   = fit_surrogate(df_5y$m2_5y_tau_inc_tax_share_pp, X5, df_5y$m2_5y_tau_sd_inc_tax_share_pp),
    goods_share = fit_surrogate(df_5y$m2_5y_tau_goods_tax_share_pp, X5, df_5y$m2_5y_tau_sd_goods_tax_share_pp)
  ),
  h10 = list(
    tax_gdp     = fit_surrogate(df_10y$m2_10y_tau_tax_gdp_pp, X10, df_10y$m2_10y_tau_sd_tax_gdp_pp),
    inc_gdp     = fit_surrogate(df_10y$m2_10y_tau_inc_tax_gdp_pp, X10, df_10y$m2_10y_tau_sd_inc_tax_gdp_pp),
    inc_share   = fit_surrogate(df_10y$m2_10y_tau_inc_tax_share_pp, X10, df_10y$m2_10y_tau_sd_inc_tax_share_pp),
    goods_share = fit_surrogate(df_10y$m2_10y_tau_goods_tax_share_pp, X10, df_10y$m2_10y_tau_sd_goods_tax_share_pp)
  ),
  sample_defaults = as.list(round(colMeans(X10, na.rm = TRUE), 2)),
  sample_sds      = as.list(round(sapply(X10, sd, na.rm = TRUE), 2)),
  sample_mins     = as.list(round(sapply(X10, min, na.rm = TRUE), 2)),
  sample_maxs     = as.list(round(sapply(X10, max, na.rm = TRUE), 2))
)

# ------------------------------------------------------------------------------
# 4. Write Master JSON and Self-Contained JS Bundle for app/index.html
# ------------------------------------------------------------------------------
app_payload <- list(
  generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  countries = df_countries,
  historical = df_hist,
  global_ate = tab_ate,
  subgroup_cates = tab_sub,
  surrogates = surrogates
)

json_str <- toJSON(app_payload, dataframe = "rows", auto_unbox = TRUE, na = "null", digits = 4)
writeLines(json_str, "app/data/app_data.json")
writeLines(paste0("window.EDUCATION_TAX_APP_DATA = ", json_str, ";"), "app/data/app_data.js")

cat(sprintf("Exported %d countries and %d historical country-waves to app/data/\n",
            nrow(df_countries), nrow(df_hist)))
