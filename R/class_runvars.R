# RunVars: R6 wrapper for CDMetaPOP's RunVars.csv input file.
#
# RunVars.csv is the top of CDMetaPOP's input-file hierarchy: each row is a
# separate "run", and its `Popvars` field points at one or more PopVars.csv
# files (one per species for a multispecies run). CDMetaPOP executes every
# RunVars row ("run") x every PopVars row ("batch") x every Monte Carlo
# replicate (`mcruns`) as a separate simulation -- so the vocabulary is:
# RunVars rows = runs (this class's `n_runs`), PopVars rows = batches
# (PopVars' `n_batches`).
#
# Like PopVars (and UNLIKE ClassVars/PatchVars), CDMetaPOP reads RunVars.csv
# headers as dictionary KEYS, not just by column order -- so every column
# must be present and its header text must match exactly. Every RunVars.csv
# header is already a valid R name with no spaces, so -- as with PopVars --
# `.rv_fields` IS the header text, used directly as both the data frame's
# column name and the active binding name (e.g. `myrunvars$gridformat`); no
# separate snake_case field-name layer.
#
# As with PopVars/PatchVars, each *column* is exposed as an R6 active
# binding (rows are runs, edited as whole columns: `myrunvars$runtime <-
# c(5, 5, 10)`). Headers/defaults are drawn verbatim from
# example_files/RunVars.csv (the canonical example, 13 columns, 4 rows).
# Rules are from the user manual's section 3.1, "RunVars.csv file -- run
# parameters apply to all species".

# Canonical column headers/field names, in CDMetaPOP's expected order and
# exact spelling/case (read as dictionary keys by CDMetaPOP, so no
# human-readable-vs-snake_case distinction -- same as PopVars).
.rv_fields <- c(
	"Popvars", "sizecontrol", "constMortans", "mcruns", "runtime",
	"output_years", "gridformat", "gridsampling", "summaryOutput",
	"cdclimgentime", "startcomp", "implementcomp", "ncores"
)

# `Popvars` is an object-or-path list column referencing one or more PopVars
# objects/files (one per species; see `.rv_normalize_popvars_row()`). It is
# the only such field in RunVars, and -- unlike PopVars' object fields,
# which use `|` -- it uses `;` as its multi-value separator (the literal
# delimiter CDMetaPOP expects for multispecies PopVars lists). Handled
# separately from `.rv_rules` below, the same way PopVars singles out
# `xyfilename`/the cdmat fields.
.rv_object_fields <- c("Popvars")

# Default values, taken verbatim (one 4-element vector per column, one
# element per example row) from example_files/RunVars.csv -- the canonical
# RunVars example. Used by `.rv_default_for()` to fill in any column not
# specified at construction.
.rv_s1_defaults <- list(
	Popvars       = c("popvars/PopVars.csv", "popvars/PopVars.csv", "popvars/PopVars_IntroducePopulation.csv", "popvars/PopVars_Climate.csv"),
	sizecontrol   = c("Y", "N", "N", "N"),
	constMortans  = c("1", "1", "1", "1"),
	mcruns        = c("1", "1", "1", "2"),
	runtime       = c("5", "5", "5", "5"),
	output_years  = c("1", "1", "1", "1"),
	gridformat    = c("cdpop", "cdpop", "cdpop", "cdpop"),
	gridsampling  = c("Sample", "Sample", "Sample", "Sample"),
	summaryOutput = c("N", "N", "N", "N"),
	cdclimgentime = c("0|1|2", "0|1|2", "0|5", "0|4|8"),
	startcomp     = c("0", "0", "0", "0"),
	implementcomp = c("Back", "Back", "Back", "Back"),
	ncores        = c("1", "1", "1", "2")
)

