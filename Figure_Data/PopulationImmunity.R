# R0 = 9 population-immunity re-run: final outbreak sizes of the three
# Figure 4 arms (see FigureABM.R) for each adult vaccination assumption, in
# total and for children (under 18) and adults, over the retained runs.
#
# Usage (from the repository root):
#   Rscript Figure_Data/PopulationImmunity.R [output_dir]
#
# Writes <output_dir>/summary.csv.

library(data.table)
source(file.path("Figure_Data", "FigureABM.R"))

args <- commandArgs(trailingOnly = TRUE)
dir  <- if (length(args)) args[1] else "population_immunity"

ADULTS <- c("18to24", "25to44", "45to69", "70+")

#' Median child and adult infections of each arm over the retained runs
by_age <- function(v) {
  rbindlist(lapply(seq_len(nrow(FOCAL_SCENARIOS)), function(i) {
    s <- FOCAL_SCENARIOS[i]
    f <- scenario_file(dir, 9, s$rash, s$ct, vax_adults = v)
    x <- as.data.table(
      readRDS(f)[[sub("outbreak_size", "infections_by_age", s$arm)]]
    )
    x <- x[,
      .(
        child = sum(infections[!age_group %in% ADULTS]),
        adult = sum(infections[age_group %in% ADULTS])
      ),
      by = sim_num
    ][child + adult >= MIN_OUTBREAK_SIZE]
    x[, .(scenario = s$label, child = median(child), adult = median(adult))]
  }))
}

out <- rbindlist(lapply(c("baseline", "78pct", "86pct", "93pct"), function(v) {
  s <- abm_summaries(dir, vax_adults = v)
  s$final[,
    .(
      median = median(outbreak_size),
      q25    = quantile(outbreak_size, 0.25, names = FALSE),
      q75    = quantile(outbreak_size, 0.75, names = FALSE)
    ),
    by = scenario
  ][s$runs, on = "scenario"][by_age(v), on = "scenario"][, vax_adults := v]
}))

out[, child_adult_ratio := round(child / adult, 1)]

fwrite(out, file.path(dir, "summary.csv"))
print(out)
