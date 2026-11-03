#!/usr/bin/env python3
"""
Step 1a: Automated Data Ingestion Pipeline (01_download_tax_education_data.py)

Fetches raw cross-country panel datasets from official public APIs using only
the Python standard library (for zero-dependency reproducibility) and records
SHA-256 checksums for every downloaded file:

1. World Bank / UNESCO UIS / IMF Government Finance Statistics (GFS) API:
   - Sovereign country metadata (ISO3, ISO2, region, income group, OECD membership)
   - Disaggregated fiscal revenue channels (1985-2024):
     * Total tax revenue (% of GDP): GC.TAX.TOTL.GD.ZS
     * Government revenue excluding grants (% of GDP): GC.REV.XGRT.GD.ZS
     * Taxes on income, profits, and capital gains (% of revenue): GC.TAX.YPKG.ZS
     * Taxes on goods and services / VAT (% of revenue): GC.TAX.GSRV.RV.ZS
     * Taxes on international trade (% of revenue): GC.TAX.INTT.RV.ZS
     * Social contributions (% of revenue): GC.REV.SOCL.ZS
     * Total natural resource rents (% of GDP): NY.GDP.TOTL.RT.ZS
   - Education expenditure & attainment channels (UNESCO UIS):
     * Government expenditure per tertiary student (% of GDP per person): SE.XPD.TERT.PC.ZS
     * Government expenditure per secondary student (% of GDP per person): SE.XPD.SECO.PC.ZS
     * Government expenditure per primary student (% of GDP per person): SE.XPD.PRIM.PC.ZS
     * Total government expenditure on education (% of GDP): SE.XPD.TOTL.GD.ZS
     * Tertiary share of total government education expenditure (%): SE.XPD.TERT.ZS
     * Gross tertiary enrolment ratio (%): SE.TER.ENRR
     * Gross secondary enrolment ratio (%): SE.SEC.ENRR
     * Labour force with advanced education (%): SL.TLF.ADVN.ZS
     * Bachelor's or equivalent attainment, population 25+ (%): SE.TER.CUAT.BA.ZS
2. Standardized World Income Inequality Database (SWIID, Solt 2020):
   - Harmonised disposable income Gini (gini_disp) and pre-tax market Gini (gini_mkt)
     along with posterior standard errors (gini_disp_se, gini_mkt_se).
"""

import csv
import hashlib
import json
import time
import urllib.error
import urllib.request
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
RAW_DIR = REPO_ROOT / "data" / "raw"
RAW_DIR.mkdir(parents=True, exist_ok=True)

WB_INDICATORS = {
    # Primary treatment & education expenditure / enrolment variables (UNESCO UIS)
    "SE.XPD.TERT.PC.ZS": "tert_spend_per_student_gdp_pc",
    "SE.XPD.SECO.PC.ZS": "seco_spend_per_student_gdp_pc",
    "SE.XPD.PRIM.PC.ZS": "prim_spend_per_student_gdp_pc",
    "SE.XPD.TOTL.GD.ZS": "edu_spend_total_gdp_pct",
    "SE.XPD.TERT.ZS": "tert_share_of_edu_spend_pct",
    "SE.TER.ENRR": "gross_tert_enrolment_pct",
    "SE.SEC.ENRR": "gross_seco_enrolment_pct",
    "SL.TLF.ADVN.ZS": "labour_force_advanced_edu_pct",
    "SE.TER.CUAT.BA.ZS": "tertiary_attainment_bachelor_25plus_pct",
    # Disaggregated fiscal tax take & revenue channels (IMF GFS / World Bank WDI)
    "GC.TAX.TOTL.GD.ZS": "tax_rev_gdp_pct",
    "GC.REV.XGRT.GD.ZS": "gov_rev_ex_grants_gdp_pct",
    "NY.GDP.TOTL.RT.ZS": "natural_resource_rents_gdp_pct",
    "GC.TAX.YPKG.ZS": "income_profit_tax_share_rev_pct",
    "GC.TAX.GSRV.RV.ZS": "goods_services_tax_share_rev_pct",
    "GC.TAX.INTT.RV.ZS": "trade_tax_share_rev_pct",
    "GC.REV.SOCL.ZS": "social_contrib_share_rev_pct",
    # Macroeconomic, demographic, inequality, health & governance controls / mediators
    "NY.GDP.PCAP.PP.KD": "gdp_per_capita_ppp_const2021",
    "NY.GDP.PCAP.KD.ZG": "gdp_per_capita_growth_pct",
    "SI.POV.GINI": "wb_gini_index",
    "SP.DYN.LE00.IN": "life_expectancy_birth_yrs",
    "SP.DYN.IMRT.IN": "infant_mortality_per_1000",
    "SP.POP.TOTL": "population_total",
    "SP.POP.1564.TO.ZS": "working_age_pop_15_64_pct",
    "NE.GDI.FTOT.ZS": "gross_fixed_capital_form_gdp_pct",
    "NE.TRD.GNFS.ZS": "trade_openness_gdp_pct",
    "GB.XPD.RSDV.GD.ZS": "rd_expenditure_gdp_pct",
    "SL.UEM.TOTL.ZS": "unemployment_rate_pct",
    "GE.EST": "wgi_gov_effectiveness",
    "RL.EST": "wgi_rule_of_law",
}


