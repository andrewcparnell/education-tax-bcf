#!/usr/bin/env Rscript
# ==============================================================================
# Step 06: Generate Publication Figures, MCMC & Posterior Predictive Diagnostics,
#          and Compute/Energy Report
# (src/r/06_generate_figures_and_diagnostics.R)
#
# Style rules enforced:
#   - British English throughout (enrolment, colour, modelled, etc.)
#   - Zero em dashes (uses ' - ', colons, or parentheses)
#   - Exclusively focused on tertiary education spending definitions
#   - Two-letter ISO-2 country codes in legends and labelled directly on lines
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(ggplot2)
  library(grid)
})

repo_root <- getwd()
if (!dir.exists(file.path(repo_root, "src")) && dir.exists(file.path(dirname(dirname(repo_root)), "src"))) {
  repo_root <- dirname(dirname(repo_root))
}
proc_dir    <- file.path(repo_root, "data", "processed")
out_tab_dir <- file.path(repo_root, "outputs", "tables")
res_tab_dir <- file.path(repo_root, "results", "tables")
out_fig_dir <- file.path(repo_root, "outputs", "figures")
res_fig_dir <- file.path(repo_root, "results", "figures")
pap_fig_dir <- file.path(repo_root, "paper", "figures")

for (d in c(out_tab_dir, res_tab_dir, out_fig_dir, res_fig_dir, pap_fig_dir)) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
}

save_pub_fig <- function(p, fname_base, width, height) {
  for (dir_path in c(out_fig_dir, res_fig_dir, pap_fig_dir)) {
    ggsave(file.path(dir_path, paste0(fname_base, ".png")), p, width = width, height = height, dpi = 300)
    ggsave(file.path(dir_path, paste0(fname_base, ".pdf")), p, width = width, height = height)
  }
}

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
    "1. Tertiary Education Spending\n(Four Unbundled Measures)",
    "2A. Baseline Country Context\n(Pre-Treatment Confounders X)",
    "2B. Mediating Macro Changes\n(Separated Out in Direct Model)",
    "3. Future National Tax Take\n(+5 Year and +10 Year Changes)"
  ),
  body = c(
    paste(
      "Four Observed Measures:",
      "* Per-Student Spending Ratio",
      "  (% of GDP per person)",
      "* Within-Country Expansion",
      "  (>= +2.5 pp ratio increase)",
      "* Real PPP Dollars per Student",
      "  (removes GDP denominator)",
      "* Tertiary Budget % of GDP",
      "  (removes student headcount)",
      "",
      "Moderators W Tested:",
      "* Enrolment, Income & Tuition",
      sep = "\n"
    ),
    paste(
      "Measured Before Funding Wave:",
      "* Starting GDP & Tax Structure",
      "* Prior 5-Year Economic Growth",
      "* Starting Tertiary Enrolment",
      "* Demographics & Trade Openness",
      "* Propensity Score pi_hat(X)",
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
      "   (% of Total Revenue)",
      "4. Goods & Services Tax Share",
      "   (Negative-Control Check)",
      sep = "\n"
    )
  )
)

# Directed causal pathways:
# - Box 2A -> Box 1 (pre-treatment confounders X drive treatment selection Z)
# - Box 2A -> Box 3 (pre-treatment confounders X drive future fiscal outcomes Y)
# - Box 2A -> Box 2B (pre-treatment confounders X influence intermediate growth M)
# - Box 1  -> Box 2B (treatment Z influences mediating macro changes M)
# - Box 2B -> Box 3  (mediating macro changes M influence future fiscal outcomes Y)
arrows_df <- tibble(
  x    = c(3.55, 2.92, 6.32, 6.32, 4.95),
  y    = c(4.4,  2.1,  4.4,  1.8,  3.25),
  xend = c(2.92, 3.55, 6.95, 6.95, 4.95),
  yend = c(4.2,  1.8,  4.0,  2.3,  2.85)
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
    hjust = 0, size = 3.10, colour = "#102a43", lineheight = 1.13
  ) +
  geom_segment(
    data = arrows_df,
    aes(x = x, y = y, xend = xend, yend = yend),
    arrow = arrow(length = unit(0.22, "cm"), type = "closed"),
    linewidth = 0.8, colour = "#243b53"
  ) +
  annotate(
    "text", x = 5.0, y = 5.85,
    label = "Study Design: Isolating the Direct Fiscal Dividend of Government Tertiary Education Spending",
    fontface = "bold", size = 4.5, colour = "#0f2537"
  ) +
  annotate(
    "text", x = 5.0, y = 0.3,
    label = "Comparing Total Effects (adjusting for 2A) against Mediator-Removed Direct Effects (net of 2B) across 121 countries (1985 to 2024)",
    size = 3.3, colour = "#334e68"
  ) +
  coord_cartesian(xlim = c(0, 10), ylim = c(0.1, 6.1), expand = FALSE) +
  theme_void() +
  theme(plot.background = element_rect(fill = "white", colour = NA))

