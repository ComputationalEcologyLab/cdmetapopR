# DiseaseVars: R6 wrapper for CDMetaPOP's DiseaseVars.csv input file.
#
# A DiseaseVars.csv file defines one compartmental disease model: how many
# disease states there are, the proportion of individuals initialized in each,
# where the state-to-state transition rates live, which states count as
# susceptible/infectious/dead, how offspring are initialized, when the disease
# starts, whether transmission is direct or environmental, and which
# transitions are modified by the resistance/tolerance defense loci.
#
# Three things make this class different from the other four:
#
#   1. EXACTLY ONE ROW. CDMetaPOP reads the header row plus a single data row
#      (`df.iloc[1, N]`, src/CDmetaPOP_Disease.py) and silently ignores any
#      further rows. So there is no row-count argument and no add_row(); the
#      `add_row()` method below deliberately errors. Note `n_states` is a
#      COLUMN (how many disease compartments the model has), NOT a row count
#      -- unlike PopVars' `n_batches` or RunVars' `n_runs`.
#
#   2. NO `|` DELIMITER ANYWHERE. Every cell is read as a plain scalar; no
#      cdclimate `split_or_get()` call touches this file. Temporal variation
#      happens one level up, in PatchVars' `disease_file` column, by swapping
#      whole DiseaseVars files. `;` is the only delimiter used here.
#
#   3. GENUINE CROSS-FIELD RULES. Seven rules span two or more columns (e.g.
#      `initial_conditions` must have `n_states` parts; the transition matrix
#      must be `n_states` square for Direct transmission and `n_states + 1`
#      square for Indirect). The other classes validate every column
#      independently. These are enforced by `.dv_cross_check()`, which ERRORS
#      at construction but only WARNS on a later single-column assignment --
#      otherwise an object could never move between consistent states (going
#      from 3 to 4 compartments requires `n_states` and `initial_conditions`
#      to change in two separate assignments, and whichever came first would
#      fail). Everything is re-checked as an error before any file is written.
#
# Like ClassVars/PatchVars -- and UNLIKE PopVars/RunVars -- CDMetaPOP matches
# these columns by POSITION, not by header text (it reads the file with
# `header=None`). So the header row is never interpreted, and the stored data
# frame uses the human-readable header text (`.dv_headers`) as its column
# names while the active bindings use snake_case names (`.dv_fields`), the
# same split as PatchVars.
#
# Headers/defaults: the header text is verbatim from CDMetaPOP's
# example_files/DiseaseExamples/OnePatch_SIDP/otherfiles/disease/
# DiseaseVars_SIDP.csv. The DEFAULTS deliberately are NOT from that file: it
# is an indirect-transmission SIDP model with a resistance locus configured,
# which would make a no-argument DiseaseVars() a poor starting point (it also
# drags in the 4-loci/2-allele requirement). Instead the defaults describe the
# basic 3-state SIR model from the user manual's disease quick-start, which is
# also the template used by the make_diseasevars() Shiny app.

# Canonical column headers, in CDMetaPOP's expected order and exact spelling.
# Read positionally, so this text is for humans only. Unlike `.pv_headers`/
# `.cv_headers` there is no leading id column, so `.dv_headers` and
# `.dv_fields` are parallel 1:1.
.dv_headers <- c(
	"Number of States", "Initial Conditions", "Transition Rates",
	"Susceptible States", "Infection States", "Death States",
	"Initial Conditions Offspring", "Start Disease", "Transmission Mode",
	"Disease Resistant", "Disease Tolerant"
)

# snake_case field/binding names, in the same order as `.dv_headers`.
.dv_fields <- c(
	"n_states", "initial_conditions", "transition_rates",
	"susceptible_states", "infection_states", "death_states",
	"initial_conditions_offspring", "start_disease", "transmission_mode",
	"disease_resistant", "disease_tolerant"
)

# `transition_rates` is a matrix-or-path field (Key Design Decision 4),
# handled by `.validate_dv_transition_rates()` rather than `.dv_rules`. It is
# the only one in this class, and -- unlike PopVars' matrix fields -- it does
# NOT accept "N": CDMetaPOP always reads a transition matrix when the disease
# module is on. A CHARACTER matrix is accepted as well as a numeric one, since
# a cell may be "mu;sigma" (CDMetaPOP redraws that rate from rnorm(mu, sigma)
# at every CDClimate step; see src/CDmetaPOP_PreProcess.py).
.dv_matrix_fields <- c("transition_rates")

