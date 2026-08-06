genetics_example_dir <- function() {
  system.file("extdata", "Example_dat", package = "cdmetapopR")
}

genetics_sample_example_dir <- function() {
  source_dir <- genetics_example_dir()
  temp_dir <- file.path(tempdir(), "cdmetapopR_genetics_sample_example")
  if (dir.exists(temp_dir)) {
    unlink(temp_dir, recursive = TRUE)
  }
  dir.create(temp_dir, recursive = TRUE)

  run_dirs <- list.dirs(source_dir, full.names = FALSE, recursive = FALSE)
  for (run_dir in run_dirs) {
    dir.create(file.path(temp_dir, run_dir), recursive = TRUE)
    file.copy(
      from = file.path(source_dir, run_dir, "ind9.csv"),
      to = file.path(temp_dir, run_dir, "indSample9.csv")
    )
  }

  temp_dir
}

test_that("allele_frequencies_ind plots allele frequencies by patch and locus", {
  p <- allele_frequencies_ind(genetics_example_dir(), year = 9, loci = c("L0", "L1"))

  expect_s3_class(p, "ggplot")
  expect_true(all(c("Group", "Locus", "Allele", "frequency") %in% names(p$data)))
  expect_setequal(unique(p$data$Locus), c("L0", "L1"))
  expect_true(all(p$data$frequency >= 0, na.rm = TRUE))
  expect_true(all(p$data$frequency <= 1, na.rm = TRUE))
  expect_true(any(vapply(p$layers, function(layer) inherits(layer$geom, "GeomBoxplot"), logical(1))))
  expect_true(any(vapply(p$layers, function(layer) inherits(layer$geom, "GeomPoint"), logical(1))))
  expect_false(any(vapply(p$layers, function(layer) inherits(layer$geom, "GeomCol"), logical(1))))
})

test_that("allele_frequencies_ind can hide jittered points", {
  p <- allele_frequencies_ind(
    genetics_example_dir(),
    year = 9,
    loci = c("L0", "L1"),
    jitter = FALSE
  )

  expect_s3_class(p, "ggplot")
  expect_true(all(c("Group", "Locus", "Allele", "frequency") %in% names(p$data)))
  expect_setequal(unique(p$data$Locus), c("L0", "L1"))
  expect_true(all(p$data$frequency >= 0, na.rm = TRUE))
  expect_true(all(p$data$frequency <= 1, na.rm = TRUE))
  expect_true(any(vapply(p$layers, function(layer) inherits(layer$geom, "GeomBoxplot"), logical(1))))
  expect_false(any(vapply(p$layers, function(layer) inherits(layer$geom, "GeomPoint"), logical(1))))
  expect_false(any(vapply(p$layers, function(layer) inherits(layer$geom, "GeomErrorbar"), logical(1))))
})

test_that("heterozygosity_ind plots observed and expected heterozygosity", {
  p <- heterozygosity_ind(genetics_example_dir(), year = 9, loci = c("L0", "L1"))

  expect_s3_class(p, "ggplot")
  expect_true(all(c("Group", "Locus", "Metric", "Value") %in% names(p$data)))
  expect_setequal(unique(p$data$Metric), c("Ho", "He"))
  expect_true(all(p$data$Value >= 0, na.rm = TRUE))
  expect_true(all(p$data$Value <= 1, na.rm = TRUE))
  expect_true(any(vapply(p$layers, function(layer) inherits(layer$geom, "GeomBoxplot"), logical(1))))
  expect_true(any(vapply(p$layers, function(layer) inherits(layer$geom, "GeomPoint"), logical(1))))
  expect_false(any(vapply(p$layers, function(layer) inherits(layer$geom, "GeomCol"), logical(1))))
})

