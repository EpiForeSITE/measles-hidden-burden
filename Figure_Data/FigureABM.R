# Figure 4C-D: agent-based model (ABM) results at R0 = 9
#
# Rebuilds the ABM panels of Figure 4 from the simulation outputs saved by
# template.qmd (scenarios/*.rds), for the three focal scenarios:
#
# - No interventions: no contact reduction after rash onset, no contact tracing
# - Self-isolation only: 50% contact reduction after rash onset
# - Self-isolation with quarantine: 75% contact reduction after rash onset and
#   25% contact-tracing success, from the run *with* quarantine
#
# Each scenario file holds two runs, with quarantine (`outbreak_size`) and
# without (`outbreak_size_no_quarantine`). The quarantine scenario uses the
# former; the other two scenarios use the latter.
#
# Usage (from the repository root):
#
#   Rscript Figure_Data/FigureABM.R [scenarios_dir]
#
# Writes Figure_Data/Figure4CD.{png,pdf}.

library(data.table)
library(ggplot2)

# Simulations start with one infectious case on this date (day 0)
START_DATE <- as.Date("2025-08-06")

# Runs with fewer cases are early extinctions and are excluded (Methods)
MIN_OUTBREAK_SIZE <- 10

FOCAL_SCENARIOS <- data.table(
  label = c(
    "No interventions",
    "Self-isolation only",
    "Self-isolation with quarantine"
  ),
  rash  = c(0.00, 0.50, 0.75),
  ct    = c(0.00, 0.00, 0.25),
  arm   = c(
    "outbreak_size_no_quarantine",
    "outbreak_size_no_quarantine",
    "outbreak_size"
  )
)

# Scenario colors of Figure 4 in the first submission, used in every figure
SCENARIO_COLORS <- setNames(
  c("#E4937B", "#8B7BAD", "#4F868E"),
  FOCAL_SCENARIOS$label
)

INK_PRIMARY   <- "#0b0b0b"
INK_SECONDARY <- "#52514e"
GRID_COLOR    <- "#e4e3df"

# Date range shared by the time panels of Figure 4 (A and C)
FIGURE4_XLIM <- as.Date(c("2025-07-14", "2026-02-28"))

#' Path of the simulation output of one scenario
scenario_file <- function(
    dir,
    r0,
    rash,
    ct,
    vax_adults = "baseline",
    epistorm   = FALSE
) {
  stem <- sprintf(
    "r0_%.2f-epistorm_%s-rash_contact_redux_%.2f-isolation_willingness_0.00-quarantine_willingness_0.90-contact_tracing_success_%.2f",
    r0,
    epistorm,
    rash,
    ct
  )

  f <- file.path(dir, sprintf("%s-vax_adults_%s.rds", stem, vax_adults))
  if (!file.exists(f)) {
    stop("No simulation output for ", basename(f), " in ", dir)
  }

  f
}

