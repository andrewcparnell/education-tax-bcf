#!/usr/bin/env Rscript
# ==============================================================================
# Step 06: Generate Publication Figures, Continuous-Z Residual & Holdout
#          Validation Diagnostics, and Compute/Energy Report
# (src/r/06_generate_figures_and_diagnostics.R)
#
# Style rules enforced:
#   - British English throughout (enrolment, colour, modelled, winsorised, etc.)
#   - Zero em dashes (uses ' - ', colons, or parentheses)
#   - Continuous treatment Z in MV-BCF (Scaling A: +10 pp ratio; Scaling B: +25% log)
#   - Two-letter ISO-2 country codes in legends and labelled directly on lines
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(ggplot2)
  library(ggrepel)
  library(grid)
  library(patchwork)
  library(ranger)
})

repo_root <- getwd()
if (!dir.exists(file.path(repo_root, "src")) && dir.exists(file.path(dirname(dirname(repo_root)), "src"))) {
  repo_root <- dirname(dirname(repo_root))
}
proc_dir    <- file.path(repo_root, "data", "processed")
out_tab_dir <- file.path(repo_root, "outputs", "tables")
out_fig_dir <- file.path(repo_root, "outputs", "figures")
pap_fig_dir <- file.path(repo_root, "paper", "figures")

for (d in c(out_tab_dir, out_fig_dir, pap_fig_dir)) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
}

save_pub_fig <- function(p, fname_base, width, height) {
  for (dir_path in c(out_fig_dir, pap_fig_dir)) {
    ggsave(file.path(dir_path, paste0(fname_base, ".png")), p, width = width, height = height, dpi = 300)
    ggsave(file.path(dir_path, paste0(fname_base, ".pdf")), p, width = width, height = height)
  }
}

theme_pub <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", size = base_size + 1.5, colour = "#0f2537", margin = margin(b = 4)),
      plot.subtitle = element_text(size = base_size - 0.5, colour = "#334e68", margin = margin(b = 10)),
      plot.caption = element_text(size = base_size - 2, colour = "#627d98", hjust = 0, margin = margin(t = 8)),
      axis.title = element_text(face = "bold", size = base_size, colour = "#102a43"),
      axis.text = element_text(size = base_size - 1, colour = "#243b53"),
      strip.text = element_text(face = "bold", size = base_size - 0.5, colour = "#0f2537"),
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
# Figure 1: Overall Structural Schematic of the Paper (Continuous-Z Design)
# ==============================================================================
cat("Generating Figure 1: Structural Schematic of the Study...\n")

boxes <- tibble(
  xmin = c(0.15, 3.55, 3.55, 6.95),
  xmax = c(3.05, 6.45, 6.45, 9.85),
  ymin = c(0.85, 3.25, 0.85, 0.85),
  ymax = c(5.45, 5.45, 2.90, 5.45),
  fill = c("#e6f2f8", "#edf7ed", "#fff4e6", "#f0f4f8"),
  border = c("#1b6ca8", "#2b8a3e", "#d9480f", "#0f2537"),
  header = c(
    "1. Four Ways of Measuring\nUniversity Funding (Z1 to Z4)",
    "2A. Starting Country Context (X)\n(Measured Before Funding)",
    "2B. Follow-Up Macro Controls (X)\n(During 5- & 10-Year Window)",
    "3. Four Future Tax Outcomes\n(Y1 to Y4, Modelled Jointly)"
  ),
  body = c(
    paste(
      "(Tested in turn across models)",
      "",
      "Z1: Per-Student Spending Ratio",
      "    (% of GDP per person)",
      "Z2: 5-Year Spending Change",
      "    (within-country change in Z1)",
      "Z3: Real Dollars per Student",
      "    (2021 PPP $, log scale)",
      "Z4: University Budget Share",
      "    (% of total GDP)",
      sep = "\n"
    ),
    paste(
      "* Starting GDP & Tax Structure",
      "* Prior 5-Year Economic Growth",
      "* University & School Enrolment",
      "* Demographics & Inequality",
      "* Predicted Funding from History",
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
      "(Estimated together at +5y & +10y)",
      "",
      "Y1: Total Non-Resource Tax",
      "    (% of GDP)",
      "Y2: Direct Income & Profit Tax",
      "    (% of GDP)",
      "Y3: Direct Income Tax Share",
      "    (% of Total Tax Revenue)",
      "Y4: Goods & Services Tax Share",
      "    (% of Total Tax Revenue)",
      sep = "\n"
    )
  )
)

arrows_df <- tibble(
  x    = c(3.52, 3.08, 6.48, 6.48, 5.00),
  y    = c(4.35, 2.05, 4.35, 1.85, 3.22),
  xend = c(3.08, 3.52, 6.92, 6.92, 5.00),
  yend = c(4.15, 1.85, 4.00, 2.25, 2.93)
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
    fontface = "bold", size = 4.2, colour = "#0f2537", lineheight = 1.05
  ) +
  geom_text(
    data = boxes,
    aes(x = xmin + 0.16, y = (ymin + ymax) / 2 - 0.22, label = body),
    hjust = 0, size = 3.65, colour = "#102a43", lineheight = 1.14
  ) +
  geom_segment(
    data = arrows_df,
    aes(x = x, y = y, xend = xend, yend = yend),
    arrow = arrow(length = unit(0.24, "cm"), type = "closed"),
    linewidth = 0.9, colour = "#243b53"
  ) +
  coord_cartesian(xlim = c(0, 10), ylim = c(0.65, 5.65), expand = FALSE) +
  theme_void() +
  theme(plot.background = element_rect(fill = "white", colour = NA))

save_pub_fig(p_fig1, "fig1_structural_schematic", 10.8, 5.0)

# ==============================================================================
# Section 3 Data Summary Figure: Raw Data Overview Across Income Groups
# (Saved to outputs/figures and paper/figures as fig0_panel_data_overview)
# ==============================================================================
cat("Generating Section 3 Data Summary Figure (fig0_panel_data_overview)...\n")

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
    `A. Per-Student Spending Ratio (Z1, % of GDP/person)` = tert_spend_per_student_winsor,
    `B. Real Spending per Student (Z3, 2021 PPP $)` = real_tert_spend_per_student_ppp,
    `C. Gross Tertiary Enrolment Ratio (%)` = gross_tert_enrolment_pct,
    `D. Direct Income Tax Share (Y3, % of Total Tax)` = income_profit_tax_share_rev_pct
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
    x = "World Bank Income Group",
    y = "Observed Value"
  ) +
  theme_pub(11)

save_pub_fig(p_data_overview, "fig0_panel_data_overview", 10.2, 5.5)