# Default values: the basic SIR model from the user manual's disease
# quick-start (see the file note above for why these do not come from an
# example csv). Stored as length-1 character, matching the other classes'
# defaults objects and this file's single row. `transition_rates` defaults to
# a PATH rather than a matrix for the same reason PopVars' cost matrices do:
# the file is not bundled with the package, so it can only be referenced.
.dv_sir_defaults <- list(
	n_states                     = "3",
	initial_conditions           = "0.9;0.1;0.0",
	transition_rates             = "otherfiles/disease/TransitionMatrix_SIR.csv",
	susceptible_states           = "0",
	infection_states             = "1",
	death_states                 = "N",
	initial_conditions_offspring = "Susceptible",
	start_disease                = "0",
	transmission_mode            = "Direct",
	disease_resistant            = "N",
	disease_tolerant             = "N"
)

# Validation rules for every plain-value (non-matrix) column. Rule `type`s --
# five of these are specific to this class, because every DiseaseVars field
# has a composite format where the other classes are mostly scalars:
#   - "numeric": a number within [lower, upper]; `integer = TRUE` additionally
#     requires a whole number.
#   - "enum": exact match against a fixed set (case-sensitive; see
#     `transmission_mode` below for why that matters).
#   - "prop_list": one or more `;`-separated proportions, each in [0, 1].
#   - "state_list": one or more `;`-separated state indices (non-negative
#     whole numbers). CDMetaPOP gained multi-state support for the susceptible
#     and infectious compartments in src/CDmetaPOP_Disease.py; before that
#     these were single values, which is why every example file has only one.
#   - "state_or_N": a single state index, or the literal "N" (feature off).
#   - "offspring_rule": "Susceptible", or "Vertical;<rate>" with rate in
#     [0, 1]. NOTE the manual and the Shiny app document "Vertical_X:Y" (mean
#     and standard deviation), but the engine reads `OffAns.split(';')[1]` as
#     a single rate (src/CDmetaPOP_Offspring2.py), so the `;` form is what is
#     accepted here. The manual's third option, "Random", is NOT accepted: it
#     has no branch in the engine, which leaves the offspring's state variable
#     unassigned.
#   - "transition_spec": "N", or one or more `;`-separated "<from>_<to>" state
#     pairs (e.g. "0_1;3_1"), naming the transitions a defense locus modifies.
#
# `transmission_mode` is deliberately an exact-match enum. CDMetaPOP's own
# check lowercases the value, but every USE of it is a case-sensitive
# comparison against "Indirect" -- so a lowercase "indirect" would pass
# CDMetaPOP's validation and then silently run as Direct, with no
# environmental force of infection and no error.
.dv_rules <- list(
	n_states                     = list(type = "numeric", lower = 1, upper = Inf, integer = TRUE),
	initial_conditions           = list(type = "prop_list"),
	susceptible_states           = list(type = "state_list"),
	infection_states             = list(type = "state_list"),
	death_states                 = list(type = "state_or_N"),
	initial_conditions_offspring = list(type = "offspring_rule"),
	start_disease                = list(type = "numeric", lower = 0, upper = Inf, integer = TRUE),
	transmission_mode            = list(type = "enum", values = c("Direct", "Indirect")),
	disease_resistant            = list(type = "transition_spec"),
	disease_tolerant             = list(type = "transition_spec")
)

#' Look up one field's value in a DiseaseVars data frame
#'
#' The stored table is keyed by header text while fields are snake_case, so
#' every internal read goes through this mapping (mirrors PatchVars' use of
#' `.pv_headers[match(field, .pv_fields) + 1]`, without the id-column offset).
#'
#' @keywords internal
.dv_get <- function(df, field) {
	df[[.dv_headers[match(field, .dv_fields)]]]
}

#' Split a `;`-delimited DiseaseVars cell
#'
#' @keywords internal
.dv_split <- function(x) strsplit(as.character(x), ";", fixed = TRUE)[[1]]

#' Parse `;`-separated parts as numbers, erroring on anything unparseable
#'
#' @param field,what Used only to build the error message.
#' @keywords internal
.dv_as_numbers <- function(parts, field, what) {
	nums <- suppressWarnings(as.numeric(parts))
	if (length(nums) == 0 || any(is.na(nums))) {
		stop(sprintf("`%s` must be %s, separated by \";\" if more than one.", field, what), call. = FALSE)
	}
	nums
}

