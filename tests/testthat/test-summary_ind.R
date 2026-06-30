ind_example_dir <- function() {
  system.file("extdata", "Example_dat", package = "cdmetapopR")
}

ind_sample_example_dir <- function() {
  source_dir <- ind_example_dir()
  temp_dir <- file.path(tempdir(), "cdmetapopR_ind_sample_example")
  if (dir.exists(temp_dir)) {
    unlink(temp_dir, recursive = TRUE)
  }
  dir.create(temp_dir, recursive = TRUE)

  run_dirs <- list.dirs(source_dir, full.names = FALSE, recursive = FALSE)
  for (run_dir in run_dirs) {
    dir.create(file.path(temp_dir, run_dir), recursive = TRUE)
    file.copy(
      from = file.path(source_dir, run_dir, "ind9.csv"),
      to = file.path(temp_dir, run_dir, "indSample9.csv")
    )
  }

  temp_dir
}

test_that("summary_ind creates one-year age, size, and age-size plots from an output directory", {
  example_dir <- ind_example_dir()

  age_plot <- summary_ind(example_dir, type = "age", year = 9)
  size_plot <- summary_ind(example_dir, type = "size", year = 9)
  age_size_plot <- summary_ind(example_dir, type = "age_size", year = 9)

  expect_s3_class(age_plot, "ggplot")
  expect_s3_class(size_plot, "ggplot")
  expect_s3_class(age_size_plot, "ggplot")
  expect_true(all(age_plot$data$Year == 9))
  expect_false(any(vapply(
    age_size_plot$layers,
    function(layer) inherits(layer$geom, "GeomSmooth"),
    logical(1)
  )))
})

test_that("summary_ind creates cdist and hindex histograms from a run directory", {
  run_dir <- file.path(ind_example_dir(), "run0batch0mc0species0")

  cdist_plot <- summary_ind(run_dir, type = "cdist", year = 9)
  hindex_plot <- summary_ind(run_dir, type = "hindex", year = 9)

  expect_s3_class(cdist_plot, "ggplot")
  expect_s3_class(hindex_plot, "ggplot")
  expect_true(all(cdist_plot$data$CDist != -9999))
})

test_that("summary_ind creates movement plots across years", {
  movement_plot <- summary_ind(
    ind_example_dir(),
    type = "movement",
    years = 0:9,
    batch = 1,
    mc = 1
  )

  expect_s3_class(movement_plot, "ggplot")
  expect_setequal(movement_plot$data$Year, 0:9)
  expect_true(all(movement_plot$data$prop_moved >= 0))
  expect_true(all(movement_plot$data$prop_moved <= 1))
  expect_false(any(vapply(
    movement_plot$layers,
    function(layer) inherits(layer$geom, "GeomLine"),
    logical(1)
  )))
})

test_that("summary_ind accepts a direct ind file path", {
  ind_file <- file.path(ind_example_dir(), "run0batch0mc0species0", "ind3.csv")

  p <- summary_ind(ind_file, type = "age")

  expect_s3_class(p, "ggplot")
  expect_true(all(p$data$Year == 3))
})

test_that("summary_ind can read ind sample files when requested", {
  sample_dir <- ind_sample_example_dir()

  p <- summary_ind(sample_dir, type = "age", year = 9, file_type = "ind_Sample")

  expect_s3_class(p, "ggplot")
  expect_true(all(p$data$Year == 9))
  expect_true(all(p$data$.file_type == "ind_Sample"))
})

test_that("summary_ind can filter to selected patches", {
  ind_data <- data.frame(
    PatchID = c(1, 2, 10, 100),
    age = c(1, 2, 3, 4),
    Year = 9
  )

  p <- summary_ind(
    ind_data,
    type = "age",
    year = 9,
    patches = c(1, 10)
  )

  expect_s3_class(p, "ggplot")
  expect_setequal(sort(unique(p$data$PatchID)), c(1, 10))
})

test_that("summary_ind warns when some requested patches do not exist", {
  ind_data <- data.frame(
    PatchID = c(1, 2, 10),
    age = c(1, 2, 3),
    Year = 9
  )

  expect_warning(
    p <- summary_ind(ind_data, type = "age", year = 9, patches = c(1, 99)),
    "Patches 99 do not exist"
  )

  expect_s3_class(p, "ggplot")
  expect_setequal(unique(p$data$PatchID), 1)
})

test_that("summary_ind errors when no requested patches exist", {
  ind_data <- data.frame(
    PatchID = c(1, 2, 10),
    age = c(1, 2, 3),
    Year = 9
  )

  expect_error(
    suppressWarnings(summary_ind(ind_data, type = "age", year = 9, patches = c(99, 100))),
    "No individuals matched the requested patches"
  )
})