test_that("heterozygosity_ind can hide jittered points", {
  p <- heterozygosity_ind(
    genetics_example_dir(),
    year = 9,
    loci = c("L0", "L1"),
    jitter = FALSE
  )

  expect_s3_class(p, "ggplot")
  expect_true(all(c("Group", "Locus", "Metric", "Value") %in% names(p$data)))
  expect_setequal(unique(p$data$Metric), c("Ho", "He"))
  expect_true(all(p$data$Value >= 0, na.rm = TRUE))
  expect_true(all(p$data$Value <= 1, na.rm = TRUE))
  expect_true(any(vapply(p$layers, function(layer) inherits(layer$geom, "GeomBoxplot"), logical(1))))
  expect_false(any(vapply(p$layers, function(layer) inherits(layer$geom, "GeomPoint"), logical(1))))
  expect_false(any(vapply(p$layers, function(layer) inherits(layer$geom, "GeomErrorbar"), logical(1))))
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

test_that("genetic functions can read ind sample files when requested", {
  sample_dir <- genetics_sample_example_dir()

  p_freq <- allele_frequencies_ind(sample_dir, year = 9, file_type = "ind_Sample", loci = 0)
  p_het <- heterozygosity_ind(sample_dir, year = 9, file_type = "ind_Sample", loci = 0)
  p_fst <- pairwise_fst_ind(sample_dir, year = 9, file_type = "ind_Sample", loci = 0)

  expect_s3_class(p_freq, "ggplot")
  expect_s3_class(p_het, "ggplot")
  expect_s3_class(p_fst, "ggplot")
  expect_setequal(unique(p_freq$data$Locus), "L0")
})

test_that("genetic patch labels are ordered numerically", {
  ind_data <- data.frame(
    PatchID = rep(c(1, 2, 10, 100), each = 2),
    Year = 9,
    L0A0 = c(2, 1, 2, 1, 0, 1, 0, 1),
    L0A1 = c(0, 1, 0, 1, 2, 1, 2, 1)
  )

  p_freq <- allele_frequencies_ind(ind_data, year = 9, loci = 0)
  p_het <- heterozygosity_ind(ind_data, year = 9, loci = 0)
  p_fst <- pairwise_fst_ind(ind_data, year = 9, loci = 0)

  expected_levels <- c("1", "2", "10", "100")
  expect_equal(levels(p_freq$data$Group), expected_levels)
  expect_equal(levels(p_het$data$Group), expected_levels)
  expect_equal(levels(p_fst$data$Group1), expected_levels)
  expect_equal(levels(p_fst$data$Group2), expected_levels)
})

test_that("genetic functions can filter to selected patches", {
  ind_data <- data.frame(
    PatchID = rep(c(1, 2, 10, 100), each = 2),
    Year = 9,
    L0A0 = c(2, 1, 2, 1, 0, 1, 0, 1),
    L0A1 = c(0, 1, 0, 1, 2, 1, 2, 1)
  )

  p_freq <- allele_frequencies_ind(ind_data, year = 9, loci = 0, patches = c(1, 10))
  p_het <- heterozygosity_ind(ind_data, year = 9, loci = 0, patches = c(1, 10))
  p_fst <- pairwise_fst_ind(ind_data, year = 9, loci = 0, patches = c(1, 10))

  expect_equal(levels(p_freq$data$Group), c("1", "10"))
  expect_equal(levels(p_het$data$Group), c("1", "10"))
  expect_equal(levels(p_fst$data$Group1), c("1", "10"))
  expect_equal(levels(p_fst$data$Group2), c("1", "10"))
})

test_that("genetic plots without jitter still use boxplots for one patch", {
  ind_data <- data.frame(
    PatchID = rep(1, 4),
    Year = 9,
    L0A0 = c(2, 1, 0, 1),
    L0A1 = c(0, 1, 2, 1)
  )

  p_freq <- allele_frequencies_ind(ind_data, year = 9, loci = 0, patches = 1, jitter = FALSE)
  p_het <- heterozygosity_ind(ind_data, year = 9, loci = 0, patches = 1, jitter = FALSE)

  expect_true(any(vapply(p_freq$layers, function(layer) inherits(layer$geom, "GeomBoxplot"), logical(1))))
  expect_false(any(vapply(p_freq$layers, function(layer) inherits(layer$geom, "GeomErrorbar"), logical(1))))
  expect_false(any(vapply(p_freq$layers, function(layer) inherits(layer$geom, "GeomPoint"), logical(1))))
  expect_true(any(vapply(p_het$layers, function(layer) inherits(layer$geom, "GeomBoxplot"), logical(1))))
  expect_false(any(vapply(p_het$layers, function(layer) inherits(layer$geom, "GeomErrorbar"), logical(1))))
  expect_false(any(vapply(p_het$layers, function(layer) inherits(layer$geom, "GeomPoint"), logical(1))))
})
