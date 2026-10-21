# Population, POLYMOD contact matrix, and vaccination data for the
# Utah-Arizona border community (Hildale UT, Colorado City AZ, and Centennial
# Park AZ). Follows the multigroup.vaccine vignette "Utah/Arizona border
# community model with age and school structure" at the commit pinned in
# .devcontainer/Containerfile:
# https://github.com/EpiForeSITE/multigroup-vaccine/blob/ddd9201f28b9908c033542f6a2445b84619af1c7/vignettes/experiments/utaz_age_school.Rmd
#
# Run from the repository root (`make data`). Writes to data/:
#
# - utaz_population.rds: age and school populations (used by epistorm_matrix.R).
# - utaz_contacts_polymod.rds: the 15 x 15 POLYMOD contact matrix.
# - utaz_vaccination_adults_<assumption>.rds: one data.frame per adult
#   vaccination assumption (see `vaccination_data()`), selected in template.qmd
#   with the `vax_adults` parameter.

library(multigroup.vaccine)

# ==============================================================================
# Population by age (ACS 2024, table S0101)
# ==============================================================================

agelims <- c(0, 1, 5, 12, 14, 18, 25, 45, 70)

places <- c(
  "Hildale city, Utah"           = "hildale_ut_2024.csv",
  "Colorado City town, Arizona"  = "colorado_city_az_2024.csv",
  "Centennial Park CDP, Arizona" = "centennial_park_az_2024.csv"
)

agepops <- 0
for (p in names(places)) {
  city <- getCityData(
    city_name  = p,
    csv_path   = system.file("extdata", places[p], package = "multigroup.vaccine"),
    age_groups = agelims
  )
  agepops <- agepops + city$age_pops
}
agepops <- round(agepops)

# ==============================================================================
# School enrollment and MMR vaccination (public school records)
# ==============================================================================

schoolpops      <- c(250, 350, 190, 86, 150, 84, 114, 108, 205)
schoolagegroups <- c(3, 3, 3, 4, 4, 4, 5, 5, 5)
schoolvax       <- c(16, 129, 80, 20, 55, 50, 27, 40, 93)

# Rescale the schools to match the census age counts
for (a in unique(schoolagegroups)) {
  inds <- which(schoolagegroups == a)
  schoolpopsnew <- round(agepops[a] * schoolpops[inds] / sum(schoolpops[inds]))
  schoolvax[inds] <- round(schoolpopsnew * schoolvax[inds] / schoolpops[inds])
  schoolpops[inds] <- schoolpopsnew
}

saveRDS(
  list(
    agelims         = agelims,
    agepops         = agepops,
    schoolagegroups = schoolagegroups,
    schoolpops      = schoolpops
  ),
  file = file.path("data", "utaz_population.rds")
)

# ==============================================================================
# Contact matrix (POLYMOD)
# ==============================================================================

cm <- contactMatrixAgeSchool(
  agelims,
  agepops,
  schoolagegroups,
  schoolpops,
  schportion = 0.7
)

grouppops <- c(
  agepops[1:(min(schoolagegroups) - 1)],
  schoolpops,
  agepops[(max(schoolagegroups) + 1):length(agepops)]
)

stopifnot(max(abs(cm * grouppops - t(cm * grouppops))) < 1e-10)

saveRDS(cm, file = file.path("data", "utaz_contacts_polymod.rds"))

# ==============================================================================
# Vaccination
# ==============================================================================

#' Vaccination coverage by group
#'
#' @param adults `NULL` for the baseline assumption, or the vaccination coverage
#'   (between 0 and 1) of all adults aged 18-69. The baseline sets ages 18-24 to
#'   the high-school coverage, ages 25-44 to the mean of that and 95%, and ages
#'   45-69 to 95%. Under 1s are unvaccinated, ages 1-4 have the elementary
#'   school coverage, and those aged 70+ are immune in both cases.
#' @returns A data.frame with one row per group of the contact matrix:
#'   `age_labels`, `agepops`, `agelims` (upper age limit), and `vacc_rate`
#'   (share vaccinated; the model applies the vaccine efficacy).
vaccination_data <- function(adults = NULL) {

  elem <- schoolagegroups == 3
  high <- schoolagegroups == 5

  groupvax <- c(
    0,
    grouppops[2] * sum(schoolvax[elem]) / sum(schoolpops[elem]),
    schoolvax,
    grouppops[12] * sum(schoolvax[high]) / sum(schoolpops[high]),
    0,
    grouppops[14] * 0.95,
    grouppops[15]
  )
  groupvax[13] <- grouppops[13] * mean(c(groupvax[12] / grouppops[12], 0.95))

  if (!is.null(adults)) {
    stopifnot(adults >= 0, adults <= 1)
    groupvax[12:14] <- grouppops[12:14] * adults
  }

  # Upper age limit of each group (1 for under 1s and 90 for 70+)
  labs <- rownames(cm)
  agelims_upper <- rep(1L, length(labs))
  has_to <- grepl("to", labs)
  agelims_upper[has_to] <- as.integer(gsub(".+to([0-9]+).*", "\\1", labs[has_to]))
  agelims_upper[labs == "70+"] <- 90L

  data.frame(
    age_labels = rownames(cm),
    agepops    = grouppops,
    agelims    = agelims_upper,
    vacc_rate  = groupvax / grouppops
  )

}

#' Saves the vaccination data for an assumption
#'
#' The file is data/utaz_vaccination_adults_<assumption>.rds, where the
#' assumption is "baseline" or the adult coverage in percent (e.g., "78pct").
save_vaccination <- function(adults = NULL) {

  assumption <- if (is.null(adults)) "baseline" else
    sprintf("%gpct", adults * 100)

  saveRDS(
    vaccination_data(adults),
    file = file.path(
      "data",
      sprintf("utaz_vaccination_adults_%s.rds", assumption)
    )
  )

}

# Assumptions in the multigroup.vaccine vignette ("Alternate adult immunization
# assumptions"): Washington County UT (78%); Mohave County AZ, Utah, and Arizona
# (86%); and both counties 10 years ago (93%).
save_vaccination()
save_vaccination(0.78)
save_vaccination(0.86)
save_vaccination(0.93)
