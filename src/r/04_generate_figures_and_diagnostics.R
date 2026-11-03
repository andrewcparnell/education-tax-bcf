#!/usr/bin/env Rscript
# ==============================================================================
# Step 3.3: Generate Publication Figures & Appendix Diagnostics
# (src/r/04_generate_figures_and_diagnostics.R)
#
# Style rules enforced:
#   - British English throughout (enrolment, colour, modelled, etc.)
#   - Zero em dashes (uses ' - ', colons, or parentheses)
#   - Clear, simple, jargon-free labels on all axes, legends, and titles
#   - Two-letter ISO-2 country codes in legends and labelled directly on lines
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(ggplot2)
  library(grid)
})

repo_root <- "/Users/andrewparnell/Documents/GitHub/education-tax-bcf"
proc_dir  <- file.path(repo_root, "data", "processed")
tab_dir   <- file.path(repo_root, "results", "tables")
fig_dir   <- file.path(repo_root, "results", "figures")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

# Clean publication theme (large readable text, clean gridlines)
theme_pub <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", size = base_size + 2, colour = "#0f2537", margin = margin(b = 4)),
      plot.subtitle = element_text(size = base_size - 0.5, colour = "#334e68", margin = margin(b = 10)),
      plot.caption = element_text(size = base_size - 2, colour = "#627d98", hjust = 0, margin = margin(t = 8)),
      axis.title = element_text(face = "bold", size = base_size, colour = "#102a43"),
      axis.text = element_text(size = base_size - 1, colour = "#243b53"),
      strip.text = element_text(face = "bold", size = base_size, colour = "#0f2537"),
      strip.background = element_rect(fill = "#f0f4f8", colour = NA),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = "#e1e8ed", linewidth = 0.35),
      legend.position = "bottom",
      legend.title = element_text(face = "bold", size = base_size - 0.5),
      legend.text = element_text(size = base_size - 1),
      plot.background = element_rect(fill = "white", colour = NA),
      panel.background = element_rect(fill = "white", colour = NA)
    )
}

# ==============================================================================
# Figure 1: Overall Structural Schematic of the Paper
# ==============================================================================
cat("Generating Figure 1: Structural Schematic of the Study...\n")

boxes <- tibble(
  xmin = c(0.2, 3.6, 3.6, 7.0),
  xmax = c(2.9, 6.3, 6.3, 9.8),
  ymin = c(1.2, 3.3, 0.7, 1.2),
  ymax = c(5.3, 5.5, 2.8, 5.3),
  fill = c("#e6f2f8", "#edf7ed", "#fff4e6", "#f0f4f8"),
  border = c("#1b6ca8", "#2b8a3e", "#d9480f", "#0f2537"),
  header = c(
    "1. University Funding\n(Three Ways to Measure It)",
    "2A. Baseline Country Context\n(Controlled in All Models)",
    "2B. Broader Economic Changes\n(Separated Out in Direct Model)",
    "3. National Tax Take\n(+5 Year and +10 Year Changes)"
  ),
  body = c(
    paste(
      "Three Observed Measures:",
      "* Per-Student Spending Ratio",
      "  (% of GDP per person)",
      "* Real PPP Dollars per Student",
      "  (removes GDP from denominator)",
      "* University Budget % of GDP",
      "  (removes student headcount)",
      "",
      "Tested Across Contexts:",
      "* University Enrolment (%)",
      "* Country Income Group",
      "* Public vs Private Tuition Mix",
      sep = "\n"
    ),
    paste(
      "Measured Before Funding Wave:",
      "* Starting GDP & Tax Structure",
      "* Prior 5-Year Economic Growth",
      "* Starting University Enrolment",
      "* Demographics & Governance",
      "* Likelihood of High Funding",
      sep = "\n"
    ),
    paste(
      "Changes During Follow-Up Window:",
      "* Overall GDP per Person Growth",
      "* Expansion in Student Numbers",
      "* Changes in Income Inequality",
      "* Changes in Life Expectancy",
      sep = "\n"
    ),
    paste(
      "Tracked Jointly Over Time:",
      "",
      "1. Overall Non-Resource Tax",
      "   (% of GDP)",
      "2. Direct Income & Profit Tax",
      "   (% of GDP)",
      "3. Direct Income & Profit Share",
      "   (% of Total Tax Revenue)",
      "4. Goods & Services Tax Share",
      "   (Negative-Control Check)",
      sep = "\n"
    )
  )
)

