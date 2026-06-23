disease_example_dir <- function() {
  system.file("extdata", "Adaptive_Run_08", package = "cdmetapopR")
}

test_that("summarize_states discovers disease summaries from an output directory", {
  p <- summarize_states(disease_example_dir())

  expect_s3_class(p, "ggplot")
  expect_setequal(unique(p$data$State), as.character(1:3))
  expect_setequal(as.character(unique(p$data$Scenario)), c("Batch 0", "Batch 1"))
})

test_that("summarize_states accepts custom labels and cumulative states", {
  p <- summarize_states(
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