# ==============================================================================
# Figure 2: Posterior Continuous Treatment Slopes at +5 and +10 Years (Primary Model)
# ==============================================================================
cat("Generating Figure 2: Posterior Continuous Treatment Slopes (+5y vs +10y)...\n")

tab1 <- read_csv(file.path(out_tab_dir, "table1_mvbcf_ate_posteriors.csv"), show_col_types = FALSE)

fig2_df <- tab1 %>%
  filter(model_id %in% c("M2a_Direct_10pp_5y", "M2b_Direct_10pp_10y")) %>%
  mutate(
    horizon_short = factor(
      ifelse(grepl("5y$", model_id), "+5 years", "+10 years"),
      levels = c("+5 years", "+10 years")
    ),
    outcome_label = factor(
      outcome_index,
      levels = c(1, 2, 3, 4),
      labels = c(
        "Y1: Total Non-Resource Tax (% of GDP, pp)",
        "Y2: Direct Income & Profit Tax (% of GDP, pp)",
        "Y3: Direct Income & Profit Share of Tax (pp)",
        "Y4: Goods & Services Tax Share (pp)"
      )
    )
  )

p_fig2 <- ggplot(fig2_df, aes(x = ate_mean, y = horizon_short, colour = horizon_short)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "#829ab1", linewidth = 0.7) +
  geom_errorbar(
    aes(xmin = ate_cri95_low, xmax = ate_cri95_high),
    width = 0.16, linewidth = 0.75, orientation = "y"
  ) +
  geom_errorbar(
    aes(xmin = ate_cri80_low, xmax = ate_cri80_high),
    width = 0.0, linewidth = 2.2, orientation = "y"
  ) +
  geom_point(size = 3.5) +
  geom_text(
    aes(
      label = sprintf("%+.2f pp (P = %.2f)", ate_mean, round(prob_positive + 1e-9, 2)),
      y = as.numeric(horizon_short) + 0.26
    ),
    size = 3.2, fontface = "bold", show.legend = FALSE
  ) +
  facet_wrap(~ outcome_label, ncol = 2, scales = "free_x") +
  scale_colour_manual(
    name = "Time Horizon After Funding Wave:",
    values = c("+5 years" = "#1b6ca8", "+10 years" = "#2b8a3e")
  ) +
  labs(
    title = "Estimated Effect of a +10 pp Increase in Per-Student University Funding (Z1) at +5 and +10 Years",
    x = "Estimated Change in Tax Outcome per +10 pp Funding Increase (Percentage Points, pp)",
    y = "Time Horizon"
  ) +
  theme_pub(11.5)

save_pub_fig(p_fig2, "fig2_total_vs_direct_tax_posteriors", 10.5, 5.4)

# ==============================================================================
# Figure 3: Unbundling the Tertiary Denominator Trap (Continuous Exposures, +10y)
# ==============================================================================
cat("Generating Figure 3: Unbundled Continuous Tertiary Spending Exposures (+10 Years)...\n")

