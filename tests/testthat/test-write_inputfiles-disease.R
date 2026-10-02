# Tests for the graph-writer's disease handling: DiseaseVars nodes, the
# transition-matrix leaf, and the cross-file rules checked before anything is
# written. All output goes under tempdir().

# A scratch directory plus the real source files the writer's pre-flight check
# needs to find. Returns the paths, and registers cleanup on the calling test.
disease_fixture <- function(env = parent.frame()) {
	dir <- file.path(tempdir(), paste0("wif-disease-", as.integer(runif(1, 1, 1e6))))
	src <- file.path(dir, "src")
	dir.create(src, recursive = TRUE)
	# Clean up when the calling test exits. The path is substituted in as a
	# literal rather than left as a variable name, which would be looked up in
	# the test's own frame (where `dir` is base R's dir() function).
	do.call(on.exit, list(bquote(unlink(.(dir), recursive = TRUE)), add = TRUE),
		envir = env)

	cost <- file.path(src, "costA.csv")
	utils::write.table(matrix(0.9, 7, 7), cost, sep = ",", row.names = FALSE, col.names = FALSE)
	genes <- file.path(src, "genefile.csv")
	writeLines(c("Allele List,Frequency", "0,1"), genes)
	tm <- file.path(src, "TM.csv")
	utils::write.table(matrix(0, 4, 4), tm, sep = ",", row.names = FALSE, col.names = FALSE)

	list(dir = dir, src = src, cost = cost, genes = genes, tm = tm,
		m = matrix(0.1, 7, 7))
}

# An Indirect 3-state model (so the transition matrix is 4x4) whose resistance
# locus names two transitions.
fx_diseasevars <- function(fx, ...) {
	# modifyList() so a caller can override any of these defaults by name.
	do.call(DiseaseVars, utils::modifyList(
		list(transmission_mode = "Indirect", transition_rates = fx$tm,
			disease_resistant = "0_1;3_1"),
		list(...)
	))
}

# The eight PatchVars disease columns, sized to the model above.
fx_disease_cols <- function(dv, ...) {
	utils::modifyList(
		list(disease_file = dv, env_res = 0,
			resistant_CC = "0;0", resistant_Cc = "0.2;0.9", resistant_cc = "0.2;0.9",
			tolerant_DD = 0, tolerant_Dd = 0.1, tolerant_dd = 0.1),
		list(...)
	)
}

fx_patchvars <- function(fx, disease = NULL) {
	suppressWarnings(do.call(PatchVars, c(
		list(patch_id = 1:7, class_vars = ClassVars(),
			genes_initialize = c(fx$genes, rep("random", 6))),
		disease
	)))
}

fx_runvars <- function(fx, patchvars, implement_disease = "N") {
	popv <- PopVars(xyfilename = patchvars, implement_disease = implement_disease,
		mate_cdmat = fx$m, migrateout_cdmat = fx$m, migrateback_cdmat = fx$m,
		stray_cdmat = fx$cost, disperseLocal_cdmat = fx$cost,
		correlation_matrix = "N", subpopmort_file = "N", betaFile_selection = "N")
	RunVars(n_runs = 1, Popvars = popv)
}

read_written <- function(run_dir, relpath) {
	utils::read.csv(file.path(run_dir, relpath), colClasses = "character",
		check.names = FALSE)
}

test_that("a disease run writes DiseaseVars and its transition matrix", {
	fx <- disease_fixture()
	dv <- fx_diseasevars(fx)
	pv <- fx_patchvars(fx, fx_disease_cols(dv))
	res <- .write_cdmetapop_inputfiles(fx_runvars(fx, pv, "Back"), base_dir = fx$dir)
	written <- list.files(res$run_dir, recursive = TRUE)

	expect_true(file.exists(res$runvars_csv))
	# Built inline rather than assigned to a variable, so the type+index
	# fallback name applies.
	expect_true(any(grepl("^otherfiles/disease/diseasevars[0-9]+\\.csv$", written)))
	expect_true("otherfiles/disease/TM.csv" %in% written)
	expect_true(all(c("patchvars", "classvars", "popvars") %in%
		basename(dirname(written[grepl("/", written)]))))
})

