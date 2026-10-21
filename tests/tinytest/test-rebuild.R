# The committed data files match a fresh build with data/utaz_data.R and
# data/epistorm_matrix.R. A mismatch means a script changed without re-running
# `make data`, or the pinned packages give different data.

data_dir <- file.path("..", "..", "data")

# Build in a temporary copy of data/ so the committed files are not touched
build_dir <- tempfile("utaz-data-")
dir.create(file.path(build_dir, "data"), recursive = TRUE)
file.copy(
  file.path(
    data_dir,
    c("utaz_data.R", "epistorm_matrix.R", "Total-M-by5_80-matrix.csv")
  ),
  file.path(build_dir, "data")
)

old_wd <- setwd(build_dir)
status <- sapply(
  c("utaz_data.R", "epistorm_matrix.R"),
  function(script) {
    system2(
      file.path(R.home("bin"), "Rscript"),
      file.path("data", script),
      stdout = FALSE,
      stderr = FALSE
    )
  }
)
setwd(old_wd)

expect_equal(unname(status), c(0L, 0L), info = "data scripts run")

committed <- list.files(data_dir, pattern = "^utaz_.*[.]rds$")
built     <- list.files(file.path(build_dir, "data"), pattern = "^utaz_.*[.]rds$")

expect_equal(sort(built), sort(committed))

for (f in committed) {
  expect_equal(
    readRDS(file.path(build_dir, "data", f)),
    readRDS(file.path(data_dir, f)),
    tolerance = 1e-10,
    info      = f
  )
}

unlink(build_dir, recursive = TRUE)
