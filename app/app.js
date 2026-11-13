// =============================================================================
// Script: app/app.js
// Purpose: Clean, Policy-Maker, Tax-Specialist, and Education-Analyst Focused
//          Interactive Explorer for University Funding and Tax Revenue Returns
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
    EUR_TOT: { code: "EUR_TOT", baseCode: "EUR", symbol: "\u20ac", rate: 0.92, isTotal: true,  label: "EUR (\u20ac billion / year, country total)" },
    USD_TOT: { code: "USD_TOT", baseCode: "USD", symbol: "$",      rate: 1.0,  isTotal: true,  label: "USD ($ billion / year, country total)" },
    GBP_TOT: { code: "GBP_TOT", baseCode: "GBP", symbol: "\u00a3", rate: 0.79, isTotal: true,  label: "GBP (\u00a3 billion / year, country total)" },
    EUR:     { code: "EUR",     baseCode: "EUR", symbol: "\u20ac", rate: 0.92, isTotal: false, label: "EUR (\u20ac per person / year)" },
    USD:     { code: "USD",     baseCode: "USD", symbol: "$",      rate: 1.0,  isTotal: false, label: "USD ($ per person / year)" },
    GBP:     { code: "GBP",     baseCode: "GBP", symbol: "\u00a3", rate: 0.79, isTotal: false, label: "GBP (\u00a3 per person / year)" },
    PP:      { code: "PP",      baseCode: "EUR", symbol: "pp",     rate: 1.0,  isTotal: false, label: "Percentage points (pp)" }
  };

  // World Bank Income-Group Training Median Thresholds (% of GDP per person per student)
  const INCOME_GROUP_THRESHOLDS = {
    "High income": 26.4,
    "Upper middle income": 27.6,
    "Lower middle income": 68.9,
    "Low income": 183.8
  };

  let currentUnit = "EUR_TOT";
  let lastActiveTab = "tab1";

  const OUTCOME_META = {
    inc_gdp: {
      key: "inc_gdp",
      label: "Income & Profit Tax Revenue",
      shortLabel: "Income & Profit Tax",
      isShareOfTax: false,
      scaleNote: "of GDP",
      colour: "#0b2545"
    },
    tax_gdp: {
      key: "tax_gdp",
      label: "Total Non-Resource Tax Revenue",
      shortLabel: "Total Non-Resource Tax",
      isShareOfTax: false,
      scaleNote: "of GDP",
      colour: "#136f63"
    },
    inc_share: {
      key: "inc_share",
      label: "Income Tax Share of Total Tax",
      shortLabel: "Income Tax Share",
      isShareOfTax: true,
      scaleNote: "of total tax",
      colour: "#1d4ed8"
    },
    goods_share: {
      key: "goods_share",
      label: "Goods & Services / VAT Share",
      shortLabel: "Goods / VAT Share",
      isShareOfTax: true,
      scaleNote: "of total tax",
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
  function convertValue(ppVal, c, outKey, customGdpMultiplier) {
    if (ppVal === null || ppVal === undefined || !Number.isFinite(Number(ppVal))) {
      return null;
    }
    const pp = Number(ppVal);
    if (currentUnit === "PP") {
      return pp;
    }
    const u = UNIT_CONFIG[currentUnit] || UNIT_CONFIG.EUR_TOT;
    const mult = Number.isFinite(customGdpMultiplier) && customGdpMultiplier > 0 ? customGdpMultiplier : 1.0;
    const gdpPc = Number(c.gdp_per_capita_latest || c.gdp_per_capita_ppp || 25000) * mult;
    const meta = OUTCOME_META[outKey];
    const shareFactor = meta && meta.isShareOfTax ? Number(c.non_resource_tax_gdp_pct || 20) / 100 : 1.0;
    const perPersonCurr = (pp / 100) * shareFactor * gdpPc * u.rate;
    if (u.isTotal) {
      const pop = Number(c.population_latest || 5e6);
      return (perPersonCurr * pop) / 1e9;
    }
    return perPersonCurr;
  }

  // Always convert pp to currency per person (using the active currency family, or EUR if PP)
  function convertToCurrencyPerPerson(ppVal, c, outKey, customGdpMultiplier) {
    if (ppVal === null || ppVal === undefined || !Number.isFinite(Number(ppVal))) {
      return null;
    }
    const pp = Number(ppVal);
    const activeCfg = UNIT_CONFIG[currentUnit] || UNIT_CONFIG.EUR_TOT;
    const u = UNIT_CONFIG[activeCfg.baseCode] || UNIT_CONFIG.EUR;
    const mult = Number.isFinite(customGdpMultiplier) && customGdpMultiplier > 0 ? customGdpMultiplier : 1.0;
    const gdpPc = Number(c.gdp_per_capita_latest || c.gdp_per_capita_ppp || 25000) * mult;
    const meta = OUTCOME_META[outKey];
    if (meta && meta.isShareOfTax) {
      const taxShareGdp = Number(c.non_resource_tax_gdp_pct || 20) / 100;
      return (pp / 100) * taxShareGdp * gdpPc * u.rate;
    }
    return (pp / 100) * gdpPc * u.rate;
  }

  function formatPP(ppVal, scaleNote) {
    if (ppVal === null || ppVal === undefined || !Number.isFinite(Number(ppVal))) return "N/A";
    const n = Number(ppVal);
    const sign = n >= 0 ? "+" : "-";
    const suffix = scaleNote ? ` pp ${scaleNote}` : " pp";
    return `${sign}${Math.abs(n).toFixed(2)}${suffix}`;
  }

  function formatCurrencyPerPerson(currVal, forceUnitKey) {
    if (currVal === null || currVal === undefined || !Number.isFinite(Number(currVal))) return "N/A";
    const n = Number(currVal);
    const sign = n >= 0 ? "+" : "-";
    const activeCfg = UNIT_CONFIG[forceUnitKey || currentUnit] || UNIT_CONFIG.EUR_TOT;
    const sym = UNIT_CONFIG[activeCfg.baseCode].symbol;
    return `${sign}${sym}${Math.round(Math.abs(n)).toLocaleString("en-GB")} / person`;
  }

  function formatEffectValue(val, forcePP) {
    if (val === null || val === undefined || !Number.isFinite(Number(val))) return "N/A";
    const n = Number(val);
    const sign = n >= 0 ? "+" : "-";
    const absVal = Math.abs(n);
    if (forcePP || currentUnit === "PP") {
      return `${sign}${absVal.toFixed(2)} pp`;
    }
    const u = UNIT_CONFIG[currentUnit] || UNIT_CONFIG.EUR_TOT;
    const sym = u.symbol;
    if (u.isTotal) {
      if (absVal >= 1.0) {
        return `${sign}${sym}${absVal.toFixed(2)} bn`;
      }
      if (absVal >= 0.01) {
        return `${sign}${sym}${Math.round(absVal * 1000).toLocaleString("en-GB")} m`;
      }
      return `${sign}${sym}${(absVal * 1000).toFixed(1)} m`;
    }
    return `${sign}${sym}${Math.round(absVal).toLocaleString("en-GB")}`;
  }

  function formatDualEstimate(ppVal, c, outKey, customGdpMultiplier) {
    if (ppVal === null || ppVal === undefined || !Number.isFinite(Number(ppVal))) return "N/A";
    const meta = OUTCOME_META[outKey] || {};
    const u = UNIT_CONFIG[currentUnit] || UNIT_CONFIG.EUR_TOT;
    const ppStr = formatPP(ppVal, meta.scaleNote);
    if (u.isTotal) {
      const totVal = convertValue(ppVal, c, outKey, customGdpMultiplier);
      return `${formatEffectValue(totVal)} / yr (${ppStr})`;
    }
    const currVal = convertToCurrencyPerPerson(ppVal, c, outKey, customGdpMultiplier);
    const currStr = formatCurrencyPerPerson(currVal);
    if (currentUnit === "PP") {
      return `${ppStr} (approx. ${currStr})`;
    }
    return `${currStr} (${ppStr})`;
  }

  function formatNationalTotal(perPersonCurrVal, c, forceUnitKey) {
    if (
      perPersonCurrVal === null ||
      perPersonCurrVal === undefined ||
      !Number.isFinite(Number(perPersonCurrVal))
    ) {
      return "";
    }
    const u = UNIT_CONFIG[forceUnitKey || currentUnit] || UNIT_CONFIG.EUR_TOT;
    if (u.isTotal) {
      return `Per-person equivalent: ${formatCurrencyPerPerson(perPersonCurrVal)} / yr (at constant population)`;
    }
    const pop = Number(c.population_latest || 0);
    if (!pop || pop <= 0) return "";
    const total = Number(perPersonCurrVal) * pop;
    const sign = total >= 0 ? "+" : "-";
    const absTot = Math.abs(total);
    const sym = UNIT_CONFIG[u.baseCode].symbol;
    if (absTot >= 1e9) {
      return `Country total: ${sign}${sym}${(absTot / 1e9).toFixed(2)} billion / yr (at constant population)`;
    }
    return `Country total: ${sign}${sym}${Math.round(absTot / 1e6).toLocaleString("en-GB")} million / yr (at constant population)`;
  }

  function formatCountryContextLines(c) {
    if (!c) return "";
    const thresh = INCOME_GROUP_THRESHOLDS[c.income_group] || 26.9;
    const spendRatio = Number(c.tert_spend_per_student_gdp_pc);
    const realPpp = Number(c.real_tert_spend_per_student_ppp);
    const budgetGdp = Number(c.tert_spend_gdp_pct);

    const statusStr = Number.isFinite(spendRatio)
      ? spendRatio >= thresh
        ? `Above peer median (${thresh.toFixed(1)}%)`
        : `Below peer median (${thresh.toFixed(1)}%)`
      : c.income_group || "";

    const pppStr = Number.isFinite(realPpp)
      ? `$${Math.round(realPpp).toLocaleString("en-GB")} PPP/student`
      : "N/A";
    const ratioStr = Number.isFinite(spendRatio) ? `${spendRatio.toFixed(1)}% GDP/pc` : "N/A";
    const budgetStr = Number.isFinite(budgetGdp) ? `${budgetGdp.toFixed(2)}% GDP` : "N/A";

    const taxGdp = Number(c.non_resource_tax_gdp_pct);
    const incShare = Number(c.inc_tax_share_pct);
    const goodsShare = Number(c.goods_tax_share_pct);

    const taxLine =
      `Baseline tax: ${Number.isFinite(taxGdp) ? taxGdp.toFixed(1) + "% GDP" : "N/A"}` +
      ` (Direct: ${Number.isFinite(incShare) ? incShare.toFixed(1) + "%" : "N/A"}` +
      ` | Goods/VAT: ${Number.isFinite(goodsShare) ? goodsShare.toFixed(1) + "%" : "N/A"})`;

    return (
      `Historical avg uni spend: ${pppStr} (${ratioStr} - ${statusStr}) | Budget: ${budgetStr}<br>` +
      taxLine
    );
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
  // TAB 1: Return on Investment (ROI) & Future Tax Estimation
  // ===========================================================================
  const t1State = {
    horizon: "career",
    outcome: "tax_gdp",
    scatterX: "Z1",
    scatterY: "bcr",
    selectedIsos: ["IRL", "GBR", "NOR", "AUT", "CHL", "ZAF"],
    searchQuery: ""
  };

  const t1Presets = {
    default: ["IRL", "GBR", "NOR", "AUT", "CHL", "ZAF"],
    europe: ["IRL", "GBR", "NOR", "AUT", "SWE", "DEU", "FRA"],
    nordic_tuition: ["NOR", "DNK", "SWE", "AUT", "USA", "GBR", "CHL", "IRL"],
    emerging: ["CHL", "COL", "ZAF", "MEX", "BRA", "THA"],
    all: COUNTRIES.filter((c) => c.tau10_tax_gdp !== null && c.tau10_tax_gdp !== undefined).map((c) => c.iso3),
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

    const scatterXSel = document.getElementById("t1-scatter-x-select");
    if (scatterXSel) {
      scatterXSel.addEventListener("change", () => {
        t1State.scatterX = scatterXSel.value;
        renderTab1();
      });
    }

    const scatterYSel = document.getElementById("t1-scatter-y-select");
    if (scatterYSel) {
      scatterYSel.addEventListener("change", () => {
        t1State.scatterY = scatterYSel.value;
        renderTab1();
      });
    }

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

  function computeCohortRoiMetrics(c, outKey, doseUnits) {
    const dose = Number.isFinite(Number(doseUnits)) ? Number(doseUnits) : 1.0;
    const costInfo = computeAnnualFundingCost(c, "Z1", dose);
    const meta = OUTCOME_META[outKey] || OUTCOME_META.tax_gdp;
    const shareFactor = meta.isShareOfTax ? Number(c.non_resource_tax_gdp_pct || 20) / 100 : 1.0;

    const pp10 = c[`tau10_${outKey}`];
    const ppLow80 = c[`tau10_${outKey}_low80`];
    const ppHigh80 = c[`tau10_${outKey}_high80`];
    const ppLow95 = c[`tau10_${outKey}_low95`];
    const ppHigh95 = c[`tau10_${outKey}_high95`];

    if (pp10 === null || pp10 === undefined || !Number.isFinite(Number(pp10))) {
      return null;
    }

    const ppMean = dose * Number(pp10);
    const ppL80 = ppLow80 !== null && ppLow80 !== undefined ? dose * Number(ppLow80) : ppMean - 0.25;
    const ppH80 = ppHigh80 !== null && ppHigh80 !== undefined ? dose * Number(ppHigh80) : ppMean + 0.25;
    const ppL95 = ppLow95 !== null && ppLow95 !== undefined ? dose * Number(ppLow95) : ppMean - 0.38;
    const ppH95 = ppHigh95 !== null && ppHigh95 !== undefined ? dose * Number(ppHigh95) : ppMean + 0.38;
    const ppSd = c[`tau10_${outKey}_sd`] !== null && Number.isFinite(Number(c[`tau10_${outKey}_sd`]))
      ? dose * Number(c[`tau10_${outKey}_sd`])
      : Math.abs(ppH95 - ppL95) / 3.92;

    // 40-year career multiplier for revenue outcomes = 8x Year-10 annual flow
    const careerMult = meta.isShareOfTax ? 1.0 : 8.0;

    const careerBnMean = careerMult * costInfo.gdpTotBn * shareFactor * (ppMean / 100);
    const careerBnLow95 = careerMult * costInfo.gdpTotBn * shareFactor * (ppL95 / 100);
    const careerBnHigh95 = careerMult * costInfo.gdpTotBn * shareFactor * (ppH95 / 100);
    const careerBnSd = Math.max(0.0005, careerMult * costInfo.gdpTotBn * shareFactor * (ppSd / 100));

    const bcr = !meta.isShareOfTax && costInfo.costTotBn > 0 ? careerBnMean / costInfo.costTotBn : null;
    const bcrLow95 = !meta.isShareOfTax && costInfo.costTotBn > 0 ? careerBnLow95 / costInfo.costTotBn : null;
    const bcrHigh95 = !meta.isShareOfTax && costInfo.costTotBn > 0 ? careerBnHigh95 / costInfo.costTotBn : null;
    const probNetPos = !meta.isShareOfTax && costInfo.costTotBn > 0
      ? normCdf((careerBnMean - costInfo.costTotBn) / careerBnSd)
      : normCdf(ppMean / Math.max(0.001, ppSd));

    // Values in currently selected unit (EUR_TOT, USD_TOT, GBP_TOT, per-person, or PP)
    const meanUnitVal = careerMult * convertValue(ppMean, c, outKey);
    const low80UnitVal = careerMult * convertValue(ppL80, c, outKey);
    const high80UnitVal = careerMult * convertValue(ppH80, c, outKey);
    const low95UnitVal = careerMult * convertValue(ppL95, c, outKey);
    const high95UnitVal = careerMult * convertValue(ppH95, c, outKey);
    const inputUnitVal = meta.isShareOfTax ? null : convertValue(costInfo.costGdpPct, c, "tax_gdp");

    return {
      sym: costInfo.sym,
      costGdpPct: costInfo.costGdpPct,
      costTotBn: costInfo.costTotBn,
      careerBnMean,
      careerBnLow95,
      careerBnHigh95,
      bcr,
      bcrLow95,
      bcrHigh95,
      probNetPos,
      ppMean,
      ppL95,
      ppH95,
      meanUnitVal,
      low80UnitVal,
      high80UnitVal,
      low95UnitVal,
      high95UnitVal,
      inputUnitVal
    };
  }

  function renderTab1RoiScatter(selected) {
    const scatterDiv = document.getElementById("t1-roi-scatter-plot");
    const scatterTitleEl = document.getElementById("t1-roi-scatter-title");
    if (!scatterDiv) return;

    if (!selected || selected.length === 0) {
      Plotly.purge(scatterDiv);
      scatterDiv.innerHTML = `<div style="padding:2.5rem;text-align:center;color:#64748b;">Select one or more countries on the left to view the Investment Variable vs 40-Year ROI scatter plot.</div>`;
      return;
    }

    scatterDiv.innerHTML = "";
    const outKey = t1State.outcome;
    const meta = OUTCOME_META[outKey] || OUTCOME_META.tax_gdp;
    const uCfg = UNIT_CONFIG[currentUnit] || UNIT_CONFIG.EUR_TOT;
    const xKey = t1State.scatterX || "Z1";
    const useBcr = (t1State.scatterY || "bcr") === "bcr" && !meta.isShareOfTax;

    const xAxisMeta = {
      Z1: {
        label: "Current Per-Student University Spending (% of GDP per Person, Z1 Base)",
        getVal: (c) => Number(c.tert_spend_per_student_gdp_pc),
        fmt: (v) => `${Number(v).toFixed(1)}% of GDP/person`
      },
      Z3: {
        label: "Real Per-Student University Spending (2021 PPP USD, Z3)",
        getVal: (c) => Number(c.real_tert_spend_per_student_ppp),
        fmt: (v) => `$${Math.round(Number(v)).toLocaleString("en-GB")} PPP/student`
      },
      Z4: {
        label: "Total University Budget (% of GDP, Z4)",
        getVal: (c) => Number(c.tert_spend_gdp_pct),
        fmt: (v) => `${Number(v).toFixed(2)}% of GDP`
      },
      input_cost: {
        label: `Cohort Degree Input Cost (+10 pp Per-Student Boost, ${uCfg.label.replace(" / year", "")})`,
        getVal: (c, roi) => (roi.inputUnitVal !== null ? Number(roi.inputUnitVal) : Number(roi.costTotBn)),
        fmt: (v) => formatEffectValue(v).replace(/^\+/, "")
      }
    }[xKey];

    const pts = selected
      .map((c) => {
        const roi = computeCohortRoiMetrics(c, outKey, 1.0);
        if (!roi) return null;
        const xVal = xAxisMeta.getVal(c, roi);
        if (!Number.isFinite(xVal)) return null;
        const yMean = useBcr ? roi.bcr : roi.meanUnitVal;
        const yLow95 = useBcr ? roi.bcrLow95 : roi.low95UnitVal;
        const yHigh95 = useBcr ? roi.bcrHigh95 : roi.high95UnitVal;
        if (yMean === null || !Number.isFinite(Number(yMean))) return null;
        return { c, roi, xVal, yMean, yLow95, yHigh95 };
      })
      .filter(Boolean);

    if (pts.length === 0) {
      Plotly.purge(scatterDiv);
      scatterDiv.innerHTML = `<div style="padding:2.5rem;text-align:center;color:#64748b;">Selected countries have 5-year horizon data only; select countries with 10-year horizon data to plot 40-year career ROI.</div>`;
      return;
    }

    if (scatterTitleEl) {
      scatterTitleEl.textContent = useBcr
        ? `Investment Variable vs 40-Year Career ROI Ratio (${meta.label}, ${pts.length} Countries)`
        : `Investment Variable vs 40-Year Career Tax Output (${meta.label}, ${pts.length} Countries)`;
    }

    const traceScatter = {
      type: "scatter",
      mode: pts.length <= 35 ? "markers+text" : "markers",
      name: useBcr ? "40-Year Career ROI Ratio (95% CI)" : "40-Year Career Output (95% CI)",
      x: pts.map((p) => p.xVal),
      y: pts.map((p) => p.yMean),
      text: pts.map((p) => p.c.iso3),
      textposition: "top center",
      textfont: { size: 10.5, color: "#0f172a", weight: "bold" },
      marker: {
        color: pts.map((p) => (p.c.is_oecd ? "#1b6ca8" : "#136f63")),
        size: 11,
        line: { color: "#ffffff", width: 1.2 }
      },
      error_y: {
        type: "data",
        symmetric: false,
        array: pts.map((p) => (p.yHigh95 !== null ? p.yHigh95 - p.yMean : 0)),
        arrayminus: pts.map((p) => (p.yLow95 !== null ? p.yMean - p.yLow95 : 0)),
        color: "rgba(15, 23, 42, 0.35)",
        thickness: 1.8,
        width: 4
      },
      customdata: pts.map((p) => {
        const yMeanStr = useBcr ? `${p.yMean.toFixed(2)}x` : formatEffectValue(p.yMean);
        const yLowStr = useBcr ? `${p.yLow95.toFixed(2)}x` : formatEffectValue(p.yLow95);
        const yHighStr = useBcr ? `${p.yHigh95.toFixed(2)}x` : formatEffectValue(p.yHigh95);
        const inputStr = p.roi.inputUnitVal !== null
          ? formatEffectValue(p.roi.inputUnitVal).replace(/^\+/, "")
          : `${p.roi.sym}${p.roi.costTotBn.toFixed(2)} bn`;
        return [
          p.c.country_name,
          xAxisMeta.fmt(p.xVal),
          inputStr,
          yMeanStr,
          yLowStr,
          yHighStr,
          p.roi.probNetPos.toFixed(2),
          p.c.income_group || ""
        ];
      }),
      hovertemplate:
        "<b>%{customdata[0]} (%{customdata[7]})</b><br>" +
        "Investment level: <b>%{customdata[1]}</b><br>" +
        "Cohort degree input cost: <b>%{customdata[2]}</b><br>" +
        (useBcr ? "40-year career ROI (Output/Input): " : "40-year career output: ") +
        "<b>%{customdata[3]}</b><br>" +
        "95% credible interval: [%{customdata[4]}, %{customdata[5]}]<br>" +
        "P(40y Output > Input): <b>%{customdata[6]}</b><extra></extra>"
    };

    const shapes = [
      {
        type: "line",
        xref: "paper",
        x0: 0,
        x1: 1,
        y0: 0,
        y1: 0,
        line: { color: "#be123c", width: 1.6, dash: "dot" }
      }
    ];
    const annotations = [];

    if (useBcr) {
      shapes.push({
        type: "line",
        xref: "paper",
        x0: 0,
        x1: 1,
        y0: 1.0,
        y1: 1.0,
        line: { color: "#0b2545", width: 2.0, dash: "dash" }
      });
      annotations.push({
        xref: "paper",
        yref: "y",
        x: 0.99,
        y: 1.0,
        yshift: 11,
        xanchor: "right",
        text: "Break-Even (ROI = 1.0x: Output = Input)",
        showarrow: false,
        font: { size: 11, color: "#0b2545", weight: "bold" }
      });
    }

    const yAxisTitle = useBcr
      ? `40-Year Career ROI Ratio (40y Output / Cohort Input, x)`
      : !meta.isShareOfTax
        ? `40-Year Career Tax Output (${uCfg.label.replace(" / year", " across career")})`
        : `10-Year Structural Shift (${uCfg.label})`;

    Plotly.newPlot(
      scatterDiv,
      [traceScatter],
      {
        margin: { t: 28, r: 30, b: 56, l: 75 },
        xaxis: {
          title: xAxisMeta.label,
          type: xKey === "Z3" && pts.length > 8 ? "log" : "linear",
          gridcolor: "#f1f5f9",
          zeroline: false
        },
        yaxis: {
          title: yAxisTitle,
          gridcolor: "#f1f5f9",
          zeroline: false
        },
        shapes,
        annotations,
        showlegend: false,
        paper_bgcolor: "#ffffff",
        plot_bgcolor: "#ffffff"
      },
      { responsive: true, displayModeBar: false }
    );
  }

  function renderTab1() {
    const plotDiv = document.getElementById("t1-forest-plot");
    const titleEl = document.getElementById("t1-main-chart-title");
    const subTitleEl = document.getElementById("t1-chart-subtitle");
    const bannerEl = document.getElementById("t1-roi-summary-banner");
    const selected = t1State.selectedIsos
      .map((iso) => COUNTRY_MAP[iso])
      .filter(Boolean);

    renderTab1RoiScatter(selected);

    if (selected.length === 0) {
      Plotly.purge(plotDiv);
      if (bannerEl) bannerEl.innerHTML = "Select one or more countries on the left to view Cohort Return on Investment estimates.";
      plotDiv.innerHTML = `<div style="padding:4rem;text-align:center;color:#64748b;">Select one or more countries on the left to view estimated Return on Investment and tax effects.</div>`;
      return;
    }

    plotDiv.innerHTML = "";
    const outKey = t1State.outcome;
    const meta = OUTCOME_META[outKey];
    const uCfg = UNIT_CONFIG[currentUnit];

    // Populate top Cohort ROI Summary Banner for selected countries
    if (bannerEl) {
      const fmtBn = (sym, v) => {
        if (v === null || v === undefined || !Number.isFinite(Number(v))) return "N/A";
        const s = v >= 0 ? "+" : "-";
        const a = Math.abs(v);
        return a >= 0.05 ? `${s}${sym}${a.toFixed(2)}B` : `${s}${sym}${Math.round(a * 1000)}M`;
      };
      const chips = selected
        .map((c) => {
          const roiY1 = computeCohortRoiMetrics(c, "tax_gdp", 1.0);
          const roiY2 = computeCohortRoiMetrics(c, "inc_gdp", 1.0);
          if (!roiY1 || !roiY2) return null;
          return (
            `<span style="display:inline-block; background:#ffffff; border:1px solid #cbd5e1; border-radius:5px; padding:0.25rem 0.55rem; margin:0.18rem 0.3rem 0.18rem 0; font-size:0.78rem;">` +
            `<b>${c.country_name}:</b> Input <b>${roiY1.sym}${roiY1.costTotBn.toFixed(2)}B</b> &rarr; ` +
            `40y Total Tax (Y1) <b style="color:#136f63;">${fmtBn(roiY1.sym, roiY1.careerBnMean)}</b> (${roiY1.bcr.toFixed(2)}x, P<sub>net</sub>=${roiY1.probNetPos.toFixed(2)}) | ` +
            `Inc. Tax Floor (Y2) <b style="color:#0b2545;">${fmtBn(roiY2.sym, roiY2.careerBnMean)}</b> (${roiY2.bcr.toFixed(2)}x, P<sub>net</sub>=${roiY2.probNetPos.toFixed(2)})` +
            `</span>`
          );
        })
        .filter(Boolean)
        .join("");

      bannerEl.innerHTML =
        `<div style="font-weight:700; color:#0b2545; margin-bottom:0.2rem;">Cohort Return on Investment Summary (+10 pp Per-Student Funding Boost): Single Entering Cohort Input vs 40-Year Career Tax Output</div>` +
        `<div style="font-size:0.77rem; color:#334155; margin-bottom:0.35rem;">Because one entering cohort is 1/<i>D</i> of the student body and studies for <i>D</i> years, its multi-year degree cost equals 1 year of the system-wide boost, while its 40-year career tax output equals 8 &times; the Year-10 annual flow. <b>Y1 (Total Tax)</b> is the full Exchequer return; <b>Y2 (Direct Income Tax)</b> is the conservative floor.</div>` +
        `<div>${chips || "10-year career ROI available for countries with 10-year horizon coverage."}</div>`;
    }

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

    const zeroAnnotation = {
      x: 0,
      y: 1.04,
      xref: "x",
      yref: "paper",
      text: "Zero (no effect)",
      showarrow: false,
      font: { size: 12, color: "#be123c", weight: "bold" }
    };

    if (t1State.horizon === "career") {
      const isRev = !meta.isShareOfTax;
      titleEl.textContent = isRev
        ? `40-Year Career Return on Investment (${meta.label}) vs Cohort Degree Input Cost`
        : `${meta.label}: 10-Year Structural Tax-Mix Shift (+10 pp Per-Student Funding Boost)`;
      if (subTitleEl) {
        subTitleEl.textContent = isRev
          ? "Gold diamond = Cohort Degree Input Cost | Circle & bars = 40-Year Career Tax Output (80% & 95% CI)"
          : "80% (thick) & 95% (thin) credible intervals | Hover for details";
      }

      const roiRows = selected
        .map((c) => {
          const roi = computeCohortRoiMetrics(c, outKey, 1.0);
          return { c, roi, sortKey: roi && roi.meanUnitVal !== null ? roi.meanUnitVal : -1e9 };
        })
        .sort((a, b) => a.sortKey - b.sortKey);

      const yLabels = roiRows.map((r) => r.c.country_name);

      const trace95 = {
        type: "scatter",
        mode: "markers",
        name: "95% credible interval",
        y: yLabels,
        x: roiRows.map((r) => (r.roi ? r.roi.meanUnitVal : null)),
        marker: { color: "rgba(0,0,0,0)", size: 1 },
        error_x: {
          type: "data",
          symmetric: false,
          array: roiRows.map((r) => (r.roi && r.roi.high95UnitVal !== null ? r.roi.high95UnitVal - r.roi.meanUnitVal : 0)),
          arrayminus: roiRows.map((r) => (r.roi && r.roi.low95UnitVal !== null ? r.roi.meanUnitVal - r.roi.low95UnitVal : 0)),
          color: "#94a3b8",
          thickness: 1.6,
          width: 0
        },
        hoverinfo: "skip"
      };

      const trace80 = {
        type: "scatter",
        mode: "markers",
        name: isRev ? "40-Yr Career Tax Output (mean & 80% CI)" : "10-Yr Tax Share Shift (mean & 80% CI)",
        y: yLabels,
        x: roiRows.map((r) => (r.roi ? r.roi.meanUnitVal : null)),
        marker: { color: meta.colour, size: 12, symbol: "circle" },
        error_x: {
          type: "data",
          symmetric: false,
          array: roiRows.map((r) => (r.roi && r.roi.high80UnitVal !== null ? r.roi.high80UnitVal - r.roi.meanUnitVal : 0)),
          arrayminus: roiRows.map((r) => (r.roi && r.roi.low80UnitVal !== null ? r.roi.meanUnitVal - r.roi.low80UnitVal : 0)),
          color: meta.colour,
          thickness: 4,
          width: 6
        },
        customdata: roiRows.map((r) => {
          if (!r.roi) return ["N/A", "N/A", "N/A", "N/A", "N/A", ""];
          const sym = r.roi.sym;
          const outStr = isRev
            ? `${sym}${r.roi.careerBnMean >= 0 ? "+" : "-"}${Math.abs(r.roi.careerBnMean).toFixed(2)} bn`
            : `${r.roi.ppMean >= 0 ? "+" : "-"}${Math.abs(r.roi.ppMean).toFixed(2)} pp`;
          const ci95Str = isRev
            ? `[${sym}${r.roi.careerBnLow95 >= 0 ? "+" : "-"}${Math.abs(r.roi.careerBnLow95).toFixed(1)}B, ${sym}${r.roi.careerBnHigh95 >= 0 ? "+" : "-"}${Math.abs(r.roi.careerBnHigh95).toFixed(1)}B]`
            : `[${r.roi.ppL95.toFixed(2)} pp, ${r.roi.ppH95.toFixed(2)} pp]`;
          const inStr = isRev
            ? `${sym}${r.roi.costTotBn.toFixed(2)} bn (${r.roi.costGdpPct.toFixed(2)}% of GDP)`
            : `${sym}${r.roi.costTotBn.toFixed(2)} bn cohort input`;
          const bcrStr = isRev && r.roi.bcr !== null
            ? `${r.roi.bcr.toFixed(2)}x cohort input | P(net return > 0) = ${r.roi.probNetPos.toFixed(2)}`
            : `Posterior P(effect > 0) = ${r.roi.probNetPos.toFixed(2)}`;
          return [outStr, ci95Str, inStr, bcrStr, formatCountryContextLines(r.c)];
        }),
        hovertemplate:
          "<b>%{y}</b><br>" +
          (isRev ? "40-Yr Career Output: <b>%{customdata[0]}</b><br>" : "10-Yr Shift: <b>%{customdata[0]}</b><br>") +
          "95% CI: %{customdata[1]}<br>" +
          "Cohort Degree Input Cost: <b>%{customdata[2]}</b><br>" +
          "ROI Summary: <b>%{customdata[3]}</b><br>" +
          "%{customdata[4]}<extra></extra>"
      };

      const traces = [trace95, trace80];

      if (isRev) {
        traces.push({
          type: "scatter",
          mode: "markers",
          name: "Cohort Degree Input Cost (+10 pp)",
          y: yLabels,
          x: roiRows.map((r) => (r.roi ? r.roi.inputUnitVal : null)),
          marker: {
            color: "#f59e0b",
            size: 12,
            symbol: "diamond",
            line: { color: "#78350f", width: 1.5 }
          },
          customdata: roiRows.map((r) =>
            r.roi ? `${r.roi.sym}${r.roi.costTotBn.toFixed(2)} bn (${r.roi.costGdpPct.toFixed(2)}% of GDP)` : "N/A"
          ),
          hovertemplate: "<b>%{y}</b><br>Cohort Degree Input Cost: <b>%{customdata}</b><extra></extra>"
        });
      }

      const annotations = [zeroAnnotation];
      roiRows.forEach((r) => {
        if (!r.roi) {
          annotations.push({
            x: 0,
            y: r.c.country_name,
            xref: "x",
            yref: "y",
            text: "  5-yr data only (switch to 5 Years)",
            xanchor: "left",
            showarrow: false,
            font: { size: 11, color: "#64748b" }
          });
        } else if (isRev && r.roi.bcr !== null) {
          annotations.push({
            x: r.roi.meanUnitVal,
            y: r.c.country_name,
            xref: "x",
            yref: "y",
            text: `<b>${r.roi.bcr.toFixed(2)}x</b> (P<sub>net</sub>=${r.roi.probNetPos.toFixed(2)})`,
            yshift: 14,
            showarrow: false,
            font: { size: 10.5, color: "#0f172a" }
          });
        }
      });

      const xAxisLabel = isRev
        ? currentUnit === "PP"
          ? "Cumulative 40-Year Career Output vs Cohort Input (% of Single-Year GDP)"
          : `Cumulative 40-Year Career Tax Output vs Cohort Input (${uCfg.label.replace(" / year", " across career")})`
        : `10-Year Structural Shift (${uCfg.label})`;

      const layout = {
        margin: { t: 42, r: 40, b: 60, l: 150 },
        xaxis: {
          title: xAxisLabel,
          gridcolor: "#f1f5f9",
          zeroline: false
        },
        yaxis: { automargin: true },
        shapes: makeZeroShapes(yLabels.length),
        annotations: annotations,
        legend: { orientation: "h", y: 1.12, x: 0 },
        paper_bgcolor: "#ffffff",
        plot_bgcolor: "#ffffff"
      };

      Plotly.newPlot(plotDiv, traces, layout, {
        responsive: true,
        displayModeBar: false
      });
      return;
    }

    if (subTitleEl) {
      subTitleEl.textContent = "80% (thick) & 95% (thin) uncertainty ranges | Hover for baseline & national totals";
    }

    if (t1State.horizon === "both") {
      titleEl.textContent = `${meta.label}: 5 Years vs 10 Years After Increasing University Funding`;

      const sortedRows = selected
        .map((c) => {
          const pp5 = c["tau5_" + outKey];
          const pp10 = c["tau10_" + outKey];
          const x5 = convertValue(pp5, c, outKey);
          const x5Low = convertValue(c[`tau5_${outKey}_low80`], c, outKey);
          const x5High = convertValue(c[`tau5_${outKey}_high80`], c, outKey);
          const x10 = convertValue(pp10, c, outKey);
          const x10Low = convertValue(c[`tau10_${outKey}_low80`], c, outKey);
          const x10High = convertValue(c[`tau10_${outKey}_high80`], c, outKey);
          const sortKey = x10 !== null ? x10 : x5 !== null ? x5 : -1e9;
          return { c, pp5, pp10, x5, x5Low, x5High, x10, x10Low, x10High, sortKey };
        })
        .sort((a, b) => a.sortKey - b.sortKey);

      const nRows = sortedRows.length;
      const tickVals = sortedRows.map((_, i) => i);
      const tickText = sortedRows.map((r) => r.c.country_name);

      // Vertically offset 5-year (-0.16) and 10-year (+0.16) so horizontal bars never collide
      const y5 = sortedRows.map((_, i) => i - 0.16);
      const y10 = sortedRows.map((_, i) => i + 0.16);

      const trace5 = {
        type: "scatter",
        mode: "markers",
        name: "After 5 Years (80% range)",
        y: y5,
        x: sortedRows.map((r) => r.x5),
        marker: { color: "#0b2545", size: 10, symbol: "circle" },
        error_x: {
          type: "data",
          symmetric: false,
          array: sortedRows.map((r) => (r.x5 !== null && r.x5High !== null ? r.x5High - r.x5 : 0)),
          arrayminus: sortedRows.map((r) => (r.x5 !== null && r.x5Low !== null ? r.x5 - r.x5Low : 0)),
          color: "#0b2545",
          thickness: 2.6,
          width: 5
        },
        customdata: sortedRows.map((r) => {
          const currVal = convertToCurrencyPerPerson(r.pp5, r.c, outKey);
          return [
            r.c.country_name,
            formatDualEstimate(r.pp5, r.c, outKey),
            formatEffectValue(r.x5Low),
            formatEffectValue(r.x5High),
            formatNationalTotal(currVal, r.c),
            formatCountryContextLines(r.c)
          ];
        }),
        hovertemplate:
          "<b>%{customdata[0]} (After 5 Years)</b><br>" +
          "Estimated annual change: <b>%{customdata[1]}</b><br>" +
          "80% range: [%{customdata[2]}, %{customdata[3]}]<br>" +
          "%{customdata[4]}<br>" +
          "%{customdata[5]}<extra></extra>"
      };

      const trace10 = {
        type: "scatter",
        mode: "markers",
        name: "After 10 Years (80% range)",
        y: y10,
        x: sortedRows.map((r) => r.x10),
        marker: { color: "#136f63", size: 11, symbol: "diamond" },
        error_x: {
          type: "data",
          symmetric: false,
          array: sortedRows.map((r) => (r.x10 !== null && r.x10High !== null ? r.x10High - r.x10 : 0)),
          arrayminus: sortedRows.map((r) => (r.x10 !== null && r.x10Low !== null ? r.x10 - r.x10Low : 0)),
          color: "#136f63",
          thickness: 2.8,
          width: 5
        },
        customdata: sortedRows.map((r) => {
          const currVal = convertToCurrencyPerPerson(r.pp10, r.c, outKey);
          return [
            r.c.country_name,
            formatDualEstimate(r.pp10, r.c, outKey),
            formatEffectValue(r.x10Low),
            formatEffectValue(r.x10High),
            formatNationalTotal(currVal, r.c),
            formatCountryContextLines(r.c)
          ];
        }),
        hovertemplate:
          "<b>%{customdata[0]} (After 10 Years)</b><br>" +
          "Estimated annual change: <b>%{customdata[1]}</b><br>" +
          "80% range: [%{customdata[2]}, %{customdata[3]}]<br>" +
          "%{customdata[4]}<br>" +
          "%{customdata[5]}<extra></extra>"
      };

      const annotations = [zeroAnnotation];
      sortedRows.forEach((r, idx) => {
        if (r.x10 === null) {
          annotations.push({
            x: 0,
            y: idx + 0.16,
            xref: "x",
            yref: "y",
            text: "  10-yr unavailable (5-yr data only)",
            xanchor: "left",
            showarrow: false,
            font: { size: 11, color: "#64748b" }
          });
        }
      });

      const layout = {
        margin: { t: 38, r: 30, b: 60, l: 150 },
        xaxis: {
          title: `Estimated Annual Change (${uCfg.label})`,
          gridcolor: "#f1f5f9",
          zeroline: false
        },
        yaxis: {
          automargin: true,
          tickmode: "array",
          tickvals: tickVals,
          ticktext: tickText,
          range: [-0.5, Math.max(0.5, nRows - 0.5)]
        },
        shapes: makeZeroShapes(nRows),
        annotations: annotations,
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
        const ppMean = c[pref + outKey];
        const mean = convertValue(ppMean, c, outKey);
        const low80 = convertValue(c[`${pref}${outKey}_low80`], c, outKey);
        const high80 = convertValue(c[`${pref}${outKey}_high80`], c, outKey);
        const low95 = convertValue(c[`${pref}${outKey}_low95`], c, outKey);
        const high95 = convertValue(c[`${pref}${outKey}_high95`], c, outKey);
        return { c, ppMean, mean, low80, high80, low95, high95 };
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
        thickness: 1.6,
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
      customdata: rows.map((r) => {
        const currVal = convertToCurrencyPerPerson(r.ppMean, r.c, outKey);
        return [
          formatDualEstimate(r.ppMean, r.c, outKey),
          formatEffectValue(r.low80),
          formatEffectValue(r.high80),
          formatNationalTotal(currVal, r.c),
          formatCountryContextLines(r.c)
        ];
      }),
      hovertemplate:
        "<b>%{y}</b><br>" +
        "Estimated annual change: <b>%{customdata[0]}</b><br>" +
        "80% range: [%{customdata[1]}, %{customdata[2]}]<br>" +
        "%{customdata[3]}<br>" +
        "%{customdata[4]}<extra></extra>"
    };

    const annotations = [zeroAnnotation];
    rows.forEach((r) => {
      if (r.mean === null) {
        annotations.push({
          x: 0,
          y: r.c.country_name,
          xref: "x",
          yref: "y",
          text: "  5-yr data only (switch to 5 Years)",
          xanchor: "left",
          showarrow: false,
          font: { size: 11, color: "#64748b" }
        });
      }
    });

    const layout = {
      margin: { t: 38, r: 30, b: 60, l: 150 },
      xaxis: {
        title: `Estimated Annual Change (${uCfg.label})`,
        gridcolor: "#f1f5f9",
        zeroline: false
      },
      yaxis: { automargin: true },
      shapes: makeZeroShapes(yLabels.length),
      annotations: annotations,
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
  // TAB 2: Historical Data (Mode-Aware Variables, Denominator Trap, Click-to-Select)
  // ===========================================================================
  const t2State = {
    mode: "levels",
    xVar: "tert_spend_per_student_winsor",
    yVar: "income_profit_tax_share_rev_pct",
    wave: 8,
    playing: false,
    timer: null,
    selectedIsos: ["IRL", "NOR", "CHL", "AUT", "LTU", "ZAF"],
    searchQuery: ""
  };

  const T2_AXIS_OPTIONS = {
    levels: {
      x: [
        { value: "tert_spend_per_student_winsor", label: "Spend per Student (% of GDP per person, UNESCO)" },
        { value: "real_tert_spend_per_student_ppp", label: "Real Spend per Student (2021 PPP USD)" },
        { value: "tert_spend_gdp_pct", label: "Total University Budget (% of GDP)" },
        { value: "gross_tert_enrolment_pct", label: "University Enrolment (%)" }
      ],
      y: [
        { value: "income_profit_tax_share_rev_pct", label: "Income & Profit Tax Share (% of total tax)" },
        { value: "goods_services_tax_share_rev_pct", label: "Goods & Services / VAT Share (% of total tax)" },
        { value: "inc_tax_gdp_pct", label: "Income & Profit Tax Revenue (% of GDP)" },
        { value: "non_resource_tax_gdp_pct", label: "Total Non-Resource Tax Revenue (% of GDP)" }
      ]
    },
    changes: {
      x: [
        { value: "tert_spend_abs_change", label: "5-Year Change in Spend per Student (pp of GDP/pc)" },
        { value: "d_log_real_spend_stu_pct", label: "5-Year % Change in Real Spend per Student (PPP)" },
        { value: "d_tert_spend_gdp_pp", label: "5-Year Change in University Budget (% of GDP, pp)" }
      ],
      y: [
        { value: "d_prev_inc_tax_share_pp", label: "5-Year Change in Income Tax Share (pp)" },
        { value: "d_prev_goods_tax_share_pp", label: "5-Year Change in Goods / VAT Tax Share (pp)" },
        { value: "d_prev_inc_tax_gdp_pp", label: "5-Year Change in Income Tax Revenue (% of GDP, pp)" },
        { value: "d_prev_nonres_tax_gdp_pp", label: "5-Year Change in Total Tax Revenue (% of GDP, pp)" }
      ]
    }
  };

  const t2VarLabels = {};
  Object.values(T2_AXIS_OPTIONS).forEach((grp) => {
    grp.x.forEach((o) => { t2VarLabels[o.value] = o.label; });
    grp.y.forEach((o) => { t2VarLabels[o.value] = o.label; });
  });

  const t2Presets = {
    default: ["IRL", "NOR", "CHL", "AUT", "LTU", "ZAF"],
    trap: ["IRL", "CHL", "NOR", "AUT", "ETH", "MWI"],
    risers: ["NOR", "CHL", "AUT", "DNK", "MEX"],
    decliners: ["IRL", "LTU", "COL", "ZAF", "SWE"],
    clear: []
  };

  function populateTab2AxisMenus() {
    const xSel = document.getElementById("t2-x-select");
    const ySel = document.getElementById("t2-y-select");
    const opts = T2_AXIS_OPTIONS[t2State.mode] || T2_AXIS_OPTIONS.levels;

    xSel.innerHTML = "";
    opts.x.forEach((o) => {
      const el = document.createElement("option");
      el.value = o.value;
      el.textContent = o.label;
      xSel.appendChild(el);
    });

    ySel.innerHTML = "";
    opts.y.forEach((o) => {
      const el = document.createElement("option");
      el.value = o.value;
      el.textContent = o.label;
      ySel.appendChild(el);
    });

    if (opts.x.some((o) => o.value === t2State.xVar)) {
      xSel.value = t2State.xVar;
    } else {
      t2State.xVar = opts.x[0].value;
      xSel.value = t2State.xVar;
    }

    if (opts.y.some((o) => o.value === t2State.yVar)) {
      ySel.value = t2State.yVar;
    } else {
      t2State.yVar = opts.y[0].value;
      ySel.value = t2State.yVar;
    }
  }

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

    populateTab2AxisMenus();

    document.querySelectorAll("#t2-mode-group .seg-btn").forEach((btn) => {
      btn.addEventListener("click", () => {
        document
          .querySelectorAll("#t2-mode-group .seg-btn")
          .forEach((b) => b.classList.toggle("active", b === btn));
        t2State.mode = btn.getAttribute("data-mode");
        populateTab2AxisMenus();
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
          if (key === "trap" && t2State.mode === "levels") {
            t2State.xVar = "tert_spend_per_student_winsor";
            document.getElementById("t2-x-select").value = t2State.xVar;
          }
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
        mode: "markers+text",
        name: reg,
        x: sub.map((r) => r[xCol]),
        y: sub.map((r) => r[yCol]),
        text: sub.map((r) => (t2State.selectedIsos.includes(r.iso3) ? "" : r.iso3)),
        textposition: "top center",
        textfont: {
          size: 9,
          color: t2State.selectedIsos.length > 0 ? "rgba(71, 85, 105, 0.42)" : "rgba(15, 23, 42, 0.65)"
        },
        customdata: sub.map((r) => [
          r.iso3,
          `${r.country_name} (${r.wave_label})`,
          r.income_group || "",
          r.real_tert_spend_per_student_ppp
            ? `$${Math.round(Number(r.real_tert_spend_per_student_ppp)).toLocaleString("en-GB")} PPP`
            : "N/A"
        ]),
        marker: {
          color: REGION_COLOURS[reg] || "#475569",
          opacity: t2State.selectedIsos.length > 0 ? 0.34 : 0.78,
          size: sub.map((r) => {
            const pop = Number(r.population_total) || 5e6;
            return Math.max(8, Math.min(32, Math.sqrt(pop / 1e6) * 2.1));
          }),
          line: { color: "#ffffff", width: 1 }
        },
        hovertemplate:
          "<b>%{customdata[1]}</b> (%{customdata[2]})<br>" +
          `${t2VarLabels[xCol]}: <b>%{x:.2f}</b><br>` +
          `${t2VarLabels[yCol]}: <b>%{y:.2f}</b><br>` +
          "Real spend/student: %{customdata[3]}<br>" +
          "<i>Click bubble to toggle country trail</i><extra></extra>"
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
        customdata: cRows.map((r) => [iso, r.wave_label]),
        hovertemplate:
          `<b>${cName} (%{customdata[1]})</b><br>` +
          `${t2VarLabels[xCol]}: <b>%{x:.2f}</b><br>` +
          `${t2VarLabels[yCol]}: <b>%{y:.2f}</b><extra></extra>`
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

    // Click any bubble to toggle country selection
    if (typeof plotDiv.on === "function") {
      plotDiv.on("plotly_click", (evt) => {
        if (!evt || !evt.points || !evt.points.length) return;
        const pt = evt.points[0];
        const cd = pt.customdata;
        const iso = Array.isArray(cd) ? cd[0] : null;
        if (!iso || !COUNTRY_MAP[iso]) return;
        if (t2State.selectedIsos.includes(iso)) {
          t2State.selectedIsos = t2State.selectedIsos.filter((x) => x !== iso);
        } else {
          t2State.selectedIsos.push(iso);
        }
        buildTab2CountryList();
        renderTab2();
      });
    }
  }

  function renderTab2TimeSeriesPlot() {
    const plotDiv = document.getElementById("t2-timeseries-plot");
    const xCol = t2State.xVar;
    const yCol = t2State.yVar;
    const activeWaveLabel = WAVE_LABELS[t2State.wave];
    const isos = t2State.selectedIsos.length
      ? t2State.selectedIsos
      : ["IRL", "NOR", "CHL", "AUT", "LTU", "ZAF"];
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
        hovertemplate: `<b>${name}</b> (%{x})<br>${t2VarLabels[xCol]}: %{y:.2f}<extra></extra>`
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
        hovertemplate: `<b>${name}</b> (%{x})<br>${t2VarLabels[yCol]}: %{y:.2f}<extra></extra>`
      });
    });

    const allWaveLabels = ["1990-1994", "1995-1999", "2000-2004", "2005-2009", "2010-2014", "2015-2019", "2020-2024"];

    const layout = {
      grid: { rows: 1, columns: 2, pattern: "independent" },
      margin: { t: 28, r: 25, b: 48, l: 60 },
      xaxis: {
        title: "Five-Year Period",
        type: "category",
        categoryorder: "array",
        categoryarray: allWaveLabels
      },
      yaxis: {
        title: t2VarLabels[xCol] || "University Funding",
        gridcolor: "#f1f5f9"
      },
      xaxis2: {
        title: "Five-Year Period",
        type: "category",
        categoryorder: "array",
        categoryarray: allWaveLabels
      },
      yaxis2: {
        title: t2VarLabels[yCol] || "Tax Revenue",
        gridcolor: "#f1f5f9"
      },
      shapes: [
        {
          type: "line",
          xref: "x",
          yref: "paper",
          x0: activeWaveLabel,
          x1: activeWaveLabel,
          y0: 0,
          y1: 1,
          line: { color: "#be123c", width: 1.8, dash: "dot" }
        },
        {
          type: "line",
          xref: "x2",
          yref: "paper",
          x0: activeWaveLabel,
          x1: activeWaveLabel,
          y0: 0,
          y1: 1,
          line: { color: "#be123c", width: 1.8, dash: "dot" }
        }
      ],
      legend: { orientation: "h", y: 1.16, x: 0 },
      paper_bgcolor: "#ffffff",
      plot_bgcolor: "#ffffff"
    };

    Plotly.newPlot(plotDiv, traces, layout, { responsive: true, displayModeBar: false });
  }

  // ===========================================================================
  // TAB 3: Country Policy & Treasury Calculator
  // ===========================================================================
  const t3State = {
    iso3: "IRL",
    zMeasure: "Z1",
    yFocus: "tax_gdp",
    doseUnits: 1.0,
    scenarioPreset: "boost",
    direction: 1,
    horizon: "both",
    drawerOpen: false,
    moderators: {},
    baselineModerators: {}
  };

  const Z_MEASURE_META = {
    Z1: {
      code: "Z1",
      label: "Z1: Per-Student Spending Ratio (+10 pp of GDP/person)",
      shortUnit: "+10 pp of GDP/person per student",
      model5y: "M2a_Direct_10pp_5y",
      model10y: "M2b_Direct_10pp_10y"
    },
    Z2: {
      code: "Z2",
      label: "Z2: 5-Year Within-Country Change (+10 pp/student)",
      shortUnit: "+10 pp 5-year per-student change",
      model5y: "M3a_Delta10pp_5y",
      model10y: "M3b_Delta10pp_10y"
    },
    Z3: {
      code: "Z3",
      label: "Z3: Real PPP Dollars per Student (+25% real spend)",
      shortUnit: "+25% real PPP dollars per student",
      model5y: "M3c_RealPPP_5y",
      model10y: "M3d_RealPPP_10y"
    },
    Z4: {
      code: "Z4",
      label: "Z4: Total University Budget (+0.25 pp of GDP)",
      shortUnit: "+0.25 pp of GDP university budget",
      model5y: "M3e_TertGDP_5y",
      model10y: "M3f_TertGDP_10y"
    }
  };

  const MODERATOR_SPECS = [
    {
      id: "gross_tert_enrolment_pct",
      countryField: "gross_tert_enrolment_pct",
      fmt: (v) => `${Number(v).toFixed(0)}%`,
      deltaFmt: (d) => `${d >= 0 ? "+" : ""}${d.toFixed(0)}%`
    },
    {
      id: "gdp_pc_ppp",
      countryField: "gdp_per_capita_ppp",
      fmt: (v) => `$${Math.round(Number(v)).toLocaleString("en-GB")}`,
      deltaFmt: (d) => `${d >= 0 ? "+" : "-"}$${Math.round(Math.abs(d)).toLocaleString("en-GB")}`
    },
    {
      id: "gross_seco_enrolment_pct",
      countryField: "gross_seco_enrolment_pct",
      fmt: (v) => `${Number(v).toFixed(0)}%`,
      deltaFmt: (d) => `${d >= 0 ? "+" : ""}${d.toFixed(0)}%`
    },
    {
      id: "income_profit_tax_share_rev_pct",
      countryField: "inc_tax_share_pct",
      fmt: (v) => `${Number(v).toFixed(1)}%`,
      deltaFmt: (d) => `${d >= 0 ? "+" : ""}${d.toFixed(1)}%`
    },
    {
      id: "working_age_pop_15_64_pct",
      countryField: "working_age_pop_pct",
      fmt: (v) => `${Number(v).toFixed(1)}%`,
      deltaFmt: (d) => `${d >= 0 ? "+" : ""}${d.toFixed(1)}%`
    },
    {
      id: "gini_disp_harmonised",
      countryField: "gini_disp",
      fmt: (v) => `${Number(v).toFixed(1)}`,
      deltaFmt: (d) => `${d >= 0 ? "+" : ""}${d.toFixed(1)}`
    },
    {
      id: "life_expectancy_birth_yrs",
      countryField: "life_expectancy_yrs",
      fmt: (v) => `${Number(v).toFixed(1)} yrs`,
      deltaFmt: (d) => `${d >= 0 ? "+" : ""}${d.toFixed(1)}y`
    }
  ];

  function updateSliderDisplay(spec) {
    const inputEl = document.getElementById(`mod-${spec.id}`);
    const valEl = document.getElementById(`val-${spec.id}`);
    const cur = Number(t3State.moderators[spec.id]);
    const base = Number(t3State.baselineModerators[spec.id]);
    if (inputEl) inputEl.value = String(cur);
    if (valEl) {
      const diff = cur - base;
      if (Math.abs(diff) > 0.05) {
        valEl.textContent = `${spec.fmt(cur)} (${spec.deltaFmt(diff)} vs base)`;
      } else {
        valEl.textContent = spec.fmt(cur);
      }
    }
  }

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
      updateSliderDisplay(spec);
    });
  }

  function applyTab3ScenarioPreset(scenKey) {
    t3State.scenarioPreset = scenKey;
    document.querySelectorAll("#t3-scenario-pills .preset-pill").forEach((b) => {
      b.classList.toggle("active", b.getAttribute("data-scen") === scenKey);
    });

    // Reset moderators to baseline first
    MODERATOR_SPECS.forEach((spec) => {
      t3State.moderators[spec.id] = Number(t3State.baselineModerators[spec.id]);
    });

    if (scenKey === "boost") {
      t3State.direction = 1;
    } else if (scenKey === "funded_exp") {
      t3State.direction = 1;
      t3State.moderators.gross_tert_enrolment_pct = Math.min(
        115,
        Number(t3State.baselineModerators.gross_tert_enrolment_pct) + 15
      );
      t3State.moderators.gross_seco_enrolment_pct = Math.min(
        140,
        Number(t3State.baselineModerators.gross_seco_enrolment_pct) + 10
      );
    } else if (scenKey === "crowding") {
      t3State.direction = -1;
      t3State.moderators.gross_tert_enrolment_pct = Math.min(
        115,
        Number(t3State.baselineModerators.gross_tert_enrolment_pct) + 20
      );
    } else if (scenKey === "cut") {
      t3State.direction = -1;
    }

    // Sync direction buttons & slider displays
    document.querySelectorAll("#t3-direction-group .seg-btn").forEach((b) => {
      b.classList.toggle("active", Number(b.getAttribute("data-dir")) === t3State.direction);
    });
    MODERATOR_SPECS.forEach((spec) => updateSliderDisplay(spec));
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
      applyTab3ScenarioPreset(t3State.scenarioPreset || "boost");
      renderTab3();
    });

    const zSel = document.getElementById("t3-z-select");
    if (zSel) {
      zSel.addEventListener("change", () => {
        t3State.zMeasure = zSel.value || "Z1";
        renderTab3();
      });
    }

    const ySel = document.getElementById("t3-y-select");
    if (ySel) {
      ySel.addEventListener("change", () => {
        t3State.yFocus = ySel.value || "inc_gdp";
        renderTab3();
      });
    }

    const doseSel = document.getElementById("t3-dose-select");
    if (doseSel) {
      doseSel.addEventListener("change", () => {
        t3State.doseUnits = Number(doseSel.value || 1.0);
        renderTab3();
      });
    }

    document.querySelectorAll("#t3-scenario-pills .preset-pill").forEach((btn) => {
      btn.addEventListener("click", () => {
        applyTab3ScenarioPreset(btn.getAttribute("data-scen"));
        renderTab3();
      });
    });

    document.querySelectorAll("#t3-direction-group .seg-btn").forEach((btn) => {
      btn.addEventListener("click", () => {
        document
          .querySelectorAll("#t3-direction-group .seg-btn")
          .forEach((b) => b.classList.toggle("active", b === btn));
        t3State.direction = Number(btn.getAttribute("data-dir"));
        document
          .querySelectorAll("#t3-scenario-pills .preset-pill")
          .forEach((b) => b.classList.remove("active"));
        renderTab3();
      });
    });

    document.querySelectorAll("#t3-horizon-group .seg-btn").forEach((btn) => {
      btn.addEventListener("click", () => {
        document
          .querySelectorAll("#t3-horizon-group .seg-btn")
          .forEach((b) => b.classList.toggle("active", b === btn));
        t3State.horizon = btn.getAttribute("data-h");
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
      if (!inputEl) return;
      inputEl.addEventListener("input", () => {
        t3State.moderators[spec.id] = Number(inputEl.value);
        updateSliderDisplay(spec);
        document
          .querySelectorAll("#t3-scenario-pills .preset-pill")
          .forEach((b) => b.classList.remove("active"));
        renderTab3();
      });
    });

    document.getElementById("t3-reset-btn").addEventListener("click", () => {
      loadCountryDefaultsIntoTab3(t3State.iso3);
      applyTab3ScenarioPreset("boost");
      renderTab3();
    });

    loadCountryDefaultsIntoTab3(t3State.iso3);
  }

  function hasCustomModerators() {
    return MODERATOR_SPECS.some(
      (s) => Math.abs(Number(t3State.moderators[s.id]) - Number(t3State.baselineModerators[s.id])) > 0.05
    );
  }

  function getZMeasureAdjustment(outKey, numHorizon) {
    const zCode = t3State.zMeasure || "Z1";
    if (zCode === "Z1") return { ratio: 1.0, offset: 0.0 };
    const globalAte = DATA.global_ate || [];
    const outIdx = outKey === "tax_gdp" ? 1 : outKey === "inc_gdp" ? 2 : outKey === "inc_share" ? 3 : 4;
    const zMeta = Z_MEASURE_META[zCode] || Z_MEASURE_META.Z1;
    const refId = numHorizon === 5 ? "M2a_Direct_10pp_5y" : "M2b_Direct_10pp_10y";
    const altId = numHorizon === 5 ? zMeta.model5y : zMeta.model10y;
    const refRow = globalAte.find((r) => r.model_id === refId && Number(r.outcome_index) === outIdx);
    const altRow = globalAte.find((r) => r.model_id === altId && Number(r.outcome_index) === outIdx);
    if (!refRow || !altRow) return { ratio: 1.0, offset: 0.0 };
    return {
      ratio: 1.0,
      offset: Number(altRow.ate_mean || 0) - Number(refRow.ate_mean || 0)
    };
  }

  function computeAnnualFundingCost(c, zCode, doseUnits) {
    const u = UNIT_CONFIG[currentUnit] || UNIT_CONFIG.EUR_TOT;
    const baseCurr = UNIT_CONFIG[u.baseCode] || UNIT_CONFIG.EUR;
    const gdpPc = Number(c.gdp_per_capita_latest || c.gdp_per_capita_ppp || 25000);
    const pop = Number(c.population_latest || 5e6);
    const gdpTotBn = (gdpPc * pop * baseCurr.rate) / 1e9;
    const rawSpend = Math.max(2.0, Number(c.tert_spend_per_student_gdp_pc || 25.0));
    const enrol = Math.max(2.0, Number(c.gross_tert_enrolment_pct || 40.0));
    const baseTertGdpPct = Number.isFinite(Number(c.tert_spend_gdp_pct)) && Number(c.tert_spend_gdp_pct) > 0
      ? Number(c.tert_spend_gdp_pct)
      : 0.081 * (rawSpend / 100) * (enrol / 100) * 100;

    let costGdpPct = baseTertGdpPct * ((10.0 * doseUnits) / rawSpend);
    if (zCode === "Z3") {
      costGdpPct = baseTertGdpPct * (0.25 * doseUnits);
    } else if (zCode === "Z4") {
      costGdpPct = 0.25 * doseUnits;
    }
    const costTotBn = gdpTotBn * (costGdpPct / 100);
    return {
      sym: baseCurr.symbol,
      costGdpPct,
      costTotBn,
      gdpTotBn
    };
  }

  function evaluateScenarioForHorizon(c, outKey, numHorizon) {
    const hKey = numHorizon === 5 ? "h5" : "h10";
    const pref = numHorizon === 5 ? "tau5_" : "tau10_";
    const sur = SURROGATES[hKey] && SURROGATES[hKey][outKey];
    const coefs = (sur && sur.coefs) || {};
    const dir = t3State.direction;
    const dose = Number(t3State.doseUnits || 1.0);
    const zAdj = getZMeasureAdjustment(outKey, numHorizon);

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

    const halfWidth80PP =
      dose *
      (c[`${pref}${outKey}_high80`] !== null && c[`${pref}${outKey}_low80`] !== null
        ? Math.abs(c[`${pref}${outKey}_high80`] - c[`${pref}${outKey}_low80`]) / 2
        : 1.28 * Number((sur && sur.mean_sd) || 0.5));

    const halfWidth95PP =
      dose *
      (c[`${pref}${outKey}_high95`] !== null && c[`${pref}${outKey}_low95`] !== null
        ? Math.abs(c[`${pref}${outKey}_high95`] - c[`${pref}${outKey}_low95`]) / 2
        : 1.96 * Number(c[`${pref}${outKey}_sd`] || (sur && sur.mean_sd) || 0.2));

    const sdPP =
      dose *
      (c[`${pref}${outKey}_sd`] !== null && Number.isFinite(Number(c[`${pref}${outKey}_sd`]))
        ? Number(c[`${pref}${outKey}_sd`])
        : halfWidth95PP / 1.96);

    const basePP = dir * dose * (baseMean + zAdj.offset);
    const simPP = dir * dose * (baseMean + zAdj.offset + deltaMod);
    const gdpMult =
      baseMods.gdp_pc_ppp > 0 ? Number(curMods.gdp_pc_ppp) / Number(baseMods.gdp_pc_ppp) : 1.0;

    return {
      basePP,
      simPP,
      halfWidth80PP,
      halfWidth95PP,
      sdPP,
      baseVal: convertValue(basePP, c, outKey, 1.0),
      simVal: convertValue(simPP, c, outKey, gdpMult),
      errBaseVal: Math.abs(convertValue(halfWidth80PP, c, outKey, 1.0)),
      errSimVal: Math.abs(convertValue(halfWidth80PP, c, outKey, gdpMult)),
      gdpMult
    };
  }

  function normCdf(x) {
    const t = 1 / (1 + 0.2316419 * Math.abs(x));
    const d = 0.3989423 * Math.exp((-x * x) / 2);
    const p =
      d *
      t *
      (0.3193815 +
        t * (-0.3565638 + t * (1.781478 + t * (-1.821256 + t * 1.330274))));
    return x > 0 ? 1 - p : p;
  }

  function renderTab3() {
    const c = COUNTRY_MAP[t3State.iso3] || COUNTRIES[0];
    const dirLabel =
      t3State.direction === 1 ? "Increasing University Funding" : "Reducing University Funding";
    const uCfg = UNIT_CONFIG[currentUnit];

    const thresh = INCOME_GROUP_THRESHOLDS[c.income_group] || 26.9;
    const spendRatio = Number(c.tert_spend_per_student_gdp_pc);
    const tagEl = document.getElementById("t3-baseline-tag");
    if (tagEl) {
      const ratioTxt = Number.isFinite(spendRatio)
        ? `${spendRatio.toFixed(1)}% GDP/pc (${spendRatio >= thresh ? "Above" : "Below"} peer median ${thresh.toFixed(1)}%)`
        : "80% uncertainty range";
      tagEl.textContent = `Avg spend/student: ${ratioTxt} | Baseline tax: ${Number(c.non_resource_tax_gdp_pct || 0).toFixed(1)}% GDP`;
    }

    // Populate Assistance for Policy Makers Card (#t3-policy-brief-card)
    const briefEl = document.getElementById("t3-policy-brief-card");
    if (briefEl) {
      const zCode = t3State.zMeasure || "Z1";
      const yKey = t3State.yFocus || "tax_gdp";
      const dose = Number(t3State.doseUnits || 1.0);
      const yMeta = OUTCOME_META[yKey] || OUTCOME_META.tax_gdp;
      const costInfo = computeAnnualFundingCost(c, zCode, dose);
      const ev5 = evaluateScenarioForHorizon(c, yKey, 5);
      const ev10 = evaluateScenarioForHorizon(c, yKey, 10);
      const ev10Tax = evaluateScenarioForHorizon(c, "tax_gdp", 10);
      const ev10Inc = evaluateScenarioForHorizon(c, "inc_gdp", 10);
      const ev10Share = evaluateScenarioForHorizon(c, "inc_share", 10);

      const shareFactor = yMeta.isShareOfTax ? Number(c.non_resource_tax_gdp_pct || 20) / 100 : 1.0;
      const ret5Bn = costInfo.gdpTotBn * shareFactor * (ev5.simPP / 100);
      const ret10Bn = costInfo.gdpTotBn * shareFactor * (ev10.simPP / 100);
      const career8Bn = 8.0 * ret10Bn;
      const career8Half95Bn = 8.0 * costInfo.gdpTotBn * shareFactor * (ev10.halfWidth95PP / 100);
      const career8SdBn = Math.max(0.001, 8.0 * costInfo.gdpTotBn * shareFactor * (ev10.sdPP / 100));
      const careerLow95Bn = career8Bn - career8Half95Bn;
      const careerHigh95Bn = career8Bn + career8Half95Bn;
      const bcr = costInfo.costTotBn > 0 ? career8Bn / costInfo.costTotBn : 0;
      const probNetPos = normCdf((career8Bn - costInfo.costTotBn) / career8SdBn);

      // Always compute both Y1 (Total Tax Full Exchequer Return) and Y2 (Direct Income Tax Floor)
      const careerTax8Bn = 8.0 * costInfo.gdpTotBn * (ev10Tax.simPP / 100);
      const careerTaxSdBn = Math.max(0.001, 8.0 * costInfo.gdpTotBn * (ev10Tax.sdPP / 100));
      const careerTaxHalf95Bn = 8.0 * costInfo.gdpTotBn * (ev10Tax.halfWidth95PP / 100);
      const bcrTax = costInfo.costTotBn > 0 ? careerTax8Bn / costInfo.costTotBn : 0;
      const probNetPosTax = normCdf((careerTax8Bn - costInfo.costTotBn) / careerTaxSdBn);

      const careerInc8Bn = 8.0 * costInfo.gdpTotBn * (ev10Inc.simPP / 100);
      const careerIncSdBn = Math.max(0.001, 8.0 * costInfo.gdpTotBn * (ev10Inc.sdPP / 100));
      const careerIncHalf95Bn = 8.0 * costInfo.gdpTotBn * (ev10Inc.halfWidth95PP / 100);
      const bcrInc = costInfo.costTotBn > 0 ? careerInc8Bn / costInfo.costTotBn : 0;
      const probNetPosInc = normCdf((careerInc8Bn - costInfo.costTotBn) / careerIncSdBn);

      const shareShiftPP = ev10Share.simPP;

      const curSpendTxt = zCode === "Z3"
        ? `$${Math.round(Number(c.real_tert_spend_per_student_ppp || 8000)).toLocaleString("en-GB")} PPP/student`
        : zCode === "Z4"
        ? `${Number(c.tert_spend_gdp_pct || 1.0).toFixed(2)}% of GDP`
        : `${Number(c.tert_spend_per_student_gdp_pc || 25.0).toFixed(1)}% of GDP/person`;

      const fmtBn = (val) => {
        const s = val >= 0 ? "+" : "-";
        const a = Math.abs(val);
        return a >= 0.1 ? `${s}${costInfo.sym}${a.toFixed(2)} bn` : `${s}${costInfo.sym}${Math.round(a * 1000)} m`;
      };

      briefEl.innerHTML =
        `<div style="font-weight:700; color:#0b2545; margin-bottom:0.25rem;">Assistance for Policy Makers: Treasury Return on Investment Brief (${c.country_name} - ${Z_MEASURE_META[zCode].label})</div>` +
        `<div style="display:flex; flex-wrap:wrap; gap:1.1rem; margin-bottom:0.35rem;">` +
        `<span><b>Current funding:</b> ${curSpendTxt}</span>` +
        `<span><b>Cohort degree input (${dose.toFixed(1)}u):</b> <b>${costInfo.sym}${costInfo.costTotBn.toFixed(2)} bn</b> (${costInfo.costGdpPct.toFixed(2)}% GDP)</span>` +
        `<span><b>+5y / +10y annual flow (${yMeta.shortLabel}):</b> ${fmtBn(ret5Bn)}/yr &rarr; ${fmtBn(ret10Bn)}/yr</span>` +
        `<span><b>+10y tax mix shift (Y3):</b> ${shareShiftPP >= 0 ? "+" : ""}${shareShiftPP.toFixed(2)} pp</span>` +
        `</div>` +
        `<div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(260px, 1fr)); gap:0.55rem; margin-bottom:0.4rem;">` +
        `<div style="background:#ffffff; border:1px solid #cbd5e1; border-left:3px solid #136f63; border-radius:4px; padding:0.4rem 0.6rem;">` +
        `<b>Full Exchequer 40-Yr Career Output (Y1 Total Tax):</b> <b style="color:#136f63;">${fmtBn(careerTax8Bn)}</b><br/>` +
        `<span style="font-size:0.78rem; color:#334155;">95% CI [${fmtBn(careerTax8Bn - careerTaxHalf95Bn)}, ${fmtBn(careerTax8Bn + careerTaxHalf95Bn)}] | <b>BCR = ${bcrTax.toFixed(2)}x</b> | <b>P(net &gt; 0) = ${probNetPosTax.toFixed(2)}</b> (includes income, corporate, payroll/PRSI &amp; VAT)</span>` +
        `</div>` +
        `<div style="background:#ffffff; border:1px solid #cbd5e1; border-left:3px solid #0b2545; border-radius:4px; padding:0.4rem 0.6rem;">` +
        `<b>Conservative Floor 40-Yr Output (Y2 Direct Income Tax Only):</b> <b style="color:#0b2545;">${fmtBn(careerInc8Bn)}</b><br/>` +
        `<span style="font-size:0.78rem; color:#334155;">95% CI [${fmtBn(careerInc8Bn - careerIncHalf95Bn)}, ${fmtBn(careerInc8Bn + careerIncHalf95Bn)}] | <b>BCR = ${bcrInc.toFixed(2)}x</b> | <b>P(net &gt; 0) = ${probNetPosInc.toFixed(2)}</b> (paycheque &amp; corporate profit taxes alone)</span>` +
        `</div>` +
        `</div>` +
        `<div style="color:#136f63; font-weight:600; font-size:0.81rem;">Treasury pitch: &ldquo;Investing ${costInfo.sym}${costInfo.costTotBn.toFixed(2)} bn to educate one cohort of university students in ${c.country_name} returns ${fmtBn(careerInc8Bn)} (${bcrInc.toFixed(2)}x) from direct income and profit taxes alone (Y2), and ${fmtBn(careerTax8Bn)} (${bcrTax.toFixed(2)}x, P(net &gt; 0) = ${probNetPosTax.toFixed(2)}, 95% CI [${fmtBn(careerTax8Bn - careerTaxHalf95Bn)}, ${fmtBn(careerTax8Bn + careerTaxHalf95Bn)}]) in total Exchequer tax revenue (Y1) across their 40-year career.&rdquo;</div>`;
    }

    const revOutcomes = [
      { key: "inc_gdp", label: "Income & Profit\nTax Revenue" },
      { key: "tax_gdp", label: "Total Non-Resource\nTax Revenue" }
    ];
    const mixOutcomes = [
      { key: "inc_share", label: "Income Tax\nShare of Tax" },
      { key: "goods_share", label: "Goods / VAT\nShare of Tax" }
    ];

    const contextLines = formatCountryContextLines(c);
    const traces = [];

    if (t3State.horizon === "both") {
      document.getElementById("t3-chart-title").textContent =
        `${c.country_name}: 5-Year vs 10-Year Impact After ${dirLabel}`;

      const rev5 = revOutcomes.map((o) => evaluateScenarioForHorizon(c, o.key, 5));
      const rev10 = revOutcomes.map((o) => evaluateScenarioForHorizon(c, o.key, 10));
      const mix5 = mixOutcomes.map((o) => evaluateScenarioForHorizon(c, o.key, 5));
      const mix10 = mixOutcomes.map((o) => evaluateScenarioForHorizon(c, o.key, 10));

      // Left Panel: Revenue Mobilisation (Currency or pp of GDP)
      traces.push({
        type: "bar",
        name: "After 5 Years",
        legendgroup: "h5",
        xaxis: "x",
        yaxis: "y",
        x: revOutcomes.map((o) => o.label),
        y: rev5.map((e) => e.simVal),
        text: rev5.map((e) => formatEffectValue(e.simVal)),
        textposition: "outside",
        cliponaxis: false,
        marker: { color: "#0b2545" },
        error_y: {
          type: "data",
          array: rev5.map((e) => e.errSimVal),
          color: "#334155",
          thickness: 2,
          width: 5
        },
        customdata: rev5.map((e, i) => {
          const currVal = convertToCurrencyPerPerson(e.simPP, c, revOutcomes[i].key, e.gdpMult);
          return [
            formatDualEstimate(e.simPP, c, revOutcomes[i].key, e.gdpMult),
            formatNationalTotal(currVal, c),
            contextLines
          ];
        }),
        hovertemplate:
          "<b>%{x} (After 5 Years)</b><br>" +
          "Estimated annual change: <b>%{customdata[0]}</b><br>" +
          "%{customdata[1]}<br>%{customdata[2]}<extra></extra>"
      });

      traces.push({
        type: "bar",
        name: "After 10 Years",
        legendgroup: "h10",
        xaxis: "x",
        yaxis: "y",
        x: revOutcomes.map((o) => o.label),
        y: rev10.map((e) => e.simVal),
        text: rev10.map((e) => formatEffectValue(e.simVal)),
        textposition: "outside",
        cliponaxis: false,
        marker: { color: "#136f63" },
        error_y: {
          type: "data",
          array: rev10.map((e) => e.errSimVal),
          color: "#0f766e",
          thickness: 2,
          width: 5
        },
        customdata: rev10.map((e, i) => {
          const currVal = convertToCurrencyPerPerson(e.simPP, c, revOutcomes[i].key, e.gdpMult);
          return [
            formatDualEstimate(e.simPP, c, revOutcomes[i].key, e.gdpMult),
            formatNationalTotal(currVal, c),
            contextLines
          ];
        }),
        hovertemplate:
          "<b>%{x} (After 10 Years)</b><br>" +
          "Estimated annual change: <b>%{customdata[0]}</b><br>" +
          "%{customdata[1]}<br>%{customdata[2]}<extra></extra>"
      });

      // Right Panel: Tax Mix Shift (Always in percentage points of total tax)
      traces.push({
        type: "bar",
        name: "After 5 Years",
        legendgroup: "h5",
        showlegend: false,
        xaxis: "x2",
        yaxis: "y2",
        x: mixOutcomes.map((o) => o.label),
        y: mix5.map((e) => e.simPP),
        text: mix5.map((e) => formatEffectValue(e.simPP, true)),
        textposition: "outside",
        cliponaxis: false,
        marker: { color: "#0b2545" },
        error_y: {
          type: "data",
          array: mix5.map((e) => e.halfWidth80PP),
          color: "#334155",
          thickness: 2,
          width: 5
        },
        customdata: mix5.map((e, i) => {
          const currVal = convertToCurrencyPerPerson(e.simPP, c, mixOutcomes[i].key, e.gdpMult);
          return [
            formatPP(e.simPP, "of total tax"),
            formatCurrencyPerPerson(currVal),
            formatNationalTotal(currVal, c),
            contextLines
          ];
        }),
        hovertemplate:
          "<b>%{x} (After 5 Years)</b><br>" +
          "Tax mix shift: <b>%{customdata[0]}</b> (equiv. %{customdata[1]})<br>" +
          "%{customdata[2]}<br>%{customdata[3]}<extra></extra>"
      });

      traces.push({
        type: "bar",
        name: "After 10 Years",
        legendgroup: "h10",
        showlegend: false,
        xaxis: "x2",
        yaxis: "y2",
        x: mixOutcomes.map((o) => o.label),
        y: mix10.map((e) => e.simPP),
        text: mix10.map((e) => formatEffectValue(e.simPP, true)),
        textposition: "outside",
        cliponaxis: false,
        marker: { color: "#136f63" },
        error_y: {
          type: "data",
          array: mix10.map((e) => e.halfWidth80PP),
          color: "#0f766e",
          thickness: 2,
          width: 5
        },
        customdata: mix10.map((e, i) => {
          const currVal = convertToCurrencyPerPerson(e.simPP, c, mixOutcomes[i].key, e.gdpMult);
          return [
            formatPP(e.simPP, "of total tax"),
            formatCurrencyPerPerson(currVal),
            formatNationalTotal(currVal, c),
            contextLines
          ];
        }),
        hovertemplate:
          "<b>%{x} (After 10 Years)</b><br>" +
          "Tax mix shift: <b>%{customdata[0]}</b> (equiv. %{customdata[1]})<br>" +
          "%{customdata[2]}<br>%{customdata[3]}<extra></extra>"
      });
    } else {
      // Single horizon (5 or 10 years)
      const h = Number(t3State.horizon);
      const customActive = hasCustomModerators();
      document.getElementById("t3-chart-title").textContent =
        `${c.country_name}: Estimated Tax Impact ${h} Years After ${dirLabel}`;

      const revEvals = revOutcomes.map((o) => evaluateScenarioForHorizon(c, o.key, h));
      const mixEvals = mixOutcomes.map((o) => evaluateScenarioForHorizon(c, o.key, h));

      if (customActive) {
        // Show Baseline vs Custom Scenario side by side
        traces.push({
          type: "bar",
          name: `${c.country_name} Baseline`,
          legendgroup: "base",
          xaxis: "x",
          yaxis: "y",
          x: revOutcomes.map((o) => o.label),
          y: revEvals.map((e) => e.baseVal),
          text: revEvals.map((e) => formatEffectValue(e.baseVal)),
          textposition: "outside",
          cliponaxis: false,
          marker: { color: "#0b2545" },
          error_y: {
            type: "data",
            array: revEvals.map((e) => e.errBaseVal),
            color: "#334155",
            thickness: 2,
            width: 5
          },
          customdata: revEvals.map((e, i) => {
            const currVal = convertToCurrencyPerPerson(e.basePP, c, revOutcomes[i].key, 1.0);
            return [
              formatDualEstimate(e.basePP, c, revOutcomes[i].key, 1.0),
              formatNationalTotal(currVal, c),
              contextLines
            ];
          }),
          hovertemplate:
            "<b>%{x} (Country Baseline)</b><br>" +
            "Estimated annual change: <b>%{customdata[0]}</b><br>" +
            "%{customdata[1]}<br>%{customdata[2]}<extra></extra>"
        });

        traces.push({
          type: "bar",
          name: "Custom Scenario",
          legendgroup: "sim",
          xaxis: "x",
          yaxis: "y",
          x: revOutcomes.map((o) => o.label),
          y: revEvals.map((e) => e.simVal),
          text: revEvals.map((e) => formatEffectValue(e.simVal)),
          textposition: "outside",
          cliponaxis: false,
          marker: { color: "#136f63" },
          error_y: {
            type: "data",
            array: revEvals.map((e) => e.errSimVal),
            color: "#0f766e",
            thickness: 2,
            width: 5
          },
          customdata: revEvals.map((e, i) => {
            const currVal = convertToCurrencyPerPerson(e.simPP, c, revOutcomes[i].key, e.gdpMult);
            return [
              formatDualEstimate(e.simPP, c, revOutcomes[i].key, e.gdpMult),
              formatNationalTotal(currVal, c),
              contextLines
            ];
          }),
          hovertemplate:
            "<b>%{x} (Custom Scenario)</b><br>" +
            "Estimated annual change: <b>%{customdata[0]}</b><br>" +
            "%{customdata[1]}<br>%{customdata[2]}<extra></extra>"
        });

        traces.push({
          type: "bar",
          name: `${c.country_name} Baseline`,
          legendgroup: "base",
          showlegend: false,
          xaxis: "x2",
          yaxis: "y2",
          x: mixOutcomes.map((o) => o.label),
          y: mixEvals.map((e) => e.basePP),
          text: mixEvals.map((e) => formatEffectValue(e.basePP, true)),
          textposition: "outside",
          cliponaxis: false,
          marker: { color: "#0b2545" },
          error_y: {
            type: "data",
            array: mixEvals.map((e) => e.halfWidth80PP),
            color: "#334155",
            thickness: 2,
            width: 5
          },
          customdata: mixEvals.map((e, i) => {
            const currVal = convertToCurrencyPerPerson(e.basePP, c, mixOutcomes[i].key, 1.0);
            return [
              formatPP(e.basePP, "of total tax"),
              formatCurrencyPerPerson(currVal),
              formatNationalTotal(currVal, c),
              contextLines
            ];
          }),
          hovertemplate:
            "<b>%{x} (Country Baseline)</b><br>" +
            "Tax mix shift: <b>%{customdata[0]}</b> (equiv. %{customdata[1]})<br>" +
            "%{customdata[2]}<br>%{customdata[3]}<extra></extra>"
        });

        traces.push({
          type: "bar",
          name: "Custom Scenario",
          legendgroup: "sim",
          showlegend: false,
          xaxis: "x2",
          yaxis: "y2",
          x: mixOutcomes.map((o) => o.label),
          y: mixEvals.map((e) => e.simPP),
          text: mixEvals.map((e) => formatEffectValue(e.simPP, true)),
          textposition: "outside",
          cliponaxis: false,
          marker: { color: "#136f63" },
          error_y: {
            type: "data",
            array: mixEvals.map((e) => e.halfWidth80PP),
            color: "#0f766e",
            thickness: 2,
            width: 5
          },
          customdata: mixEvals.map((e, i) => {
            const currVal = convertToCurrencyPerPerson(e.simPP, c, mixOutcomes[i].key, e.gdpMult);
            return [
              formatPP(e.simPP, "of total tax"),
              formatCurrencyPerPerson(currVal),
              formatNationalTotal(currVal, c),
              contextLines
            ];
          }),
          hovertemplate:
            "<b>%{x} (Custom Scenario)</b><br>" +
            "Tax mix shift: <b>%{customdata[0]}</b> (equiv. %{customdata[1]})<br>" +
            "%{customdata[2]}<br>%{customdata[3]}<extra></extra>"
        });
      } else {
        // Single clean bar per outcome when sliders are at country baseline
        traces.push({
          type: "bar",
          name: `After ${h} Years (80% range)`,
          xaxis: "x",
          yaxis: "y",
          x: revOutcomes.map((o) => o.label),
          y: revEvals.map((e) => e.baseVal),
          text: revEvals.map((e) => formatEffectValue(e.baseVal)),
          textposition: "outside",
          cliponaxis: false,
          marker: { color: "#136f63" },
          error_y: {
            type: "data",
            array: revEvals.map((e) => e.errBaseVal),
            color: "#0f766e",
            thickness: 2.2,
            width: 6
          },
          customdata: revEvals.map((e, i) => {
            const currVal = convertToCurrencyPerPerson(e.basePP, c, revOutcomes[i].key, 1.0);
            return [
              formatDualEstimate(e.basePP, c, revOutcomes[i].key, 1.0),
              formatNationalTotal(currVal, c),
              contextLines
            ];
          }),
          hovertemplate:
            "<b>%{x}</b><br>" +
            "Estimated annual change: <b>%{customdata[0]}</b><br>" +
            "%{customdata[1]}<br>%{customdata[2]}<extra></extra>"
        });

        traces.push({
          type: "bar",
          name: `After ${h} Years (Tax Mix)`,
          showlegend: false,
          xaxis: "x2",
          yaxis: "y2",
          x: mixOutcomes.map((o) => o.label),
          y: mixEvals.map((e) => e.basePP),
          text: mixEvals.map((e) => formatEffectValue(e.basePP, true)),
          textposition: "outside",
          cliponaxis: false,
          marker: { color: "#0b2545" },
          error_y: {
            type: "data",
            array: mixEvals.map((e) => e.halfWidth80PP),
            color: "#334155",
            thickness: 2.2,
            width: 6
          },
          customdata: mixEvals.map((e, i) => {
            const currVal = convertToCurrencyPerPerson(e.basePP, c, mixOutcomes[i].key, 1.0);
            return [
              formatPP(e.basePP, "of total tax"),
              formatCurrencyPerPerson(currVal),
              formatNationalTotal(currVal, c),
              contextLines
            ];
          }),
          hovertemplate:
            "<b>%{x}</b><br>" +
            "Tax mix shift: <b>%{customdata[0]}</b> (equiv. %{customdata[1]})<br>" +
            "%{customdata[2]}<br>%{customdata[3]}<extra></extra>"
        });
      }
    }

    const layout = {
      barmode: "group",
      grid: { rows: 1, columns: 2, pattern: "independent" },
      margin: { t: 48, r: 28, b: 60, l: 75 },
      yaxis: {
        title: `Tax Revenue Change (${uCfg.label})`,
        zeroline: true,
        zerolinecolor: "#be123c",
        zerolinewidth: 2,
        gridcolor: "#f1f5f9"
      },
      yaxis2: {
        title: "Tax Mix Shift (pp of total tax)",
        zeroline: true,
        zerolinecolor: "#be123c",
        zerolinewidth: 2,
        gridcolor: "#f1f5f9"
      },
      annotations: [
        {
          x: 0.22,
          y: 1.07,
          xref: "paper",
          yref: "paper",
          text: "<b>Tax Revenue Mobilisation</b>",
          showarrow: false,
          font: { size: 12, color: "#0b2545" }
        },
        {
          x: 0.80,
          y: 1.07,
          xref: "paper",
          yref: "paper",
          text: "<b>Shift in Tax Mix (% of Total Tax)</b>",
          showarrow: false,
          font: { size: 12, color: "#0b2545" }
        }
      ],
      legend: { orientation: "h", y: 1.16, x: 0 },
      paper_bgcolor: "#ffffff",
      plot_bgcolor: "#ffffff"
    };

    Plotly.newPlot("t3-scenario-plot", traces, layout, {
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