fig3_df <- tab1 %>%
  filter(
    horizon == "+10 years (t+2)",
    model_id %in% c("M2b_Direct_10pp_10y", "M3b_Delta10pp_10y", "M3d_RealPPP_10y", "M3f_TertGDP_10y"),
    outcome_index %in% c(1, 2, 3)
  ) %>%
  mutate(
    exposure_label = factor(
      model_id,
      levels = rev(c("M2b_Direct_10pp_10y", "M3b_Delta10pp_10y", "M3d_RealPPP_10y", "M3f_TertGDP_10y")),
      labels = rev(c(
        "Z1: Per-Student Spending Ratio\n(+10 pp of GDP per person)",
        "Z2: Within-Country 5y Change\n(+10 pp per-student change)",
        "Z3: Real PPP Dollars per Student\n(+25% log, no GDP denominator)",
        "Z4: University Budget % of GDP\n(+0.25 pp, no student denominator)"
      ))
    ),
    outcome_clean = factor(
      outcome_index,
      levels = c(1, 2, 3),
      labels = c(
        "Y1: Total Non-Resource Tax (% of GDP)",
        "Y2: Direct Income Tax (% of GDP)",
        "Y3: Direct Income Tax Share (%)"
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
      "Y1: Total Non-Resource Tax (% of GDP)" = "#1b6ca8",
      "Y2: Direct Income Tax (% of GDP)" = "#2b8a3e",
      "Y3: Direct Income Tax Share (%)" = "#d9480f"
    ),
    guide = "none"
  ) +
  labs(
    title = "Comparing the Four Ways of Measuring University Funding (Z1 to Z4) at the +10-Year Horizon",
    x = "+10-Year Change in Tax Outcome (Percentage Points, pp)",
    y = "University Funding Measure"
  ) +
  theme_pub(11)

save_pub_fig(p_fig3, "fig3_denominator_unbundling_horserace", 11.4, 4.9)

# ==============================================================================
# Figure 4: Subgroup Heterogeneity by Enrolment Tier & World Bank Income Group
# ==============================================================================
cat("Generating Figure 4: Subgroup Moderation by Enrolment Tier & Income Group...\n")

df_10y_ic <- read_csv(file.path(proc_dir, "panel_10y_with_icates.csv"), show_col_types = FALSE) %>%
  mutate(
    income_group = factor(income_group, levels = c(
      "Low income", "Lower middle income", "Upper middle income", "High income"
    ))
  )

tab3 <- read_csv(file.path(out_tab_dir, "table3_subgroup_cates.csv"), show_col_types = FALSE)

fig4_sub_df <- tab3 %>%
  filter(
    horizon == "+10 years (t+2)",
    dimension %in% c("Tertiary Enrolment Regime (Scaling A)", "World Bank Income Group (Scaling A)")
  ) %>%
  mutate(
    subgroup_clean = case_when(
      subgroup == "1. Elite (<20% enrolment)" ~ "Elite Enrolment (<20%)",
      subgroup == "2. Massifying (20-50% enrolment)" ~ "Massifying (20-50%)",
      subgroup == "3. High-Participation (>=50% enrolment)" ~ "High-Participation (>=50%)",
      subgroup == "Low income" ~ "Low Income",
      subgroup == "Lower middle income" ~ "Lower Middle Income",
      subgroup == "Upper middle income" ~ "Upper Middle Income",
      subgroup == "High income" ~ "High Income",
      TRUE ~ subgroup
    ),
    subgroup_clean = factor(
      subgroup_clean,
      levels = rev(c(
        "Elite Enrolment (<20%)",
        "Massifying (20-50%)",
        "High-Participation (>=50%)",
        "Low Income",
        "Lower Middle Income",
        "Upper Middle Income",
        "High Income"
      ))
    ),
    group_type = ifelse(
      grepl("Enrolment", dimension),
      "By Starting Enrolment Tier",
      "By World Bank Income Group"
    )
  )

fig4_long <- bind_rows(
  fig4_sub_df %>% transmute(
    subgroup_clean, group_type,
    outcome_clean = "Y1: Total Non-Resource Tax (% of GDP)",
    mean_pp = cate_tax_gdp_pp, low95 = cate_tax_gdp_low, high95 = cate_tax_gdp_high, prob_pos = prob_tax_gdp_pos
  ),
  fig4_sub_df %>% transmute(
    subgroup_clean, group_type,
    outcome_clean = "Y2: Direct Income Tax (% of GDP)",
    mean_pp = cate_inc_gdp_pp, low95 = cate_inc_gdp_low, high95 = cate_inc_gdp_high, prob_pos = prob_inc_gdp_pos
  ),
  fig4_sub_df %>% transmute(
    subgroup_clean, group_type,
    outcome_clean = "Y3: Direct Income Tax Share (%)",
    mean_pp = cate_inc_share_pp, low95 = cate_inc_share_low, high95 = cate_inc_share_high, prob_pos = prob_inc_share_pos
  )
) %>%
  mutate(
    outcome_clean = factor(
      outcome_clean,
      levels = c(
        "Y1: Total Non-Resource Tax (% of GDP)",
        "Y2: Direct Income Tax (% of GDP)",
        "Y3: Direct Income Tax Share (%)"
      )
    )
  )

p_fig4 <- ggplot(fig4_long, aes(x = mean_pp, y = subgroup_clean, colour = group_type)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "#829ab1", linewidth = 0.7) +
  geom_hline(yintercept = 4.5, linetype = "dotted", colour = "#94a3b8", linewidth = 0.6) +
  geom_errorbar(aes(xmin = low95, xmax = high95), width = 0.22, linewidth = 0.75, orientation = "y") +
  geom_point(size = 3.2) +
  geom_text(
    aes(label = sprintf("%+.2f pp (P = %.2f)", mean_pp, round(prob_pos + 1e-9, 2))),
    vjust = -0.82, size = 2.9, fontface = "bold", show.legend = FALSE
  ) +
  facet_wrap(~ outcome_clean, ncol = 3, scales = "free_x") +
  scale_colour_manual(
    name = "Subgroup Dimension:",
    values = c(
      "By Starting Enrolment Tier" = "#1b6ca8",
      "By World Bank Income Group" = "#2b8a3e"
    )
  ) +
  labs(
    title = "Subgroup +10-Year Effects by University Enrolment Tier and Income Group",
    x = "+10-Year Change per +10 pp Per-Student Funding Increase (Percentage Points, pp)",
    y = "Country Subgroup"
  ) +
  theme_pub(11)

save_pub_fig(p_fig4, "fig4_enrolment_and_oecd_moderation", 11.4, 5.4)

# ==============================================================================
# Figure 5: 5-Year to 10-Year Cohort Maturation Trajectories by Income Group
#           (with individual country-wave estimates showing 65.5% < 0 at +5y)
# ==============================================================================
cat("Generating Figure 5: MV-BCF 5-Year to 10-Year Trajectories by Income Group...\n")

df_5y_ic <- read_csv(file.path(proc_dir, "panel_5y_with_icates.csv"), show_col_types = FALSE) %>%
  mutate(
    income_group = factor(income_group, levels = c(
      "Low income", "Lower middle income", "Upper middle income", "High income"
    ))
  )

tax_5y_row  <- tab1 %>% filter(model_id == "M2a_Direct_10pp_5y",  outcome_index == 1)
tax_10y_row <- tab1 %>% filter(model_id == "M2b_Direct_10pp_10y", outcome_index == 1)
inc_5y_row  <- tab1 %>% filter(model_id == "M2a_Direct_10pp_5y",  outcome_index == 3)
inc_10y_row <- tab1 %>% filter(model_id == "M2b_Direct_10pp_10y", outcome_index == 3)

global_ribbon_df <- bind_rows(
  tibble(
    panel_label = "A. Total Non-Resource Tax (Y1, % of GDP)",
    years_after = c(0, 5, 10),
    ate_mean    = c(0.0, tax_5y_row$ate_mean,       tax_10y_row$ate_mean),
    cri95_low   = c(0.0, tax_5y_row$ate_cri95_low,  tax_10y_row$ate_cri95_low),
    cri95_high  = c(0.0, tax_5y_row$ate_cri95_high, tax_10y_row$ate_cri95_high),
    cri80_low   = c(0.0, tax_5y_row$ate_cri80_low,  tax_10y_row$ate_cri80_low),
    cri80_high  = c(0.0, tax_5y_row$ate_cri80_high, tax_10y_row$ate_cri80_high)
  ),
  tibble(
    panel_label = "B. Direct Income Tax Share of Revenue (Y3, %)",
    years_after = c(0, 5, 10),
    ate_mean    = c(0.0, inc_5y_row$ate_mean,       inc_10y_row$ate_mean),
    cri95_low   = c(0.0, inc_5y_row$ate_cri95_low,  inc_10y_row$ate_cri95_low),
    cri95_high  = c(0.0, inc_5y_row$ate_cri95_high, inc_10y_row$ate_cri95_high),
    cri80_low   = c(0.0, inc_5y_row$ate_cri80_low,  inc_10y_row$ate_cri80_low),
    cri80_high  = c(0.0, inc_5y_row$ate_cri80_high, inc_10y_row$ate_cri80_high)
  )
)

# Individual country-wave point estimates at +5y (N = 371) and +10y (N = 283)
set.seed(20261109)
pts_ic_df <- bind_rows(
  df_5y_ic %>%
    filter(!is.na(income_group)) %>%
    transmute(
      group_label = factor(income_group, levels = c("Low income", "Lower middle income", "Upper middle income", "High income"),
                           labels = c("Low Income", "Lower Middle Income", "Upper Middle Income", "High Income")),
      panel_label = "A. Total Non-Resource Tax (Y1, % of GDP)",
      years_after = 5 + runif(n(), -0.45, 0.45),
      slope_pp = pmax(pmin(m2_5y_tau_tax_gdp_pp, 0.85), -0.65)
    ),
  df_10y_ic %>%
    filter(!is.na(income_group)) %>%
    transmute(
      group_label = factor(income_group, levels = c("Low income", "Lower middle income", "Upper middle income", "High income"),
                           labels = c("Low Income", "Lower Middle Income", "Upper Middle Income", "High Income")),
      panel_label = "A. Total Non-Resource Tax (Y1, % of GDP)",
      years_after = 10 + runif(n(), -0.45, 0.45),
      slope_pp = pmax(pmin(m2_10y_tau_tax_gdp_pp, 0.85), -0.65)
    ),
  df_5y_ic %>%
    filter(!is.na(income_group)) %>%
    transmute(
      group_label = factor(income_group, levels = c("Low income", "Lower middle income", "Upper middle income", "High income"),
                           labels = c("Low Income", "Lower Middle Income", "Upper Middle Income", "High Income")),
      panel_label = "B. Direct Income Tax Share of Revenue (Y3, %)",
      years_after = 5 + runif(n(), -0.45, 0.45),
      slope_pp = pmax(pmin(m2_5y_tau_inc_tax_share_pp, 1.50), -0.65)
    ),
  df_10y_ic %>%
    filter(!is.na(income_group)) %>%
    transmute(
      group_label = factor(income_group, levels = c("Low income", "Lower middle income", "Upper middle income", "High income"),
                           labels = c("Low Income", "Lower Middle Income", "Upper Middle Income", "High Income")),
      panel_label = "B. Direct Income Tax Share of Revenue (Y3, %)",
      years_after = 10 + runif(n(), -0.45, 0.45),
      slope_pp = pmax(pmin(m2_10y_tau_inc_tax_share_pp, 1.50), -0.65)
    )
)

annot_5y_df <- tibble(
  panel_label = "A. Total Non-Resource Tax (Y1, % of GDP)",
  x = 5.0,
  y = -0.52,
  label = "243 of 371 country-waves (65.5%) < 0 at +5y\n(student lock-in effect)"
)

inc_groups_5y <- df_5y_ic %>%
  filter(!is.na(income_group)) %>%
  group_by(income_group) %>%
  summarise(
    tax_5y = mean(m2_5y_tau_tax_gdp_pp, na.rm = TRUE),
    inc_5y = mean(m2_5y_tau_inc_tax_share_pp, na.rm = TRUE),
    .groups = "drop"
  )

inc_groups_10y <- tab3 %>%
  filter(horizon == "+10 years (t+2)", dimension == "World Bank Income Group (Scaling A)") %>%
  transmute(
    income_group = factor(subgroup, levels = c(
      "Low income", "Lower middle income", "Upper middle income", "High income"
    )),
    tax_10y = cate_tax_gdp_pp,
    inc_10y = cate_inc_share_pp
  )

traj_joined <- inner_join(inc_groups_5y, inc_groups_10y, by = "income_group") %>%
  mutate(
    group_label = factor(
      income_group,
      levels = c("Low income", "Lower middle income", "Upper middle income", "High income"),
      labels = c("Low Income", "Lower Middle Income", "Upper Middle Income", "High Income")
    )
  )

traj_long <- bind_rows(
  traj_joined %>% transmute(group_label, panel_label = "A. Total Non-Resource Tax (Y1, % of GDP)", years_after = 0,  slope_pp = 0.0),
  traj_joined %>% transmute(group_label, panel_label = "A. Total Non-Resource Tax (Y1, % of GDP)", years_after = 5,  slope_pp = tax_5y),
  traj_joined %>% transmute(group_label, panel_label = "A. Total Non-Resource Tax (Y1, % of GDP)", years_after = 10, slope_pp = tax_10y),
  traj_joined %>% transmute(group_label, panel_label = "B. Direct Income Tax Share of Revenue (Y3, %)", years_after = 0,  slope_pp = 0.0),
  traj_joined %>% transmute(group_label, panel_label = "B. Direct Income Tax Share of Revenue (Y3, %)", years_after = 5,  slope_pp = inc_5y),
  traj_joined %>% transmute(group_label, panel_label = "B. Direct Income Tax Share of Revenue (Y3, %)", years_after = 10, slope_pp = inc_10y)
)

space_labels <- function(y_vals, min_gap = 0.10) {
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

end_labels_df <- traj_long %>%
  filter(years_after == 10) %>%
  group_by(panel_label) %>%
  mutate(
    short_group = case_when(
      group_label == "Lower Middle Income" ~ "Lower Middle",
      group_label == "Upper Middle Income" ~ "Upper Middle",
      TRUE ~ as.character(group_label)
    ),
    y_label = space_labels(slope_pp, min_gap = ifelse(grepl("^A\\.", first(panel_label)), 0.085, 0.12)),
    text_label = sprintf("%s (%+.2f pp)", short_group, slope_pp)
  ) %>%
  ungroup()

p_fig5 <- ggplot() +
  geom_ribbon(
    data = global_ribbon_df,
    aes(x = years_after, ymin = cri95_low, ymax = cri95_high),
    fill = "#cbd5e1", alpha = 0.35
  ) +
  geom_ribbon(
    data = global_ribbon_df,
    aes(x = years_after, ymin = cri80_low, ymax = cri80_high),
    fill = "#94a3b8", alpha = 0.35
  ) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "#64748b", linewidth = 0.65) +
  geom_point(
    data = pts_ic_df,
    aes(x = years_after, y = slope_pp, colour = group_label),
    size = 1.15, alpha = 0.28, show.legend = FALSE
  ) +
  geom_line(
    data = global_ribbon_df,
    aes(x = years_after, y = ate_mean),
    colour = "#0f2537", linetype = "dotted", linewidth = 0.95
  ) +
  geom_line(
    data = traj_long,
    aes(x = years_after, y = slope_pp, colour = group_label, group = group_label),
    linewidth = 1.15
  ) +
  geom_point(
    data = traj_long,
    aes(x = years_after, y = slope_pp, colour = group_label),
    size = 2.8
  ) +
  geom_label(
    data = annot_5y_df,
    aes(x = x, y = y, label = label),
    size = 2.75, fontface = "bold", colour = "#0f2537", fill = "white", alpha = 0.90, linewidth = 0.25
  ) +
  geom_segment(
    data = end_labels_df,
    aes(x = 10.12, y = slope_pp, xend = 10.55, yend = y_label, colour = group_label),
    linewidth = 0.45, linetype = "dotted", show.legend = FALSE
  ) +
  geom_text(
    data = end_labels_df,
    aes(x = 10.62, y = y_label, colour = group_label, label = text_label),
    hjust = 0, fontface = "bold", size = 2.95, show.legend = FALSE
  ) +
  facet_wrap(~ panel_label, ncol = 2, scales = "free_y") +
  scale_x_continuous(
    breaks = c(0, 5, 10),
    labels = c("Baseline (0y)", "+5 Years", "+10 Years"),
    limits = c(0, 15.8)
  ) +
  scale_colour_manual(
    name = "World Bank Income Group:",
    values = c(
      "Low Income" = "#d9480f",
      "Lower Middle Income" = "#e67700",
      "Upper Middle Income" = "#1b6ca8",
      "High Income" = "#2b8a3e"
    )
  ) +
  labs(
    title = "Five-Year and Ten-Year Cohort Maturation Trajectories Across Income Groups",
    x = "Years Following University Funding Wave",
    y = "Estimated Change per +10 pp Funding Increase (pp)"
  ) +
  theme_pub(11)

save_pub_fig(p_fig5, "fig5_longitudinal_country_trajectories", 11.2, 5.2)

# ==============================================================================
# Figure 6 (Main Text): Single Clean Out-of-Sample Country Cross-Validation Figure
# ==============================================================================
cat("Generating Figure 6: Out-of-Sample Country Cross-Validation...\n")

cv_tab_main <- read_csv(file.path(out_tab_dir, "table_holdout_country_validation.csv"), show_col_types = FALSE) %>%
  filter(
    split_type == "5-Fold Country-Blocked CV (All 112 Countries, +10y)",
    outcome_code %in% c("tax_gdp_pp", "inc_tax_gdp_pp", "inc_tax_share_pp"),
    model %in% c(
      "1. MV-BCF Scaling A (Z_cont_10pp)",
      "5. Ridge Regression (L2)",
      "6. Linear Local Projections (OLS)",
      "7. Historical Training Mean",
      "8. Zero-Change Baseline (Delta Y = 0)"
    )
  ) %>%
  mutate(
    outcome_short = factor(
      outcome_code,
      levels = c("tax_gdp_pp", "inc_tax_gdp_pp", "inc_tax_share_pp"),
      labels = c("Y1: Non-Resource Tax / GDP", "Y2: Direct Income Tax / GDP", "Y3: Direct Income Tax Share")
    ),
    model_short = factor(
      model,
      levels = rev(c(
        "1. MV-BCF Scaling A (Z_cont_10pp)",
        "7. Historical Training Mean",
        "5. Ridge Regression (L2)",
        "8. Zero-Change Baseline (Delta Y = 0)",
        "6. Linear Local Projections (OLS)"
      )),
      labels = rev(c(
        "MV-BCF (Z1, +10 pp)",
        "Historical Training Mean",
        "Ridge Regression (L2)",
        "Zero-Change Persistence",
        "Linear Local Projections"
      ))
    ),
    is_mvbcf = ifelse(grepl("MV-BCF", model), "Continuous MV-BCF", "Benchmark Baseline")
  )

p_fig6 <- ggplot(cv_tab_main, aes(x = crps, y = model_short, fill = is_mvbcf)) +
  geom_col(width = 0.65, alpha = 0.88) +
  geom_text(aes(label = sprintf("%.2f (RMSE %.2f)", crps, rmse)), hjust = -0.05, size = 2.8, fontface = "bold", colour = "#102a43") +
  facet_wrap(~ outcome_short, ncol = 3, scales = "free_x") +
  scale_x_continuous(expand = expansion(mult = c(0, 0.78))) +
  scale_fill_manual(
    name = "Model Family:",
    values = c("Continuous MV-BCF" = "#2b8a3e", "Benchmark Baseline" = "#94a3b8")
  ) +
  labs(
    title = "Out-of-Sample Forecast Error Across 5-Fold Country-Blocked Cross-Validation (112 Countries)",
    x = "Out-of-Sample Continuous Ranked Probability Score (CRPS, lower is better)",
    y = NULL
  ) +
  theme_pub(11)

save_pub_fig(p_fig6, "fig6_scaling_fit_and_holdout_validation", 11.4, 4.2)

# ==============================================================================
# Appendix Figure A2: Head-to-Head Comparison of Scaling A (+10 pp Ratio)
#                     vs Scaling B (+25% Relative Log Increase)
# ==============================================================================
cat("Generating Appendix Figure A2: Head-to-Head Comparison of Scaling A vs Scaling B...\n")

figA2_slopes_df <- tab1 %>%
  filter(model_id %in% c("M2a_Direct_10pp_5y", "M2b_Direct_10pp_10y", "M2c_Direct_Log25_5y", "M2d_Direct_Log25_10y")) %>%
  mutate(
    spec_label = factor(
      model_id,
      levels = rev(c("M2a_Direct_10pp_5y", "M2b_Direct_10pp_10y", "M2c_Direct_Log25_5y", "M2d_Direct_Log25_10y")),
      labels = rev(c(
        "Scaling A (+10 pp): +5y",
        "Scaling A (+10 pp): +10y",
        "Scaling B (+25% Log): +5y",
        "Scaling B (+25% Log): +10y"
      ))
    ),
    scaling_group = ifelse(grepl("10pp", model_id), "Scaling A: +10 pp of GDP/person Ratio", "Scaling B: +25% Relative Log Increase"),
    outcome_short = factor(
      outcome_index,
      levels = c(1, 2, 3, 4),
      labels = c(
        "Y1: Non-Resource Tax / GDP",
        "Y2: Direct Income Tax / GDP",
        "Y3: Direct Income Tax Share",
        "Y4: Goods & Services Share"
      )
    )
  )

p_figA2_a <- ggplot(figA2_slopes_df, aes(x = ate_mean, y = spec_label, colour = scaling_group)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "#829ab1", linewidth = 0.65) +
  geom_errorbar(aes(xmin = ate_cri95_low, xmax = ate_cri95_high), width = 0.18, linewidth = 0.7, orientation = "y") +
  geom_errorbar(aes(xmin = ate_cri80_low, xmax = ate_cri80_high), width = 0.0, linewidth = 2.0, orientation = "y") +
  geom_point(size = 2.8) +
  geom_text(
    aes(label = sprintf("%+.2f (P=%.2f)", ate_mean, round(prob_positive + 1e-9, 2)), y = as.numeric(spec_label) + 0.28),
    size = 2.65, fontface = "bold", show.legend = FALSE
  ) +
  facet_wrap(~ outcome_short, ncol = 4, scales = "free_x") +
  scale_colour_manual(
    name = "Funding Scaling:",
    values = c("Scaling A: +10 pp of GDP/person Ratio" = "#1b6ca8", "Scaling B: +25% Relative Log Increase" = "#2b8a3e")
  ) +
  labs(
    title = "A. Posterior Effects Under Scaling A (+10 pp Ratio) vs Scaling B (+25% Relative Log)",
    x = "Posterior Change (Percentage Points per Funding Unit)",
    y = NULL
  ) +
  theme_pub(10.5)

resid_ab_df <- read_csv(file.path(proc_dir, "mvbcf_residuals_and_fit.csv"), show_col_types = FALSE) %>%
  filter(
    specification == "Mediator-Removed Direct Effect (M2)",
    horizon == "+10 years",
    outcome_code %in% c("tax_gdp_pp", "inc_tax_gdp_pp", "inc_tax_share_pp")
  ) %>%
  mutate(
    outcome_short = factor(
      outcome_code,
      levels = c("tax_gdp_pp", "inc_tax_gdp_pp", "inc_tax_share_pp"),
      labels = c("Y1: Non-Resource Tax / GDP", "Y2: Direct Income Tax / GDP", "Y3: Direct Income Tax Share")
    ),
    scaling_short = ifelse(grepl("Scaling A", scaling), "Scaling A (+10 pp Ratio)", "Scaling B (+25% Relative Log)")
  )

p_figA2_b <- ggplot(resid_ab_df, aes(x = Z, y = std_resid, colour = scaling_short)) +
  geom_hline(yintercept = 0, linetype = "solid", colour = "#334e68", linewidth = 0.6) +
  geom_hline(yintercept = c(-2, 2), linetype = "dashed", colour = "#829ab1", linewidth = 0.55) +
  geom_point(alpha = 0.50, size = 1.4) +
  geom_smooth(method = "loess", formula = y ~ x, span = 0.95, se = FALSE, linewidth = 0.95) +
  coord_cartesian(ylim = c(-3.2, 3.2)) +
  facet_wrap(~ outcome_short, ncol = 3, scales = "free_x") +
  scale_colour_manual(
    name = "Funding Scaling:",
    values = c("Scaling A (+10 pp Ratio)" = "#1b6ca8", "Scaling B (+25% Relative Log)" = "#2b8a3e")
  ) +
  labs(
    title = "B. Standardised Posterior Residuals Across University Funding Z: Scaling A vs Scaling B (+10-Year Horizon, N = 283)",
    x = "Centred University Funding Variable Z (0 = -1.5 Units Below Median, 1.5 = Income-Group Median, 3.0 = +1.5 Units Above)",
    y = "Standardised Residual (SD)"
  ) +
  theme_pub(10.5)

holdout_preds_ab <- read_csv(file.path(out_tab_dir, "table_country_holdout_predictions.csv"), show_col_types = FALSE) %>%
  filter(
    split_type == "Locked 20% Holdout Test Countries (Fold 5, +10y)",
    outcome_code == "inc_tax_share_pp"
  ) %>%
  mutate(
    scaling_short = ifelse(grepl("Scaling A", model), "Scaling A (+10 pp Ratio, CRPS = 3.23)", "Scaling B (+25% Relative Log, CRPS = 3.15)"),
    y_pred_low80 = y_pred - 1.2816 * pred_sd,
    y_pred_high80 = y_pred + 1.2816 * pred_sd
  ) %>%
  group_by(scaling_short, iso3, country_name, income_group) %>%
  summarise(
    y_obs = mean(y_true, na.rm = TRUE),
    y_pred = mean(y_pred, na.rm = TRUE),
    y_low80 = mean(y_pred_low80, na.rm = TRUE),
    y_high80 = mean(y_pred_high80, na.rm = TRUE),
    .groups = "drop"
  )

p_figA2_c <- ggplot(holdout_preds_ab, aes(x = y_pred, y = y_obs, colour = scaling_short)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "#64748b", linewidth = 0.65) +
  geom_errorbar(aes(ymin = y_low80, ymax = y_high80), width = 0, alpha = 0.35, linewidth = 0.55) +
  geom_point(size = 2.4, alpha = 0.85) +
  ggrepel::geom_text_repel(
    aes(label = iso3),
    size = 2.5, fontface = "bold", colour = "#0f2537", max.overlaps = 22, seed = 42, show.legend = FALSE
  ) +
  facet_wrap(~ scaling_short, ncol = 2) +
  scale_colour_manual(
    values = c("Scaling A (+10 pp Ratio, CRPS = 3.23)" = "#1b6ca8", "Scaling B (+25% Relative Log, CRPS = 3.15)" = "#2b8a3e"),
    guide = "none"
  ) +
  labs(
    title = "C. Unseen Holdout Countries (Fold 5): Scaling A vs Scaling B Out-of-Sample Predictions (+10-Year Income Tax Share)",
    x = "Out-of-Sample Predicted 10-Year Change in Direct Income Tax Share (pp)",
    y = "Observed 10-Year Change (pp)"
  ) +
  theme_pub(10.5)

p_figA2 <- (p_figA2_a / p_figA2_b / p_figA2_c) +
  plot_layout(heights = c(1.0, 1.0, 1.05))

save_pub_fig(p_figA2, "figA2_scaling_a_vs_b_comparison", 11.6, 11.4)

# ==============================================================================
# Appendix Figure A1: MCMC Trace Plots across the 4 Fiscal Outcomes (MV-BCF)
# ==============================================================================
cat("Generating Appendix Figure A1: MCMC Posterior Trace Plots (MV-BCF)...\n")

draws_df <- read_csv(file.path(proc_dir, "mvbcf_ate_posterior_draws.csv"), show_col_types = FALSE)

draws_long <- draws_df %>%
  filter(model %in% c("Mediator-Removed Direct Effect (M2, Scaling A)", "Mediator-Removed Direct Effect (M2, Scaling B)")) %>%
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
        "1. Total Non-Resource Tax (% of GDP, pp)",
        "2. Direct Income & Profit Tax (% of GDP, pp)",
        "3. Direct Income & Profit Share of Tax (pp)",
        "4. Goods & Services Tax Share (pp)"
      )
    ),
    series = factor(
      case_when(
        model == "Mediator-Removed Direct Effect (M2, Scaling A)" & horizon == "+5 years"  ~ "Scaling A (+10 pp): +5 Years",
        model == "Mediator-Removed Direct Effect (M2, Scaling A)" & horizon == "+10 years" ~ "Scaling A (+10 pp): +10 Years",
        model == "Mediator-Removed Direct Effect (M2, Scaling B)" & horizon == "+5 years"  ~ "Scaling B (+25% Log): +5 Years",
        model == "Mediator-Removed Direct Effect (M2, Scaling B)" & horizon == "+10 years" ~ "Scaling B (+25% Log): +10 Years"
      ),
      levels = c(
        "Scaling A (+10 pp): +5 Years",
        "Scaling A (+10 pp): +10 Years",
        "Scaling B (+25% Log): +5 Years",
        "Scaling B (+25% Log): +10 Years"
      )
    )
  )

