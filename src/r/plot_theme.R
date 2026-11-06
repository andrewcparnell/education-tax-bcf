# ==============================================================================
# Shared Publication Plotting Theme (src/r/plot_theme.R)
#
# Provides colour-blind-safe palettes (Okabe-Ito) and consistent typography
# (minimum effective font size >= 8pt at print scale) across all EDA and
# manuscript figures.
# ==============================================================================

suppressPackageStartupMessages({
  library(ggplot2)
})

# Colour-blind-safe Okabe-Ito palette
okabe_ito <- c(
  navy   = "#003366",
  teal   = "#009E73",
  orange = "#E69F00",
  sky    = "#56B4E9",
  red    = "#D55E00",
  purple = "#CC79A7",
  yellow = "#F0E442",
  grey   = "#666666"
)

theme_pub <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title       = element_text(face = "bold", size = base_size + 1.5, colour = "#111111", margin = margin(b = 4)),
      plot.subtitle    = element_text(size = base_size - 0.5, colour = "#333333", margin = margin(b = 8)),
      plot.caption     = element_text(size = base_size - 2.0, colour = "#555555", hjust = 0, margin = margin(t = 6)),
      axis.title       = element_text(face = "bold", size = base_size, colour = "#111111"),
      axis.text        = element_text(size = base_size - 1.0, colour = "#222222"),
      strip.text       = element_text(face = "bold", size = base_size - 0.5, colour = "#111111"),
      strip.background = element_rect(fill = "#F0F4F8", colour = NA),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = "#E5E9F0", linewidth = 0.35),
      panel.border     = element_rect(colour = "#CCCCCC", fill = NA, linewidth = 0.4),
      legend.position  = "bottom",
      legend.title     = element_text(face = "bold", size = base_size - 0.5),
      legend.text      = element_text(size = base_size - 1.0),
      plot.margin      = margin(8, 10, 8, 8)
    )
}
