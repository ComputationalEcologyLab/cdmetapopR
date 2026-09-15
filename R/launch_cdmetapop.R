# launch_cdmetapop(): build CDMetaPOP's input files from a RunVars object (or
# use an existing on-disk run directory) and launch the Python simulation.
#
# The command-preparation step (.launch_prepare) is split out from the actual
# shell dispatch so the input-writing + command construction can be tested
# without invoking Python.

# Resolve `runvars` to a data directory + RunVars filename, writing the input
# graph first if `runvars` is a RunVars object, and build the CDMetaPOP command
# line. Returns list(data_dir, cmd). No process is launched here.
.launch_prepare <- function(runvars, pythonFilepath, CDMetaPOPFilepath,
		base_dir, output_prefix) {
	if (inherits(runvars, "RunVars")) {
		# Object: materialize the whole input-file graph into a fresh run dir
		# (RunVars.csv at its root; see .write_cdmetapop_inputfiles()).
		written <- .write_cdmetapop_inputfiles(runvars, base_dir = base_dir)
		data_dir <- written$run_dir
		runvars_file <- "RunVars.csv"
	} else if (is.character(runvars) && length(runvars) == 1 && !is.na(runvars)) {
		# Path: an existing directory (RunVars.csv assumed inside) or a csv file.
		if (dir.exists(runvars)) {
			data_dir <- runvars
			runvars_file <- "RunVars.csv"
		} else if (file.exists(runvars)) {
			data_dir <- dirname(runvars)
			runvars_file <- basename(runvars)
		} else {
			stop(sprintf("`runvars` path does not exist: \"%s\".", runvars), call. = FALSE)
		}
	} else {
		stop("`runvars` must be a RunVars object or a path to a run directory / RunVars.csv file.",
			call. = FALSE)
	}

	# CDMetaPOP command: python CDMetaPOP.py <datadir> <runvars> <output_prefix>
	# (CDMetaPOP appends a unix timestamp to <output_prefix> for the output
	# folder, and prepends <datadir> to every relative path it reads). The
	# executable/directory paths are quoted in case they contain spaces; the
	# RunVars filename and output prefix are simple tokens.
	q <- function(x) paste0("\"", x, "\"")
	cmd <- paste(q(pythonFilepath), q(CDMetaPOPFilepath), q(data_dir),
		runvars_file, output_prefix)

	list(data_dir = data_dir, cmd = cmd)
}

#' Launch a CDMetaPOP simulation from R
#'
#' @description
#' Builds CDMetaPOP's input files from a [RunVars()] object (or uses an existing
#' on-disk run directory) and launches the Python simulation.
#'
#' When `runvars` is a [RunVars()] object, its full set of input files (RunVars ->
#' PopVars -> PatchVars -> ClassVars, plus cost matrices and other referenced
#' files) is written to a fresh, timestamped run directory
#' (`cdmetapop_run_<timestamp>/`) created under `base_dir`, and CDMetaPOP is
#' pointed at it. When `runvars` is instead a path to a directory containing
#' a `RunVars.csv`, or directly to a RunVars csv file, that existing directory
#' is used as-is and no input files are written.
#'
#' CDMetaPOP writes its output into a timestamped subfolder of the run directory. 
#' Because CDMetaPOP runs can take a long
#' time, the simulation launches in the background by default (`wait = FALSE`)
#' so the R session is not blocked; set `wait = TRUE` to block until it
#' finishes. Either way, read results afterward by pointing the `summary_*`
#' functions (e.g. [summary_pop()]) at the returned run directory.
#'
#' @param runvars A [RunVars()] object (its inputs are written to a fresh run
#'   directory), or a character path to an existing run directory or
#'   `RunVars.csv` file.
#' @param pythonFilepath Location of the Python executable, or just `"python"`
#'   if it is already on the PATH.
#' @param CDMetaPOPFilepath Location of CDMetaPOP's `CDMetaPOP.py`, or just
#'   `"CDMetaPOP.py"` if it is in the working directory.
#' @param base_dir Parent directory under which the fresh run directory is
#'   created when `runvars` is a [RunVars()] object. Defaults to the working
#'   directory. Ignored when `runvars` is a path to an existing run.
#' @param output_prefix Name prefix for CDMetaPOP's output subfolder; CDMetaPOP
#'   appends a unix timestamp to it. Defaults to `"output_"`.
#' @param wait If `FALSE` (the default), launch the simulation in the background
#'   and return immediately -- suitable for long runs. If `TRUE`, block until
#'   CDMetaPOP finishes before returning.
#'
#' @return The output run directory, to be used as an argument for output summary 
#' functions, (e.g. [summary_pop()]) once the run has completed.
#' @export
#'
#' @examples
#' \dontrun{
#' # Build inputs from a RunVars object and launch in the background:
#' myrun <- RunVars()
#' run_dir <- launch_cdmetapop(
#'   myrun,
#'   pythonFilepath = "C:/Users/User1/anaconda3/python.exe",
#'   CDMetaPOPFilepath = "C:/Users/User1/CDMetaPOP/src/CDMetaPOP.py"
#' )
#' # ... once the run finishes, read results from the same directory:
#' summary_pop(run_dir, type = "N_initial")
#'
#' # Or launch an existing on-disk run directory, blocking until it finishes:
#' launch_cdmetapop("C:/Users/User1/CDMetaPOP/example_files", wait = TRUE)
#' }
launch_cdmetapop <- function(runvars,
                             pythonFilepath = "python",
                             CDMetaPOPFilepath = "CDMetaPOP.py",
                             base_dir = getwd(),
                             output_prefix = "output_",
                             wait = FALSE) {
	prep <- .launch_prepare(runvars, pythonFilepath, CDMetaPOPFilepath,
		base_dir, output_prefix)

	# Launch. wait = FALSE runs in the background (with a trailing pause so the
	# spawned console stays open after the run); wait = TRUE blocks the R session
	# until CDMetaPOP exits.
	if (.Platform$OS.type == "windows") {
		full <- if (wait) prep$cmd else paste(prep$cmd, "& pause")
		# shell() runs `cmd.exe /c <command>`. When that command starts with a
		# quote and contains more than two quote characters, cmd strips the
		# first and last quote on the line, which mangles the quoted paths
		# ("The filename, directory name, or volume label syntax is
		# incorrect."). Wrapping the whole command in one extra outer pair of
		# quotes gives cmd a pair to strip, leaving the inner quoting intact.
		shell(paste0("\"", full, "\""), invisible = FALSE, wait = wait)
	} else {
		full <- if (wait) prep$cmd else paste0(prep$cmd, "; read -p 'Press enter to continue'")
		system(full, wait = wait)
	}

	# Point the user at the run directory and how to read results from it.
	if (wait) {
		message(sprintf(
			"CDMetaPOP run complete. Read results from:\n  %s\ne.g. summary_pop(\"%s\")",
			prep$data_dir, prep$data_dir))
	} else {
		message(sprintf(
			"CDMetaPOP launched in the background in:\n  %s\nWhen it finishes, read results with e.g. summary_pop(\"%s\").",
			prep$data_dir, prep$data_dir))
	}
	invisible(prep$data_dir)
}