p_figA1 <- ggplot(draws_long, aes(x = draw, y = ate_pp, colour = series)) +
  geom_line(alpha = 0.68, linewidth = 0.40) +
  facet_wrap(~ outcome_label, ncol = 2, scales = "free_y") +
  scale_colour_manual(
    name = "Continuous MV-BCF Specification:",
    values = c(
      "Scaling A (+10 pp): +5 Years" = "#1b6ca8",
      "Scaling A (+10 pp): +10 Years" = "#2b8a3e",
      "Scaling B (+25% Log): +5 Years" = "#e67700",
      "Scaling B (+25% Log): +10 Years" = "#d9480f"
    )
  ) +
  guides(colour = guide_legend(nrow = 2, byrow = TRUE)) +
  labs(
    title = "Post-Burn-In MCMC Trace Plots for Continuous-Treatment Multivariate BCF Models",
    subtitle = "1,250 retained post-burn-in MCMC draws across all four tax revenue outcomes (Scaling A & B at +5y and +10y)",
    x = "Post-Burn-In MCMC Iteration",
    y = "Average Continuous Slope Draw (Percentage Points, pp)"
  ) +
  theme_pub(11)

save_pub_fig(p_figA1, "figA1_mcmc_convergence_traces", 10.6, 6.0)

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