#' Validate one DiseaseVars value against its column's rule
#'
#' Checks only what can be judged from the value itself; rules that depend on
#' another column (e.g. a state index against `n_states`) are deferred to
#' `.dv_cross_check()`.
#'
#' @keywords internal
.dv_check_value <- function(rule, val, field) {
	type <- rule$type

	if (type == "numeric") {
		num <- suppressWarnings(as.numeric(val))
		if (is.na(num)) {
			stop(sprintf("`%s` = \"%s\" is not a valid number.", field, val), call. = FALSE)
		}
		if (num < rule$lower || num > rule$upper) {
			stop(sprintf("`%s` = %s is outside the allowed range [%s, %s].",
				field, num, rule$lower, rule$upper), call. = FALSE)
		}
		if (isTRUE(rule$integer) && num != round(num)) {
			stop(sprintf("`%s` = %s must be a whole number.", field, num), call. = FALSE)
		}
		return(invisible(NULL))
	}

	if (type == "enum") {
		if (!val %in% rule$values) {
			stop(sprintf("`%s` = \"%s\" must be one of: %s (matched exactly, including case).",
				field, val, paste(rule$values, collapse = ", ")), call. = FALSE)
		}
		return(invisible(NULL))
	}

	if (type == "prop_list") {
		nums <- .dv_as_numbers(.dv_split(val), field, "one or more proportions between 0 and 1")
		if (any(nums < 0 | nums > 1)) {
			stop(sprintf("`%s` = \"%s\" has a proportion outside [0, 1].", field, val), call. = FALSE)
		}
		return(invisible(NULL))
	}

	if (type == "state_list") {
		nums <- .dv_as_numbers(.dv_split(val), field, "one or more state indices (whole numbers, counting from 0)")
		if (any(nums < 0) || any(nums != round(nums))) {
			stop(sprintf("`%s` = \"%s\" must be non-negative whole state indices, counting from 0.",
				field, val), call. = FALSE)
		}
		return(invisible(NULL))
	}

	if (type == "state_or_N") {
		# "N" is matched exactly: CDMetaPOP compares `!= 'N'` before calling
		# int() on this cell, so a lowercase "n" would be sent to int().
		if (identical(val, "N")) return(invisible(NULL))
		parts <- .dv_split(val)
		if (length(parts) != 1) {
			stop(sprintf("`%s` = \"%s\" must be a single state index or \"N\"; multiple (\";\"-separated) values are not supported.",
				field, val), call. = FALSE)
		}
		num <- .dv_as_numbers(parts, field, "a single state index (a whole number, counting from 0) or \"N\"")
		if (num < 0 || num != round(num)) {
			stop(sprintf("`%s` = \"%s\" must be a non-negative whole state index, or \"N\".",
				field, val), call. = FALSE)
		}
		return(invisible(NULL))
	}

	if (type == "offspring_rule") {
		if (identical(val, "Susceptible")) return(invisible(NULL))
		parts <- .dv_split(val)
		if (length(parts) == 2 && identical(parts[1], "Vertical")) {
			rate <- suppressWarnings(as.numeric(parts[2]))
			if (is.na(rate) || rate < 0 || rate > 1) {
				stop(sprintf("`%s` = \"%s\": the vertical transmission rate must be a number between 0 and 1, e.g. \"Vertical;0.5\".",
					field, val), call. = FALSE)
			}
			return(invisible(NULL))
		}
		stop(sprintf("`%s` = \"%s\" must be \"Susceptible\" or \"Vertical;<rate>\" (e.g. \"Vertical;0.5\").",
			field, val), call. = FALSE)
	}

	# type == "transition_spec"
	if (identical(val, "N")) return(invisible(NULL))
	for (pair in .dv_split(val)) {
		halves <- strsplit(pair, "_", fixed = TRUE)[[1]]
		nums <- suppressWarnings(as.numeric(halves))
		if (length(halves) != 2 || any(is.na(nums)) || any(nums < 0) || any(nums != round(nums))) {
			stop(sprintf("`%s` = \"%s\": each transition must be \"<from>_<to>\" using state indices, joined by \";\" if more than one (e.g. \"0_1;3_1\"). Use \"N\" for no defense locus.",
				field, val), call. = FALSE)
		}
	}
	invisible(NULL)
}

#' Validate and normalize one plain-value DiseaseVars column
#'
#' Unlike the other classes' field validators there is no row count to recycle
#' against: the file has exactly one row, so exactly one value is accepted.
#' The original string is stored verbatim as character (the literal text
#' CDMetaPOP expects).
#'
#' @param field Column name (a key in `.dv_rules`, i.e. not
#'   `"transition_rates"`).
#' @param value A single value.
#' @keywords internal
.validate_dv_field <- function(field, value) {
	rule <- .dv_rules[[field]]
	if (length(value) != 1) {
		stop(sprintf("`%s` must be a single value; DiseaseVars holds exactly one row (%d given).",
			field, length(value)), call. = FALSE)
	}
	raw_chr <- as.character(value)
	if (is.na(raw_chr)) stop(sprintf("`%s` cannot be NA.", field), call. = FALSE)
	.dv_check_value(rule, raw_chr, field)
	raw_chr
}

