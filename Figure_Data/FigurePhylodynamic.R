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

# Colors of Figure 4 in the first submission
INCLUSION_COLORS <- setNames(c("#9C7BB2", "#B0895A"), names(EBSP_LOGS))

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

#' Figure 4A: scaled Ne over time (median and 95% interval)
plot_phylo_ne <- function(summaries, xlim = FIGURE4_XLIM) {
  ggplot(
    summaries$ne,
    aes(x = date, y = median, color = inclusion, fill = inclusion)
  ) +
    geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.2, color = NA) +
    geom_line(linewidth = 1.5) +
    scale_color_manual(values = INCLUSION_COLORS, name = NULL) +
    scale_fill_manual(values = INCLUSION_COLORS, name = NULL) +
    scale_x_months() +
    coord_cartesian(xlim = xlim) +
    labs(
      x   = "Date",
      y   = expression(Effective~Population~Size~(N[e])),
      tag = "A"
    ) +
    theme_submission() +
    theme(
      legend.position = c(0.2, 0.85),
      axis.text.x     = element_text(hjust = 1, angle = 30)
    )
}

#' Figure 4B: linked outbreak size (box from the lower to the upper 95%
#' bound, line at the median)
plot_phylo_total <- function(summaries) {
  ggplot(
    summaries$total,
    aes(x = inclusion, fill = inclusion, color = inclusion)
  ) +
    geom_boxplot(
      aes(
        ymin   = lower,
        lower  = lower,
        middle = median,
        upper  = upper,
        ymax   = upper
      ),
      stat  = "identity",
      width = 0.9,
      alpha = 0.6
    ) +
    scale_fill_manual(values = INCLUSION_COLORS, guide = "none") +
    scale_color_manual(values = INCLUSION_COLORS, guide = "none") +
    scale_x_discrete(labels = function(x) sub(" ", " \n", tools::toTitleCase(x))) +
    scale_y_continuous(labels = function(x) format(x, big.mark = ",")) +
    labs(x = "Sample Inclusion", y = "Linked Outbreak Size", tag = "B") +
    theme_submission()
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
