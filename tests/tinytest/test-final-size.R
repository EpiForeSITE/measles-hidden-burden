# Deterministic final outbreak sizes at R0 = 9, compared with the
# multigroup.vaccine Utah/Arizona vignette ("Alternate adult immunization
# assumptions"), at the commit pinned in .devcontainer/Containerfile

library(multigroup.vaccine)

data_dir <- file.path("..", "..", "data")

cm <- readRDS(file.path(data_dir, "utaz_contacts_polymod.rds"))

# Total infections reported in the vignette for each assumption
expected <- c(baseline = 2788, "78pct" = 2396, "86pct" = 2158, "93pct" = 1969)

for (a in names(expected)) {

  vax <- readRDS(
    file.path(data_dir, sprintf("utaz_vaccination_adults_%s.rds", a))
  )
  grouppops <- vax$agepops

  # Immune people: 93% efficacy under age 5, 97% otherwise, and those aged 70+
  # are immune
  efficacy <- rep(0.97, nrow(vax))
  efficacy[1:2] <- 0.93
  efficacy[nrow(vax)] <- 1
  immune <- round(vax$vacc_rate * grouppops * efficacy)

  # One initial infection among 18-24-year-olds
  init_infected <- rep(0, nrow(vax))
  init_infected[vax$age_labels == "18to24"] <- 1

  fs <- finalsize(
    popsize       = grouppops,
    R0            = 9,
    contactmatrix = cm,
    relsusc       = 1,
    reltransm     = 1,
    initR         = rep(0, nrow(vax)),
    initI         = init_infected,
    initV         = immune
  )

  expect_equal(round(sum(fs)), expected[[a]], info = a)

}
