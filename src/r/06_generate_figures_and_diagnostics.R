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
  xmin = c(0.15, 3.55, 3.55, 6.95),
  xmax = c(3.05, 6.45, 6.45, 9.85),
  ymin = c(1.0,  3.25, 0.75, 1.0),
  ymax = c(5.35, 5.45, 2.85, 5.35),
  fill = c("#e6f2f8", "#edf7ed", "#fff4e6", "#f0f4f8"),
  border = c("#1b6ca8", "#2b8a3e", "#d9480f", "#0f2537"),
  header = c(
    "1. University Funding\n(Four Ways of Measuring)",
    "2A. Starting Country Context\n(Measured Before Funding)",
    "2B. Economic Growth Controls\n(During Follow-Up Period)",
    "3. Future Tax Revenue\n(+5 Year & +10 Year Changes)"
  ),
  body = c(
    paste(
      "* Per-Student Spending Ratio",
      "  (% of GDP per person)",
      "",
      "* Within-Country Increases",
      "  (5-year funding jump)",
      "",
      "* Real PPP Dollars per Student",
      "  (purchasing-power adjusted)",
      "",
      "* University Budget % of GDP",
      "  (share of national income)",
      sep = "\n"
    ),
    paste(
      "* Starting GDP & Tax Structure",
      "* Prior 5-Year Economic Growth",
      "* Starting University Enrolment",
      "* Demographics & Inequality",
      "* Likelihood of High Funding",
      sep = "\n"
    ),
    paste(
      "* Overall GDP per Person Growth",
      "* Growth in Student Numbers",
      "* Income Inequality Changes",
      "* Life Expectancy Changes",
      sep = "\n"
    ),
    paste(
      "1. Total Non-Resource Tax",
      "   (% of GDP)",
      "",
      "2. Income & Profit Tax",
      "   (% of GDP)",
      "",
      "3. Income & Profit Tax Share",
      "   (% of Total Tax Revenue)",
      "",
      "4. Goods & Services Tax Share",
      "   (% of Total Tax Revenue)",
      sep = "\n"
    )
  )
)

arrows_df <- tibble(
  x    = c(3.52, 3.08, 6.48, 6.48, 5.00),
  y    = c(4.35, 2.05, 4.35, 1.80, 3.22),
  xend = c(3.08, 3.52, 6.92, 6.92, 5.00),
  yend = c(4.15, 1.80, 4.00, 2.25, 2.88)
)

p_fig1 <- ggplot() +
  geom_rect(
    data = boxes,
    aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
    fill = boxes$fill, colour = boxes$border, linewidth = 1.0
  ) +
  geom_text(
    data = boxes,
    aes(x = (xmin + xmax) / 2, y = ymax - 0.36, label = header),
    fontface = "bold", size = 4.4, colour = "#0f2537", lineheight = 1.05
  ) +
  geom_text(
    data = boxes,
    aes(x = xmin + 0.16, y = (ymin + ymax) / 2 - 0.24, label = body),
    hjust = 0, size = 3.85, colour = "#102a43", lineheight = 1.15
  ) +
  geom_segment(
    data = arrows_df,
    aes(x = x, y = y, xend = xend, yend = yend),
    arrow = arrow(length = unit(0.24, "cm"), type = "closed"),
    linewidth = 0.9, colour = "#243b53"
  ) +
  annotate(
    "text", x = 5.0, y = 5.82,
    label = "Study Design: Estimating the Effect of Government University Spending on Future Tax Revenue",
    fontface = "bold", size = 4.7, colour = "#0f2537"
  ) +
  annotate(
    "text", x = 5.0, y = 0.32,
    label = "Separating university funding effects from starting conditions (2A) and general economic growth (2B) across 121 countries (1985-2024)",
    size = 3.7, colour = "#334e68"
  ) +
  coord_cartesian(xlim = c(0, 10), ylim = c(0.05, 6.1), expand = FALSE) +
  theme_void() +
  theme(plot.background = element_rect(fill = "white", colour = NA))

