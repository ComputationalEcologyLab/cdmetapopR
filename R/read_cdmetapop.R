# Read an existing CDMetaPOP input file (csv) into the corresponding R6
# object. Unlike write_cdmetapop()/add_rows() in generics.R, this is not a
# UseMethod()-dispatched generic -- there is no object yet to dispatch on,
# since building one is the whole point -- so `type` is a plain string
# argument, switched on internally. Add one new `if (type == "...")`
# branch (and one `.read_<classname>_csv()` helper) here as each new
# class (PatchVars, PopVars, RunVars, ...) is implemented.

#' Read an existing CDMetaPOP input file into an R6 object
#'
#' @param filepath Path to an existing CDMetaPOP input csv.
#' @param type Which input file type `filepath` is. Currently `"ClassVars"`
#'   and `"PatchVars"` are supported. Case-insensitive.
#'
#' @return An R6 object of the corresponding class (e.g. a [ClassVars()]
#'   object), with `location` set to `filepath`.
#' @export
#'
#' @examples
#' \dontrun{
#' myclassvars <- read_cdmetapop("classvars/ClassVars_AS1.csv", type = "ClassVars")
#' mypatchvars <- read_cdmetapop("patchvars/PatchVarsS1.csv", type = "PatchVars")
#' }
read_cdmetapop <- function(filepath, type = "ClassVars") {
	type <- tolower(type)
	if (type == "classvars") {
		return(.read_classvars_csv(filepath))
	}
	if (type == "patchvars") {
		return(.read_patchvars_csv(filepath))
	}
	stop(sprintf(
		"Unsupported `type` \"%s\". Currently \"ClassVars\" and \"PatchVars\" are supported.",
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

	do.call(ClassVars, c(list(ages = ages, location = filepath), column_args))
}

# Read a PatchVars.csv file into a PatchVars object. Columns are read as
# plain character and matched to PatchVars() arguments by *position*, for
# the same reason as .read_classvars_csv() above. The "Class Vars" column
# is passed through as a character path (or ';'-separated paths) -- it is
# not resolved into a nested ClassVars object here; do that explicitly
# afterward via read_cdmetapop(..., type = "ClassVars") if needed.
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

	do.call(PatchVars, c(list(patch_id = patch_id, location = filepath), column_args))
}
