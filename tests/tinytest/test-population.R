# Population sizes in data/utaz_population.rds and the vaccination files
# (built by data/utaz_data.R)

data_dir <- file.path("..", "..", "data")

pop <- readRDS(file.path(data_dir, "utaz_population.rds"))
agepops         <- pop$agepops
schoolpops      <- pop$schoolpops
schoolagegroups <- pop$schoolagegroups

# 2024 ACS counts for Hildale UT, Colorado City AZ, and Centennial Park AZ. A
# change here means the census files in multigroup.vaccine changed.
expect_equal(sum(agepops), 5913)
expect_equal(pop$agelims, c(0, 1, 5, 12, 14, 18, 25, 45, 70))
expect_equal(length(agepops), length(pop$agelims))

# Positive integer counts
for (x in list(agepops, schoolpops)) {
  expect_true(all(is.finite(x)))
  expect_true(all(x > 0))
  expect_true(all(x == round(x)))
}

# Schools cover the contiguous age groups 5-11, 12-13, and 14-17
expect_equal(sort(unique(schoolagegroups)), 3:5)
expect_equal(length(schoolpops), length(schoolagegroups))

# The schools of an age group add up to its census count. Each school is
# rounded separately when rescaled, so the sum can be off by up to half a
# person per school.
for (a in unique(schoolagegroups)) {
  inds <- which(schoolagegroups == a)
  expect_true(
    abs(sum(schoolpops[inds]) - agepops[a]) <= length(inds) / 2,
    info = sprintf("schools of age group %s add up to its census count", a)
  )
}

# Model groups: age groups before the schools, the schools, and age groups
# after the schools
grouppops <- c(
  agepops[1:(min(schoolagegroups) - 1)],
  schoolpops,
  agepops[(max(schoolagegroups) + 1):length(agepops)]
)
expect_equal(length(grouppops), 15)
expect_true(
  abs(sum(grouppops) - sum(agepops)) <= length(schoolpops) / 2,
  info = "model groups add up to the census total"
)

# Every vaccination assumption has the same groups and sizes
assumptions <- c("baseline", "78pct", "86pct", "93pct")
for (a in assumptions) {
  vax <- readRDS(
    file.path(data_dir, sprintf("utaz_vaccination_adults_%s.rds", a))
  )
  expect_equal(vax$agepops, grouppops, info = a)
}