# Validation rules for every plain-value (non-object-or-path) column, drawn
# from the user manual's section 3.1. RunVars uses only one delimiter
# mechanism, `|` (temporal change, via `allow_pipe` -- `output_years` and
# `cdclimgentime` give multiple `|`-separated year values); there is no `~`
# (per-sex) or `:` usage anywhere in RunVars, so the validator below is
# simpler than PopVars'. Rule `type`s:
#   - "YN": exactly "Y" or "N".
#   - "enum": one of a fixed character set.
#   - "enum_numeric": a number equal to one of a fixed numeric set.
#   - "numeric": a number within [lower, upper] (NA bound = unbounded);
#     `allow_pipe = TRUE` permits multiple `|`-separated values, each
#     validated independently.
.rv_rules <- list(
	sizecontrol   = list(type = "YN"),
	constMortans  = list(type = "enum_numeric", values = c(1, 2)),
	mcruns        = list(type = "numeric", lower = 1, upper = Inf, allow_pipe = FALSE),
	runtime       = list(type = "numeric", lower = 1, upper = Inf, allow_pipe = FALSE),
	output_years  = list(type = "numeric", lower = 0, upper = Inf, allow_pipe = TRUE),
	gridformat    = list(type = "enum", values = c("cdpop", "general", "genalex", "structure", "genepop")),
	gridsampling  = list(type = "enum", values = c("N", "Sample")),
	summaryOutput = list(type = "YN"),
	cdclimgentime = list(type = "numeric", lower = 0, upper = Inf, allow_pipe = TRUE),
	startcomp     = list(type = "numeric", lower = 0, upper = Inf, allow_pipe = FALSE),
	implementcomp = list(type = "enum", values = c("Back", "Out", "N")),
	ncores        = list(type = "numeric", lower = 1, upper = Inf, allow_pipe = FALSE)
)

#' Validate a single (post-'|'-split) RunVars value against its column's rule
#'
#' Internal helper called once per '|'-separated segment by
#' `.validate_rv_field()` -- mirrors PopVars' `.popv_check_segment()`, but
#' with only the four rule types RunVars actually uses.
#'
#' @keywords internal
.rv_check_segment <- function(rule, seg, field, i) {
	type <- rule$type

	if (type == "YN") {
		if (!seg %in% c("Y", "N")) stop(sprintf("`%s`[%d] = \"%s\" must be \"Y\" or \"N\".", field, i, seg))
		return(invisible(NULL))
	}
	if (type == "enum") {
		if (!seg %in% rule$values) stop(sprintf("`%s`[%d] = \"%s\" must be one of: %s.", field, i, seg, paste(rule$values, collapse = ", ")))
		return(invisible(NULL))
	}
	if (type == "enum_numeric") {
		num <- suppressWarnings(as.numeric(seg))
		if (is.na(num) || !(num %in% rule$values)) stop(sprintf("`%s`[%d] = \"%s\" must be one of: %s.", field, i, seg, paste(rule$values, collapse = ", ")))
		return(invisible(NULL))
	}

	# type == "numeric"
	num <- suppressWarnings(as.numeric(seg))
	if (is.na(num)) stop(sprintf("`%s`[%d] = \"%s\" is not a valid number.", field, i, seg))
	if (num < rule$lower || num > rule$upper) {
		stop(sprintf("`%s`[%d] = %s is outside the allowed range [%s, %s].", field, i, num, rule$lower, rule$upper))
	}
	invisible(NULL)
}

#' Validate and normalize one plain-value RunVars column
#'
#' Mirrors PopVars' `.validate_popv_field()` but only splits on `|` (RunVars
#' has no `~`/`:` fields). Each `|`-separated segment is validated
#' independently via `.rv_check_segment()`, but the whole original string is
#' stored verbatim as character (the literal text CDMetaPOP expects).
#'
#' @param field Column name (a key in `.rv_rules`, i.e. not `"Popvars"`).
#' @param values Vector of values; recycled to length `n` if length 1.
#' @param n Expected length (the number of runs already defined).
#' @keywords internal
.validate_rv_field <- function(field, values, n) {
	rule <- .rv_rules[[field]]
	if (length(values) == 1) values <- rep(values, n)
	if (length(values) != n) {
		stop(sprintf("`%s` must have length 1 or %d (the number of runs), not %d.", field, n, length(values)))
	}

	out <- character(n)
	for (i in seq_len(n)) {
		raw_chr <- as.character(values[i])
		if (is.na(raw_chr)) stop(sprintf("`%s`[%d] cannot be NA.", field, i))

		segments <- if (isTRUE(rule$allow_pipe) && grepl("|", raw_chr, fixed = TRUE)) {
			strsplit(raw_chr, "|", fixed = TRUE)[[1]]
		} else {
			raw_chr
		}
		for (seg in segments) .rv_check_segment(rule, seg, field, i)
		out[i] <- raw_chr
	}
	out
}

