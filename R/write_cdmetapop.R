# write_cdmetapop(): write a single cdmetapopR input-file object to a csv.
#
# A deliberately minimal convenience fallback. The normal route to input files
# is launch_cdmetapop(), whose graph-writer (R/write_inputfiles.R) names,
# places, and writes the whole object graph at launch (Key Design Decision 6).
# This function instead writes exactly ONE ClassVars, PatchVars, PopVars,
# RunVars, or DiseaseVars object to a file named by the caller, and never
# follows references: path strings are written verbatim, and any cell holding a
# live R object (an R6 object or a raw matrix) -- which has no file path to
# write -- is written as NA with a warning.

#' Write a cdmetapopR input-file object to a csv file
#'
#' Writes a single [ClassVars()], [PatchVars()], [PopVars()], [RunVars()], or
#' [DiseaseVars()] object to a csv file in CDMetaPOP's input format: the same
#' headers, column order, and unquoted values that [launch_cdmetapop()] writes.
#'
#' @details
#' This is a convenience for writing one object at a time. It is not needed to
#' run a simulation, since [launch_cdmetapop()] writes every input file
#' automatically. Only `x` itself is written:
#' * References stored as file paths (e.g. a `class_vars` value of
#'   `"classvars/ClassVars_AS1.csv"`, or a cost-distance matrix path) are
#'   written exactly as entered. They are not checked, and the files they point
#'   to are not written or copied.
#' * A reference cell holding a live R object -- a [PopVars()], [PatchVars()],
#'   [ClassVars()], or [DiseaseVars()] object, or a raw `matrix` -- has no file
#'   path to write, so that cell is written as `NA` and a warning lists the
#'   affected cells. To keep the reference, write that object or matrix to its
#'   own file first and assign its path instead.
#' * A [PatchVars()] object's eight disease columns are written only if at
#'   least one of them is set, matching the 50-or-58 column file CDMetaPOP
#'   expects (see [PatchVars()]).
#'
#' @param x A [ClassVars()], [PatchVars()], [PopVars()], [RunVars()], or
#'   [DiseaseVars()] object.
#' @param file File name or path of the csv to write. A bare file name (e.g.
#'   `"myclassvars.csv"`) is written to the working directory. Include the
#'   `.csv` extension. The containing directory must already exist.
#' @param overwrite If `FALSE` (the default), an existing file at `file` is not
#'   replaced and an error is raised instead. Set to `TRUE` to replace it.
#'
#' @return `file`, invisibly.
#' @export
#'
#' @examples
#' myclassvars <- ClassVars()
#' out <- file.path(tempdir(), "myclassvars.csv")
#' write_cdmetapop(myclassvars, file = out)
#'
#' # The written file can be read back in:
#' read_cdmetapop(out, type = "ClassVars")
write_cdmetapop <- function(x, file, overwrite = FALSE) {
	# Only the input-file classes are supported.
	if (!inherits(x, c("ClassVars", "PatchVars", "PopVars", "RunVars", "DiseaseVars"))) {
		stop("`x` must be a ClassVars, PatchVars, PopVars, RunVars, or DiseaseVars object.", call. = FALSE)
	}

	# A file name is required; there is no default output name. A bare name
	# resolves against the working directory, as with utils::write.csv().
	if (missing(file) || !is.character(file) || length(file) != 1 || is.na(file) || !nzchar(file)) {
		stop("`file` must be a file name or path, e.g. \"myclassvars.csv\".", call. = FALSE)
	}

	# Write only into an existing directory, and never replace a file unless
	# explicitly asked to.
	if (!dir.exists(dirname(file))) {
		stop(sprintf("The directory \"%s\" does not exist.", dirname(file)), call. = FALSE)
	}
	if (file.exists(file) && !isTRUE(overwrite)) {
		stop(sprintf("\"%s\" already exists; use `overwrite = TRUE` to replace it.", file), call. = FALSE)
	}

	# The object's stored table already has CDMetaPOP's column names and order.
	df <- x$as_data_frame()

	# Reference fields are stored as list columns, since they can hold R
	# objects. Flatten each back into the delimited text CDMetaPOP expects:
	# RunVars' `Popvars` joins multiple species with `;`, and every other
	# reference field joins multiple values with `|`. A cell that holds anything
	# other than path strings is written as NA, and its location is recorded
	# for the warning below.
	na_cells <- character(0)
	for (col in names(df)) {
		if (!is.list(df[[col]])) next
		sep <- if (col == "Popvars") ";" else "|"

		# Object-reference cells hold a list of items; matrix-field cells hold a
		# single item (a matrix, a path string, or "N").
		cell_items <- lapply(df[[col]], function(cell) if (is.list(cell)) cell else list(cell))

		# A cell is writable only if every item in it is a single path string.
		writable <- vapply(cell_items, function(items) {
			all(vapply(items, function(item) is.character(item) && length(item) == 1, logical(1)))
		}, logical(1))

		df[[col]] <- vapply(seq_along(cell_items), function(i) {
			# An empty cell means the column was never set -- only possible for
			# PatchVars' `disease_file` when some, but not all, of the disease
			# columns are set. Write NA, as the other unset disease columns do,
			# rather than an empty string.
			if (length(cell_items[[i]]) == 0) return(NA_character_)
			if (writable[i]) paste(unlist(cell_items[[i]]), collapse = sep) else NA_character_
		}, character(1))

		if (any(!writable)) {
			na_cells <- c(na_cells, sprintf("`%s` (row %s)", col, paste(which(!writable), collapse = ", ")))
		}
	}

	# quote = FALSE matches CDMetaPOP's own example files (no quoted "N" or
	# delimited values).
	utils::write.csv(df, file, row.names = FALSE, quote = FALSE)

	if (length(na_cells) > 0) {
		warning(sprintf(
			"These cells held a live R object (an R6 object or a matrix), which has no file path, and were written as NA: %s. To keep a reference, write that object or matrix to its own file and assign its path instead.",
			paste(na_cells, collapse = "; ")
		), call. = FALSE)
	}

	invisible(file)
}
