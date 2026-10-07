# Tests for PatchVars' eight disease columns, and for the 50-or-58 column
# shapes CDMetaPOP requires: exactly 50 when PopVars' `implement_disease` is
# "N" and exactly 58 when it is not.

warnings_of <- function(expr) {
	w <- character(0)
	withCallingHandlers(expr, warning = function(cond) {
		w <<- c(w, conditionMessage(cond))
		invokeRestart("muffleWarning")
	})
	w
}

# All eight disease columns, for the complete-set cases.
full_disease <- function(...) {
	utils::modifyList(
		list(
			disease_file = "otherfiles/disease/DiseaseVars_SIR.csv", env_res = 0,
			resistant_CC = 0, resistant_Cc = 0.2, resistant_cc = 0.2,
			tolerant_DD = 0, tolerant_Dd = 0.1, tolerant_dd = 0.1
		),
		list(...)
	)
}
pv_disease <- function(n = 2, ...) {
	do.call(PatchVars, c(list(patch_id = seq_len(n)), full_disease(...)))
}

test_that("a PatchVars object with no disease columns is unchanged", {
	pv <- PatchVars()
	df <- pv$as_data_frame()

	expect_equal(ncol(df), 50)
	expect_identical(colnames(df), .pv_headers)
	expect_false(pv$has_disease())
	expect_length(warnings_of(PatchVars()), 0)
})

test_that("setting all eight disease columns gives the 58-column shape", {
	pv <- pv_disease(2)
	df <- pv$as_data_frame()

	expect_equal(ncol(df), 58)
	expect_identical(colnames(df), c(.pv_headers, .pv_disease_headers))
	expect_true(pv$has_disease())
	expect_length(warnings_of(pv_disease(2)), 0)
	expect_identical(pv$env_res, c("0", "0"))
	expect_identical(pv$resistant_Cc, c("0.2", "0.2"))
})

test_that("a partially set disease block warns but still applies", {
	w <- warnings_of(
		pv <- PatchVars(patch_id = 1:2,
			disease_file = "otherfiles/disease/DiseaseVars_SIR.csv")
	)

	expect_length(w, 1)
	expect_match(w, "env_res")
	expect_match(w, "tolerant_dd")
	expect_identical(pv$disease_file[[1]][[1]], "otherfiles/disease/DiseaseVars_SIR.csv")
	expect_true(all(is.na(pv$as_data_frame()[["Env Res"]])))

	# The reminder follows whichever column was touched last, until complete.
	expect_length(warnings_of(pv$env_res <- 1), 1)
})

test_that("disease_file is an object-or-path column", {
	dv <- DiseaseVars()

	pv <- pv_disease(3, disease_file = dv)
	expect_s3_class(pv$as_data_frame()[["disease_file"]][[1]][[1]], "DiseaseVars")
	# Several patches share one object by reference, the usual case for a
	# spatially uniform disease model.
	expect_identical(pv$as_data_frame()[["disease_file"]][[2]][[1]], dv)

	# `|` separates DiseaseVars files that take effect at successive cdclimate
	# time steps, as it does for class_vars.
	pv2 <- pv_disease(2, disease_file = "a.csv|b.csv")
	expect_length(pv2$as_data_frame()[["disease_file"]][[1]], 2)
})

test_that("disease_file resolves a .GlobalEnv object name unless told not to", {
	assign("test_dv_global", DiseaseVars(), envir = globalenv())
	on.exit(rm("test_dv_global", envir = globalenv()), add = TRUE)

	pv <- pv_disease(2, disease_file = "test_dv_global")
	expect_s3_class(pv$as_data_frame()[["disease_file"]][[1]][[1]], "DiseaseVars")

	pv2 <- do.call(PatchVars, c(list(patch_id = 1:2, resolve_disease_file = FALSE),
		full_disease(disease_file = "test_dv_global")))
	expect_identical(pv2$as_data_frame()[["disease_file"]][[1]][[1]], "test_dv_global")
})

test_that("env_res must be a non-negative number", {
	# CDMetaPOP calls float() on this cell whenever the disease module is on,
	# even under Direct transmission where the value is unused.
	expect_error(pv_disease(2, env_res = "x"), "not a valid")
	expect_error(pv_disease(2, env_res = -1), "outside the allowed range")
	expect_identical(pv_disease(2, env_res = "0|1|2")$env_res[1], "0|1|2")
})

test_that("defense rates are ;-separated numbers, unbounded", {
	# One rate per transition named in the referenced DiseaseVars file.
	expect_identical(pv_disease(2, resistant_Cc = "0.2;0.9")$resistant_Cc[1], "0.2;0.9")
	expect_error(pv_disease(2, resistant_Cc = "0.2;high"), "one or more numbers")
	# A rate above 1 is legitimate: these override transition-matrix entries,
	# which under Indirect transmission are scaled by pathogen concentration
	# rather than used directly as probabilities.
	expect_identical(pv_disease(2, tolerant_Dd = 10)$tolerant_Dd[1], "10")
})

test_that("disease columns take one value per patch", {
	expect_identical(pv_disease(3, env_res = c(0, 1, 2))$env_res, c("0", "1", "2"))
	expect_error(pv_disease(3, env_res = c(0, 1)), "must have length 1 or 3")
})

test_that("add_row() carries the disease columns", {
	pv <- pv_disease(2)
	pv$add_row()

	expect_equal(nrow(pv$as_data_frame()), 3)
	expect_identical(pv$env_res[3], "0")
	expect_length(pv$as_data_frame()[["disease_file"]][[3]], 1)
})

test_that("both column shapes survive a write/read round trip", {
	dir <- file.path(tempdir(), "pv-disease-roundtrip")
	dir.create(dir, showWarnings = FALSE)
	on.exit(unlink(dir, recursive = TRUE), add = TRUE)

	f50 <- file.path(dir, "pv50.csv")
	write_cdmetapop(PatchVars(), f50)
	pv50 <- read_cdmetapop(f50, type = "PatchVars")
	expect_equal(ncol(pv50$as_data_frame()), 50)
	expect_false(pv50$has_disease())
	expect_identical(PatchVars()$as_data_frame(), pv50$as_data_frame())

	f58 <- file.path(dir, "pv58.csv")
	pvd <- pv_disease(3)
	write_cdmetapop(pvd, f58)
	expect_identical(colnames(utils::read.csv(f58, check.names = FALSE))[51:58],
		.pv_disease_headers)
	pv58 <- read_cdmetapop(f58, type = "PatchVars")
	expect_equal(ncol(pv58$as_data_frame()), 58)
	expect_true(pv58$has_disease())
	expect_identical(pvd$as_data_frame(), pv58$as_data_frame())
})

test_that("a column count between the two valid shapes is rejected", {
	dir <- file.path(tempdir(), "pv-disease-badcols")
	dir.create(dir, showWarnings = FALSE)
	on.exit(unlink(dir, recursive = TRUE), add = TRUE)

	f <- file.path(dir, "pv58.csv")
	write_cdmetapop(pv_disease(2), f)
	trimmed <- utils::read.csv(f, colClasses = "character", check.names = FALSE)[, 1:55]
	bad <- file.path(dir, "pv55.csv")
	utils::write.csv(trimmed, bad, row.names = FALSE, quote = FALSE)

	expect_error(read_cdmetapop(bad, type = "PatchVars"), "or 58 with the eight disease columns")
})
