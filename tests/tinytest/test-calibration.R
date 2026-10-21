# Calibration of the contact matrices to R0 (as in template.qmd) and the
# deterministic final sizes of the multigroup.vaccine Utah/Arizona vignette

library(measles)
library(multigroup.vaccine)

data_dir <- file.path("..", "..", "data")

vax <- readRDS(file.path(data_dir, "utaz_vaccination_adults_baseline.rds"))
grouppops <- vax$agepops

matrices <- list(
  polymod  = readRDS(file.path(data_dir, "utaz_contacts_polymod.rds")),
  epistorm = readRDS(file.path(data_dir, "utaz_contacts_epistorm.rds"))
)

# ==============================================================================
# Calibration
# ==============================================================================

# Settings from template.qmd
h_rate            <- 0.1 * (1 / 4) / (1 - 0.1)
total_duration    <- 4 + 1 / (h_rate + 1 / 4)
transmission_prob <- 0.2

for (src in names(matrices)) {
  cm <- matrices[[src]]

  # R0 values in the Makefile
  for (r0 in c(5, 7, 9, 11, 13, 15, 17)) {
    info <- sprintf("%s, R0 = %s", src, r0)

    scaled <- cm * calibrate_mixing_model(
      contact_matrix         = cm,
      target_rep_number      = r0,
      infectious_period_days = total_duration,
      transmission_prob      = transmission_prob
    )

    # The scaled matrix gives back R0, computed independently of epiworldR
    # as the spectral radius of the next-generation matrix
    ngm <- t(scaled) * transmission_prob * total_duration
    expect_equal(max(Mod(eigen(ngm)$values)), r0, tolerance = 1e-3, info = info)

    # Contacts per day after scaling are still plausible
    mean_contacts <- sum(rowSums(scaled) * grouppops) / sum(grouppops)
    expect_true(mean_contacts > 1 && mean_contacts < 30, info = info)
  }
}

# ==============================================================================
# Final size
# ==============================================================================

# Total infections at R0 = 9 in the vignette ("Alternate adult immunization
# assumptions"). The data here differ slightly: each age group's schools add up
# exactly to the census count.
expected <- c(baseline = 2788, "78pct" = 2396, "86pct" = 2158, "93pct" = 1969)

# 93% efficacy under age 5, 97% otherwise, and those aged 70+ are immune
efficacy <- c(0.93, 0.93, rep(0.97, 12), 1)

for (a in names(expected)) {
  v <- readRDS(
    file.path(data_dir, sprintf("utaz_vaccination_adults_%s.rds", a))
  )

  fs <- finalsize(
    popsize       = v$agepops,
    R0            = 9,
    contactmatrix = matrices$polymod,
    relsusc       = 1,
    reltransm     = 1,
    initR         = rep(0, 15),
    initI         = as.numeric(v$age_labels == "18to24"),
    initV         = round(v$vacc_rate * v$agepops * efficacy)
  )

  expect_equal(sum(fs), expected[[a]], tolerance = 0.005, info = a)
}
