# ClassVars: R6 wrapper for CDMetaPOP's ClassVars.csv input file.
#
# A ClassVars.csv file holds one row per age/size class, with one column
# per class-level parameter (mortality, migration, fecundity, etc.). This
# class stores that table internally as a data frame, but exposes each
# *column* as an R6 active binding (e.g. `myclassvars$maturation <- ...`)
# rather than exposing rows, because users are expected to edit and rerun
# whole parameter columns (e.g. a mortality schedule), not individual
# age-class rows. CDMetaPOP itself does not read the csv header text as
# keys -- only column *order* matters at read time -- so the headers below
# exist purely for human readability of the written file, and are copied
# verbatim (including a spelling inconsistency) from
# example_files/classvars/ClassVars_AS1.csv, the package's canonical
# example.
#
# Good practice: keep ClassVars csv files in their own subdirectory (e.g.
# classvars/), separate from other file types -- this is just good
# organizational hygiene, and also avoids a file's path ever coincidentally
# matching the name of a ClassVars object in your R session (see
# PatchVars()'s Details on `class_vars` name resolution).

# Canonical column headers, in CDMetaPOP's expected order. "Age class" is
# handled separately from the other columns (see `ages` active binding
# below), since it is immutable after construction and drives the row
# count for every other column.
.cv_headers <- c(
	"Age class", "Body Size Mean", "Body Size Std", "Distribution",
	"Sex Ratio", "Age Mortality Out", "Age Mortality Out StDev",
	"Age Mortality Back", "Age Mortality Back StDev",
	"Size Mortality Out", "Size Mortality Out StDev",
	"Size Mortality Back", "Size Mortaltiy Back StDev",
	"Migration Out Prob", "Migration Back Prob", "Straying Prob",
	"Dispersal Prob", "Maturation", "Fecundity Ind", "Fecundity Ind StDev",
	"Fecundity Leslie", "Fecundity Leslie StDev", "Capture Out Probability",
	"Capture Back Probability"
)

# snake_case field names, in the same order as `.cv_headers[-1]` (i.e.
# excluding "Age class"). These are the names used for ClassVars()
# constructor arguments, active bindings, and validation rules below.
.cv_fields <- c(
	"body_size_mean", "body_size_std", "distribution", "sex_ratio",
	"age_mortality_out", "age_mortality_out_stdev",
	"age_mortality_back", "age_mortality_back_stdev",
	"size_mortality_out", "size_mortality_out_stdev",
	"size_mortality_back", "size_mortality_back_stdev",
	"migration_out_prob", "migration_back_prob", "straying_prob",
	"dispersal_prob", "maturation", "fecundity_ind", "fecundity_ind_stdev",
	"fecundity_leslie", "fecundity_leslie_stdev", "capture_out_prob",
	"capture_back_prob"
)

# Default values taken from example_files/classvars/ClassVars_AS1.csv (the
# basic example referenced by this package's default RunVars.csv /
# PatchVars.csv pair), one 6-element vector per column, indexed by age
# class (age 0 is element 1, age 1 is element 2, etc.). Used by
# .cv_default_for() to fill in any column a user does not specify at
# construction.
.cv_as1_defaults <- list(
	body_size_mean            = c(31, 53, 92, 123, 147, 184),
	body_size_std             = c(0, 5, 0, 10, 10, 10),
	distribution              = c(0.5, 0.25, 0.125, 0.0625, 0.03, 0.015),
	sex_ratio                 = rep(".50~.50", 6),
	age_mortality_out         = rep("N", 6),
	age_mortality_out_stdev   = rep(0, 6),
	age_mortality_back        = c(0, 0, 0, 0, 0, 1),
	age_mortality_back_stdev  = rep(0, 6),
	size_mortality_out        = rep(0, 6),
	size_mortality_out_stdev  = rep(0, 6),
	size_mortality_back       = rep(0, 6),
	size_mortality_back_stdev = rep(0, 6),
	migration_out_prob        = c(0, 0.1, 0.3, 0.5, 1, 1),
	migration_back_prob       = rep(1, 6),
	straying_prob             = rep(0.2, 6),
	dispersal_prob            = rep(0.2, 6),
	maturation                = c(0, 1, 1, 1, 1, 1),
	fecundity_ind             = c(0, 5, 5, 10, 10, 10),
	fecundity_ind_stdev       = rep(0, 6),
	fecundity_leslie          = c(0, 2.5, 10, 11.7, 11.743, 15),
	fecundity_leslie_stdev    = rep(0, 6),
	capture_out_prob          = rep("N", 6),
	capture_back_prob         = rep("N", 6)
)

