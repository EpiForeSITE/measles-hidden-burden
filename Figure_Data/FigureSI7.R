# Figure SI 7: projected weekly incidence and final outbreak size by R0.
#
# Run from the repository root with:
#   Rscript Figure_Data/FigureSI7.R [scenarios_dir]
#
# The objects `weekly`, `final`, `p_a`, `p_b`, `p_c`, and `p_d` are left in
# the interactive workspace when this file is sourced.

library(data.table)
library(ggplot2)

source(file.path("Figure_Data", "FigureABM.R"))

run_args <- commandArgs(trailingOnly = TRUE)
scenarios_dir <- if (interactive() || !length(run_args)) "scenarios" else run_args[1]
r0_values <- c(5, 7, 9, 11, 13, 15, 17)
r0_colors <- setNames(
  c("#c6dbef", "#9ecae1", "#6baed6", "#4292c6", "#2171b5", "#08519c", "#08306b"),
  r0_values
)
scenario_colors <- c(
  "No interventions" = "#df8068",
  "Self-isolation only" = "#7561a8",
  "Self-isolation with quarantine" = "#3f7d82"
)
date_xlim <- as.Date(c("2025-08-01", "2026-03-01"))

# Read the three intervention scenarios for each R0. `abm_summaries()` removes
# early extinctions (fewer than 10 final cases) before calculating summaries.
# The preprint instead plotted the 75% contact-reduction, no-quarantine arm
# under a quarantine label; this figure uses the intended quarantine arm.
summaries <- lapply(r0_values, function(r0) abm_summaries(scenarios_dir, r0))
weekly <- rbindlist(Map(function(s, r0) copy(s$weekly)[, r0 := r0], summaries, r0_values))
final <- rbindlist(Map(function(s, r0) copy(s$final)[, r0 := r0], summaries, r0_values))
weekly <- weekly[week <= date_xlim[2]]

# Panels A-C: median weekly incidence across retained simulations.
p_a <- ggplot(weekly[scenario == "No interventions"], aes(week, median, color = factor(r0))) +
  geom_line(linewidth = 0.65) +
  scale_color_manual(values = r0_colors, name = expression(R[0])) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b %Y", limits = date_xlim) +
  scale_y_continuous(limits = c(0, 600), expand = expansion(mult = c(0, 0.03))) +
  labs(x = "Date", y = "Incidence", title = "No interventions", tag = "A") +
  theme_figure4(9) +
  theme(
    legend.position = "none", plot.title = element_text(size = 9, hjust = 0.5),
    plot.tag = element_text(face = "bold"),
    axis.text.x = element_text(angle = 35, hjust = 1, size = 7),
    axis.text.y = element_text(size = 7), axis.title = element_text(size = 8)
  )

p_b <- ggplot(weekly[scenario == "Self-isolation only"], aes(week, median, color = factor(r0))) +
  geom_line(linewidth = 0.65) +
  scale_color_manual(values = r0_colors, name = expression(R[0])) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b %Y", limits = date_xlim) +
  scale_y_continuous(limits = c(0, 600), expand = expansion(mult = c(0, 0.03))) +
  labs(x = "Date", y = "Incidence", title = "Self-isolation only", tag = "B") +
  theme_figure4(9) +
  theme(
    legend.position = c(0.8, 0.76),
    legend.background = element_rect(fill = "white", color = NA),
    legend.text = element_text(size = 6), legend.title = element_text(size = 7),
    plot.title = element_text(size = 9, hjust = 0.5),
    plot.tag = element_text(face = "bold"),
    axis.text.x = element_text(angle = 35, hjust = 1, size = 7),
    axis.text.y = element_text(size = 7), axis.title = element_text(size = 8)
  )

p_c <- ggplot(weekly[scenario == "Self-isolation with quarantine"], aes(week, median, color = factor(r0))) +
  geom_line(linewidth = 0.65) +
  scale_color_manual(values = r0_colors, name = expression(R[0])) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b %Y", limits = date_xlim) +
  scale_y_continuous(limits = c(0, 600), expand = expansion(mult = c(0, 0.03))) +
  labs(x = "Date", y = "Incidence", title = "Self-isolation with quarantine", tag = "C") +
  theme_figure4(9) +
  theme(
    legend.position = "none", plot.title = element_text(size = 9, hjust = 0.5),
    plot.tag = element_text(face = "bold"),
    axis.text.x = element_text(angle = 35, hjust = 1, size = 7),
    axis.text.y = element_text(size = 7), axis.title = element_text(size = 8)
  )

# Panel D: all retained final sizes. The vertical range matches the submitted
# figure while retaining every large-outbreak observation in the violins.
p_d <- ggplot(final, aes(factor(r0), outbreak_size, fill = scenario, color = scenario)) +
  geom_violin(
    position = position_dodge(width = 0.8), width = 0.72,
    linewidth = 0.25, alpha = 0.8, trim = FALSE
  ) +
  stat_summary(
    fun = median, geom = "point", shape = 18, size = 2.8,
    position = position_dodge(width = 0.8), show.legend = FALSE
  ) +
  scale_fill_manual(values = scenario_colors, name = NULL) +
  scale_color_manual(values = scenario_colors, guide = "none") +
  scale_y_continuous(labels = function(x) format(x, big.mark = ",")) +
  coord_cartesian(ylim = c(1450, 3100)) +
  labs(x = expression(R[0]), y = "Final outbreak size", tag = "D") +
  theme_figure4(10) +
  theme(
    legend.position = c(0.04, 0.98), legend.justification = c(0, 1),
    legend.text = element_text(size = 7),
    legend.key.height = grid::unit(0.3, "cm"), legend.key.width = grid::unit(0.3, "cm"),
    plot.tag = element_text(face = "bold")
  )

# Assemble and save the four panels. Print with `grid::grid.draw(figure_si7)`
# when working interactively.
figure_si7 <- grid::grid.grabExpr({
  grid::grid.newpage()
  grid::pushViewport(grid::viewport(
    layout = grid::grid.layout(3, 2, widths = grid::unit(c(1, 1.25), "null"))
  ))
  print(p_a, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 1))
  print(p_b, vp = grid::viewport(layout.pos.row = 2, layout.pos.col = 1))
  print(p_c, vp = grid::viewport(layout.pos.row = 3, layout.pos.col = 1))
  print(p_d, vp = grid::viewport(layout.pos.row = 1:3, layout.pos.col = 2))
}, wrap.grobs = TRUE)

fig_w <- 10 *.75
fig_h <- 7.5 * .75

ggsave("Figure_Data/FigureSI7.png", figure_si7, width = fig_w, height = fig_h, dpi = 300)
ggsave("Figure_Data/FigureSI7.pdf", figure_si7, width = fig_w, height = fig_h)
