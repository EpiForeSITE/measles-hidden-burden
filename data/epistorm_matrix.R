library(data.table)
library(multigroup.vaccine)
library(measles)

#' Calculate a contact matrix for age groups and schools
#'
#' Splits one or more age groups into individual schools, distributing contacts
#' proportionally among them. Age groups not covered by any school retain their
#' original contact rates; school groups interact among themselves according to
#' proportional preference (see `contactMatrixPropPref`) and with all other
#' groups via the original matrix. Adapted from `multigroup.
#' vaccine::contactMatrixAgeSchool()`.
#'
#' @param cmp a symmetric contact matrix for the age groups (e.g. as returned
#'   by `contactMatrixPolymod` or `make_cmat_symmetric`).
#' @param agepops integer vector giving the population size of each age group.
#' @param schoolagegroups integer vector of length equal to `schoolpops`,
#'   indicating which age-group index each school belongs to.
#' @param schoolpops integer vector of school population sizes.
#' @param schportion numeric scalar in [0, 1]: portion of within-age-group
#'   contacts that are exclusively within a school.
#' @returns a square matrix with the contact rate of each group (row) with
#'   members of each other group (column). Rows/columns are labelled with
#'   the original age-group names; school groups inherit the parent age-group
#'   name suffixed with `s1`, `s2`, etc.
#' @examples
#' contactMatrixAgeSchool2(cmp = diag(3), agepops = c(500, 1300, 8200),
#'   schoolagegroups = c(2, 2), schoolpops = c(600, 700), schportion = 0.7)
contactMatrixAgeSchool2 <- function(
  cmp,
  agepops, schoolagegroups, schoolpops, schportion
  ) {
  # Total groups = original age groups, minus school-age groups that get split,
  # plus the individual schools that replace them.
  ngrps <- length(agepops) + length(schoolpops) - length(unique(schoolagegroups))
  cmps <- matrix(0, ngrps, ngrps)

  # npre / npost: number of age groups entirely before / after the school-age
  # span. These groups are copied straight from cmp without modification.
  npre  <- min(schoolagegroups) - 1
  npost <- length(agepops) - max(schoolagegroups)

  # Index ranges for the pre-school and post-school age groups in cmps.
  ipre  <- 1:npre
  ipost <- (ngrps - npost + 1):ngrps

  # Build row/column names: pre-school names | "AgeGroupsN" per school | post-school names.
  nm <- colnames(cmp)
  grpnames <- c(
    nm[1:npre],
    paste0(nm[schoolagegroups], "s", seq_along(schoolagegroups)),
    nm[(nrow(cmp) - npost + 1):nrow(cmp)]
  )
  rownames(cmps) <- colnames(cmps) <- grpnames

  # Copy contact rates among non-school age groups directly from cmp.
  cmps[ipre,  ipre]  <- cmp[1:npre, 1:npre]
  cmps[ipost, ipost] <- cmp[(nrow(cmp) - npost + 1):nrow(cmp), (nrow(cmp) - npost + 1):nrow(cmp)]
  cmps[ipre,  ipost] <- cmp[1:npre, (nrow(cmp) - npost + 1):nrow(cmp)]
  cmps[ipost, ipre]  <- cmp[(nrow(cmp) - npost + 1):nrow(cmp), 1:npre]

  sag <- unique(schoolagegroups)
  for (s in sag) {
    inds <- which(schoolagegroups == s)  # column indices of schools belonging to age group s
    nums <- length(inds)

    # Contacts between pre-school age groups and schools in age group s.
    # Columns are scaled by the school share of the age-group population;
    # rows (school → pre-school) use the raw age-group rate from cmp.
    for (i in 1:npre) {
      cmps[i, npre + inds]      <- cmp[i, s] * schoolpops[inds] / agepops[s]
      cmps[npre + inds, i]      <- cmp[s, i]
    }

    # Same for post-school age groups (indexed from the bottom of the matrix).
    for (i in 1:npost) {
      cmps[nrow(cmps) - i + 1, npre + inds] <- cmp[nrow(cmp) - i + 1, s] * schoolpops[inds] / agepops[s]
      cmps[npre + inds, nrow(cmps) - i + 1] <- cmp[s, nrow(cmp) - i + 1]
    }

    # Within-school-age-group block: use proportional preference so that
    # each school has the same total within-group contact rate as the original
    # age group, but contacts are preferentially within the same school.
    cmps[npre + inds, npre + inds] <- contactMatrixPropPref(
      schoolpops[inds], rep(cmp[s, s], nums), rep(schportion, nums)
    )

    # Cross-school-age-group contacts (only relevant when schools span more
    # than one age group, e.g. a K-8 and a high school).
    if (length(sag) > 1) {
      for (ss in sag[sag != s]) {
        for (j in which(schoolagegroups == ss)) {
          cmps[npre + inds, npre + j] <- cmp[s, ss] * schoolpops[j] / agepops[ss]
        }
      }
    }
  }
  cmps
}

