#!/usr/bin/env bash
# ==============================================================================
# Master End-to-End Reproducibility Pipeline (run_all.sh)
#
# Rebuilds the entire project from raw data verification to the compiled PDF
# manuscript and house-style verification with zero manual steps:
#   1. Step 01: Verify raw data & SHA-256 checksums (src/r/01_download_tax_education_data.R)
#   2. Step 02: Build clean 5-year & 10-year panels and country-blocked folds (src/r/02_build_clean_tax_panel.R)
#   3. Step 03: Generate training-set EDA tables, figures & report (src/r/03_eda_and_summary_tables.R)
#   4. Step 04: Fit Continuous Multivariate BCF models, CV, holdout & benchmarks (src/r/04_run_mvbcf_tax_models.R)
#   5. Step 05: Generate publication figures, residual & holdout diagnostics (src/r/06_generate_figures_and_diagnostics.R)
#   6. Step 06: Export interactive policy app data payload (app/prepare_app_data.R)
#   7. Step 07: Run automated data & numerical consistency tests (tests/test_pipeline.R)
#   8. Step 08: Compile LaTeX manuscript (paper/paper.tex -> paper/paper.pdf)
#   9. Step 09: Run automated house-style linter (scripts/check_style.py)
# ==============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${REPO_ROOT}"

echo "======================================================================"
echo " Starting End-to-End Reproducibility Pipeline at $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo " Repository root: ${REPO_ROOT}"
echo "======================================================================"

echo "[1/9] Running Step 01: Raw data & SHA-256 verification..."
Rscript src/r/01_download_tax_education_data.R

echo "[2/9] Running Step 02: Building clean disaggregated tax & education panel..."
Rscript src/r/02_build_clean_tax_panel.R

echo "[3/9] Running Step 03: Generating EDA summary tables & diagnostic figures..."
Rscript src/r/03_eda_and_summary_tables.R
if command -v quarto >/dev/null 2>&1; then
  quarto render eda/eda_report.qmd >/dev/null 2>&1 || true
elif [ -x "/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto" ]; then
  /Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto render eda/eda_report.qmd >/dev/null 2>&1 || true
fi

echo "[4/9] Running Step 04: Fitting Continuous Multivariate BCF (mvbcf), CV, holdout & benchmarks..."
Rscript src/r/04_run_mvbcf_tax_models.R

echo "[5/9] Running Step 05: Generating publication figures, residual & holdout diagnostics..."
Rscript src/r/06_generate_figures_and_diagnostics.R

echo "[6/9] Running Step 06: Exporting interactive policy app data payload..."
Rscript app/prepare_app_data.R

echo "[7/9] Running Step 07: Executing automated pipeline & number-matching tests..."
Rscript tests/test_pipeline.R

echo "[8/9] Running Step 08: Compiling paper/paper.pdf from paper/paper.tex..."
if command -v pdflatex >/dev/null 2>&1; then
  (
    cd paper
    pdflatex -interaction=nonstopmode paper.tex >/dev/null
    bibtex paper >/dev/null
    pdflatex -interaction=nonstopmode paper.tex >/dev/null
    pdflatex -interaction=nonstopmode paper.tex >/dev/null
    pdflatex -interaction=nonstopmode paper.tex >/dev/null
    rm -f paper.aux paper.bbl paper.blg paper.log paper.out
  )
  echo "      Compiled paper/paper.pdf successfully."
else
  echo "      WARNING: pdflatex not found on PATH; skipping PDF compilation."
fi

echo "[9/9] Running Step 09: Verifying house-style rules via scripts/check_style.py..."
python3 scripts/check_style.py --warnings-as-errors --data-plural error --all .

echo "======================================================================"
echo " Pipeline completed cleanly at $(date -u '+%Y-%m-%dT%H:%M:%SZ')!"
echo "======================================================================"