#' Resolve one `Popvars` `;`-segment to a live PopVars object or a literal
#' path
#'
#' Mirrors PopVars' `.popv_resolve_object_segment()` (and PatchVars'
#' `.pv_resolve_class_vars_segment()`): if `seg` is the name of a `PopVars`
#' object in the global environment, that object is returned (a live
#' reference); otherwise `seg` is returned unchanged, to be treated as a
#' literal file path. Searches `.GlobalEnv` only, for the same reasons
#' documented in `.pv_resolve_class_vars_segment()`.
#'
#' @param seg A single character segment, or already a `PopVars` object
#'   (passed through unchanged).
#' @param resolve If `FALSE`, skip the lookup entirely and return `seg`
#'   unchanged -- used when reading an existing RunVars.csv from disk, where
#'   every `Popvars` entry is necessarily a literal path.
#' @keywords internal
.rv_resolve_popvars_segment <- function(seg, resolve = TRUE) {
	if (resolve && is.character(seg) && length(seg) == 1 && !is.na(seg) && nzchar(seg) &&
			exists(seg, envir = .GlobalEnv, inherits = FALSE)) {
		candidate <- get(seg, envir = .GlobalEnv, inherits = FALSE)
		if (inherits(candidate, "PopVars")) return(candidate)
	}
	seg
}

#' Normalize one run's `Popvars` entry into a flat list of items
#'
#' A "item" is either a `PopVars` object or a literal character path. Unlike
#' PopVars' object fields (which split on `|`), `Popvars` splits on `;` --
#' the delimiter CDMetaPOP uses to list multiple PopVars files, one per
#' species, for a multispecies run. Handles a bare `PopVars` object; a bare
#' (possibly `;`-joined) character string, each segment resolved via
#' `.rv_resolve_popvars_segment()`; or a list/vector of multiple such items;
#' recursing so nested combinations flatten correctly.
#'
#' @keywords internal
.rv_normalize_popvars_row <- function(x, resolve = TRUE) {
	if (inherits(x, "PopVars")) return(list(x))
	if (is.character(x) && length(x) == 1) {
		segs <- strsplit(x, ";", fixed = TRUE)[[1]]
		return(lapply(segs, .rv_resolve_popvars_segment, resolve = resolve))
	}
	if (is.list(x) || is.character(x)) {
		items <- if (is.list(x)) x else as.list(x)
		return(Reduce(c, lapply(items, .rv_normalize_popvars_row, resolve = resolve), list()))
	}
	stop("`Popvars` items must each be a PopVars object or a single character string.")
}

#' Validate and normalize the `Popvars` column
#'
#' Stored as a list column (R6 objects cannot live in an atomic vector).
#' Each element is itself a flat list of one or more items (multiple
#' species per run), normalized by `.rv_normalize_popvars_row()`. Mirrors
#' PopVars' `.validate_popv_object_field()`.
#'
#' @param values A single value, or a list/vector of length `n`, each
#'   element one run's worth of `Popvars` input.
#' @param n Expected length (the number of runs).
#' @param resolve Forwarded to `.rv_normalize_popvars_row()` -- `FALSE`
#'   disables `.GlobalEnv` name resolution (used when reading from disk).
#' @keywords internal
.validate_rv_popvars <- function(values, n, resolve = TRUE) {
	is_scalar_value <- inherits(values, "PopVars") ||
		(is.character(values) && length(values) == 1)
	if (is_scalar_value) {
		one_run <- .rv_normalize_popvars_row(values, resolve = resolve)
		return(rep(list(one_run), n))
	}

	if (!is.list(values)) values <- as.list(values)
	if (length(values) == 1 && n != 1) values <- rep(values, n)
	if (length(values) != n) {
		stop(sprintf("`Popvars` must have length 1 or %d (the number of runs), not %d.", n, length(values)))
	}
	lapply(values, .rv_normalize_popvars_row, resolve = resolve)
}

# Default value for one column, for a given set of run indices. Rows beyond
# what RunVars.csv defines (row 4) recycle the last defined default, with a
# warning emitted once by the initializer (mirrors PopVars'
# `.popv_default_for()`).
.rv_default_for <- function(field, run_ids) {
	defaults <- .rv_s1_defaults[[field]]
	n <- length(run_ids)
	if (n <= length(defaults)) return(defaults[run_ids])
	c(defaults, rep(defaults[length(defaults)], n - length(defaults)))
}

