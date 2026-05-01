library(data.table)

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
# Adapting for Utah-Arizona border age ranges

# Ages from the Utah-Arizona border
# Based on indices from 0 to 80
ages <- data.frame(
  from = c(0, 1,  5,  5,  5, 12, 12, 12, 14, 14, 14, 18, 25, 45, 70) + 1,
  to   = c(1, 4, 11, 11, 11, 13, 13, 13, 17, 17, 17, 24, 44, 69, 80) + 1
)

# To group them, we need to 
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

data(short_creek_matrix, package = "measles")
dimnames(short_creek_epistorm) <- dimnames(short_creek_matrix)

# Now, for the schools, we ensure that 80% of their contacts are
# with the same school
schools <- 3:11
for (n in schools) {
  short_creek_epistorm[n, n] <-
    short_creek_epistorm[n, n] + 0.8 * sum(short_creek_epistorm[n, -n])
    
  short_creek_epistorm[n, -n] <- 0.2 * short_creek_epistorm[n, -n]
}

saveRDS(
  short_creek_epistorm,
  file = file.path("data", "short_creek_epistorm.rds")
  )
