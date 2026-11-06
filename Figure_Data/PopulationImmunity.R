# R0 = 9 population-immunity re-run summary
#
# Reads the four adult-vaccination-assumption outputs written by
# `make population_immunity` and writes final outbreak-size summaries as CSV
# and Markdown. The selected arms match Figure 4: no interventions and
# self-isolation only use the no-quarantine run, while self-isolation with
# quarantine uses the run with quarantine.
#
# Usage (from the repository root):
#   Rscript Figure_Data/PopulationImmunity.R [output_dir]

library(data.table)

source(file.path("Figure_Data", "FigureABM.R"))

args <- commandArgs(trailingOnly = TRUE)
output_dir <- if (length(args)) args[1] else "population_immunity"
assumptions <- c("baseline", "78pct", "86pct", "93pct")

summary_one <- function(assumption) {
  s <- abm_summaries(output_dir, r0 = 9, vax_adults = assumption)
  sizes <- s$final[, .(
    retained_runs = .N,
    median_infections = median(outbreak_size),
    q25_infections = quantile(outbreak_size, 0.25, names = FALSE),
    q75_infections = quantile(outbreak_size, 0.75, names = FALSE)
  ), by = scenario]

  runs <- s$runs[, .(scenario, total_runs = runs)]
  out <- merge(sizes, runs, by = "scenario", sort = FALSE)
  out[, adult_vaccination := assumption]
  setcolorder(out, c(
    "adult_vaccination", "scenario", "total_runs", "retained_runs",
    "median_infections", "q25_infections", "q75_infections"
  ))
  out
}

out <- rbindlist(lapply(assumptions, summary_one))
out[, adult_vaccination := factor(adult_vaccination, levels = assumptions)]
out[, scenario := factor(scenario, levels = FOCAL_SCENARIOS$label)]
setorder(out, adult_vaccination, scenario)

fwrite(out, file.path(output_dir, "summary.csv"))

table_lines <- c(
  "# R0 = 9 population-immunity scenarios",
  "",
  "Final outbreak sizes after 365 days for 1,000 stochastic runs per scenario.",
  "Runs with fewer than 10 cases are excluded as early extinctions.",
  "The arms match Figure 4: the first two use the no-quarantine run and the",
  "third uses the quarantine run.",
  "",
  "| Adult vaccination assumption | Scenario | Retained runs | Median infections | IQR |",
  "|---|---|---:|---:|---:|"
)

for (i in seq_len(nrow(out))) {
  x <- out[i]
  table_lines <- c(table_lines, sprintf(
    "| %s | %s | %s / %s | %s | %s-%s |",
    as.character(x$adult_vaccination),
    as.character(x$scenario),
    format(x$retained_runs, big.mark = ","),
    format(x$total_runs, big.mark = ","),
    format(round(x$median_infections), big.mark = ","),
    format(round(x$q25_infections), big.mark = ","),
    format(round(x$q75_infections), big.mark = ",")
  ))
}

writeLines(table_lines, file.path(output_dir, "summary.md"))
print(out)