save_pub_fig(p_fig1, "fig1_structural_schematic", 10.5, 5.6)

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
  geom_errorbar(
    aes(xmin = q025, xmax = q975),
    width = 0.18, linewidth = 0.7, position = position_dodge(width = 0.55),
    orientation = "y"
  ) +
  geom_errorbar(
    aes(xmin = q10, xmax = q90),
    width = 0.0, linewidth = 1.9, position = position_dodge(width = 0.55),
    orientation = "y"
  ) +
  geom_point(size = 3.2, position = position_dodge(width = 0.55)) +
  geom_text(
    aes(
      label = ifelse(
        prob_pos >= 0.995,
        sprintf("%+.2f pp (P>0: >99%%)", mean_val),
        sprintf("%+.2f pp (P>0: %.0f%%)", mean_val, 100 * prob_pos)
      ),
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
    title = "Posterior Treatment Effect Estimates Across the Four Tax Outcomes (+5 and +10 Years)",
    subtitle = "Posterior mean treatment effects (with 80% and 95% CIs) comparing Total (M1) and Mediator-Removed Direct (M2) specifications",
    x = "Treatment Effect on Tax Outcome (Percentage Points)",
    y = "Time Horizon After Funding Wave",
    caption = "Note: Thick bars show 80% credible intervals (CIs); thin bars show 95% CIs. P>0 is the posterior probability of a positive fiscal return."
  ) +
  theme_pub(11.5)

save_pub_fig(p_fig2, "fig2_total_vs_direct_tax_posteriors", 10.5, 6.2)

# ==============================================================================
# Figure 3: Unbundling the Tertiary Denominator Trap (Exclusively Tertiary)
# ==============================================================================
cat("Generating Figure 3: Unbundled Tertiary Spending Exposure Comparison (+10 Years)...\n")

tab1 <- read_csv(file.path(out_tab_dir, "table1_mvbcf_ate_posteriors.csv"), show_col_types = FALSE)

fig3_df <- tab1 %>%
  filter(
    horizon == "+10 years (t+2)",
    model_id %in% c("M2b_Direct_10y", "M3b_ObsExp_10y", "M3d_RealPPP_10y", "M3f_TertGDP_10y"),
    outcome_index %in% c(1, 2, 3)
  ) %>%
  mutate(
    exposure_label = factor(
      model_id,
      levels = rev(c("M2b_Direct_10y", "M3b_ObsExp_10y", "M3d_RealPPP_10y", "M3f_TertGDP_10y")),
      labels = rev(c(
        "1. Per-Student Tertiary Ratio Regime\n(% of GDP per person)",
        "2. Observed Per-Student Expansion\n(>=2.5 pp increase over wave)",
        "3. Real PPP Dollars per Student\n(removes GDP denominator)",
        "4. Public Tertiary Budget % of GDP\n(removes student headcount)"
      ))
    ),
    outcome_clean = factor(
      outcome_index,
      levels = c(1, 2, 3),
      labels = c(
        "1. Non-Resource Tax / GDP (pp)",
        "2. Direct Income Tax / GDP (pp)",
        "3. Direct Income Tax Share (pp)"
      )
    )
  )

p_fig3 <- ggplot(fig3_df, aes(x = ate_mean, y = exposure_label, colour = outcome_clean)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "#829ab1", linewidth = 0.6) +
  geom_errorbar(aes(xmin = ate_cri95_low, xmax = ate_cri95_high), width = 0.2, linewidth = 0.65, orientation = "y") +
  geom_errorbar(aes(xmin = ate_cri80_low, xmax = ate_cri80_high), width = 0.0, linewidth = 1.8, orientation = "y") +
  geom_point(size = 3.0) +
  geom_text(
    aes(label = sprintf("%+.2f pp (P=%.2f)", ate_mean, prob_positive)),
    vjust = -0.85, size = 2.85, fontface = "bold", show.legend = FALSE
  ) +
  facet_wrap(~ outcome_clean, ncol = 3, scales = "free_x") +
  scale_colour_manual(
    values = c(
      "1. Non-Resource Tax / GDP (pp)" = "#1b6ca8",
      "2. Direct Income Tax / GDP (pp)" = "#2b8a3e",
      "3. Direct Income Tax Share (pp)" = "#d9480f"
    ),
    guide = "none"
  ) +
  labs(
    title = "Comparison of +10-Year Direct Fiscal Returns Across Tertiary Spending Definitions",
    subtitle = "Comparing per-student ratios, observed expansions, real PPP dollars per student, and budget % of GDP",
    x = "+10-Year Mediator-Removed Direct Effect (Percentage Points)",
    y = "Tertiary Spending Exposure Definition",
    caption = "Note: Thin bars show 95% credible intervals; thick bars show 80% credible intervals. P is the posterior probability of a positive return."
  ) +
  theme_pub(11)

save_pub_fig(p_fig3, "fig3_denominator_unbundling_horserace", 11.4, 5.2)

# ==============================================================================
# Figure 4: Heterogeneity by Tertiary Enrolment Access & Income Group
# ==============================================================================
cat("Generating Figure 4: Enrolment Moderation & Income Group Heterogeneity...\n")

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
  geom_linerange(
    aes(ymin = m2_10y_tau_low80_inc_tax_share_pp, ymax = m2_10y_tau_high80_inc_tax_share_pp),
    alpha = 0.28, linewidth = 0.48
  ) +
  geom_point(alpha = 0.72, size = 2.1) +
  geom_smooth(aes(group = 1), method = "loess", formula = y ~ x, se = FALSE, colour = "#0f2537", linewidth = 1.1) +
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
    title = "Unit-Level +10-Year Direct Effect on Income Tax Share by Baseline Tertiary Enrolment",
    subtitle = "Posterior mean unit-level treatment effects (pp, with 80% unit CI bars and LOESS trend) across World Bank income groups",
    x = "Baseline Gross Tertiary Enrolment Ratio (%)",
    y = "+10-Year Direct Effect on Income Tax Share (pp)",
    caption = "Note: Vertical bars show 80% unit-level posterior credible intervals (CIs); solid dark curve shows the LOESS conditional mean trend.\nGross tertiary enrolment can exceed 100% because the numerator includes students of all ages while the denominator is the official 5-year age cohort."
  ) +
  theme_pub(11.5)

