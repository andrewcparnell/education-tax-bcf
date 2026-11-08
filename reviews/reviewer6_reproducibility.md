# Reviewer 6: End-to-End Reproducibility Audit Report

**Repository:** `/Users/andrewparnell/Documents/GitHub/education-tax-bcf`  
**Audit Role:** Reviewer 6 (Reproducibility Referee, Phase 6 of `/academic-paper-workflow`)  
**Verification Commands Executed:**
- `Rscript tests/test_pipeline.R`: **PASSED** (0 errors; all 7 test sections succeeded).
- `python3 scripts/check_style.py --warnings-as-errors --data-plural error --all .`: **PASSED** (`Clean. Checked 18 file(s), no house-style issues found.`).
- `shasum -a 256 data/raw/*.csv`: **PASSED** (all 3 raw data files match `data/raw/PROVENANCE.md` and `data/raw/checksums_sha256.json` byte-for-byte).

## Overall Reproducibility Verdict

**Verdict: CONDITIONAL PASS (Minor-to-Moderate Reproducibility Revisions Required Before Release)**

The core statistical pipeline (`01` -> `02` -> `03` -> `04` -> `06` -> `app/prepare_app_data.R` -> `tests/test_pipeline.R`) is well-engineered, deterministic (fixed seeds across R and C++ Gibbs samplers), and passes all automated verification and style gates. All primary causal tables in `paper/paper.tex` match the generated CSV tables in `outputs/tables/`.

However, the audit identified four reproducibility and synchronisation items to address:
1. **Undeclared R packages in `environment.yml` (`r-ranger`, `r-patchwork`, `r-ggrepel`)** that would cause `run_all.sh` to fail at Steps 3 and 5 in a clean Conda environment.
2. **Stale binary-treatment (`Z = 0 -> 1`) and longitudinal (`lbcf_3wave`) descriptions in `README.md`**, mismatched header comments in `run_all.sh`, and leftover legacy files (`src/r/05_run_longitudinal_bcf_tax.R`, `src/r/07_publishability_gate_diagnostics.R`, `outputs/tables/table5_longitudinal_bcf_trajectories.csv`, `outputs/tables/publishability_gate_diagnostics.csv`).
3. **Anomaly screening note in Section 3.1 (`paper/paper.tex` line 112 and `paper/paper.md` line 67) and `data/raw/PROVENANCE.md` indicator list:** Update the anomaly screening sentence in Section 3.1 to match the exact 4 WDI (`Sudan 1995-1999`, `Timor-Leste 2010-2014`, `United Arab Emirates 2010-2014 and 2015-2019`) + 1 UNESCO (`Madagascar 2015-2019` at `0.036%`) observations screened in `02_build_clean_tax_panel.R`, and clarify in Table 1 (`tab:eda1`) that Table 1 reports full-panel observed distributions (`808 country-waves across 162 countries`) matching Figure 2 (`eda_fig1_raw_distributions_and_bivariate.pdf`), while `outputs/tables/eda_table1_income_group_summary.csv` reports the 80% training-split summary (`660 waves across 130 countries`).
4. **Unsynchronised numbers and a broken file reference in `paper/paper.md`:** Synchronise `paper/paper.md` with `paper/paper.tex` and `outputs/tables/*.csv`, and replace `/tmp/rcpp_cache_edu_tax_bcf` with `file.path(tempdir(), "rcpp_cache_edu_tax_bcf")`.