arrows_df <- tibble(
  x    = c(2.92, 2.92, 6.32, 6.32, 4.95),
  y    = c(4.2,  2.1,  4.4,  1.8,  3.25),
  xend = c(3.55, 3.55, 6.95, 6.95, 4.95),
  yend = c(4.4,  1.8,  4.0,  2.3,  2.85)
)

p_fig1 <- ggplot() +
  geom_rect(
    data = boxes,
    aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
    fill = boxes$fill, colour = boxes$border, linewidth = 0.9
  ) +
  geom_text(
    data = boxes,
    aes(x = (xmin + xmax) / 2, y = ymax - 0.35, label = header),
    fontface = "bold", size = 3.8, colour = "#0f2537", lineheight = 1.05
  ) +
  geom_text(
    data = boxes,
    aes(x = xmin + 0.15, y = (ymin + ymax) / 2 - 0.25, label = body),
    hjust = 0, size = 3.15, colour = "#102a43", lineheight = 1.15
  ) +
  geom_segment(
    data = arrows_df,
    aes(x = x, y = y, xend = xend, yend = yend),
    arrow = arrow(length = unit(0.22, "cm"), type = "closed"),
    linewidth = 0.8, colour = "#243b53"
  ) +
  annotate(
    "text", x = 5.0, y = 5.85,
    label = "Study Design: Isolating the Direct Fiscal Dividend of Public University Funding",
    fontface = "bold", size = 4.6, colour = "#0f2537"
  ) +
  annotate(
    "text", x = 5.0, y = 0.3,
    label = "Comparing Total Effects (Pathway 2A) against Mediator-Removed Direct Effects (net of Pathway 2B) across 121 countries (1985 - 2024)",
    size = 3.3, colour = "#334e68"
  ) +
  coord_cartesian(xlim = c(0, 10), ylim = c(0.1, 6.1), expand = FALSE) +
  theme_void() +
  theme(plot.background = element_rect(fill = "white", colour = NA))

ggsave(file.path(fig_dir, "fig1_structural_schematic.png"), p_fig1, width = 10.5, height = 5.6, dpi = 300)
ggsave(file.path(fig_dir, "fig1_structural_schematic.pdf"), p_fig1, width = 10.5, height = 5.6)

# ==============================================================================
# Figure 2: Total Fiscal Effect vs Mediator-Removed Direct Effect Posteriors
# ==============================================================================
cat("Generating Figure 2: Total vs Mediator-Removed Direct Fiscal Posteriors...\n")

draws_df <- read_csv(file.path(proc_dir, "mvbcf_ate_posterior_draws.csv"), show_col_types = FALSE)

draws_long <- draws_df %>%
  pivot_longer(
    cols = c(tax_gdp_pp, inc_tax_gdp_pp, inc_tax_share_pp, goods_tax_share_pp),
    names_to = "outcome_code",
    values_to = "ate_pp"
  ) %>%
  mutate(
    outcome_label = factor(
      outcome_code,
      levels = c("tax_gdp_pp", "inc_tax_gdp_pp", "inc_tax_share_pp", "goods_tax_share_pp"),
      labels = c(
        "1. Non-Resource Tax / GDP (pp)",
        "2. Direct Income & Profit Tax / GDP (pp)",
        "3. Direct Income & Profit Share of Revenue (pp)",
        "4. Goods & Services Tax Share (pp, Negative Control)"
      )
    ),
    horizon = factor(horizon, levels = c("+5 years", "+10 years")),
    model = factor(model, levels = c("Total Fiscal Effect (M1)", "Mediator-Removed Direct Effect (M2)"))
  )