test_that("references are rewritten to canonical relative paths", {
	fx <- disease_fixture()
	dv <- fx_diseasevars(fx)
	pv <- fx_patchvars(fx, fx_disease_cols(dv))
	res <- .write_cdmetapop_inputfiles(fx_runvars(fx, pv, "Back"), base_dir = fx$dir)

	pv_rel <- list.files(res$run_dir, pattern = "\\.csv$", recursive = TRUE)
	pv_file <- pv_rel[startsWith(pv_rel, "patchvars/")]
	dv_file <- pv_rel[startsWith(pv_rel, "otherfiles/disease/diseasevars")]

	pv_out <- read_written(res$run_dir, pv_file)
	expect_equal(ncol(pv_out), 58)
	expect_true(all(pv_out[["disease_file"]] == dv_file))
	expect_true(all(pv_out[["Resistant_Cc"]] == "0.2;0.9"))

	dv_out <- read_written(res$run_dir, dv_file)
	expect_identical(colnames(dv_out), .dv_headers)
	expect_equal(nrow(dv_out), 1)
	expect_identical(dv_out[["Transition Rates"]], "otherfiles/disease/TM.csv")
})

test_that("a raw transition matrix is serialized NxN", {
	fx <- disease_fixture()
	tm <- matrix(c(0, 0, 0, 0, 0.5, 0, 0, 0.9, 0, 0.2, 0, 0, 0, 0.1, 0, 0),
		nrow = 4, byrow = TRUE)
	dv <- fx_diseasevars(fx, transition_rates = tm)
	pv <- fx_patchvars(fx, fx_disease_cols(dv))
	res <- .write_cdmetapop_inputfiles(fx_runvars(fx, pv, "Back"), base_dir = fx$dir)

	written <- list.files(res$run_dir, recursive = TRUE)
	mat_file <- written[grepl("^otherfiles/disease/matrix[0-9]+\\.csv$", written)]
	expect_length(mat_file, 1)
	expect_identical(
		readLines(file.path(res$run_dir, mat_file)),
		c("0,0,0,0", "0.5,0,0,0.9", "0,0.2,0,0", "0,0.1,0,0")
	)
})

test_that("the manifest records DiseaseVars and transition-matrix nodes", {
	fx <- disease_fixture()
	dv <- fx_diseasevars(fx)
	pv <- fx_patchvars(fx, fx_disease_cols(dv))
	res <- .write_cdmetapop_inputfiles(fx_runvars(fx, pv, "Back"), base_dir = fx$dir)
	man <- utils::read.csv(res$manifest, colClasses = "character")

	expect_true(any(man$kind == "DiseaseVars"))
	expect_identical(man$referenced_by[man$kind == "DiseaseVars"], "disease_file")
	expect_true(any(man$kind == "copyfile" & man$referenced_by == "transition_rates"))
})

test_that("distinct DiseaseVars objects get distinct files; a shared one is written once", {
	fx <- disease_fixture()
	dv_a <- fx_diseasevars(fx)
	dv_b <- fx_diseasevars(fx, start_disease = 5)
	pv <- fx_patchvars(fx, fx_disease_cols(
		list(dv_a, dv_b, dv_a, dv_a, dv_a, dv_a, dv_a)
	))
	res <- .write_cdmetapop_inputfiles(fx_runvars(fx, pv, "Back"), base_dir = fx$dir)
	written <- list.files(res$run_dir, recursive = TRUE)

	expect_length(written[grepl("^otherfiles/disease/diseasevars", written)], 2)
	# The two objects share one transition-matrix source, copied once.
	expect_length(written[written == "otherfiles/disease/TM.csv"], 1)

	pv_file <- written[startsWith(written, "patchvars/")]
	refs <- read_written(res$run_dir, pv_file)[["disease_file"]]
	expect_identical(refs[1], refs[3])
	expect_false(identical(refs[1], refs[2]))
})

