# Population, vaccination, and contact data in data/ (built by
# data/utaz_data.R and data/epistorm_matrix.R)

data_dir <- file.path("..", "..", "data")

pop <- readRDS(file.path(data_dir, "utaz_population.rds"))

assumptions <- c("baseline", "78pct", "86pct", "93pct")
vax <- lapply(assumptions, function(a) {
  readRDS(file.path(data_dir, sprintf("utaz_vaccination_adults_%s.rds", a)))
})
names(vax) <- assumptions

matrices <- list(
  polymod  = readRDS(file.path(data_dir, "utaz_contacts_polymod.rds")),
  epistorm = readRDS(file.path(data_dir, "utaz_contacts_epistorm.rds"))
)

# ==============================================================================
# Population
# ==============================================================================

# 2024 ACS counts for Hildale UT, Colorado City AZ, and Centennial Park AZ
expect_equal(sum(pop$agepops), 5913)

# The schools of an age group add up to its census count
for (a in unique(pop$schoolagegroups)) {
  expect_equal(
    sum(pop$schoolpops[pop$schoolagegroups == a]),
    pop$agepops[a],
    info = sprintf("schools of age group %s", a)
  )
}

# Every file has the same 15 groups, which add up to the census total
grouppops <- vax$baseline$agepops
expect_equal(sum(grouppops), 5913)
for (a in assumptions) {
  expect_equal(vax[[a]]$agepops, grouppops, info = a)
  expect_equal(vax[[a]]$age_labels, rownames(matrices$polymod), info = a)
}

# ==============================================================================
# Vaccination
# ==============================================================================

for (a in assumptions) {
  rate <- vax[[a]]$vacc_rate
  expect_true(all(rate >= 0 & rate <= 1), info = a)

  # Low, but not implausibly so (e.g., counts or percentages used as shares)
  overall <- sum(rate * grouppops) / sum(grouppops)
  expect_true(overall > 0.3 && overall < 0.9, info = a)
}

# The alternate assumptions set ages 18-69 (groups 12-14) and nothing else
adults <- c("78pct" = 0.78, "86pct" = 0.86, "93pct" = 0.93)
for (a in names(adults)) {
  expect_equal(vax[[a]]$vacc_rate[12:14], rep(adults[[a]], 3), info = a)
  expect_equal(
    vax[[a]]$vacc_rate[-(12:14)],
    vax$baseline$vacc_rate[-(12:14)],
    info = a
  )
}

# ==============================================================================
# Contact matrices
# ==============================================================================

for (src in names(matrices)) {
  cm <- matrices[[src]]

  expect_equal(dimnames(cm), rep(list(vax$baseline$age_labels), 2), info = src)

  # Reciprocity: total contacts from group i to j equal those from j to i
  expect_equal(cm * grouppops, t(cm * grouppops), info = src)

  # Contacts per day
  expect_true(all(cm >= 0) && all(rowSums(cm) < 50), info = src)
}
