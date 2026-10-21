# Contact matrices in data/utaz_contacts_<source>.rds (built by
# data/utaz_data.R and data/epistorm_matrix.R)

data_dir <- file.path("..", "..", "data")

vax <- readRDS(file.path(data_dir, "utaz_vaccination_adults_baseline.rds"))
pop <- readRDS(file.path(data_dir, "utaz_population.rds"))
grouppops <- vax$agepops

matrices <- list(
  polymod  = readRDS(file.path(data_dir, "utaz_contacts_polymod.rds")),
  epistorm = readRDS(file.path(data_dir, "utaz_contacts_epistorm.rds"))
)

mean_contacts <- function(cm) sum(rowSums(cm) * grouppops) / sum(grouppops)

for (src in names(matrices)) {

  cm <- matrices[[src]]

  # One row and column per group, in the order of the vaccination data
  expect_equal(dim(cm), c(15L, 15L), info = src)
  expect_equal(rownames(cm), vax$age_labels, info = src)
  expect_equal(colnames(cm), vax$age_labels, info = src)

  expect_true(all(is.finite(cm)), info = src)
  expect_true(all(cm >= 0), info = src)

  # Reciprocity: total contacts from group i to j equal those from j to i
  expect_equal(cm * grouppops, t(cm * grouppops), info = src)

  # Contacts per day: every group has some, none has an implausible number
  expect_true(all(rowSums(cm) > 1 & rowSums(cm) < 50), info = src)
  expect_true(mean_contacts(cm) > 5 && mean_contacts(cm) < 30, info = src)

  # Within an age group, students have more contacts per person with their own
  # school than with each other school (schportion = 0.7)
  for (a in unique(pop$schoolagegroups)) {
    inds <- 2 + which(pop$schoolagegroups == a)
    per_person <- t(t(cm[inds, inds]) / grouppops[inds])
    for (i in seq_along(inds)) {
      expect_true(
        all(per_person[i, i] > per_person[i, -i]),
        info = sprintf("%s: %s", src, rownames(cm)[inds[i]])
      )
    }
  }

}

# The two sources measure the same thing, so their overall contact rates
# should be within the same order of magnitude
ratio <- mean_contacts(matrices$epistorm) / mean_contacts(matrices$polymod)
expect_true(ratio > 0.25 && ratio < 4)