# The R6 generator itself is not exported; users construct instances via the
# RunVars() wrapper function below. See class_classvars.R's note above
# `.ClassVarsR6` for why this is wrapped in local() + `#' @noRd`.

#' @noRd
.RunVarsR6 <- local(R6::R6Class("RunVars",
	public = list(
		initialize = function(
				n_runs = 4,
				Popvars = NULL,
				sizecontrol = NULL,
				constMortans = NULL,
				mcruns = NULL,
				runtime = NULL,
				output_years = NULL,
				gridformat = NULL,
				gridsampling = NULL,
				summaryOutput = NULL,
				cdclimgentime = NULL,
				startcomp = NULL,
				implementcomp = NULL,
				ncores = NULL,
				resolve_popvars = TRUE
		) {
			# RunVars.csv has no id column -- row order is the only thing
			# that matters (CDMetaPOP labels runs by position, "counting
			# from 0", per the user manual). So row count is just a plain
			# integer, `n_runs` (analogous to PopVars' `n_batches`).
			if (!is.numeric(n_runs) || length(n_runs) != 1 || n_runs < 1 || n_runs != as.integer(n_runs)) {
				stop("`n_runs` must be a single positive integer.")
			}
			n <- as.integer(n_runs)

			# Collect the user-supplied column arguments by name so they can
			# be looped over alongside `.rv_fields` below.
			supplied <- list(
				Popvars = Popvars, sizecontrol = sizecontrol, constMortans = constMortans,
				mcruns = mcruns, runtime = runtime, output_years = output_years,
				gridformat = gridformat, gridsampling = gridsampling,
				summaryOutput = summaryOutput, cdclimgentime = cdclimgentime,
				startcomp = startcomp, implementcomp = implementcomp, ncores = ncores
			)

			private$data <- as.data.frame(matrix(nrow = n, ncol = length(.rv_fields)))
			colnames(private$data) <- .rv_fields
			# `Popvars` is a list column (can hold PopVars objects), so it
			# must be assigned via `[[<-`, not the matrix-fill above.
			private$data[["Popvars"]] <- vector("list", n)

			# RunVars.csv only defines defaults for 4 runs. If more are
			# requested and any column is left unspecified, warn once (not
			# once per column) that the run-4 default is being recycled.
			max_default_n <- length(.rv_s1_defaults[[1]])
			any_unspecified <- any(vapply(supplied, is.null, logical(1)))
			if (n > max_default_n && any_unspecified) {
				warning(sprintf(
					"No default values exist in RunVars.csv for runs above %d; the run-%d default is being recycled for any unspecified column on the extra runs.",
					max_default_n, max_default_n
				), call. = FALSE)
			}

			for (field in .rv_fields) {
				raw <- supplied[[field]]
				if (is.null(raw)) raw <- .rv_default_for(field, seq_len(n))
				if (field == "Popvars") {
					private$data[["Popvars"]] <- private$validate_popvars(raw, resolve = resolve_popvars)
				} else {
					private$data[[field]] <- private$validate(field, raw)
				}
			}
		},

		# Add one or more runs, copying the current last row. See
		# class_classvars.R's add_row() for why row names are reset.
		add_row = function(n = 1) {
			last_row <- private$data[nrow(private$data), , drop = FALSE]
			new_rows <- last_row[rep(1, n), , drop = FALSE]
			private$data <- rbind(private$data, new_rows)
			rownames(private$data) <- NULL
			invisible(self)
		},

		print = function(...) {
			cat("<RunVars>", nrow(private$data), "run(s)\n")
			out <- private$data
			out[["Popvars"]] <- vapply(private$data[["Popvars"]], function(items) {
				paste(vapply(items, function(val) {
					if (inherits(val, "PopVars")) "<PopVars object>" else val
				}, character(1)), collapse = ";")
			}, character(1))
			print(out)
			invisible(self)
		},

		# Returns a plain (independent) copy of the underlying table -- see
		# class_classvars.R's as_data_frame() for rationale. The `Popvars`
		# list column is left as-is.
		as_data_frame = function() private$data
	),

	private = list(
		data = NULL,

		validate = function(field, values) {
			.validate_rv_field(field, values, nrow(private$data))
		},
		validate_popvars = function(values, resolve = TRUE) {
			.validate_rv_popvars(values, nrow(private$data), resolve = resolve)
		}
	),

	active = list(
		Popvars = function(value) {
			if (missing(value)) return(private$data[["Popvars"]])
			private$data[["Popvars"]] <- private$validate_popvars(value)
		},
		sizecontrol = function(value) {
			if (missing(value)) return(private$data[["sizecontrol"]])
			private$data[["sizecontrol"]] <- private$validate("sizecontrol", value)
		},
		constMortans = function(value) {
			if (missing(value)) return(private$data[["constMortans"]])
			private$data[["constMortans"]] <- private$validate("constMortans", value)
		},
		mcruns = function(value) {
			if (missing(value)) return(private$data[["mcruns"]])
			private$data[["mcruns"]] <- private$validate("mcruns", value)
		},
		runtime = function(value) {
			if (missing(value)) return(private$data[["runtime"]])
			private$data[["runtime"]] <- private$validate("runtime", value)
		},
		output_years = function(value) {
			if (missing(value)) return(private$data[["output_years"]])
			private$data[["output_years"]] <- private$validate("output_years", value)
		},
		gridformat = function(value) {
			if (missing(value)) return(private$data[["gridformat"]])
			private$data[["gridformat"]] <- private$validate("gridformat", value)
		},
		gridsampling = function(value) {
			if (missing(value)) return(private$data[["gridsampling"]])
			private$data[["gridsampling"]] <- private$validate("gridsampling", value)
		},
		summaryOutput = function(value) {
			if (missing(value)) return(private$data[["summaryOutput"]])
			private$data[["summaryOutput"]] <- private$validate("summaryOutput", value)
		},
		cdclimgentime = function(value) {
			if (missing(value)) return(private$data[["cdclimgentime"]])
			private$data[["cdclimgentime"]] <- private$validate("cdclimgentime", value)
		},
		startcomp = function(value) {
			if (missing(value)) return(private$data[["startcomp"]])
			private$data[["startcomp"]] <- private$validate("startcomp", value)
		},
		implementcomp = function(value) {
			if (missing(value)) return(private$data[["implementcomp"]])
			private$data[["implementcomp"]] <- private$validate("implementcomp", value)
		},
		ncores = function(value) {
			if (missing(value)) return(private$data[["ncores"]])
			private$data[["ncores"]] <- private$validate("ncores", value)
		},
		n_runs = function(value) {
			if (missing(value)) return(nrow(private$data))
			stop("`n_runs` cannot be reassigned after construction; create a new RunVars() object (or use add_row()) instead.")
		}
	)
))

