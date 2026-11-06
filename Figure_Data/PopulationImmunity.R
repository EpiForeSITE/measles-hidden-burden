# R0 = 9 population-immunity re-run: final outbreak sizes of the three
# Figure 4 arms (see FigureABM.R) for each adult vaccination assumption.
#
# Usage (from the repository root):
#   Rscript Figure_Data/PopulationImmunity.R [output_dir]
#
# Writes <output_dir>/summary.csv.

library(data.table)
source(file.path("Figure_Data", "FigureABM.R"))

args <- commandArgs(trailingOnly = TRUE)
dir  <- if (length(args)) args[1] else "population_immunity"

out <- rbindlist(lapply(c("baseline", "78pct", "86pct", "93pct"), function(v) {
  s <- abm_summaries(dir, vax_adults = v)
  s$final[,
    .(
      median = median(outbreak_size),
      q25    = quantile(outbreak_size, 0.25, names = FALSE),
      q75    = quantile(outbreak_size, 0.75, names = FALSE)
    ),
    by = scenario
  ][s$runs, on = "scenario"][, vax_adults := v]
}))

fwrite(out, file.path(dir, "summary.csv"))
print(out)