sum_fig2 <- draws_long %>%
  group_by(outcome_label, horizon, model) %>%
  summarise(
    mean_val = mean(ate_pp),
    q025 = quantile(ate_pp, 0.025),
    q10  = quantile(ate_pp, 0.10),
    q90  = quantile(ate_pp, 0.90),
    q975 = quantile(ate_pp, 0.975),
    prob_pos = mean(ate_pp > 0),
    .groups = "drop"
  )

p_fig2 <- ggplot(sum_fig2, aes(x = mean_val, y = horizon, colour = model)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "#829ab1", linewidth = 0.6) +
  geom_errorbarh(
    aes(xmin = q025, xmax = q975),
    height = 0.18, linewidth = 0.7, position = position_dodge(width = 0.55)
  ) +
  geom_errorbarh(
    aes(xmin = q10, xmax = q90),
    height = 0.0, linewidth = 1.9, position = position_dodge(width = 0.55)
  ) +
  geom_point(size = 3.2, position = position_dodge(width = 0.55)) +
  geom_text(
    aes(
      label = sprintf("%+.2f pp (P>0: %.0f%%)", mean_val, 100 * prob_pos),
      y = as.numeric(horizon) + ifelse(model == "Total Fiscal Effect (M1)", -0.27, 0.27)
    ),
    size = 3.0, fontface = "bold", show.legend = FALSE
  ) +
  facet_wrap(~ outcome_label, ncol = 2, scales = "free_x") +
  scale_colour_manual(
    name = "Causal Model Specification:",
    values = c("Total Fiscal Effect (M1)" = "#1b6ca8", "Mediator-Removed Direct Effect (M2)" = "#2b8a3e")
  ) +
  labs(
    title = "Public University Funding Increases Direct Tax Capacity Beyond General Economic Growth",
    subtitle = "Posterior mean treatment effects (with 80% and 95% credible intervals) across the four tax channels at +5 and +10 years",
    x = "Treatment Effect on Tax Outcome (Percentage Points)",
    y = "Time Horizon After Funding Wave",
    caption = "Note: Thick bars show 80% credible intervals; thin bars show 95% credible intervals. P>0 is the posterior probability of a positive fiscal return."
  ) +
  theme_pub(11.5)

ggsave(file.path(fig_dir, "fig2_total_vs_direct_tax_posteriors.png"), p_fig2, width = 10.5, height = 6.2, dpi = 300)
ggsave(file.path(fig_dir, "fig2_total_vs_direct_tax_posteriors.pdf"), p_fig2, width = 10.5, height = 6.2)

# ==============================================================================
# Figure 3: Unbundling the Denominator Trap (Comparison of Spending Definitions)
# ==============================================================================
cat("Generating Figure 3: Unbundled Spending Exposure Comparison (+10 Years)...\n")

tab1 <- read_csv(file.path(tab_dir, "table1_mvbcf_ate_posteriors.csv"), show_col_types = FALSE)

fig3_df <- tab1 %>%
  filter(
    horizon == "+10 years (t+2)",
    model_id %in% c("M2b_Direct_10y", "M3b_ObsExp_10y", "M3d_RealPPP_10y", "M3f_TertGDP_10y", "M3h_TotalEduGDP_10y"),
    outcome_index %in% c(1, 2, 3)
  ) %>%
  mutate(
    exposure_label = factor(
      model_id,
      levels = rev(c("M2b_Direct_10y", "M3b_ObsExp_10y", "M3d_RealPPP_10y", "M3f_TertGDP_10y", "M3h_TotalEduGDP_10y")),
      labels = rev(c(
        "1. Per-Student Ratio Regime\n(% of GDP per person)",
        "2. Observed Ratio Expansion\n(>=2.5 pp increase over wave)",
        "3. Real PPP Dollars per Student\n(removes GDP denominator)",
        "4. University Budget % of GDP\n(removes student headcount)",
        "5. Total Education Budget % of GDP\n(all schooling levels combined)"
      ))
    ),
    outcome_clean = factor(
      outcome_index,
      levels = c(1, 2, 3),
      labels = c(
        "1. Non-Resource Tax / GDP (pp)",
        "2. Direct Income Tax / GDP (pp)",
        "3. Direct Income Share of Revenue (pp)"
      )
    )
  )

