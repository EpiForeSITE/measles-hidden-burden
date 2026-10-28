# Figure 4A-B: phylodynamic estimates of the outbreak
#
# Builds the phylodynamic panels of Figure 4 from the extended Bayesian skyline
# (EBSP) logs, in the style of the ABM panels (Figure_Data/FigureABM.R):
#
# - A: effective population size (Ne) over time, scaled by sigma / generation
#   time at R0 = 9 (median and 95% interval across posterior samples)
# - B: linked outbreak size, the scaled Ne summed once per generation time
#   (BedfordMethodCount.R), for the epidemiological and genomic inclusion sets
#
# Usage (from the repository root):
#
#   Rscript Figure_Data/FigurePhylodynamic.R
#
# Writes Figure_Data/Figure4AB.{png,pdf} and the full Figure 4,
# Figure_Data/Figure4.{png,pdf} (ABM panels from scenarios/).

source(file.path("Figure_Data", "FigureABM.R"))
source("plotEBSP.R")

# Most recent sample date (time 0 in the EBSP logs)
MRSD_DATE <- as.Date("2026-02-28")

# Average time from rash onset to a secondary case (years)
GENERATION_TIME <- 11.9 / 365

EBSP_LOGS <- c(
  "Epidemiological inclusion" = file.path("Figure_Data", "EBSP_epi.log"),
  "Genomic inclusion"         = file.path("Figure_Data", "EBSP_genomepi.log")
)

# Violet and yellow from the reference categorical palette (dataviz skill):
# the most separable pair (validated for all pairs, including under
# color-vision deficiencies) outside the three slots of the ABM scenarios
INCLUSION_COLORS <- setNames(c("#6250d6", "#eda100"), names(EBSP_LOGS))

#' Scaled Ne over time and linked outbreak size from one EBSP log
#'
#' @return A list with `ne` (median and 95% interval of the scaled Ne at each
#'   time point) and `total` (outbreak size: the median and interval bounds
#'   summed once per generation time, as in BedfordMethodCount.R).
ebsp_summaries <- function(
    log,
    r0          = 9,
    burnin      = 0.1,
    window      = 0.015,
    gen_time    = GENERATION_TIME
) {
  res <- processEBSPdata(
    removeBurnin(read.table(log, header = TRUE, sep = "\t", as.is = TRUE), burnin),
    TRUE
  )

  factor <- ((1 / r0) + (1 / 0.34) + 1) / gen_time

  ne <- data.table(
    years_before = res$allTimes,
    date         = MRSD_DATE - res$allTimes * 365.25,
    median       = res$Nmedian * factor,
    lower        = res$NlowerCPD * factor,
    upper        = res$NupperCPD * factor
  )

  # Largest value within +/- `window` years of each generation, summed
  targets <- seq(min(ne$years_before), max(ne$years_before), by = gen_time)
  per_generation <- function(x) {
    vapply(
      targets,
      function(t) {
        w <- x[ne$years_before >= t - window & ne$years_before <= t + window]
        if (length(w)) max(w) else 0
      },
      numeric(1)
    )
  }

  total <- data.table(
    median = sum(per_generation(ne$median)),
    lower  = sum(per_generation(ne$lower)),
    upper  = sum(per_generation(ne$upper))
  )

  list(ne = ne, total = total)
}

#' Summaries of all the EBSP logs, one row per inclusion set
phylo_summaries <- function(logs = EBSP_LOGS, r0 = 9) {
  s <- lapply(logs, ebsp_summaries, r0 = r0)

  bind <- function(what) {
    x <- rbindlist(lapply(s, `[[`, what), idcol = "inclusion")
    x[, inclusion := factor(inclusion, levels = names(logs))]
    x
  }

  list(ne = bind("ne"), total = bind("total"))
}

