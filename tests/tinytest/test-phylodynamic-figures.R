# Figure 4A-B (Figure_Data/FigurePhylodynamic.R) from the committed EBSP logs:
# the linked outbreak sizes at R0 = 9 match the values of the preprint (typed
# by hand in Figure_Data/Figure4.R), and the figure is written.

old_wd <- setwd(file.path("..", ".."))
source(file.path("Figure_Data", "FigurePhylodynamic.R"))
s <- phylo_summaries()
setwd(old_wd)

total <- s$total[order(inclusion)]
expect_equal(as.character(total$inclusion), names(EBSP_LOGS))

# Preprint: 1,798 [1,050-3,573] and 2,051 [1,300-3,885]. The epidemiological
# upper bound computed from the log is 3,537 (digits transposed in Figure4.R).
expect_equal(round(total$median), c(1798, 2052))
expect_equal(round(total$lower), c(1050, 1300))
expect_equal(round(total$upper), c(3537, 3885))

# Scaled Ne: a median inside its interval, back in time from the last sample
expect_true(all(s$ne[, lower <= median & median <= upper]))
expect_true(all(s$ne$date <= MRSD_DATE))

out <- save_panels(
  list(list(plot_phylo_ne(s), plot_phylo_total(s))),
  file.path(tempdir(), "Figure4AB")
)
expect_true(all(file.exists(out)))
unlink(out)