# Validation rule for each column, per CDMetaPOP's user manual (section
# 3.4, "Class level controls - ClassVars.csv file") and clarified per-field
# during development. Each value supplied for a column must be one of:
#   - a bare number within [lower, upper] (NA bound = unbounded), or
#   - the literal string "N" (CDMetaPOP's "turned off" value), if allow_N
#     is TRUE, or
#   - 2-4 "~"-separated numbers (one per sex: FXX~MXY~MYY~FYY), each within
#     [lower, upper], if allow_tilde is TRUE
# sum_to_one additionally requires "~"-separated parts to sum to 1
# (currently only true for Sex Ratio; not a general rule for this file
# type, and not assumed to carry over to other CDMetaPOP input files).
.cv_rules <- list(
	body_size_mean            = list(lower = -Inf, upper = Inf, allow_N = FALSE, allow_tilde = FALSE, sum_to_one = FALSE),
	body_size_std             = list(lower = -Inf, upper = Inf, allow_N = FALSE, allow_tilde = FALSE, sum_to_one = FALSE),
	distribution              = list(lower = 0,    upper = 1,   allow_N = FALSE, allow_tilde = FALSE, sum_to_one = FALSE),
	sex_ratio                 = list(lower = 0,    upper = 1,   allow_N = FALSE, allow_tilde = TRUE,  sum_to_one = TRUE),
	age_mortality_out         = list(lower = 0,    upper = 1,   allow_N = TRUE,  allow_tilde = TRUE,  sum_to_one = FALSE),
	age_mortality_out_stdev   = list(lower = 0,    upper = Inf, allow_N = TRUE,  allow_tilde = TRUE,  sum_to_one = FALSE),
	age_mortality_back        = list(lower = 0,    upper = 1,   allow_N = TRUE,  allow_tilde = TRUE,  sum_to_one = FALSE),
	age_mortality_back_stdev  = list(lower = 0,    upper = Inf, allow_N = TRUE,  allow_tilde = TRUE,  sum_to_one = FALSE),
	size_mortality_out        = list(lower = 0,    upper = 1,   allow_N = TRUE,  allow_tilde = TRUE,  sum_to_one = FALSE),
	size_mortality_out_stdev  = list(lower = 0,    upper = Inf, allow_N = TRUE,  allow_tilde = TRUE,  sum_to_one = FALSE),
	size_mortality_back       = list(lower = 0,    upper = 1,   allow_N = TRUE,  allow_tilde = TRUE,  sum_to_one = FALSE),
	size_mortality_back_stdev = list(lower = 0,    upper = Inf, allow_N = TRUE,  allow_tilde = TRUE,  sum_to_one = FALSE),
	migration_out_prob        = list(lower = 0,    upper = 1,   allow_N = TRUE,  allow_tilde = TRUE,  sum_to_one = FALSE),
	migration_back_prob       = list(lower = 0,    upper = 1,   allow_N = TRUE,  allow_tilde = TRUE,  sum_to_one = FALSE),
	straying_prob             = list(lower = 0,    upper = 1,   allow_N = TRUE,  allow_tilde = TRUE,  sum_to_one = FALSE),
	dispersal_prob            = list(lower = 0,    upper = 1,   allow_N = TRUE,  allow_tilde = TRUE,  sum_to_one = FALSE),
	maturation                = list(lower = 0,    upper = 1,   allow_N = TRUE,  allow_tilde = TRUE,  sum_to_one = FALSE),
	fecundity_ind             = list(lower = -Inf, upper = Inf, allow_N = FALSE, allow_tilde = FALSE, sum_to_one = FALSE),
	fecundity_ind_stdev       = list(lower = -Inf, upper = Inf, allow_N = FALSE, allow_tilde = FALSE, sum_to_one = FALSE),
	fecundity_leslie          = list(lower = -Inf, upper = Inf, allow_N = FALSE, allow_tilde = FALSE, sum_to_one = FALSE),
	fecundity_leslie_stdev    = list(lower = -Inf, upper = Inf, allow_N = FALSE, allow_tilde = FALSE, sum_to_one = FALSE),
	capture_out_prob          = list(lower = 0,    upper = 1,   allow_N = TRUE,  allow_tilde = TRUE,  sum_to_one = FALSE),
	capture_back_prob         = list(lower = 0,    upper = 1,   allow_N = TRUE,  allow_tilde = TRUE,  sum_to_one = FALSE)
)