# Age-group label names matching the Epistorm matrix columns (5-year bands, 0–80+)
age_limits <- seq(from = 0, to = 80, by = 5)
dnames <- sprintf("%dto%d", age_limits[-length(age_limits)], age_limits[-1] - 1)
dnames <- c(dnames, "80plus")

# Retrieving mixing data from epistorm
if (!file.exists(file.path("data", "Total-M-by5_80-matrix.csv"))) {
  download.file(
    url = "https://raw.githubusercontent.com/epistorm/Epistorm-Mix/05966ba49c7b49fb1cd902d6b98b3be0bb2785a8/matrices/M_matrix/Total-M-by5_80-matrix.csv",
    destfile = file.path("data", "Total-M-by5_80-matrix.csv")
  )  
}

# Creating a mixing matrix from epistorm data
epistorm <- fread("data/Total-M-by5_80-matrix.csv")
epistorm <- epistorm[, resp_age_by5_80 := NULL] |> 
  as.matrix()

dimnames(epistorm) <- list(dnames, dnames)

# Transforming the data get the increments in 1 year
es_ranges <- rownames(epistorm)
es_ranges <- data.frame(
  from = as.numeric(gsub("[^0-9]+.+", "", es_ranges)),
  to   = as.numeric(gsub(".+[^0-9]+", "", es_ranges))
)

es_ranges$to[is.na(es_ranges$to)] <- Inf

new_range <- 1:81
epistorm2 <- matrix(0, nrow = 81, ncol = 81)
for (i in new_range) {
  for (j in new_range) {

    a_i <- i - 1
    a_j <- j - 1
    
    # Identify relevant cell
    m_i <- with(es_ranges, which(from <= a_i & to >= a_i))
    m_j <- with(es_ranges, which(from <= a_j & to >= a_j))

    epistorm2[i, j] <- epistorm[m_i, m_j] / 5

    # The last column is for ages 80+, so we don't
    # need to divide it by 5
    if (m_j == nrow(es_ranges)) {
      epistorm2[i, j] <- epistorm2[i, j] * 5
    }

  }

}

# Validating
for (n in 1:nrow(es_ranges)) {

  i <- es_ranges$from[n] + 1
  j <- es_ranges$to[n] + 1

  # Infinity is not a valid index, so we set it to 81 (the last column)
  if (!is.finite(j)) {
      j <- 81
  }

  tryCatch(
    stopifnot(
      all(rowSums(epistorm2[i:j, , drop=FALSE]) == sum(epistorm[n, ]))
      ),
    error = \(e) {
      stop(
        sprintf(
          "Validation failed for age range %i-%s",
          es_ranges$from[n],
          ifelse(
            is.finite(es_ranges$to[n]),
            es_ranges$to[n],
            "Inf"
            )
        )
      )
    }
  )
}

# ==============================================================================
# Collapse the 1-year matrix into the Short Creek (Utah-Arizona border) age bands
# Age indices are 1-based (age 0 → index 1, age 80 → index 81)

