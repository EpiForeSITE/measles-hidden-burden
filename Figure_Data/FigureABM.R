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
# without (`outbreak_size_no_quarantine`). The published Figure 4C-D drew all
# three scenarios from the run without quarantine; `--paper-arms` reproduces
# that choice.
#
# Usage (from the repository root):
#
#   Rscript Figure_Data/FigureABM.R [scenarios_dir] [--paper-arms]
#
# Writes Figure_Data/Figure4CD.{png,pdf} (Figure4CD_paper_arms.* with
# --paper-arms).

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

# First three slots of the reference categorical palette (dataviz skill),
# validated for all pairs, including under color-vision deficiencies
SCENARIO_COLORS <- setNames(
  c("#2a78d6", "#eb6834", "#1baf7a"),
  FOCAL_SCENARIOS$label
)

INK_PRIMARY   <- "#0b0b0b"
INK_SECONDARY <- "#52514e"
GRID_COLOR    <- "#e4e3df"

# Date range shared by the time panels of Figure 4 (A and C)
FIGURE4_XLIM <- as.Date(c("2025-07-01", "2026-03-01"))

#' Path of the simulation output of one scenario
#'
#' Matches files with and without the `-vax_adults_<assumption>` suffix (runs
#' made before the adult vaccination assumptions were added are `baseline`).
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

  candidates <- file.path(
    dir,
    paste0(stem, c(sprintf("-vax_adults_%s.rds", vax_adults), ".rds"))
  )

  if (vax_adults != "baseline") candidates <- candidates[1]

  found <- candidates[file.exists(candidates)]
  if (!length(found)) {
    stop("No simulation output for ", stem, " in ", dir)
  }

  found[1]
}

