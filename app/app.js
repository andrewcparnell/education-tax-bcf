// =============================================================================
// Script: app/app.js
// Purpose: Clean, Policy-Maker Focused Interactive Explorer for University
//          Funding and Tax Revenue Returns
// Author: Andrew C. Parnell
// =============================================================================

(function () {
  "use strict";

  const DATA = window.EDUCATION_TAX_APP_DATA;
  if (!DATA) {
    console.error("EDUCATION_TAX_APP_DATA not found.");
    return;
  }

  const COUNTRIES = DATA.countries || [];
  const HISTORICAL = DATA.historical || [];
  const SURROGATES = DATA.surrogates || {};

  const COUNTRY_MAP = {};
  COUNTRIES.forEach((c) => {
    COUNTRY_MAP[c.iso3] = c;
  });

  // Currency & Unit Configuration
  const UNIT_CONFIG = {
    EUR: { code: "EUR", symbol: "\u20ac", rate: 0.92, label: "EUR (\u20ac per person / year)" },
    USD: { code: "USD", symbol: "$", rate: 1.0, label: "USD ($ per person / year)" },
    GBP: { code: "GBP", symbol: "\u00a3", rate: 0.79, label: "GBP (\u00a3 per person / year)" },
    PP:  { code: "PP",  symbol: "pp", rate: 1.0, label: "Percentage points (pp)" }
  };

  let currentUnit = "EUR";
  let lastActiveTab = "tab1";

  const OUTCOME_META = {
    inc_gdp: {
      key: "inc_gdp",
      label: "Income & Profit Tax Revenue",
      isShareOfTax: false,
      colour: "#0b2545"
    },
    tax_gdp: {
      key: "tax_gdp",
      label: "Total Non-Resource Tax Revenue",
      isShareOfTax: false,
      colour: "#136f63"
    },
    inc_share: {
      key: "inc_share",
      label: "Income Tax Share of Total Tax",
      isShareOfTax: true,
      colour: "#1d4ed8"
    },
    goods_share: {
      key: "goods_share",
      label: "Goods & Services Tax Share",
      isShareOfTax: true,
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

  // Convert percentage-point (pp) effect for country c and outcome outKey into active unit
  function convertValue(ppVal, c, outKey) {
    if (ppVal === null || ppVal === undefined || !Number.isFinite(Number(ppVal))) {
      return null;
    }
    const pp = Number(ppVal);
    if (currentUnit === "PP") {
      return pp;
    }
    const u = UNIT_CONFIG[currentUnit];
    const gdpPc = Number(c.gdp_per_capita_latest || c.gdp_per_capita_ppp || 25000);
    const meta = OUTCOME_META[outKey];
    if (meta && meta.isShareOfTax) {
      const taxShareGdp = Number(c.non_resource_tax_gdp_pct || 20) / 100;
      return (pp / 100) * taxShareGdp * gdpPc * u.rate;
    }
    return (pp / 100) * gdpPc * u.rate;
  }

  function formatEffectValue(val) {
    if (val === null || val === undefined || !Number.isFinite(Number(val))) return "N/A";
    const n = Number(val);
    const sign = n >= 0 ? "+" : "-";
    const absVal = Math.abs(n);
    if (currentUnit === "PP") {
      return `${sign}${absVal.toFixed(2)} pp`;
    }
    const sym = UNIT_CONFIG[currentUnit].symbol;
    return `${sign}${sym}${Math.round(absVal).toLocaleString("en-GB")}`;
  }

  function formatNationalTotal(perPersonVal, c) {
    if (
      currentUnit === "PP" ||
      perPersonVal === null ||
      perPersonVal === undefined ||
      !Number.isFinite(Number(perPersonVal))
    ) {
      return "";
    }
    const pop = Number(c.population_latest || 0);
    if (!pop || pop <= 0) return "";
    const total = Number(perPersonVal) * pop;
    const sign = total >= 0 ? "+" : "-";
    const absTot = Math.abs(total);
    const sym = UNIT_CONFIG[currentUnit].symbol;
    if (absTot >= 1e9) {
      return `National total: ${sign}${sym}${(absTot / 1e9).toFixed(2)} billion / yr`;
    }
    return `National total: ${sign}${sym}${Math.round(absTot / 1e6).toLocaleString("en-GB")} million / yr`;
  }

  // ===========================================================================
  // Navigation & Help Page
  // ===========================================================================
  const tabBtns = document.querySelectorAll(".tab-btn");
  const tabPanes = document.querySelectorAll(".tab-pane");
  const helpBtn = document.getElementById("btn-help");
  const closeHelpBtn = document.getElementById("btn-close-help");

  function showPane(paneId) {
    tabPanes.forEach((p) => p.classList.toggle("active", p.id === paneId));
    if (paneId === "help-pane") {
      tabBtns.forEach((b) => b.classList.remove("active"));
      helpBtn.classList.add("active");
    } else {
      lastActiveTab = paneId;
      helpBtn.classList.remove("active");
      tabBtns.forEach((b) =>
        b.classList.toggle("active", b.getAttribute("data-tab") === paneId)
      );
      if (paneId === "tab1") renderTab1();
      if (paneId === "tab2") renderTab2();
      if (paneId === "tab3") renderTab3();
    }
  }

  tabBtns.forEach((btn) => {
    btn.addEventListener("click", () => {
      showPane(btn.getAttribute("data-tab"));
    });
  });

  helpBtn.addEventListener("click", () => {
    const isHelpOpen = document.getElementById("help-pane").classList.contains("active");
    showPane(isHelpOpen ? lastActiveTab : "help-pane");
  });

  closeHelpBtn.addEventListener("click", () => {
    showPane(lastActiveTab);
  });

  // Global Unit Selector
  const unitSel = document.getElementById("global-unit-select");
  unitSel.addEventListener("change", () => {
    currentUnit = unitSel.value;
    if (lastActiveTab === "tab1") renderTab1();
    if (lastActiveTab === "tab3") renderTab3();
  });

  // ===========================================================================
  // TAB 1: Future Tax Estimation
  // ===========================================================================
  const t1State = {
    horizon: "10",
    outcome: "inc_gdp",
    selectedIsos: ["IRL", "GBR", "NOR", "AUT", "CHL", "ZAF"],
    searchQuery: ""
  };

  const t1Presets = {
    default: ["IRL", "GBR", "NOR", "AUT", "CHL", "ZAF"],
    europe: ["IRL", "GBR", "NOR", "AUT", "SWE", "DEU", "FRA"],
    anglo: ["IRL", "GBR", "USA", "CAN", "AUS", "NZL"],
    emerging: ["CHL", "COL", "ZAF", "MEX", "BRA", "THA"],
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
        c.iso3.toLowerCase().includes(q)
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
    document.querySelectorAll("#t1-horizon-group .seg-btn").forEach((btn) => {
      btn.addEventListener("click", () => {
        document
          .querySelectorAll("#t1-horizon-group .seg-btn")
          .forEach((b) => b.classList.toggle("active", b === btn));
        t1State.horizon = btn.getAttribute("data-horizon");
        renderTab1();
      });
    });

    const outSel = document.getElementById("t1-outcome-select");
    outSel.addEventListener("change", () => {
      t1State.outcome = outSel.value;
      renderTab1();
    });

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

    const searchInput = document.getElementById("t1-country-search");
    searchInput.addEventListener("input", () => {
      t1State.searchQuery = searchInput.value;
      buildTab1CountryList();
    });

    buildTab1CountryList();
  }

  function renderTab1() {
    const plotDiv = document.getElementById("t1-forest-plot");
    const titleEl = document.getElementById("t1-main-chart-title");
    const selected = t1State.selectedIsos
      .map((iso) => COUNTRY_MAP[iso])
      .filter(Boolean);

    if (selected.length === 0) {
      Plotly.purge(plotDiv);
      plotDiv.innerHTML = `<div style="padding:4rem;text-align:center;color:#64748b;">Select one or more countries on the left to view estimated tax effects.</div>`;
      return;
    }

    const outKey = t1State.outcome;
    const meta = OUTCOME_META[outKey];
    const uCfg = UNIT_CONFIG[currentUnit];

    // Zero reference line shape + annotation
    const makeZeroShapes = (nRows) => [
      {
        type: "line",
        x0: 0,
        x1: 0,
        y0: -0.5,
        y1: Math.max(0.5, nRows - 0.5),
        line: { color: "#be123c", width: 2.5, dash: "dash" }
      }
    ];

    const zeroAnnotation = [
      {
        x: 0,
        y: 1.04,
        xref: "x",
        yref: "paper",
        text: "Zero (no effect)",
        showarrow: false,
        font: { size: 12, color: "#be123c", weight: "bold" }
      }
    ];

    if (t1State.horizon === "both") {
      titleEl.textContent = `${meta.label}: 5 Years vs 10 Years After Increasing University Funding`;
      const yNames = selected.map((c) => c.country_name);

      const x5 = selected.map((c) => convertValue(c["tau5_" + outKey], c, outKey));
      const x5High = selected.map((c) => convertValue(c[`tau5_${outKey}_high80`], c, outKey));
      const x5Low = selected.map((c) => convertValue(c[`tau5_${outKey}_low80`], c, outKey));

      const x10 = selected.map((c) => convertValue(c["tau10_" + outKey], c, outKey));
      const x10High = selected.map((c) => convertValue(c[`tau10_${outKey}_high80`], c, outKey));
      const x10Low = selected.map((c) => convertValue(c[`tau10_${outKey}_low80`], c, outKey));

      const trace5 = {
        type: "scatter",
        mode: "markers",
        name: "After 5 Years (80% range)",
        y: yNames,
        x: x5,
        marker: { color: "#0b2545", size: 11, symbol: "circle" },
        error_x: {
          type: "data",
          symmetric: false,
          array: x5.map((v, i) => (v !== null && x5High[i] !== null ? x5High[i] - v : 0)),
          arrayminus: x5.map((v, i) => (v !== null && x5Low[i] !== null ? v - x5Low[i] : 0)),
          color: "#0b2545",
          thickness: 2.5,
          width: 5
        },
        customdata: selected.map((c, i) => [
          formatEffectValue(x5[i]),
          formatNationalTotal(x5[i], c)
        ]),
        hovertemplate: "<b>%{y} (5 Years)</b><br>Estimated change: %{customdata[0]}<br>%{customdata[1]}<extra></extra>"
      };

      const trace10 = {
        type: "scatter",
        mode: "markers",
        name: "After 10 Years (80% range)",
        y: yNames,
        x: x10,
        marker: { color: "#136f63", size: 12, symbol: "diamond" },
        error_x: {
          type: "data",
          symmetric: false,
          array: x10.map((v, i) => (v !== null && x10High[i] !== null ? x10High[i] - v : 0)),
          arrayminus: x10.map((v, i) => (v !== null && x10Low[i] !== null ? v - x10Low[i] : 0)),
          color: "#136f63",
          thickness: 2.8,
          width: 5
        },
        customdata: selected.map((c, i) => [
          formatEffectValue(x10[i]),
          formatNationalTotal(x10[i], c)
        ]),
        hovertemplate: "<b>%{y} (10 Years)</b><br>Estimated change: %{customdata[0]}<br>%{customdata[1]}<extra></extra>"
      };

      const layout = {
        margin: { t: 38, r: 30, b: 60, l: 150 },
        xaxis: {
          title: `Estimated Annual Change (${uCfg.label})`,
          gridcolor: "#f1f5f9",
          zeroline: false
        },
        yaxis: { automargin: true },
        shapes: makeZeroShapes(yNames.length),
        annotations: zeroAnnotation,
        legend: { orientation: "h", y: 1.11, x: 0 },
        paper_bgcolor: "#ffffff",
        plot_bgcolor: "#ffffff"
      };

      Plotly.newPlot(plotDiv, [trace5, trace10], layout, {
        responsive: true,
        displayModeBar: false
      });
      return;
    }

    // Single horizon (5 or 10 years)
    const h = Number(t1State.horizon);
    const pref = h === 5 ? "tau5_" : "tau10_";
    titleEl.textContent = `${meta.label}: Estimated Effect ${h} Years After Increasing University Funding`;

    const rows = selected
      .map((c) => {
        const mean = convertValue(c[pref + outKey], c, outKey);
        const low80 = convertValue(c[`${pref}${outKey}_low80`], c, outKey);
        const high80 = convertValue(c[`${pref}${outKey}_high80`], c, outKey);
        const low95 = convertValue(c[`${pref}${outKey}_low95`], c, outKey);
        const high95 = convertValue(c[`${pref}${outKey}_high95`], c, outKey);
        return { c, mean, low80, high80, low95, high95 };
      })
      .sort((a, b) => (a.mean !== null ? a.mean : -1e9) - (b.mean !== null ? b.mean : -1e9));

    const yLabels = rows.map((r) => r.c.country_name);

    const trace95 = {
      type: "scatter",
      mode: "markers",
      name: "95% range",
      y: yLabels,
      x: rows.map((r) => r.mean),
      marker: { color: "rgba(0,0,0,0)", size: 1 },
      error_x: {
        type: "data",
        symmetric: false,
        array: rows.map((r) => (r.mean !== null && r.high95 !== null ? r.high95 - r.mean : 0)),
        arrayminus: rows.map((r) => (r.mean !== null && r.low95 !== null ? r.mean - r.low95 : 0)),
        color: "#94a3b8",
        thickness: 1.5,
        width: 0
      },
      hoverinfo: "skip"
    };

    const trace80 = {
      type: "scatter",
      mode: "markers",
      name: "Estimated effect & 80% range",
      y: yLabels,
      x: rows.map((r) => r.mean),
      marker: { color: meta.colour, size: 12 },
      error_x: {
        type: "data",
        symmetric: false,
        array: rows.map((r) => (r.mean !== null && r.high80 !== null ? r.high80 - r.mean : 0)),
        arrayminus: rows.map((r) => (r.mean !== null && r.low80 !== null ? r.mean - r.low80 : 0)),
        color: meta.colour,
        thickness: 4,
        width: 6
      },
      customdata: rows.map((r) => [
        formatEffectValue(r.mean),
        formatEffectValue(r.low80),
        formatEffectValue(r.high80),
        formatNationalTotal(r.mean, r.c)
      ]),
      hovertemplate:
        "<b>%{y}</b><br>" +
        "Estimated annual change: <b>%{customdata[0]}</b><br>" +
        "80% range: [%{customdata[1]}, %{customdata[2]}]<br>" +
        "%{customdata[3]}<extra></extra>"
    };

    const layout = {
      margin: { t: 38, r: 30, b: 60, l: 150 },
      xaxis: {
        title: `Estimated Annual Change (${uCfg.label})`,
        gridcolor: "#f1f5f9",
        zeroline: false
      },
      yaxis: { automargin: true },
      shapes: makeZeroShapes(yLabels.length),
      annotations: zeroAnnotation,
      legend: { orientation: "h", y: 1.11, x: 0 },
      paper_bgcolor: "#ffffff",
      plot_bgcolor: "#ffffff"
    };

    Plotly.newPlot(plotDiv, [trace95, trace80], layout, {
      responsive: true,
      displayModeBar: false
    });
  }

  // ===========================================================================
  // TAB 2: Historical Data (Compelling Multi-Wave Default Countries)
  // ===========================================================================
  const t2State = {
    mode: "levels",
    xVar: "tert_spend_gdp_pct",
    yVar: "income_profit_tax_share_rev_pct",
    wave: 8,
    playing: false,
    timer: null,
    selectedIsos: ["NOR", "CHL", "AUT", "LTU", "ZAF"],
    searchQuery: ""
  };

  const t2VarLabels = {
    tert_spend_gdp_pct: "University Spending (% of GDP)",
    tert_spend_per_student_winsor: "Spend per Student (% of GDP per person)",
    tert_spend_abs_change: "5-Year Change in Spend per Student (pp)",
    d_tert_spend_gdp_pp: "5-Year Change in University Spending (% of GDP)",
    income_profit_tax_share_rev_pct: "Income Tax Share (% of total tax revenue)",
    inc_tax_gdp_pct: "Income Tax Revenue (% of GDP)",
    non_resource_tax_gdp_pct: "Total Non-Resource Tax Revenue (% of GDP)",
    d_prev_inc_tax_share_pp: "5-Year Change in Income Tax Share (pp)",
    d_prev_nonres_tax_gdp_pp: "5-Year Change in Total Tax (% of GDP)"
  };

  const t2Presets = {
    default: ["NOR", "CHL", "AUT", "LTU", "ZAF"],
    risers: ["NOR", "CHL", "AUT", "DNK", "MEX"],
    decliners: ["LTU", "COL", "IRL", "ZAF", "SWE"],
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
          `${t2State.selectedIsos.length} selected`;
        renderTab2();
      });
      box.appendChild(div);
    });

    document.getElementById("t2-selected-count").textContent =
      `${t2State.selectedIsos.length} selected`;
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
        if (t2State.mode === "levels") {
          xSel.value = "tert_spend_gdp_pct";
          ySel.value = "income_profit_tax_share_rev_pct";
        } else {
          xSel.value = "d_tert_spend_gdp_pp";
          ySel.value = "d_prev_inc_tax_share_pp";
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

    const slider = document.getElementById("t2-wave-slider");
    slider.addEventListener("input", () => {
      t2State.wave = Number(slider.value);
      document.getElementById("t2-wave-badge").textContent = WAVE_LABELS[t2State.wave];
      renderTab2();
    });

    const playBtn = document.getElementById("t2-play-btn");
    playBtn.addEventListener("click", () => {
      if (t2State.playing) {
        stopTab2Animation();
      } else {
        startTab2Animation();
      }
    });

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

    if (t2State.wave >= 8 || t2State.wave < 2) {
      t2State.wave = 2;
      slider.value = "2";
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
    }, 1100);
  }

  function stopTab2Animation() {
    const playBtn = document.getElementById("t2-play-btn");
    t2State.playing = false;
    playBtn.innerHTML = "&#9654; Play";
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
    const xPad = (xMax - xMin) * 0.1 || 1;
    const yPad = (yMax - yMin) * 0.1 || 2;

    const waveRows = allValid.filter((r) => Number(r.wave_index) === activeWave);
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
        text: sub.map((r) => `${r.country_name} (${r.wave_label})`),
        marker: {
          color: REGION_COLOURS[reg] || "#475569",
          opacity: t2State.selectedIsos.length > 0 ? 0.32 : 0.75,
          size: sub.map((r) => {
            const pop = Number(r.population_total) || 5e6;
            return Math.max(8, Math.min(32, Math.sqrt(pop / 1e6) * 2.1));
          }),
          line: { color: "#ffffff", width: 1 }
        },
        hovertemplate:
          "<b>%{text}</b><br>" +
          `${t2VarLabels[xCol]}: %{x:.2f}<br>` +
          `${t2VarLabels[yCol]}: %{y:.2f}<extra></extra>`
      });
    });

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
        name: cName,
        x: cRows.map((r) => r[xCol]),
        y: cRows.map((r) => r[yCol]),
        text: cRows.map((r, i) => (i === cRows.length - 1 ? cName : "")),
        textposition: "top center",
        textfont: { size: 11, color: col, weight: "bold" },
        line: { color: col, width: 3 },
        marker: {
          color: col,
          size: cRows.map((_, i) => (i === cRows.length - 1 ? 13 : 7)),
          symbol: cRows.map((_, i) => (i === cRows.length - 1 ? "diamond" : "circle")),
          line: { color: "#ffffff", width: 1.5 }
        },
        customdata: cRows.map((r) => r.wave_label),
        hovertemplate:
          `<b>${cName} (%{customdata})</b><br>` +
          `University funding: %{x:.2f}<br>Tax revenue: %{y:.2f}<extra></extra>`
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
    const isos = t2State.selectedIsos.length
      ? t2State.selectedIsos
      : ["NOR", "CHL", "AUT", "LTU", "ZAF"];
    const palette = ["#be123c", "#0b2545", "#136f63", "#d97706", "#2563eb", "#7c3aed"];

    const traces = [];

    isos.forEach((iso, idx) => {
      const cRows = HISTORICAL.filter((r) => r.iso3 === iso && Number(r.wave_index) >= 2).sort(
        (a, b) => Number(a.wave_index) - Number(b.wave_index)
      );
      if (!cRows.length) return;
      const col = palette[idx % palette.length];
      const name = cRows[0].country_name;

      traces.push({
        type: "scatter",
        mode: "lines+markers",
        name: name,
        legendgroup: iso,
        x: cRows.map((r) => r.wave_label),
        y: cRows.map((r) => r[xCol]),
        xaxis: "x",
        yaxis: "y",
        line: { color: col, width: 2.5 },
        marker: { size: 7, color: col },
        hovertemplate: `<b>${name}</b> (%{x})<br>Funding: %{y:.2f}<extra></extra>`
      });

      traces.push({
        type: "scatter",
        mode: "lines+markers",
        name: name,
        legendgroup: iso,
        showlegend: false,
        x: cRows.map((r) => r.wave_label),
        y: cRows.map((r) => r[yCol]),
        xaxis: "x2",
        yaxis: "y2",
        line: { color: col, width: 2.5 },
        marker: { size: 7, color: col, symbol: "diamond" },
        hovertemplate: `<b>${name}</b> (%{x})<br>Tax: %{y:.2f}<extra></extra>`
      });
    });

    const layout = {
      grid: { rows: 1, columns: 2, pattern: "independent" },
      margin: { t: 28, r: 25, b: 48, l: 60 },
      xaxis: { title: "Five-Year Period" },
      yaxis: {
        title: t2VarLabels[xCol] || "University Funding",
        gridcolor: "#f1f5f9"
      },
      xaxis2: { title: "Five-Year Period" },
      yaxis2: {
        title: t2VarLabels[yCol] || "Tax Revenue",
        gridcolor: "#f1f5f9"
      },
      legend: { orientation: "h", y: 1.16, x: 0 },
      paper_bgcolor: "#ffffff",
      plot_bgcolor: "#ffffff"
    };

    Plotly.newPlot(plotDiv, traces, layout, { responsive: true, displayModeBar: false });
  }

  // ===========================================================================
  // TAB 3: Full policy scenarios
  // ===========================================================================
  const t3State = {
    iso3: "IRL",
    direction: 1,
    horizon: 10,
    drawerOpen: false,
    moderators: {},
    baselineModerators: {}
  };

  const MODERATOR_SPECS = [
    {
      id: "gross_tert_enrolment_pct",
      countryField: "gross_tert_enrolment_pct",
      fmt: (v) => `${Number(v).toFixed(0)}%`
    },
    {
      id: "gdp_pc_ppp",
      countryField: "gdp_per_capita_ppp",
      fmt: (v) => `$${Math.round(Number(v)).toLocaleString("en-GB")}`
    },
    {
      id: "gross_seco_enrolment_pct",
      countryField: "gross_seco_enrolment_pct",
      fmt: (v) => `${Number(v).toFixed(0)}%`
    },
    {
      id: "income_profit_tax_share_rev_pct",
      countryField: "inc_tax_share_pct",
      fmt: (v) => `${Number(v).toFixed(1)}%`
    },
    {
      id: "working_age_pop_15_64_pct",
      countryField: "working_age_pop_pct",
      fmt: (v) => `${Number(v).toFixed(1)}%`
    },
    {
      id: "gini_disp_harmonised",
      countryField: "gini_disp",
      fmt: (v) => `${Number(v).toFixed(1)}`
    },
    {
      id: "life_expectancy_birth_yrs",
      countryField: "life_expectancy_yrs",
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
      opt.textContent = c.country_name;
      if (c.iso3 === t3State.iso3) opt.selected = true;
      cSel.appendChild(opt);
    });

    cSel.addEventListener("change", () => {
      t3State.iso3 = cSel.value;
      loadCountryDefaultsIntoTab3(t3State.iso3);
      renderTab3();
    });

    document.querySelectorAll("#t3-direction-group .seg-btn").forEach((btn) => {
      btn.addEventListener("click", () => {
        document
          .querySelectorAll("#t3-direction-group .seg-btn")
          .forEach((b) => b.classList.toggle("active", b === btn));
        t3State.direction = Number(btn.getAttribute("data-dir"));
        renderTab3();
      });
    });

    document.querySelectorAll("#t3-horizon-group .seg-btn").forEach((btn) => {
      btn.addEventListener("click", () => {
        document
          .querySelectorAll("#t3-horizon-group .seg-btn")
          .forEach((b) => b.classList.toggle("active", b === btn));
        t3State.horizon = Number(btn.getAttribute("data-h"));
        renderTab3();
      });
    });

    const drawerBtn = document.getElementById("t3-drawer-toggle");
    const drawerBody = document.getElementById("t3-drawer-body");
    const drawerArrow = document.getElementById("t3-drawer-arrow");

    drawerBtn.addEventListener("click", () => {
      t3State.drawerOpen = !t3State.drawerOpen;
      drawerBody.classList.toggle("open", t3State.drawerOpen);
      drawerBtn.setAttribute("aria-expanded", String(t3State.drawerOpen));
      drawerArrow.innerHTML = t3State.drawerOpen ? "&#9652; Hide" : "&#9662; Show";
    });

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

    document.getElementById("t3-reset-btn").addEventListener("click", () => {
      loadCountryDefaultsIntoTab3(t3State.iso3);
      renderTab3();
    });

    loadCountryDefaultsIntoTab3(t3State.iso3);
  }

  function evaluateScenarioPP(c, outKey) {
    const hKey = t3State.horizon === 5 ? "h5" : "h10";
    const pref = t3State.horizon === 5 ? "tau5_" : "tau10_";
    const sur = SURROGATES[hKey] && SURROGATES[hKey][outKey];
    const coefs = (sur && sur.coefs) || {};
    const dir = t3State.direction;

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

    const deltaMod =
      Number(coefs.gross_tert_enrolment_pct || 0) *
        (curMods.gross_tert_enrolment_pct - baseMods.gross_tert_enrolment_pct) +
      Number(coefs.log_gdp_pc_ppp || 0) * (curLogGdp - baseLogGdp) +
      Number(coefs.gross_seco_enrolment_pct || 0) *
        (curMods.gross_seco_enrolment_pct - baseMods.gross_seco_enrolment_pct) +
      Number(coefs.income_profit_tax_share_rev_pct || 0) *
        (curMods.income_profit_tax_share_rev_pct - baseMods.income_profit_tax_share_rev_pct) +
      Number(coefs.working_age_pop_15_64_pct || 0) *
        (curMods.working_age_pop_15_64_pct - baseMods.working_age_pop_15_64_pct) +
      Number(coefs.gini_disp_harmonised || 0) *
        (curMods.gini_disp_harmonised - baseMods.gini_disp_harmonised) +
      Number(coefs.life_expectancy_birth_yrs || 0) *
        (curMods.life_expectancy_birth_yrs - baseMods.life_expectancy_birth_yrs);

    const halfWidth80 =
      c[`${pref}${outKey}_high80`] !== null && c[`${pref}${outKey}_low80`] !== null
        ? (c[`${pref}${outKey}_high80`] - c[`${pref}${outKey}_low80`]) / 2
        : 1.28 * Number((sur && sur.mean_sd) || 0.5);

    const basePP = dir * baseMean;
    const simPP = dir * (baseMean + deltaMod);

    return {
      baseVal: convertValue(basePP, c, outKey),
      simVal: convertValue(simPP, c, outKey),
      errVal: Math.abs(convertValue(halfWidth80, c, outKey))
    };
  }

  function renderTab3() {
    const c = COUNTRY_MAP[t3State.iso3] || COUNTRIES[0];
    const dirLabel = t3State.direction === 1 ? "Increasing University Funding" : "Reducing University Funding";
    const uCfg = UNIT_CONFIG[currentUnit];

    document.getElementById("t3-chart-title").textContent =
      `${c.country_name}: Estimated Tax Impact ${t3State.horizon} Years After ${dirLabel}`;

    const outcomes = [
      { key: "inc_gdp", label: "Income & Profit Tax\nRevenue" },
      { key: "tax_gdp", label: "Total Non-Resource\nTax Revenue" },
      { key: "inc_share", label: "Income Tax Share\nof Total Tax" },
      { key: "goods_share", label: "Goods & Services\nTax Share" }
    ];

    const evals = outcomes.map((o) => evaluateScenarioPP(c, o.key));

    const traceBase = {
      type: "bar",
      name: `${c.country_name} Baseline Profile`,
      x: outcomes.map((o) => o.label),
      y: evals.map((e) => e.baseVal),
      marker: { color: "#0b2545" },
      error_y: {
        type: "data",
        array: evals.map((e) => e.errVal),
        color: "#334155",
        thickness: 2,
        width: 5
      },
      customdata: evals.map((e) => [
        formatEffectValue(e.baseVal),
        formatNationalTotal(e.baseVal, c)
      ]),
      hovertemplate:
        "<b>%{x} (Baseline Profile)</b><br>Estimated change: <b>%{customdata[0]}</b><br>%{customdata[1]}<extra></extra>"
    };

    const traceSim = {
      type: "bar",
      name: "Custom Policy Scenario",
      x: outcomes.map((o) => o.label),
      y: evals.map((e) => e.simVal),
      marker: { color: "#136f63" },
      error_y: {
        type: "data",
        array: evals.map((e) => e.errVal),
        color: "#0f766e",
        thickness: 2,
        width: 5
      },
      customdata: evals.map((e) => [
        formatEffectValue(e.simVal),
        formatNationalTotal(e.simVal, c)
      ]),
      hovertemplate:
        "<b>%{x} (Custom Scenario)</b><br>Estimated change: <b>%{customdata[0]}</b><br>%{customdata[1]}<extra></extra>"
    };

    const layout = {
      barmode: "group",
      margin: { t: 35, r: 25, b: 60, l: 75 },
      yaxis: {
        title: `Estimated Annual Change (${uCfg.label})`,
        zeroline: true,
        zerolinecolor: "#be123c",
        zerolinewidth: 2,
        gridcolor: "#f1f5f9"
      },
      legend: { orientation: "h", y: 1.11, x: 0 },
      paper_bgcolor: "#ffffff",
      plot_bgcolor: "#ffffff"
    };

    Plotly.newPlot("t3-scenario-plot", [traceBase, traceSim], layout, {
      responsive: true,
      displayModeBar: false
    });
  }

  // ===========================================================================
  // Boot Application
  // ===========================================================================
  initTab1Controls();
  initTab2Controls();
  initTab3Controls();
  renderTab1();
})();