#' Final outbreak sizes and weekly cases of the focal scenarios
#'
#' @return A list with `final` (one row per retained run: final outbreak size
#'   at day 365), `weekly_simulations` (weekly cases in each retained run),
#'   `weekly` (median and IQR of weekly cases across retained runs), `peak`
#'   (peak-incidence date for each retained run), and `runs` (number of runs
#'   and retained runs per scenario).
abm_summaries <- function(
    dir        = "scenarios",
    r0         = 9,
    min_size   = MIN_OUTBREAK_SIZE,
    vax_adults = "baseline",
    epistorm   = FALSE
) {
  scenarios <- copy(FOCAL_SCENARIOS)

  sims <- rbindlist(lapply(seq_len(nrow(scenarios)), function(i) {
    s <- scenarios[i]
    f <- scenario_file(
      dir,
      r0,
      s$rash,
      s$ct,
      vax_adults = vax_adults,
      epistorm   = epistorm
    )
    d <- as.data.table(readRDS(f)[[s$arm]])
    d[, scenario := s$label]
    d[, .(scenario, sim_num, date, outbreak_size = as.numeric(outbreak_size))]
  }))

  setorder(sims, scenario, sim_num, date)

  final <- sims[, .SD[date == max(date)], by = .(scenario, sim_num)]
  runs  <- final[,
    .(runs = .N, retained = sum(outbreak_size >= min_size)),
    by = scenario
  ]

  final <- final[outbreak_size >= min_size]
  sims  <- sims[final[, .(scenario, sim_num)], on = .(scenario, sim_num)]

  # New cases per day; day 0 counts the initial case
  sims[,
    new_cases := c(outbreak_size[1], diff(outbreak_size)),
    by = .(scenario, sim_num)
  ]
  sims[, calendar_date := START_DATE + date]

  # Keep the first date when several days share a run's maximum incidence.
  peak <- sims[order(scenario, sim_num, date),
    .SD[which.max(new_cases)], by = .(scenario, sim_num)
  ][, .(scenario, sim_num, peak_date = calendar_date)]

  sims[,
    week := calendar_date - (as.integer(format(calendar_date, "%u")) - 1L)
  ]

  per_week <- sims[,
    .(cases = sum(new_cases)),
    by = .(scenario, sim_num, week)
  ]

  weekly <- per_week[,
    .(
      median = median(cases),
      q25    = quantile(cases, 0.25, names = FALSE),
      q75    = quantile(cases, 0.75, names = FALSE)
    ),
    by = .(scenario, week)
  ]

  final[, calendar_date := START_DATE + date]

  for (x in list(final, per_week, weekly, peak, runs)) {
    x[, scenario := factor(scenario, levels = FOCAL_SCENARIOS$label)]
  }

  list(
    final  = final[, .(scenario, sim_num, calendar_date, outbreak_size)],
    weekly_simulations = per_week,
    weekly = weekly,
    peak   = peak,
    runs   = runs[order(scenario)]
  )
}

theme_figure4 <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      text               = element_text(color = INK_PRIMARY),
      axis.text          = element_text(color = INK_SECONDARY),
      axis.title         = element_text(color = INK_SECONDARY),
      axis.ticks.x       = element_line(color = GRID_COLOR),
      axis.line.x        = element_line(color = INK_SECONDARY, linewidth = 0.3),
      panel.grid.major.y = element_line(color = GRID_COLOR, linewidth = 0.3),
      panel.grid.major.x = element_blank(),
      panel.grid.minor   = element_blank(),
      plot.title         = element_text(face = "bold", size = base_size + 1),
      plot.subtitle      = element_text(color = INK_SECONDARY),
      plot.tag           = element_text(face = "bold", size = base_size + 3),
      legend.position    = "top",
      legend.justification = "left",
      legend.title       = element_blank(),
      legend.text        = element_text(color = INK_PRIMARY),
      plot.margin        = margin(8, 12, 8, 8)
    )
}

#' Style of Figure 4 in the first submission (as cowplot::theme_cowplot(),
#' with larger text)
theme_submission <- function(base_size = 15) {
  theme_classic(base_size = base_size) +
    theme(
      text         = element_text(color = "black"),
      axis.line    = element_line(color = "black"),
      axis.ticks   = element_line(color = "black"),
      axis.text    = element_text(color = "black", size = base_size),
      axis.title.x = element_text(vjust = -1, size = base_size),
      axis.title.y = element_text(vjust = 2, size = base_size),
      legend.text  = element_text(size = base_size),
      legend.background = element_blank(),
      plot.tag     = element_text(face = "bold", size = base_size + 5),
      plot.margin  = margin(10, 10, 14, 10)
    )
}

#' Monthly date axis of the time panels (A and C)
scale_x_months <- function() {
  scale_x_date(date_breaks = "1 month", date_labels = "%b %Y")
}