#' Validate and normalize one ClassVars column
#'
#' Internal helper used by every ClassVars active binding. Validation
#' happens here, at assignment time in R, rather than being deferred to
#' CDMetaPOP -- the goal is to catch malformed input before it is ever
#' written to a csv or handed to Python.
#'
#' @param field snake_case column name (must be in `.cv_fields`).
#' @param values Vector of values to validate; recycled to length `n` if
#'   it has length 1.
#' @param n Expected length (the number of age classes already defined on
#'   the object).
#' @return A validated vector of length `n`: numeric if the column's rule
#'   forbids `"N"`/`"~"` values, character otherwise (since `"N"` and
#'   `"~"`-joined values cannot be stored as numeric).
#' @keywords internal
.validate_cv_field <- function(field, values, n) {
	rule <- .cv_rules[[field]]
	if (length(values) == 1) values <- rep(values, n)
	if (length(values) != n) {
		stop(sprintf(
			"`%s` must have length 1 or %d (the number of age classes), not %d.",
			field, n, length(values)
		))
	}

	# Character storage is only needed when "N"/"~" values are permitted;
	# otherwise keep the column numeric for downstream arithmetic.
	as_character_storage <- rule$allow_N || rule$allow_tilde
	out <- vector(if (as_character_storage) "character" else "numeric", n)

	for (i in seq_len(n)) {
		val <- values[i]

		if (rule$allow_N && identical(as.character(val), "N")) {
			out[i] <- "N"
			next
		}

		if (rule$allow_tilde && is.character(val) && grepl("~", val, fixed = TRUE)) {
			parts <- suppressWarnings(as.numeric(strsplit(val, "~", fixed = TRUE)[[1]]))
			if (any(is.na(parts)) || length(parts) < 2 || length(parts) > 4) {
				stop(sprintf(
					"`%s`[%d] = \"%s\" is not a valid '~'-separated value (need 2-4 numeric parts, e.g. FXX~MXY~MYY~FYY).",
					field, i, val
				))
			}
			if (any(parts < rule$lower | parts > rule$upper)) {
				stop(sprintf(
					"`%s`[%d] = \"%s\" has a part outside the allowed range [%s, %s].",
					field, i, val, rule$lower, rule$upper
				))
			}
			if (rule$sum_to_one && !isTRUE(all.equal(sum(parts), 1))) {
				stop(sprintf(
					"`%s`[%d] = \"%s\" must have parts summing to 1.", field, i, val
				))
			}
			out[i] <- val
			next
		}

		num <- suppressWarnings(as.numeric(val))
		if (is.na(num)) {
			stop(sprintf(
				"`%s`[%d] = \"%s\" is not a valid value (expected a number%s%s).",
				field, i, val,
				if (rule$allow_N) ", \"N\"" else "",
				if (rule$allow_tilde) ", or 2-4 '~'-separated numbers" else ""
			))
		}
		if (num < rule$lower || num > rule$upper) {
			stop(sprintf(
				"`%s`[%d] = %s is outside the allowed range [%s, %s].",
				field, i, num, rule$lower, rule$upper
			))
		}
		if (rule$sum_to_one && !isTRUE(all.equal(num, 1))) {
			stop(sprintf(
				"`%s`[%d] = %s must equal 1 when given as a single (non-'~') value.",
				field, i, num
			))
		}
		out[i] <- if (as_character_storage) as.character(num) else num
	}

	out
}

#' Default values for one ClassVars column, for a given set of age classes
#'
#' Looks up `.cv_as1_defaults` by age-class index. Age classes beyond what
#' ClassVarsAS1.csv defines (i.e. above age 5) have no principled default,
#' so the last defined default (age 5) is recycled, with a warning.
#'
#' @keywords internal
.cv_default_for <- function(field, ages) {
	defaults <- .cv_as1_defaults[[field]]
	n <- length(ages)
	if (n <= length(defaults)) return(defaults[ages + 1])

	# Recycle the last (age-5) default silently; the caller (initialize())
	# is responsible for emitting a single warning covering all affected
	# columns, rather than warning once per column here.
	c(defaults, rep(defaults[length(defaults)], n - length(defaults)))
}