#' Validate and normalize the `transition_rates` column
#'
#' Accepts either a single raw `matrix` (numeric or character) or a filepath
#' string, and is stored as a one-element list column (an R6-style payload
#' cannot live in an atomic vector). Checked here: squareness, and that every
#' cell is a number or a "mu;sigma" pair. NOT checked here: the matrix's
#' dimension against `n_states`/`transmission_mode`, which is a cross-field
#' rule (see `.dv_cross_check()`).
#'
#' @keywords internal
.validate_dv_transition_rates <- function(value) {
	# Unwrap a length-1 list so round-tripping a stored cell works.
	if (is.list(value) && length(value) == 1) value <- value[[1]]

	if (is.matrix(value)) {
		if (nrow(value) != ncol(value)) {
			stop(sprintf("`transition_rates` must be a square matrix (got %d x %d).",
				nrow(value), ncol(value)), call. = FALSE)
		}
		if (nrow(value) == 0) {
			stop("`transition_rates` cannot be an empty matrix.", call. = FALSE)
		}
		# Each cell is a rate, or "mu;sigma" for a rate redrawn each CDClimate
		# step. A character matrix is how the latter is supplied.
		for (cell in as.character(value)) {
			if (is.na(cell)) {
				stop("`transition_rates` cannot contain NA; use 0 for \"no transition\".", call. = FALSE)
			}
			parts <- suppressWarnings(as.numeric(.dv_split(cell)))
			if (length(parts) > 2 || any(is.na(parts))) {
				stop(sprintf("`transition_rates` cell \"%s\" must be a number, or \"mu;sigma\" to redraw that rate each CDClimate step.",
					cell), call. = FALSE)
			}
		}
		return(list(value))
	}

	if (is.character(value) && length(value) == 1 && !is.na(value)) {
		if (!nzchar(value)) {
			stop("`transition_rates` cannot be an empty string.", call. = FALSE)
		}
		if (identical(value, "N")) {
			stop("`transition_rates` does not accept \"N\"; a transition matrix is required whenever the disease module is on.", call. = FALSE)
		}
		return(list(value))
	}

	stop("`transition_rates` must be a single square matrix or a filepath string.", call. = FALSE)
}

