patch_map_example_dir <- function() {
  normalizePath(
    file.path("..", "..", "inst", "extdata", "Adaptive_Run_08"),
    winslash = "/",
    mustWork = TRUE
  )
}

patch_map_sample_example_dir <- function() {
  source_dir <- patch_map_example_dir()
  temp_dir <- file.path(tempdir(), "cdmetapopR_patch_map_sample_example")
  if (dir.exists(temp_dir)) {
    unlink(temp_dir, recursive = TRUE)
  }
  dir.create(temp_dir, recursive = TRUE)

  run_dirs <- list.dirs(source_dir, full.names = FALSE, recursive = FALSE)
  for (run_dir in run_dirs) {
    dir.create(file.path(temp_dir, run_dir), recursive = TRUE)
    file.copy(
      from = file.path(source_dir, run_dir, "ind9.csv"),
      to = file.path(temp_dir, run_dir, "ind9_Sample.csv")
    )
  }

  temp_dir
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

test_that("summary_patch_map can read ind sample files when requested", {
  sample_dir <- patch_map_sample_example_dir()

  p <- summary_patch_map(sample_dir, years = 9, file_type = "ind_Sample", crs = 5070)

  expect_s3_class(p, "ggplot")
  expect_setequal(as.character(unique(p$data$Year)), "9")
  expect_true(all(p$data$count > 0))
})

test_that("summary_patch_map can log-scale abundance point sizes", {
  p <- summary_patch_map(patch_map_example_dir(), years = 9, log_scale = TRUE)

  expect_s3_class(p, "ggplot")
  expect_true("size_value" %in% names(p$data))
  expect_equal(p$data$size_value, log1p(p$data$count))
})

test_that("summary_patch_map orders patch labels numerically", {
  ind_data <- data.frame(
    PatchID = c(1, 2, 10, 100),
    XCOORD = c(0, 1, 2, 3),
    YCOORD = c(0, 1, 2, 3),
    Year = 9,
    state = 0
  )

  p <- summary_patch_map(ind_data, years = 9)

  expect_equal(levels(p$data$PatchID), c("1", "2", "10", "100"))
})

test_that("summary_patch_map can filter to selected patches", {
  ind_data <- data.frame(
    PatchID = c(1, 2, 10, 100),
    XCOORD = c(0, 1, 2, 3),
    YCOORD = c(0, 1, 2, 3),
    Year = 9,
    state = 0
  )

  p <- summary_patch_map(ind_data, years = 9, patches = c(1, 10))

  expect_equal(levels(p$data$PatchID), c("1", "10"))
  expect_setequal(as.character(p$data$PatchID), c("1", "10"))
})

test_that("summary_patch_map can map allele frequencies", {
  p <- summary_patch_map(
    patch_map_example_dir(),
    type = "allele_frequency",
    years = 9,
    locus = "L0",
    allele = "A1",
    crs = 5070
  )

  expect_s3_class(p, "ggplot")
  expect_true(all(c("Year", "PatchID", "XCOORD", "YCOORD", "Locus", "Allele", "value") %in% names(p$data)))
  expect_setequal(unique(p$data$Locus), "L0")
  expect_setequal(unique(p$data$Allele), "A1")
  expect_true(all(p$data$value >= 0, na.rm = TRUE))
  expect_true(all(p$data$value <= 1, na.rm = TRUE))
})

test_that("summary_patch_map can map heterozygosity", {
  p <- summary_patch_map(
    patch_map_example_dir(),
    type = "heterozygosity",
    years = c(0, 9),
    locus = 0,
    metric = "He",
    labels = TRUE,
    crs = 5070
  )

  expect_s3_class(p, "ggplot")
  expect_true(all(c("Year", "PatchID", "XCOORD", "YCOORD", "Locus", "Metric", "value") %in% names(p$data)))
  expect_setequal(unique(p$data$Locus), "L0")
  expect_setequal(unique(p$data$Metric), "He")
  expect_true(any(vapply(p$layers, function(layer) inherits(layer$geom, "GeomText"), logical(1))))
  expect_true(all(p$data$value >= 0, na.rm = TRUE))
  expect_true(all(p$data$value <= 1, na.rm = TRUE))
})