save_pub_fig(p_fig4, "fig4_enrolment_and_oecd_moderation", 9.5, 5.4)

# ==============================================================================
# Figure 5: Longitudinal Trajectories with Posterior Credible Fan & Country CrIs
# ==============================================================================
cat("Generating Figure 5: Longitudinal Tax-Share Trajectories with Uncertainty & ISO-2 Labels...\n")

df_long_pred <- read_csv(file.path(proc_dir, "panel_longitudinal_3wave_predictions.csv"), show_col_types = FALSE)
tab5_lbcf    <- read_csv(file.path(out_tab_dir, "table5_longitudinal_bcf_trajectories.csv"), show_col_types = FALSE)
lbcf_draws   <- readRDS(file.path(repo_root, "outputs", "models", "lbcf_posterior_draws.rds"))

# Extract global ATE posterior mean and exact 80% / 95% credible intervals for Direct Income Tax Share (pp)
inc_share_row <- tab5_lbcf %>% filter(outcome_code == "inc_tax_share_pp")

global_ribbon_df <- tibble(
  years_after = c(0, 5, 10),
  ate_mean    = c(0.0, inc_share_row$ate_5y_mean,   inc_share_row$ate_cum_10y_mean),
  cri95_low   = c(0.0, inc_share_row$ate_5y_low,    inc_share_row$ate_cum_10y_low),
  cri95_high  = c(0.0, inc_share_row$ate_5y_high,   inc_share_row$ate_cum_10y_high),
  cri80_low   = c(0.0, inc_share_row$ate_5y_low80,  inc_share_row$ate_cum_10y_low80),
  cri80_high  = c(0.0, inc_share_row$ate_5y_high80, inc_share_row$ate_cum_10y_high80)
)

