# Calibration of the contact matrices to a target R0, as in template.qmd

library(measles)

data_dir <- file.path("..", "..", "data")

vax <- readRDS(file.path(data_dir, "utaz_vaccination_adults_baseline.rds"))
grouppops <- vax$agepops

matrices <- list(
  polymod  = readRDS(file.path(data_dir, "utaz_contacts_polymod.rds")),
  epistorm = readRDS(file.path(data_dir, "utaz_contacts_epistorm.rds"))
)

# Settings from template.qmd: 10% hospitalization probability over a 4-day
# rash period, and a transmission probability of 0.2
rash_period       <- 4
h_rate            <- 0.1 * (1 / rash_period) / (1 - 0.1)
total_duration    <- 4 + 1 / (h_rate + 1 / rash_period)
transmission_prob <- 0.2

# Vaccine efficacy by group, as in template.qmd: 93% under age 5 and 100% for
# those aged 70+
efficacy <- rep(0.97, nrow(vax))
efficacy[1:2] <- 0.93
efficacy[nrow(vax)] <- 1

# Spectral radius of the next-generation matrix, computed independently of
# epiworldR. `susceptible` is the share of each group that can be infected.
rep_number <- function(cm, susceptible = 1) {
  ngm <- susceptible * t(cm) * transmission_prob * total_duration
  max(Mod(eigen(ngm, only.values = TRUE)$values))
}

mean_contacts <- function(cm) sum(rowSums(cm) * grouppops) / sum(grouppops)

# R0 values in the Makefile
r0_values <- c(5, 7, 9, 11, 13, 15, 17)

for (src in names(matrices)) {

  cm <- matrices[[src]]

  scaling <- sapply(r0_values, function(r0) {
    calibrate_mixing_model(
      contact_matrix         = cm,
      target_rep_number      = r0,
      infectious_period_days = total_duration,
      transmission_prob      = transmission_prob
    )
  })

  expect_true(all(is.finite(scaling) & scaling > 0), info = src)

  # Not at the edge of the search interval of calibrate_mixing_model()
  expect_true(all(scaling < 999), info = src)

  # A higher R0 needs more contacts
  expect_true(all(diff(scaling) > 0), info = src)

  for (k in seq_along(r0_values)) {

    r0     <- r0_values[k]
    scaled <- cm * scaling[k]
    info   <- sprintf("%s, R0 = %s", src, r0)

    # The scaled matrix gives back the target R0
    expect_equal(rep_number(scaled), r0, tolerance = 1e-3, info = info)

    # Contacts per day after scaling are still plausible
    expect_true(
      mean_contacts(scaled) > 1 && mean_contacts(scaled) < 30,
      info = info
    )

    # Vaccination lowers the reproduction number, but not below 1: the
    # community is far from herd immunity
    r_vax <- rep_number(scaled, 1 - vax$vacc_rate * efficacy)
    expect_true(r_vax > 1 && r_vax < r0, info = info)

  }

}
