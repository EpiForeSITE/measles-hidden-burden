# Vaccination coverage in data/utaz_vaccination_adults_<assumption>.rds
# (built by data/utaz_data.R)

data_dir <- file.path("..", "..", "data")

read_vax <- function(assumption) {
  readRDS(
    file.path(data_dir, sprintf("utaz_vaccination_adults_%s.rds", assumption))
  )
}

assumptions <- c("baseline", "78pct", "86pct", "93pct")
vax <- lapply(assumptions, read_vax)
names(vax) <- assumptions

cm <- readRDS(file.path(data_dir, "utaz_contacts_polymod.rds"))

for (a in assumptions) {

  v <- vax[[a]]

  expect_equal(
    names(v),
    c("age_labels", "agepops", "agelims", "vacc_rate"),
    info = a
  )
  expect_equal(nrow(v), 15, info = a)
  expect_equal(v$age_labels, rownames(cm), info = a)

  # Upper age limit of each group
  expect_equal(
    v$agelims,
    c(1, 4, 11, 11, 11, 13, 13, 13, 17, 17, 17, 24, 44, 69, 90),
    info = a
  )

  # Shares, not counts or percentages
  expect_true(all(is.finite(v$vacc_rate)), info = a)
  expect_true(all(v$vacc_rate >= 0 & v$vacc_rate <= 1), info = a)

  # Under 1s are unvaccinated and those aged 70+ are immune
  expect_equal(v$vacc_rate[v$age_labels == "under1"], 0, info = a)
  expect_equal(v$vacc_rate[v$age_labels == "70+"], 1, info = a)

  # Overall coverage of the community: low, but not implausibly so
  overall <- sum(v$vacc_rate * v$agepops) / sum(v$agepops)
  expect_true(overall > 0.3 && overall < 0.9, info = a)

}

# Baseline: ages 1-4 have the elementary school coverage, 18-24 the high school
# coverage, 25-44 the mean of that and 95%, and 45-69 95%
b <- vax$baseline
pooled <- function(rows) sum(b$vacc_rate[rows] * b$agepops[rows]) /
  sum(b$agepops[rows])

expect_equal(b$vacc_rate[2], pooled(grep("^5to11s", b$age_labels)))
expect_equal(b$vacc_rate[12], pooled(grep("^14to17s", b$age_labels)))
expect_equal(b$vacc_rate[13], mean(c(b$vacc_rate[12], 0.95)))
expect_equal(b$vacc_rate[14], 0.95)

# Alternate adult assumptions: ages 18-69 have the given coverage and every
# other group matches the baseline
adults <- c("78pct" = 0.78, "86pct" = 0.86, "93pct" = 0.93)
for (a in names(adults)) {
  expect_equal(vax[[a]]$vacc_rate[12:14], rep(adults[[a]], 3), info = a)
  expect_equal(vax[[a]]$vacc_rate[-(12:14)], b$vacc_rate[-(12:14)], info = a)
}

# Higher adult coverage means higher overall coverage
overall <- sapply(vax, function(v) sum(v$vacc_rate * v$agepops))
expect_true(all(diff(overall[c("78pct", "86pct", "93pct")]) > 0))