rep_countries <- tibble(
  iso3 = c("CHL", "DNK", "KOR", "USA", "DEU", "ZAF", "BRA"),
  iso2 = c("CL",  "DK",  "KR",  "US",  "DE",  "ZA",  "BR"),
  legend_label = c(
    "Chile (CL)", "Denmark (DK)", "South Korea (KR)",
    "United States (US)", "Germany (DE)", "South Africa (ZA)", "Brazil (BR)"
  ),
  x_dodge = seq(-0.54, 0.54, length.out = 7)
)

# Compute exact country-level posterior trajectory quantiles across MCMC draws s
tau1_inc_mat    <- lbcf_draws[["inc_tax_share_pp"]]$tau1_mat
tau_cum_inc_mat <- lbcf_draws[["inc_tax_share_pp"]]$tau_cum_mat

country_summary_list <- list()
for (r_idx in seq_len(nrow(rep_countries))) {
  c_iso3 <- rep_countries$iso3[r_idx]
  obs_idx <- which(df_long_pred$iso3 == c_iso3)
  c_tau1_draws <- colMeans(tau1_inc_mat[obs_idx, , drop = FALSE])
  c_cum_draws  <- colMeans(tau_cum_inc_mat[obs_idx, , drop = FALSE])
  country_summary_list[[r_idx]] <- tibble(
    iso3         = c_iso3,
    iso2         = rep_countries$iso2[r_idx],
    legend_label = rep_countries$legend_label[r_idx],
    x_dodge      = rep_countries$x_dodge[r_idx],
    m_5y         = mean(c_tau1_draws),
    l80_5y       = unname(quantile(c_tau1_draws, 0.10)),
    h80_5y       = unname(quantile(c_tau1_draws, 0.90)),
    m_10y        = mean(c_cum_draws),
    l80_10y      = unname(quantile(c_cum_draws, 0.10)),
    h80_10y      = unname(quantile(c_cum_draws, 0.90))
  )
}
country_summary <- bind_rows(country_summary_list)

country_traj <- bind_rows(
  country_summary %>% transmute(iso3, iso2, legend_label, years_after = 0,               effect_pp = 0.0,   low80 = 0.0,     high80 = 0.0),
  country_summary %>% transmute(iso3, iso2, legend_label, years_after = 5 + x_dodge,     effect_pp = m_5y,  low80 = l80_5y,  high80 = h80_5y),
  country_summary %>% transmute(iso3, iso2, legend_label, years_after = 10 + x_dodge,    effect_pp = m_10y, low80 = l80_10y, high80 = h80_10y)
)

space_labels <- function(y_vals, min_gap = 0.24) {
  ord <- order(y_vals)
  y_sorted <- y_vals[ord]
  for (i in 2:length(y_sorted)) {
    if (y_sorted[i] - y_sorted[i - 1] < min_gap) {
      y_sorted[i] <- y_sorted[i - 1] + min_gap
    }
  }
  y_sorted <- y_sorted - (mean(y_sorted) - mean(y_vals))
  out <- numeric(length(y_vals))
  out[ord] <- y_sorted
  out
}