p_fig3 <- ggplot(fig3_df, aes(x = ate_mean, y = exposure_label, colour = outcome_clean)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "#829ab1", linewidth = 0.6) +
  geom_errorbarh(aes(xmin = clu_cri95_low, xmax = clu_cri95_high), height = 0.2, linewidth = 0.65) +
  geom_errorbarh(aes(xmin = ate_cri80_low, xmax = ate_cri80_high), height = 0.0, linewidth = 1.8) +
  geom_point(size = 3.0) +
  geom_text(
    aes(label = sprintf("%+.2f pp (P=%.2f)", ate_mean, clu_prob_pos)),
    vjust = -0.85, size = 2.85, fontface = "bold", show.legend = FALSE
  ) +
  facet_wrap(~ outcome_clean, ncol = 3, scales = "free_x") +
  scale_colour_manual(
    values = c(
      "1. Non-Resource Tax / GDP (pp)" = "#1b6ca8",
      "2. Direct Income Tax / GDP (pp)" = "#2b8a3e",
      "3. Direct Income Share of Revenue (pp)" = "#d9480f"
    ),
    guide = "none"
  ) +
  labs(
    title = "Sensitivity of +10-Year Direct Fiscal Returns Across University and Education Spending Definitions",
    subtitle = "Comparing per-student ratios, real PPP dollars per student, university share of GDP, and total education spending",
    x = "+10-Year Mediator-Removed Direct Effect (Percentage Points)",
    y = "Spending Exposure Definition",
    caption = "Note: Thin bars show country-clustered 95% credible intervals; thick bars show 80% credible intervals."
  ) +
  theme_pub(11)

ggsave(file.path(fig_dir, "fig3_denominator_unbundling_horserace.png"), p_fig3, width = 11.2, height = 5.6, dpi = 300)
ggsave(file.path(fig_dir, "fig3_denominator_unbundling_horserace.pdf"), p_fig3, width = 11.2, height = 5.6)

# ==============================================================================
# Figure 4: Heterogeneity by University Enrolment Access & OECD Financing Model
# ==============================================================================
cat("Generating Figure 4: Enrolment Moderation & OECD Public-vs-Private Financing...\n")

df_10y_ic <- read_csv(file.path(proc_dir, "panel_10y_with_icates.csv"), show_col_types = FALSE) %>%
  mutate(
    income_group = factor(income_group, levels = c(
      "Low income", "Lower middle income", "Upper middle income", "High income"
    ))
  )

p_fig4 <- ggplot(
  df_10y_ic %>% filter(!is.na(gross_tert_enrolment_pct), !is.na(m2_10y_tau_inc_tax_share_pp)),
  aes(x = gross_tert_enrolment_pct, y = m2_10y_tau_inc_tax_share_pp, colour = income_group)
) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "#829ab1", linewidth = 0.6) +
  geom_point(alpha = 0.65, size = 2.2) +
  geom_smooth(aes(group = 1), method = "loess", se = TRUE, colour = "#0f2537", fill = "#cbd5e1", linewidth = 1.1) +
  scale_colour_manual(
    name = "World Bank Income Group:",
    values = c(
      "Low income" = "#d9480f",
      "Lower middle income" = "#e67700",
      "Upper middle income" = "#1b6ca8",
      "High income" = "#2b8a3e"
    )
  ) +
  labs(
    title = "Direct Income Tax Returns Are Positive Across All University Enrolment Regimes",
    subtitle = "Unit-level +10-year direct effect on Direct Income & Profit Tax Share (pp) by baseline university enrolment ratio",
    x = "Baseline Gross University Enrolment Ratio (%)",
    y = "+10-Year Direct Effect on Income Tax Share (pp)",
    caption = "Note: Gross university enrolment can exceed 100% because the numerator includes students of all ages (including mature and postgraduate students)\nwhile the denominator is the official 5-year post-secondary age cohort."
  ) +
  theme_pub(11.5)

