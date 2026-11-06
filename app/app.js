// =============================================================================
// Script: app/app.js
// Purpose: Interactive 3-Tab Causal & Historical Explorer for Tertiary
//          Education Spending and Fiscal Policy Returns (121 Countries)
// Author: Andrew C. Parnell
// =============================================================================

(function () {
  "use strict";

  const DATA = window.EDUCATION_TAX_APP_DATA;
  if (!DATA) {
    console.error("EDUCATION_TAX_APP_DATA not found. Run Rscript app/prepare_app_data.R.");
    return;
  }

  const COUNTRIES = DATA.countries || [];
  const HISTORICAL = DATA.historical || [];
  const GLOBAL_ATE = DATA.global_ate || [];
  const LONG_ATE = DATA.longitudinal_ate || [];
  const SURROGATES = DATA.surrogates || {};

  // Map country by ISO3
  const COUNTRY_MAP = {};
  COUNTRIES.forEach((c) => {
    COUNTRY_MAP[c.iso3] = c;
  });

  // Outcome metadata
  const OUTCOME_META = {
    inc_share: {
      key: "inc_share",
      label: "Income & Profit Tax Share of Revenue (pp)",
      shortLabel: "Income Tax Share (pp)",
      outcomeIndex: 3,
      lbcfCode: "inc_tax_share_pp",
      baseCol: "inc_tax_share_pct",
      baseUnit: "% of rev",
      colour: "#136f63"
    },
    inc_gdp: {
      key: "inc_gdp",
      label: "Income & Profit Tax / GDP (pp)",
      shortLabel: "Income Tax / GDP (pp)",
      outcomeIndex: 2,
      lbcfCode: "inc_tax_gdp_pp",
      baseCol: "inc_tax_gdp_pct",
      baseUnit: "% of GDP",
      colour: "#0b2545"
    },
    tax_gdp: {
      key: "tax_gdp",
      label: "Total Non-Resource Tax / GDP (pp)",
      shortLabel: "Non-Resource Tax / GDP (pp)",
      outcomeIndex: 1,
      lbcfCode: "tax_gdp_pp",
      baseCol: "non_resource_tax_gdp_pct",
      baseUnit: "% of GDP",
      colour: "#1d4ed8"
    },
    goods_share: {
      key: "goods_share",
      label: "Goods & Services Tax Share of Revenue (pp)",
      shortLabel: "Goods & Services Share (pp)",
      outcomeIndex: 4,
      lbcfCode: "goods_tax_share_pp",
      baseCol: "goods_tax_share_pct",
      baseUnit: "% of rev",
      colour: "#d97706"
    }
  };

  const REGION_COLOURS = {
    "Europe & Central Asia": "#0b2545",
    "East Asia & Pacific": "#136f63",
    "Latin America & Caribbean": "#d97706",
    "North America": "#2563eb",
    "Sub-Saharan Africa": "#be123c",
    "Middle East & North Africa": "#7c3aed",
    "South Asia": "#059669"
  };

  const WAVE_LABELS = {
    1: "1985-1989",
    2: "1990-1994",
    3: "1995-1999",
    4: "2000-2004",
    5: "2005-2009",
    6: "2010-2014",
    7: "2015-2019",
    8: "2020-2024"
  };

  // Helper formatting
  function fmtSigned(v, digits = 2) {
    if (v === null || v === undefined || Number.isNaN(Number(v))) return "N/A";
    const n = Number(v);
    return (n >= 0 ? "+" : "") + n.toFixed(digits);
  }

  function fmtNum(v, digits = 1) {
    if (v === null || v === undefined || Number.isNaN(Number(v))) return "N/A";
    return Number(v).toFixed(digits);
  }

  function getGlobalATE(horizon, outcomeKey) {
    const meta = OUTCOME_META[outcomeKey];
    if (!meta) return null;
    const modelId = Number(horizon) === 5 ? "M2a_Direct_5y" : "M2b_Direct_10y";
    return GLOBAL_ATE.find(
      (r) => r.model_id === modelId && Number(r.outcome_index) === meta.outcomeIndex
    );
  }

  function getLongATE(outcomeKey) {
    const meta = OUTCOME_META[outcomeKey];
    if (!meta) return null;
    return LONG_ATE.find((r) => r.outcome_code === meta.lbcfCode);
  }

  // ===========================================================================
  // Tab Switching
  // ===========================================================================
  const tabBtns = document.querySelectorAll(".tab-btn");
  const tabPanes = document.querySelectorAll(".tab-pane");

  tabBtns.forEach((btn) => {
    btn.addEventListener("click", () => {
      const target = btn.getAttribute("data-tab");
      tabBtns.forEach((b) => b.classList.toggle("active", b === btn));
      tabPanes.forEach((p) => p.classList.toggle("active", p.id === target));
      if (target === "tab1") renderTab1();
      if (target === "tab2") renderTab2();
      if (target === "tab3") renderTab3();
    });
  });

  // ===========================================================================
  // TAB 1: Country Future Tax Effect Comparison (Z = 0 -> 1)
  // ===========================================================================
  const t1State = {
    horizon: "10", // "5", "10", or "both"
    outcome: "inc_share",
    selectedIsos: ["IRL", "GBR", "SWE", "USA", "KOR", "CHL"],
    searchQuery: ""
  };

  const t1Presets = {
    default: ["IRL", "GBR", "SWE", "USA", "KOR", "CHL"],
    nordic: ["SWE", "DNK", "NOR", "FIN", "DEU", "FRA", "NLD"],
    anglo: ["IRL", "GBR", "USA", "CAN", "AUS", "NZL"],
    emerging: ["CHL", "COL", "BRA", "ZAF", "THA", "MYS", "MEX"],
    clear: []
  };

  function buildTab1CountryList() {
    const box = document.getElementById("t1-country-list");
    const q = t1State.searchQuery.trim().toLowerCase();
    box.innerHTML = "";

    const filtered = COUNTRIES.filter((c) => {
      if (!q) return true;
      return (
        c.country_name.toLowerCase().includes(q) ||
        c.iso3.toLowerCase().includes(q) ||
        (c.region && c.region.toLowerCase().includes(q))
      );
    });

    filtered.forEach((c) => {
      const div = document.createElement("div");
      div.className = "country-item";
      const checked = t1State.selectedIsos.includes(c.iso3);
      div.innerHTML = `
        <label>
          <input type="checkbox" value="${c.iso3}" ${checked ? "checked" : ""} />
          <span>${c.country_name}</span>
        </label>
        <span class="country-tag">${c.iso3}</span>
      `;
      const cb = div.querySelector("input");
      cb.addEventListener("change", () => {
        if (cb.checked) {
          if (!t1State.selectedIsos.includes(c.iso3)) {
            t1State.selectedIsos.push(c.iso3);
          }
        } else {
          t1State.selectedIsos = t1State.selectedIsos.filter((x) => x !== c.iso3);
        }
        document.getElementById("t1-selected-count").textContent =
          `${t1State.selectedIsos.length} selected`;
        renderTab1();
      });
      box.appendChild(div);
    });

    document.getElementById("t1-selected-count").textContent =
      `${t1State.selectedIsos.length} selected`;
  }

  function initTab1Controls() {
    // Horizon buttons
    document.querySelectorAll("#t1-horizon-group .seg-btn").forEach((btn) => {
      btn.addEventListener("click", () => {
        document
          .querySelectorAll("#t1-horizon-group .seg-btn")
          .forEach((b) => b.classList.toggle("active", b === btn));
        t1State.horizon = btn.getAttribute("data-horizon");
        renderTab1();
      });
    });

    // Outcome select
    const outSel = document.getElementById("t1-outcome-select");
    outSel.addEventListener("change", () => {
      t1State.outcome = outSel.value;
      renderTab1();
    });

    // Presets
    document.querySelectorAll("[data-preset]").forEach((btn) => {
      btn.addEventListener("click", () => {
        const key = btn.getAttribute("data-preset");
        if (t1Presets[key]) {
          t1State.selectedIsos = t1Presets[key].filter((iso) => COUNTRY_MAP[iso]);
          buildTab1CountryList();
          renderTab1();
        }
      });
    });

    // Search box
    const searchInput = document.getElementById("t1-country-search");
    searchInput.addEventListener("input", () => {
      t1State.searchQuery = searchInput.value;
      buildTab1CountryList();
    });

    buildTab1CountryList();
  }

  function renderTab1() {
    const selected = t1State.selectedIsos
      .map((iso) => COUNTRY_MAP[iso])
      .filter(Boolean);

    const outKey = t1State.outcome === "all4" ? "inc_share" : t1State.outcome;
    const meta = OUTCOME_META[outKey];
    const hNum = t1State.horizon === "5" ? 5 : 10;
    const globalRow = getGlobalATE(hNum, outKey);
    const longRow = getLongATE(outKey);

    // KPI Cards
    const kpiContainer = document.getElementById("t1-kpi-row");
    const prefix = hNum === 5 ? "tau5_" : "tau10_";
    const vals = selected
      .map((c) => c[prefix + outKey])
      .filter((v) => v !== null && v !== undefined && Number.isFinite(Number(v)));
    const meanSel =
      vals.length > 0 ? vals.reduce((a, b) => a + b, 0) / vals.length : null;

    kpiContainer.innerHTML = `
      <div class="kpi-card">
        <div class="kpi-title">Global ATE (+${hNum} Years)</div>
        <div class="kpi-val">${globalRow ? fmtSigned(globalRow.ate_mean, 2) + " pp" : "N/A"}</div>
        <div class="kpi-sub">80% CI: [${globalRow ? fmtSigned(globalRow.ate_cri80_low, 2) : ""}, ${globalRow ? fmtSigned(globalRow.ate_cri80_high, 2) : ""}] | P = ${globalRow ? Number(globalRow.prob_positive).toFixed(2) : ""}</div>
      </div>
      <div class="kpi-card secondary">
        <div class="kpi-title">Selected Countries Mean (+${hNum}y)</div>
        <div class="kpi-val">${meanSel !== null ? fmtSigned(meanSel, 2) + " pp" : "Select country"}</div>
        <div class="kpi-sub">Across ${vals.length} selected ${vals.length === 1 ? "country" : "countries"} (${meta.shortLabel})</div>
      </div>
      <div class="kpi-card">
        <div class="kpi-title">10-Year Cumulative LBCF ATE</div>
        <div class="kpi-val">${longRow ? fmtSigned(longRow.ate_cum_10y_mean, 2) + " pp" : "N/A"}</div>
        <div class="kpi-sub">80% CI: [${longRow ? fmtSigned(longRow.ate_cum_10y_low80, 2) : ""}, ${longRow ? fmtSigned(longRow.ate_cum_10y_high80, 2) : ""}] | P = ${longRow ? Number(longRow.prob_cum_10y_pos).toFixed(3) : ""}</div>
      </div>
    `;

    // Main Forest / Comparison Plot
    renderTab1ForestPlot(selected);

    // Trajectory Plot (Wave 0 -> +5y -> +10y)
    renderTab1TrajectoryPlot(selected, outKey);

    // Summary Table
    renderTab1Table(selected, outKey);
  }

  function renderTab1ForestPlot(selected) {
    const plotDiv = document.getElementById("t1-forest-plot");
    const titleEl = document.getElementById("t1-main-chart-title");

    if (selected.length === 0) {
      Plotly.purge(plotDiv);
      plotDiv.innerHTML = `<div style="padding:3rem;text-align:center;color:#64748b;">Select one or more countries on the left to compare their estimated treatment effects.</div>`;
      return;
    }

    if (t1State.outcome === "all4") {
      const h = t1State.horizon === "5" ? 5 : 10;
      const pref = h === 5 ? "tau5_" : "tau10_";
      titleEl.textContent = `All 4 Tax Outcomes Compared (+${h} Years Ahead, Z = 0 -> 1)`;

      const outcomesOrder = ["inc_share", "inc_gdp", "tax_gdp", "goods_share"];
      const traces = outcomesOrder.map((k) => {
        const m = OUTCOME_META[k];
        return {
          type: "bar",
          name: m.shortLabel,
          x: selected.map((c) => c.country_name),
          y: selected.map((c) => c[pref + k]),
          marker: { color: m.colour },
          error_y: {
            type: "data",
            symmetric: false,
            array: selected.map((c) =>
              c[pref + k + "_high80"] !== null && c[pref + k] !== null
                ? c[pref + k + "_high80"] - c[pref + k]
                : 0
            ),
            arrayminus: selected.map((c) =>
              c[pref + k] !== null && c[pref + k + "_low80"] !== null
                ? c[pref + k] - c[pref + k + "_low80"]
                : 0
            ),
            thickness: 1.5,
            width: 4
          },
          hovertemplate: `<b>%{x}</b><br>${m.shortLabel}: %{y:+.2f} pp<extra></extra>`
        };
      });

      const layout = {
        barmode: "group",
        margin: { t: 25, r: 25, b: 65, l: 65 },
        yaxis: {
          title: "Estimated Treatment Effect (percentage points, pp)",
          zeroline: true,
          zerolinecolor: "#94a3b8",
          zerolinewidth: 1.5,
          gridcolor: "#f1f5f9"
        },
        xaxis: { title: "" },
        legend: { orientation: "h", y: 1.12, x: 0 },
        paper_bgcolor: "#ffffff",
        plot_bgcolor: "#ffffff"
      };

      Plotly.newPlot(plotDiv, traces, layout, { responsive: true, displayModeBar: false });
      return;
    }

    const outKey = t1State.outcome;
    const meta = OUTCOME_META[outKey];

    if (t1State.horizon === "both") {
      titleEl.textContent = `+5 Years vs +10 Years Effect on ${meta.label} (Z = 0 -> 1)`;
      const yNames = selected.map((c) => `${c.country_name} (${c.iso3})`);

      const trace5 = {
        type: "scatter",
        mode: "markers",
        name: "+5 Years (80% CI)",
        y: yNames,
        x: selected.map((c) => c["tau5_" + outKey]),
        marker: { color: "#0b2545", size: 10, symbol: "circle" },
        error_x: {
          type: "data",
          symmetric: false,
          array: selected.map((c) =>
            c[`tau5_${outKey}_high80`] !== null ? c[`tau5_${outKey}_high80`] - c[`tau5_${outKey}`] : 0
          ),
          arrayminus: selected.map((c) =>
            c[`tau5_${outKey}_low80`] !== null ? c[`tau5_${outKey}`] - c[`tau5_${outKey}_low80`] : 0
          ),
          color: "#0b2545",
          thickness: 2.2,
          width: 5
        },
        hovertemplate: "<b>%{y}</b> (+5y): %{x:+.2f} pp<extra></extra>"
      };

      const trace10 = {
        type: "scatter",
        mode: "markers",
        name: "+10 Years (80% CI)",
        y: yNames,
        x: selected.map((c) => c["tau10_" + outKey]),
        marker: { color: "#136f63", size: 11, symbol: "diamond" },
        error_x: {
          type: "data",
          symmetric: false,
          array: selected.map((c) =>
            c[`tau10_${outKey}_high80`] !== null ? c[`tau10_${outKey}_high80`] - c[`tau10_${outKey}`] : 0
          ),
          arrayminus: selected.map((c) =>
            c[`tau10_${outKey}_low80`] !== null ? c[`tau10_${outKey}`] - c[`tau10_${outKey}_low80`] : 0
          ),
          color: "#136f63",
          thickness: 2.5,
          width: 5
        },
        hovertemplate: "<b>%{y}</b> (+10y): %{x:+.2f} pp<extra></extra>"
      };

      const layout = {
        margin: { t: 25, r: 30, b: 55, l: 165 },
        xaxis: {
          title: `Posterior Treatment Effect on ${meta.shortLabel} (pp)`,
          zeroline: true,
          zerolinecolor: "#64748b",
          zerolinewidth: 1.5,
          gridcolor: "#f1f5f9"
        },
        yaxis: { automargin: true },
        legend: { orientation: "h", y: 1.1, x: 0 },
        paper_bgcolor: "#ffffff",
        plot_bgcolor: "#ffffff"
      };

      Plotly.newPlot(plotDiv, [trace5, trace10], layout, {
        responsive: true,
        displayModeBar: false
      });
      return;
    }

    // Single horizon ("5" or "10") with both 95% and 80% CIs + Global ATE line
    const h = Number(t1State.horizon);
    const pref = h === 5 ? "tau5_" : "tau10_";
    const globalRow = getGlobalATE(h, outKey);

    titleEl.textContent = `+${h}-Year Posterior Treatment Effect on ${meta.label} (Z = 0 -> 1)`;

    const sorted = [...selected].sort(
      (a, b) => (a[pref + outKey] || -999) - (b[pref + outKey] || -999)
    );
    const yLabels = sorted.map((c) => `${c.country_name} (${c.iso3})`);

    // 95% CI thin bars
    const trace95 = {
      type: "scatter",
      mode: "markers",
      name: "95% Credible Interval",
      y: yLabels,
      x: sorted.map((c) => c[pref + outKey]),
      marker: { color: "rgba(0,0,0,0)", size: 1 },
      error_x: {
        type: "data",
        symmetric: false,
        array: sorted.map((c) =>
          c[`${pref}${outKey}_high95`] !== null ? c[`${pref}${outKey}_high95`] - c[pref + outKey] : 0
        ),
        arrayminus: sorted.map((c) =>
          c[`${pref}${outKey}_low95`] !== null ? c[pref + outKey] - c[`${pref}${outKey}_low95`] : 0
        ),
        color: "#94a3b8",
        thickness: 1.4,
        width: 0
      },
      hoverinfo: "skip"
    };

    // 80% CI thick bars + Posterior Mean point
    const trace80 = {
      type: "scatter",
      mode: "markers",
      name: "Posterior Mean & 80% CI",
      y: yLabels,
      x: sorted.map((c) => c[pref + outKey]),
      marker: { color: meta.colour, size: 11 },
      error_x: {
        type: "data",
        symmetric: false,
        array: sorted.map((c) =>
          c[`${pref}${outKey}_high80`] !== null ? c[`${pref}${outKey}_high80`] - c[pref + outKey] : 0
        ),
        arrayminus: sorted.map((c) =>
          c[`${pref}${outKey}_low80`] !== null ? c[pref + outKey] - c[`${pref}${outKey}_low80`] : 0
        ),
        color: meta.colour,
        thickness: 3.5,
        width: 6
      },
      customdata: sorted.map((c) => [
        fmtSigned(c[`${pref}${outKey}_low80`], 2),
        fmtSigned(c[`${pref}${outKey}_high80`], 2),
        fmtSigned(c[`${pref}${outKey}_low95`], 2),
        fmtSigned(c[`${pref}${outKey}_high95`], 2)
      ]),
      hovertemplate:
        "<b>%{y}</b><br>Posterior Mean: %{x:+.2f} pp<br>80% CI: [%{customdata[0]}, %{customdata[1]}] pp<br>95% CI: [%{customdata[2]}, %{customdata[3]}] pp<extra></extra>"
    };

    const shapes = [
      {
        type: "line",
        x0: 0,
        x1: 0,
        y0: -0.5,
        y1: Math.max(0.5, yLabels.length - 0.5),
        line: { color: "#64748b", width: 1.5, dash: "dot" }
      }
    ];

    const annotations = [];
    if (globalRow) {
      shapes.push({
        type: "line",
        x0: globalRow.ate_mean,
        x1: globalRow.ate_mean,
        y0: -0.5,
        y1: Math.max(0.5, yLabels.length - 0.5),
        line: { color: "#be123c", width: 2, dash: "dash" }
      });
      annotations.push({
        x: globalRow.ate_mean,
        y: 1.04,
        xref: "x",
        yref: "paper",
        text: `Global ATE: ${fmtSigned(globalRow.ate_mean, 2)} pp`,
        showarrow: false,
        font: { size: 11, color: "#be123c", weight: "bold" }
      });
    }

    const layout = {
      margin: { t: 32, r: 30, b: 55, l: 165 },
      xaxis: {
        title: `Estimated Effect on ${meta.shortLabel} (percentage points, pp)`,
        gridcolor: "#f1f5f9",
        zeroline: false
      },
      yaxis: { automargin: true },
      shapes: shapes,
      annotations: annotations,
      legend: { orientation: "h", y: 1.12, x: 0 },
      paper_bgcolor: "#ffffff",
      plot_bgcolor: "#ffffff"
    };

    Plotly.newPlot(plotDiv, [trace95, trace80], layout, {
      responsive: true,
      displayModeBar: false
    });
  }

  function renderTab1TrajectoryPlot(selected, outKey) {
    const plotDiv = document.getElementById("t1-trajectory-plot");
    const meta = OUTCOME_META[outKey];
    const longRow = getLongATE(outKey);

    const traces = [];
    const xWaves = ["Baseline (Year 0)", "+5 Years (Wave 1)", "+10 Years (Wave 2)"];

    // Global LBCF trajectory with 80% ribbon
    if (longRow) {
      traces.push({
        type: "scatter",
        mode: "lines",
        name: "Global LBCF 80% CI Band",
        x: [...xWaves, ...[...xWaves].reverse()],
        y: [
          0,
          longRow.ate_5y_high80,
          longRow.ate_cum_10y_high80,
          longRow.ate_cum_10y_low80,
          longRow.ate_5y_low80,
          0
        ],
        fill: "toself",
        fillcolor: "rgba(190, 18, 60, 0.11)",
        line: { color: "rgba(190, 18, 60, 0.25)", width: 1 },
        hoverinfo: "skip",
        showlegend: true
      });

      traces.push({
        type: "scatter",
        mode: "lines+markers",
        name: "Global LBCF Mean Trajectory",
        x: xWaves,
        y: [0, longRow.ate_5y_mean, longRow.ate_cum_10y_mean],
        line: { color: "#be123c", width: 3, dash: "dash" },
        marker: { size: 9, color: "#be123c" },
        hovertemplate: "<b>Global LBCF ATE</b><br>%{x}: %{y:+.2f} pp<extra></extra>"
      });
    }

    const palette = ["#0b2545", "#136f63", "#2563eb", "#d97706", "#7c3aed", "#059669", "#dc2626"];

    selected.slice(0, 8).forEach((c, idx) => {
      const y1 =
        c["lbcf_w1_" + outKey] !== null && c["lbcf_w1_" + outKey] !== undefined
          ? c["lbcf_w1_" + outKey]
          : c["tau5_" + outKey];
      const y2 =
        c["lbcf_cum_" + outKey] !== null && c["lbcf_cum_" + outKey] !== undefined
          ? c["lbcf_cum_" + outKey]
          : c["tau10_" + outKey];

      if (y1 === null && y2 === null) return;

      traces.push({
        type: "scatter",
        mode: "lines+markers",
        name: `${c.country_name} (${c.iso3})`,
        x: xWaves,
        y: [0, y1, y2],
        line: { color: palette[idx % palette.length], width: 2.3 },
        marker: { size: 8 },
        hovertemplate: `<b>${c.country_name}</b><br>%{x}: %{y:+.2f} pp<extra></extra>`
      });
    });

    const layout = {
      margin: { t: 25, r: 25, b: 45, l: 65 },
      yaxis: {
        title: `Cumulative Effect on ${meta.shortLabel} (pp)`,
        zeroline: true,
        zerolinecolor: "#94a3b8",
        gridcolor: "#f1f5f9"
      },
      xaxis: { title: "" },
      legend: { orientation: "h", y: 1.15, x: 0 },
      paper_bgcolor: "#ffffff",
      plot_bgcolor: "#ffffff"
    };

    Plotly.newPlot(plotDiv, traces, layout, { responsive: true, displayModeBar: false });
  }

  function renderTab1Table(selected, outKey) {
    const tbody = document.querySelector("#t1-summary-table tbody");
    const meta = OUTCOME_META[outKey];
    tbody.innerHTML = "";

    selected.forEach((c) => {
      const tr = document.createElement("tr");
      const v5 = c[`tau5_${outKey}`];
      const v10 = c[`tau10_${outKey}`];
      const vCum = c[`lbcf_cum_${outKey}`];
      const baseVal = c[meta.baseCol];

      tr.innerHTML = `
        <td><strong>${c.country_name}</strong> (${c.iso3})</td>
        <td>${c.region} <span class="country-tag">${c.is_oecd ? "OECD" : c.income_group}</span></td>
        <td>${v5 !== null ? `<strong>${fmtSigned(v5, 2)} pp</strong> [${fmtSigned(c[`tau5_${outKey}_low80`], 2)}, ${fmtSigned(c[`tau5_${outKey}_high80`], 2)}]` : "N/A"}</td>
        <td>${v10 !== null ? `<strong>${fmtSigned(v10, 2)} pp</strong> [${fmtSigned(c[`tau10_${outKey}_low80`], 2)}, ${fmtSigned(c[`tau10_${outKey}_high80`], 2)}]` : "N/A"}</td>
        <td>${vCum !== null ? `<strong>${fmtSigned(vCum, 2)} pp</strong> [${fmtSigned(c[`lbcf_cum_${outKey}_low80`], 2)}, ${fmtSigned(c[`lbcf_cum_${outKey}_high80`], 2)}]` : "N/A"}</td>
        <td>${baseVal !== null ? `${fmtNum(baseVal, 1)} ${meta.baseUnit}` : "N/A"}</td>
      `;
      tbody.appendChild(tr);
    });
  }

  // ===========================================================================
  // TAB 2: Historical Gapminder-Style Animated Trajectory Explorer
  // ===========================================================================
  const t2State = {
    mode: "changes", // "changes" or "levels"
    xVar: "tert_spend_abs_change",
    yVar: "d_prev_inc_tax_share_pp",
    wave: 8,
    playing: false,
    timer: null,
    selectedIsos: ["IRL", "GBR", "SWE", "KOR"],
    searchQuery: ""
  };

  const t2VarLabels = {
    tert_spend_abs_change: "5-Year Change in Tertiary Spend per Student (% GDP/cap)",
    d_log_real_spend_stu_pct: "5-Year Growth in Real PPP Spend per Student (%)",
    d_tert_spend_gdp_pp: "5-Year Change in Tertiary Budget Share (pp of GDP)",
    tert_spend_per_student_winsor: "Tertiary Spend per Student (% of GDP per capita)",
    real_tert_spend_per_student_ppp: "Real Tertiary Spend per Student (2021 PPP $)",
    tert_spend_gdp_pct: "Government Tertiary Spending (% of GDP)",
    d_prev_inc_tax_share_pp: "5-Year Change in Income & Profit Tax Share (pp)",
    d_prev_inc_tax_gdp_pp: "5-Year Change in Income & Profit Tax / GDP (pp)",
    d_prev_nonres_tax_gdp_pp: "5-Year Change in Non-Resource Tax / GDP (pp)",
    d_t2_inc_tax_share_pp: "10-Year Forward Change in Income Tax Share (pp)",
    income_profit_tax_share_rev_pct: "Income & Profit Tax Share (% of Revenue)",
    inc_tax_gdp_pct: "Income & Profit Tax Revenue (% of GDP)",
    non_resource_tax_gdp_pct: "Total Non-Resource Tax Revenue (% of GDP)"
  };

  const t2Presets = {
    default: ["IRL", "GBR", "SWE", "KOR"],
    oecd: ["IRL", "GBR", "SWE", "USA", "DEU", "AUS"],
    latam: ["CHL", "BRA", "COL", "KOR", "THA", "MYS"],
    clear: []
  };

  function buildTab2CountryList() {
    const box = document.getElementById("t2-country-list");
    const q = t2State.searchQuery.trim().toLowerCase();
    box.innerHTML = "";

    const filtered = COUNTRIES.filter((c) => {
      if (!q) return true;
      return (
        c.country_name.toLowerCase().includes(q) ||
        c.iso3.toLowerCase().includes(q)
      );
    });

    filtered.forEach((c) => {
      const div = document.createElement("div");
      div.className = "country-item";
      const checked = t2State.selectedIsos.includes(c.iso3);
      div.innerHTML = `
        <label>
          <input type="checkbox" value="${c.iso3}" ${checked ? "checked" : ""} />
          <span>${c.country_name}</span>
        </label>
        <span class="country-tag">${c.iso3}</span>
      `;
      const cb = div.querySelector("input");
      cb.addEventListener("change", () => {
        if (cb.checked) {
          if (!t2State.selectedIsos.includes(c.iso3)) {
            t2State.selectedIsos.push(c.iso3);
          }
        } else {
          t2State.selectedIsos = t2State.selectedIsos.filter((x) => x !== c.iso3);
        }
        document.getElementById("t2-selected-count").textContent =
          `${t2State.selectedIsos.length} traced`;
        renderTab2();
      });
      box.appendChild(div);
    });

    document.getElementById("t2-selected-count").textContent =
      `${t2State.selectedIsos.length} traced`;
  }

  function initTab2Controls() {
    const xSel = document.getElementById("t2-x-select");
    const ySel = document.getElementById("t2-y-select");

    document.querySelectorAll("#t2-mode-group .seg-btn").forEach((btn) => {
      btn.addEventListener("click", () => {
        document
          .querySelectorAll("#t2-mode-group .seg-btn")
          .forEach((b) => b.classList.toggle("active", b === btn));
        t2State.mode = btn.getAttribute("data-mode");
        if (t2State.mode === "changes") {
          xSel.value = "tert_spend_abs_change";
          ySel.value = "d_prev_inc_tax_share_pp";
          if (t2State.wave === 1) {
            t2State.wave = 8;
            document.getElementById("t2-wave-slider").value = "8";
          }
        } else {
          xSel.value = "tert_spend_per_student_winsor";
          ySel.value = "income_profit_tax_share_rev_pct";
        }
        t2State.xVar = xSel.value;
        t2State.yVar = ySel.value;
        renderTab2();
      });
    });

    xSel.addEventListener("change", () => {
      t2State.xVar = xSel.value;
      renderTab2();
    });

    ySel.addEventListener("change", () => {
      t2State.yVar = ySel.value;
      renderTab2();
    });

    // Wave slider
    const slider = document.getElementById("t2-wave-slider");
    slider.addEventListener("input", () => {
      t2State.wave = Number(slider.value);
      document.getElementById("t2-wave-badge").textContent = WAVE_LABELS[t2State.wave];
      renderTab2();
    });

    // Play / Pause animation button
    const playBtn = document.getElementById("t2-play-btn");
    playBtn.addEventListener("click", () => {
      if (t2State.playing) {
        stopTab2Animation();
      } else {
        startTab2Animation();
      }
    });

    // Presets
    document.querySelectorAll("[data-t2preset]").forEach((btn) => {
      btn.addEventListener("click", () => {
        const key = btn.getAttribute("data-t2preset");
        if (t2Presets[key]) {
          t2State.selectedIsos = t2Presets[key].filter((iso) => COUNTRY_MAP[iso]);
          buildTab2CountryList();
          renderTab2();
        }
      });
    });

    // Search
    const searchInput = document.getElementById("t2-country-search");
    searchInput.addEventListener("input", () => {
      t2State.searchQuery = searchInput.value;
      buildTab2CountryList();
    });

    buildTab2CountryList();
  }

  function startTab2Animation() {
    const playBtn = document.getElementById("t2-play-btn");
    const slider = document.getElementById("t2-wave-slider");
    t2State.playing = true;
    playBtn.innerHTML = "&#10074;&#10074; Pause";

    // Start at wave 2 for changes (since wave 1 has no prior wave change) or wave 1 for levels
    const minStartWave = t2State.xVar.startsWith("d_") || t2State.xVar.includes("change") ? 2 : 1;
    if (t2State.wave >= 8 || t2State.wave < minStartWave) {
      t2State.wave = minStartWave;
      slider.value = String(t2State.wave);
      renderTab2();
    }

    t2State.timer = setInterval(() => {
      if (t2State.wave < 8) {
        t2State.wave += 1;
        slider.value = String(t2State.wave);
        renderTab2();
      } else {
        stopTab2Animation();
      }
    }, 1150);
  }

  function stopTab2Animation() {
    const playBtn = document.getElementById("t2-play-btn");
    t2State.playing = false;
    playBtn.innerHTML = "&#9654; Play Waves";
    if (t2State.timer) {
      clearInterval(t2State.timer);
      t2State.timer = null;
    }
  }

  function renderTab2() {
    document.getElementById("t2-wave-badge").textContent = WAVE_LABELS[t2State.wave];
    renderTab2GapminderPlot();
    renderTab2TimeSeriesPlot();
  }

  function renderTab2GapminderPlot() {
    const plotDiv = document.getElementById("t2-gapminder-plot");
    const xCol = t2State.xVar;
    const yCol = t2State.yVar;
    const activeWave = t2State.wave;

    // Compute fixed global axis bounds across all waves so animation is stable
    const allValid = HISTORICAL.filter(
      (r) =>
        r[xCol] !== null &&
        r[xCol] !== undefined &&
        r[yCol] !== null &&
        r[yCol] !== undefined &&
        Number.isFinite(Number(r[xCol])) &&
        Number.isFinite(Number(r[yCol]))
    );

    const xVals = allValid.map((r) => Number(r[xCol])).sort((a, b) => a - b);
    const yVals = allValid.map((r) => Number(r[yCol])).sort((a, b) => a - b);

    const q = (arr, p) =>
      arr.length ? arr[Math.max(0, Math.min(arr.length - 1, Math.floor(p * arr.length)))] : 0;

    const xMin = q(xVals, 0.015);
    const xMax = q(xVals, 0.985);
    const yMin = q(yVals, 0.015);
    const yMax = q(yVals, 0.985);
    const xPad = (xMax - xMin) * 0.1 || 5;
    const yPad = (yMax - yMin) * 0.1 || 5;

    // Filter rows for active wave
    const waveRows = allValid.filter((r) => Number(r.wave_index) === activeWave);

    // Group by region for background scatter bubbles
    const regions = [...new Set(COUNTRIES.map((c) => c.region).filter(Boolean))];
    const traces = [];

    regions.forEach((reg) => {
      const sub = waveRows.filter((r) => r.region === reg);
      if (!sub.length) return;
      traces.push({
        type: "scatter",
        mode: "markers",
        name: reg,
        x: sub.map((r) => r[xCol]),
        y: sub.map((r) => r[yCol]),
        text: sub.map((r) => `${r.country_name} (${r.iso3}) - ${r.wave_label}`),
        marker: {
          color: REGION_COLOURS[reg] || "#475569",
          opacity: t2State.selectedIsos.length > 0 ? 0.42 : 0.78,
          size: sub.map((r) => {
            const pop = Number(r.population_total) || 5e6;
            return Math.max(8, Math.min(34, Math.sqrt(pop / 1e6) * 2.2));
          }),
          line: { color: "#ffffff", width: 1 }
        },
        hovertemplate:
          "<b>%{text}</b><br>" +
          `${t2VarLabels[xCol]}: %{x:.2f}<br>` +
          `${t2VarLabels[yCol]}: %{y:.2f}<extra></extra>`
      });
    });

    // Historical trails for selected countries up to activeWave
    const trailPalette = ["#be123c", "#0b2545", "#136f63", "#d97706", "#2563eb", "#7c3aed"];
    t2State.selectedIsos.forEach((iso, idx) => {
      const cRows = allValid
        .filter((r) => r.iso3 === iso && Number(r.wave_index) <= activeWave)
        .sort((a, b) => Number(a.wave_index) - Number(b.wave_index));

      if (!cRows.length) return;
      const col = trailPalette[idx % trailPalette.length];
      const cName = cRows[0].country_name;

      traces.push({
        type: "scatter",
        mode: "lines+markers+text",
        name: `${cName} (${iso}) Path`,
        x: cRows.map((r) => r[xCol]),
        y: cRows.map((r) => r[yCol]),
        text: cRows.map((r, i) => (i === cRows.length - 1 ? `${iso} (${r.wave_label})` : "")),
        textposition: "top center",
        textfont: { size: 11, color: col, weight: "bold" },
        line: { color: col, width: 2.8 },
        marker: {
          color: col,
          size: cRows.map((_, i) => (i === cRows.length - 1 ? 13 : 7)),
          symbol: cRows.map((_, i) => (i === cRows.length - 1 ? "diamond" : "circle")),
          line: { color: "#ffffff", width: 1.5 }
        },
        customdata: cRows.map((r) => r.wave_label),
        hovertemplate:
          `<b>${cName} (${iso}) - %{customdata}</b><br>` +
          `Spend: %{x:.2f}<br>Tax: %{y:.2f}<extra></extra>`
      });
    });

    const layout = {
      margin: { t: 25, r: 25, b: 55, l: 65 },
      xaxis: {
        title: t2VarLabels[xCol] || xCol,
        range: [xMin - xPad, xMax + xPad],
        zeroline: true,
        zerolinecolor: "#94a3b8",
        gridcolor: "#f1f5f9"
      },
      yaxis: {
        title: t2VarLabels[yCol] || yCol,
        range: [yMin - yPad, yMax + yPad],
        zeroline: true,
        zerolinecolor: "#94a3b8",
        gridcolor: "#f1f5f9"
      },
      annotations: [
        {
          x: 0.98,
          y: 0.06,
          xref: "paper",
          yref: "paper",
          text: WAVE_LABELS[activeWave],
          showarrow: false,
          font: { size: 32, color: "rgba(15, 23, 42, 0.14)", weight: "bold" }
        }
      ],
      legend: { orientation: "h", y: 1.12, x: 0 },
      paper_bgcolor: "#ffffff",
      plot_bgcolor: "#ffffff"
    };

    Plotly.newPlot(plotDiv, traces, layout, { responsive: true, displayModeBar: false });
  }

  function renderTab2TimeSeriesPlot() {
    const plotDiv = document.getElementById("t2-timeseries-plot");
    const xCol = t2State.xVar;
    const yCol = t2State.yVar;
    const isos = t2State.selectedIsos.length ? t2State.selectedIsos : ["IRL", "GBR", "SWE"];
    const palette = ["#be123c", "#0b2545", "#136f63", "#d97706", "#2563eb", "#7c3aed"];

    const traces = [];

    isos.forEach((iso, idx) => {
      const cRows = HISTORICAL.filter((r) => r.iso3 === iso).sort(
        (a, b) => Number(a.wave_index) - Number(b.wave_index)
      );
      if (!cRows.length) return;
      const col = palette[idx % palette.length];
      const name = cRows[0].country_name;

      // Left panel: spending indicator over time
      traces.push({
        type: "scatter",
        mode: "lines+markers",
        name: `${name} (${iso})`,
        legendgroup: iso,
        x: cRows.map((r) => r.wave_label),
        y: cRows.map((r) => r[xCol]),
        xaxis: "x",
        yaxis: "y",
        line: { color: col, width: 2.3 },
        marker: { size: 7, color: col },
        hovertemplate: `<b>${name}</b> (%{x})<br>Spending: %{y:.2f}<extra></extra>`
      });

      // Right panel: tax indicator over time
      traces.push({
        type: "scatter",
        mode: "lines+markers",
        name: `${name} (${iso})`,
        legendgroup: iso,
        showlegend: false,
        x: cRows.map((r) => r.wave_label),
        y: cRows.map((r) => r[yCol]),
        xaxis: "x2",
        yaxis: "y2",
        line: { color: col, width: 2.3, dash: "solid" },
        marker: { size: 7, color: col, symbol: "diamond" },
        hovertemplate: `<b>${name}</b> (%{x})<br>Tax: %{y:.2f}<extra></extra>`
      });
    });

    const layout = {
      grid: { rows: 1, columns: 2, pattern: "independent" },
      margin: { t: 32, r: 25, b: 55, l: 60 },
      xaxis: { title: "Five-Year Wave (Spending Indicator)" },
      yaxis: {
        title: t2VarLabels[xCol] || "Spending",
        gridcolor: "#f1f5f9",
        zeroline: true,
        zerolinecolor: "#cbd5e1"
      },
      xaxis2: { title: "Five-Year Wave (Tax Indicator)" },
      yaxis2: {
        title: t2VarLabels[yCol] || "Tax Revenue",
        gridcolor: "#f1f5f9",
        zeroline: true,
        zerolinecolor: "#cbd5e1"
      },
      legend: { orientation: "h", y: 1.15, x: 0 },
      paper_bgcolor: "#ffffff",
      plot_bgcolor: "#ffffff"
    };

    Plotly.newPlot(plotDiv, traces, layout, { responsive: true, displayModeBar: false });
  }

  // ===========================================================================
  // TAB 3: Counterfactual Policy & Moderator Scenario Simulator (CATE)
  // ===========================================================================
  const t3State = {
    iso3: "IRL",
    direction: 1, // +1 for Z: 0 -> 1, -1 for Z: 1 -> 0
    horizon: 10,  // 5 or 10
    drawerOpen: false,
    moderators: {},
    baselineModerators: {}
  };

  const MODERATOR_SPECS = [
    {
      id: "gross_tert_enrolment_pct",
      countryField: "gross_tert_enrolment_pct",
      label: "Gross Tertiary Enrolment (%)",
      fmt: (v) => `${Number(v).toFixed(1)}%`
    },
    {
      id: "gdp_pc_ppp",
      countryField: "gdp_per_capita_ppp",
      label: "Real GDP per Capita (2021 PPP $)",
      fmt: (v) => `$${Math.round(Number(v)).toLocaleString("en-GB")}`
    },
    {
      id: "gross_seco_enrolment_pct",
      countryField: "gross_seco_enrolment_pct",
      label: "Gross Secondary Enrolment (%)",
      fmt: (v) => `${Number(v).toFixed(1)}%`
    },
    {
      id: "income_profit_tax_share_rev_pct",
      countryField: "inc_tax_share_pct",
      label: "Baseline Income Tax Share (% rev)",
      fmt: (v) => `${Number(v).toFixed(1)}%`
    },
    {
      id: "working_age_pop_15_64_pct",
      countryField: "working_age_pop_pct",
      label: "Working-Age Population 15-64 (%)",
      fmt: (v) => `${Number(v).toFixed(1)}%`
    },
    {
      id: "gini_disp_harmonised",
      countryField: "gini_disp",
      label: "Disposable Income Gini Index",
      fmt: (v) => `${Number(v).toFixed(1)}`
    },
    {
      id: "life_expectancy_birth_yrs",
      countryField: "life_expectancy_yrs",
      label: "Life Expectancy at Birth (Years)",
      fmt: (v) => `${Number(v).toFixed(1)} yrs`
    }
  ];

  function loadCountryDefaultsIntoTab3(iso3) {
    const c = COUNTRY_MAP[iso3] || COUNTRIES[0];
    const defaults = SURROGATES.sample_defaults || {};

    MODERATOR_SPECS.forEach((spec) => {
      let val = c ? c[spec.countryField] : null;
      if (val === null || val === undefined || !Number.isFinite(Number(val))) {
        if (spec.id === "gdp_pc_ppp") {
          val = Math.exp(Number(defaults.log_gdp_pc_ppp || 9.8));
        } else {
          val = Number(defaults[spec.id] || 50);
        }
      }
      t3State.baselineModerators[spec.id] = Number(val);
      t3State.moderators[spec.id] = Number(val);

      const inputEl = document.getElementById(`mod-${spec.id}`);
      const valEl = document.getElementById(`val-${spec.id}`);
      if (inputEl) inputEl.value = String(val);
      if (valEl) valEl.textContent = spec.fmt(val);
    });
  }

  function initTab3Controls() {
    const cSel = document.getElementById("t3-country-select");
    cSel.innerHTML = "";
    COUNTRIES.forEach((c) => {
      const opt = document.createElement("option");
      opt.value = c.iso3;
      opt.textContent = `${c.country_name} (${c.iso3})`;
      if (c.iso3 === t3State.iso3) opt.selected = true;
      cSel.appendChild(opt);
    });

    cSel.addEventListener("change", () => {
      t3State.iso3 = cSel.value;
      loadCountryDefaultsIntoTab3(t3State.iso3);
      renderTab3();
    });

    // Direction toggle
    document.querySelectorAll("#t3-direction-group .seg-btn").forEach((btn) => {
      btn.addEventListener("click", () => {
        document
          .querySelectorAll("#t3-direction-group .seg-btn")
          .forEach((b) => b.classList.toggle("active", b === btn));
        t3State.direction = Number(btn.getAttribute("data-dir"));
        renderTab3();
      });
    });

    // Horizon toggle
    document.querySelectorAll("#t3-horizon-group .seg-btn").forEach((btn) => {
      btn.addEventListener("click", () => {
        document
          .querySelectorAll("#t3-horizon-group .seg-btn")
          .forEach((b) => b.classList.toggle("active", b === btn));
        t3State.horizon = Number(btn.getAttribute("data-h"));
        renderTab3();
      });
    });

    // Collapsible moderator drawer
    const drawerBtn = document.getElementById("t3-drawer-toggle");
    const drawerBody = document.getElementById("t3-drawer-body");
    const drawerArrow = document.getElementById("t3-drawer-arrow");

    drawerBtn.addEventListener("click", () => {
      t3State.drawerOpen = !t3State.drawerOpen;
      drawerBody.classList.toggle("open", t3State.drawerOpen);
      drawerBtn.setAttribute("aria-expanded", String(t3State.drawerOpen));
      drawerArrow.innerHTML = t3State.drawerOpen ? "&#9652; Hide" : "&#9662; Show";
    });

    // Moderator sliders
    MODERATOR_SPECS.forEach((spec) => {
      const inputEl = document.getElementById(`mod-${spec.id}`);
      const valEl = document.getElementById(`val-${spec.id}`);
      if (!inputEl) return;
      inputEl.addEventListener("input", () => {
        const v = Number(inputEl.value);
        t3State.moderators[spec.id] = v;
        if (valEl) valEl.textContent = spec.fmt(v);
        renderTab3();
      });
    });

    // Reset button
    document.getElementById("t3-reset-btn").addEventListener("click", () => {
      loadCountryDefaultsIntoTab3(t3State.iso3);
      renderTab3();
    });

    loadCountryDefaultsIntoTab3(t3State.iso3);
  }

  // Evaluate CATE shift from moderator deltas anchored on the country's posterior CATE
  function evaluateScenarioForOutcome(c, outKey) {
    const hKey = t3State.horizon === 5 ? "h5" : "h10";
    const pref = t3State.horizon === 5 ? "tau5_" : "tau10_";
    const sur = SURROGATES[hKey] && SURROGATES[hKey][outKey];
    const coefs = (sur && sur.coefs) || {};
    const dir = t3State.direction;

    // Country baseline CATE (or surrogate fallback if country is missing that horizon)
    let baseMean = c[pref + outKey];
    const baseMods = t3State.baselineModerators;
    const curMods = t3State.moderators;

    const baseLogGdp = Math.log(Math.max(500, baseMods.gdp_pc_ppp || 15000));
    const curLogGdp = Math.log(Math.max(500, curMods.gdp_pc_ppp || 15000));

    if (baseMean === null || baseMean === undefined || !Number.isFinite(Number(baseMean))) {
      baseMean =
        Number(coefs["(Intercept)"] || 0) +
        Number(coefs.gross_tert_enrolment_pct || 0) * baseMods.gross_tert_enrolment_pct +
        Number(coefs.log_gdp_pc_ppp || 0) * baseLogGdp +
        Number(coefs.gross_seco_enrolment_pct || 0) * baseMods.gross_seco_enrolment_pct +
        Number(coefs.income_profit_tax_share_rev_pct || 0) * baseMods.income_profit_tax_share_rev_pct +
        Number(coefs.working_age_pop_15_64_pct || 0) * baseMods.working_age_pop_15_64_pct +
        Number(coefs.gini_disp_harmonised || 0) * baseMods.gini_disp_harmonised +
        Number(coefs.life_expectancy_birth_yrs || 0) * baseMods.life_expectancy_birth_yrs;
    }

    // Moderator shift contributions
    const contrib = {
      "Gross Tertiary Enrolment":
        Number(coefs.gross_tert_enrolment_pct || 0) *
        (curMods.gross_tert_enrolment_pct - baseMods.gross_tert_enrolment_pct),
      "Real GDP per Capita (log PPP)":
        Number(coefs.log_gdp_pc_ppp || 0) * (curLogGdp - baseLogGdp),
      "Gross Secondary Enrolment":
        Number(coefs.gross_seco_enrolment_pct || 0) *
        (curMods.gross_seco_enrolment_pct - baseMods.gross_seco_enrolment_pct),
      "Baseline Income Tax Share":
        Number(coefs.income_profit_tax_share_rev_pct || 0) *
        (curMods.income_profit_tax_share_rev_pct - baseMods.income_profit_tax_share_rev_pct),
      "Working-Age Population %":
        Number(coefs.working_age_pop_15_64_pct || 0) *
        (curMods.working_age_pop_15_64_pct - baseMods.working_age_pop_15_64_pct),
      "Disposable Income Gini":
        Number(coefs.gini_disp_harmonised || 0) *
        (curMods.gini_disp_harmonised - baseMods.gini_disp_harmonised),
      "Life Expectancy at Birth":
        Number(coefs.life_expectancy_birth_yrs || 0) *
        (curMods.life_expectancy_birth_yrs - baseMods.life_expectancy_birth_yrs)
    };

    const deltaMod = Object.values(contrib).reduce((a, b) => a + b, 0);
    const halfWidth80 =
      c[`${pref}${outKey}_high80`] !== null && c[`${pref}${outKey}_low80`] !== null
        ? (c[`${pref}${outKey}_high80`] - c[`${pref}${outKey}_low80`]) / 2
        : 1.28 * Number((sur && sur.mean_sd) || 0.5);

    const simMean = dir * (baseMean + deltaMod);
    const directedBase = dir * baseMean;

    return {
      baseMean: directedBase,
      simMean: simMean,
      halfWidth80: halfWidth80,
      contrib: contrib
    };
  }

  function renderTab3() {
    const c = COUNTRY_MAP[t3State.iso3] || COUNTRIES[0];
    const dirLabel =
      t3State.direction === 1 ? "Increase Spend (Z: 0 -> 1)" : "Reduce Spend (Z: 1 -> 0)";

    const resIncShare = evaluateScenarioForOutcome(c, "inc_share");
    const resIncGdp = evaluateScenarioForOutcome(c, "inc_gdp");
    const resTaxGdp = evaluateScenarioForOutcome(c, "tax_gdp");
    const resGoods = evaluateScenarioForOutcome(c, "goods_share");

    // KPI row
    const kpiRow = document.getElementById("t3-kpi-row");
    kpiRow.innerHTML = `
      <div class="kpi-card">
        <div class="kpi-title">${c.country_name}: Simulated Income Tax Share (+${t3State.horizon}y)</div>
        <div class="kpi-val">${fmtSigned(resIncShare.simMean, 2)} pp</div>
        <div class="kpi-sub">Baseline CATE: ${fmtSigned(resIncShare.baseMean, 2)} pp | 80% CI: &plusmn;${fmtNum(resIncShare.halfWidth80, 2)} pp</div>
      </div>
      <div class="kpi-card secondary">
        <div class="kpi-title">${c.country_name}: Simulated Income Tax / GDP (+${t3State.horizon}y)</div>
        <div class="kpi-val">${fmtSigned(resIncGdp.simMean, 2)} pp</div>
        <div class="kpi-sub">Baseline CATE: ${fmtSigned(resIncGdp.baseMean, 2)} pp | 80% CI: &plusmn;${fmtNum(resIncGdp.halfWidth80, 2)} pp</div>
      </div>
      <div class="kpi-card neutral">
        <div class="kpi-title">${c.country_name}: Total Non-Resource Tax / GDP (+${t3State.horizon}y)</div>
        <div class="kpi-val">${fmtSigned(resTaxGdp.simMean, 2)} pp</div>
        <div class="kpi-sub">Baseline CATE: ${fmtSigned(resTaxGdp.baseMean, 2)} pp | Policy: ${dirLabel}</div>
      </div>
    `;

    // Main Scenario Comparison Plot across all 4 tax channels
    const scenarioDiv = document.getElementById("t3-scenario-plot");
    document.getElementById("t3-chart-title").textContent =
      `${c.country_name} (${c.iso3}): Baseline Country CATE vs Custom Scenario (+${t3State.horizon} Years, ${dirLabel})`;

    const xCats = [
      "Income Tax Share\n(% of Revenue)",
      "Income Tax\n(% of GDP)",
      "Non-Resource Tax\n(% of GDP)",
      "Goods & Services Share\n(% of Revenue)"
    ];
    const allRes = [resIncShare, resIncGdp, resTaxGdp, resGoods];

    const traceBase = {
      type: "bar",
      name: `${c.country_name} Baseline Averages`,
      x: xCats,
      y: allRes.map((r) => r.baseMean),
      marker: { color: "#0b2545" },
      error_y: {
        type: "data",
        array: allRes.map((r) => r.halfWidth80),
        color: "#334155",
        thickness: 1.8,
        width: 5
      },
      hovertemplate: "<b>%{x}</b><br>Baseline CATE: %{y:+.2f} pp<extra></extra>"
    };

    const traceSim = {
      type: "bar",
      name: "Simulated Custom Scenario",
      x: xCats,
      y: allRes.map((r) => r.simMean),
      marker: { color: "#136f63" },
      error_y: {
        type: "data",
        array: allRes.map((r) => r.halfWidth80),
        color: "#0f766e",
        thickness: 1.8,
        width: 5
      },
      hovertemplate: "<b>%{x}</b><br>Simulated CATE: %{y:+.2f} pp<extra></extra>"
    };

    const layoutScenario = {
      barmode: "group",
      margin: { t: 25, r: 25, b: 60, l: 65 },
      yaxis: {
        title: "Predicted Effect on Tax Indicator (percentage points, pp)",
        zeroline: true,
        zerolinecolor: "#64748b",
        zerolinewidth: 1.5,
        gridcolor: "#f1f5f9"
      },
      legend: { orientation: "h", y: 1.12, x: 0 },
      paper_bgcolor: "#ffffff",
      plot_bgcolor: "#ffffff"
    };

    Plotly.newPlot(scenarioDiv, [traceBase, traceSim], layoutScenario, {
      responsive: true,
      displayModeBar: false
    });

    // Sensitivity / Moderator Tornado Plot
    renderTab3SensitivityPlot(c, resIncShare);
  }

  function renderTab3SensitivityPlot(c, resIncShare) {
    const sensDiv = document.getElementById("t3-sensitivity-plot");
    const hKey = t3State.horizon === 5 ? "h5" : "h10";
    const coefs = (SURROGATES[hKey] && SURROGATES[hKey].inc_share.coefs) || {};
    const sds = SURROGATES.sample_sds || {};
    const dir = t3State.direction;

    // Check if user moved any slider away from baseline
    const userDeltas = Object.entries(resIncShare.contrib).map(([k, v]) => ({
      name: k,
      val: dir * v
    }));
    const maxDelta = Math.max(...userDeltas.map((d) => Math.abs(d.val)));

    // If sliders are at default (0 shift), show +1 SD standardised marginal effect on Income Tax Share CATE
    const showingCustom = maxDelta > 0.002;
    const bars = showingCustom
      ? userDeltas
      : [
          {
            name: "Gross Tertiary Enrolment (+1 SD)",
            val: dir * Number(coefs.gross_tert_enrolment_pct || 0) * Number(sds.gross_tert_enrolment_pct || 25)
          },
          {
            name: "Real GDP per Capita (+1 SD log)",
            val: dir * Number(coefs.log_gdp_pc_ppp || 0) * Number(sds.log_gdp_pc_ppp || 0.9)
          },
          {
            name: "Gross Secondary Enrolment (+1 SD)",
            val: dir * Number(coefs.gross_seco_enrolment_pct || 0) * Number(sds.gross_seco_enrolment_pct || 22)
          },
          {
            name: "Baseline Income Tax Share (+1 SD)",
            val:
              dir *
              Number(coefs.income_profit_tax_share_rev_pct || 0) *
              Number(sds.income_profit_tax_share_rev_pct || 12)
          },
          {
            name: "Working-Age Population (+1 SD)",
            val:
              dir *
              Number(coefs.working_age_pop_15_64_pct || 0) *
              Number(sds.working_age_pop_15_64_pct || 5)
          },
          {
            name: "Disposable Income Gini (+1 SD)",
            val: dir * Number(coefs.gini_disp_harmonised || 0) * Number(sds.gini_disp_harmonised || 8)
          },
          {
            name: "Life Expectancy at Birth (+1 SD)",
            val:
              dir *
              Number(coefs.life_expectancy_birth_yrs || 0) *
              Number(sds.life_expectancy_birth_yrs || 6)
          }
        ];

    bars.sort((a, b) => a.val - b.val);

    const trace = {
      type: "bar",
      orientation: "h",
      y: bars.map((b) => b.name),
      x: bars.map((b) => b.val),
      marker: {
        color: bars.map((b) => (b.val >= 0 ? "#136f63" : "#be123c"))
      },
      hovertemplate: "<b>%{y}</b>: %{x:+.3f} pp shift in CATE<extra></extra>"
    };

    const layout = {
      title: {
        text: showingCustom
          ? "Custom Slider Adjustments: Contribution to Income Tax Share CATE (pp)"
          : "Standardised Sensitivity (+1 SD Increase in Each Moderator on Income Tax Share CATE, pp)",
        font: { size: 12, color: "#0b2545" }
      },
      margin: { t: 38, r: 30, b: 45, l: 215 },
      xaxis: {
        title: "Shift in Predicted CATE (percentage points, pp)",
        zeroline: true,
        zerolinecolor: "#64748b",
        gridcolor: "#f1f5f9"
      },
      yaxis: { automargin: true },
      paper_bgcolor: "#ffffff",
      plot_bgcolor: "#ffffff"
    };

    Plotly.newPlot(sensDiv, [trace], layout, { responsive: true, displayModeBar: false });
  }

  // ===========================================================================
  // Boot Application
  // ===========================================================================
  initTab1Controls();
  initTab2Controls();
  initTab3Controls();
  renderTab1();
})();