# The R6 generator itself is not exported; users construct instances via
# the ClassVars() wrapper function below, which calls .ClassVarsR6$new().
# This keeps the public-facing constructor call as `ClassVars(...)` rather
# than the more verbose R6 convention of `ClassVars$new(...)`.
#
# Wrapped in local() so the call is not a top-level `<- R6::R6Class(...)`
# assignment: roxygen2's automatic R6 documentation support matches that
# exact pattern unconditionally (regardless of @noRd or absence of any
# roxygen comment) and would otherwise demand a fully-documented topic for
# every one of this class's 25 internal active bindings/methods.

#' @noRd
.ClassVarsR6 <- local(R6::R6Class("ClassVars",
	public = list(
		initialize = function(
			ages = 0:5,
			body_size_mean = NULL, body_size_std = NULL, distribution = NULL,
			sex_ratio = NULL, age_mortality_out = NULL, age_mortality_out_stdev = NULL,
			age_mortality_back = NULL, age_mortality_back_stdev = NULL,
			size_mortality_out = NULL, size_mortality_out_stdev = NULL,
			size_mortality_back = NULL, size_mortality_back_stdev = NULL,
			migration_out_prob = NULL, migration_back_prob = NULL,
			straying_prob = NULL, dispersal_prob = NULL, maturation = NULL,
			fecundity_ind = NULL, fecundity_ind_stdev = NULL,
			fecundity_leslie = NULL, fecundity_leslie_stdev = NULL,
			capture_out_prob = NULL, capture_back_prob = NULL
		) {
			# `ages` must be sequential integers starting at 0, e.g. 0:5 or
			# c(0, 1, 2). This is the only field validated once and then
			# blocked from reassignment (see the `ages` active binding) --
			# changing the number of age classes is handled via
			# add_row(), not by re-setting `ages` directly.
			if (!is.numeric(ages) || anyNA(ages) ||
					!identical(as.numeric(ages), as.numeric(seq(0, length(ages) - 1)))) {
				stop("`ages` must be sequential integers starting at 0 (e.g. 0:5 or c(0, 1, 2)).")
			}
			ages <- as.integer(ages)
			n <- length(ages)

			# Collect the user-supplied column arguments by name so they can
			# be looped over alongside `.cv_fields` below, rather than
			# writing out 23 near-identical "if not supplied, use default"
			# blocks by hand.
			supplied <- list(
				body_size_mean = body_size_mean, body_size_std = body_size_std,
				distribution = distribution, sex_ratio = sex_ratio,
				age_mortality_out = age_mortality_out, age_mortality_out_stdev = age_mortality_out_stdev,
				age_mortality_back = age_mortality_back, age_mortality_back_stdev = age_mortality_back_stdev,
				size_mortality_out = size_mortality_out, size_mortality_out_stdev = size_mortality_out_stdev,
				size_mortality_back = size_mortality_back, size_mortality_back_stdev = size_mortality_back_stdev,
				migration_out_prob = migration_out_prob, migration_back_prob = migration_back_prob,
				straying_prob = straying_prob, dispersal_prob = dispersal_prob, maturation = maturation,
				fecundity_ind = fecundity_ind, fecundity_ind_stdev = fecundity_ind_stdev,
				fecundity_leslie = fecundity_leslie, fecundity_leslie_stdev = fecundity_leslie_stdev,
				capture_out_prob = capture_out_prob, capture_back_prob = capture_back_prob
			)

			private$data <- as.data.frame(matrix(nrow = n, ncol = length(.cv_headers)))
			colnames(private$data) <- .cv_headers
			private$data[["Age class"]] <- ages

			# ClassVarsAS1.csv only defines defaults for ages 0-5. If more
			# age classes are requested and any column is left unspecified,
			# warn once (not once per column) that the age-5 default is
			# being recycled for those extra age classes.
			max_default_age <- length(.cv_as1_defaults[[1]]) - 1
			any_unspecified <- any(vapply(supplied, is.null, logical(1)))
			if (n > max_default_age + 1 && any_unspecified) {
				warning(sprintf(
					"No default values exist in ClassVarsAS1.csv for age classes above %d; the age-%d default is being recycled for any unspecified column on the extra age classes.",
					max_default_age, max_default_age
				), call. = FALSE)
			}

			for (field in .cv_fields) {
				raw <- supplied[[field]]
				if (is.null(raw)) raw <- .cv_default_for(field, ages)
				header <- .cv_headers[match(field, .cv_fields) + 1]
				private$data[[header]] <- private$validate(field, raw)
			}
		},

		# Add one or more age classes, copying the current last row. All
		# new rows are initialized as a copy of the current oldest (last)
		# age class; edit the new row(s) afterward via the column active
		# bindings. See plan.md "Parking Lot" for a possible future
		# per-column override argument. (Documented for users on the
		# ClassVars() wrapper function below, not here -- see note above
		# the .ClassVarsR6 assignment on why these are plain comments.)
		add_row = function(n = 1) {
			last_row <- private$data[nrow(private$data), , drop = FALSE]
			new_rows <- last_row[rep(1, n), , drop = FALSE]
			new_rows[["Age class"]] <- seq(max(private$data[["Age class"]]) + 1, length.out = n)
			private$data <- rbind(private$data, new_rows)
			# Repeated single-row subsetting above (rep(1, n)) leaves
			# R's auto-generated row names mangled (e.g. "61" instead of
			# a clean sequential label) when the original row names are
			# plain digit strings; row names carry no meaning here (the
			# "Age class" column is the real identifier), so just reset
			# them to plain sequential defaults.
			rownames(private$data) <- NULL
			invisible(self)
		},


		print = function(...) {
			cat("<ClassVars>", nrow(private$data), "age classes\n")
			print(private$data)
			invisible(self)
		},

		# Returns a plain (independent) copy of the underlying table, for
		# viewing/inspection -- e.g. via View(cv$as_data_frame()) or the
		# as.data.frame.ClassVars() S3 method in generics.R. A copy, not a
		# reference, so editing the returned data frame never mutates this
		# object; edits still have to go through the column active
		# bindings to get validated.
		as_data_frame = function() private$data
	),

	private = list(
		data = NULL,

		# Shared by every column active binding: validates `values` against
		# `field`'s rule and the current number of age classes.
		validate = function(field, values) {
			.validate_cv_field(field, values, nrow(private$data))
		}
	),

	active = list(
		ages = function(value) {
			if (missing(value)) return(private$data[["Age class"]])
			stop("`ages` cannot be reassigned after construction; create a new ClassVars() object (or use add_row()) instead.")
		},
		body_size_mean = function(value) {
			if (missing(value)) return(private$data[["Body Size Mean"]])
			private$data[["Body Size Mean"]] <- private$validate("body_size_mean", value)
		},
		body_size_std = function(value) {
			if (missing(value)) return(private$data[["Body Size Std"]])
			private$data[["Body Size Std"]] <- private$validate("body_size_std", value)
		},
		distribution = function(value) {
			if (missing(value)) return(private$data[["Distribution"]])
			private$data[["Distribution"]] <- private$validate("distribution", value)
		},
		sex_ratio = function(value) {
			if (missing(value)) return(private$data[["Sex Ratio"]])
			private$data[["Sex Ratio"]] <- private$validate("sex_ratio", value)
		},
		age_mortality_out = function(value) {
			if (missing(value)) return(private$data[["Age Mortality Out"]])
			private$data[["Age Mortality Out"]] <- private$validate("age_mortality_out", value)
		},
		age_mortality_out_stdev = function(value) {
			if (missing(value)) return(private$data[["Age Mortality Out StDev"]])
			private$data[["Age Mortality Out StDev"]] <- private$validate("age_mortality_out_stdev", value)
		},
		age_mortality_back = function(value) {
			if (missing(value)) return(private$data[["Age Mortality Back"]])
			private$data[["Age Mortality Back"]] <- private$validate("age_mortality_back", value)
		},
		age_mortality_back_stdev = function(value) {
			if (missing(value)) return(private$data[["Age Mortality Back StDev"]])
			private$data[["Age Mortality Back StDev"]] <- private$validate("age_mortality_back_stdev", value)
		},
		size_mortality_out = function(value) {
			if (missing(value)) return(private$data[["Size Mortality Out"]])
			private$data[["Size Mortality Out"]] <- private$validate("size_mortality_out", value)
		},
		size_mortality_out_stdev = function(value) {
			if (missing(value)) return(private$data[["Size Mortality Out StDev"]])
			private$data[["Size Mortality Out StDev"]] <- private$validate("size_mortality_out_stdev", value)
		},
		size_mortality_back = function(value) {
			if (missing(value)) return(private$data[["Size Mortality Back"]])
			private$data[["Size Mortality Back"]] <- private$validate("size_mortality_back", value)
		},
		size_mortality_back_stdev = function(value) {
			if (missing(value)) return(private$data[["Size Mortaltiy Back StDev"]])
			private$data[["Size Mortaltiy Back StDev"]] <- private$validate("size_mortality_back_stdev", value)
		},
		migration_out_prob = function(value) {
			if (missing(value)) return(private$data[["Migration Out Prob"]])
			private$data[["Migration Out Prob"]] <- private$validate("migration_out_prob", value)
		},
		migration_back_prob = function(value) {
			if (missing(value)) return(private$data[["Migration Back Prob"]])
			private$data[["Migration Back Prob"]] <- private$validate("migration_back_prob", value)
		},
		straying_prob = function(value) {
			if (missing(value)) return(private$data[["Straying Prob"]])
			private$data[["Straying Prob"]] <- private$validate("straying_prob", value)
		},
		dispersal_prob = function(value) {
			if (missing(value)) return(private$data[["Dispersal Prob"]])
			private$data[["Dispersal Prob"]] <- private$validate("dispersal_prob", value)
		},
		maturation = function(value) {
			if (missing(value)) return(private$data[["Maturation"]])
			private$data[["Maturation"]] <- private$validate("maturation", value)
		},
		fecundity_ind = function(value) {
			if (missing(value)) return(private$data[["Fecundity Ind"]])
			private$data[["Fecundity Ind"]] <- private$validate("fecundity_ind", value)
		},
		fecundity_ind_stdev = function(value) {
			if (missing(value)) return(private$data[["Fecundity Ind StDev"]])
			private$data[["Fecundity Ind StDev"]] <- private$validate("fecundity_ind_stdev", value)
		},
		fecundity_leslie = function(value) {
			if (missing(value)) return(private$data[["Fecundity Leslie"]])
			private$data[["Fecundity Leslie"]] <- private$validate("fecundity_leslie", value)
		},
		fecundity_leslie_stdev = function(value) {
			if (missing(value)) return(private$data[["Fecundity Leslie StDev"]])
			private$data[["Fecundity Leslie StDev"]] <- private$validate("fecundity_leslie_stdev", value)
		},
		capture_out_prob = function(value) {
			if (missing(value)) return(private$data[["Capture Out Probability"]])
			private$data[["Capture Out Probability"]] <- private$validate("capture_out_prob", value)
		},
		capture_back_prob = function(value) {
			if (missing(value)) return(private$data[["Capture Back Probability"]])
			private$data[["Capture Back Probability"]] <- private$validate("capture_back_prob", value)
		}
	)
))