save_pub_fig(p_fig1, "fig1_structural_schematic", 10.8, 5.6)

# ==============================================================================
# Section 3 Data Summary Figure: Raw Data Overview Across Income Groups
# ==============================================================================
cat("Generating Section 3 Data Summary Figure (eda_fig1_raw_distributions_and_bivariate)...\n")

df_clean <- read_csv(file.path(proc_dir, "clean_tax_panel.csv"), show_col_types = FALSE) %>%
  filter(!is.na(tert_spend_per_student_winsor) | !is.na(non_resource_tax_gdp_pct)) %>%
  mutate(
    income_group = factor(
      income_group,
      levels = c("Low income", "Lower middle income", "Upper middle income", "High income"),
      labels = c("Low\nIncome", "Lower Middle\nIncome", "Upper Middle\nIncome", "High\nIncome")
    )
  ) %>%
  filter(!is.na(income_group))

eda_long <- df_clean %>%
  transmute(
    iso3,
    income_group,
    `A. UNESCO Per-Student Ratio (% of GDP/person)` = tert_spend_per_student_winsor,
    `B. Real Spending per Student (2021 PPP $)` = real_tert_spend_per_student_ppp,
    `C. Gross Tertiary Enrolment Ratio (%)` = gross_tert_enrolment_pct,
    `D. Direct Income & Profit Tax Share (% of Tax)` = income_profit_tax_share_rev_pct
  ) %>%
  pivot_longer(
    cols = starts_with(c("A.", "B.", "C.", "D.")),
    names_to = "panel",
    values_to = "val"
  ) %>%
  filter(!is.na(val), is.finite(val))

p_data_overview <- ggplot(eda_long, aes(x = income_group, y = val, fill = income_group, colour = income_group)) +
  geom_jitter(width = 0.18, alpha = 0.28, size = 1.3, show.legend = FALSE) +
  geom_boxplot(width = 0.48, alpha = 0.55, outlier.shape = NA, colour = "#102a43", linewidth = 0.45, show.legend = FALSE) +
  facet_wrap(~ panel, ncol = 2, scales = "free_y") +
  scale_fill_manual(values = c("#d9480f", "#e67700", "#1b6ca8", "#2b8a3e")) +
  scale_colour_manual(values = c("#d9480f", "#e67700", "#1b6ca8", "#2b8a3e")) +
  labs(
    title = "Overview of University Spending, Enrolment, and Tax Structure Across Income Groups",
    subtitle = "Observed five-year country-wave distributions (boxes show median and interquartile range; points show country-waves)",
    x = "World Bank Income Group",
    y = "Observed Value"
  ) +
  theme_pub(11)

save_pub_fig(p_data_overview, "eda_fig1_raw_distributions_and_bivariate", 10.2, 5.8)
if (dir.exists(file.path(repo_root, "eda", "figures"))) {
  ggsave(file.path(repo_root, "eda", "figures", "eda_fig1_raw_distributions_and_bivariate.pdf"), p_data_overview, width = 10.2, height = 5.8)
  ggsave(file.path(repo_root, "eda", "figures", "eda_fig1_raw_distributions_and_bivariate.png"), p_data_overview, width = 10.2, height = 5.8, dpi = 300)
}

# ==============================================================================
# Figure 2: Posterior Treatment Effects at +5 and +10 Years (Primary Model)
# ==============================================================================
cat("Generating Figure 2: Posterior Treatment Effects at +5 and +10 Years...\n")

draws_df <- read_csv(file.path(proc_dir, "mvbcf_ate_posterior_draws.csv"), show_col_types = FALSE)

draws_long <- draws_df %>%
  filter(model == "Mediator-Removed Direct Effect (M2)") %>%
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
        "1. Total Tax Revenue (% of GDP, pp)",
        "2. Direct Income & Profit Tax (% of GDP, pp)",
        "3. Direct Income & Profit Share of Tax (pp)",
        "4. Goods & Services Tax Share (pp)"
      )
    ),
    horizon = factor(horizon, levels = c("+5 years", "+10 years"))
  )

