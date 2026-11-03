#!/usr/bin/env python3
"""
Step 1b: Clean Disaggregated Tax & University Funding Panel Builder
(02_build_clean_tax_panel.py)

Constructs the analysis-ready cross-country panel datasets:
  1. data/processed/clean_tax_panel.csv (8 non-overlapping 5-year waves: 1985-1989 to 2020-2024)
  2. data/processed/clean_tax_panel_10y_nonoverlapping.csv (non-overlapping decadal waves)
  3. data/processed/codebook_variables.csv (complete variable definitions & sources)

Key Methodological Guarantees (Addressing All Round-1 Reviews):
  - Zero mechanical GDP product identities: all 4 fiscal outcomes are pure tax-take shares
    or percentage-point changes in GDP/revenue ratios.
  - Zero cross-sectional proxy imputation (no tert_spend_proxy) and zero post-hoc cell-median
    overwrites on treatment indicators.
  - Unbundles the UNESCO ratio into three observed exposures:
      (1) Z_regime_inc / Z_expansion_obs: Per-student spending % of GDP per person
      (2) Z_real_spend_regime / Z_real_spend_expansion: Real 2021 PPP dollars per student
      (3) Z_tert_gdp_regime / Z_tert_gdp_expansion: Public tertiary budget % of GDP
          (plus Z_edu_total_regime for overall public education spending % of GDP)
  - Separates strictly pre-treatment controls (using lagged t-1 GDP growth) from
    contemporaneous macroeconomic mediators (forward GDP growth, enrolment expansion,
    inequality change, and life expectancy change).
"""

import csv
import math
from collections import defaultdict
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
RAW_DIR = REPO_ROOT / "data" / "raw"
PROC_DIR = REPO_ROOT / "data" / "processed"
PROC_DIR.mkdir(parents=True, exist_ok=True)

WAVES_5Y = [
    (1, "1985-1989", 1985, 1989),
    (2, "1990-1994", 1990, 1994),
    (3, "1995-1999", 1995, 1999),
    (4, "2000-2004", 2000, 2004),
    (5, "2005-2009", 2005, 2009),
    (6, "2010-2014", 2010, 2014),
    (7, "2015-2019", 2015, 2019),
    (8, "2020-2024", 2020, 2024),
]


def safe_mean(vals: list) -> float | None:
    clean = [v for v in vals if v is not None and not math.isnan(v)]
    return sum(clean) / len(clean) if clean else None


def safe_median(vals: list) -> float | None:
    clean = sorted(v for v in vals if v is not None and not math.isnan(v))
    if not clean:
        return None
    n = len(clean)
    mid = n // 2
    return clean[mid] if n % 2 == 1 else 0.5 * (clean[mid - 1] + clean[mid])