#' Check the cross-field DiseaseVars rules
#'
#' Returns a character vector of problem descriptions (empty if consistent)
#' rather than erroring, so the caller can choose severity: construction and
#' the launch-time writer treat these as errors, while a single-column
#' assignment only warns. That split exists because consistency cannot be
#' maintained assignment-by-assignment -- moving from 3 to 4 compartments
#' needs `n_states` and `initial_conditions` to change separately, and
#' whichever was set first would otherwise be rejected.
#'
#' @param df A one-row DiseaseVars data frame (header-keyed).
#' @keywords internal
.dv_cross_check <- function(df) {
	problems <- character(0)

	n_states    <- as.numeric(.dv_get(df, "n_states"))
	mode        <- .dv_get(df, "transmission_mode")
	is_indirect <- identical(mode, "Indirect")

	# 1 + 2. Initial conditions: one proportion per state, summing to 1.
	init <- suppressWarnings(as.numeric(.dv_split(.dv_get(df, "initial_conditions"))))
	if (!any(is.na(init))) {
		if (length(init) != n_states) {
			problems <- c(problems, sprintf(
				"`initial_conditions` has %d proportion(s) but `n_states` is %s; CDMetaPOP requires one per state.",
				length(init), n_states))
		}
		if (!isTRUE(all.equal(sum(init), 1))) {
			problems <- c(problems, sprintf(
				"`initial_conditions` sums to %s, not 1.", format(sum(init))))
		}
	}

	# 3-5. State indices must name a state that exists. CDMetaPOP's own checks
	# for the susceptible and infectious compartments are currently commented
	# out in src/CDmetaPOP_Disease.py, so these are enforced here only.
	for (field in c("susceptible_states", "infection_states")) {
		idx <- suppressWarnings(as.numeric(.dv_split(.dv_get(df, field))))
		if (!any(is.na(idx)) && any(idx >= n_states)) {
			problems <- c(problems, sprintf(
				"`%s` names state %s, but `n_states` is %s (states are numbered from 0, so the highest valid index is %s).",
				field, paste(idx[idx >= n_states], collapse = ", "), n_states, n_states - 1))
		}
	}
	death <- .dv_get(df, "death_states")
	if (!identical(death, "N")) {
		d <- suppressWarnings(as.numeric(death))
		if (!is.na(d) && d >= n_states) {
			problems <- c(problems, sprintf(
				"`death_states` is %s, but `n_states` is %s (the highest valid index is %s).",
				d, n_states, n_states - 1))
		}
	}

	# 6. Transition matrix dimension. Indirect transmission adds one row and
	# column for the environmental reservoir (the pathogen state), which is
	# assumed to be last. Only checkable when a raw matrix was supplied -- a
	# path is not read here.
	tr <- .dv_get(df, "transition_rates")[[1]]
	if (is.matrix(tr)) {
		expected <- if (is_indirect) n_states + 1 else n_states
		if (nrow(tr) != expected) {
			problems <- c(problems, sprintf(
				"`transition_rates` is %d x %d, but %s transmission with `n_states` = %s requires %d x %d%s.",
				nrow(tr), ncol(tr), mode, n_states, expected, expected,
				if (is_indirect) " (one extra row/column for the environmental reservoir)" else ""))
		}
	}

	# 7. Defense transitions must name states that exist. Under Indirect
	# transmission the environmental reservoir is itself a valid FROM state at
	# index `n_states` -- which is why the canonical "0_1;3_1" is legal with 3
	# states.
	max_idx <- if (is_indirect) n_states else n_states - 1
	for (field in c("disease_resistant", "disease_tolerant")) {
		spec <- .dv_get(df, field)
		if (identical(spec, "N")) next
		idx <- suppressWarnings(as.numeric(unlist(strsplit(.dv_split(spec), "_", fixed = TRUE))))
		if (!any(is.na(idx)) && any(idx > max_idx)) {
			problems <- c(problems, sprintf(
				"`%s` names state %s, but the highest valid index with %s transmission and `n_states` = %s is %s.",
				field, paste(unique(idx[idx > max_idx]), collapse = ", "), mode, n_states, max_idx))
		}
	}

	problems
}

#' Report cross-field problems as an error or a warning
#'
#' @param problems Output of `.dv_cross_check()`.
#' @param strict `TRUE` to stop, `FALSE` to warn (see `.dv_cross_check()`).
#' @keywords internal
.dv_report_cross <- function(problems, strict) {
	if (length(problems) == 0) return(invisible(NULL))
	msg <- paste(c("", paste0("  - ", problems)), collapse = "\n")
	if (strict) {
		stop(sprintf("Inconsistent DiseaseVars values:%s", msg), call. = FALSE)
	}
	warning(sprintf(
		"This DiseaseVars object is now internally inconsistent:%s\nFix this before writing or launching; the remaining column(s) can be set next.",
		msg), call. = FALSE)
	invisible(NULL)
}

# The R6 generator itself is not exported; users construct instances via the
# DiseaseVars() wrapper function below. See class_classvars.R's note above
# `.ClassVarsR6` for why this is wrapped in local() + `#' @noRd`.

