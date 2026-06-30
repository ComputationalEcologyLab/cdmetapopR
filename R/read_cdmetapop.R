# Read an existing CDMetaPOP input file (csv) into the corresponding R6
# object. Unlike the `add_rows()` generic in generics.R, this is not a
# UseMethod()-dispatched generic -- there is no object yet to dispatch on,
# since building one is the whole point -- so `type` is a plain string
# argument, switched on internally. Add one new `if (type == "...")`
# branch (and one `.read_<classname>_csv()` helper) here as each new
# input-file class is implemented.

#' Read an existing CDMetaPOP input file into an R6 object
#'
#' @param filepath Path to an existing CDMetaPOP input csv.
#' @param type Which input file type `filepath` is. One of `"RunVars"`
#'   (the default), `"PopVars"`, `"PatchVars"`, or `"ClassVars"`.
#'   Case-insensitive.
#'
#' @return An R6 object of the corresponding class (e.g. a [RunVars()]
#'   object).
#' @export
#'
#' @examples
#' \dontrun{
#' myrunvars <- read_cdmetapop("RunVars.csv", type = "RunVars")
#' mypopvars <- read_cdmetapop("popvars/PopVars.csv", type = "PopVars")
#' mypatchvars <- read_cdmetapop("patchvars/PatchVarsS1.csv", type = "PatchVars")
#' myclassvars <- read_cdmetapop("classvars/ClassVars_AS1.csv", type = "ClassVars")
#' }
read_cdmetapop <- function(filepath, type = "RunVars") {
	type <- tolower(type)
	if (type == "runvars") {
		return(.read_runvars_csv(filepath))
	}
	if (type == "popvars") {
		return(.read_popvars_csv(filepath))
	}
	if (type == "patchvars") {
		return(.read_patchvars_csv(filepath))
	}
	if (type == "classvars") {
		return(.read_classvars_csv(filepath))
	}
	stop(sprintf(
		"Unsupported `type` \"%s\". Supported types are \"RunVars\", \"PopVars\", \"PatchVars\", and \"ClassVars\".",
		type
	))
}

# Read a ClassVars.csv file into a ClassVars object. Columns are read as
# plain character and matched to ClassVars() arguments by *position*, not
# by header text -- CDMetaPOP itself does not read these headers as keys
# (see the note at the top of class_classvars.R), so a file's header row
# is never relied on here either. Each column is then validated exactly
# as if the user had typed it into ClassVars() directly, since it is
# passed straight through to that constructor.
.read_classvars_csv <- function(filepath) {
	raw <- utils::read.csv(
		filepath, colClasses = "character", check.names = FALSE,
		stringsAsFactors = FALSE
	)

	if (ncol(raw) != length(.cv_headers)) {
		stop(sprintf(
			"\"%s\" has %d columns; expected %d (one 'Age class' column plus the %d ClassVars columns, in CDMetaPOP's expected order).",
			filepath, ncol(raw), length(.cv_headers), length(.cv_fields)
		))
	}

	ages <- as.integer(raw[[1]])
	column_args <- stats::setNames(
		lapply(seq_along(.cv_fields), function(i) raw[[i + 1]]),
		.cv_fields
	)

	do.call(ClassVars, c(list(ages = ages), column_args))
}

# Read a PatchVars.csv file into a PatchVars object. Columns are read as
# plain character and matched to PatchVars() arguments by *position*, for
# the same reason as .read_classvars_csv() above. The "Class Vars" column
# is passed through as-is (a literal path, or ';'/'|'-separated multiple
# paths) -- resolve_class_vars = FALSE below disables PatchVars()'s usual
# .GlobalEnv name-resolution for this column, since a value read from an
# existing csv is always a path, never a reference to some ClassVars
# object that happens to be sitting in the current R session. It is not
# otherwise resolved into a nested ClassVars object here; do that
# explicitly afterward via read_cdmetapop(..., type = "ClassVars") if
# needed.
.read_patchvars_csv <- function(filepath) {
	raw <- utils::read.csv(
		filepath, colClasses = "character", check.names = FALSE,
		stringsAsFactors = FALSE
	)

	if (ncol(raw) != length(.pv_headers)) {
		stop(sprintf(
			"\"%s\" has %d columns; expected %d (one 'PatchID' column plus the %d PatchVars columns, in CDMetaPOP's expected order).",
			filepath, ncol(raw), length(.pv_headers), length(.pv_fields)
		))
	}

	patch_id <- as.integer(raw[[1]])
	column_args <- stats::setNames(
		lapply(seq_along(.pv_fields), function(i) raw[[i + 1]]),
		.pv_fields
	)

	do.call(PatchVars, c(
		list(patch_id = patch_id, resolve_class_vars = FALSE),
		column_args
	))
}

