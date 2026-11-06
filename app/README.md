# Interactive Causal & Historical Explorer (`app/`)

This folder contains the companion three-tab interactive web application for:

> **Does Increasing Government Spend on Tertiary Education Improve Fiscal Policy? A Causal Inference Analysis**  
> Andrew C. Parnell (School of Mathematics and Statistics, University College Dublin)

---

## What Questions Does the App Answer?

### Tab 1: Country Future Tax Effect Comparison ($Z = 0 \to 1$)
- **Question:** *For country $[X]$, if they were to increase investment in tertiary education ($Z = 0 \to 1$), what would be the effect on tax take in 5 or 10 years?*
- **Features:**
  - Multi-country comparison selector across all 121 countries (with search and regional/OECD presets).
  - Switch between **+5 Years**, **+10 Years**, or a side-by-side **5y vs 10y** horizon view across all 4 tax outcomes.
  - Forest plot showing posterior means with both **80% (thick)** and **95% (thin)** Bayesian credible intervals (CI) benchmarked against the global Average Treatment Effect (ATE).
  - 10-year longitudinal trajectory plot (**Baseline Wave 0 $\to$ +5y Wave 1 $\to$ +10y Wave 2**) from the Longitudinal Bayesian Causal Forest (LBCF).

### Tab 2: Historical Spending vs Tax Take Animation (1985-2024)
- **Question:** *What has previously happened to country $[X]$ in terms of its tax take as its spending on tertiary education went up or down?*
- **Features:**
  - Gapminder-style animated scatter and historical trail explorer across the 8 five-year waves (`1985-1989` to `2020-2024`).
  - **Play / Pause** animation player bar and interactive wave slider.
  - Toggle between **5-Year Changes ($\Delta$ Spending vs $\Delta$ Tax Take)** and **Historical Levels**.
  - Select multiple countries to trace their connected historical arrows and inspect synchronised time-series plots below.

### Tab 3: Counterfactual Policy & Moderator Scenario Simulator (CATE)
- **Question:** *If country $[X]$ increased or reduced spending in tertiary education and a selection of other structural variables changed, what would be the effect on tax take?*
- **Features:**
  - Select any country $[X]$, policy direction (**Increase Spend $Z: 0 \to 1$** or **Reduce Spend $Z: 1 \to 0$**), and horizon (**+5 Years** or **+10 Years**).
  - All 7 structural moderators default automatically to the selected country's observed baseline averages and are neatly tucked inside the collapsible **"Customise Structural Moderators (Optional)"** drawer so the interface stays clean and uncluttered.
  - Includes a one-click **Reset All Moderators to Country Averages** button and a tornado plot showing how each moderator shifts the predicted Conditional Average Treatment Effect (CATE).

---

## How to Launch the App

### Option 1: Open Directly in Any Web Browser (Zero Setup)
Because `app/data/app_data.js` bundles the processed model outputs directly, you can open `app/index.html` immediately without starting a server:

```bash
open app/index.html
```

### Option 2: Launch via R / Shiny
From the repository root in R or RStudio:

```r
Rscript app/app.R
# or inside an interactive R session:
shiny::runApp("app")
```

### Regenerating the App Data Bundle
If you re-run the C++/R causal pipeline and wish to refresh the data files in `app/data/` (`country_cates.csv`, `historical_waves.csv`, `app_data.json`, and `app_data.js`):

```bash
Rscript app/prepare_app_data.R
```
