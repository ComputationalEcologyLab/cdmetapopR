example_output_dir <- function() {
  system.file("extdata", "Adaptive_Run_08", package = "cdmetapopR")
}

multi_species_example_dir <- function() {
  source_dir <- example_output_dir()
  temp_dir <- file.path(tempdir(), "cdmetapopR_multi_species_summary_example")
  if (dir.exists(temp_dir)) {
    unlink(temp_dir, recursive = TRUE)
  }
  dir.create(temp_dir, recursive = TRUE)

  run_dirs <- list.dirs(source_dir, full.names = FALSE, recursive = FALSE)
  for (run_dir in run_dirs) {
    species0_dest <- file.path(temp_dir, run_dir)
    dir.create(species0_dest, recursive = TRUE)
    file.copy(
      from = list.files(file.path(source_dir, run_dir), full.names = TRUE),
      to = species0_dest,
      recursive = TRUE
    )

    species1_dir <- sub("species0$", "species1", run_dir)
    species1_dest <- file.path(temp_dir, species1_dir)
    dir.create(species1_dest, recursive = TRUE)
    file.copy(
      from = list.files(file.path(source_dir, run_dir), full.names = TRUE),
      to = species1_dest,
      recursive = TRUE
    )
  }

  temp_dir
}

test_that("summary functions discover summary files from an output directory", {
  example_dir <- example_output_dir()

  n_initial_plot <- summary_pop(example_dir, type = "N_initial")
  age_plot <- summary_class(example_dir, type = "age_class", n = 10)

  expect_s3_class(n_initial_plot, "ggplot")
  expect_s3_class(age_plot, "ggplot")
})

test_that("summary_class age classes are ordered numerically", {
  age_plot <- summary_class(example_output_dir(), type = "age_class", n = 10)
  age_levels <- levels(age_plot$data$Ages)

  expect_true(length(age_levels) > 10)
  expect_identical(age_levels[1:11], paste0("Age_", 0:10))
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

test_that("summary_pop and summary_class can filter directory inputs by species", {
  example_dir <- multi_species_example_dir()

  pop_species1 <- summary_pop(example_dir, type = "N_initial", species = 1)
  class_species1 <- summary_class(example_dir, type = "age_plus_one", species = 1)

  expect_s3_class(pop_species1, "ggplot")
  expect_s3_class(class_species1, "ggplot")
  expect_true(all(pop_species1$data$.species == 1))
  expect_true(all(class_species1$data$.species == 1))
})

test_that("summary_pop and summary_class can filter directory inputs by run, batch, and mc", {
  example_dir <- example_output_dir()

  pop_batch1 <- summary_pop(example_dir, type = "N_initial", run = 0, batch = 1, mc = 1)
  class_batch1 <- summary_class(example_dir, type = "age_plus_one", run = 0, batch = 1, mc = 1)

  expect_s3_class(pop_batch1, "ggplot")
  expect_s3_class(class_batch1, "ggplot")
  expect_true(all(pop_batch1$data$.run == 0))
  expect_true(all(pop_batch1$data$.batch == 1))
  expect_true(all(pop_batch1$data$.mc == 1))
  expect_true(all(class_batch1$data$.run == 0))
  expect_true(all(class_batch1$data$.batch == 1))
  expect_true(all(class_batch1$data$.mc == 1))
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

test_that("summary_pop can plot allelic richness", {
  richness_plot <- summary_pop(example_output_dir(), type = "allelic_richness")

  expect_s3_class(richness_plot, "ggplot")
  expect_true(all(c("Year", "Richness") %in% names(richness_plot$data)))
  expect_true(all(richness_plot$data$Richness >= 0, na.rm = TRUE))
  expect_true(all(richness_plot$data$Richness <= 6, na.rm = TRUE))
})

test_that("summary_pop can plot observed and expected heterozygosity", {
  het_plot <- summary_pop(example_output_dir(), type = "het")

  expect_s3_class(het_plot, "ggplot")
  expect_true(all(c("Year", "Metric", "Heterozygosity") %in% names(het_plot$data)))
  expect_setequal(unique(het_plot$data$Metric), c("Observed (Ho)", "Expected (He)"))
  expect_true(all(het_plot$data$Heterozygosity >= 0, na.rm = TRUE))
  expect_true(all(het_plot$data$Heterozygosity <= 1, na.rm = TRUE))
})