#' Final outbreak sizes and weekly cases of the focal scenarios
#'
#' @return A list with `final` (one row per retained run: final outbreak size
#'   at day 365) and `weekly` (median and IQR of the new cases per calendar
#'   week, Monday to Sunday, across the retained runs), plus `runs` (number of
#'   runs and retained runs per scenario).
abm_summaries <- function(
    dir        = "scenarios",
    r0         = 9,
    paper_arms = FALSE,
    min_size   = MIN_OUTBREAK_SIZE,
    vax_adults = "baseline"
) {
  scenarios <- copy(FOCAL_SCENARIOS)
  if (paper_arms) scenarios[, arm := "outbreak_size_no_quarantine"]

  sims <- rbindlist(lapply(seq_len(nrow(scenarios)), function(i) {
    s <- scenarios[i]
    f <- scenario_file(dir, r0, s$rash, s$ct, vax_adults = vax_adults)
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

  for (x in list(final, weekly, runs)) {
    x[, scenario := factor(scenario, levels = FOCAL_SCENARIOS$label)]
  }

  list(
    final  = final[, .(scenario, sim_num, calendar_date, outbreak_size)],
    weekly = weekly,
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

#' Figure 4C: weekly cases over time (median and IQR across runs)
plot_abm_weekly <- function(summaries, xlim = FIGURE4_XLIM) {
  weekly <- summaries$weekly[week <= xlim[2]]

  peaks <- weekly[, .SD[which.max(median)], by = scenario]
  peaks[, label := sprintf(
    "%s cases, week of %s",
    format(round(median), big.mark = ","),
    format(week, "%b %d")
  )]

  ggplot(weekly, aes(x = week, color = scenario, fill = scenario)) +
    geom_ribbon(aes(ymin = q25, ymax = q75), alpha = 0.12, color = NA) +
    geom_line(aes(y = q25), linewidth = 0.25, alpha = 0.6) +
    geom_line(aes(y = q75), linewidth = 0.25, alpha = 0.6) +
    geom_line(aes(y = median), linewidth = 0.8) +
    geom_point(
      data   = peaks,
      aes(y = median),
      size   = 2.2,
      shape  = 21,
      stroke = 0.8,
      fill   = "white"
    ) +
    geom_label(
      data          = peaks,
      aes(y = median, label = label),
      color         = INK_PRIMARY,
      fill          = "white",
      alpha         = 0.85,
      linewidth     = 0,
      label.padding = grid::unit(0.12, "lines"),
      hjust         = 0,
      nudge_x       = 5,
      vjust         = 0,
      nudge_y       = 6,
      size          = 3,
      show.legend   = FALSE
    ) +
    scale_color_manual(values = SCENARIO_COLORS, drop = FALSE) +
    scale_fill_manual(values = SCENARIO_COLORS, drop = FALSE) +
    scale_x_date(
      date_breaks = "1 month",
      date_labels = "%b\n%Y",
      expand      = expansion(mult = c(0.01, 0.02))
    ) +
    scale_y_continuous(
      labels = function(x) format(x, big.mark = ","),
      expand = expansion(mult = c(0, 0.08))
    ) +
    coord_cartesian(xlim = xlim, clip = "off") +
    labs(
      x        = NULL,
      y        = "New cases per week",
      title    = "Weekly cases",
      subtitle = "Median (line) and interquartile range (band) across runs",
      tag      = "C"
    ) +
    guides(color = guide_legend(nrow = 1), fill = "none") +
    theme_figure4()
}

#' Figure 4D: final outbreak size (cases by day 365) per run
#'
#' The y-axis zooms on the large outbreaks (> `large` cases); the number of
#' retained runs below that is reported in the subtitle, and every run counts
#' in the boxes and medians.
plot_abm_final <- function(summaries, large = 100) {
  final <- summaries$final
  runs  <- summaries$runs

  medians <- final[, .(median = median(outbreak_size)), by = scenario]

  n_small  <- final[outbreak_size <= large, .N]
  ylim     <- range(final[outbreak_size > large]$outbreak_size)
  ylim     <- ylim + c(-1, 1) * 0.04 * diff(ylim)
  subtitle <- "Each dot is a run; box shows median and IQR"
  if (n_small > 0) {
    subtitle <- sprintf(
      "%s\n%d run%s with %d-%d cases not shown",
      subtitle,
      n_small,
      if (n_small > 1) "s" else "",
      MIN_OUTBREAK_SIZE,
      large
    )
  }

  axis_labels <- setNames(
    sprintf(
      "%s\n%s of %s runs",
      sub(" with ", "\nwith ", runs$scenario),
      format(runs$retained, big.mark = ","),
      format(runs$runs, big.mark = ",")
    ),
    runs$scenario
  )

  set.seed(1231)
  ggplot(final, aes(x = scenario, y = outbreak_size, color = scenario)) +
    geom_jitter(width = 0.2, height = 0, size = 0.7, alpha = 0.3) +
    geom_boxplot(
      width         = 0.5,
      fill          = NA,
      color         = INK_PRIMARY,
      linewidth     = 0.4,
      outlier.shape = NA
    ) +
    geom_text(
      data    = medians,
      aes(y = median, label = format(round(median), big.mark = ",")),
      color   = INK_PRIMARY,
      nudge_x = 0.3,
      hjust   = 0,
      size    = 3.2
    ) +
    scale_color_manual(values = SCENARIO_COLORS, guide = "none") +
    scale_x_discrete(
      labels = axis_labels,
      expand = expansion(add = c(0.5, 0.75))
    ) +
    scale_y_continuous(labels = function(x) format(x, big.mark = ",")) +
    coord_cartesian(ylim = ylim) +
    labs(
      x        = NULL,
      y        = "Infections by day 365",
      title    = "Community outbreak size",
      subtitle = subtitle,
      tag      = "D"
    ) +
    theme_figure4() +
    theme(axis.text.x = element_text(color = INK_PRIMARY, lineheight = 0.95))
}

#' Draws panels C and D side by side and saves them as PNG and PDF
save_abm_figure <- function(
    summaries,
    file,
    width  = 12,
    height = 4.8
) {
  draw <- function() {
    grid::grid.newpage()
    grid::pushViewport(grid::viewport(
      layout = grid::grid.layout(1, 2, widths = grid::unit(c(1.55, 1), "null"))
    ))
    print(
      plot_abm_weekly(summaries),
      vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 1)
    )
    print(
      plot_abm_final(summaries),
      vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 2)
    )
  }

  ragg::agg_png(
    paste0(file, ".png"),
    width  = width,
    height = height,
    units  = "in",
    res    = 300,
    background = "white"
  )
  draw()
  grDevices::dev.off()

  grDevices::pdf(paste0(file, ".pdf"), width = width, height = height)
  draw()
  grDevices::dev.off()

  invisible(paste0(file, c(".png", ".pdf")))
}

if (sys.nframe() == 0L) {
  args       <- commandArgs(trailingOnly = TRUE)
  paper_arms <- "--paper-arms" %in% args
  dir        <- setdiff(args, "--paper-arms")
  dir        <- if (length(dir)) dir[1] else "scenarios"

  summaries <- abm_summaries(dir, paper_arms = paper_arms)

  print(summaries$runs)
  print(summaries$final[,
    .(
      median = median(outbreak_size),
      q25    = quantile(outbreak_size, 0.25, names = FALSE),
      q75    = quantile(outbreak_size, 0.75, names = FALSE)
    ),
    by = scenario
  ])

  out <- file.path(
    "Figure_Data",
    if (paper_arms) "Figure4CD_paper_arms" else "Figure4CD"
  )
  message("Saved ", paste(save_abm_figure(summaries, out), collapse = ", "))
}