ppc_tbl <- read_csv(file.path(out_tab_dir, "table_scaling_fit_and_residuals.csv"), show_col_types = FALSE)

draws_all_long <- draws_df %>%
  pivot_longer(
    cols = c(tax_gdp_pp, inc_tax_gdp_pp, inc_tax_share_pp, goods_tax_share_pp),
    names_to = "outcome_code",
    values_to = "ate_pp"
  )

tabA1 <- draws_all_long %>%
  group_by(model, horizon, outcome_code) %>%
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
      filter(model_id %in% c("M1a_Total_10pp_5y", "M1b_Total_10pp_10y", "M2a_Direct_10pp_5y", "M2b_Direct_10pp_10y", "M2c_Direct_Log25_5y", "M2d_Direct_Log25_10y")) %>%
      mutate(
        model = case_when(
          model_id %in% c("M1a_Total_10pp_5y", "M1b_Total_10pp_10y") ~ "Total Fiscal Effect (M1, Scaling A)",
          model_id %in% c("M2a_Direct_10pp_5y", "M2b_Direct_10pp_10y") ~ "Mediator-Removed Direct Effect (M2, Scaling A)",
          model_id %in% c("M2c_Direct_Log25_5y", "M2d_Direct_Log25_10y") ~ "Mediator-Removed Direct Effect (M2, Scaling B)"
        ),
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
  left_join(
    ppc_tbl %>%
      mutate(
        model = case_when(
          specification == "Total Fiscal Effect (M1)" & grepl("Scaling A", scaling) ~ "Total Fiscal Effect (M1, Scaling A)",
          specification == "Mediator-Removed Direct Effect (M2)" & grepl("Scaling A", scaling) ~ "Mediator-Removed Direct Effect (M2, Scaling A)",
          specification == "Mediator-Removed Direct Effect (M2)" & grepl("Scaling B", scaling) ~ "Mediator-Removed Direct Effect (M2, Scaling B)",
          TRUE ~ "Other"
        )
      ) %>%
      select(model, horizon, outcome_code, ppc_rmse, ppc_mae, ppc_r2, ppc_crps, ppc_cov80_pct, ppc_cov95_pct, resid_skew, resid_within_2sd_pct),
    by = c("model", "horizon", "outcome_code")
  )

write_csv(tabA1, file.path(out_tab_dir, "tableA1_convergence_and_fit_diagnostics.csv"))
print(tabA1, n = 25)

cat("\n=== Figure 5 Income-Group Trajectories ===\n")
print(traj_joined)

# ==============================================================================
# Appendix Table A3: Random Forest Expected-Treatment Conditioning E[Z | X]
#                    & 19-Covariate Residual Independence Audit
# ==============================================================================
df_clean_full <- read_csv(file.path(proc_dir, "clean_tax_panel.csv"), show_col_types = FALSE) %>%
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
d10 <- df_clean_full[complete.cases(df_clean_full[, c(y10_cols, "Z_cont_10pp", "Z_cont_log25pct")]), ]
X_ps10 <- as.data.frame(lapply(d10[, base_con_vars], function(v) {
  v <- as.numeric(v); med <- median(v, na.rm = TRUE); ifelse(is.na(v), med, v)
}))
Z10_A <- as.numeric(d10$Z_cont_10pp)
Z10_B <- as.numeric(d10$Z_cont_log25pct)

set.seed(202604)
rf_A <- ranger(y = Z10_A, x = X_ps10, num.trees = 500, min.node.size = 10, seed = 202604)
rf_B <- ranger(y = Z10_B, x = X_ps10, num.trees = 500, min.node.size = 10, seed = 202604)
z_hat_A <- rf_A$predictions
z_hat_B <- rf_B$predictions
res_A <- Z10_A - z_hat_A
res_B <- Z10_B - z_hat_B

bal_rows <- list()
for (v in base_con_vars) {
  x <- X_ps10[[v]]
  corr_raw_A <- if (sd(x) > 0) cor(x, Z10_A) else 0.0
  corr_res_A <- if (sd(x) > 0) cor(x, res_A) else 0.0
  corr_raw_B <- if (sd(x) > 0) cor(x, Z10_B) else 0.0
  corr_res_B <- if (sd(x) > 0) cor(x, res_B) else 0.0
  bal_rows[[length(bal_rows) + 1]] <- tibble(
    covariate = v,
    mean_low_dose = round(mean(x[Z10_A < 1.5]), 2),
    mean_high_dose = round(mean(x[Z10_A >= 1.5]), 2),
    corr_raw_scaling_a = round(corr_raw_A, 3),
    corr_resid_scaling_a = round(corr_res_A, 3),
    corr_raw_scaling_b = round(corr_raw_B, 3),
    corr_resid_scaling_b = round(corr_res_B, 3)
  )
}
tabA3 <- bind_rows(bal_rows)
write_csv(tabA3, file.path(out_tab_dir, "tableA3_propensity_overlap_and_balance.csv"))
cat(sprintf(
  "Continuous E[Z|X] Conditioning (+10y N=283): Scaling A mean |r| %.3f -> %.3f (max %.3f); Scaling B mean |r| %.3f -> %.3f (max %.3f)\n",
  mean(abs(tabA3$corr_raw_scaling_a)), mean(abs(tabA3$corr_resid_scaling_a)), max(abs(tabA3$corr_resid_scaling_a)),
  mean(abs(tabA3$corr_raw_scaling_b)), mean(abs(tabA3$corr_resid_scaling_b)), max(abs(tabA3$corr_resid_scaling_b))
))

# ==============================================================================
# Appendix Table A2: Compute and Energy Report (Local C++ MCMC + Cloud LLM Queries)
# ==============================================================================
mvbcf_meta <- readLines(file.path(repo_root, "outputs", "models", "mvbcf_run_metadata.json"))
mvbcf_sec  <- as.numeric(gsub("[^0-9.]", "", mvbcf_meta[grepl("wall_clock_seconds", mvbcf_meta)]))
tot_sec    <- mvbcf_sec
kwh_est    <- (tot_sec / 3600) * 0.025
co2_g_est  <- kwh_est * 250

tabA2 <- tribble(
  ~pipeline_stage, ~models_fitted, ~wall_clock_sec, ~est_energy_wh, ~est_co2e_grams,
  "Step 04: Local C++ Continuous MV-BCF, CV & Benchmarks", "65 four-outcome MV-BCF / CV / BART / LP / TWFE / DML fits (2,000 iter)", round(mvbcf_sec, 1), round(1000 * kwh_est, 2), round(co2_g_est, 2),
  "LLM Stage 1: Scoping, Continuous-Z Redesign & Data Pipeline", "58 queries (102k input / 68k output tokens)", NA_real_, 49.80, 12.45,
  "LLM Stage 2: C++ Continuous Sampler, Scaling & Holdout CV", "39 queries (64k input / 45k output tokens)", NA_real_, 33.40, 8.35,
  "LLM Stage 3: Manuscript & Author Revisions", "305 queries (518k input / 314k output tokens)", NA_real_, 244.60, 61.15,
  "LLM Stage 4: Multi-Agent & External Peer Review", "261 queries (682k input / 361k output tokens)", NA_real_, 256.80, 64.20,
  "LLM Stage 5: Interactive Policy App & Testing", "142 queries (362k input / 219k output tokens)", NA_real_, 148.60, 37.15,
  "Subtotal: Cloud LLM Assistance", "805 queries (1.73M input / 1.01M output tokens)", NA_real_, 733.20, 183.30,
  "Total Project Footprint (Local C++ + Cloud LLM)", "65 MCMC/CV models + 805 LLM queries (2.74M tokens)", round(tot_sec, 1), round(1000 * kwh_est + 733.20, 2), round(co2_g_est + 183.30, 2)
)
write_csv(tabA2, file.path(out_tab_dir, "tableA2_compute_and_energy.csv"))
print(tabA2)

# ==============================================================================
# Appendix Table A4: Latest-Wave (2015-2019) Below-Median Countries (Z_cont_10pp < 1.5),
#                    Proportional Continuous Gap Costs & +10y Continuous Returns
# ==============================================================================
inc_meds <- df_clean_full %>%
  filter(!is.na(tert_spend_per_student_winsor), !is.na(income_group), is_holdout_test == 0) %>%
  group_by(income_group) %>%
  summarise(med_spend_raw = median(tert_spend_per_student_winsor, na.rm = TRUE), .groups = "drop")

cohort_factor <- df_clean_full %>%
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

ctry_base_meta <- df_clean_full %>%
  group_by(iso3) %>%
  summarise(
    tert_spend_gdp_pct_ctry = mean(tert_spend_gdp_pct, na.rm = TRUE),
    gdp_per_capita_latest = dplyr::last(na.omit(gdp_per_capita_ppp_const2021), default = NA_real_),
    population_latest = dplyr::last(na.omit(population_total), default = NA_real_),
    .groups = "drop"
  )

tabA4 <- df_clean_full %>%
  filter(wave_label == "2015-2019", !is.na(Z_cont_10pp), Z_cont_10pp < 1.5) %>%
  left_join(inc_meds, by = "income_group") %>%
  left_join(ctry_cates, by = "iso3") %>%
  left_join(ctry_base_meta, by = "iso3") %>%
  filter(!is.na(tau10_inc_gdp)) %>%
  mutate(
    base_tert_gdp_pct = coalesce(
      tert_spend_gdp_pct,
      ifelse(is.finite(tert_spend_gdp_pct_ctry), tert_spend_gdp_pct_ctry, NA_real_),
      cohort_factor * (tert_spend_raw / 100) * (gross_tert_enrolment_pct / 100) * 100
    ),
    gap_to_median_pp = round(med_spend_raw - tert_spend_raw, 2),
    dose_units_to_median = pmin(gap_to_median_pp / 10.0, 1.5),
    near_boundary_flag = ifelse(gap_to_median_pp < 2.5, 1L, 0L),
    gdp_eur_bn = 0.92 * (gdp_per_capita_latest * population_latest) / 1e9,
    # Cost of closing gap to group median vs standard +10 pp dose
    cost_to_thresh_gdp_pp = round(base_tert_gdp_pct * ((med_spend_raw - tert_spend_raw) / tert_spend_raw), 3),
    cost_to_thresh_eur_bn = round(gdp_eur_bn * (cost_to_thresh_gdp_pp / 100), 3),
    cost_plus10pp_gdp_pp = round(base_tert_gdp_pct * (10.0 / tert_spend_raw), 3),
    cost_plus10pp_eur_bn = round(gdp_eur_bn * (cost_plus10pp_gdp_pp / 100), 3),
    # Proportional continuous return to closing the exact gap to median
    ret10_gap_inc_eur_bn = round(gdp_eur_bn * (dose_units_to_median * tau10_inc_gdp / 100), 2),
    # Standardised continuous return per +10 pp per-student expansion (1.0 dose unit)
    ret10_inc_eur_bn = round(gdp_eur_bn * (tau10_inc_gdp / 100), 2),
    ret10_inc_low95_eur_bn = round(gdp_eur_bn * (tau10_inc_gdp_low95 / 100), 2),
    ret10_inc_high95_eur_bn = round(gdp_eur_bn * (tau10_inc_gdp_high95 / 100), 2),
    income_group = factor(income_group, levels = c("High income", "Upper middle income", "Lower middle income", "Low income"))
  ) %>%
  arrange(income_group, gap_to_median_pp) %>%
  select(
    iso3, country_name, income_group, wave_label,
    tert_spend_raw, med_spend_raw, gap_to_median_pp, dose_units_to_median, near_boundary_flag,
    cost_to_thresh_gdp_pp, cost_to_thresh_eur_bn,
    cost_plus10pp_gdp_pp, cost_plus10pp_eur_bn,
    ret10_gap_inc_eur_bn,
    tau10_inc_gdp, tau10_inc_gdp_low95, tau10_inc_gdp_high95,
    ret10_inc_eur_bn, ret10_inc_low95_eur_bn, ret10_inc_high95_eur_bn,
    tau10_inc_share, tau10_inc_share_low95, tau10_inc_share_high95
  )

write_csv(tabA4, file.path(out_tab_dir, "tableA4_latest_z0_countries_costs_and_returns.csv"))
cat(sprintf("Saved Table A4 (%d latest-wave below-median countries with continuous +10y CATE slopes)\n", nrow(tabA4)))

cat("All figures and diagnostics generated and saved to outputs/ and paper/figures/!\n")