#' Create a RunVars object
#'
#' Constructs an R6 object representing a CDMetaPOP `RunVars.csv` input file
#' -- the top of CDMetaPOP's input-file hierarchy. Each row is a separate
#' "run", and its `Popvars` field references one or more [PopVars()]
#' objects/files (one per species). CDMetaPOP executes every run x every
#' `PopVars` batch x every Monte Carlo replicate (`mcruns`) as a separate
#' simulation. Columns are edited as a whole after construction via `$`,
#' e.g. `myrunvars$runtime <- c(5, 5, 10)`.
#'
#' Any column argument left unsupplied defaults to the corresponding values
#' in `example_files/RunVars.csv`, matched to each requested run (recycling
#' the row-4 default, with a warning, for runs beyond what that file
#' defines).
#'
#' @details
#' **CDMetaPOP reads `RunVars.csv` headers as dictionary keys** (like
#' `PopVars.csv`, unlike `ClassVars.csv`/`PatchVars.csv`), so every column
#' name below is used verbatim as both the data frame column name and this
#' function's argument/active-binding name.
#'
#' **Delimiters:** `output_years` and `cdclimgentime` support CDMetaPOP's
#' `|` (multiple values; see [PatchVars()]'s Details for the analogous
#' temporal-change mechanism). No RunVars field uses `~` or `:`.
#'
#' **`Popvars` is an object-or-path field:** it accepts a [PopVars()] object
#' directly, a character path, the name of a `PopVars` object in
#' `.GlobalEnv` (see [PatchVars()]'s Details for the identical `class_vars`
#' name-resolution mechanism and its caveats), or -- for a multispecies run
#' -- several of any of these joined with `;` (e.g.
#' `"popvars/PopVarsS1.csv;popvars/PopVarsS2.csv"`), or a list of them. Note
#' `;`, not `|`, is `Popvars`' multi-value separator.
#'
#' @param n_runs Number of runs (rows). Defaults to 4, matching
#'   `RunVars.csv`. Cannot be changed after construction (use `add_row()` or
#'   [add_rows()] instead).
#' @param Popvars A [PopVars()] object, object-name/path string, or
#'   `;`-joined/list of several (one per species), for each run.
#' @param sizecontrol `"Y"` (body size drives size-linked processes) or
#'   `"N"` (age drives them).
#' @param constMortans How constant mortality events compound: `1` (additive
#'   / mutually exclusive) or `2` (multiplicative / independent).
#' @param mcruns Number of Monte Carlo replicates (positive integer).
#' @param runtime Simulation run time in generations/years (positive
#'   integer).
#' @param output_years Time steps to write output: a single integer (a
#'   stride, e.g. `2` -> years 0, 2, 4, ...), or exact years `|`-joined
#'   (e.g. `"0|3|4"`).
#' @param gridformat Genotype output format: `"cdpop"`, `"general"`,
#'   `"genalex"`, `"structure"`, or `"genepop"`.
#' @param gridsampling `"N"` (output at natal grounds) or `"Sample"` (also
#'   output when away from natal grounds).
#' @param summaryOutput `"Y"`/`"N"`: produce per-patch summary metrics.
#' @param cdclimgentime CDClimate module switch times: `"0"` (one surface
#'   throughout), or years `|`-joined (e.g. `"0|5|10"`).
#' @param startcomp Year Lotka-Volterra competition begins (non-negative
#'   integer).
#' @param implementcomp When to implement competition: `"Back"`, `"Out"`, or
#'   `"N"`.
#' @param ncores Number of cores for parallel Monte Carlo processing
#'   (positive integer).
#' @param resolve_popvars Whether `Popvars` character entries should be
#'   resolved against `PopVars` objects in `.GlobalEnv` by name (see
#'   Details). Defaults to `TRUE`; set to `FALSE` when every `Popvars` value
#'   is known to already be a literal path (e.g.
#'   `read_cdmetapop(..., type = "RunVars")` does this automatically).
#'
#' @return An R6 `RunVars` object.
#' @export
#'
#' @examples
#' # Default 4-run object, matching RunVars.csv:
#' myrunvars <- RunVars()
#'
#' # 1 run, defaults taken from RunVars.csv's first row:
#' myrunvars <- RunVars(n_runs = 1)
#'
#' # Edit a column in place (one value per run):
#' myrunvars$runtime <- c(5, 5, 10, 10)
#'
#' # Add a run (copies the last row; edit afterward):
#' myrunvars$add_row()
#' # or equivalently:
#' add_rows(myrunvars)
RunVars <- function(
	n_runs = 4,
	Popvars = c("popvars/PopVars.csv", "popvars/PopVars.csv", "popvars/PopVars_IntroducePopulation.csv", "popvars/PopVars_Climate.csv"),
	sizecontrol = c("Y", "N", "N", "N"),
	constMortans = c("1", "1", "1", "1"),
	mcruns = c("1", "1", "1", "2"),
	runtime = c("5", "5", "5", "5"),
	output_years = c("1", "1", "1", "1"),
	gridformat = c("cdpop", "cdpop", "cdpop", "cdpop"),
	gridsampling = c("Sample", "Sample", "Sample", "Sample"),
	summaryOutput = c("N", "N", "N", "N"),
	cdclimgentime = c("0|1|2", "0|1|2", "0|5", "0|4|8"),
	startcomp = c("0", "0", "0", "0"),
	implementcomp = c("Back", "Back", "Back", "Back"),
	ncores = c("1", "1", "1", "2"),
	resolve_popvars = TRUE
) {
	# See ClassVars()'s wrapper function for why these literal defaults are
	# forwarded as NULL to .RunVarsR6$new() when not actually supplied by
	# the caller (preserves the initializer's own run-count-based
	# default-resizing logic).
	this_env <- environment()
	supplied <- vapply(.rv_fields, function(field) {
		!eval(substitute(missing(x), list(x = as.name(field))), envir = this_env)
	}, logical(1))
	names(supplied) <- .rv_fields

	column_args <- mget(.rv_fields, envir = environment())
	column_args[!supplied] <- list(NULL)

	do.call(.RunVarsR6$new, c(
		list(n_runs = n_runs, resolve_popvars = resolve_popvars),
		column_args
	))
}