sum_fig2 <- draws_long %>%
  group_by(outcome_label, horizon) %>%
  summarise(
    mean_val = mean(ate_pp),
    q025 = quantile(ate_pp, 0.025),
    q10  = quantile(ate_pp, 0.10),
    q90  = quantile(ate_pp, 0.90),
    q975 = quantile(ate_pp, 0.975),
    prob_pos = mean(ate_pp > 0),
    .groups = "drop"
  )

p_fig2 <- ggplot(sum_fig2, aes(x = mean_val, y = horizon, colour = horizon)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "#829ab1", linewidth = 0.7) +
  geom_errorbar(
    aes(xmin = q025, xmax = q975),
    width = 0.16, linewidth = 0.75, orientation = "y"
  ) +
  geom_errorbar(
    aes(xmin = q10, xmax = q90),
    width = 0.0, linewidth = 2.2, orientation = "y"
  ) +
  geom_point(size = 3.6) +
  geom_text(
    aes(
      label = sprintf("%+.2f pp (P = %.2f)", mean_val, round(prob_pos + 1e-9, 2)),
      y = as.numeric(horizon) + 0.26
    ),
    size = 3.25, fontface = "bold", show.legend = FALSE
  ) +
  facet_wrap(~ outcome_label, ncol = 2, scales = "free_x") +
  scale_colour_manual(
    name = "Time Horizon After Funding Wave:",
    values = c("+5 years" = "#1b6ca8", "+10 years" = "#2b8a3e")
  ) +
  labs(
    title = "Estimated Effect of Above-Median Per-Student University Funding (+5 vs +10 Years)",
    subtitle = "Posterior mean effects (in percentage points, pp) with 80% (thick) and 95% (thin) credible intervals (CIs)",
    x = "Estimated Change in Tax Outcome (Percentage Points, pp)",
    y = "Time Horizon",
    caption = "Note: P is the posterior probability that the effect is greater than zero given the data, P(tau > 0 | data)."
  ) +
  theme_pub(11.5)

save_pub_fig(p_fig2, "fig2_total_vs_direct_tax_posteriors", 10.5, 5.8)

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
        "1. Per-Student Spending Ratio\n(% of GDP per person)",
        "2. Within-Country Per-Student Increase\n(>= +2.5 pp over 5-year wave)",
        "3. Real PPP Dollars per Student\n(removes GDP from denominator)",
        "4. University Budget % of GDP\n(removes student headcount)"
      ))
    ),
    outcome_clean = factor(
      outcome_index,
      levels = c(1, 2, 3),
      labels = c(
        "1. Total Tax Revenue (% of GDP, pp)",
        "2. Direct Income Tax (% of GDP, pp)",
        "3. Direct Income Tax Share (pp)"
      )
    )
  )

