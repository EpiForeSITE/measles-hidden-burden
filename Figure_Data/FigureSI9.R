# Figure SI 9: projected incidence and final outbreak size under two mixing
# assumptions. Run from the repository root with:
#   Rscript Figure_Data/FigureSI9.R
#
# Source this file interactively to inspect `weekly`, `final`, `p_a`, and
# `p_b`. The figure uses the intended run with quarantine for the third arm.

library(data.table)
library(ggplot2)

source(file.path("Figure_Data", "FigureABM.R"))

scenario_colors <- c(
  "No interventions" = "#df8068",
  "Self-isolation only" = "#7561a8",
  "Self-isolation with quarantine" = "#3f7d82"
)
date_xlim <- as.Date(c("2025-08-01", "2026-03-01"))

# Both model sets use R0 = 9 and retain runs with at least 10 final cases.
polymod <- abm_summaries("scenarios", 9)
epistorm <- abm_summaries("sensitivity_epistorm", 9, epistorm = TRUE)

weekly <- rbind(
  copy(polymod$weekly)[, matrix := "POLYMOD"],
  copy(epistorm$weekly)[, matrix := "Epistorm-Mix"]
)[week <= date_xlim[2]]
final <- rbind(
  copy(polymod$final)[, matrix := "POLYMOD"],
  copy(epistorm$final)[, matrix := "Epistorm-Mix"]
)
weekly[, matrix := factor(matrix, levels = c("Epistorm-Mix", "POLYMOD"))]
final[, matrix := factor(matrix, levels = c("Epistorm-Mix", "POLYMOD"))]

# Panel A: median weekly incidence and IQR. The line type distinguishes the
# mixing matrix, while color identifies the intervention scenario.
p_a <- ggplot(weekly, aes(week, median, color = scenario, linetype = matrix)) +
  geom_ribbon(
    aes(ymin = q25, ymax = q75, fill = scenario),
    alpha = 0.13, color = NA, show.legend = FALSE
  ) +
  geom_line(linewidth = 0.8) +
  scale_color_manual(values = scenario_colors, name = NULL) +
  scale_fill_manual(values = scenario_colors, guide = "none") +
  scale_linetype_manual(
    values = c("Epistorm-Mix" = "solid", "POLYMOD" = "dashed"),
    name = NULL
  ) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b %Y", limits = date_xlim) +
  scale_y_continuous(limits = c(0, 540), expand = expansion(mult = c(0, 0.03))) +
  labs(x = "Date", y = "Weekly cases", tag = "A") +
  theme_figure4(10) +
  theme(
    legend.position = c(0.72, 0.97),
    legend.justification = c(0, 1),
    legend.background = element_rect(fill = "white", color = NA),
    legend.text = element_text(size = 8),
    legend.key.width = grid::unit(0.5, "cm"),
    plot.tag = element_text(face = "bold"),
    axis.text.x = element_text(angle = 35, hjust = 1)
  )

# Panel B shows final-size distributions for the alternative Epistorm-Mix
# contact matrix. Each box is one intervention scenario across retained runs;
# the displayed range focuses on the large outbreaks, as in the supplement.
p_b <- ggplot(
  final[matrix == "Epistorm-Mix"],
  aes(scenario, outbreak_size, fill = scenario, color = scenario)
) +
  geom_boxplot(width = 0.6, outlier.size = 1.8, alpha = 0.65) +
  scale_fill_manual(values = scenario_colors, guide = "none") +
  scale_color_manual(values = scenario_colors, guide = "none") +
  scale_y_continuous(labels = function(x) format(x, big.mark = ",")) +
  coord_cartesian(ylim = c(2000, 3000)) +
  labs(x = NULL, y = "Community outbreak size", tag = "B") +
  theme_figure4(10) +
  theme(
    plot.tag = element_text(face = "bold"),
    axis.text.x = element_text(angle = 28, hjust = 1, color = INK_PRIMARY)
  )

# Assemble and save the two panels. Print with `grid::grid.draw(figure_si9)`
# when working interactively.
figure_si9 <- grid::grid.grabExpr({
  grid::grid.newpage()
  grid::pushViewport(grid::viewport(
    layout = grid::grid.layout(1, 2, widths = grid::unit(c(1.55, 0.85), "null"))
  ))
  print(p_a, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 1))
  print(p_b, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 2))
}, wrap.grobs = TRUE)

ggsave("Figure_Data/FigureSI9.png", figure_si9, width = 10, height = 5.8, dpi = 300)
ggsave("Figure_Data/FigureSI9.pdf", figure_si9, width = 10, height = 5.8)