label_points_10y <- country_traj %>%
  filter(years_after > 8) %>%
  mutate(
    x_label = 10.78,
    y_label = space_labels(effect_pp, min_gap = 0.28)
  )

label_points_5y <- country_traj %>%
  filter(years_after > 3 & years_after < 7) %>%
  arrange(years_after) %>%
  mutate(
    y_label = ifelse(seq_len(n()) %% 2 == 1, high80 + 0.18, low80 - 0.18)
  )

p_fig5 <- ggplot() +
  # Shaded 95% and 80% global posterior credible fan in background
  geom_ribbon(
    data = global_ribbon_df,
    aes(x = years_after, ymin = cri95_low, ymax = cri95_high),
    fill = "#cbd5e1", alpha = 0.38
  ) +
  geom_ribbon(
    data = global_ribbon_df,
    aes(x = years_after, ymin = cri80_low, ymax = cri80_high),
    fill = "#94a3b8", alpha = 0.38
  ) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "#64748b", linewidth = 0.65) +
  # Country trajectories and exact 80% posterior credible interval error bars
  geom_errorbar(
    data = country_traj %>% filter(years_after > 0),
    aes(x = years_after, ymin = low80, ymax = high80, colour = legend_label),
    width = 0.09, linewidth = 0.65, alpha = 0.85
  ) +
  geom_line(
    data = country_traj,
    aes(x = years_after, y = effect_pp, colour = legend_label, group = legend_label),
    linewidth = 1.05
  ) +
  geom_point(
    data = country_traj,
    aes(x = years_after, y = effect_pp, colour = legend_label),
    size = 2.6
  ) +
  geom_segment(
    data = label_points_10y,
    aes(x = years_after + 0.06, y = effect_pp, xend = x_label - 0.06, yend = y_label, colour = legend_label),
    linewidth = 0.45, linetype = "dotted", show.legend = FALSE
  ) +
  geom_text(
    data = label_points_10y,
    aes(
      x = x_label, y = y_label, colour = legend_label,
      label = sprintf("%s: %+.1f pp [%+.1f, %+.1f]", iso2, effect_pp, low80, high80)
    ),
    hjust = 0, fontface = "bold", size = 3.05, show.legend = FALSE
  ) +
  geom_label(
    data = label_points_5y,
    aes(x = years_after, y = y_label, label = iso2, colour = legend_label),
    fontface = "bold", size = 2.65, label.padding = unit(0.10, "lines"),
    fill = "white", alpha = 0.92, show.legend = FALSE
  ) +
  annotate(
    "text", x = 2.4, y = -0.35,
    label = "Shaded bands: Global 80% & 95% posterior CI",
    colour = "#475569", size = 3.0, fontface = "italic"
  ) +
  scale_x_continuous(
    breaks = c(0, 5, 10),
    labels = c("Baseline (0y)", "+5 Years", "+10 Years"),
    limits = c(0, 13.45)
  ) +
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
    subtitle = "Three-wave Longitudinal BCF trajectories with 80% country credible intervals and global 80% / 95% posterior fan",
    x = "Years Following Tertiary Funding Wave",
    y = "Cumulative Effect on Direct Income Tax Share (pp)",
    caption = "Note: Vertical bars and brackets show exact 80% country-level posterior credible intervals (horizontally dodged at +5y and +10y for visibility).\nGrey ribbons show the global average 80% (dark) and 95% (light) posterior credible fan across all N = 282 trajectories."
  ) +
  theme_pub(11.5)

save_pub_fig(p_fig5, "fig5_longitudinal_country_trajectories", 10.2, 5.8)

# ==============================================================================
# Appendix Figure A1: MCMC Trace Plots across the 4 Fiscal Outcomes (mvbcf & lbcf)
# ==============================================================================
cat("Generating Appendix Figure A1: MCMC Posterior Trace Plots...\n")