test_that("a path-valued disease_file is folded into the graph", {
	fx <- disease_fixture()
	on_disk <- file.path(fx$src, "DiseaseVars_OnDisk.csv")
	write_cdmetapop(fx_diseasevars(fx), on_disk)

	pv <- fx_patchvars(fx, fx_disease_cols(on_disk))
	res <- .write_cdmetapop_inputfiles(fx_runvars(fx, pv, "Back"), base_dir = fx$dir)
	written <- list.files(res$run_dir, recursive = TRUE)

	expect_true("otherfiles/disease/DiseaseVars_OnDisk.csv" %in% written)
	# Its own transition matrix came along with it.
	expect_true("otherfiles/disease/TM.csv" %in% written)
	pv_file <- written[startsWith(written, "patchvars/")]
	expect_true(all(read_written(res$run_dir, pv_file)[["disease_file"]] ==
		"otherfiles/disease/DiseaseVars_OnDisk.csv"))
})

test_that("a non-disease run writes nothing disease-related", {
	fx <- disease_fixture()
	pv <- fx_patchvars(fx, NULL)
	res <- .write_cdmetapop_inputfiles(fx_runvars(fx, pv, "N"), base_dir = fx$dir)
	written <- list.files(res$run_dir, recursive = TRUE)

	expect_false(any(grepl("otherfiles/disease", written)))
	pv_file <- written[startsWith(written, "patchvars/")]
	expect_equal(ncol(read_written(res$run_dir, pv_file)), 50)
	expect_false(any(utils::read.csv(res$manifest, colClasses = "character")$kind == "DiseaseVars"))
})

test_that("a missing transition-matrix file is caught before any directory is made", {
	fx <- disease_fixture()
	dv <- fx_diseasevars(fx, transition_rates = file.path(fx$src, "nope.csv"))
	pv <- fx_patchvars(fx, fx_disease_cols(dv))
	rv <- fx_runvars(fx, pv, "Back")

	before <- length(list.dirs(fx$dir, recursive = FALSE))
	expect_error(.write_cdmetapop_inputfiles(rv, base_dir = fx$dir), "nope.csv")
	expect_equal(length(list.dirs(fx$dir, recursive = FALSE)), before)
})

# --- cross-file rules -------------------------------------------------------

test_that("implement_disease on with no PatchVars disease columns errors", {
	fx <- disease_fixture()
	rv <- fx_runvars(fx, fx_patchvars(fx, NULL), "Back")

	before <- length(list.dirs(fx$dir, recursive = FALSE))
	expect_error(.write_cdmetapop_inputfiles(rv, base_dir = fx$dir),
		"none of the eight disease columns are set")
	expect_equal(length(list.dirs(fx$dir, recursive = FALSE)), before)
})

test_that("implement_disease \"N\" with disease columns set errors", {
	fx <- disease_fixture()
	pv <- fx_patchvars(fx, fx_disease_cols(fx_diseasevars(fx)))

	expect_error(.write_cdmetapop_inputfiles(fx_runvars(fx, pv, "N"), base_dir = fx$dir),
		"exactly 50 PatchVars columns")
})

test_that("a partially set disease block names the gaps and the patches", {
	fx <- disease_fixture()
	pv <- fx_patchvars(fx, fx_disease_cols(fx_diseasevars(fx), env_res = NULL))
	expect_error(.write_cdmetapop_inputfiles(fx_runvars(fx, pv, "Out"), base_dir = fx$dir),
		"`env_res` is unset")

	pv2 <- fx_patchvars(fx, fx_disease_cols(fx_diseasevars(fx)))
	dv <- pv2$as_data_frame()[["disease_file"]][[1]][[1]]
	pv2$disease_file <- list(dv, dv, "", dv, dv, dv, dv)
	expect_error(.write_cdmetapop_inputfiles(fx_runvars(fx, pv2, "Back"), base_dir = fx$dir),
		"`disease_file` is unset for patch(es) 3", fixed = TRUE)
})