#' @noRd
.DiseaseVarsR6 <- local(R6::R6Class("DiseaseVars",
	public = list(
		initialize = function(
				n_states = NULL,
				initial_conditions = NULL,
				transition_rates = NULL,
				susceptible_states = NULL,
				infection_states = NULL,
				death_states = NULL,
				initial_conditions_offspring = NULL,
				start_disease = NULL,
				transmission_mode = NULL,
				disease_resistant = NULL,
				disease_tolerant = NULL
		) {
			# Collect the user-supplied column arguments by name so they can be
			# looped over alongside `.dv_fields` below.
			supplied <- list(
				n_states = n_states, initial_conditions = initial_conditions,
				transition_rates = transition_rates,
				susceptible_states = susceptible_states,
				infection_states = infection_states, death_states = death_states,
				initial_conditions_offspring = initial_conditions_offspring,
				start_disease = start_disease, transmission_mode = transmission_mode,
				disease_resistant = disease_resistant,
				disease_tolerant = disease_tolerant
			)

			# Exactly one row, always (see the file note above).
			private$data <- as.data.frame(matrix(nrow = 1, ncol = length(.dv_headers)))
			colnames(private$data) <- .dv_headers
			# "Transition Rates" is a list column (it can hold a raw matrix),
			# so it must be assigned via `[[<-`, not the matrix-fill above.
			private$data[["Transition Rates"]] <- vector("list", 1)

			for (field in .dv_fields) {
				raw <- supplied[[field]]
				if (is.null(raw)) raw <- .dv_sir_defaults[[field]]
				header <- .dv_headers[match(field, .dv_fields)]
				if (field %in% .dv_matrix_fields) {
					private$data[[header]] <- .validate_dv_transition_rates(raw)
				} else {
					private$data[[header]] <- .validate_dv_field(field, raw)
				}
			}

			# A freshly constructed object must be fully consistent.
			.dv_report_cross(.dv_cross_check(private$data), strict = TRUE)
		},

		# DiseaseVars.csv holds exactly one row, so there is nothing to add.
		# Defined (rather than left out) so the error explains why, instead of
		# R reporting no applicable method for the add_rows() generic.
		add_row = function(n = 1) {
			stop("A DiseaseVars object holds exactly one row: CDMetaPOP reads a single disease model from DiseaseVars.csv and ignores any further rows. To describe a second disease model, create another DiseaseVars object (patches can reference different ones).",
				call. = FALSE)
		},

		# Re-run the cross-field rules, erroring on any problem. Called by the
		# launch-time writer, and available to users who have finished a
		# multi-step edit and want to confirm the object is consistent.
		check = function() {
			.dv_report_cross(.dv_cross_check(private$data), strict = TRUE)
			invisible(self)
		},

		print = function(...) {
			cat("<DiseaseVars>", .dv_get(private$data, "n_states"), "state(s),",
				.dv_get(private$data, "transmission_mode"), "transmission\n")
			out <- private$data
			# Summarize the matrix cell rather than printing a whole matrix
			# inside a one-row data frame.
			out[["Transition Rates"]] <- vapply(private$data[["Transition Rates"]], function(val) {
				if (is.matrix(val)) sprintf("<%d x %d matrix>", nrow(val), ncol(val)) else val
			}, character(1))
			print(out)
			invisible(self)
		},

		# Returns a plain (independent) copy of the underlying table -- see
		# class_classvars.R's as_data_frame() for rationale. The
		# "Transition Rates" list column is left as-is.
		as_data_frame = function() private$data
	),

	private = list(
		data = NULL
	),

	active = list(
		n_states = function(value) {
			if (missing(value)) return(private$data[["Number of States"]])
			private$data[["Number of States"]] <- .validate_dv_field("n_states", value)
			.dv_report_cross(.dv_cross_check(private$data), strict = FALSE)
		},
		initial_conditions = function(value) {
			if (missing(value)) return(private$data[["Initial Conditions"]])
			private$data[["Initial Conditions"]] <- .validate_dv_field("initial_conditions", value)
			.dv_report_cross(.dv_cross_check(private$data), strict = FALSE)
		},
		transition_rates = function(value) {
			if (missing(value)) return(private$data[["Transition Rates"]])
			private$data[["Transition Rates"]] <- .validate_dv_transition_rates(value)
			.dv_report_cross(.dv_cross_check(private$data), strict = FALSE)
		},
		susceptible_states = function(value) {
			if (missing(value)) return(private$data[["Susceptible States"]])
			private$data[["Susceptible States"]] <- .validate_dv_field("susceptible_states", value)
			.dv_report_cross(.dv_cross_check(private$data), strict = FALSE)
		},
		infection_states = function(value) {
			if (missing(value)) return(private$data[["Infection States"]])
			private$data[["Infection States"]] <- .validate_dv_field("infection_states", value)
			.dv_report_cross(.dv_cross_check(private$data), strict = FALSE)
		},
		death_states = function(value) {
			if (missing(value)) return(private$data[["Death States"]])
			private$data[["Death States"]] <- .validate_dv_field("death_states", value)
			.dv_report_cross(.dv_cross_check(private$data), strict = FALSE)
		},
		# `initial_conditions_offspring` and `start_disease` take part in no
		# cross-field rule, but still re-check after assignment so that the
		# warning consistently reflects the object's state no matter which
		# column was touched (and so a future cross-rule involving them needs
		# no change here).
		initial_conditions_offspring = function(value) {
			if (missing(value)) return(private$data[["Initial Conditions Offspring"]])
			private$data[["Initial Conditions Offspring"]] <- .validate_dv_field("initial_conditions_offspring", value)
			.dv_report_cross(.dv_cross_check(private$data), strict = FALSE)
		},
		start_disease = function(value) {
			if (missing(value)) return(private$data[["Start Disease"]])
			private$data[["Start Disease"]] <- .validate_dv_field("start_disease", value)
			.dv_report_cross(.dv_cross_check(private$data), strict = FALSE)
		},
		transmission_mode = function(value) {
			if (missing(value)) return(private$data[["Transmission Mode"]])
			private$data[["Transmission Mode"]] <- .validate_dv_field("transmission_mode", value)
			.dv_report_cross(.dv_cross_check(private$data), strict = FALSE)
		},
		disease_resistant = function(value) {
			if (missing(value)) return(private$data[["Disease Resistant"]])
			private$data[["Disease Resistant"]] <- .validate_dv_field("disease_resistant", value)
			.dv_report_cross(.dv_cross_check(private$data), strict = FALSE)
		},
		disease_tolerant = function(value) {
			if (missing(value)) return(private$data[["Disease Tolerant"]])
			private$data[["Disease Tolerant"]] <- .validate_dv_field("disease_tolerant", value)
			.dv_report_cross(.dv_cross_check(private$data), strict = FALSE)
		}
	)
))