def fetch_json(url: str, retries: int = 3) -> list:
    headers = {"User-Agent": "Mozilla/5.0 (UCD-Education-Tax-BCF-Pipeline/1.0)"}
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(req, timeout=45) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except Exception as exc:
            if attempt == retries - 1:
                raise
            print(f"  Retry {attempt + 1}/{retries} for {url}: {exc}")
            time.sleep(2 * (attempt + 1))
    return []


def compute_sha256(filepath: Path) -> str:
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def update_wb_indicators() -> None:
    meta_path = RAW_DIR / "wb_countries_metadata.csv"
    with open(meta_path, "r", encoding="utf-8") as f:
        valid_iso3 = {row["iso3"].strip() for row in csv.DictReader(f)}

    long_path = RAW_DIR / "wb_unesco_imf_wgi_long.csv"
    existing_rows = []
    existing_codes = set()
    if long_path.exists():
        with open(long_path, "r", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                existing_rows.append(row)
                existing_codes.add(row["indicator_code"].strip())

    missing_indicators = {
        k: v for k, v in WB_INDICATORS.items() if k not in existing_codes
    }
    if not missing_indicators:
        print("All World Bank / UNESCO / IMF indicators already cached in wb_unesco_imf_wgi_long.csv.")
        return

    print(f"Fetching {len(missing_indicators)} additional disaggregated fiscal/education indicators (1985-2024)...")
    new_rows = []
    for idx, (ind_code, col_name) in enumerate(missing_indicators.items(), 1):
        print(f"  [{idx:02d}/{len(missing_indicators):02d}] Fetching {ind_code} ({col_name})...")
        page = 1
        total_pages = 1
        count = 0
        while page <= total_pages:
            url = (
                f"https://api.worldbank.org/v2/country/all/indicator/{ind_code}"
                f"?format=json&date=1985:2024&per_page=10000&page={page}"
            )
            try:
                data = fetch_json(url)
            except Exception as exc:
                print(f"    Warning: could not fetch {ind_code}: {exc}")
                break
            if not isinstance(data, list) or len(data) < 2 or not data[1]:
                break
            total_pages = int(data[0].get("pages", 1))
            for entry in data[1]:
                iso3 = entry.get("countryiso3code", "")
                val = entry.get("value")
                yr = entry.get("date", "")
                if iso3 in valid_iso3 and val is not None and str(yr).isdigit():
                    new_rows.append({
                        "iso3": iso3,
                        "year": int(yr),
                        "indicator_code": ind_code,
                        "variable": col_name,
                        "value": float(val),
                    })
                    count += 1
            page += 1
        print(f"       -> {count} non-null country-year observations")

    all_rows = existing_rows + new_rows
    with open(long_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f, fieldnames=["iso3", "year", "indicator_code", "variable", "value"]
        )
        writer.writeheader()
        writer.writerows(all_rows)
    print(f"Updated {long_path.name} with {len(all_rows):,} total observations.")


def write_checksums() -> None:
    checksums = {}
    for fp in sorted(RAW_DIR.glob("*.csv")):
        checksums[fp.name] = {
            "sha256": compute_sha256(fp),
            "size_bytes": fp.stat().st_size,
        }
    manifest_path = RAW_DIR / "checksums_sha256.json"
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(checksums, f, indent=2)
    print(f"Wrote SHA-256 data integrity manifest to {manifest_path.name}")


if __name__ == "__main__":
    update_wb_indicators()
    write_checksums()
    print("Step 1a complete!")