lbcf_trace_rows <- list()
lbcf_label_map <- c(
  "tax_gdp_pp"         = "1. Non-Resource Tax / GDP (pp)",
  "inc_tax_gdp_pp"     = "2. Direct Income & Profit Tax / GDP (pp)",
  "inc_tax_share_pp"   = "3. Direct Income & Profit Share of Revenue (pp)",
  "goods_tax_share_pp" = "4. Goods & Services Tax Share (pp, Negative Control)"
)
for (code_nm in names(lbcf_label_map)) {
  cdraws <- lbcf_draws[[code_nm]]$ate_cum_draws
  lbcf_trace_rows[[code_nm]] <- tibble(
    draw = seq_along(cdraws),
    series = "Longitudinal BCF (+10y Cumulative)",
    outcome_label = factor(lbcf_label_map[[code_nm]], levels = unname(lbcf_label_map)),
    ate_pp = cdraws
  )
}

mvbcf_trace_df <- draws_long %>%
  filter(model == "Mediator-Removed Direct Effect (M2)") %>%
  mutate(
    series = ifelse(horizon == "+5 years", "Multivariate BCF (+5y Direct)", "Multivariate BCF (+10y Direct)")
  ) %>%
  select(draw, series, outcome_label, ate_pp)

trace_combined_df <- bind_rows(
  mvbcf_trace_df,
  bind_rows(lbcf_trace_rows) %>% filter(draw <= 1250)
) %>%
  mutate(
    series = factor(series, levels = c(
      "Multivariate BCF (+5y Direct)",
      "Multivariate BCF (+10y Direct)",
      "Longitudinal BCF (+10y Cumulative)"
    ))
  )

p_figA1 <- ggplot(trace_combined_df, aes(x = draw, y = ate_pp, colour = series)) +
  geom_line(alpha = 0.72, linewidth = 0.42) +
  facet_wrap(~ outcome_label, ncol = 2, scales = "free_y") +
  scale_colour_manual(
    name = "Model & Horizon:",
    values = c(
      "Multivariate BCF (+5y Direct)" = "#1b6ca8",
      "Multivariate BCF (+10y Direct)" = "#d9480f",
      "Longitudinal BCF (+10y Cumulative)" = "#2b8a3e"
    )
  ) +
  labs(
    title = "Post-Burn-In MCMC Trace Plots for Multivariate BCF and Longitudinal BCF Models",
    subtitle = "Stationary post-burn-in MCMC draws across all four fiscal outcomes for mvbcf (+5y, +10y) and lbcf (+10y cumulative)",
    x = "Post-Burn-In MCMC Iteration",
    y = "Average Treatment Effect Draw (Percentage Points)"
  ) +
  theme_pub(11)

save_pub_fig(p_figA1, "figA1_mcmc_convergence_traces", 10.4, 6.0)

# ==============================================================================
# Appendix Table A1: MCMC Convergence & Posterior Predictive Fit Diagnostics
# ==============================================================================
cat("Computing Appendix Table A1: MCMC Convergence & Posterior Predictive Fit Diagnostics...\n")

