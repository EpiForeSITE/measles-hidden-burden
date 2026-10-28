# Figure 4C-D (Figure_Data/FigureABM.R) from the committed R0 = 9 simulation
# outputs in scenarios/: the summaries have the shape of the published figure
# data (Figure_Data/main_*.RData), and the scenario with quarantine is drawn
# from the run with quarantine.

source(file.path("..", "..", "Figure_Data", "FigureABM.R"))

scenarios_dir <- file.path("..", "..", "scenarios")

s     <- abm_summaries(scenarios_dir)
paper <- abm_summaries(scenarios_dir, paper_arms = TRUE)

# Runs and exclusions
expect_equal(as.character(s$runs$scenario), FOCAL_SCENARIOS$label)
expect_true(all(s$runs$runs == 1000))
expect_equal(
  s$runs$retained,
  as.vector(table(s$final$scenario)),
  info = "one final size per retained run"
)
expect_true(all(s$final$outbreak_size >= MIN_OUTBREAK_SIZE))
expect_true(all(s$final$calendar_date == START_DATE + 365))

# Weekly cases: Monday-start weeks covering the 365 days, as in main_weekly
weeks <- sort(unique(s$weekly$week))
expect_equal(min(weeks), as.Date("2025-08-04"))
expect_equal(length(weeks), 53L)
expect_true(all(format(weeks, "%u") == "1"))
expect_true(all(s$weekly[, q25 <= median & median <= q75]))

# Interventions reduce the outbreak; quarantine adds to self-isolation
med <- s$final[, .(median = median(outbreak_size)), by = scenario]$median
expect_true(all(diff(med) < 0))

# The published arms differ only for the scenario with quarantine
expect_equal(s$runs[1:2], paper$runs[1:2])
expect_true(
  median(s$final[scenario == FOCAL_SCENARIOS$label[3]]$outbreak_size) <
    median(paper$final[scenario == FOCAL_SCENARIOS$label[3]]$outbreak_size)
)

# The figure is written
out <- save_abm_figure(s, file.path(tempdir(), "Figure4CD"))
expect_true(all(file.exists(out)))
unlink(out)
