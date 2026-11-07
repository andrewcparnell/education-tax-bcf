# University Funding & Future Tax Returns - Interactive Policy Explorer (`app/`)

This folder contains the three-tab interactive web application for policy makers, tax specialists, and higher-education analysts exploring how changes in government university funding affect future tax revenue across 121 countries (1985-2024).

---

## Key Features

* **Units Switcher (`Country Total Currency`, `Per-Person Currency`, or `Percentage points`):**
  * Defaults to **EUR (€ billion / yr, country total)** (showing the estimated annual tax change across the whole country holding population and baseline GDP constant) and lets users switch seamlessly between **Country Total (`EUR`, `USD`, `GBP` billion / yr)**, **Per-Person (`EUR`, `USD`, `GBP` per person / yr)**, and **Percentage points (pp)** at any time.
  * Hovering over any bar or point displays the country total in billions or millions, the per-person equivalent, and the underlying percentage-point change (alongside the country's historical average university funding level relative to its World Bank income-group median threshold and its baseline tax structure).
* **Built-In Help Page (`?` Button):**
  * Clicking the `?` button in the top-right header opens a plain-language guide explaining how the app works and how to use each tab.
* **Three Policy-Focused Tabs:**
  1. **Future Tax Estimation:** Compare the estimated 5-year, 10-year, or side-by-side 5-vs-10-year change in tax revenue after increasing university funding across any selection of countries (with quick peer-group pills for *EU & UK*, *Nordic vs Tuition*, and *Emerging* economies), with **zero** highlighted as the clear benchmark and 80% / 95% uncertainty ranges displayed.
  2. **Historical Data:** Play the Gapminder-style animated scatter plot and synchronised historical country trajectories across five-year periods (`1990-1994` to `2020-2024`). Features mode-aware axis menus covering UNESCO spend per student (`% of GDP/pc`), real PPP dollars per student (`2021 PPP USD`), university budget (`% of GDP`), university enrolment (`%`), income tax share, goods/VAT share, and tax-to-GDP ratios, plus direct click-on-bubble highlighting and a *Denominator Trap* preset (**Ireland**, **Chile**, **Norway**, **Austria**, **Ethiopia**, **Malawi**).
  3. **Full policy scenarios:** Splits the estimated impact for a single country into a two-panel view separating **Tax Revenue Mobilisation** (left panel: Income Tax and Total Tax per person) from **Shift in Tax Mix** (right panel: Income Tax Share vs Goods/VAT Share in percentage points of total tax). Includes one-click policy scenarios (*Boost Per-Student*, *Funded Expansion*, *Unfunded Crowding*, and *Budget Cut*), a `5 vs 10 Years` comparison mode, and a collapsible **"Adjust other country factors"** drawer with live baseline deltas.

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
