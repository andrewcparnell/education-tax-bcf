# University Funding & Future Tax Returns - Interactive Policy Explorer (`app/`)

This folder contains the three-tab interactive web application for policy makers exploring how changes in government university funding affect future tax revenue across 121 countries (1985-2024).

---

## Key Features

* **Units Switcher (`EUR`, `USD`, `GBP`, or `Percentage points`):**
  * Defaults to **EUR (€ per person / year)** and lets users switch seamlessly between **EUR (€)**, **USD ($)**, **GBP (£)**, and **Percentage points (pp)** at any time. Hovering over any bar or point also displays the total national annual impact in billions or millions of EUR, USD, or GBP.
* **Built-In Help Page (`?` Button):**
  * Clicking the `?` button in the top-right header opens a plain-language guide explaining how the app works and how to use each tab.
* **Three Policy-Focused Tabs:**
  1. **Future Tax Estimation:** Compare the estimated 5-year and 10-year change in tax revenue after increasing university funding across any selection of countries, with **zero** highlighted as the clear benchmark and 80% / 95% uncertainty ranges displayed.
  2. **Historical Data:** Play the Gapminder-style animated scatter plot and historical country trajectories across five-year periods (`1990-1994` to `2020-2024`), defaulting to major long-term movers with rich multi-decade records (**Norway**, **Chile**, **Austria**, **Lithuania**, and **South Africa**).
  3. **Full policy scenarios:** Test how increasing or reducing university funding in a single country affects all four tax revenue streams when other country characteristics remain at their historical averages or are adjusted inside the collapsible **"Adjust other country factors"** drawer.

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
