# Regression tests: a delimiter character that is part of a FILENAME must not
# be treated as a delimiter.
#
# Found on a Windows CI runner. A user profile folder whose name exceeds 8
# characters, or contains a space or a dot, gets an 8.3 alias containing `~`
# ("runneradmin" -> "RUNNER~1"), so every absolute path beneath it -- anything
# from tempdir() or USERPROFILE included -- carries a `~`. Because `~` is also
# CDMetaPOP's per-sex delimiter, the graph-writer split such paths into
# fragments that do not exist and failed its own pre-flight check on a
# perfectly valid path.
#
# `~` and `;` are both legal in filenames on Windows, macOS and Linux, so the
# bug is reproduced here by putting them in the file NAMES. That is portable,
# unlike creating a real 8.3 alias; the Windows-specific short-name path is
# covered by the last test, which skips elsewhere.

delim_fixture <- function() {
	dir <- withr_tempdir()
	src <- file.path(dir, "src")
	dir.create(src, recursive = TRUE)

	# Filenames deliberately containing the per-sex and multi-file delimiters.
	cost <- file.path(src, "cost~A.csv")
	utils::write.table(matrix(0.9, 7, 7), cost, sep = ",",
		row.names = FALSE, col.names = FALSE)
	genes <- file.path(src, "gene;file.csv")
	writeLines(c("Allele List,Frequency", "0,1"), genes)

	list(dir = dir, src = src, cost = cost, genes = genes, m = matrix(0.1, 7, 7))
}

# A temp directory removed when the calling test finishes. Written out rather
# than injecting on.exit() into another frame, which is fragile.
withr_tempdir <- function() {
	d <- file.path(tempdir(), paste0("delim-", as.integer(runif(1, 1, 1e6))))
	dir.create(d, recursive = TRUE, showWarnings = FALSE)
	d
}

build_run <- function(fx, genes = NULL) {
	pv <- PatchVars(
		patch_id = 1:7,
		class_vars = ClassVars(),
		genes_initialize = if (is.null(genes)) "random" else genes
	)
	popv <- PopVars(
		xyfilename = pv,
		mate_cdmat = fx$m, migrateout_cdmat = fx$m, migrateback_cdmat = fx$m,
		stray_cdmat = fx$cost, disperseLocal_cdmat = fx$cost,
		correlation_matrix = "N", subpopmort_file = "N", betaFile_selection = "N"
	)
	RunVars(n_runs = 1, Popvars = popv)
}

test_that("a cost-matrix path whose filename contains '~' is not split", {
	fx <- delim_fixture()
	on.exit(unlink(fx$dir, recursive = TRUE), add = TRUE)

	res <- .write_cdmetapop_inputfiles(build_run(fx), base_dir = fx$dir)
	written <- list.files(res$run_dir, recursive = TRUE)

	# One file copied, under its real basename -- not two fragments. (cdmats/
	# also holds the serialized raw matrix from mate_cdmat, so only the copied
	# file is counted here.)
	expect_true("cdmats/cost~A.csv" %in% written)
	expect_length(written[grepl("cost", written, fixed = TRUE)], 1)

	# And the reference in the written PopVars points at it.
	popv_out <- utils::read.csv(
		file.path(res$run_dir, written[startsWith(written, "popvars/")]),
		colClasses = "character", check.names = FALSE
	)
	expect_true(all(popv_out[["stray_cdmat"]] == "cdmats/cost~A.csv"))
})

test_that("a genes_initialize path whose filename contains ';' is not split", {
	fx <- delim_fixture()
	on.exit(unlink(fx$dir, recursive = TRUE), add = TRUE)

	res <- .write_cdmetapop_inputfiles(
		build_run(fx, genes = c(fx$genes, rep("random", 6))), base_dir = fx$dir)
	written <- list.files(res$run_dir, recursive = TRUE)

	expect_true("genes/gene;file.csv" %in% written)
	expect_length(written[startsWith(written, "genes/")], 1)
})

test_that("genuine per-sex and multi-file delimiters still split", {
	# The fix must not disable the delimiters themselves. These paths do not
	# exist as written, so they are still split -- and the writer then reports
	# the two halves as missing, which is the correct behaviour.
	fx <- delim_fixture()
	on.exit(unlink(fx$dir, recursive = TRUE), add = TRUE)

	expect_length(.wif_split_pipe_tilde("cdmats/F.csv~cdmats/M.csv"), 2)
	expect_length(.wif_split_pipe_tilde("a.csv~b.csv|c.csv~d.csv"), 4)
	expect_length(.wif_split_gene_paths("genes/A.csv;genes/B.csv"), 2)
	expect_length(.wif_split_gene_paths("random"), 0)

	# An existing file is one path, however many delimiters are in its name.
	expect_identical(length(.wif_split_pipe_tilde(fx$cost)), 1L)
	expect_identical(length(.wif_split_gene_paths(fx$genes)), 1L)
})

test_that("a Windows 8.3 short path is resolved rather than split", {
	# The original failure: C:/Users/RUNNER~1/.../costA.csv torn in two.
	skip_on_os(c("mac", "linux", "solaris"))

	# A directory name long enough to be given an 8.3 alias.
	dir <- file.path(tempdir(), paste0("averylongdirectoryname-", as.integer(runif(1, 1, 1e6))))
	src <- file.path(dir, "src")
	dir.create(src, recursive = TRUE, showWarnings = FALSE)
	on.exit(unlink(dir, recursive = TRUE), add = TRUE)

	cost <- file.path(src, "costA.csv")
	utils::write.table(matrix(0.9, 7, 7), cost, sep = ",",
		row.names = FALSE, col.names = FALSE)

	short <- utils::shortPathName(cost)
	skip_if_not(grepl("~", short, fixed = TRUE), "no 8.3 alias available here")
	expect_true(file.exists(short))

	# The short form must resolve to a single path, not fragments.
	expect_length(.wif_split_pipe_tilde(short), 1)

	fx <- list(dir = dir, cost = short, m = matrix(0.1, 7, 7))
	res <- .write_cdmetapop_inputfiles(build_run(fx), base_dir = dir)
	written <- list.files(res$run_dir, recursive = TRUE)
	expect_true("cdmats/costA.csv" %in% written)
	expect_length(written[grepl("costA", written, fixed = TRUE)], 1)
})
