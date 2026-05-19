patch_map_example_dir <- function() {
  normalizePath(
    file.path("..", "..", "inst", "extdata", "Adaptive_Run_08"),
    winslash = "/",
    mustWork = TRUE
  )
}

test_that("summary_patch_map creates patch abundance maps across years", {
  p <- summary_patch_map(patch_map_example_dir(), years = c(0, 5, 9), crs = 5070)

  expect_s3_class(p, "ggplot")
  expect_true(all(c("Year", "PatchID", "XCOORD", "YCOORD", "count") %in% names(p$data)))
  expect_false(any(c("movers", "prop_moved", "mean_cdist") %in% names(p$data)))
  expect_setequal(as.character(unique(p$data$Year)), c("0", "5", "9"))
  expect_equal(attr(p$data, "crs"), "EPSG:5070")
  expect_true(all(p$data$count > 0))
})

test_that("summary_patch_map can filter to disease states", {
  p <- summary_patch_map(
    patch_map_example_dir(),
    years = 9,
    states = 1,
    crs = 5070
  )

  expect_s3_class(p, "ggplot")
  expect_true(all(p$data$State == "All selected states"))
  expect_true(all(p$data$count > 0))
})

test_that("summary_patch_map can facet by disease state", {
  p <- summary_patch_map(
    patch_map_example_dir(),
    years = c(0, 9),
    states = c(0, 1),
    facet_by_state = TRUE,
    crs = 5070
  )

  expect_s3_class(p, "ggplot")
  expect_true(all(p$data$State %in% c("State 0", "State 1")))
})