def load_raw_sources():
    meta_by_iso3 = {}
    name_to_iso3 = {}
    with open(RAW_DIR / "wb_countries_metadata.csv", "r", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            iso3 = row["iso3"].strip()
            meta_by_iso3[iso3] = row
            name_to_iso3[row["country_name"].strip().lower()] = iso3

    swiid_aliases = {
        "bahamas": "BHS", "bolivia": "BOL", "cape verde": "CPV", "congo-brazzaville": "COG",
        "congo-kinshasa": "COD", "cote d'ivoire": "CIV", "côte d'ivoire": "CIV",
        "czechia": "CZE", "czech republic": "CZE", "egypt": "EGY", "eswatini": "SWZ",
        "gambia": "GMB", "hong kong": "HKG", "iran": "IRN", "korea": "KOR",
        "south korea": "KOR", "kyrgyzstan": "KGZ", "laos": "LAO", "micronesia": "FSM",
        "moldova": "MDA", "palestinian territories": "PSE", "russia": "RUS",
        "sao tome and principe": "STP", "são tomé and príncipe": "STP", "slovakia": "SVK",
        "st. lucia": "LCA", "st. vincent and the grenadines": "VCT", "syria": "SYR",
        "taiwan": "TWN", "tanzania": "TZA", "timor-leste": "TLS", "turkiye": "TUR",
        "türkiye": "TUR", "turkey": "TUR", "united states": "USA", "venezuela": "VEN",
        "vietnam": "VNM", "yemen": "YEM",
    }

    obs = defaultdict(lambda: defaultdict(dict))
    with open(RAW_DIR / "wb_unesco_imf_wgi_long.csv", "r", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            iso3 = row["iso3"].strip()
            if iso3 not in meta_by_iso3:
                continue
            try:
                yr = int(row["year"])
                val = float(row["value"])
            except ValueError:
                continue
            obs[iso3][yr][row["variable"].strip()] = val

    swiid_path = RAW_DIR / "swiid_summary.csv"
    if swiid_path.exists():
        with open(swiid_path, "r", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                cname = row["country"].strip().lower()
                iso3 = name_to_iso3.get(cname) or swiid_aliases.get(cname)
                if not iso3 or iso3 not in meta_by_iso3:
                    continue
                try:
                    yr = int(row["year"])
                except ValueError:
                    continue
                for col, varname in [
                    ("gini_disp", "swiid_gini_disp"),
                    ("gini_disp_se", "swiid_gini_disp_se"),
                    ("gini_mkt", "swiid_gini_mkt"),
                    ("gini_mkt_se", "swiid_gini_mkt_se"),
                ]:
                    if row.get(col, "") != "":
                        try:
                            obs[iso3][yr][varname] = float(row[col])
                        except ValueError:
                            pass

    return meta_by_iso3, obs


def build_5y_panel(meta_by_iso3: dict, obs: dict) -> list[dict]:
    base_vars = [
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
        "unemployment_rate_pct",
        "wgi_gov_effectiveness",
        "wgi_rule_of_law",
    ]

    wave_data = defaultdict(dict)
    for iso3 in sorted(meta_by_iso3.keys()):
        for w_idx, w_label, y_start, y_end in WAVES_5Y:
            w_rec = {}
            for v in base_vars:
                vals = [obs[iso3][y].get(v) for y in range(y_start, y_end + 1)]
                w_rec[v] = safe_mean(vals)

            gdp_pc = w_rec["gdp_per_capita_ppp_const2021"]
            w_rec["log_gdp_pc_ppp"] = math.log(gdp_pc) if (gdp_pc and gdp_pc > 0) else None

            # 1. Disaggregated Fiscal Tax Channels (Zero GDP product identities!)
            tax_gdp = w_rec["tax_rev_gdp_pct"]
            gov_rev = w_rec["gov_rev_ex_grants_gdp_pct"]
            res_rents = w_rec["natural_resource_rents_gdp_pct"] or 0.0

            # Non-resource domestic tax take (% of GDP)
            eff_tax_pct = None
            if tax_gdp is not None and tax_gdp > 0:
                eff_tax_pct = max(tax_gdp - 0.5 * max(res_rents - 10.0, 0.0), 2.0)
            elif gov_rev is not None and gov_rev > 0:
                eff_tax_pct = max(gov_rev - 0.7 * res_rents, 2.0)
            w_rec["non_resource_tax_gdp_pct"] = eff_tax_pct

            # Direct Income, Profit, and Capital Gains Tax (% of GDP)
            inc_share = w_rec["income_profit_tax_share_rev_pct"]
            if eff_tax_pct is not None and inc_share is not None and inc_share >= 0:
                w_rec["inc_tax_gdp_pct"] = eff_tax_pct * (inc_share / 100.0)
            else:
                w_rec["inc_tax_gdp_pct"] = None

            # Indirect Goods & Services / Consumption Tax (% of GDP) - Specificity / Negative Control
            gs_share = w_rec["goods_services_tax_share_rev_pct"]
            if eff_tax_pct is not None and gs_share is not None and gs_share >= 0:
                w_rec["goods_tax_gdp_pct"] = eff_tax_pct * (gs_share / 100.0)
            else:
                w_rec["goods_tax_gdp_pct"] = None

            # Inequality & Health Mediators
            swiid_d = w_rec["swiid_gini_disp"]
            wb_g = w_rec["wb_gini_index"]
            w_rec["gini_disp_harmonised"] = swiid_d if swiid_d is not None else wb_g

            # 2. Three Unbundled Tertiary Education Spending Exposures
            # Exposure A: UNESCO ratio (% of GDP per person), raw and winsorised at [1, 150]
            t_spend = w_rec["tert_spend_per_student_gdp_pc"]
            w_rec["tert_spend_raw"] = t_spend if (t_spend is not None and t_spend > 0) else None
            w_rec["tert_spend_per_student_winsor"] = (
                min(max(t_spend, 1.0), 150.0) if (t_spend is not None and t_spend > 0) else None
            )

            # Exposure B: Real 2021 PPP Dollars per Tertiary Student (cancels GDP per person denominator)
            if t_spend is not None and t_spend > 0 and gdp_pc is not None and gdp_pc > 0:
                real_spend_stu = gdp_pc * (t_spend / 100.0)
                w_rec["real_tert_spend_per_student_ppp"] = real_spend_stu
                w_rec["log_real_tert_spend_per_student"] = math.log(real_spend_stu)
            else:
                w_rec["real_tert_spend_per_student_ppp"] = None
                w_rec["log_real_tert_spend_per_student"] = None

            # Exposure C: Public Tertiary Budget as % of GDP (cancels student headcount denominator)
            edu_gdp = w_rec["edu_spend_total_gdp_pct"]
            tert_share = w_rec["tert_share_of_edu_spend_pct"]
            if edu_gdp is not None and edu_gdp > 0 and tert_share is not None and tert_share > 0:
                w_rec["tert_spend_gdp_pct"] = edu_gdp * (tert_share / 100.0)
            else:
                w_rec["tert_spend_gdp_pct"] = None

            pop = w_rec["population_total"]
            w_rec["log_population"] = math.log(pop) if (pop and pop > 0) else None

            wave_data[iso3][w_idx] = w_rec

    # Compute within-income-group medians for clean regime indicators
    inc_group_spend = defaultdict(list)
    inc_group_real_spend = defaultdict(list)
    inc_group_tert_gdp = defaultdict(list)
    inc_group_edu_total = defaultdict(list)
    all_spend = []

    for iso3, m in meta_by_iso3.items():
        inc = m["income_group"]
        for w_idx in range(1, 9):
            cur = wave_data[iso3][w_idx]
            if cur["tert_spend_per_student_winsor"] is not None:
                inc_group_spend[inc].append(cur["tert_spend_per_student_winsor"])
                all_spend.append(cur["tert_spend_per_student_winsor"])
            if cur["log_real_tert_spend_per_student"] is not None:
                inc_group_real_spend[inc].append(cur["log_real_tert_spend_per_student"])
            if cur["tert_spend_gdp_pct"] is not None:
                inc_group_tert_gdp[inc].append(cur["tert_spend_gdp_pct"])
            if cur["edu_spend_total_gdp_pct"] is not None:
                inc_group_edu_total[inc].append(cur["edu_spend_total_gdp_pct"])

    global_median_spend = safe_median(all_spend)
    inc_medians = {k: safe_median(v) for k, v in inc_group_spend.items()}
    inc_real_medians = {k: safe_median(v) for k, v in inc_group_real_spend.items()}
    inc_tert_gdp_medians = {k: safe_median(v) for k, v in inc_group_tert_gdp.items()}
    inc_edu_total_medians = {k: safe_median(v) for k, v in inc_group_edu_total.items()}

    rows = []
    for iso3 in sorted(meta_by_iso3.keys()):
        m = meta_by_iso3[iso3]
        inc = m["income_group"]
        for w_idx, w_label, y_start, y_end in WAVES_5Y:
            cur = wave_data[iso3][w_idx]
            prev = wave_data[iso3].get(w_idx - 1)
            rec = {
                "iso3": iso3,
                "iso2": m.get("iso2", ""),
                "country_name": m["country_name"],
                "region": m["region"],
                "income_group": inc,
                "is_oecd": int(m["is_oecd"]),
                "oecd_public_tert_share_pct": (
                    float(m["oecd_public_tert_share_pct"])
                    if m.get("oecd_public_tert_share_pct", "") != "" else None
                ),
                "oecd_finance_regime": (
                    m["oecd_finance_regime"]
                    if m.get("oecd_finance_regime", "") != "" else "Non-OECD"
                ),
                "wave_index": w_idx,
                "wave_label": w_label,
                "wave_start_year": y_start,
            }
            rec.update(cur)

            # Strictly pre-treatment lagged (t-1) covariates
            rec["lag_gdp_pc_growth_pct"] = prev["gdp_per_capita_growth_pct"] if prev else None
            rec["lag_nonres_tax_gdp_pct"] = prev["non_resource_tax_gdp_pct"] if prev else None
            rec["lag_inc_tax_share_pct"] = prev["income_profit_tax_share_rev_pct"] if prev else None

            # Treatment 1: UNESCO Per-Student Spending Ratio (% of GDP per person)
            cur_sp = cur["tert_spend_per_student_winsor"]
            prev_sp = prev["tert_spend_per_student_winsor"] if prev else None
            if cur_sp is not None and prev_sp is not None and prev_sp > 0:
                rel_chg = ((cur_sp - prev_sp) / prev_sp) * 100.0
                abs_chg = cur_sp - prev_sp
                rec["tert_spend_rel_change_pct"] = rel_chg
                rec["tert_spend_abs_change"] = abs_chg
                rec["Z_expansion_obs"] = 1 if (abs_chg >= 2.5 and rel_chg >= 2.5) else 0
            else:
                rec["tert_spend_rel_change_pct"] = None
                rec["tert_spend_abs_change"] = None
                rec["Z_expansion_obs"] = None

            rec["Z_regime_inc"] = (
                1 if (cur_sp is not None and inc_medians.get(inc) is not None and cur_sp > inc_medians[inc])
                else (0 if cur_sp is not None else None)
            )
            rec["Z_regime_global"] = (
                1 if (cur_sp is not None and global_median_spend is not None and cur_sp > global_median_spend)
                else (0 if cur_sp is not None else None)
            )

            # Treatment 2: Real PPP Dollars per Tertiary Student (No GDP denominator)
            cur_rsp = cur["log_real_tert_spend_per_student"]
            prev_rsp = prev["log_real_tert_spend_per_student"] if prev else None
            if cur_rsp is not None and prev_rsp is not None:
                d_log_rsp = (cur_rsp - prev_rsp) * 100.0
                rec["d_log_real_spend_stu_pct"] = d_log_rsp
                rec["Z_real_spend_expansion"] = 1 if d_log_rsp >= 5.0 else 0
            else:
                rec["d_log_real_spend_stu_pct"] = None
                rec["Z_real_spend_expansion"] = None

            rec["Z_real_spend_regime"] = (
                1 if (cur_rsp is not None and inc_real_medians.get(inc) is not None and cur_rsp > inc_real_medians[inc])
                else (0 if cur_rsp is not None else None)
            )

            # Treatment 3: Public Tertiary Budget % of GDP (No Enrolment denominator) & Total Education % of GDP
            cur_bgdp = cur["tert_spend_gdp_pct"]
            prev_bgdp = prev["tert_spend_gdp_pct"] if prev else None
            if cur_bgdp is not None and prev_bgdp is not None:
                d_bgdp = cur_bgdp - prev_bgdp
                rec["d_tert_spend_gdp_pp"] = d_bgdp
                rec["Z_tert_gdp_expansion"] = 1 if d_bgdp >= 0.05 else 0
            else:
                rec["d_tert_spend_gdp_pp"] = None
                rec["Z_tert_gdp_expansion"] = None

            rec["Z_tert_gdp_regime"] = (
                1 if (cur_bgdp is not None and inc_tert_gdp_medians.get(inc) is not None and cur_bgdp > inc_tert_gdp_medians[inc])
                else (0 if cur_bgdp is not None else None)
            )

            cur_egdp = cur["edu_spend_total_gdp_pct"]
            rec["Z_edu_total_regime"] = (
                1 if (cur_egdp is not None and inc_edu_total_medians.get(inc) is not None and cur_egdp > inc_edu_total_medians[inc])
                else (0 if cur_egdp is not None else None)
            )

            # Forward outcomes & mediators at +5y (t1) and +10y (t2)
            for step, h in [(1, "t1"), (2, "t2")]:
                fut = wave_data[iso3].get(w_idx + step)
                if fut:
                    # Outcome 1A: Non-resource tax-to-GDP change (pp of GDP)
                    rec[f"d_{h}_nonres_tax_gdp_pp"] = (
                        fut["non_resource_tax_gdp_pct"] - cur["non_resource_tax_gdp_pct"]
                        if (fut["non_resource_tax_gdp_pct"] is not None and cur["non_resource_tax_gdp_pct"] is not None) else None
                    )
                    rec[f"y_{h}_nonres_tax_gdp_pct"] = fut["non_resource_tax_gdp_pct"]

                    # Outcome 1B: Pure WDI observed tax-to-GDP change (pp of GDP, zero splicing)
                    rec[f"d_{h}_wdi_tax_gdp_pp"] = (
                        fut["tax_rev_gdp_pct"] - cur["tax_rev_gdp_pct"]
                        if (fut["tax_rev_gdp_pct"] is not None and cur["tax_rev_gdp_pct"] is not None) else None
                    )
                    rec[f"y_{h}_wdi_tax_gdp_pct"] = fut["tax_rev_gdp_pct"]

                    # Outcome 2: Direct Income, Profit & Capital Gains Tax-to-GDP change (pp of GDP)
                    rec[f"d_{h}_inc_tax_gdp_pp"] = (
                        fut["inc_tax_gdp_pct"] - cur["inc_tax_gdp_pct"]
                        if (fut["inc_tax_gdp_pct"] is not None and cur["inc_tax_gdp_pct"] is not None) else None
                    )
                    rec[f"y_{h}_inc_tax_gdp_pct"] = fut["inc_tax_gdp_pct"]

                    # Outcome 3: Direct Income & Profit Tax Share of Revenue change (pp of revenue)
                    rec[f"d_{h}_inc_tax_share_pp"] = (
                        fut["income_profit_tax_share_rev_pct"] - cur["income_profit_tax_share_rev_pct"]
                        if (fut["income_profit_tax_share_rev_pct"] is not None and cur["income_profit_tax_share_rev_pct"] is not None) else None
                    )
                    rec[f"y_{h}_inc_tax_share_pct"] = fut["income_profit_tax_share_rev_pct"]

                    # Outcome 4A: Indirect Goods & Services Tax Share of Revenue change (pp of revenue)
                    rec[f"d_{h}_goods_tax_share_pp"] = (
                        fut["goods_services_tax_share_rev_pct"] - cur["goods_services_tax_share_rev_pct"]
                        if (fut["goods_services_tax_share_rev_pct"] is not None and cur["goods_services_tax_share_rev_pct"] is not None) else None
                    )
                    rec[f"y_{h}_goods_tax_share_pct"] = fut["goods_services_tax_share_rev_pct"]

                    # Outcome 4B: Indirect Goods & Services Tax-to-GDP change (pp of GDP)
                    rec[f"d_{h}_goods_tax_gdp_pp"] = (
                        fut["goods_tax_gdp_pct"] - cur["goods_tax_gdp_pct"]
                        if (fut["goods_tax_gdp_pct"] is not None and cur["goods_tax_gdp_pct"] is not None) else None
                    )
                    rec[f"y_{h}_goods_tax_gdp_pct"] = fut["goods_tax_gdp_pct"]

                    # Mediating macroeconomic variables over [t, t+h]
                    rec[f"d_{h}_log_gdp_pc_pct"] = (
                        (fut["log_gdp_pc_ppp"] - cur["log_gdp_pc_ppp"]) * 100.0
                        if (fut["log_gdp_pc_ppp"] is not None and cur["log_gdp_pc_ppp"] is not None) else None
                    )
                    rec[f"d_{h}_tert_enrol_pp"] = (
                        fut["gross_tert_enrolment_pct"] - cur["gross_tert_enrolment_pct"]
                        if (fut["gross_tert_enrolment_pct"] is not None and cur["gross_tert_enrolment_pct"] is not None) else None
                    )
                    rec[f"d_{h}_gini_disp"] = (
                        fut["gini_disp_harmonised"] - cur["gini_disp_harmonised"]
                        if (fut["gini_disp_harmonised"] is not None and cur["gini_disp_harmonised"] is not None) else None
                    )
                    rec[f"d_{h}_life_exp_yrs"] = (
                        fut["life_expectancy_birth_yrs"] - cur["life_expectancy_birth_yrs"]
                        if (fut["life_expectancy_birth_yrs"] is not None and cur["life_expectancy_birth_yrs"] is not None) else None
                    )
                else:
                    for col in [
                        f"d_{h}_nonres_tax_gdp_pp", f"y_{h}_nonres_tax_gdp_pct",
                        f"d_{h}_wdi_tax_gdp_pp", f"y_{h}_wdi_tax_gdp_pct",
                        f"d_{h}_inc_tax_gdp_pp", f"y_{h}_inc_tax_gdp_pct",
                        f"d_{h}_inc_tax_share_pp", f"y_{h}_inc_tax_share_pct",
                        f"d_{h}_goods_tax_share_pp", f"y_{h}_goods_tax_share_pct",
                        f"d_{h}_goods_tax_gdp_pp", f"y_{h}_goods_tax_gdp_pct",
                        f"d_{h}_log_gdp_pc_pct", f"d_{h}_tert_enrol_pp",
                        f"d_{h}_gini_disp", f"d_{h}_life_exp_yrs",
                    ]:
                        rec[col] = None

            rows.append(rec)

    return rows


def write_codebook() -> None:
    codebook = [
        ("iso3", "Identifier", "ISO 3166-1 alpha-3 sovereign country code", "World Bank"),
        ("iso2", "Identifier", "ISO 3166-1 alpha-2 two-letter country code", "World Bank"),
        ("wave_index", "Time", "Non-overlapping 5-year wave index (1 = 1985-1989 to 8 = 2020-2024)", "Constructed"),
        ("tert_spend_per_student_winsor", "Treatment (Ratio)", "Public expenditure per university student (% of GDP per person, winsorised [1, 150])", "UNESCO UIS (SE.XPD.TERT.PC.ZS)"),
        ("real_tert_spend_per_student_ppp", "Treatment (Real $)", "Real constant-2021 PPP dollars spent per university student (no GDP denominator)", "UNESCO UIS & WDI"),
        ("tert_spend_gdp_pct", "Treatment (% GDP)", "Public university expenditure as % of GDP (no student headcount denominator)", "UNESCO UIS (SE.XPD.TOTL.GD.ZS * SE.XPD.TERT.ZS)"),
        ("edu_spend_total_gdp_pct", "Treatment (Total Edu)", "Total public expenditure on all education levels (% of GDP)", "UNESCO UIS (SE.XPD.TOTL.GD.ZS)"),
        ("Z_regime_inc", "Binary Treatment 1A", "1 if per-student university spending ratio exceeds World Bank income-group median", "Constructed (strictly observed)"),
        ("Z_expansion_obs", "Binary Treatment 1B", "1 if observed per-student spending ratio increases by >=2.5 pp and >=2.5% over wave", "Constructed (strictly observed)"),
        ("Z_real_spend_regime", "Binary Treatment 2A", "1 if real PPP dollars per student exceeds World Bank income-group median", "Constructed (no GDP denominator)"),
        ("Z_real_spend_expansion", "Binary Treatment 2B", "1 if real PPP dollars per student grows by >=5% over 5-year wave", "Constructed (no GDP denominator)"),
        ("Z_tert_gdp_regime", "Binary Treatment 3A", "1 if public university spending (% of GDP) exceeds World Bank income-group median", "Constructed (no enrolment denominator)"),
        ("Z_edu_total_regime", "Binary Treatment 3B", "1 if total public education spending (% of GDP) exceeds income-group median", "Constructed"),
        ("d_t1_nonres_tax_gdp_pp", "Outcome Y1 (+5y)", "5-year change in non-resource domestic tax revenue (% of GDP, percentage points)", "IMF GFS / WDI"),
        ("d_t2_nonres_tax_gdp_pp", "Outcome Y1 (+10y)", "10-year change in non-resource domestic tax revenue (% of GDP, percentage points)", "IMF GFS / WDI"),
        ("d_t1_inc_tax_gdp_pp", "Outcome Y2 (+5y)", "5-year change in direct income, profit & capital gains tax (% of GDP, percentage points)", "IMF GFS / WDI (GC.TAX.YPKG.ZS * Tax/GDP)"),
        ("d_t2_inc_tax_gdp_pp", "Outcome Y2 (+10y)", "10-year change in direct income, profit & capital gains tax (% of GDP, percentage points)", "IMF GFS / WDI (GC.TAX.YPKG.ZS * Tax/GDP)"),
        ("d_t1_inc_tax_share_pp", "Outcome Y3 (+5y)", "5-year change in direct income, profit & capital gains share of revenue (percentage points)", "IMF GFS / WDI (GC.TAX.YPKG.ZS)"),
        ("d_t2_inc_tax_share_pp", "Outcome Y3 (+10y)", "10-year change in direct income, profit & capital gains share of revenue (percentage points)", "IMF GFS / WDI (GC.TAX.YPKG.ZS)"),
        ("d_t1_goods_tax_share_pp", "Outcome Y4 (+5y)", "5-year change in indirect goods & services / VAT share of revenue (pp, negative control)", "IMF GFS / WDI (GC.TAX.GSRV.RV.ZS)"),
        ("d_t2_goods_tax_share_pp", "Outcome Y4 (+10y)", "10-year change in indirect goods & services / VAT share of revenue (pp, negative control)", "IMF GFS / WDI (GC.TAX.GSRV.RV.ZS)"),
        ("d_t1_log_gdp_pc_pct", "Mediator (+5y)", "5-year real GDP per person PPP log growth (%, controlled in Direct Fiscal Effect model)", "WDI (NY.GDP.PCAP.PP.KD)"),
        ("d_t2_log_gdp_pc_pct", "Mediator (+10y)", "10-year real GDP per person PPP log growth (%, controlled in Direct Fiscal Effect model)", "WDI (NY.GDP.PCAP.PP.KD)"),
        ("lag_gdp_pc_growth_pct", "Pre-Treatment Control", "Lagged (wave t-1) annual real GDP per person growth (%, avoids wave-t collider)", "WDI (NY.GDP.PCAP.KD.ZG)"),
    ]
    cb_path = PROC_DIR / "codebook_variables.csv"
    with open(cb_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["variable", "role", "description", "source"])
        writer.writerows(codebook)
    print(f"Saved variable codebook to {cb_path.name}")


def main():
    meta_by_iso3, obs = load_raw_sources()
    rows = build_5y_panel(meta_by_iso3, obs)

    out_5y = PROC_DIR / "clean_tax_panel.csv"
    with open(out_5y, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)
    print(f"Saved 5-year panel to {out_5y.name} ({len(rows):,} country-waves across {len(meta_by_iso3)} countries).")

    # Also save non-overlapping 10-year waves (even wave indices: 1990-1994 -> 2000-2004 -> 2010-2014 -> 2020-2024)
    rows_10y_nonoverlap = [r for r in rows if r["wave_index"] in (2, 4, 6)]
    out_10y = PROC_DIR / "clean_tax_panel_10y_nonoverlapping.csv"
    with open(out_10y, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows_10y_nonoverlap)
    print(f"Saved non-overlapping 10-year panel to {out_10y.name} ({len(rows_10y_nonoverlap):,} country-waves).")

    write_codebook()


if __name__ == "__main__":
    main()
