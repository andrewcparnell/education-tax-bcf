# University Funding: Return on Investment Explorer (`app/`)

This folder contains the two-tab interactive web application for policy makers, treasury officials, and researchers exploring whether government spending on tertiary (university) education provides a positive return on investment across 121 countries (1985-2024). By default, the interface presents a clean, streamlined view focused on single-cohort 40-year career returns with explicit 80% and 95% credible intervals. Switching **Advanced** on in the top header unlocks additional time horizons, discounted and conservative career accounting rules, all four funding measures ($Z_1$ to $Z_4$), tax-share outcomes ($Y_3$ and $Y_4$), and custom national baseline inputs.

---

## Key Features

* **Simple Default Mode + One-Click `Advanced` Switch:**
  * **Default Mode:** Focuses immediately on **Total Tax** vs **Income Tax Only**, currency pills (`EUR`, `USD`, `GBP`), and clear error bars (`80%` and `95%` credible intervals) without clutter or technical jargon.
  * **Advanced Mode:** Reveals per-person and percentage-point (`pp`) scales, `+5y` and `+10y` annual horizons, discounted (`r - g = 1.5%`, `5.7x`) and conservative two-wave (`4.0x`) career multipliers, funding definitions $Z_1$ to $Z_4$, tax-mix outcomes $Y_3$ and $Y_4$, CSV export, and custom post-2019 national baseline overrides.
* **Two Streamlined Tabs:**
  1. **Compare Countries:** Rank selected countries by expected 40-year return per unit spent (`x`, with break-even line and 80%/95% error bars) or total currency, or switch to **By Enrolment** to view the diminishing-returns curve across tertiary participation levels.
  2. **Country Explorer:** Select any country to see three headline KPI cards (**Cohort Degree Cost**, **Expected 40-Year Total Tax Return**, and **Chance of Net Gain & Floor**) paired with a clean 95% error-bar chart comparing upfront cost against expected returns.

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