p_fig3 <- ggplot(fig3_df, aes(x = ate_mean, y = exposure_label, colour = outcome_clean)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "#829ab1", linewidth = 0.7) +
  geom_errorbar(aes(xmin = ate_cri95_low, xmax = ate_cri95_high), width = 0.2, linewidth = 0.7, orientation = "y") +
  geom_errorbar(aes(xmin = ate_cri80_low, xmax = ate_cri80_high), width = 0.0, linewidth = 1.9, orientation = "y") +
  geom_point(size = 3.2) +
  geom_text(
    aes(label = sprintf("%+.2f pp (P = %.2f)", ate_mean, round(prob_positive + 1e-9, 2))),
    vjust = -0.85, size = 2.95, fontface = "bold", show.legend = FALSE
  ) +
  facet_wrap(~ outcome_clean, ncol = 3, scales = "free_x") +
  scale_colour_manual(
    values = c(
      "1. Total Tax Revenue (% of GDP, pp)" = "#1b6ca8",
      "2. Direct Income Tax (% of GDP, pp)" = "#2b8a3e",
      "3. Direct Income Tax Share (pp)" = "#d9480f"
    ),
    guide = "none"
  ) +
  labs(
    title = "Comparing the Four Ways of Measuring University Funding (+10-Year Horizon)",
    subtitle = "Posterior mean effects (in percentage points, pp) with 80% (thick) and 95% (thin) credible intervals (CIs)",
    x = "+10-Year Effect on Tax Outcome (Percentage Points, pp)",
    y = "University Funding Measure",
    caption = "Note: P is the posterior probability that the effect is greater than zero given the data, P(tau > 0 | data)."
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

fig4_plot_df <- df_10y_ic %>%
  filter(!is.na(gross_tert_enrolment_pct), !is.na(m2_10y_tau_inc_tax_share_pp))

# Select notable extremes and running-example country-waves to label clearly
highlight_waves <- fig4_plot_df %>%
  filter(
    (iso3 == "IRL" & wave_label == "2005-2009") |
    (iso3 == "ETH" & wave_label == "1995-1999") |
    (iso3 == "MWI" & wave_label == "2010-2014") |
    (iso3 == "KHM" & wave_label == "2010-2014") |
    (iso3 == "ARM" & wave_label == "2010-2014") |
    (iso3 == "USA" & wave_label == "2010-2014") |
    (iso3 == "AUT" & wave_label == "2010-2014") |
    (iso3 == "CHL" & wave_label == "2010-2014") |
    (iso3 == "BRA" & wave_label == "2010-2014")
  ) %>%
  mutate(
    point_label = case_when(
      iso3 == "IRL" ~ "Ireland (2005-09: +3.01 pp)",
      iso3 == "ETH" ~ "Ethiopia (1995-99: -0.83 pp, >150% ratio)",
      iso3 == "MWI" ~ "Malawi (2010-14: -0.51 pp, >150% ratio)",
      iso3 == "KHM" ~ "Cambodia (2010-14: 5.9% ratio)",
      iso3 == "ARM" ~ "Armenia (2010-14: 7.1% ratio)",
      iso3 == "USA" ~ "United States (2010-14: +2.67 pp)",
      iso3 == "AUT" ~ "Austria (2010-14: +2.72 pp)",
      iso3 == "CHL" ~ "Chile (2010-14)",
      iso3 == "BRA" ~ "Brazil (2010-14)"
    )
  )

p_fig4 <- ggplot(
  fig4_plot_df,
  aes(x = gross_tert_enrolment_pct, y = m2_10y_tau_inc_tax_share_pp, colour = income_group)
) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "#829ab1", linewidth = 0.6) +
  geom_linerange(
    aes(ymin = m2_10y_tau_low80_inc_tax_share_pp, ymax = m2_10y_tau_high80_inc_tax_share_pp),
    alpha = 0.25, linewidth = 0.48
  ) +
  geom_point(alpha = 0.72, size = 2.1) +
  geom_point(data = highlight_waves, size = 3.2, shape = 21, fill = "white", stroke = 1.2, show.legend = FALSE) +
  ggrepel::geom_label_repel(
    data = highlight_waves,
    aes(label = point_label),
    size = 2.85,
    fontface = "bold",
    fill = "white",
    box.padding = 0.45,
    point.padding = 0.3,
    max.overlaps = 20,
    min.segment.length = 0,
    segment.colour = "#334e68",
    segment.size = 0.45,
    show.legend = FALSE,
    seed = 42
  ) +
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
    title = "Unit-Level +10-Year Effect on Income Tax Share by Starting University Enrolment",
    subtitle = "Posterior mean unit-level treatment effects (pp, with 80% CI bars and LOESS trend) across World Bank income groups",
    x = "Starting Gross Tertiary Enrolment Ratio (%)",
    y = "+10-Year Effect on Income Tax Share (pp)",
    caption = "Note: Vertical bars show 80% unit-level credible intervals (CIs); solid dark curve shows the LOESS trend.\nHighlighted points show notable extremes in spending ratios (>150% vs <8%) and 10-year effects (+3.01 pp in Ireland vs -0.83 pp in Ethiopia)."
  ) +
  theme_pub(11.5)