ages <- data.frame(
  from = c(0, 1,  5, 12, 14, 18, 25, 45, 70) + 1,
  to   = c(0, 4, 11, 13, 17, 24, 44, 69, 80) + 1
)

# Collapse by summing rows within each band and then averaging across rows
short_creek_epistorm <- matrix(0, nrow = nrow(ages), ncol = nrow(ages))

for (n in seq_len(nrow(ages))) {
  
  row_i <- ages$from[n]
  row_j <- ages$to[n]

  for (m in seq_len(nrow(ages))) {
    
    col_i <- ages$from[m]
    col_j <- ages$to[m]

    # We first collapse the columns and then take the mean 
    # to distribute the contacts proportionally
    short_creek_epistorm[n, m] <-
      rowSums(epistorm2[row_i:row_j, col_i:col_j, drop=FALSE]) |>
      mean()


  }

}

dn <- c(
  "under1", "1to4", "5to11", "12to13", "14to17", "18to24",
  "25to44", "45to69", "70+"
  )
dimnames(short_creek_epistorm) <- list(dn, dn)

# ==============================================================================
# Preparing to scale the matrix for the short creek population
# ==============================================================================

hildale_path <- system.file("extdata", "hildale_ut_2024.csv", package = "multigroup.vaccine")
colorado_city_path <- system.file("extdata", "colorado_city_az_2024.csv", package = "multigroup.vaccine")
centennial_park_path <- system.file("extdata", "centennial_park_az_2024.csv", package = "multigroup.vaccine")

agelims <- c(0, 1, 5, 12, 14, 18, 25, 45, 70)

hildale <- getCityData(
  city_name = "Hildale city, Utah",
  csv_path = hildale_path,
  age_groups = agelims
)

colorado_city <- getCityData(
  city_name = "Colorado City town, Arizona",
  csv_path = colorado_city_path,
  age_groups = agelims
)

centennial_park <- getCityData(
  city_name = "Centennial Park CDP, Arizona",
  csv_path = centennial_park_path,
  age_groups = agelims
)

agepops <- round(hildale$age_pops + colorado_city$age_pops + centennial_park$age_pops)
schoolpops <- c(250, 350, 190, 86, 150, 84, 114, 108, 205)
schoolagegroups <- c(3, 3, 3, 4, 4, 4, 5, 5, 5)

# Readjust the school populations to match the age data:
for (a in unique(schoolagegroups)) {
  inds <- which(schoolagegroups == a)
  schoolpops[inds] <- round(agepops[a] * schoolpops[inds] / sum(schoolpops[inds]))
}

# Ensuring symmetry before we apply the school-age adjustments
short_creek_epistorm <- make_cmat_symmetric(short_creek_epistorm, agepops)

# Verify symmetry of the age-only matrix before school splitting
stopifnot(all(abs(
  short_creek_epistorm * agepops -
  t(short_creek_epistorm * agepops)
) < 1e-10))

cm <- contactMatrixAgeSchool2(
  cmp = short_creek_epistorm,
  agepops = agepops,
  schoolagegroups = schoolagegroups,
  schoolpops = schoolpops,
  schportion = 0.7
)

grouppops <- c(
  agepops[1:(min(schoolagegroups) - 1)],
  schoolpops,
  agepops[(max(schoolagegroups) + 1):length(agepops)]
)

# Verify symmetry of the final school-resolved matrix
stopifnot(max(abs(
  cm * grouppops -
  t(cm * grouppops)
)) < 1e-10)

# Inspect the diagonal proportion of within-group contacts (for review)
message("Diagonal share of contacts — age groups:")
print(round(diag(short_creek_epistorm / rowSums(short_creek_epistorm)), 3))
message("Diagonal share of contacts — school-resolved groups:")
print(round(diag(cm / rowSums(cm)), 3))

saveRDS(
  cm,
  file = file.path("data", "short_creek_epistorm.rds")
  )
