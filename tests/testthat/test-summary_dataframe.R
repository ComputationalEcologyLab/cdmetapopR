summary_dataframe_example_dir <- function() {
  system.file("extdata", "Adaptive_Run_08", package = "cdmetapopR")
}

test_that("summary_dataframe returns pop and class data with metadata", {
  example_dir <- summary_dataframe_example_dir()

  pop_df <- summary_dataframe(example_dir, type = "pop", batch = 1, mc = 1)
  class_df <- summary_dataframe(example_dir, type = "class", batch = 1, mc = 1)

  expect_s3_class(pop_df, "data.frame")
  expect_s3_class(class_df, "data.frame")
  expect_true(all(c("Year", "PatchID", "GrowthRate", "K", "N_Initial", ".run", ".batch", ".mc", ".species") %in% names(pop_df)))
  expect_true(all(c("Year", "ClassID", "Ages", "N_Initial_Age", ".run", ".batch", ".mc", ".species") %in% names(class_df)))
  expect_false("Element" %in% names(pop_df))
  expect_false("Element" %in% names(class_df))
  expect_true(all(pop_df$.batch == 1))
  expect_true(all(pop_df$.mc == 1))
  expect_true(all(class_df$.batch == 1))
  expect_true(all(class_df$.mc == 1))
  expect_true(all(!grepl("\\|", as.character(pop_df$N_Initial), fixed = FALSE)))
  expect_true(all(!grepl("\\|", as.character(class_df$N_Initial_Age), fixed = FALSE)))
  expect_true(0 %in% pop_df$PatchID)
  expect_true(any(pop_df$PatchID > 1))
  expect_true(any(class_df$ClassID > 1))
})

test_that("summary_dataframe can include multiple MCs for pop data", {
  pop_df <- summary_dataframe(summary_dataframe_example_dir(), type = "pop", mc = "all")

  expect_s3_class(pop_df, "data.frame")
  expect_setequal(unique(pop_df$.mc), c(0, 1))
})

test_that("summary_dataframe can return raw wide summary data", {
  pop_df <- summary_dataframe(summary_dataframe_example_dir(), type = "pop", summary_format = "wide")
  class_df <- summary_dataframe(summary_dataframe_example_dir(), type = "class", summary_format = "wide")

  expect_s3_class(pop_df, "data.frame")
  expect_s3_class(class_df, "data.frame")
  expect_true("N_Initial" %in% names(pop_df))
  expect_true("N_Initial_Age" %in% names(class_df))
  expect_false("Metric" %in% names(pop_df))
  expect_false("Metric" %in% names(class_df))
  expect_true(any(grepl("\\|", pop_df$N_Initial, fixed = FALSE)))
  expect_true(any(grepl("\\|", class_df$N_Initial_Age, fixed = FALSE)))
})

test_that("summary_dataframe returns tidy disease data by default", {
  disease_df <- summary_dataframe(
    summary_dataframe_example_dir(),
    type = "disease",
    state_names = c("Susceptible", "Infected", "Recovered")
  )

  expect_s3_class(disease_df, "data.frame")
  expect_true(all(c("Year", "State", "Count", ".run", ".batch", ".mc", ".species") %in% names(disease_df)))
  expect_setequal(unique(as.character(disease_df$State)), c("Susceptible", "Infected", "Recovered"))
  expect_true(all(disease_df$.run == 0))
  expect_true(all(disease_df$.batch == 0))
  expect_true(all(disease_df$.mc == 0))
})

test_that("summary_dataframe can return wide disease data", {
  disease_df <- summary_dataframe(
    summary_dataframe_example_dir(),
    type = "disease",
    disease_format = "wide"
  )

  expect_s3_class(disease_df, "data.frame")
  expect_true(all(c("1", "2", "3") %in% names(disease_df)))
  expect_false("State" %in% names(disease_df))
})

test_that("summary_dataframe returns ind data with year and patch filters", {
  ind_df <- summary_dataframe(
    summary_dataframe_example_dir(),
    type = "ind",
    years = 9,
    patches = c(1, 3)
  )

  expect_s3_class(ind_df, "data.frame")
  expect_true(all(c("PatchID", "Year", ".run", ".batch", ".mc", ".species") %in% names(ind_df)))
  expect_true(all(ind_df$Year == 9))
  expect_true(all(ind_df$PatchID %in% c(1, 3)))
})

test_that("summary_dataframe can include multiple MCs for ind data", {
  ind_df <- summary_dataframe(
    summary_dataframe_example_dir(),
    type = "ind",
    mc = "all"
  )

  expect_s3_class(ind_df, "data.frame")
  expect_setequal(unique(ind_df$.mc), c(0, 1))
})
