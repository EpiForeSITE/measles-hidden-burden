# Reading and writing the data in data/ as CSV files. Doubles are written with
# the fewest significant digits (15 to 17) that read back as the same number,
# so the files give exactly the values the scripts computed.

#' Formats doubles as the shortest decimal that reads back exactly
format_exact <- function(x) {
  out <- sprintf("%.15g", x)
  for (digits in 16:17) {
    redo <- as.numeric(out) != x
    out[redo] <- sprintf("%.*g", digits, x[redo])
  }
  out
}

#' Writes a data.frame, or a matrix with its row names as the first column
#' (`group`)
write_data <- function(x, file) {
  if (is.matrix(x)) {
    x <- data.frame(
      group            = rownames(x),
      x,
      check.names      = FALSE,
      stringsAsFactors = FALSE
    )
  }
  doubles <- vapply(x, is.double, logical(1))
  x[doubles] <- lapply(x[doubles], format_exact)
  write.csv(x, file, row.names = FALSE, quote = FALSE)
}

#' Reads a contact matrix written by `write_data()`
read_contacts <- function(file) {
  as.matrix(read.csv(file, row.names = 1, check.names = FALSE))
}

#' Reads the vaccination data of an adult vaccination assumption
read_vaccination <- function(file) {
  read.csv(
    file,
    colClasses = c(
      age_labels = "character",
      agepops    = "numeric",
      agelims    = "integer",
      vacc_rate  = "numeric"
    )
  )
}

#' Reads the age and school populations as a list (as used by
#' `multigroup.vaccine::contactMatrixAgeSchool()`)
read_population <- function(dir) {
  c(
    read.csv(
      file.path(dir, "utaz_population_ages.csv"),
      colClasses = "numeric"
    ),
    read.csv(
      file.path(dir, "utaz_population_schools.csv"),
      colClasses = "numeric"
    )
  )
}
