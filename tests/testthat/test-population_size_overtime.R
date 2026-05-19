example_output_dir <- function() {
  normalizePath(
    file.path("..", "..", "inst", "extdata", "Adaptive_Run_08"),
    winslash = "/",
    mustWork = TRUE
  )
}

test_that("summary functions discover summary files from an output directory", {
  example_dir <- example_output_dir()

  n_initial_plot <- summary_pop(example_dir, type = "N_initial")
  age_plot <- summary_class(example_dir, type = "age_class", n = 10)

  expect_s3_class(n_initial_plot, "ggplot")
  expect_s3_class(age_plot, "ggplot")
})

test_that("summary functions accept custom facet labels and summary options", {
  example_dir <- example_output_dir()

  batch_labels <- c("Adaptive_Run_08" = "Adaptive Run 08")

  n_initial_plot <- summary_pop(
    example_dir,
    type = "N_initial",
    batch_labels = batch_labels,
    show_mc = FALSE,
    show_ci = TRUE
  )

  sex_plot <- summary_pop(
    example_dir,
    type = "sex",
    batch_labels = batch_labels
  )

  expect_s3_class(n_initial_plot, "ggplot")
  expect_s3_class(sex_plot, "ggplot")
})

test_that("summary_pop sex plot excludes YY categories by default", {
  sex_plot <- summary_pop(example_output_dir(), type = "sex")

  expect_setequal(unique(sex_plot$data$category), c("Males", "Females"))
})

test_that("summary_pop sex plot can include YY categories", {
  sex_plot <- summary_pop(example_output_dir(), type = "sex", include_yys = TRUE)

  expect_setequal(
    unique(sex_plot$data$category),
    c("Males", "Females", "YY Males", "YY Females")
  )
})

test_that("summary_pop mature plot excludes YY categories by default", {
  mature_plot <- summary_pop(example_output_dir(), type = "mature")

  expect_setequal(unique(mature_plot$data$category), c("Mature Females", "Mature Males"))
})

test_that("summary_pop mature plot can include YY categories", {
  mature_plot <- summary_pop(example_output_dir(), type = "mature", include_yys = TRUE)

  expect_setequal(
    unique(mature_plot$data$category),
    c("Mature Females", "Mature Males", "Mature YY Males", "Mature YY Females")
  )
})

test_that("plot_population is deprecated but still dispatches to new summary functions", {
  example_dir <- example_output_dir()

  expect_warning(
    pop_plot <- plot_population(example_dir, type = "N_initial"),
    "deprecated"
  )
  expect_warning(
    class_plot <- plot_population(example_dir, type = "age_class", n = 10),
    "deprecated"
  )

  expect_s3_class(pop_plot, "ggplot")
  expect_s3_class(class_plot, "ggplot")
})