ggsave(file.path(fig_dir, "fig4_enrolment_and_oecd_moderation.png"), p_fig4, width = 9.5, height = 5.4, dpi = 300)
ggsave(file.path(fig_dir, "fig4_enrolment_and_oecd_moderation.pdf"), p_fig4, width = 9.5, height = 5.4)

# ==============================================================================
# Figure 5: Longitudinal Trajectories with Two-Letter Country Codes on Lines
# ==============================================================================
cat("Generating Figure 5: Longitudinal Tax-Share Trajectories with ISO-2 Labels...\n")

df_long_pred <- read_csv(file.path(proc_dir, "panel_longitudinal_3wave_predictions.csv"), show_col_types = FALSE)

# Select 7 globally diverse representative countries across income/financing regimes
rep_countries <- tibble(
  iso3 = c("DNK", "DEU", "USA", "KOR", "CHL", "BRA", "ZAF"),
  iso2 = c("DK",  "DE",  "US",  "KR",  "CL",  "BR",  "ZA"),
  legend_label = c(
    "Denmark (DK)", "Germany (DE)", "United States (US)",
    "South Korea (KR)", "Chile (CL)", "Brazil (BR)", "South Africa (ZA)"
  )
)

country_traj <- df_long_pred %>%
  inner_join(rep_countries, by = c("iso3", "iso2")) %>%
  group_by(iso3, iso2, legend_label) %>%
  summarise(
    tau_0y  = 0.0,
    tau_5y  = mean(lbcf_tau1_inc_tax_share_pp, na.rm = TRUE),
    tau_10y = mean(lbcf_tau_cum_inc_tax_share_pp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_longer(
    cols = c(tau_0y, tau_5y, tau_10y),
    names_to = "horizon_step",
    values_to = "effect_pp"
  ) %>%
  mutate(
    years_after = case_when(
      horizon_step == "tau_0y"  ~ 0,
      horizon_step == "tau_5y"  ~ 5,
      horizon_step == "tau_10y" ~ 10
    )
  )

# Compute non-overlapping vertical label positions at +5y and +10y
space_labels <- function(y_vals, min_gap = 0.16) {
  ord <- order(y_vals)
  y_sorted <- y_vals[ord]
  for (i in 2:length(y_sorted)) {
    if (y_sorted[i] - y_sorted[i - 1] < min_gap) {
      y_sorted[i] <- y_sorted[i - 1] + min_gap
    }
  }
  # Re-centre around original mean if shifted upward
  y_sorted <- y_sorted - (mean(y_sorted) - mean(y_vals))
  out <- numeric(length(y_vals))
  out[ord] <- y_sorted
  out
}

label_points_10y <- country_traj %>%
  filter(years_after == 10) %>%
  mutate(
    x_label = 10.45,
    y_label = space_labels(effect_pp, min_gap = 0.165)
  )

label_points_5y <- country_traj %>%
  filter(years_after == 5) %>%
  arrange(effect_pp) %>%
  mutate(
    # Stagger x positions slightly to the left/right of x = 5 so labels never collide with lines
    x_label = c(4.35, 5.45, 4.35, 5.45, 4.35, 5.45, 4.55),
    y_label = space_labels(effect_pp, min_gap = 0.155)
  )

p_fig5 <- ggplot(country_traj, aes(x = years_after, y = effect_pp, colour = legend_label, group = legend_label)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "#829ab1", linewidth = 0.6) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.8) +
  geom_segment(
    data = label_points_10y,
    aes(x = years_after + 0.08, y = effect_pp, xend = x_label - 0.10, yend = y_label),
    linewidth = 0.45, linetype = "dotted", show.legend = FALSE
  ) +
  geom_text(
    data = label_points_10y,
    aes(x = x_label, y = y_label, label = paste0(iso2, " (+", sprintf("%.1f", effect_pp), " pp)")),
    hjust = 0, fontface = "bold", size = 3.25, show.legend = FALSE
  ) +
  geom_segment(
    data = label_points_5y,
    aes(x = years_after, y = effect_pp, xend = x_label, yend = y_label),
    linewidth = 0.4, linetype = "dotted", show.legend = FALSE
  ) +
  geom_label(
    data = label_points_5y,
    aes(x = x_label, y = y_label, label = iso2),
    fontface = "bold", size = 2.9, label.padding = unit(0.12, "lines"),
    fill = "white", alpha = 0.9, show.legend = FALSE
  ) +
  scale_x_continuous(breaks = c(0, 5, 10), labels = c("Baseline (0y)", "+5 Years", "+10 Years"), limits = c(0, 12.1)) +
  scale_colour_manual(
    name = "Country (ISO-2):",
    values = c(
      "Denmark (DK)" = "#1b6ca8",
      "Germany (DE)" = "#2b8a3e",
      "United States (US)" = "#d9480f",
      "South Korea (KR)" = "#5f3dc4",
      "Chile (CL)" = "#e67700",
      "Brazil (BR)" = "#0b7285",
      "South Africa (ZA)" = "#c92a2a"
    )
  ) +
  labs(
    title = "Ten-Year Compounding Trajectory of Direct Income & Profit Tax Share Across Countries",
    subtitle = "Three-wave Longitudinal Bayesian Causal Forest cumulative effect from baseline (0y) to +5 and +10 years",
    x = "Years Following University Funding Wave",
    y = "Cumulative Effect on Direct Income Tax Share (pp)",
    caption = "Note: Each country trajectory is labelled with its two-letter ISO-2 country code at both +5 years and +10 years."
  ) +
  theme_pub(11.5)

ggsave(file.path(fig_dir, "fig5_longitudinal_country_trajectories.png"), p_fig5, width = 9.6, height = 5.6, dpi = 300)
ggsave(file.path(fig_dir, "fig5_longitudinal_country_trajectories.pdf"), p_fig5, width = 9.6, height = 5.6)

# ==============================================================================
# Appendix Figure A1: MCMC Trace Plots across the 4 Fiscal Outcomes
# ==============================================================================
cat("Generating Appendix Figure A1: MCMC Posterior Trace Plots...\n")

trace_df <- draws_long %>%
  filter(model == "Mediator-Removed Direct Effect (M2)")

p_figA1 <- ggplot(trace_df, aes(x = draw, y = ate_pp, colour = horizon)) +
  geom_line(alpha = 0.75, linewidth = 0.45) +
  facet_wrap(~ outcome_label, ncol = 2, scales = "free_y") +
  scale_colour_manual(
    name = "Horizon:",
    values = c("+5 years" = "#1b6ca8", "+10 years" = "#d9480f")
  ) +
  labs(
    title = "Appendix Figure A1: Post-Burn-In MCMC Trace Plots for Mediator-Removed Direct Fiscal Effects",
    subtitle = "1,250 post-burn-in Gibbs draws across all four disaggregated fiscal outcomes at +5 and +10 years",
    x = "Post-Burn-In MCMC Iteration",
    y = "Average Treatment Effect Draw (Percentage Points)"
  ) +
  theme_pub(11)

ggsave(file.path(fig_dir, "figA1_mcmc_convergence_traces.png"), p_figA1, width = 10.2, height = 5.8, dpi = 300)
ggsave(file.path(fig_dir, "figA1_mcmc_convergence_traces.pdf"), p_figA1, width = 10.2, height = 5.8)

# ==============================================================================
# Appendix Table A1: MCMC Convergence & Posterior Fit Diagnostics
# ==============================================================================
cat("Computing Appendix Table A1: MCMC Convergence & Fit Diagnostics...\n")

compute_ess <- function(x) {
  n <- length(x)
  if (sd(x) == 0) return(n)
  acf_vals <- acf(x, lag.max = 50, plot = FALSE)$acf[-1]
  # Sum positive autocorrelation pairs (Geyer's initial positive sequence approximation)
  pos_idx <- which(acf_vals < 0)[1]
  if (is.na(pos_idx)) pos_idx <- length(acf_vals)
  rho_sum <- sum(acf_vals[seq_len(max(1, pos_idx - 1))])
  ess <- n / (1 + 2 * max(0, rho_sum))
  round(min(n, max(10, ess)), 0)
}

compute_split_rhat <- function(x) {
  n <- length(x)
  half <- floor(n / 2)
  c1 <- x[1:half]
  c2 <- x[(half + 1):(2 * half)]
  W <- 0.5 * (var(c1) + var(c2))
  B <- half * var(c(mean(c1), mean(c2)))
  var_hat <- ((half - 1) / half) * W + (1 / half) * B
  round(sqrt(var_hat / W), 3)
}

compute_geweke_z <- function(x) {
  n <- length(x)
  n1 <- floor(0.1 * n)
  n2 <- floor(0.5 * n)
  x1 <- x[1:n1]
  x2 <- x[(n - n2 + 1):n]
  ess1 <- compute_ess(x1)
  ess2 <- compute_ess(x2)
  z <- (mean(x1) - mean(x2)) / sqrt(var(x1) / ess1 + var(x2) / ess2)
  round(z, 2)
}

tabA1 <- draws_long %>%
  group_by(model, horizon, outcome_code, outcome_label) %>%
  summarise(
    n_post_draws = n(),
    ate_mean = round(mean(ate_pp), 3),
    ate_sd   = round(sd(ate_pp), 3),
    split_rhat = compute_split_rhat(ate_pp),
    ess_ate    = compute_ess(ate_pp),
    geweke_z   = compute_geweke_z(ate_pp),
    .groups = "drop"
  ) %>%
  left_join(
    tab1 %>%
      filter(model_id %in% c("M1a_Total_5y", "M1b_Total_10y", "M2a_Direct_5y", "M2b_Direct_10y")) %>%
      mutate(
        model = ifelse(grepl("^M1", model_id), "Total Fiscal Effect (M1)", "Mediator-Removed Direct Effect (M2)"),
        horizon = ifelse(grepl("5y$", model_id), "+5 years", "+10 years"),
        outcome_code = case_when(
          outcome_index == 1 ~ "tax_gdp_pp",
          outcome_index == 2 ~ "inc_tax_gdp_pp",
          outcome_index == 3 ~ "inc_tax_share_pp",
          outcome_index == 4 ~ "goods_tax_share_pp"
        )
      ) %>%
      select(model, horizon, outcome_code, n_obs, n_countries, prob_positive, clu_prob_pos),
    by = c("model", "horizon", "outcome_code")
  )

write_csv(tabA1, file.path(tab_dir, "tableA1_convergence_and_fit_diagnostics.csv"))
print(tabA1)

# Also sync figures into paper/figures/ for self-contained Typst/Quarto rendering
paper_fig_dir <- file.path(repo_root, "paper", "figures")
dir.create(paper_fig_dir, recursive = TRUE, showWarnings = FALSE)
file.copy(list.files(fig_dir, full.names = TRUE), paper_fig_dir, overwrite = TRUE)

cat("All figures and diagnostics generated and saved to results/ and paper/figures/!\n")