test_that("an inconsistent DiseaseVars object is caught before writing", {
	# Editing one column only warns, so an inconsistent object can reach
	# launch; this is where it becomes an error.
	fx <- disease_fixture()
	dv <- fx_diseasevars(fx)
	suppressWarnings(dv$n_states <- 4)
	pv <- fx_patchvars(fx, fx_disease_cols(dv))
	rv <- fx_runvars(fx, pv, "Back")

	before <- length(list.dirs(fx$dir, recursive = FALSE))
	expect_error(.write_cdmetapop_inputfiles(rv, base_dir = fx$dir), "one per state")
	expect_equal(length(list.dirs(fx$dir, recursive = FALSE)), before)
})

test_that("defense-rate counts must match the DiseaseVars transition count", {
	# CDMetaPOP indexes one into the other, so a short list is an IndexError
	# partway into a run.
	fx <- disease_fixture()
	dv <- fx_diseasevars(fx)

	pv_short <- fx_patchvars(fx, fx_disease_cols(dv, resistant_Cc = "0.2"))
	expect_error(
		.write_cdmetapop_inputfiles(fx_runvars(fx, pv_short, "Back"), base_dir = fx$dir),
		"Resistant_Cc"
	)

	pv_long <- fx_patchvars(fx, fx_disease_cols(dv, resistant_cc = "0.1;0.2;0.3"))
	expect_error(
		.write_cdmetapop_inputfiles(fx_runvars(fx, pv_long, "Back"), base_dir = fx$dir),
		"3 rate"
	)

	dv_tol <- fx_diseasevars(fx, disease_tolerant = "1_2;2_1")
	pv_tol <- fx_patchvars(fx, fx_disease_cols(dv_tol, tolerant_Dd = "0.1"))
	expect_error(
		.write_cdmetapop_inputfiles(fx_runvars(fx, pv_tol, "Back"), base_dir = fx$dir),
		"Tolerant_Dd"
	)
})

test_that("an \"N\" defense locus and temporal values skip the count check", {
	fx <- disease_fixture()

	# "N" means the locus is unused, so its rates are never read.
	dv_n <- DiseaseVars(transmission_mode = "Indirect", transition_rates = fx$tm)
	pv_n <- fx_patchvars(fx, fx_disease_cols(dv_n, resistant_Cc = "0"))
	expect_error(
		.write_cdmetapop_inputfiles(fx_runvars(fx, pv_n, "Back"), base_dir = fx$dir),
		NA
	)

	# With several `|` groups, which group pairs with which DiseaseVars depends
	# on RunVars' cdclimate switch years, so the check is skipped rather than
	# risk a false error.
	dv <- fx_diseasevars(fx)
	pv_t <- fx_patchvars(fx, fx_disease_cols(dv, resistant_Cc = "0.2;0.9|0.3;0.8"))
	expect_error(
		.write_cdmetapop_inputfiles(fx_runvars(fx, pv_t, "Back"), base_dir = fx$dir),
		NA
	)
})

test_that("every problem is reported in one error", {
	fx <- disease_fixture()
	dv <- fx_diseasevars(fx, disease_tolerant = "1_2")
	pv <- fx_patchvars(fx, fx_disease_cols(dv,
		resistant_Cc = "0.2", tolerant_Dd = "0.1;0.2"))

	msg <- tryCatch(
		.write_cdmetapop_inputfiles(fx_runvars(fx, pv, "Back"), base_dir = fx$dir),
		error = function(e) conditionMessage(e)
	)
	expect_match(msg, "Resistant_Cc")
	expect_match(msg, "Tolerant_Dd")
})
