genetics_example_dir <- function() {
  normalizePath(
    file.path("..", "..", "inst", "extdata", "Adaptive_Run_08"),
    winslash = "/",
    mustWork = TRUE
  )
}

test_that("allele_frequencies_ind plots allele frequencies by patch and locus", {
  p <- allele_frequencies_ind(genetics_example_dir(), year = 9, loci = c("L0", "L1"))

  expect_s3_class(p, "ggplot")
  expect_true(all(c("Group", "Locus", "Allele", "frequency") %in% names(p$data)))
  expect_setequal(unique(p$data$Locus), c("L0", "L1"))
  expect_true(all(p$data$frequency >= 0, na.rm = TRUE))
  expect_true(all(p$data$frequency <= 1, na.rm = TRUE))
})

test_that("allele_frequencies_ind can plot mean frequency across patches", {
  p <- allele_frequencies_ind(
    genetics_example_dir(),
    year = 9,
    loci = c("L0", "L1"),
    mean_across_patches = TRUE
  )

  expect_s3_class(p, "ggplot")
  expect_true(all(c("Locus", "Allele", "frequency", "sd_frequency", "n_groups") %in% names(p$data)))
  expect_false("Group" %in% names(p$data))
  expect_setequal(unique(p$data$Locus), c("L0", "L1"))
  expect_true(all(p$data$frequency >= 0, na.rm = TRUE))
  expect_true(all(p$data$frequency <= 1, na.rm = TRUE))
})

test_that("heterozygosity_ind plots observed and expected heterozygosity", {
  p <- heterozygosity_ind(genetics_example_dir(), year = 9, loci = c("L0", "L1"))

  expect_s3_class(p, "ggplot")
  expect_true(all(c("Group", "Locus", "Metric", "Value") %in% names(p$data)))
  expect_setequal(unique(p$data$Metric), c("Ho", "He"))
  expect_true(all(p$data$Value >= 0, na.rm = TRUE))
  expect_true(all(p$data$Value <= 1, na.rm = TRUE))
})

test_that("heterozygosity_ind can plot mean heterozygosity across patches", {
  p <- heterozygosity_ind(
    genetics_example_dir(),
    year = 9,
    loci = c("L0", "L1"),
    mean_across_patches = TRUE
  )

  expect_s3_class(p, "ggplot")
  expect_true(all(c("Locus", "Metric", "Value", "sd_value", "n_groups") %in% names(p$data)))
  expect_false("Group" %in% names(p$data))
  expect_setequal(unique(p$data$Metric), c("Ho", "He"))
  expect_true(all(p$data$Value >= 0, na.rm = TRUE))
  expect_true(all(p$data$Value <= 1, na.rm = TRUE))
})

test_that("pairwise_fst_ind plots pairwise FST across patches", {
  p <- pairwise_fst_ind(genetics_example_dir(), year = 9, loci = c("L0", "L1"))

  expect_s3_class(p, "ggplot")
  expect_true(all(c("Group1", "Group2", "FST") %in% names(p$data)))
  expect_gt(nrow(p$data), 0)
  expect_true(all(p$data$FST >= -1e-8, na.rm = TRUE))
  expect_true(all(p$data$FST <= 1 + 1e-8, na.rm = TRUE))
  expect_equal(levels(p$data$Group1), as.character(sort(as.numeric(levels(p$data$Group1)))))
  expect_equal(levels(p$data$Group2), as.character(sort(as.numeric(levels(p$data$Group2)))))
})

test_that("genetic functions accept direct ind file paths", {
  ind_file <- file.path(genetics_example_dir(), "run0batch0mc0species0", "ind9.csv")

  p <- allele_frequencies_ind(ind_file, loci = 0)

  expect_s3_class(p, "ggplot")
  expect_setequal(unique(p$data$Locus), "L0")
})