#' Figure 4C: weekly cases over time (median and IQR across runs)
plot_abm_weekly <- function(summaries, xlim = FIGURE4_XLIM) {
  ggplot(
    summaries$weekly,
    aes(x = week, y = median, color = scenario, fill = scenario)
  ) +
    geom_ribbon(aes(ymin = q25, ymax = q75), alpha = 0.2, color = NA) +
    geom_line(linewidth = 1) +
    scale_color_manual(values = SCENARIO_COLORS) +
    scale_fill_manual(values = SCENARIO_COLORS) +
    scale_x_months() +
    coord_cartesian(xlim = xlim) +
    labs(
      x     = "Date",
      y     = "Weekly Cases",
      color = "Among cases from the community",
      fill  = "Among cases from the community",
      tag   = "C"
    ) +
    theme_submission() +
    theme(
      legend.position = c(0.78, 0.8),
      axis.text.x     = element_text(hjust = 1, angle = 30)
    )
}

#' Figure 4D: final outbreak size (cases by day 365) per run
#'
#' The boxes summarize every retained run; the y-axis zooms on the large
#' outbreaks (more than `large` cases), as in the first submission.
plot_abm_final <- function(summaries, large = 100) {
  final <- summaries$final
  ylim  <- range(final[outbreak_size > large]$outbreak_size)

  ggplot(
    final,
    aes(x = scenario, y = outbreak_size, color = scenario, fill = scenario)
  ) +
    geom_boxplot(alpha = 0.8) +
    scale_fill_manual(values = SCENARIO_COLORS, guide = "none") +
    scale_color_manual(values = SCENARIO_COLORS, guide = "none") +
    scale_x_discrete(
      labels = c(
        "No\nInterventions",
        "Self-Isolation\nOnly",
        "Self-Isolation\nWith Quarantine"
      )
    ) +
    scale_y_continuous(labels = function(x) format(x, big.mark = ",")) +
    coord_cartesian(ylim = ylim) +
    labs(x = NULL, y = "Community Outbreak Size", tag = "D") +
    theme_submission()
}

#' Draws a grid of ggplots (a list of rows) on the current device
draw_panels <- function(rows, widths = c(1.6, 1)) {
  grid::grid.newpage()
  grid::pushViewport(grid::viewport(
    layout = grid::grid.layout(
      length(rows),
      length(widths),
      widths = grid::unit(widths, "null")
    )
  ))
  for (i in seq_along(rows)) {
    for (j in seq_along(rows[[i]])) {
      print(
        rows[[i]][[j]],
        vp = grid::viewport(layout.pos.row = i, layout.pos.col = j)
      )
    }
  }
}

#' Draws a grid of ggplots and saves it as PNG and PDF
save_panels <- function(
    rows,
    file,
    width  = 16,
    height = 5.5 * length(rows),
    widths = c(1.6, 1)
) {
  ragg::agg_png(
    paste0(file, ".png"),
    width      = width,
    height     = height,
    units      = "in",
    res        = 300,
    background = "white"
  )
  draw_panels(rows, widths)
  grDevices::dev.off()

  grDevices::pdf(paste0(file, ".pdf"), width = width, height = height)
  draw_panels(rows, widths)
  grDevices::dev.off()

  invisible(paste0(file, c(".png", ".pdf")))
}

#' Draws panels C and D side by side and saves them as PNG and PDF
save_abm_figure <- function(summaries, file) {
  save_panels(
    list(list(plot_abm_weekly(summaries), plot_abm_final(summaries))),
    file
  )
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  dir  <- if (length(args)) args[1] else "scenarios"

  summaries <- abm_summaries(dir)

  print(summaries$runs)
  print(summaries$final[,
    .(
      median = median(outbreak_size),
      q25    = quantile(outbreak_size, 0.25, names = FALSE),
      q75    = quantile(outbreak_size, 0.75, names = FALSE)
    ),
    by = scenario
  ])

  out <- file.path("Figure_Data", "Figure4CD")
  message("Saved ", paste(save_abm_figure(summaries, out), collapse = ", "))
}