save_pub_fig(p_fig4, "fig4_enrolment_and_oecd_moderation", 9.8, 5.6)

# ==============================================================================
# Figure 5: Country Trajectories from MV-BCF (+5y and +10y) with Credible Fan
# ==============================================================================
cat("Generating Figure 5: MV-BCF Country Tax-Share Trajectories (+5y & +10y) with Uncertainty...\n")

df_5y_ic <- read_csv(file.path(proc_dir, "panel_5y_with_icates.csv"), show_col_types = FALSE)

inc_5y_row  <- tab1 %>% filter(model_id == "M2a_Direct_5y",  outcome_index == 3)
inc_10y_row <- tab1 %>% filter(model_id == "M2b_Direct_10y", outcome_index == 3)

global_ribbon_df <- tibble(
  years_after = c(0, 5, 10),
  ate_mean    = c(0.0, inc_5y_row$ate_mean,       inc_10y_row$ate_mean),
  cri95_low   = c(0.0, inc_5y_row$ate_cri95_low,  inc_10y_row$ate_cri95_low),
  cri95_high  = c(0.0, inc_5y_row$ate_cri95_high, inc_10y_row$ate_cri95_high),
  cri80_low   = c(0.0, inc_5y_row$ate_cri80_low,  inc_10y_row$ate_cri80_low),
  cri80_high  = c(0.0, inc_5y_row$ate_cri80_high, inc_10y_row$ate_cri80_high)
)

rep_countries <- tibble(
  iso3 = c("USA", "NOR", "AUT", "IRL", "CHL", "GBR", "ZAF"),
  iso2 = c("US",  "NO",  "AT",  "IE",  "CL",  "GB",  "ZA"),
  legend_label = c(
    "United States (US)", "Norway (NO)", "Austria (AT)",
    "Ireland (IE)", "Chile (CL)", "United Kingdom (GB)", "South Africa (ZA)"
  ),
  x_dodge = seq(-0.54, 0.54, length.out = 7)
)

country_summary_list <- list()
for (r_idx in seq_len(nrow(rep_countries))) {
  c_iso3 <- rep_countries$iso3[r_idx]
  s5  <- df_5y_ic %>% filter(iso3 == c_iso3)
  s10 <- df_10y_ic %>% filter(iso3 == c_iso3)
  country_summary_list[[r_idx]] <- tibble(
    iso3         = c_iso3,
    iso2         = rep_countries$iso2[r_idx],
    legend_label = rep_countries$legend_label[r_idx],
    x_dodge      = rep_countries$x_dodge[r_idx],
    m_5y         = mean(s5$m2_5y_tau_inc_tax_share_pp, na.rm = TRUE),
    l80_5y       = mean(s5$m2_5y_tau_low80_inc_tax_share_pp, na.rm = TRUE),
    h80_5y       = mean(s5$m2_5y_tau_high80_inc_tax_share_pp, na.rm = TRUE),
    m_10y        = mean(s10$m2_10y_tau_inc_tax_share_pp, na.rm = TRUE),
    l80_10y      = mean(s10$m2_10y_tau_low80_inc_tax_share_pp, na.rm = TRUE),
    h80_10y      = mean(s10$m2_10y_tau_high80_inc_tax_share_pp, na.rm = TRUE)
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
    y_label = space_labels(effect_pp, min_gap = 0.30)
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
      label = sprintf("%s: %+.2f pp [%+.2f, %+.2f]", iso2, effect_pp, low80, high80)
    ),
    hjust = 0, fontface = "bold", size = 3.0, show.legend = FALSE
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
    limits = c(0, 13.75)
  ) +
  scale_colour_manual(
    name = "Country (ISO-2):",
    values = c(
      "United States (US)" = "#d9480f",
      "Norway (NO)" = "#1b6ca8",
      "Austria (AT)" = "#2b8a3e",
      "Ireland (IE)" = "#0b7285",
      "Chile (CL)" = "#e67700",
      "United Kingdom (GB)" = "#5f3dc4",
      "South Africa (ZA)" = "#c92a2a"
    )
  ) +
  labs(
    title = "Five-Year and Ten-Year Trajectory of Direct Income & Profit Tax Share Across Countries",
    subtitle = "Multivariate BCF country trajectories with 80% credible intervals and global 80% / 95% posterior fan",
    x = "Years Following University Funding Wave",
    y = "Effect on Direct Income Tax Share (pp)",
    caption = "Note: Vertical bars and brackets show 80% country-level posterior credible intervals (CIs, horizontally dodged at +5y and +10y for visibility).\nGrey ribbons show the global average 80% (dark) and 95% (light) MV-BCF posterior credible fan (+1.24 pp at +5y; +1.48 pp at +10y)."
  ) +
  theme_pub(11.5)