# Read a PopVars.csv file into a PopVars object. UNLIKE .read_classvars_csv()/
# .read_patchvars_csv() above, columns are matched by header *name*, not
# position -- CDMetaPOP itself reads PopVars.csv headers as dictionary
# keys (see the note at the top of class_popvars.R), so a file claiming to
# be a PopVars.csv but with columns out of order, missing, or misspelled
# would not actually run correctly in CDMetaPOP either; matching by name
# here surfaces that mismatch immediately instead of silently
# misattributing column values. `xyfilename` is passed through as a
# literal path (resolve_xyfilename = FALSE), the same rationale as
# .read_patchvars_csv()'s `resolve_class_vars = FALSE` -- a value read from
# an existing csv is always a path, never a reference to some PatchVars
# object sitting in the current R session.
.read_popvars_csv <- function(filepath) {
	raw <- utils::read.csv(
		filepath, colClasses = "character", check.names = FALSE,
		stringsAsFactors = FALSE
	)

	missing_cols <- setdiff(.popv_fields, colnames(raw))
	extra_cols <- setdiff(colnames(raw), .popv_fields)
	if (length(missing_cols) > 0 || length(extra_cols) > 0) {
		stop(sprintf(
			"\"%s\" does not have the expected PopVars.csv columns.%s%s",
			filepath,
			if (length(missing_cols) > 0) sprintf(" Missing: %s.", paste(missing_cols, collapse = ", ")) else "",
			if (length(extra_cols) > 0) sprintf(" Unexpected: %s.", paste(extra_cols, collapse = ", ")) else ""
		))
	}

	n_batches <- nrow(raw)
	column_args <- stats::setNames(
		lapply(.popv_fields, function(field) raw[[field]]),
		.popv_fields
	)

	do.call(PopVars, c(
		list(n_batches = n_batches, resolve_xyfilename = FALSE),
		column_args
	))
}

# Read a RunVars.csv file into a RunVars object. Like .read_popvars_csv()
# (and unlike .read_classvars_csv()/.read_patchvars_csv()), columns are
# matched by header *name*, not position -- CDMetaPOP reads RunVars.csv
# headers as dictionary keys (see the note at the top of class_runvars.R).
# `Popvars` is passed through as a literal path (resolve_popvars = FALSE),
# the same rationale as .read_popvars_csv()'s `resolve_xyfilename = FALSE` --
# a value read from an existing csv is always a path, never a reference to
# some PopVars object sitting in the current R session.
.read_runvars_csv <- function(filepath) {
	raw <- utils::read.csv(
		filepath, colClasses = "character", check.names = FALSE,
		stringsAsFactors = FALSE
	)

	missing_cols <- setdiff(.rv_fields, colnames(raw))
	extra_cols <- setdiff(colnames(raw), .rv_fields)
	if (length(missing_cols) > 0 || length(extra_cols) > 0) {
		stop(sprintf(
			"\"%s\" does not have the expected RunVars.csv columns.%s%s",
			filepath,
			if (length(missing_cols) > 0) sprintf(" Missing: %s.", paste(missing_cols, collapse = ", ")) else "",
			if (length(extra_cols) > 0) sprintf(" Unexpected: %s.", paste(extra_cols, collapse = ", ")) else ""
		))
	}

	n_runs <- nrow(raw)
	column_args <- stats::setNames(
		lapply(.rv_fields, function(field) raw[[field]]),
		.rv_fields
	)

	do.call(RunVars, c(
		list(n_runs = n_runs, resolve_popvars = FALSE),
		column_args
	))
}
