// =============================================================================
// Script: app/app.js
// Purpose: Streamlined Interactive Explorer for University Funding ROI
//          Simple by default with clear error bars; Advanced options via toggle.
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

  // Exchange rates relative to 2021 PPP USD (note: gdp_2024_eur_bn is already in EUR)
  const CURR_META = {
    EUR: { code: "EUR", symbol: "\u20ac", usdRate: 0.92, eurFactor: 1.0, label: "EUR (\u20ac)" },
    USD: { code: "USD", symbol: "$",      usdRate: 1.0,  eurFactor: 1.0 / 0.92, label: "USD ($)" },
    GBP: { code: "GBP", symbol: "\u00a3", usdRate: 0.79, eurFactor: 0.79 / 0.92, label: "GBP (\u00a3)" }
  };

  let activeCurr = "EUR";
  let activeScale = "TOTAL"; // TOTAL | PER_CAPITA | PP
  let advancedMode = false;
  let lastActiveTab = "tab1";

  const OUTCOME_META = {
    tax_gdp: {
      key: "tax_gdp",
      label: "Total Tax Revenue",
      shortLabel: "Total Tax",
      hint: "All Exchequer tax streams (income, payroll, corporate & VAT).",
      isShareOfTax: false,
      colour: "#136f63"
    },
    inc_gdp: {
      key: "inc_gdp",
      label: "Direct Income & Profit Tax",
      shortLabel: "Income Tax Only",
      hint: "Conservative floor counting direct income & corporate profit taxes alone.",
      isShareOfTax: false,
      colour: "#0b2545"
    },
    inc_share: {
      key: "inc_share",
      label: "Direct Income Tax Share",
      shortLabel: "Income Tax Share",
      hint: "Shift in direct income & profit taxes as a percentage of total tax.",
      isShareOfTax: true,
      colour: "#1d4ed8"
    },
    goods_share: {
      key: "goods_share",
      label: "Goods & VAT Tax Share",
      shortLabel: "Goods / VAT Share",
      hint: "Shift in indirect consumption & VAT taxes as a percentage of total tax.",
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

  // ===========================================================================
  // Core Math & Formatting Helpers
  // ===========================================================================
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

  function formatProb(p) {
    if (p === null || p === undefined || !Number.isFinite(Number(p))) return "N/A";
    const v = Number(p);
    if (v > 0.99) return "P > 0.99";
    if (v < 0.01) return "P < 0.01";
    return `P = ${v.toFixed(2)}`;
  }

  function getCountryGdpBn(c, customGdpBn) {
    if (Number.isFinite(customGdpBn) && customGdpBn > 0) {
      return customGdpBn;
    }
    const cm = CURR_META[activeCurr] || CURR_META.EUR;
    if (c.gdp_2024_eur_bn !== null && c.gdp_2024_eur_bn !== undefined && Number.isFinite(Number(c.gdp_2024_eur_bn))) {
      return Number(c.gdp_2024_eur_bn) * cm.eurFactor;
    }
    const gdpPc = Number(c.gdp_per_capita_latest || c.gdp_per_capita_ppp || 25000);
    const pop = Number(c.population_latest || 5e6);
    return (gdpPc * pop * cm.usdRate) / 1e9;
  }

  function formatMoneyBn(valBn, signed) {
    if (valBn === null || valBn === undefined || !Number.isFinite(Number(valBn))) return "N/A";
    const cm = CURR_META[activeCurr] || CURR_META.EUR;
    const n = Number(valBn);
    const sign = signed ? (n >= 0 ? "+" : "-") : n < 0 ? "-" : "";
    const a = Math.abs(n);
    if (a >= 10) return `${sign}${cm.symbol}${a.toFixed(1)} bn`;
    if (a >= 0.1) return `${sign}${cm.symbol}${a.toFixed(1)} bn`;
    if (a >= 0.005) return `${sign}${cm.symbol}${Math.round(a * 1000)} m`;
    return `${sign}${cm.symbol}${(a * 1000).toFixed(1)} m`;
  }

  function formatScaledAmount(ppVal, c, outKey, multFactor, customGdpBn) {
    if (ppVal === null || ppVal === undefined || !Number.isFinite(Number(ppVal))) return null;
    const meta = OUTCOME_META[outKey] || OUTCOME_META.tax_gdp;
    const m = Number.isFinite(multFactor) ? multFactor : 1.0;
    const pp = Number(ppVal) * m;

    if (activeScale === "PP" || meta.isShareOfTax) {
      return pp;
    }
    const gdpBn = getCountryGdpBn(c, customGdpBn);
    const totalBn = gdpBn * (pp / 100);
    if (activeScale === "PER_CAPITA") {
      const pop = Math.max(1e4, Number(c.population_latest || 5e6));
      return (totalBn * 1e9) / pop;
    }
    return totalBn;
  }

  function formatDisplayVal(val, isShareOrPP, signed) {
    if (val === null || val === undefined || !Number.isFinite(Number(val))) return "N/A";
    const n = Number(val);
    const sign = signed ? (n >= 0 ? "+" : "-") : n < 0 ? "-" : "";
    const a = Math.abs(n);
    if (isShareOrPP || activeScale === "PP") {
      return `${sign}${a.toFixed(2)} pp`;
    }
    const cm = CURR_META[activeCurr] || CURR_META.EUR;
    if (activeScale === "PER_CAPITA") {
      return `${sign}${cm.symbol}${Math.round(a).toLocaleString("en-GB")}`;
    }
    return formatMoneyBn(n, signed);
  }

  function computeFundingCost(c, zCode, absUnits, overrides) {
    const cm = CURR_META[activeCurr] || CURR_META.EUR;
    const ov = overrides || null;
    const gdpBn = getCountryGdpBn(c, ov ? ov.gdpBn : null);
    const rawSpend = Math.max(1.5, Number((ov && ov.spendPct) || c.tert_spend_per_student_gdp_pc || 25.0));
    const enrol = Math.max(1.0, Number((ov && ov.enrolPct) || c.gross_tert_enrolment_pct || 40.0));

    let costGdpPct;
    if (!ov && zCode === "Z1" && c.cost_plus10pp_gdp_pct !== null && Number.isFinite(Number(c.cost_plus10pp_gdp_pct))) {
      costGdpPct = Number(c.cost_plus10pp_gdp_pct) * absUnits;
    } else {
      const baseBudgetPct =
        ov && Number.isFinite(ov.budgetPct) && ov.budgetPct > 0
          ? ov.budgetPct
          : Number.isFinite(Number(c.tert_spend_gdp_pct)) && Number(c.tert_spend_gdp_pct) > 0
            ? Number(c.tert_spend_gdp_pct)
            : 0.081 * (rawSpend / 100) * (enrol / 100) * 100;

      if (zCode === "Z3") {
        costGdpPct = baseBudgetPct * (0.25 * absUnits);
      } else if (zCode === "Z4") {
        costGdpPct = 0.25 * absUnits;
      } else {
        costGdpPct = baseBudgetPct * ((10.0 * absUnits) / rawSpend);
      }
    }

    const costBn = gdpBn * (costGdpPct / 100);
    return {
      symbol: cm.symbol,
      gdpBn,
      costGdpPct,
      costBn
    };
  }

  // ===========================================================================
  // Top Header, Tabs & Global Controls
  // ===========================================================================
  const tabBtns = document.querySelectorAll(".tab-btn");
  const tabPanes = document.querySelectorAll(".tab-pane");
  const helpBtn = document.getElementById("btn-help");
  const closeHelpBtn = document.getElementById("btn-close-help");
  const advToggle = document.getElementById("adv-mode-toggle");
  const advScaleSel = document.getElementById("adv-scale-select");

  function syncMetricButtonLabels() {
    const cm = CURR_META[activeCurr] || CURR_META.EUR;
    const bcrBtn = document.querySelector('#t1-metric-group [data-metric="bcr"]');
    const curBtn = document.querySelector('#t1-metric-group [data-metric="currency"]');
    if (bcrBtn) bcrBtn.textContent = `Return per ${cm.symbol}1 (x)`;
    if (curBtn) {
      curBtn.textContent =
        activeScale === "PP"
          ? "Percentage Points"
          : activeScale === "PER_CAPITA"
            ? `${cm.symbol} per Person`
            : `Total (${cm.symbol} bn)`;
    }
    const gdpLbl = document.getElementById("t3-base-gdp-label");
    if (gdpLbl) gdpLbl.textContent = `GDP (${cm.code} bn)`;
  }

  function renderActiveTab() {
    syncMetricButtonLabels();
    if (lastActiveTab === "tab1") renderTab1();
    if (lastActiveTab === "tab2") renderTab2();
    if (lastActiveTab === "tab3") renderTab3();
  }

  function showPane(paneId) {
    tabPanes.forEach((p) => p.classList.toggle("active", p.id === paneId));
    if (paneId === "help-pane") {
      tabBtns.forEach((b) => b.classList.remove("active"));
      helpBtn.classList.add("active");
    } else {
      lastActiveTab = paneId;
      helpBtn.classList.remove("active");
      tabBtns.forEach((b) => b.classList.toggle("active", b.getAttribute("data-tab") === paneId));
      renderActiveTab();
    }
  }

  tabBtns.forEach((btn) => {
    btn.addEventListener("click", () => showPane(btn.getAttribute("data-tab")));
  });

  helpBtn.addEventListener("click", () => {
    const isHelp = document.getElementById("help-pane").classList.contains("active");
    showPane(isHelp ? lastActiveTab : "help-pane");
  });

  closeHelpBtn.addEventListener("click", () => showPane(lastActiveTab));

  document.querySelectorAll("#currency-pills .curr-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      const prevCurr = activeCurr;
      activeCurr = btn.getAttribute("data-curr") || "EUR";
      document
        .querySelectorAll("#currency-pills .curr-btn")
        .forEach((b) => b.classList.toggle("active", b === btn));

      // Rescale Tab 3 GDP input smoothly when currency switches
      if (prevCurr !== activeCurr && t3State.baseGdpBn > 0) {
        const prevMeta = CURR_META[prevCurr] || CURR_META.EUR;
        const nextMeta = CURR_META[activeCurr] || CURR_META.EUR;
        const eurVal = t3State.baseGdpBn / prevMeta.eurFactor;
        t3State.baseGdpBn = Number((eurVal * nextMeta.eurFactor).toFixed(1));
        t3State.defaultGdpBn = Number(((t3State.defaultGdpBn / prevMeta.eurFactor) * nextMeta.eurFactor).toFixed(1));
        const gdpIn = document.getElementById("t3-base-gdp");
        if (gdpIn) gdpIn.value = String(t3State.baseGdpBn);
      }
      renderActiveTab();
    });
  });

  advScaleSel.addEventListener("change", () => {
    activeScale = advScaleSel.value || "TOTAL";
    if (activeScale !== "TOTAL" && t1State.metric === "bcr") {
      t1State.metric = "currency";
      document
        .querySelectorAll("#t1-metric-group .seg-btn")
        .forEach((b) => b.classList.toggle("active", b.getAttribute("data-metric") === "currency"));
    }
    renderActiveTab();
  });

  advToggle.addEventListener("change", () => {
    advancedMode = Boolean(advToggle.checked);
    document.body.classList.toggle("advanced-mode", advancedMode);

    if (!advancedMode) {
      // Return cleanly to streamlined defaults when Advanced Mode is turned off
      activeScale = "TOTAL";
      advScaleSel.value = "TOTAL";

      if (t1State.outcome === "inc_share" || t1State.outcome === "goods_share") {
        t1State.outcome = "tax_gdp";
        document.getElementById("t1-adv-outcome").value = "tax_gdp";
        syncTab1SimpleOutcomeButtons();
      }
      t1State.horizon = "career";
      t1State.careerMult = 8.0;
      t1State.scatterX = "enrolment";
      document.getElementById("t1-horizon-select").value = "career";
      document.getElementById("t1-accounting-select").value = "8.0";
      document.getElementById("t1-scatter-x-select").value = "enrolment";

      if (t2State.mode !== "levels") {
        t2State.mode = "levels";
        document
          .querySelectorAll("#t2-mode-group .seg-btn")
          .forEach((b) => b.classList.toggle("active", b.getAttribute("data-mode") === "levels"));
        populateTab2AxisMenus();
      }

      t3State.zMeasure = "Z1";
      t3State.careerMult = 8.0;
      document.getElementById("t3-z-select").value = "Z1";
      document.getElementById("t3-accounting-select").value = "8.0";
      loadCountryDefaultsIntoTab3(t3State.iso3);
    }

    renderActiveTab();
  });

  // ===========================================================================
  // TAB 1: Compare Countries
  // ===========================================================================
  const t1State = {
    outcome: "tax_gdp",
    horizon: "career", // career | 10 | 5 | both
    careerMult: 8.0,
    view: "ranking", // ranking | scatter
    metric: "bcr", // bcr | currency
    scatterX: "enrolment",
    selectedIsos: ["IRL", "GBR", "DEU", "USA", "NOR", "AUS", "COL", "ZAF"],
    searchQuery: ""
  };

  const t1Presets = {
    default: ["IRL", "GBR", "DEU", "USA", "NOR", "AUS", "COL", "ZAF"],
    europe: ["IRL", "GBR", "DEU", "FRA", "NOR", "SWE", "AUT", "ESP"],
    oecd: COUNTRIES.filter((c) => c.is_oecd === 1 && c.in_policy_2024).map((c) => c.iso3),
    emerging: ["CHL", "COL", "MEX", "BRA", "ZAF", "MYS", "BGD", "RWA"],
    all: COUNTRIES.filter((c) => c.in_policy_2024).map((c) => c.iso3),
    clear: []
  };

  function syncTab1SimpleOutcomeButtons() {
    document.querySelectorAll("#t1-simple-outcome .seg-btn").forEach((b) => {
      b.classList.toggle("active", b.getAttribute("data-out") === t1State.outcome);
    });
    const meta = OUTCOME_META[t1State.outcome] || OUTCOME_META.tax_gdp;
    const hintEl = document.getElementById("t1-outcome-hint");
    if (hintEl) hintEl.textContent = meta.hint;
  }

  function computeCountryTab1Stats(c, outKey) {
    const meta = OUTCOME_META[outKey] || OUTCOME_META.tax_gdp;
    const pp10 = c[`tau10_${outKey}`];
    if (pp10 === null || pp10 === undefined || !Number.isFinite(Number(pp10))) {
      return null;
    }

    const ppMean = Number(pp10);
    const ppL80 = c[`tau10_${outKey}_low80`] !== null ? Number(c[`tau10_${outKey}_low80`]) : ppMean - 0.22;
    const ppH80 = c[`tau10_${outKey}_high80`] !== null ? Number(c[`tau10_${outKey}_high80`]) : ppMean + 0.22;
    const ppL95 = c[`tau10_${outKey}_low95`] !== null ? Number(c[`tau10_${outKey}_low95`]) : ppMean - 0.36;
    const ppH95 = c[`tau10_${outKey}_high95`] !== null ? Number(c[`tau10_${outKey}_high95`]) : ppMean + 0.36;
    const ppSd =
      c[`tau10_${outKey}_sd`] !== null && Number.isFinite(Number(c[`tau10_${outKey}_sd`]))
        ? Number(c[`tau10_${outKey}_sd`])
        : Math.max(0.02, Math.abs(ppH95 - ppL95) / 3.92);

    const cost = computeFundingCost(c, "Z1", 1.0, null);
    const mult = meta.isShareOfTax ? 1.0 : t1State.careerMult;

    const careerMeanBn = mult * cost.gdpBn * (ppMean / 100);
    const careerL80Bn = mult * cost.gdpBn * (ppL80 / 100);
    const careerH80Bn = mult * cost.gdpBn * (ppH80 / 100);
    const careerL95Bn = mult * cost.gdpBn * (ppL95 / 100);
    const careerH95Bn = mult * cost.gdpBn * (ppH95 / 100);
    const careerSdBn = Math.max(0.0005, mult * cost.gdpBn * (ppSd / 100));

    const hasBcr = !meta.isShareOfTax && cost.costBn > 0;
    const bcr = hasBcr ? careerMeanBn / cost.costBn : null;
    const bcrL80 = hasBcr ? careerL80Bn / cost.costBn : null;
    const bcrH80 = hasBcr ? careerH80Bn / cost.costBn : null;
    const bcrL95 = hasBcr ? careerL95Bn / cost.costBn : null;
    const bcrH95 = hasBcr ? careerH95Bn / cost.costBn : null;

    let probNet = hasBcr
      ? normCdf((careerMeanBn - cost.costBn) / careerSdBn)
      : normCdf(ppMean / Math.max(0.001, ppSd));

    // Use exact posterior draw probability from table when at standard 8.0x baseline
    if (mult === 8.0 && outKey === "tax_gdp" && Number.isFinite(Number(c.prob_net_pos_y1))) {
      probNet = Number(c.prob_net_pos_y1);
    } else if (mult === 8.0 && outKey === "inc_gdp" && Number.isFinite(Number(c.prob_net_pos_y2))) {
      probNet = Number(c.prob_net_pos_y2);
    }

    return {
      costBn: cost.costBn,
      costGdpPct: cost.costGdpPct,
      costScaled: formatScaledAmount(cost.costGdpPct, c, "tax_gdp", 1.0, null),
      meanScaled: formatScaledAmount(ppMean, c, outKey, mult, null),
      low80Scaled: formatScaledAmount(ppL80, c, outKey, mult, null),
      high80Scaled: formatScaledAmount(ppH80, c, outKey, mult, null),
      low95Scaled: formatScaledAmount(ppL95, c, outKey, mult, null),
      high95Scaled: formatScaledAmount(ppH95, c, outKey, mult, null),
      careerMeanBn,
      careerL95Bn,
      careerH95Bn,
      bcr,
      bcrL80,
      bcrH80,
      bcrL95,
      bcrH95,
      ppMean,
      ppL95,
      ppH95,
      probNet
    };
  }

  function buildTab1CountryList() {
    const box = document.getElementById("t1-country-list");
    const q = t1State.searchQuery.trim().toLowerCase();
    box.innerHTML = "";

    const filtered = COUNTRIES.filter((c) => {
      if (!q) return true;
      return c.country_name.toLowerCase().includes(q) || c.iso3.toLowerCase().includes(q);
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
          if (!t1State.selectedIsos.includes(c.iso3)) t1State.selectedIsos.push(c.iso3);
        } else {
          t1State.selectedIsos = t1State.selectedIsos.filter((x) => x !== c.iso3);
        }
        document.getElementById("t1-selected-count").textContent = `${t1State.selectedIsos.length} selected`;
        renderTab1();
      });
      box.appendChild(div);
    });

    document.getElementById("t1-selected-count").textContent = `${t1State.selectedIsos.length} selected`;
  }

  function downloadTab1Csv() {
    const selected = t1State.selectedIsos.map((iso) => COUNTRY_MAP[iso]).filter(Boolean);
    const outKey = t1State.outcome;
    const cm = CURR_META[activeCurr] || CURR_META.EUR;
    const lines = [
      [
        "iso3",
        "country_name",
        "income_group",
        "enrolment_pct",
        `cohort_cost_${cm.code.toLowerCase()}_bn`,
        `career_return_mean_${cm.code.toLowerCase()}_bn`,
        `career_return_low95_${cm.code.toLowerCase()}_bn`,
        `career_return_high95_${cm.code.toLowerCase()}_bn`,
        "roi_multiplier_x",
        "roi_low95_x",
        "roi_high95_x",
        "prob_net_gain"
      ].join(",")
    ];

    selected.forEach((c) => {
      const st = computeCountryTab1Stats(c, outKey);
      if (!st) return;
      lines.push(
        [
          c.iso3,
          `"${c.country_name}"`,
          `"${c.income_group || ""}"`,
          Number(c.gross_tert_enrolment_pct || 0).toFixed(1),
          st.costBn.toFixed(2),
          st.careerMeanBn.toFixed(2),
          st.careerL95Bn.toFixed(2),
          st.careerH95Bn.toFixed(2),
          st.bcr !== null ? st.bcr.toFixed(2) : "",
          st.bcrL95 !== null ? st.bcrL95.toFixed(2) : "",
          st.bcrH95 !== null ? st.bcrH95.toFixed(2) : "",
          st.probNet.toFixed(3)
        ].join(",")
      );
    });

    const blob = new Blob([lines.join("\n")], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `university_funding_roi_${outKey}_${cm.code.toLowerCase()}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }

  function initTab1Controls() {
    document.querySelectorAll("#t1-simple-outcome .seg-btn").forEach((btn) => {
      btn.addEventListener("click", () => {
        t1State.outcome = btn.getAttribute("data-out");
        document.getElementById("t1-adv-outcome").value = t1State.outcome;
        syncTab1SimpleOutcomeButtons();
        renderTab1();
      });
    });

    const advOut = document.getElementById("t1-adv-outcome");
    advOut.addEventListener("change", () => {
      t1State.outcome = advOut.value;
      syncTab1SimpleOutcomeButtons();
      renderTab1();
    });

    const hSel = document.getElementById("t1-horizon-select");
    hSel.addEventListener("change", () => {
      t1State.horizon = hSel.value || "career";
      document.getElementById("t1-accounting-wrap").style.display =
        t1State.horizon === "career" ? "block" : "none";
      renderTab1();
    });

    const accSel = document.getElementById("t1-accounting-select");
    accSel.addEventListener("change", () => {
      t1State.careerMult = Number(accSel.value || 8.0);
      renderTab1();
    });

    document.querySelectorAll("#t1-view-group .seg-btn").forEach((btn) => {
      btn.addEventListener("click", () => {
        document
          .querySelectorAll("#t1-view-group .seg-btn")
          .forEach((b) => b.classList.toggle("active", b === btn));
        t1State.view = btn.getAttribute("data-view");
        document.getElementById("t1-scatter-axes-wrap").style.display =
          t1State.view === "scatter" ? "block" : "none";
        renderTab1();
      });
    });

    document.querySelectorAll("#t1-metric-group .seg-btn").forEach((btn) => {
      btn.addEventListener("click", () => {
        document
          .querySelectorAll("#t1-metric-group .seg-btn")
          .forEach((b) => b.classList.toggle("active", b === btn));
        t1State.metric = btn.getAttribute("data-metric");
        renderTab1();
      });
    });

    const sxSel = document.getElementById("t1-scatter-x-select");
    sxSel.addEventListener("change", () => {
      t1State.scatterX = sxSel.value || "enrolment";
      renderTab1();
    });

    document.querySelectorAll("[data-preset]").forEach((btn) => {
      btn.addEventListener("click", () => {
        const key = btn.getAttribute("data-preset");
        document.querySelectorAll("[data-preset]").forEach((b) => b.classList.toggle("active", b === btn));
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

    document.getElementById("t1-download-btn").addEventListener("click", downloadTab1Csv);

    syncTab1SimpleOutcomeButtons();
    buildTab1CountryList();
  }

  function renderTab1Scatter(plotDiv, selected, outKey, meta) {
    const useBcr = t1State.metric === "bcr" && !meta.isShareOfTax && activeScale === "TOTAL";
    const xKey = t1State.scatterX || "enrolment";
    const cm = CURR_META[activeCurr] || CURR_META.EUR;

    const xMeta = {
      enrolment: {
        title: "Current Share of Young Adults in Tertiary Education (%)",
        get: (c) => Number(c.gross_tert_enrolment_pct),
        fmt: (v) => `${Number(v).toFixed(0)}% enrolment`
      },
      Z1: {
        title: "Per-Student University Spending (% of GDP per Person)",
        get: (c) => Number(c.tert_spend_per_student_gdp_pc),
        fmt: (v) => `${Number(v).toFixed(1)}% of GDP/person`
      },
      Z3: {
        title: "Real Per-Student University Spending (2021 PPP USD)",
        get: (c) => Number(c.real_tert_spend_per_student_ppp),
        fmt: (v) => `$${Math.round(Number(v)).toLocaleString("en-GB")} PPP`
      },
      Z4: {
        title: "Total University Budget (% of GDP)",
        get: (c) => Number(c.tert_spend_gdp_pct),
        fmt: (v) => `${Number(v).toFixed(2)}% of GDP`
      }
    }[xKey];

    const pts = selected
      .map((c) => {
        const st = computeCountryTab1Stats(c, outKey);
        if (!st) return null;
        const xVal = xMeta.get(c);
        if (!Number.isFinite(xVal) || xVal <= 0) return null;
        const yMean = useBcr ? st.bcr : st.meanScaled;
        const yL95 = useBcr ? st.bcrL95 : st.low95Scaled;
        const yH95 = useBcr ? st.bcrH95 : st.high95Scaled;
        if (!Number.isFinite(Number(yMean))) return null;
        return { c, st, xVal, yMean, yL95, yH95 };
      })
      .filter(Boolean);

    if (pts.length === 0) {
      Plotly.purge(plotDiv);
      plotDiv.innerHTML = `<div style="padding:4rem;text-align:center;color:#64748b;">Select countries on the left to view the chart.</div>`;
      return;
    }

    document.getElementById("t1-chart-title").textContent = useBcr
      ? `${meta.label}: Expected 40-Year Return per ${cm.symbol}1 Spent vs Enrolment`
      : `${meta.label}: Expected 40-Year Return vs Enrolment`;
    document.getElementById("t1-chart-subtitle").textContent =
      "Points show posterior mean; vertical bars show 95% credible intervals.";

    const traces = [];

    // Smooth log-trend diminishing returns curve when plotting Enrolment vs ROI Multiplier
    if (useBcr && xKey === "enrolment" && pts.length >= 4) {
      const xs = pts.map((p) => Math.log(Math.max(2, p.xVal)));
      const ys = pts.map((p) => p.yMean);
      const n = xs.length;
      const mx = xs.reduce((a, b) => a + b, 0) / n;
      const my = ys.reduce((a, b) => a + b, 0) / n;
      let num = 0;
      let den = 0;
      for (let i = 0; i < n; i++) {
        num += (xs[i] - mx) * (ys[i] - my);
        den += (xs[i] - mx) * (xs[i] - mx);
      }
      if (den > 1e-6) {
        const slope = num / den;
        const intercept = my - slope * mx;
        const minX = Math.max(5, Math.min(...pts.map((p) => p.xVal)));
        const maxX = Math.max(...pts.map((p) => p.xVal));
        const gridX = [];
        const gridY = [];
        for (let k = 0; k <= 40; k++) {
          const xv = minX + ((maxX - minX) * k) / 40;
          gridX.push(xv);
          gridY.push(intercept + slope * Math.log(xv));
        }
        traces.push({
          type: "scatter",
          mode: "lines",
          name: "Diminishing-returns trend",
          x: gridX,
          y: gridY,
          line: { color: "rgba(19, 111, 99, 0.45)", width: 2.2, dash: "dot" },
          hoverinfo: "skip"
        });
      }
    }

    traces.push({
      type: "scatter",
      mode: pts.length <= 28 ? "markers+text" : "markers",
      name: "Country estimate (95% CI)",
      x: pts.map((p) => p.xVal),
      y: pts.map((p) => p.yMean),
      text: pts.map((p) => p.c.iso3),
      textposition: "top center",
      textfont: { size: 10.5, color: "#0f172a", weight: "bold" },
      marker: {
        color: meta.colour,
        size: 10.5,
        line: { color: "#ffffff", width: 1.3 }
      },
      error_y: {
        type: "data",
        symmetric: false,
        array: pts.map((p) => Math.max(0, p.yH95 - p.yMean)),
        arrayminus: pts.map((p) => Math.max(0, p.yMean - p.yL95)),
        color: "rgba(15, 23, 42, 0.32)",
        thickness: 1.7,
        width: 4
      },
      customdata: pts.map((p) => [
        p.c.country_name,
        xMeta.fmt(p.xVal),
        formatMoneyBn(p.st.costBn, false),
        formatMoneyBn(p.st.careerMeanBn, true),
        p.st.bcr !== null ? `${p.st.bcr.toFixed(1)}x` : "N/A",
        useBcr
          ? `[${p.yL95.toFixed(1)}x, ${p.yH95.toFixed(1)}x]`
          : `[${formatDisplayVal(p.yL95, meta.isShareOfTax, true)}, ${formatDisplayVal(p.yH95, meta.isShareOfTax, true)}]`,
        formatProb(p.st.probNet)
      ]),
      hovertemplate:
        "<b>%{customdata[0]}</b> (%{customdata[1]})<br>" +
        "Cohort cost: <b>%{customdata[2]}</b><br>" +
        "Expected 40-yr return: <b>%{customdata[3]}</b> (%{customdata[4]})<br>" +
        "95% range: %{customdata[5]}<br>" +
        "Chance of net gain: <b>%{customdata[6]}</b><extra></extra>"
    });

    const shapes = [
      {
        type: "line",
        xref: "paper",
        x0: 0,
        x1: 1,
        y0: 0,
        y1: 0,
        line: { color: "#be123c", width: 1.4, dash: "dot" }
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
        line: { color: "#0b2545", width: 1.8, dash: "dash" }
      });
      annotations.push({
        xref: "paper",
        yref: "y",
        x: 0.99,
        y: 1.0,
        yshift: 10,
        xanchor: "right",
        text: "Break-even (1.0x)",
        showarrow: false,
        font: { size: 11, color: "#0b2545", weight: "bold" }
      });
    }

    Plotly.newPlot(
      plotDiv,
      traces,
      {
        margin: { t: 22, r: 28, b: 56, l: 70 },
        xaxis: {
          title: xMeta.title,
          type: xKey === "Z3" && pts.length > 6 ? "log" : "linear",
          gridcolor: "#f1f5f9",
          zeroline: false
        },
        yaxis: {
          title: useBcr
            ? `Expected 40-Year Return per ${cm.symbol}1 Spent (x)`
            : `Expected 40-Year Return (${cm.code})`,
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
    const plotDiv = document.getElementById("t1-main-plot");
    const outKey = t1State.outcome;
    const meta = OUTCOME_META[outKey] || OUTCOME_META.tax_gdp;
    const cm = CURR_META[activeCurr] || CURR_META.EUR;

    // Hide metric toggle when viewing share outcomes or annual horizons
    const metricGroup = document.getElementById("t1-metric-group");
    if (metricGroup) {
      metricGroup.style.display =
        t1State.horizon === "career" && !meta.isShareOfTax && activeScale === "TOTAL"
          ? "inline-flex"
          : "none";
    }

    const selected = t1State.selectedIsos.map((iso) => COUNTRY_MAP[iso]).filter(Boolean);
    if (selected.length === 0) {
      Plotly.purge(plotDiv);
      plotDiv.innerHTML = `<div style="padding:4rem;text-align:center;color:#64748b;">Select one or more countries on the left to compare returns.</div>`;
      return;
    }

    plotDiv.innerHTML = "";

    // View 2: Scatter plot (Enrolment vs ROI)
    if (t1State.view === "scatter" && t1State.horizon === "career") {
      renderTab1Scatter(plotDiv, selected, outKey, meta);
      return;
    }

    // View 1A: 40-Year Career Country Ranking (Default)
    if (t1State.horizon === "career") {
      const useBcr = t1State.metric === "bcr" && !meta.isShareOfTax && activeScale === "TOTAL";
      const rows = selected
        .map((c) => {
          const st = computeCountryTab1Stats(c, outKey);
          if (!st) return null;
          const mean = useBcr ? st.bcr : st.meanScaled;
          const l80 = useBcr ? st.bcrL80 : st.low80Scaled;
          const h80 = useBcr ? st.bcrH80 : st.high80Scaled;
          const l95 = useBcr ? st.bcrL95 : st.low95Scaled;
          const h95 = useBcr ? st.bcrH95 : st.high95Scaled;
          return { c, st, mean, l80, h80, l95, h95 };
        })
        .filter((r) => r && Number.isFinite(Number(r.mean)))
        .sort((a, b) => a.mean - b.mean);

      if (rows.length === 0) {
        Plotly.purge(plotDiv);
        plotDiv.innerHTML = `<div style="padding:4rem;text-align:center;color:#64748b;">No 10-year horizon data available for the selected countries.</div>`;
        return;
      }

      document.getElementById("t1-chart-title").textContent = useBcr
        ? `${meta.label}: Expected 40-Year Return per ${cm.symbol}1 Invested`
        : meta.isShareOfTax
          ? `${meta.label}: Expected 10-Year Shift (+10 pp Per-Student Boost)`
          : `${meta.label}: Expected 40-Year Return vs Cohort Cost`;

      document.getElementById("t1-chart-subtitle").textContent = useBcr
        ? "Dots show expected return; thick & thin bars show 80% & 95% credible intervals; dashed line marks break-even (1.0x)."
        : !meta.isShareOfTax && activeScale === "TOTAL"
          ? "Dots & bars show expected 40-year return (80% & 95% intervals); gold diamonds show upfront cohort cost."
          : "Dots show posterior mean; thick & thin bars show 80% & 95% credible intervals.";

      const yLabels = rows.map((r) => r.c.country_name);
      const dynamicHeight = Math.max(460, rows.length * 36 + 110);
      plotDiv.style.height = `${dynamicHeight}px`;

      const trace95 = {
        type: "scatter",
        mode: "markers",
        name: "95% interval",
        y: yLabels,
        x: rows.map((r) => r.mean),
        marker: { color: "rgba(0,0,0,0)", size: 1 },
        error_x: {
          type: "data",
          symmetric: false,
          array: rows.map((r) => Math.max(0, r.h95 - r.mean)),
          arrayminus: rows.map((r) => Math.max(0, r.mean - r.l95)),
          color: "#94a3b8",
          thickness: 1.6,
          width: 0
        },
        hoverinfo: "skip"
      };

      const trace80 = {
        type: "scatter",
        mode: "markers",
        name: "Expected return & 80% interval",
        y: yLabels,
        x: rows.map((r) => r.mean),
        marker: { color: meta.colour, size: 11.5, symbol: "circle" },
        error_x: {
          type: "data",
          symmetric: false,
          array: rows.map((r) => Math.max(0, r.h80 - r.mean)),
          arrayminus: rows.map((r) => Math.max(0, r.mean - r.l80)),
          color: meta.colour,
          thickness: 3.8,
          width: 5
        },
        customdata: rows.map((r) => [
          formatMoneyBn(r.st.costBn, false),
          formatMoneyBn(r.st.careerMeanBn, true),
          r.st.bcr !== null ? `${r.st.bcr.toFixed(1)}x` : "N/A",
          useBcr
            ? `[${r.l95.toFixed(1)}x, ${r.h95.toFixed(1)}x]`
            : `[${formatDisplayVal(r.l95, meta.isShareOfTax, true)}, ${formatDisplayVal(r.h95, meta.isShareOfTax, true)}]`,
          formatProb(r.st.probNet)
        ]),
        hovertemplate:
          "<b>%{y}</b><br>" +
          "Cohort cost: <b>%{customdata[0]}</b><br>" +
          "Expected 40-yr return: <b>%{customdata[1]}</b> (%{customdata[2]})<br>" +
          "95% range: %{customdata[3]}<br>" +
          "Chance of net gain: <b>%{customdata[4]}</b><extra></extra>"
      };

      const traces = [trace95, trace80];

      if (!useBcr && !meta.isShareOfTax && activeScale === "TOTAL") {
        traces.push({
          type: "scatter",
          mode: "markers",
          name: "Cohort upfront cost",
          y: yLabels,
          x: rows.map((r) => r.st.costScaled),
          marker: {
            color: "#f59e0b",
            size: 11,
            symbol: "diamond",
            line: { color: "#78350f", width: 1.4 }
          },
          customdata: rows.map((r) => formatMoneyBn(r.st.costBn, false)),
          hovertemplate: "<b>%{y}</b><br>Cohort upfront cost: <b>%{customdata}</b><extra></extra>"
        });
      }

      const shapes = [
        {
          type: "line",
          x0: 0,
          x1: 0,
          y0: -0.5,
          y1: Math.max(0.5, yLabels.length - 0.5),
          line: { color: "#be123c", width: 1.6, dash: "dot" }
        }
      ];

      const annotations = [];
      if (useBcr) {
        shapes.push({
          type: "line",
          x0: 1.0,
          x1: 1.0,
          y0: -0.5,
          y1: Math.max(0.5, yLabels.length - 0.5),
          line: { color: "#0b2545", width: 2.0, dash: "dash" }
        });
        annotations.push({
          x: 1.0,
          y: 1.03,
          xref: "x",
          yref: "paper",
          text: "Break-even (1x)",
          showarrow: false,
          font: { size: 11, color: "#0b2545", weight: "bold" }
        });
      }

      if (rows.length <= 22) {
        rows.forEach((r) => {
          const txt = useBcr
            ? `<b>${r.mean.toFixed(1)}x</b>`
            : `<b>${formatDisplayVal(r.mean, meta.isShareOfTax, true)}</b>`;
          annotations.push({
            x: r.mean,
            y: r.c.country_name,
            xref: "x",
            yref: "y",
            text: txt,
            yshift: 13,
            showarrow: false,
            font: { size: 10.5, color: "#0f172a" }
          });
        });
      }

      const xAxisTitle = useBcr
        ? `Expected 40-Year Tax Return per ${cm.symbol}1 Spent (x)`
        : meta.isShareOfTax || activeScale === "PP"
          ? "Percentage Points (pp)"
          : activeScale === "PER_CAPITA"
            ? `${cm.symbol} per Person`
            : `Cumulative 40-Year Tax Return (${cm.symbol} billion)`;

      Plotly.newPlot(
        plotDiv,
        traces,
        {
          margin: { t: 36, r: 32, b: 56, l: 145 },
          xaxis: { title: xAxisTitle, gridcolor: "#f1f5f9", zeroline: false },
          yaxis: { automargin: true },
          shapes,
          annotations,
          legend: { orientation: "h", y: 1.08, x: 0 },
          paper_bgcolor: "#ffffff",
          plot_bgcolor: "#ffffff"
        },
        { responsive: true, displayModeBar: false }
      );
      return;
    }

    // View 1B (Advanced): Annual 5y, 10y, or 5 vs 10y Flow
    plotDiv.style.height = `${Math.max(460, selected.length * 36 + 110)}px`;
    if (t1State.horizon === "both") {
      document.getElementById("t1-chart-title").textContent =
        `${meta.label}: Annual Change After 5 Years vs 10 Years`;
      document.getElementById("t1-chart-subtitle").textContent =
        "Bars show 80% credible intervals for annual revenue flow.";

      const rows = selected
        .map((c) => ({
          c,
          m5: formatScaledAmount(c[`tau5_${outKey}`], c, outKey, 1, null),
          l5: formatScaledAmount(c[`tau5_${outKey}_low80`], c, outKey, 1, null),
          h5: formatScaledAmount(c[`tau5_${outKey}_high80`], c, outKey, 1, null),
          m10: formatScaledAmount(c[`tau10_${outKey}`], c, outKey, 1, null),
          l10: formatScaledAmount(c[`tau10_${outKey}_low80`], c, outKey, 1, null),
          h10: formatScaledAmount(c[`tau10_${outKey}_high80`], c, outKey, 1, null)
        }))
        .sort((a, b) => (a.m10 ?? a.m5 ?? -1e9) - (b.m10 ?? b.m5 ?? -1e9));

      const y5 = rows.map((_, i) => i - 0.16);
      const y10 = rows.map((_, i) => i + 0.16);

      Plotly.newPlot(
        plotDiv,
        [
          {
            type: "scatter",
            mode: "markers",
            name: "After 5 Years (80% CI)",
            y: y5,
            x: rows.map((r) => r.m5),
            marker: { color: "#0b2545", size: 9.5 },
            error_x: {
              type: "data",
              symmetric: false,
              array: rows.map((r) => (r.m5 !== null && r.h5 !== null ? r.h5 - r.m5 : 0)),
              arrayminus: rows.map((r) => (r.m5 !== null && r.l5 !== null ? r.m5 - r.l5 : 0)),
              color: "#0b2545",
              thickness: 2.5,
              width: 4
            }
          },
          {
            type: "scatter",
            mode: "markers",
            name: "After 10 Years (80% CI)",
            y: y10,
            x: rows.map((r) => r.m10),
            marker: { color: "#136f63", size: 10.5, symbol: "diamond" },
            error_x: {
              type: "data",
              symmetric: false,
              array: rows.map((r) => (r.m10 !== null && r.h10 !== null ? r.h10 - r.m10 : 0)),
              arrayminus: rows.map((r) => (r.m10 !== null && r.l10 !== null ? r.m10 - r.l10 : 0)),
              color: "#136f63",
              thickness: 2.6,
              width: 4
            }
          }
        ],
        {
          margin: { t: 36, r: 30, b: 56, l: 145 },
          xaxis: { title: "Estimated Annual Change", gridcolor: "#f1f5f9", zeroline: true, zerolinecolor: "#be123c" },
          yaxis: {
            tickmode: "array",
            tickvals: rows.map((_, i) => i),
            ticktext: rows.map((r) => r.c.country_name),
            automargin: true
          },
          legend: { orientation: "h", y: 1.08, x: 0 },
          paper_bgcolor: "#ffffff",
          plot_bgcolor: "#ffffff"
        },
        { responsive: true, displayModeBar: false }
      );
      return;
    }

    const h = Number(t1State.horizon);
    const pref = h === 5 ? "tau5_" : "tau10_";
    document.getElementById("t1-chart-title").textContent =
      `${meta.label}: Annual Change After ${h} Years`;
    document.getElementById("t1-chart-subtitle").textContent =
      "Thick & thin bars show 80% & 95% credible intervals.";

    const rows = selected
      .map((c) => ({
        c,
        m: formatScaledAmount(c[`${pref}${outKey}`], c, outKey, 1, null),
        l80: formatScaledAmount(c[`${pref}${outKey}_low80`], c, outKey, 1, null),
        h80: formatScaledAmount(c[`${pref}${outKey}_high80`], c, outKey, 1, null),
        l95: formatScaledAmount(c[`${pref}${outKey}_low95`], c, outKey, 1, null),
        h95: formatScaledAmount(c[`${pref}${outKey}_high95`], c, outKey, 1, null)
      }))
      .filter((r) => r.m !== null)
      .sort((a, b) => a.m - b.m);

    const yLabels = rows.map((r) => r.c.country_name);
    Plotly.newPlot(
      plotDiv,
      [
        {
          type: "scatter",
          mode: "markers",
          name: "95% interval",
          y: yLabels,
          x: rows.map((r) => r.m),
          marker: { color: "rgba(0,0,0,0)", size: 1 },
          error_x: {
            type: "data",
            symmetric: false,
            array: rows.map((r) => Math.max(0, r.h95 - r.m)),
            arrayminus: rows.map((r) => Math.max(0, r.m - r.l95)),
            color: "#94a3b8",
            thickness: 1.6,
            width: 0
          },
          hoverinfo: "skip"
        },
        {
          type: "scatter",
          mode: "markers",
          name: "Posterior mean & 80% interval",
          y: yLabels,
          x: rows.map((r) => r.m),
          marker: { color: meta.colour, size: 11 },
          error_x: {
            type: "data",
            symmetric: false,
            array: rows.map((r) => Math.max(0, r.h80 - r.m)),
            arrayminus: rows.map((r) => Math.max(0, r.m - r.l80)),
            color: meta.colour,
            thickness: 3.6,
            width: 5
          }
        }
      ],
      {
        margin: { t: 36, r: 30, b: 56, l: 145 },
        xaxis: { title: "Estimated Annual Change", gridcolor: "#f1f5f9", zeroline: true, zerolinecolor: "#be123c" },
        yaxis: { automargin: true },
        legend: { orientation: "h", y: 1.08, x: 0 },
        paper_bgcolor: "#ffffff",
        plot_bgcolor: "#ffffff"
      },
      { responsive: true, displayModeBar: false }
    );
  }

  // ===========================================================================
  // TAB 2: Historical Data
  // ===========================================================================
  const t2State = {
    mode: "levels",
    view: "bubbles", // bubbles | trends
    xVar: "tert_spend_per_student_winsor",
    yVar: "income_profit_tax_share_rev_pct",
    wave: 8,
    playing: false,
    timer: null,
    selectedIsos: ["IRL", "GBR", "NOR", "CHL", "AUT", "ZAF"],
    searchQuery: ""
  };

  const T2_AXIS_OPTIONS = {
    levels: {
      x: [
        { value: "tert_spend_per_student_winsor", label: "Per-Student Spending (% of GDP/person)" },
        { value: "real_tert_spend_per_student_ppp", label: "Real Dollars per Student (2021 PPP)" },
        { value: "tert_spend_gdp_pct", label: "Total University Budget (% of GDP)" },
        { value: "gross_tert_enrolment_pct", label: "Tertiary Enrolment (%)" }
      ],
      y: [
        { value: "income_profit_tax_share_rev_pct", label: "Income Tax Share (% of total tax)" },
        { value: "non_resource_tax_gdp_pct", label: "Total Tax Revenue (% of GDP)" },
        { value: "inc_tax_gdp_pct", label: "Income Tax Revenue (% of GDP)" },
        { value: "goods_services_tax_share_rev_pct", label: "Goods & VAT Share (% of total tax)" }
      ]
    },
    changes: {
      x: [
        { value: "tert_spend_abs_change", label: "5-Yr Change in Per-Student Spend (pp)" },
        { value: "d_log_real_spend_stu_pct", label: "5-Yr % Change in Real Spend per Student" },
        { value: "d_tert_spend_gdp_pp", label: "5-Yr Change in University Budget (pp)" }
      ],
      y: [
        { value: "d_prev_inc_tax_share_pp", label: "5-Yr Change in Income Tax Share (pp)" },
        { value: "d_prev_nonres_tax_gdp_pp", label: "5-Yr Change in Total Tax (% GDP, pp)" },
        { value: "d_prev_inc_tax_gdp_pp", label: "5-Yr Change in Income Tax (% GDP, pp)" },
        { value: "d_prev_goods_tax_share_pp", label: "5-Yr Change in Goods / VAT Share (pp)" }
      ]
    }
  };

  const t2VarLabels = {};
  Object.values(T2_AXIS_OPTIONS).forEach((grp) => {
    grp.x.forEach((o) => {
      t2VarLabels[o.value] = o.label;
    });
    grp.y.forEach((o) => {
      t2VarLabels[o.value] = o.label;
    });
  });

  const t2Presets = {
    default: ["IRL", "GBR", "NOR", "CHL", "AUT", "ZAF"],
    risers: ["NOR", "CHL", "AUT", "DNK", "MEX"],
    decliners: ["IRL", "LTU", "COL", "ZAF", "SWE"],
    trap: ["IRL", "CHL", "NOR", "AUT", "ETH", "MWI"],
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

    t2State.xVar = opts.x.some((o) => o.value === t2State.xVar) ? t2State.xVar : opts.x[0].value;
    t2State.yVar = opts.y.some((o) => o.value === t2State.yVar) ? t2State.yVar : opts.y[0].value;
    xSel.value = t2State.xVar;
    ySel.value = t2State.yVar;
  }

  function buildTab2CountryList() {
    const box = document.getElementById("t2-country-list");
    const q = t2State.searchQuery.trim().toLowerCase();
    box.innerHTML = "";

    COUNTRIES.filter((c) => !q || c.country_name.toLowerCase().includes(q) || c.iso3.toLowerCase().includes(q)).forEach((c) => {
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
          if (!t2State.selectedIsos.includes(c.iso3)) t2State.selectedIsos.push(c.iso3);
        } else {
          t2State.selectedIsos = t2State.selectedIsos.filter((x) => x !== c.iso3);
        }
        document.getElementById("t2-selected-count").textContent = `${t2State.selectedIsos.length} selected`;
        renderTab2();
      });
      box.appendChild(div);
    });

    document.getElementById("t2-selected-count").textContent = `${t2State.selectedIsos.length} selected`;
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
    }, 1050);
  }

  function initTab2Controls() {
    populateTab2AxisMenus();

    document.getElementById("t2-x-select").addEventListener("change", (e) => {
      t2State.xVar = e.target.value;
      renderTab2();
    });

    document.getElementById("t2-y-select").addEventListener("change", (e) => {
      t2State.yVar = e.target.value;
      renderTab2();
    });

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

    document.querySelectorAll("#t2-view-group .seg-btn").forEach((btn) => {
      btn.addEventListener("click", () => {
        document
          .querySelectorAll("#t2-view-group .seg-btn")
          .forEach((b) => b.classList.toggle("active", b === btn));
        t2State.view = btn.getAttribute("data-t2view");
        renderTab2();
      });
    });

    const slider = document.getElementById("t2-wave-slider");
    slider.addEventListener("input", () => {
      t2State.wave = Number(slider.value);
      renderTab2();
    });

    document.getElementById("t2-play-btn").addEventListener("click", () => {
      if (t2State.playing) stopTab2Animation();
      else startTab2Animation();
    });

    document.querySelectorAll("[data-t2preset]").forEach((btn) => {
      btn.addEventListener("click", () => {
        const key = btn.getAttribute("data-t2preset");
        document.querySelectorAll("[data-t2preset]").forEach((b) => b.classList.toggle("active", b === btn));
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

  function renderTab2() {
    document.getElementById("t2-wave-badge").textContent = WAVE_LABELS[t2State.wave];
    const plotDiv = document.getElementById("t2-main-plot");
    const xCol = t2State.xVar;
    const yCol = t2State.yVar;
    const activeWave = t2State.wave;

    if (t2State.view === "trends") {
      document.getElementById("t2-chart-title").textContent = "Historical Trends for Highlighted Countries";
      document.getElementById("t2-chart-subtitle").textContent =
        "Left: University funding | Right: Tax revenue (dotted line marks active five-year period).";

      const isos = t2State.selectedIsos.length ? t2State.selectedIsos : ["IRL", "GBR", "NOR", "CHL"];
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
          name,
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
          name,
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

      const allWaves = ["1990-1994", "1995-1999", "2000-2004", "2005-09", "2010-2014", "2015-2019", "2020-2024"];
      const waveCat = ["1990-1994", "1995-1999", "2000-2004", "2005-2009", "2010-2014", "2015-2019", "2020-2024"];
      const activeWaveLabel = WAVE_LABELS[activeWave];

      Plotly.newPlot(
        plotDiv,
        traces,
        {
          grid: { rows: 1, columns: 2, pattern: "independent" },
          margin: { t: 32, r: 24, b: 50, l: 60 },
          xaxis: { title: "Five-Year Period", type: "category", categoryorder: "array", categoryarray: waveCat },
          yaxis: { title: t2VarLabels[xCol], gridcolor: "#f1f5f9" },
          xaxis2: { title: "Five-Year Period", type: "category", categoryorder: "array", categoryarray: waveCat },
          yaxis2: { title: t2VarLabels[yCol], gridcolor: "#f1f5f9" },
          shapes: [
            { type: "line", xref: "x", yref: "paper", x0: activeWaveLabel, x1: activeWaveLabel, y0: 0, y1: 1, line: { color: "#be123c", width: 1.6, dash: "dot" } },
            { type: "line", xref: "x2", yref: "paper", x0: activeWaveLabel, x1: activeWaveLabel, y0: 0, y1: 1, line: { color: "#be123c", width: 1.6, dash: "dot" } }
          ],
          legend: { orientation: "h", y: 1.12, x: 0 },
          paper_bgcolor: "#ffffff",
          plot_bgcolor: "#ffffff"
        },
        { responsive: true, displayModeBar: false }
      );
      void allWaves;
      return;
    }

    document.getElementById("t2-chart-title").textContent = "University Spending vs Tax Revenue";
    document.getElementById("t2-chart-subtitle").textContent =
      "Bubble size reflects population; click any bubble to trace a country over time.";

    const allValid = HISTORICAL.filter(
      (r) => r[xCol] !== null && r[yCol] !== null && Number.isFinite(Number(r[xCol])) && Number.isFinite(Number(r[yCol]))
    );
    const xVals = allValid.map((r) => Number(r[xCol])).sort((a, b) => a - b);
    const yVals = allValid.map((r) => Number(r[yCol])).sort((a, b) => a - b);
    const q = (arr, p) => (arr.length ? arr[Math.max(0, Math.min(arr.length - 1, Math.floor(p * arr.length)))] : 0);

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
        textfont: { size: 9, color: t2State.selectedIsos.length > 0 ? "rgba(71,85,105,0.38)" : "rgba(15,23,42,0.6)" },
        customdata: sub.map((r) => [r.iso3, `${r.country_name} (${r.wave_label})`, r.income_group || ""]),
        marker: {
          color: REGION_COLOURS[reg] || "#475569",
          opacity: t2State.selectedIsos.length > 0 ? 0.3 : 0.78,
          size: sub.map((r) => Math.max(8, Math.min(30, Math.sqrt((Number(r.population_total) || 5e6) / 1e6) * 2.1))),
          line: { color: "#ffffff", width: 1 }
        },
        hovertemplate:
          "<b>%{customdata[1]}</b> (%{customdata[2]})<br>" +
          `${t2VarLabels[xCol]}: <b>%{x:.2f}</b><br>` +
          `${t2VarLabels[yCol]}: <b>%{y:.2f}</b><extra></extra>`
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
        text: cRows.map((_, i) => (i === cRows.length - 1 ? cName : "")),
        textposition: "top center",
        textfont: { size: 11, color: col, weight: "bold" },
        line: { color: col, width: 2.8 },
        marker: {
          color: col,
          size: cRows.map((_, i) => (i === cRows.length - 1 ? 12.5 : 6.5)),
          symbol: cRows.map((_, i) => (i === cRows.length - 1 ? "diamond" : "circle")),
          line: { color: "#ffffff", width: 1.4 }
        },
        customdata: cRows.map((r) => [iso, r.wave_label]),
        hovertemplate:
          `<b>${cName} (%{customdata[1]})</b><br>` +
          `${t2VarLabels[xCol]}: <b>%{x:.2f}</b><br>` +
          `${t2VarLabels[yCol]}: <b>%{y:.2f}</b><extra></extra>`
      });
    });

    Plotly.newPlot(
      plotDiv,
      traces,
      {
        margin: { t: 25, r: 24, b: 54, l: 64 },
        xaxis: { title: t2VarLabels[xCol], range: [xMin - xPad, xMax + xPad], gridcolor: "#f1f5f9", zeroline: true, zerolinecolor: "#cbd5e1" },
        yaxis: { title: t2VarLabels[yCol], range: [yMin - yPad, yMax + yPad], gridcolor: "#f1f5f9", zeroline: true, zerolinecolor: "#cbd5e1" },
        annotations: [
          {
            x: 0.98,
            y: 0.05,
            xref: "paper",
            yref: "paper",
            text: WAVE_LABELS[activeWave],
            showarrow: false,
            font: { size: 30, color: "rgba(15, 23, 42, 0.12)", weight: "bold" }
          }
        ],
        legend: { orientation: "h", y: 1.11, x: 0 },
        paper_bgcolor: "#ffffff",
        plot_bgcolor: "#ffffff"
      },
      { responsive: true, displayModeBar: false }
    );

    if (typeof plotDiv.on === "function") {
      plotDiv.on("plotly_click", (evt) => {
        if (!evt || !evt.points || !evt.points.length) return;
        const cd = evt.points[0].customdata;
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

  // ===========================================================================
  // TAB 3: Country Calculator
  // ===========================================================================
  const t3State = {
    iso3: "IRL",
    signedUnits: 1.0, // +0.5, +1.0, +1.5, -1.0
    view: "career", // career | annual
    zMeasure: "Z1",
    careerMult: 8.0,
    scenarioPreset: "boost",
    baseSpendPct: 17.3,
    baseEnrolPct: 76.8,
    baseBudgetPct: 0.74,
    baseGdpBn: 554.5,
    defaultSpendPct: 17.3,
    defaultEnrolPct: 76.8,
    defaultBudgetPct: 0.74,
    defaultGdpBn: 554.5,
    moderators: {},
    baselineModerators: {}
  };

  const Z_MEASURE_META = {
    Z1: { model5y: "M2a_Direct_10pp_5y", model10y: "M2b_Direct_10pp_10y", desc: "per-student spend" },
    Z2: { model5y: "M3a_Delta10pp_5y", model10y: "M3b_Delta10pp_10y", desc: "5-yr per-student expansion" },
    Z3: { model5y: "M3c_RealPPP_5y", model10y: "M3d_RealPPP_10y", desc: "real PPP spend/student" },
    Z4: { model5y: "M3e_TertGDP_5y", model10y: "M3f_TertGDP_10y", desc: "total budget only" }
  };

  const T3_MOD_SLIDERS = [
    { id: "gross_seco_enrolment_pct", field: "gross_seco_enrolment_pct", fmt: (v) => `${Number(v).toFixed(0)}%` },
    { id: "income_profit_tax_share_rev_pct", field: "inc_tax_share_pct", fmt: (v) => `${Number(v).toFixed(1)}%` },
    { id: "working_age_pop_15_64_pct", field: "working_age_pop_pct", fmt: (v) => `${Number(v).toFixed(1)}%` },
    { id: "gini_disp_harmonised", field: "gini_disp", fmt: (v) => `${Number(v).toFixed(1)}` }
  ];

  function updateTab3SliderLabels() {
    T3_MOD_SLIDERS.forEach((s) => {
      const inEl = document.getElementById(`mod-${s.id}`);
      const valEl = document.getElementById(`val-${s.id}`);
      const cur = Number(t3State.moderators[s.id]);
      if (inEl) inEl.value = String(cur);
      if (valEl) valEl.textContent = s.fmt(cur);
    });
  }

  function loadCountryDefaultsIntoTab3(iso3) {
    const c = COUNTRY_MAP[iso3] || COUNTRIES[0];
    const defaults = SURROGATES.sample_defaults || {};

    t3State.defaultSpendPct = Number((c.tert_spend_per_student_gdp_pc || 25.0).toFixed(1));
    t3State.defaultEnrolPct = Number((c.gross_tert_enrolment_pct || 45.0).toFixed(1));
    t3State.defaultBudgetPct = Number((c.tert_spend_gdp_pct || 0.9).toFixed(2));
    t3State.defaultGdpBn = Number(getCountryGdpBn(c, null).toFixed(1));

    t3State.baseSpendPct = t3State.defaultSpendPct;
    t3State.baseEnrolPct = t3State.defaultEnrolPct;
    t3State.baseBudgetPct = t3State.defaultBudgetPct;
    t3State.baseGdpBn = t3State.defaultGdpBn;

    document.getElementById("t3-base-spend").value = String(t3State.baseSpendPct);
    document.getElementById("t3-base-enrol").value = String(t3State.baseEnrolPct);
    document.getElementById("t3-base-budget").value = String(t3State.baseBudgetPct);
    document.getElementById("t3-base-gdp").value = String(t3State.baseGdpBn);

    T3_MOD_SLIDERS.forEach((s) => {
      const raw = c[s.field];
      const val = raw !== null && raw !== undefined && Number.isFinite(Number(raw)) ? Number(raw) : Number(defaults[s.id] || 50);
      t3State.baselineModerators[s.id] = val;
      t3State.moderators[s.id] = val;
    });
    updateTab3SliderLabels();
  }

  function hasBaselineOverride() {
    return (
      Math.abs(t3State.baseSpendPct - t3State.defaultSpendPct) > 0.15 ||
      Math.abs(t3State.baseEnrolPct - t3State.defaultEnrolPct) > 0.25 ||
      Math.abs(t3State.baseBudgetPct - t3State.defaultBudgetPct) > 0.02 ||
      Math.abs(t3State.baseGdpBn - t3State.defaultGdpBn) > Math.max(0.5, t3State.defaultGdpBn * 0.01)
    );
  }

  function getZOffset(outKey, horizonYears) {
    const zCode = t3State.zMeasure || "Z1";
    if (zCode === "Z1") return 0.0;
    const globalAte = DATA.global_ate || [];
    const outIdx = outKey === "tax_gdp" ? 1 : outKey === "inc_gdp" ? 2 : outKey === "inc_share" ? 3 : 4;
    const refId = horizonYears === 5 ? "M2a_Direct_10pp_5y" : "M2b_Direct_10pp_10y";
    const altId = horizonYears === 5 ? Z_MEASURE_META[zCode].model5y : Z_MEASURE_META[zCode].model10y;
    const refRow = globalAte.find((r) => r.model_id === refId && Number(r.outcome_index) === outIdx);
    const altRow = globalAte.find((r) => r.model_id === altId && Number(r.outcome_index) === outIdx);
    if (!refRow || !altRow) return 0.0;
    return Number(altRow.ate_mean || 0) - Number(refRow.ate_mean || 0);
  }

  function evalTab3Outcome(c, outKey, horizonYears) {
    const hKey = horizonYears === 5 ? "h5" : "h10";
    const pref = horizonYears === 5 ? "tau5_" : "tau10_";
    const sur = SURROGATES[hKey] && SURROGATES[hKey][outKey];
    const coefs = (sur && sur.coefs) || {};

    const signedU = Number(t3State.signedUnits || 1.0);
    const absU = Math.abs(signedU);
    const dir = signedU >= 0 ? 1 : -1;

    let baseMean = c[`${pref}${outKey}`];
    if (baseMean === null || baseMean === undefined || !Number.isFinite(Number(baseMean))) {
      baseMean = Number(coefs["(Intercept)"] || 0);
    }

    const baseGdpRatio = t3State.defaultGdpBn > 0 ? Math.max(0.1, t3State.baseGdpBn / t3State.defaultGdpBn) : 1.0;
    const deltaMod =
      Number(coefs.gross_tert_enrolment_pct || 0) * (t3State.baseEnrolPct - t3State.defaultEnrolPct) +
      Number(coefs.log_gdp_pc_ppp || 0) * Math.log(baseGdpRatio) +
      Number(coefs.gross_seco_enrolment_pct || 0) *
        (t3State.moderators.gross_seco_enrolment_pct - t3State.baselineModerators.gross_seco_enrolment_pct) +
      Number(coefs.income_profit_tax_share_rev_pct || 0) *
        (t3State.moderators.income_profit_tax_share_rev_pct - t3State.baselineModerators.income_profit_tax_share_rev_pct) +
      Number(coefs.working_age_pop_15_64_pct || 0) *
        (t3State.moderators.working_age_pop_15_64_pct - t3State.baselineModerators.working_age_pop_15_64_pct) +
      Number(coefs.gini_disp_harmonised || 0) *
        (t3State.moderators.gini_disp_harmonised - t3State.baselineModerators.gini_disp_harmonised);

    const zOffset = getZOffset(outKey, horizonYears);
    const simPP = dir * absU * (Number(baseMean) + zOffset + deltaMod);

    const rawSd =
      c[`${pref}${outKey}_sd`] !== null && Number.isFinite(Number(c[`${pref}${outKey}_sd`]))
        ? Number(c[`${pref}${outKey}_sd`])
        : c[`${pref}${outKey}_high95`] !== null && c[`${pref}${outKey}_low95`] !== null
          ? Math.abs(Number(c[`${pref}${outKey}_high95`]) - Number(c[`${pref}${outKey}_low95`])) / 3.92
          : Number((sur && sur.mean_sd) || 0.22);

    const sdPP = absU * rawSd;

    // Preserve asymmetric posterior quantiles when near baseline
    const rawL95 = c[`${pref}${outKey}_low95`];
    const rawH95 = c[`${pref}${outKey}_high95`];
    let low95PP;
    let high95PP;
    if (rawL95 !== null && rawH95 !== null && Math.abs(zOffset + deltaMod) < 1e-4 && dir === 1) {
      low95PP = absU * Number(rawL95);
      high95PP = absU * Number(rawH95);
    } else {
      low95PP = simPP - 1.96 * sdPP;
      high95PP = simPP + 1.96 * sdPP;
    }

    return { simPP, sdPP, low95PP, high95PP };
  }

  function applyTab3Preset(scen) {
    t3State.scenarioPreset = scen;
    document.querySelectorAll("#t3-scenario-pills .preset-pill").forEach((b) => {
      b.classList.toggle("active", b.getAttribute("data-scen") === scen);
    });
    loadCountryDefaultsIntoTab3(t3State.iso3);

    if (scen === "boost") {
      t3State.zMeasure = "Z1";
      t3State.signedUnits = 1.0;
    } else if (scen === "funded_exp") {
      t3State.zMeasure = "Z1";
      t3State.signedUnits = 1.0;
      t3State.baseEnrolPct = Math.min(130, t3State.defaultEnrolPct + 15);
      document.getElementById("t3-base-enrol").value = String(t3State.baseEnrolPct);
    } else if (scen === "crowding") {
      t3State.zMeasure = "Z4";
      t3State.signedUnits = 1.0;
      t3State.baseEnrolPct = Math.min(130, t3State.defaultEnrolPct + 20);
      document.getElementById("t3-base-enrol").value = String(t3State.baseEnrolPct);
    } else if (scen === "cut") {
      t3State.zMeasure = "Z1";
      t3State.signedUnits = -1.0;
    }

    document.getElementById("t3-z-select").value = t3State.zMeasure;
    document.getElementById("t3-change-select").value = String(t3State.signedUnits);
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

    const chSel = document.getElementById("t3-change-select");
    chSel.addEventListener("change", () => {
      t3State.signedUnits = Number(chSel.value || 1.0);
      renderTab3();
    });

    document.querySelectorAll("#t3-view-group .seg-btn").forEach((btn) => {
      btn.addEventListener("click", () => {
        document
          .querySelectorAll("#t3-view-group .seg-btn")
          .forEach((b) => b.classList.toggle("active", b === btn));
        t3State.view = btn.getAttribute("data-t3view");
        renderTab3();
      });
    });

    document.getElementById("t3-z-select").addEventListener("change", (e) => {
      t3State.zMeasure = e.target.value || "Z1";
      renderTab3();
    });

    document.getElementById("t3-accounting-select").addEventListener("change", (e) => {
      t3State.careerMult = Number(e.target.value || 8.0);
      renderTab3();
    });

    document.querySelectorAll("#t3-scenario-pills .preset-pill").forEach((btn) => {
      btn.addEventListener("click", () => {
        applyTab3Preset(btn.getAttribute("data-scen"));
        renderTab3();
      });
    });

    const bindNumInput = (id, key, minVal) => {
      const el = document.getElementById(id);
      el.addEventListener("input", () => {
        const v = Number(el.value);
        if (Number.isFinite(v) && v >= minVal) {
          t3State[key] = v;
          renderTab3();
        }
      });
    };
    bindNumInput("t3-base-spend", "baseSpendPct", 1.0);
    bindNumInput("t3-base-enrol", "baseEnrolPct", 1.0);
    bindNumInput("t3-base-budget", "baseBudgetPct", 0.05);
    bindNumInput("t3-base-gdp", "baseGdpBn", 0.2);

    T3_MOD_SLIDERS.forEach((s) => {
      const el = document.getElementById(`mod-${s.id}`);
      el.addEventListener("input", () => {
        t3State.moderators[s.id] = Number(el.value);
        updateTab3SliderLabels();
        renderTab3();
      });
    });

    document.getElementById("t3-reset-btn").addEventListener("click", () => {
      applyTab3Preset("boost");
      renderTab3();
    });

    loadCountryDefaultsIntoTab3(t3State.iso3);
  }

  function renderTab3() {
    const c = COUNTRY_MAP[t3State.iso3] || COUNTRIES[0];
    const signedU = Number(t3State.signedUnits || 1.0);
    const absU = Math.abs(signedU);
    const isCut = signedU < 0;
    const cm = CURR_META[activeCurr] || CURR_META.EUR;

    const overrides = hasBaselineOverride()
      ? {
          spendPct: t3State.baseSpendPct,
          enrolPct: t3State.baseEnrolPct,
          budgetPct: t3State.baseBudgetPct,
          gdpBn: t3State.baseGdpBn
        }
      : null;

    const cost = computeFundingCost(c, t3State.zMeasure, absU, overrides);
    const ev10Tax = evalTab3Outcome(c, "tax_gdp", 10);
    const ev10Inc = evalTab3Outcome(c, "inc_gdp", 10);

    const mult = t3State.careerMult;
    const taxCareerBn = mult * cost.gdpBn * (ev10Tax.simPP / 100);
    const taxL95Bn = mult * cost.gdpBn * (ev10Tax.low95PP / 100);
    const taxH95Bn = mult * cost.gdpBn * (ev10Tax.high95PP / 100);
    const taxSdBn = Math.max(0.0005, mult * cost.gdpBn * (ev10Tax.sdPP / 100));

    const incCareerBn = mult * cost.gdpBn * (ev10Inc.simPP / 100);
    const incL95Bn = mult * cost.gdpBn * (ev10Inc.low95PP / 100);
    const incH95Bn = mult * cost.gdpBn * (ev10Inc.high95PP / 100);

    const bcrTax = cost.costBn > 0 ? Math.abs(taxCareerBn) / cost.costBn : 0;
    const bcrInc = cost.costBn > 0 ? Math.abs(incCareerBn) / cost.costBn : 0;

    let probNet = isCut
      ? normCdf((-taxCareerBn - cost.costBn) / taxSdBn)
      : normCdf((taxCareerBn - cost.costBn) / taxSdBn);

    if (
      !overrides &&
      !isCut &&
      t3State.zMeasure === "Z1" &&
      absU === 1.0 &&
      mult === 8.0 &&
      Number.isFinite(Number(c.prob_net_pos_y1))
    ) {
      probNet = Number(c.prob_net_pos_y1);
    }

    // Populate the 3 clean KPI cards
    document.getElementById("kpi-cost-label").textContent = isCut ? "Cohort Budget Cut" : "Cohort Degree Cost";
    document.getElementById("kpi-cost-val").textContent = formatMoneyBn(cost.costBn, false);
    document.getElementById("kpi-cost-sub").textContent =
      `${cost.costGdpPct.toFixed(2)}% of GDP | ${t3State.baseEnrolPct.toFixed(0)}% tertiary enrolment`;

    document.getElementById("kpi-ret-label").textContent = isCut
      ? "Expected 40-Yr Total Tax Change"
      : "Expected 40-Yr Total Tax Return";
    document.getElementById("kpi-ret-val").textContent = formatMoneyBn(taxCareerBn, true);
    document.getElementById("kpi-ret-pill").textContent = isCut
      ? `${bcrTax.toFixed(1)}x cost`
      : `${(taxCareerBn / Math.max(1e-6, cost.costBn)).toFixed(1)}x return`;
    document.getElementById("kpi-ret-sub").textContent =
      `95% range: ${formatMoneyBn(taxL95Bn, true)} to ${formatMoneyBn(taxH95Bn, true)}`;

    document.getElementById("kpi-prob-val").textContent = isCut
      ? formatProb(1 - probNet)
      : formatProb(probNet);
    document.getElementById("kpi-prob-sub").textContent =
      `Income tax alone: ${formatMoneyBn(incCareerBn, true)} (${(incCareerBn / Math.max(1e-6, cost.costBn)).toFixed(1)}x)`;
    void bcrInc;

    const plotDiv = document.getElementById("t3-main-plot");

    // View A (Default): Clean 3-Bar Career Comparison with 95% Error Bars
    if (t3State.view === "career") {
      document.getElementById("t3-chart-title").textContent = isCut
        ? `${c.country_name}: Budget Cut vs Expected 40-Year Tax Change`
        : `${c.country_name}: Upfront Cohort Cost vs Expected 40-Year Tax Return`;
      document.getElementById("t3-chart-subtitle").textContent =
        "Error bars show 95% credible intervals; dashed line marks the upfront cohort cost (break-even).";

      const costVal = isCut ? -cost.costBn : cost.costBn;
      const xCats = [
        isCut ? "Cohort Budget\nSaved" : "Upfront Cohort\nCost",
        "40-Yr Income Tax\n(Conservative Floor)",
        "40-Yr Total Tax\n(All Streams)"
      ];
      const yMeans = [costVal, incCareerBn, taxCareerBn];
      const errPlus = [0, Math.max(0, incH95Bn - incCareerBn), Math.max(0, taxH95Bn - taxCareerBn)];
      const errMinus = [0, Math.max(0, incCareerBn - incL95Bn), Math.max(0, taxCareerBn - taxL95Bn)];

      Plotly.newPlot(
        plotDiv,
        [
          {
            type: "bar",
            x: xCats,
            y: yMeans,
            width: [0.46, 0.46, 0.46],
            marker: { color: ["#f59e0b", "#0b2545", "#136f63"] },
            text: [
              formatMoneyBn(costVal, isCut),
              formatMoneyBn(incCareerBn, true),
              formatMoneyBn(taxCareerBn, true)
            ],
            textposition: "outside",
            cliponaxis: false,
            error_y: {
              type: "data",
              symmetric: false,
              array: errPlus,
              arrayminus: errMinus,
              color: "#334155",
              thickness: 2.2,
              width: 7
            },
            customdata: [
              [`${cost.costGdpPct.toFixed(2)}% of GDP`, "Fixed policy outlay"],
              [
                `[${formatMoneyBn(incL95Bn, true)}, ${formatMoneyBn(incH95Bn, true)}]`,
                `Return ratio: ${(incCareerBn / Math.max(1e-6, cost.costBn)).toFixed(1)}x`
              ],
              [
                `[${formatMoneyBn(taxL95Bn, true)}, ${formatMoneyBn(taxH95Bn, true)}]`,
                `Return ratio: ${(taxCareerBn / Math.max(1e-6, cost.costBn)).toFixed(1)}x (${formatProb(probNet)})`
              ]
            ],
            hovertemplate:
              "<b>%{x}</b><br>" +
              "Estimate: <b>%{text}</b><br>" +
              "95% range: %{customdata[0]}<br>" +
              "%{customdata[1]}<extra></extra>"
          }
        ],
        {
          margin: { t: 36, r: 28, b: 56, l: 72 },
          yaxis: {
            title: `${cm.code} (${cm.symbol} billion)`,
            gridcolor: "#f1f5f9",
            zeroline: true,
            zerolinecolor: "#cbd5e1",
            zerolinewidth: 1.5
          },
          shapes: [
            {
              type: "line",
              xref: "paper",
              x0: 0,
              x1: 1,
              y0: costVal,
              y1: costVal,
              line: { color: "#d97706", width: 2.0, dash: "dash" }
            }
          ],
          annotations: [
            {
              xref: "paper",
              yref: "y",
              x: 0.99,
              y: costVal,
              yshift: 11,
              xanchor: "right",
              text: isCut ? "Budget cut level" : "Break-even (Cohort cost)",
              showarrow: false,
              font: { size: 11, color: "#b45309", weight: "bold" }
            }
          ],
          showlegend: false,
          paper_bgcolor: "#ffffff",
          plot_bgcolor: "#ffffff"
        },
        { responsive: true, displayModeBar: false }
      );
      return;
    }

    // View B: 5-Year vs 10-Year Annual Impact with 95% Error Bars
    document.getElementById("t3-chart-title").textContent =
      `${c.country_name}: Annual Tax Impact After 5 Years vs 10 Years`;
    document.getElementById("t3-chart-subtitle").textContent =
      "Left: Annual revenue flow | Right: Tax-mix shift (% of total tax), with 95% credible intervals.";

    const ev5Inc = evalTab3Outcome(c, "inc_gdp", 5);
    const ev5Tax = evalTab3Outcome(c, "tax_gdp", 5);
    const ev5ShInc = evalTab3Outcome(c, "inc_share", 5);
    const ev5ShGds = evalTab3Outcome(c, "goods_share", 5);
    const ev10ShInc = evalTab3Outcome(c, "inc_share", 10);
    const ev10ShGds = evalTab3Outcome(c, "goods_share", 10);

    const toAnn = (ev, outKey) => ({
      m: formatScaledAmount(ev.simPP, c, outKey, 1, cost.gdpBn),
      l: formatScaledAmount(ev.low95PP, c, outKey, 1, cost.gdpBn),
      h: formatScaledAmount(ev.high95PP, c, outKey, 1, cost.gdpBn)
    });

    const r5 = [toAnn(ev5Inc, "inc_gdp"), toAnn(ev5Tax, "tax_gdp")];
    const r10 = [toAnn(ev10Inc, "inc_gdp"), toAnn(ev10Tax, "tax_gdp")];
    const revLabels = ["Income Tax\nOnly", "Total Tax\n(All Streams)"];
    const mixLabels = ["Income Tax\nShare", "Goods / VAT\nShare"];

    Plotly.newPlot(
      plotDiv,
      [
        {
          type: "bar",
          name: "After 5 Years",
          legendgroup: "h5",
          xaxis: "x",
          yaxis: "y",
          x: revLabels,
          y: r5.map((d) => d.m),
          marker: { color: "#0b2545" },
          error_y: {
            type: "data",
            symmetric: false,
            array: r5.map((d) => Math.max(0, d.h - d.m)),
            arrayminus: r5.map((d) => Math.max(0, d.m - d.l)),
            color: "#334155",
            thickness: 2,
            width: 5
          }
        },
        {
          type: "bar",
          name: "After 10 Years",
          legendgroup: "h10",
          xaxis: "x",
          yaxis: "y",
          x: revLabels,
          y: r10.map((d) => d.m),
          marker: { color: "#136f63" },
          error_y: {
            type: "data",
            symmetric: false,
            array: r10.map((d) => Math.max(0, d.h - d.m)),
            arrayminus: r10.map((d) => Math.max(0, d.m - d.l)),
            color: "#0f766e",
            thickness: 2,
            width: 5
          }
        },
        {
          type: "bar",
          name: "After 5 Years",
          legendgroup: "h5",
          showlegend: false,
          xaxis: "x2",
          yaxis: "y2",
          x: mixLabels,
          y: [ev5ShInc.simPP, ev5ShGds.simPP],
          marker: { color: "#0b2545" },
          error_y: {
            type: "data",
            symmetric: false,
            array: [ev5ShInc.high95PP - ev5ShInc.simPP, ev5ShGds.high95PP - ev5ShGds.simPP],
            arrayminus: [ev5ShInc.simPP - ev5ShInc.low95PP, ev5ShGds.simPP - ev5ShGds.low95PP],
            color: "#334155",
            thickness: 2,
            width: 5
          }
        },
        {
          type: "bar",
          name: "After 10 Years",
          legendgroup: "h10",
          showlegend: false,
          xaxis: "x2",
          yaxis: "y2",
          x: mixLabels,
          y: [ev10ShInc.simPP, ev10ShGds.simPP],
          marker: { color: "#136f63" },
          error_y: {
            type: "data",
            symmetric: false,
            array: [ev10ShInc.high95PP - ev10ShInc.simPP, ev10ShGds.high95PP - ev10ShGds.simPP],
            arrayminus: [ev10ShInc.simPP - ev10ShInc.low95PP, ev10ShGds.simPP - ev10ShGds.low95PP],
            color: "#0f766e",
            thickness: 2,
            width: 5
          }
        }
      ],
      {
        barmode: "group",
        grid: { rows: 1, columns: 2, pattern: "independent" },
        margin: { t: 40, r: 24, b: 54, l: 68 },
        yaxis: {
          title: activeScale === "PP" ? "Annual Change (pp of GDP)" : `Annual Change (${cm.symbol} bn / yr)`,
          gridcolor: "#f1f5f9",
          zeroline: true,
          zerolinecolor: "#be123c"
        },
        yaxis2: {
          title: "Tax Mix Shift (pp of total tax)",
          gridcolor: "#f1f5f9",
          zeroline: true,
          zerolinecolor: "#be123c"
        },
        legend: { orientation: "h", y: 1.12, x: 0 },
        paper_bgcolor: "#ffffff",
        plot_bgcolor: "#ffffff"
      },
      { responsive: true, displayModeBar: false }
    );
  }

  // ===========================================================================
  // Boot Application
  // ===========================================================================
  initTab1Controls();
  initTab2Controls();
  initTab3Controls();
  syncMetricButtonLabels();
  renderTab1();
})();