save_pub_fig(p_fig5, "fig5_longitudinal_country_trajectories", 10.4, 5.8)

# ==============================================================================
# Appendix Figure A1: MCMC Trace Plots across the 4 Fiscal Outcomes (MV-BCF)
# ==============================================================================
cat("Generating Appendix Figure A1: MCMC Posterior Trace Plots (MV-BCF)...\n")

mvbcf_trace_df <- draws_long %>%
  filter(model == "Mediator-Removed Direct Effect (M2)") %>%
  mutate(
    series = factor(
      ifelse(horizon == "+5 years", "Multivariate BCF (+5 Years)", "Multivariate BCF (+10 Years)"),
      levels = c("Multivariate BCF (+5 Years)", "Multivariate BCF (+10 Years)")
    )
  ) %>%
  select(draw, series, outcome_label, ate_pp)

p_figA1 <- ggplot(mvbcf_trace_df, aes(x = draw, y = ate_pp, colour = series)) +
  geom_line(alpha = 0.78, linewidth = 0.45) +
  facet_wrap(~ outcome_label, ncol = 2, scales = "free_y") +
  scale_colour_manual(
    name = "Horizon:",
    values = c(
      "Multivariate BCF (+5 Years)" = "#1b6ca8",
      "Multivariate BCF (+10 Years)" = "#2b8a3e"
    )
  ) +
  labs(
    title = "Post-Burn-In MCMC Trace Plots for the Multivariate BCF Models (+5 and +10 Years)",
    subtitle = "1,250 retained post-burn-in MCMC draws across all four tax revenue outcomes",
    x = "Post-Burn-In MCMC Iteration",
    y = "Average Treatment Effect Draw (Percentage Points, pp)"
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

tabA1 <- draws_long %>%
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
# Appendix Table A2: Compute and Energy Report (Local C++ MCMC + Cloud LLM Queries)
# ==============================================================================
mvbcf_meta <- readLines(file.path(repo_root, "outputs", "models", "mvbcf_run_metadata.json"))
mvbcf_sec  <- as.numeric(gsub("[^0-9.]", "", mvbcf_meta[grepl("wall_clock_seconds", mvbcf_meta)]))
tot_sec    <- mvbcf_sec
# Assuming 25W average Apple Silicon CPU package power and 250 gCO2e/kWh Irish grid intensity
kwh_est    <- (tot_sec / 3600) * 0.025
co2_g_est  <- kwh_est * 250

tabA2 <- tribble(
  ~pipeline_stage, ~models_fitted, ~wall_clock_sec, ~est_energy_wh, ~est_co2e_grams,
  "Step 04: Local C++ MV-BCF & Benchmarks", "31 four-outcome MV-BCF / BART / LP / TWFE / DML fits (2,000 iter)", round(mvbcf_sec, 1), round(1000 * kwh_est, 2), round(co2_g_est, 2),
  "LLM Stage 1: Scoping & Data Pipeline", "45 queries (75k input / 53k output tokens)", NA_real_, 38.60, 9.65,
  "LLM Stage 2: C++ Sampler & Diagnostics", "26 queries (37k input / 29k output tokens)", NA_real_, 21.40, 5.35,
  "LLM Stage 3: Manuscript & Author Revisions", "287 queries (477k input / 292k output tokens)", NA_real_, 226.80, 56.70,
  "LLM Stage 4: Multi-Agent & External Peer Review", "261 queries (682k input / 361k output tokens)", NA_real_, 256.80, 64.20,
  "LLM Stage 5: Interactive Policy App & Testing", "134 queries (338k input / 204k output tokens)", NA_real_, 138.60, 34.65,
  "Subtotal: Cloud LLM Assistance", "753 queries (1.61M input / 0.94M output tokens)", NA_real_, 682.20, 170.55,
  "Total Project Footprint (Local C++ + Cloud LLM)", "31 MCMC models + 753 LLM queries (2.55M tokens)", round(tot_sec, 1), round(1000 * kwh_est + 682.20, 2), round(co2_g_est + 170.55, 2)
)
write_csv(tabA2, file.path(out_tab_dir, "tableA2_compute_and_energy.csv"))
write_csv(tabA2, file.path(res_tab_dir, "tableA2_compute_and_energy.csv"))
print(tabA2)

# ==============================================================================
# Appendix Table A4: Latest-Wave (2015-2019) Z=0 Countries, Costs & +10y Returns
# ==============================================================================
inc_meds <- df_clean %>%
  filter(!is.na(tert_spend_raw), !is.na(income_group)) %>%
  group_by(income_group) %>%
  summarise(med_spend_raw = median(tert_spend_raw, na.rm = TRUE), .groups = "drop")

cohort_factor <- df_clean %>%
  filter(!is.na(tert_spend_gdp_pct), !is.na(tert_spend_raw), !is.na(gross_tert_enrolment_pct)) %>%
  summarise(med_cf = median(tert_spend_gdp_pct / ((tert_spend_raw / 100) * (gross_tert_enrolment_pct / 100) * 100))) %>%
  pull(med_cf)

df_10y <- read_csv(file.path(proc_dir, "panel_10y_with_icates.csv"), show_col_types = FALSE)

ctry_cates <- df_10y %>%
  group_by(iso3) %>%
  summarise(
    tau10_tax_gdp = mean(m2_10y_tau_tax_gdp_pp, na.rm = TRUE),
    tau10_tax_gdp_low95 = mean(m2_10y_tau_low95_tax_gdp_pp, na.rm = TRUE),
    tau10_tax_gdp_high95 = mean(m2_10y_tau_high95_tax_gdp_pp, na.rm = TRUE),
    tau10_inc_gdp = mean(m2_10y_tau_inc_tax_gdp_pp, na.rm = TRUE),
    tau10_inc_gdp_low95 = mean(m2_10y_tau_low95_inc_tax_gdp_pp, na.rm = TRUE),
    tau10_inc_gdp_high95 = mean(m2_10y_tau_high95_inc_tax_gdp_pp, na.rm = TRUE),
    tau10_inc_share = mean(m2_10y_tau_inc_tax_share_pp, na.rm = TRUE),
    tau10_inc_share_low95 = mean(m2_10y_tau_low95_inc_tax_share_pp, na.rm = TRUE),
    tau10_inc_share_high95 = mean(m2_10y_tau_high95_inc_tax_share_pp, na.rm = TRUE),
    .groups = "drop"
  )

ctry_base_meta <- df_clean %>%
  group_by(iso3) %>%
  summarise(
    tert_spend_gdp_pct_ctry = mean(tert_spend_gdp_pct, na.rm = TRUE),
    gdp_per_capita_latest = dplyr::last(na.omit(gdp_per_capita_ppp_const2021), default = NA_real_),
    population_latest = dplyr::last(na.omit(population_total), default = NA_real_),
    .groups = "drop"
  )

tabA4 <- df_clean %>%
  filter(wave_label == "2015-2019", Z_regime_inc == 0) %>%
  left_join(inc_meds, by = "income_group") %>%
  left_join(ctry_cates, by = "iso3") %>%
  left_join(ctry_base_meta, by = "iso3") %>%
  filter(!is.na(tau10_inc_gdp)) %>%
  mutate(
    # Replace UNESCO near-zero reporting artefact for MDG 2015-2019 (0.036%) with its 2010-2014 value (99.1%, 0.32% GDP)
    tert_spend_raw = ifelse(tert_spend_raw < 1.0, 99.10, tert_spend_raw),
    tert_spend_gdp_pct = ifelse(!is.na(tert_spend_gdp_pct) & tert_spend_gdp_pct < 0.01, 0.320, tert_spend_gdp_pct),
    base_tert_gdp_pct = coalesce(tert_spend_gdp_pct,
                                 ifelse(is.finite(tert_spend_gdp_pct_ctry), tert_spend_gdp_pct_ctry, NA_real_),
                                 cohort_factor * (tert_spend_raw / 100) * (gross_tert_enrolment_pct / 100) * 100),
    gap_to_median_pp = round(med_spend_raw - tert_spend_raw, 2),
    near_boundary_flag = ifelse(gap_to_median_pp < 2.5, 1L, 0L),
    gdp_eur_bn = 0.92 * (gdp_per_capita_latest * population_latest) / 1e9,
    cost_to_thresh_gdp_pp = round(base_tert_gdp_pct * ((med_spend_raw - tert_spend_raw) / tert_spend_raw), 3),
    cost_to_thresh_eur_bn = round(gdp_eur_bn * (cost_to_thresh_gdp_pp / 100), 3),
    cost_plus2p5_gdp_pp = round(base_tert_gdp_pct * (2.5 / tert_spend_raw), 3),
    cost_plus2p5_eur_bn = round(gdp_eur_bn * (cost_plus2p5_gdp_pp / 100), 3),
    ret10_inc_eur_bn = round(gdp_eur_bn * (tau10_inc_gdp / 100), 2),
    ret10_inc_low95_eur_bn = round(gdp_eur_bn * (tau10_inc_gdp_low95 / 100), 2),
    ret10_inc_high95_eur_bn = round(gdp_eur_bn * (tau10_inc_gdp_high95 / 100), 2),
    income_group = factor(income_group, levels = c("High income", "Upper middle income", "Lower middle income", "Low income"))
  ) %>%
  arrange(income_group, gap_to_median_pp) %>%
  select(
    iso3, country_name, income_group, wave_label,
    tert_spend_raw, med_spend_raw, gap_to_median_pp, near_boundary_flag,
    cost_to_thresh_gdp_pp, cost_to_thresh_eur_bn,
    cost_plus2p5_gdp_pp, cost_plus2p5_eur_bn,
    tau10_inc_gdp, tau10_inc_gdp_low95, tau10_inc_gdp_high95,
    ret10_inc_eur_bn, ret10_inc_low95_eur_bn, ret10_inc_high95_eur_bn,
    tau10_inc_share, tau10_inc_share_low95, tau10_inc_share_high95
  )

write_csv(tabA4, file.path(out_tab_dir, "tableA4_latest_z0_countries_costs_and_returns.csv"))
write_csv(tabA4, file.path(res_tab_dir, "tableA4_latest_z0_countries_costs_and_returns.csv"))
cat(sprintf("Saved Table A4 (%d latest-wave Z=0 countries with +10y CATEs)\n", nrow(tabA4)))

cat("All figures and diagnostics generated and saved to outputs/, results/, and paper/figures/!\n")
