test_that("multiplication works", {
  expect_equal(2 * 2, 4)
})

test_that("plot_population can discover summary files from an output directory", {
  example_dir <- normalizePath(
    file.path("..", "..", "inst", "extdata", "package_ex_out_example"),
    winslash = "/",
    mustWork = TRUE
  )

  count_plot <- plot_population(example_dir, type = "count")
  age_plot <- plot_population(example_dir, type = "age_class", n = 10)

  expect_s3_class(count_plot, "ggplot")
  expect_s3_class(age_plot, "ggplot")
})

test_that("plot_population accepts custom facet labels and summary options", {
  example_dir <- normalizePath(
    file.path("..", "..", "inst", "extdata", "package_ex_out_example"),
    winslash = "/",
    mustWork = TRUE
  )

  batch_labels <- c(
    "N.out1776184541" = "Scenario N",
    "R.out1776189704" = "Scenario R"
  )

  count_plot <- plot_population(
    example_dir,
    type = "count",
    batch_labels = batch_labels,
    show_mc = FALSE,
    show_ci = TRUE
  )

  sex_plot <- plot_population(
    example_dir,
    type = "sex",
    batch_labels = batch_labels
  )

  expect_s3_class(count_plot, "ggplot")
  expect_s3_class(sex_plot, "ggplot")
})