#' Create a DiseaseVars object
#'
#' Constructs an R6 object representing a CDMetaPOP `DiseaseVars.csv` input
#' file -- one compartmental disease model, referenced per patch by
#' [PatchVars()]'s `disease_file` column. Columns may be edited after
#' construction, e.g. `mydiseasevars$start_disease <- 10`. **To build the
#' object from an existing DiseaseVars file, use the `path` argument or the
#' [read_cdmetapop()] function.**
#'
#' Any column argument left unsupplied defaults to the basic 3-state SIR model
#' from the user manual's disease quick-start.
#'
#' @details
#' **The file holds exactly one row.** CDMetaPOP reads a single disease model
#' from `DiseaseVars.csv` and ignores any further rows, so there is no
#' row-count argument and [add_rows()] errors on this class. Note `n_states`
#' is a *column* -- the number of disease compartments -- not a row count. To
#' give different patches different disease models, create several
#' `DiseaseVars` objects and reference them from the relevant patches.
#'
#' **The disease module must also be switched on in [PopVars()]**, by setting
#' `implement_disease` to `"Out"`, `"Back"`, or `"Both"`, and each patch must
#' reference a disease file in [PatchVars()]. A `DiseaseVars` object on its own
#' has no effect.
#'
#' **Delimiters:** `;` is the only delimiter used in this file, separating the
#' per-state proportions in `initial_conditions`, multiple state indices, and
#' multiple defense transitions. Unlike the other input files, no column
#' supports `|` for variation over time -- to change disease parameters over a
#' simulation, point [PatchVars()]'s `disease_file` column at several
#' `DiseaseVars` files joined with `|` instead.
#'
#' **States are numbered from 0**, and state 0 is assumed to be the initial
#' susceptible state. With `n_states = 3` the valid indices are 0, 1, and 2.
#' Under `"Indirect"` transmission the environmental reservoir occupies one
#' further index (`n_states`), which `transition_rates` must include and which
#' `disease_resistant`/`disease_tolerant` may name as a source state.
#'
#' **Cross-column rules.** Several values must agree with each other: one
#' `initial_conditions` proportion per state summing to 1, every state index
#' below `n_states`, and a `transition_rates` matrix of `n_states` square for
#' `"Direct"` transmission or `n_states + 1` square for `"Indirect"`. These are
#' errors at construction, but editing a single column afterward only warns --
#' so a change needing two assignments (such as moving from 3 to 4 states) can
#' be made in either order. Call `mydiseasevars$check()` to confirm the object
#' is consistent again; [launch_cdmetapop()] re-checks before writing anything.
#'
#' @param n_states Number of disease compartments (a whole number, 1 or more).
#'   State 0 is always the initial susceptible state.
#' @param initial_conditions Proportion of individuals initialized in each
#'   state at the start of the simulation, joined by `;`, one per state and
#'   summing to 1 (e.g. `"0.9;0.1;0.0"`).
#' @param transition_rates The state-to-state transition matrix: either a
#'   square `matrix` or a path to a csv holding one. Rows are the state moved
#'   TO and columns the state moved FROM. A cell may be a single rate, or
#'   `"mu;sigma"` (supply a character matrix) to redraw that rate from a normal
#'   distribution at each CDClimate time step.
#' @param infection_states State index considered infectious, or several
#'   joined by `;`.
#' @param susceptible_states State index considered susceptible, or several
#'   joined by `;`.
#' @param death_states State index used for mortality -- individuals entering
#'   it are removed from the simulation -- or `"N"` for no death compartment.
#' @param initial_conditions_offspring How newborns' disease states are
#'   assigned: `"Susceptible"` (all born into state 0), or
#'   `"Vertical;<rate>"` for vertical transmission from infected mothers at
#'   that probability (e.g. `"Vertical;0.5"`).
#' @param start_disease Time step at which disease transmission begins (a
#'   non-negative whole number).
#' @param transmission_mode `"Direct"` (individual to individual) or
#'   `"Indirect"` (from a patch's environmental reservoir to individuals, which
#'   also enables the reservoir tracked by [PatchVars()]'s `env_res` column).
#'   Matched exactly, including case.
#' @param disease_resistant The transition(s) modified by the resistance
#'   locus, each written `"<from>_<to>"` with state indices and joined by `;`
#'   (e.g. `"0_1;3_1"`), or `"N"` for no resistance locus. The rates
#'   themselves are per-patch and per-genotype, set in [PatchVars()].
#' @param disease_tolerant As `disease_resistant`, for the tolerance locus.
#' @param path Optional path to an existing DiseaseVars csv file. If supplied,
#'   the object is built from that file. Any column arguments supplied
#'   alongside `path` override the file's values, validated exactly as a later
#'   `$` assignment would be. With no overrides, this is equivalent to
#'   `read_cdmetapop(path, type = "DiseaseVars")`.
#'
#' @return An R6 `DiseaseVars` object.
#' @export
#'
#' @examples
#' # The default 3-state SIR model:
#' mydiseasevars <- DiseaseVars()
#'
#' # Start the epidemic at year 10 instead of year 0:
#' mydiseasevars$start_disease <- 10
#'
#' # An SIR model supplying the transition matrix directly. Rows are the state
#' # moved TO, columns the state moved FROM: 0.5 is the S -> I rate and 0.2 the
#' # I -> R rate.
#' transitions <- matrix(0, nrow = 3, ncol = 3)
#' transitions[2, 1] <- 0.5
#' transitions[3, 2] <- 0.2
#' mydiseasevars <- DiseaseVars(transition_rates = transitions)
#'
#' # Add vertical transmission from infected mothers:
#' mydiseasevars$initial_conditions_offspring <- "Vertical;0.3"
#'
#' # Build from an existing DiseaseVars csv, overriding one column:
#' \dontrun{
#' mydiseasevars <- DiseaseVars(
#'   path = "otherfiles/disease/DiseaseVars_SIR.csv",
#'   start_disease = 5
#' )
#' }
DiseaseVars <- function(
	n_states = "3",
	initial_conditions = "0.9;0.1;0.0",
	transition_rates = "otherfiles/disease/TransitionMatrix_SIR.csv",
	susceptible_states = "0",
	infection_states = "1",
	death_states = "N",
	initial_conditions_offspring = "Susceptible",
	start_disease = "0",
	transmission_mode = "Direct",
	disease_resistant = "N",
	disease_tolerant = "N",
	path = NULL
) {
	# See ClassVars()'s wrapper function for why these literal defaults are
	# forwarded as NULL to .DiseaseVarsR6$new() when not actually supplied by
	# the caller (the literals exist so they show up in tooltips/help).
	this_env <- environment()
	supplied <- vapply(.dv_fields, function(field) {
		!eval(substitute(missing(x), list(x = as.name(field))), envir = this_env)
	}, logical(1))
	names(supplied) <- .dv_fields

	# Build from an existing csv, then apply any explicitly supplied columns as
	# overrides. Overrides go through the active bindings, so they are
	# validated exactly like a later `$` assignment -- which means a single
	# override that is inconsistent with the file warns rather than errors, and
	# the object is re-checked strictly below.
	if (!is.null(path)) {
		if (!is.character(path) || length(path) != 1 || is.na(path) || !file.exists(path)) {
			stop("`path` must be the path to an existing DiseaseVars csv file.", call. = FALSE)
		}
		obj <- .read_diseasevars_csv(path)
		for (field in .dv_fields[supplied]) {
			obj[[field]] <- get(field, envir = this_env, inherits = FALSE)
		}
		if (any(supplied)) obj$check()
		return(obj)
	}

	# A file path passed positionally lands in `n_states`; point to `path =`.
	if (is.character(n_states) && is.na(suppressWarnings(as.numeric(n_states)))) {
		stop("`n_states` must be a single whole number (the number of disease compartments). To build a DiseaseVars object from an existing csv, use `DiseaseVars(path = ...)`.",
			call. = FALSE)
	}

	column_args <- mget(.dv_fields, envir = environment())
	column_args[!supplied] <- list(NULL)

	do.call(.DiseaseVarsR6$new, column_args)
}