#' Figure 4A: scaled Ne over time
plot_phylo_ne <- function(summaries, xlim = FIGURE4_XLIM) {
  ne <- summaries$ne[date >= xlim[1] & date <= xlim[2]]

  peaks <- ne[, .SD[which.max(median)], by = inclusion]
  peaks[, label := sprintf(
    "%s, %s",
    format(round(median), big.mark = ","),
    format(date, "%b %d")
  )]

  ggplot(ne, aes(x = date, color = inclusion, fill = inclusion)) +
    geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.12, color = NA) +
    geom_line(aes(y = lower), linewidth = 0.25, alpha = 0.6) +
    geom_line(aes(y = upper), linewidth = 0.25, alpha = 0.6) +
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
      nudge_y       = 4,
      size          = 3,
      show.legend   = FALSE
    ) +
    scale_color_manual(values = INCLUSION_COLORS) +
    scale_fill_manual(values = INCLUSION_COLORS) +
    scale_x_date(
      date_breaks = "1 month",
      date_labels = "%b\n%Y",
      expand      = expansion(mult = c(0.01, 0.02))
    ) +
    scale_y_continuous(
      labels = function(x) format(x, big.mark = ","),
      expand = expansion(mult = c(0, 0.05))
    ) +
    expand_limits(y = 0) +
    coord_cartesian(xlim = xlim, clip = "off") +
    labs(
      x        = NULL,
      y        = expression("Scaled effective population size, " * N[e]),
      title    = "Effective population size",
      subtitle = "Median (line) and 95% interval (band) across posterior samples",
      tag      = "A"
    ) +
    guides(color = guide_legend(nrow = 1), fill = "none") +
    theme_figure4()
}

#' Figure 4B: linked outbreak size (median and 95% bounds)
plot_phylo_total <- function(summaries) {
  total <- summaries$total
  total[, label := sprintf(
    "%s\n(%s-%s)",
    format(round(median), big.mark = ","),
    format(round(lower), big.mark = ","),
    format(round(upper), big.mark = ",")
  )]

  ggplot(total, aes(x = inclusion, y = median, color = inclusion)) +
    geom_linerange(aes(ymin = lower, ymax = upper), linewidth = 2.4, alpha = 0.35) +
    geom_point(size = 3.4, shape = 21, stroke = 1, fill = "white") +
    geom_text(
      aes(label = label),
      color      = INK_PRIMARY,
      nudge_x    = 0.12,
      hjust      = 0,
      size       = 3.2,
      lineheight = 0.95
    ) +
    scale_color_manual(values = INCLUSION_COLORS, guide = "none") +
    scale_x_discrete(
      labels = function(x) sub(" ", "\n", x),
      expand = expansion(add = c(0.5, 0.9))
    ) +
    scale_y_continuous(
      labels = function(x) format(x, big.mark = ","),
      limits = c(0, NA),
      expand = expansion(mult = c(0, 0.05))
    ) +
    labs(
      x        = NULL,
      y        = "Infections",
      title    = "Linked outbreak size",
      subtitle = "Median (dot) and 95% bounds (bar), R0 = 9",
      tag      = "B"
    ) +
    theme_figure4() +
    theme(axis.text.x = element_text(color = INK_PRIMARY, lineheight = 0.95))
}

#' Draws a grid of ggplots (a list of rows) and saves it as PNG and PDF
save_panels <- function(
    rows,
    file,
    width  = 12,
    height = 4.8 * length(rows),
    widths = c(1.55, 1)
) {
  draw <- function() {
    grid::grid.newpage()
    grid::pushViewport(grid::viewport(
      layout = grid::grid.layout(
        length(rows),
        2,
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

  ragg::agg_png(
    paste0(file, ".png"),
    width      = width,
    height     = height,
    units      = "in",
    res        = 300,
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
  phylo <- phylo_summaries()
  print(phylo$total)

  ab <- list(plot_phylo_ne(phylo), plot_phylo_total(phylo))
  out <- save_panels(list(ab), file.path("Figure_Data", "Figure4AB"))

  abm <- abm_summaries("scenarios")
  cd  <- list(plot_abm_weekly(abm), plot_abm_final(abm))
  out <- c(out, save_panels(list(ab, cd), file.path("Figure_Data", "Figure4")))

  message("Saved ", paste(out, collapse = ", "))
}
