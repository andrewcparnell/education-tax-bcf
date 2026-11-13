# University Funding & Cohort Return on Investment (ROI) Explorer (`app/`)

This folder contains the three-tab interactive web application for policy makers, treasury officials, tax specialists, and higher-education analysts exploring whether government spending on tertiary (university) education provides a positive return on investment across 121 countries (1985-2024).

---

## Key Features

* **Horizon & Units Switcher:**
  * Defaults to **40-Year Career Return vs Cohort Input (`8x`)** in **EUR (€ billion, country total)** and lets users switch seamlessly between the **40-Year Career ROI** view, single-year **10-Year (`+10y`)**, **5-Year (`+5y`)**, and **5 vs 10 Years** comparisons, across **Country Total (`EUR`, `USD`, `GBP` billion)**, **Per-Person (`EUR`, `USD`, `GBP`)**, and **Percentage points (pp)**.
  * Supports all four continuous university funding variables ($Z_1$: per-student `% of GDP/pc`, $Z_2$: 5-year funding change, $Z_3$: real 2021 PPP dollars per student, and $Z_4$: university budget `% of GDP`) and all four tax outcomes ($Y_1$: Total Non-Resource Tax `% of GDP`, $Y_2$: Direct Income Tax `% of GDP`, $Y_3$: Direct Income Tax Share `% of tax`, and $Y_4$: Goods & Services Tax Share `% of tax`).
* **Built-In Plain-Language Help Guide (`?` Button):**
  * Clicking the `?` button in the top-right header opens an accessible guide explaining the single-cohort 40-year career ROI accounting (`1 cohort input = 1 year of system-wide boost; 40-year career output = 8x Year-10 annual flow`) and why treasury budget decisions should pair Total Non-Resource Tax ($Y_1$) with Direct Income Tax ($Y_2$).
* **Three Policy-Focused Tabs:**
  1. **Cohort Return on Investment (ROI):** Compare each country's single-cohort degree input cost against its 40-year career tax output (`Y1` and `Y2`, with 95% credible intervals, benefit-cost ratio `BCR = Output / Input`, and posterior probability of net profit $P_{\text{net}}$), explore an interactive **Investment Variable vs 40-Year Career ROI Scatter Plot** with vertical 95% CI bars and country filtering, and browse the complete **70-Country Policy-Maker ROI Lookup Table (2020-2024)**.
  2. **Historical Data:** Play the Gapminder-style animated scatter plot and synchronised historical country trajectories across five-year periods (`1990-1994` to `2020-2024`), including a one-click *Denominator Trap* preset (**Ireland**, **Chile**, **Norway**, **Austria**, **Ethiopia**, **Malawi**).
  3. **Treasury ROI Pitch & Custom Scenarios:** Generates a ready-to-use **Treasury Pitch Card** for any selected country (with cohort degree input, 40-year career `Y1` and `Y2` outputs, 95% CIs, `BCR`, and $P_{\text{net}}$) alongside a two-panel scenario simulator separating **Tax Revenue Mobilisation** (`Y1` and `Y2`) from **Shift in Tax Mix** (`Y3` and `Y4`) and a custom baseline override drawer.

---

## How to Launch the App

### Option 1: Open Directly in Any Browser
```bash
open app/index.html
```

### Option 2: Launch via R / Shiny
```r
Rscript app/app.R
```
