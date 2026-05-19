ind_example_dir <- function() {
  normalizePath(
    file.path("..", "..", "inst", "extdata", "Adaptive_Run_08"),
    winslash = "/",
    mustWork = TRUE
  )
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
})

test_that("summary_ind accepts a direct ind file path", {
  ind_file <- file.path(ind_example_dir(), "run0batch0mc0species0", "ind3.csv")

  p <- summary_ind(ind_file, type = "age")

  expect_s3_class(p, "ggplot")
  expect_true(all(p$data$Year == 3))
})