#' Create a ClassVars object
#'
#' Constructs an R6 object representing a CDMetaPOP `ClassVars.csv` input
#' file: one row per age/size class, with one column per class-level
#' parameter (mortality, migration, fecundity, etc.). Columns are edited as
#' a whole after construction via `$`, e.g.
#' `myclassvars$age_mortality_out <- c(0, 0, 0.5)`.
#'
#' Any column argument left as `NULL` defaults to the corresponding values
#' in `example_files/classvars/ClassVarsAS1.csv`, matched to each requested
#' age class (recycling the age-5 default, with a warning, for age classes
#' beyond what that file defines).
#'
#' @param ages Integer vector of sequential age classes starting at 0
#'   (e.g. `0:5`). Determines the number of rows; cannot be changed after
#'   construction (use `add_row()` or [add_rows()] instead).
#' @param body_size_mean,body_size_std Mean and standard deviation of body
#'   size (units chosen by the user) at initialization, per age class.
#' @param distribution Proportion of the population distributed to each
#'   age class at initialization. Each value in `[0, 1]`; does not need to
#'   sum to 1.
#' @param sex_ratio Sex ratio per age class, as a `"~"`-separated string of
#'   2-4 values (order: `FXX~MXY~MYY~FYY`) that must sum to 1, e.g.
#'   `".5~.5"`.
#' @param age_mortality_out,age_mortality_back Age-specific mortality
#'   probability `[0, 1]` applied out of/back to the natal patch; or
#'   `"N"`; or `"~"`-separated per-sex values.
#' @param age_mortality_out_stdev,age_mortality_back_stdev Standard
#'   deviation for the above; numeric, `"N"`, or `"~"`-separated.
#' @param size_mortality_out,size_mortality_back Size-specific mortality
#'   probability `[0, 1]`, `"N"`, or `"~"`-separated per-sex values.
#' @param size_mortality_out_stdev,size_mortality_back_stdev Standard
#'   deviation for the above; numeric, `"N"`, or `"~"`-separated.
#' @param migration_out_prob,migration_back_prob,straying_prob,dispersal_prob
#'   Movement probabilities `[0, 1]`, `"N"`, or `"~"`-separated per-sex
#'   values.
#' @param maturation Probability `[0, 1]` of being/becoming reproductively
#'   mature; or `"N"`; or `"~"`-separated per-sex values.
#' @param fecundity_ind,fecundity_ind_stdev Mean and standard deviation of
#'   individual-based fecundity (litter/egg count) per age class.
#' @param fecundity_leslie,fecundity_leslie_stdev Mean and standard
#'   deviation of Leslie-matrix fecundity per age class.
#' @param capture_out_prob,capture_back_prob Capture/detection probability
#'   `[0, 1]`, `"N"`, or `"~"`-separated per-sex values.
#'
#' @return An R6 `ClassVars` object.
#' @export
#'
#' @examples
#' # Default 6-age-class object, matching ClassVarsAS1.csv:
#' myclassvars <- ClassVars()
#'
#' # 3 age classes, defaults taken from ClassVarsAS1.csv's first 3 rows:
#' myclassvars <- ClassVars(ages = c(0, 1, 2))
#'
#' # Edit a column in place:
#' myclassvars$age_mortality_out <- c(0, 0, 0.5)
#'
#' # Add an age class (copies the last row; edit afterward):
#' myclassvars$add_row()
#' # or equivalently:
#' add_rows(myclassvars)
ClassVars <- function(
	ages = 0:5,
	body_size_mean = c(31, 53, 92, 123, 147, 184),
	body_size_std = c(0, 5, 0, 10, 10, 10),
	distribution = c(0.5, 0.25, 0.125, 0.0625, 0.03, 0.015),
	sex_ratio = rep(".50~.50", 6),
	age_mortality_out = rep(0, 6),
	age_mortality_out_stdev = rep(0, 6),
	age_mortality_back = c(0, 0, 0, 0, 0, 1),
	age_mortality_back_stdev = rep(0, 6),
	size_mortality_out = rep(0, 6),
	size_mortality_out_stdev = rep(0, 6),
	size_mortality_back = rep(0, 6),
	size_mortality_back_stdev = rep(0, 6),
	migration_out_prob = c(0, 0.1, 0.3, 0.5, 1, 1),
	migration_back_prob = rep(1, 6),
	straying_prob = rep(0.2, 6),
	dispersal_prob = rep(0.2, 6),
	maturation = c(0, 1, 1, 1, 1, 1),
	fecundity_ind = c(0, 5, 5, 10, 10, 10),
	fecundity_ind_stdev = rep(0, 6),
	fecundity_leslie = c(0, 2.5, 10, 11.7, 11.743, 15),
	fecundity_leslie_stdev = rep(0, 6),
	capture_out_prob = rep("N", 6),
	capture_back_prob = rep("N", 6)
) {
	# The defaults above are shown literally (rather than NULL) purely so
	# that `?ClassVars` and IDE argument tooltips display the actual
	# ClassVarsAS1.csv values. Internally, though, any argument the caller
	# did not explicitly supply must still be forwarded to
	# .ClassVarsR6$new() as NULL, so its own default-resizing logic can
	# truncate/recycle that column to match the requested `ages` -- e.g.
	# ClassVars(ages = c(0, 1, 2)) should use just the first 3 AS1 rows,
	# not silently get 6 values back from this wrapper's own default.
	this_env <- environment()
	supplied <- vapply(.cv_fields, function(field) {
		!eval(substitute(missing(x), list(x = as.name(field))), envir = this_env)
	}, logical(1))
	names(supplied) <- .cv_fields

	column_args <- mget(.cv_fields, envir = environment())
	column_args[!supplied] <- list(NULL)

	do.call(.ClassVarsR6$new, c(list(ages = ages), column_args))
}