compute_ess <- function(x) {
  n <- length(x)
  if (sd(x) == 0) return(n)
  ac <- acf(x, lag.max = min(50, floor(n / 4)), plot = FALSE)$acf[-1]
  pos_ac <- ac[seq_len(which(c(ac < 0, TRUE))[1] - 1)]
  ess <- n / (1 + 2 * sum(pos_ac))
  round(max(10, min(n, ess)), 0)
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

ppc_tbl <- read_csv(file.path(out_tab_dir, "table_ppc_fit_metrics.csv"), show_col_types = FALSE)

tabA1_mvbcf <- draws_long %>%
  group_by(model, horizon, outcome_code, outcome_label) %>%
  summarise(
    n_post_draws = n(),
    ate_mean   = round(mean(ate_pp), 3),
    ate_sd     = round(sd(ate_pp), 3),
    split_rhat = compute_split_rhat(ate_pp),
    ess_ate    = compute_ess(ate_pp),
    mcse_ate   = round(sd(ate_pp) / sqrt(compute_ess(ate_pp)), 3),
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
  ) %>%
  left_join(ppc_tbl, by = c("model", "horizon", "outcome_code"))

tabA1_lbcf <- tab5_lbcf %>%
  transmute(
    model = "Longitudinal BCF (lbcf)",
    horizon = "+10 years (cum.)",
    outcome_code = outcome_code,
    outcome_label = factor(lbcf_label_map[outcome_code], levels = levels(draws_long$outcome_label)),
    n_post_draws = 1500L,
    ate_mean = ate_cum_10y_mean,
    ate_sd = ate_cum_10y_sd,
    split_rhat = split_rhat,
    ess_ate = ess_cum,
    mcse_ate = mcse_cum,
    geweke_z = geweke_z_cum,
    n_obs = n_trajectories,
    n_countries = n_countries,
    prob_positive = prob_cum_10y_pos,
    clu_prob_pos = clu_prob_cum_pos,
    ppc_rmse = ppc_rmse,
    ppc_r2 = ppc_r2,
    ppc_cov95_pct = ppc_cov95_pct
  )

tabA1 <- bind_rows(tabA1_mvbcf, tabA1_lbcf)
write_csv(tabA1, file.path(out_tab_dir, "tableA1_convergence_and_fit_diagnostics.csv"))
write_csv(tabA1, file.path(res_tab_dir, "tableA1_convergence_and_fit_diagnostics.csv"))
print(tabA1, n = 25)

cat("\n=== Figure 5 Country Callout Labels ===\n")
print(label_points_10y %>% select(iso2, legend_label, effect_pp, low80, high80))

# ==============================================================================
# Appendix Table A3: Propensity Score Overlap & 19-Covariate Balance Summary
# ==============================================================================
df_clean <- read_csv(file.path(proc_dir, "clean_tax_panel.csv"), show_col_types = FALSE) %>%
  mutate(
    income_group_num = as.numeric(factor(income_group, levels = c(
      "Low income", "Lower middle income", "Upper middle income", "High income"
    ))),
    region_num = as.numeric(factor(region))
  )
base_con_vars <- c(
  "log_gdp_pc_ppp", "non_resource_tax_gdp_pct", "income_profit_tax_share_rev_pct",
  "goods_services_tax_share_rev_pct", "gini_disp_harmonised", "life_expectancy_birth_yrs",
  "gross_tert_enrolment_pct", "gross_seco_enrolment_pct", "edu_spend_total_gdp_pct",
  "working_age_pop_15_64_pct", "log_population", "unemployment_rate_pct",
  "natural_resource_rents_gdp_pct", "trade_openness_gdp_pct", "lag_gdp_pc_growth_pct",
  "income_group_num", "region_num", "is_oecd", "wave_index"
)
y10_cols <- c("d_t2_nonres_tax_gdp_pp", "d_t2_inc_tax_gdp_pp", "d_t2_inc_tax_share_pp", "d_t2_goods_tax_share_pp")
d10 <- df_clean[complete.cases(df_clean[, c(y10_cols, "Z_regime_inc")]), ]
X_ps10 <- as.data.frame(lapply(d10[, base_con_vars], function(v) {
  v <- as.numeric(v); med <- median(v, na.rm = TRUE); ifelse(is.na(v), med, v)
}))
Z10 <- as.numeric(d10$Z_regime_inc)
ps_fit10 <- suppressWarnings(glm(Z10 ~ ., data = X_ps10, family = binomial()))
pi_hat10 <- pmin(pmax(predict(ps_fit10, type = "response"), 0.02), 0.98)
cs_low10 <- max(min(pi_hat10[Z10 == 1]), min(pi_hat10[Z10 == 0]))
cs_high10 <- min(max(pi_hat10[Z10 == 1]), max(pi_hat10[Z10 == 0]))
in_cs10 <- mean(pi_hat10 >= cs_low10 & pi_hat10 <= cs_high10)
cat(sprintf("Propensity Overlap (+10y N=283): common support [%.3f, %.3f], %.1f%% inside overlap range\n", cs_low10, cs_high10, 100 * in_cs10))

w_ipw <- ifelse(Z10 == 1, 1 / pi_hat10, 1 / (1 - pi_hat10))
bal_rows <- list()
for (v in base_con_vars) {
  x <- X_ps10[[v]]
  m1 <- mean(x[Z10 == 1]); m0 <- mean(x[Z10 == 0])
  s_pool <- sqrt(0.5 * (var(x[Z10 == 1]) + var(x[Z10 == 0])))
  smd_raw <- if (s_pool > 0) (m1 - m0) / s_pool else 0.0
  wm1 <- sum(x[Z10 == 1] * w_ipw[Z10 == 1]) / sum(w_ipw[Z10 == 1])
  wm0 <- sum(x[Z10 == 0] * w_ipw[Z10 == 0]) / sum(w_ipw[Z10 == 0])
  smd_ipw <- if (s_pool > 0) (wm1 - wm0) / s_pool else 0.0
  bal_rows[[length(bal_rows) + 1]] <- tibble(
    covariate = v,
    mean_treated = round(m1, 2),
    mean_control = round(m0, 2),
    smd_unweighted = round(smd_raw, 3),
    smd_ipw_weighted = round(smd_ipw, 3)
  )
}
tabA3 <- bind_rows(bal_rows)
write_csv(tabA3, file.path(out_tab_dir, "tableA3_propensity_overlap_and_balance.csv"))
write_csv(tabA3, file.path(res_tab_dir, "tableA3_propensity_overlap_and_balance.csv"))
cat(sprintf("Balance summary (+10y N=283): mean |SMD| unweighted = %.3f (max = %.3f) -> IPW-weighted mean |SMD| = %.3f (max = %.3f)\n",
            mean(abs(tabA3$smd_unweighted)), max(abs(tabA3$smd_unweighted)),
            mean(abs(tabA3$smd_ipw_weighted)), max(abs(tabA3$smd_ipw_weighted))))

# ==============================================================================
# Appendix Table A2: Compute and Energy Report (Phase 4.9)
# ==============================================================================
mvbcf_meta <- readLines(file.path(repo_root, "outputs", "models", "mvbcf_run_metadata.json"))
lbcf_meta  <- readLines(file.path(repo_root, "outputs", "models", "lbcf_run_metadata.json"))
mvbcf_sec  <- as.numeric(gsub("[^0-9.]", "", mvbcf_meta[grepl("wall_clock_seconds", mvbcf_meta)]))
lbcf_sec   <- as.numeric(gsub("[^0-9.]", "", lbcf_meta[grepl("wall_clock_seconds", lbcf_meta)]))
tot_sec    <- mvbcf_sec + lbcf_sec
# Assuming 25W average Apple Silicon CPU package power and 250 gCO2e/kWh Irish grid intensity
kwh_est    <- (tot_sec / 3600) * 0.025
co2_g_est  <- kwh_est * 250

tabA2 <- tribble(
  ~pipeline_stage, ~models_fitted, ~wall_clock_sec, ~est_energy_wh, ~est_co2e_grams,
  "Step 04: Multivariate BCF & Benchmarks", "30 four-outcome mvbcf / BART / LP / TWFE / DML fits", round(mvbcf_sec, 1), round(1000 * (mvbcf_sec / 3600) * 0.025, 3), round(250 * (mvbcf_sec / 3600) * 0.025, 3),
  "Step 05: Three-Wave Longitudinal BCF", "4 three-wave lbcf_3wave trajectory fits (2,500 iter each)", round(lbcf_sec, 1), round(1000 * (lbcf_sec / 3600) * 0.025, 3), round(250 * (lbcf_sec / 3600) * 0.025, 3),
  "Total Modelling Pipeline", "All primary, benchmark, ablation, and robustness models", round(tot_sec, 1), round(1000 * kwh_est, 3), round(co2_g_est, 3)
)
write_csv(tabA2, file.path(out_tab_dir, "tableA2_compute_and_energy.csv"))
write_csv(tabA2, file.path(res_tab_dir, "tableA2_compute_and_energy.csv"))
print(tabA2)

cat("All figures and diagnostics generated and saved to outputs/, results/, and paper/figures/!\n")
