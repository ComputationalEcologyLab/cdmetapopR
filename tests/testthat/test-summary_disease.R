disease_example_dir <- function() {
  system.file("extdata", "Example_dat", package = "cdmetapopR")
}

test_that("summary_disease discovers disease summaries from an output directory", {
  p <- summary_disease(disease_example_dir())

  expect_s3_class(p, "ggplot")
  expect_setequal(unique(p$data$State), as.character(1:3))
  expect_setequal(as.character(unique(p$data$Scenario)), c("Batch 0", "Batch 1"))
})

test_that("summary_disease accepts custom labels and cumulative states", {
  p <- summary_disease(
    disease_example_dir(),
    state_names = c("Susceptible", "Infected", "Recovered"),
    scenario_names = c("Control", "Adaptive"),
    cumulative_states = "Recovered"
  )

  expect_s3_class(p, "ggplot")
  expect_setequal(
    as.character(unique(p$data$State)),
    c("Susceptible", "Infected", "Recovered")
  )
  expect_setequal(as.character(unique(p$data$Scenario)), c("Control", "Adaptive"))
})
