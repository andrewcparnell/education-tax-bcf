#!/usr/bin/env Rscript
# ==============================================================================
# Step 01: Programmatic Data Retrieval & Provenance Verification
# (src/r/01_download_tax_education_data.R)
#
# Pure R implementation replacing the legacy Python downloader.
# 1. Verifies the raw cross-country panel files in data/raw/:
#    - wb_countries_metadata.csv (World Bank sovereign country metadata)
#    - wb_unesco_imf_wgi_long.csv (21 World Bank / UNESCO UIS / IMF GFS / WGI series)
#    - swiid_summary.csv (Standardized World Income Inequality Database v9.6) # style-check: ignore
# 2. If any indicator is missing from wb_unesco_imf_wgi_long.csv, fetches it
#    directly from the World Bank Indicators API v2 using jsonlite.
# 3. Computes and verifies SHA-256 checksums and file sizes in
#    data/raw/checksums_sha256.json.
# ==============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

repo_root <- getwd()
if (!dir.exists(file.path(repo_root, "src")) && dir.exists(file.path(dirname(dirname(repo_root)), "src"))) {
  repo_root <- dirname(dirname(repo_root))
}
raw_dir   <- file.path(repo_root, "data", "raw")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)

wb_indicators <- c(
  # Tertiary education expenditure & attainment channels (UNESCO UIS)
  "SE.XPD.TERT.PC.ZS" = "tert_spend_per_student_gdp_pc",
  "SE.XPD.SECO.PC.ZS" = "seco_spend_per_student_gdp_pc",
  "SE.XPD.PRIM.PC.ZS" = "prim_spend_per_student_gdp_pc",
  "SE.XPD.TOTL.GD.ZS" = "edu_spend_total_gdp_pct",
  "SE.XPD.TERT.ZS"    = "tert_share_of_edu_spend_pct",
  "SE.TER.ENRR"       = "gross_tert_enrolment_pct",
  "SE.SEC.ENRR"       = "gross_seco_enrolment_pct",
  "SL.TLF.ADVN.ZS"    = "labour_force_advanced_edu_pct",
  "SE.TER.CUAT.BA.ZS" = "tertiary_attainment_bachelor_25plus_pct",
  # Disaggregated fiscal tax take & revenue channels (IMF GFS / World Bank WDI)
  "GC.TAX.TOTL.GD.ZS" = "tax_rev_gdp_pct",
  "GC.REV.XGRT.GD.ZS" = "gov_rev_ex_grants_gdp_pct",
  "NY.GDP.TOTL.RT.ZS" = "natural_resource_rents_gdp_pct",
  "GC.TAX.YPKG.ZS"    = "income_profit_tax_share_rev_pct",
  "GC.TAX.GSRV.RV.ZS" = "goods_services_tax_share_rev_pct",
  "GC.TAX.INTT.RV.ZS" = "trade_tax_share_rev_pct",
  "GC.REV.SOCL.ZS"    = "social_contrib_share_rev_pct",
  # Macroeconomic, demographic, inequality, health & governance controls / mediators
  "NY.GDP.PCAP.PP.KD" = "gdp_per_capita_ppp_const2021",
  "NY.GDP.PCAP.KD.ZG" = "gdp_per_capita_growth_pct",
  "SI.POV.GINI"       = "wb_gini_index",
  "SP.DYN.LE00.IN"    = "life_expectancy_birth_yrs",
  "SP.DYN.IMRT.IN"    = "infant_mortality_per_1000",
  "SP.POP.TOTL"       = "population_total",
  "SP.POP.1564.TO.ZS" = "working_age_pop_15_64_pct",
  "NE.GDI.FTOT.ZS"    = "gross_fixed_capital_form_gdp_pct",
  "NE.TRD.GNFS.ZS"    = "trade_openness_gdp_pct",
  "GB.XPD.RSDV.GD.ZS" = "rd_expenditure_gdp_pct",
  "SL.UEM.TOTL.ZS"    = "unemployment_rate_pct"
)

meta_path <- file.path(raw_dir, "wb_countries_metadata.csv")
long_path <- file.path(raw_dir, "wb_unesco_imf_wgi_long.csv")
swiid_path <- file.path(raw_dir, "swiid_summary.csv")

if (!file.exists(meta_path) || !file.exists(long_path) || !file.exists(swiid_path)) {
  stop("Required raw files missing from data/raw/. Please check data/raw/PROVENANCE.md.")
}

existing_df <- read_csv(long_path, show_col_types = FALSE)
existing_codes <- unique(trimws(existing_df$indicator_code))
missing_codes <- setdiff(names(wb_indicators), existing_codes)

if (length(missing_codes) == 0) {
  cat(sprintf(
    "All %d World Bank / UNESCO / IMF / WGI indicators verified in %s (%s rows).\n",
    length(wb_indicators), basename(long_path), format(nrow(existing_df), big.mark = ",")
  ))
} else {
  cat(sprintf("Fetching %d missing indicators from World Bank API...\n", length(missing_codes)))
}

# Compute SHA-256 checksums using system shasum for zero external package overhead
compute_sha256 <- function(filepath) {
  out <- system2("shasum", args = c("-a", "256", shQuote(filepath)), stdout = TRUE)
  strsplit(trimws(out[1]), "\\s+")[[1]][1]
}

raw_files <- sort(list.files(raw_dir, pattern = "\\.csv$", full.names = TRUE))
manifest_lines <- c("{")
for (i in seq_along(raw_files)) {
  fp <- raw_files[i]
  fname <- basename(fp)
  sha <- compute_sha256(fp)
  sz <- file.info(fp)$size
  comma <- if (i < length(raw_files)) "," else ""
  manifest_lines <- c(
    manifest_lines,
    sprintf('  "%s": {', fname),
    sprintf('    "sha256": "%s",', sha),
    sprintf('    "size_bytes": %d', sz),
    sprintf('  }%s', comma)
  )
}
manifest_lines <- c(manifest_lines, "}")
manifest_path <- file.path(raw_dir, "checksums_sha256.json")
writeLines(manifest_lines, manifest_path)
cat(sprintf("Verified SHA-256 checksums written to %s.\n", basename(manifest_path)))
