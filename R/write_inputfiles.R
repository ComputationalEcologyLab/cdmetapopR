# =====================================================================
# Graph-writer for CDMetaPOP input files (plan.md Task Order item 7).
#
# The eventual `.write_cdmetapop_inputfiles()` (built incrementally across
# sub-tasks 1-6) walks the RunVars -> PopVars -> PatchVars -> ClassVars
# object graph (plus raw-matrix and external-file leaves), assigns each
# unique node a file in a fresh run directory, writes every input file with
# cross-references rewritten to canonical relative paths, and returns the
# run directory. It is UNEXPORTED and called only by launch_cdmetapop()
# (Task 8). See plan.md Key Design Decision 6 and the "Graph-writer (Task 7)
# implementation scoping" section for the full design.
#
# THIS FILE CURRENTLY IMPLEMENTS SUB-TASK 1 ONLY: node discovery + a dedup
# registry (the graph walk). Filename assignment (sub-task 2), csv/matrix
# writing (3-4), the manifest (5), and the top-level driver (6) are not yet
# built -- the `varname`/`filename`/`relpath` node slots are created here but
# left NA for sub-task 2 to populate.
#
# All functions are internal (plain `#` comments, `.wif_` prefix = "write
# input files"); none are exported or roxygen-documented.
# =====================================================================

# Canonical output subdirectory for each object TYPE. Fixed by type, so two
# references to the same object always land in the same place -- which is
# why object nodes dedup on identity alone (no subdir in their key). The root
# RunVars.csv lives at the run-directory root, hence subdir "".
.wif_type_subdir <- c(
	RunVars   = "",
	PopVars   = "popvars",
	PatchVars = "patchvars",
	ClassVars = "classvars"
)

# Canonical output subdirectory for each field that references a
# field-dependent leaf (a raw matrix or a copied external file). Unlike
# object types, these leaves' destination is set by the REFERRING FIELD, not
# by the payload -- e.g. a matrix in mate_cdmat goes to cdmats/, but the same
# matrix in correlation_matrix goes to otherfiles/. This is why matrix/
# copyfile nodes dedup on (payload, subdir): the same payload reached through
# two different-subdir fields is written to both (with a warning).
.wif_leaf_field_subdir <- c(
	mate_cdmat          = "cdmats",
	migrateout_cdmat    = "cdmats",
	migrateback_cdmat   = "cdmats",
	stray_cdmat         = "cdmats",
	disperseLocal_cdmat = "cdmats",
	correlation_matrix  = "otherfiles",
	subpopmort_file     = "otherfiles",
	betaFile_selection  = "otherfiles/betafiles",
	genes_initialize    = "genes"
)

# ---------------------------------------------------------------------
# Registry construction and low-level mutation
# ---------------------------------------------------------------------
# The registry is an ENVIRONMENT (reference semantics) so the recursive walk
# can accumulate into it in place, rather than threading an updated copy back
# out of every call.
#   $nodes:      append-only list of node entries; a node's id == its
#                position in this list.
#   $path_cache: composite-key ((subdir, normalized path) -> node id) lookup,
#                deduping path-sourced nodes across BOTH tiers (a Tier-1 path
#                read into an object, and a Tier-2 copied leaf file). Object
#                and leaf subdirs never overlap, so one shared index is safe.
.wif_new_registry <- function() {
	reg <- new.env(parent = emptyenv())
	reg$nodes <- list()
	reg$path_cache <- list()
	reg
}

# Composite path-cache key: (subdir, normalized path). Normalizing collapses
# "./" and slash/case differences so the same file referenced two ways
# dedups; a control-char separator keeps the two parts unambiguous. Existence
# is NOT required here (mustWork = FALSE) -- discovery must run before any
# file is written, and copyfile existence is checked later at copy time.
.wif_path_key <- function(subdir, path) {
	paste(subdir, normalizePath(path, winslash = "/", mustWork = FALSE), sep = "\r")
}

# Append a fully-formed node entry (minus id) and return its assigned id.
.wif_append_node <- function(reg, entry) {
	id <- length(reg$nodes) + 1L
	entry$id <- id
	reg$nodes[[id]] <- entry
	id
}

# Record one referrer (which parent node referenced this node, via which
# field) on an existing node. The root RunVars has referrer_id/field = NA.
.wif_add_provenance <- function(reg, node_id, referrer_id, field) {
	prov <- reg$nodes[[node_id]]$provenance
	prov[[length(prov) + 1L]] <- list(referrer_id = referrer_id, field = field)
	reg$nodes[[node_id]]$provenance <- prov
	invisible(NULL)
}

# Build an empty-slot node entry (the NA naming slots are filled in
# sub-task 2). Centralized so every node has an identical shape.
.wif_make_entry <- function(kind, payload, subdir, referrer_id, field,
		source_path = NA_character_) {
	list(
		kind        = kind,
		payload     = payload,
		subdir      = subdir,
		source_path = source_path,
		provenance  = list(list(referrer_id = referrer_id, field = field)),
		varname     = NA_character_,  # .GlobalEnv variable name  (sub-task 2)
		filename    = NA_character_,  # assigned basename         (sub-task 2)
		relpath     = NA_character_   # subdir + "/" + filename   (sub-task 2)
	)
}

# ---------------------------------------------------------------------
# Node lookup / dedup
# ---------------------------------------------------------------------
# Find an existing object node holding `obj` by REFERENCE identity. R6
# objects are environments, so identical() is true only for the same object
# -- two separately-built objects with equal contents stay distinct nodes
# (they may later diverge). Fixed subdir per type, so identity alone suffices.
.wif_find_object_node <- function(reg, obj) {
	for (node in reg$nodes) {
		if (node$kind %in% names(.wif_type_subdir) && identical(node$payload, obj)) {
			return(node$id)
		}
	}
	NA_integer_
}

# Find an existing matrix node with the identical value. identical() on
# matrices compares by value, so two value-identical matrices dedup (the
# intended behavior). `require_subdir`, when non-NA, restricts the match to
# that subdir (the dedup key); NA matches any subdir (used to detect the
# cross-subdir "written to two places" case for the warning).
.wif_find_matrix_node <- function(reg, m, require_subdir = NA_character_) {
	for (node in reg$nodes) {
		if (node$kind == "matrix" && identical(node$payload, m)) {
			if (is.na(require_subdir) || identical(node$subdir, require_subdir)) {
				return(node$id)
			}
		}
	}
	NA_integer_
}

# Find an existing copyfile node for `path` (matched on normalized path).
# `require_subdir` behaves as in .wif_find_matrix_node(). Used only for the
# cross-subdir warning check; same-subdir dedup goes through path_cache.
.wif_find_copyfile_node <- function(reg, path, require_subdir = NA_character_) {
	norm <- normalizePath(path, winslash = "/", mustWork = FALSE)
	for (node in reg$nodes) {
		if (node$kind == "copyfile" &&
				identical(normalizePath(node$payload, winslash = "/", mustWork = FALSE), norm)) {
			if (is.na(require_subdir) || identical(node$subdir, require_subdir)) {
				return(node$id)
			}
		}
	}
	NA_integer_
}

# Emit the cross-subdir reuse warning: the identical matrix/file is already
# registered under a different subdir, so it will be written to both. Names
# both destinations (via the existing node's referring fields) so the user
# can spot what is almost certainly an unintended reuse.
.wif_warn_cross_subdir <- function(reg, existing_id, field, new_subdir, what) {
	existing <- reg$nodes[[existing_id]]
	prior_fields <- unique(vapply(existing$provenance, function(p) {
		if (is.na(p$field)) "<root>" else p$field
	}, character(1)))
	warning(sprintf(
		"The same %s is referenced by %s (-> %s/) and %s (-> %s/); it will be written to both locations. This is often unintended.",
		what, paste(prior_fields, collapse = "/"), existing$subdir, field, new_subdir
	), call. = FALSE)
	invisible(NULL)
}

# ---------------------------------------------------------------------
# Node registration
# ---------------------------------------------------------------------
# Register an object node (RunVars/PopVars/PatchVars/ClassVars), deduping by
# reference identity, then recurse into its references. Register-BEFORE-
# recurse: children record this node's id as their referrer, and a revisit
# finds the existing node (the graph is a DAG, so this also guards against a
# hypothetical cycle). Returns the node id.
.wif_register_object <- function(reg, obj, kind, referrer_id, field,
		source_path = NA_character_) {
	existing <- .wif_find_object_node(reg, obj)
	if (!is.na(existing)) {
		.wif_add_provenance(reg, existing, referrer_id, field)
		return(existing)
	}

	id <- .wif_append_node(reg, .wif_make_entry(
		kind, obj, .wif_type_subdir[[kind]], referrer_id, field,
		source_path = source_path
	))
	.wif_walk_references(reg, id)
	id
}

# Register a raw-matrix leaf, deduping on (value, subdir). If the identical
# matrix already exists under a DIFFERENT subdir, warn and write it to both.
.wif_register_matrix <- function(reg, m, subdir, referrer_id, field) {
	same <- .wif_find_matrix_node(reg, m, require_subdir = subdir)
	if (!is.na(same)) {
		.wif_add_provenance(reg, same, referrer_id, field)
		return(same)
	}
	other <- .wif_find_matrix_node(reg, m, require_subdir = NA_character_)
	if (!is.na(other)) .wif_warn_cross_subdir(reg, other, field, subdir, "matrix")

	.wif_append_node(reg, .wif_make_entry("matrix", m, subdir, referrer_id, field))
}

# Register a copied external-file leaf (cost/correlation/subpopmort matrix,
# beta file, or gene file given as a PATH), deduping on (path, subdir) via the
# path cache. Existence is NOT checked here -- deferred to the copy step
# (sub-task 4), which errors if the source is missing at launch. Cross-subdir
# reuse warns, same as matrices.
.wif_register_copyfile <- function(reg, path, subdir, referrer_id, field) {
	key <- .wif_path_key(subdir, path)
	cached <- reg$path_cache[[key]]
	if (!is.null(cached)) {
		.wif_add_provenance(reg, cached, referrer_id, field)
		return(cached)
	}
	other <- .wif_find_copyfile_node(reg, path, require_subdir = NA_character_)
	if (!is.na(other)) .wif_warn_cross_subdir(reg, other, field, subdir, "file")

	id <- .wif_append_node(reg, .wif_make_entry(
		"copyfile", path, subdir, referrer_id, field, source_path = path
	))
	reg$path_cache[[key]] <- id
	id
}

# ---------------------------------------------------------------------
# Reference resolution (one cell segment -> a node)
# ---------------------------------------------------------------------
# Resolve one item of a Tier-1 object-reference field (RunVars$Popvars,
# PopVars$xyfilename, PatchVars$class_vars). The class normalizers already
# pre-split these cells on their separator, so `item` is atomic: either a
# live R6 object of `target_kind`, or a single path string. A path is read
# via read_cdmetapop() and FOLDED INTO THE GRAPH (so its own nested
# references are discovered/rewritten too), deduped on (subdir, path) so the
# same file is read only once. NB: nested paths inside a read file resolve
# relative to the current working directory (a known launch-time gap, see
# plan.md) -- fine for the recommended live-object workflow.
.wif_resolve_object_ref <- function(reg, item, target_kind, referrer_id, field) {
	if (inherits(item, target_kind)) {
		return(.wif_register_object(reg, item, target_kind, referrer_id, field))
	}
	if (is.character(item) && length(item) == 1 && !is.na(item) && nzchar(item)) {
		subdir <- .wif_type_subdir[[target_kind]]
		key <- .wif_path_key(subdir, item)
		cached <- reg$path_cache[[key]]
		if (!is.null(cached)) {
			.wif_add_provenance(reg, cached, referrer_id, field)
			return(cached)
		}
		obj <- read_cdmetapop(item, type = target_kind)
		id <- .wif_register_object(reg, obj, target_kind, referrer_id, field,
			source_path = item)
		reg$path_cache[[key]] <- id
		return(id)
	}
	stop(sprintf(
		"Unexpected `%s` reference: each item must be a %s object or a single path string.",
		field, target_kind
	))
}

# Resolve one matrix-field cell (exactly one item: a matrix, a path, or "N").
# A matrix -> matrix node; "N" -> skipped; a path may itself carry '|'
# (temporal) and '~' (per-sex) delimiters stored verbatim, so it is split and
# each segment is a separate copied file.
.wif_resolve_matrix_ref <- function(reg, item, subdir, referrer_id, field) {
	if (is.matrix(item)) {
		.wif_register_matrix(reg, item, subdir, referrer_id, field)
		return(invisible(NULL))
	}
	if (is.character(item) && length(item) == 1 && !is.na(item)) {
		if (identical(item, "N")) return(invisible(NULL))
		for (seg in .wif_split_pipe_tilde(item)) {
			if (nzchar(seg)) .wif_register_copyfile(reg, seg, subdir, referrer_id, field)
		}
	}
	invisible(NULL)
}

# Split a matrix-field path string on '|' (temporal) then '~' (per-sex) into
# individual file paths; a plain path with no delimiters yields itself.
.wif_split_pipe_tilde <- function(x) {
	pipe_segs <- strsplit(x, "|", fixed = TRUE)[[1]]
	unlist(lapply(pipe_segs, function(p) strsplit(p, "~", fixed = TRUE)[[1]]),
		use.names = FALSE)
}

# Extract the file-path segments from a genes_initialize value: '|' outer
# (temporal), ';' inner (multiple files per group). The keywords "random"/
# "random_var" are not files and are dropped.
.wif_split_gene_paths <- function(x) {
	if (is.na(x) || !nzchar(x)) return(character(0))
	pipe_segs <- strsplit(x, "|", fixed = TRUE)[[1]]
	segs <- unlist(lapply(pipe_segs, function(p) strsplit(p, ";", fixed = TRUE)[[1]]),
		use.names = FALSE)
	segs[!segs %in% c("random", "random_var") & nzchar(segs)]
}

# ---------------------------------------------------------------------
# Graph walk
# ---------------------------------------------------------------------
# Walk one internal node's reference fields, registering each referenced
# node. Dispatches on kind; ClassVars is a leaf with no references. Reference
# columns are read via the objects' active bindings (obj[[field]]), which use
# the uniform field names (snake_case / exact header) rather than the
# ClassVars/PatchVars data-frame header text.
.wif_walk_references <- function(reg, node_id) {
	obj  <- reg$nodes[[node_id]]$payload
	kind <- reg$nodes[[node_id]]$kind

	if (kind == "RunVars") {
		# Popvars: list column; each cell a flat list of PopVars objects/paths
		# (pre-split on ';', one per species).
		for (cell in obj[["Popvars"]]) {
			for (item in cell) {
				.wif_resolve_object_ref(reg, item, "PopVars", node_id, "Popvars")
			}
		}
		return(invisible(NULL))
	}

	if (kind == "PopVars") {
		# xyfilename: list column; each cell a flat list of PatchVars
		# objects/paths (pre-split on '|').
		for (cell in obj[["xyfilename"]]) {
			for (item in cell) {
				.wif_resolve_object_ref(reg, item, "PatchVars", node_id, "xyfilename")
			}
		}
		# Matrix fields: each cell is exactly one item (matrix / path / "N").
		for (mf in .popv_matrix_fields) {
			subdir <- .wif_leaf_field_subdir[[mf]]
			for (item in obj[[mf]]) {
				.wif_resolve_matrix_ref(reg, item, subdir, node_id, mf)
			}
		}
		# betaFile_selection: plain character column, a path or "N" (no
		# delimiters -- its rule does not permit '|').
		beta_subdir <- .wif_leaf_field_subdir[["betaFile_selection"]]
		for (v in obj[["betaFile_selection"]]) {
			if (!is.na(v) && nzchar(v) && !identical(v, "N")) {
				.wif_register_copyfile(reg, v, beta_subdir, node_id, "betaFile_selection")
			}
		}
		return(invisible(NULL))
	}

	if (kind == "PatchVars") {
		# class_vars: list column; each cell a flat list of ClassVars
		# objects/paths (pre-split on '|').
		for (cell in obj[["class_vars"]]) {
			for (item in cell) {
				.wif_resolve_object_ref(reg, item, "ClassVars", node_id, "class_vars")
			}
		}
		# genes_initialize: plain character column; '|' outer, ';' inner for
		# paths; keywords "random"/"random_var" are not files.
		genes_subdir <- .wif_leaf_field_subdir[["genes_initialize"]]
		for (v in obj[["genes_initialize"]]) {
			for (seg in .wif_split_gene_paths(v)) {
				.wif_register_copyfile(reg, seg, genes_subdir, node_id, "genes_initialize")
			}
		}
		return(invisible(NULL))
	}

	# kind == "ClassVars": leaf, nothing to recurse into.
	invisible(NULL)
}

# ---------------------------------------------------------------------
# Sub-task 1 entry point
# ---------------------------------------------------------------------
# Discover every unique node reachable from a RunVars object and return the
# populated registry (an environment; see .wif_new_registry()). The RunVars
# object is the root node (its file is RunVars.csv at the run-directory root).
.wif_discover_nodes <- function(runvars) {
	if (!inherits(runvars, "RunVars")) {
		stop("`runvars` must be a RunVars object.")
	}
	reg <- .wif_new_registry()
	.wif_register_object(reg, runvars, "RunVars",
		referrer_id = NA_integer_, field = NA_character_)
	reg
}

# =====================================================================
# SUB-TASK 2: filename assignment
#
# Assigns each node its output filename (and full canonical relative path)
# by the Key Design Decision 6 priority: reverse `.GlobalEnv` variable-name
# lookup, else a type+index fallback -- with copied files keeping their
# original basename, and per-subdirectory uniqueness enforced. Populates the
# `varname`/`filename`/`relpath` slots left NA by sub-task 1. Naming happens
# at launch (here), when the user's variables already exist, which is what
# makes the reverse lookup possible (a function on the RHS of `<-` cannot see
# the LHS name at construction; by launch the binding exists in `.GlobalEnv`).
# =====================================================================

# Split a filename's trailing extension: "foo.csv" -> stem "foo", ext ".csv";
# a name with no dot -> empty ext. Used so a uniqueness suffix is inserted
# before the extension ("foo.csv" -> "foo_2.csv"), not after it.
.wif_split_ext <- function(filename) {
	m <- regexpr("\\.[^.]+$", filename)
	if (m == -1L) return(list(stem = filename, ext = ""))
	list(stem = substr(filename, 1L, m - 1L),
		ext = substr(filename, m, nchar(filename)))
}

# Return `desired` if unused, else the first "<stem>_<k><ext>" (k = 2, 3, ...)
# not in `used`. Enforces filename uniqueness within a single subdirectory.
.wif_uniquify <- function(desired, used) {
	if (!desired %in% used) return(desired)
	parts <- .wif_split_ext(desired)
	k <- 2L
	repeat {
		cand <- paste0(parts$stem, "_", k, parts$ext)
		if (!cand %in% used) return(cand)
		k <- k + 1L
	}
}

# The name a node "wants", before uniqueness resolution. Returns NA to request
# a type+index fallback (an object/matrix node with neither a `.GlobalEnv`
# variable nor a source path). Priority:
#   - root RunVars: always "RunVars.csv" (the name launch_cdmetapop() expects);
#   - copyfile: its original basename (we copy the file by basename);
#   - object/matrix: the `.GlobalEnv` variable name (set in .wif_assign_names);
#     failing that, for a node read from a path (Tier-1), the source basename.
.wif_preferred_name <- function(node) {
	if (node$kind == "RunVars") return("RunVars.csv")
	if (node$kind == "copyfile") return(basename(node$source_path))
	if (!is.na(node$varname)) return(paste0(node$varname, ".csv"))
	if (!is.na(node$source_path)) return(basename(node$source_path))
	NA_character_
}

# Assign varname/filename/relpath to every node. Mutates `reg` in place.
.wif_assign_names <- function(reg) {
	# --- Pass A: reverse `.GlobalEnv` lookup -------------------------------
	# Snapshot the globals that could match a node payload (R6 input objects
	# or matrices) ONCE, so we neither re-fetch per node nor scan unrelated
	# large objects. First identical() match wins (reference identity for R6
	# objects, value identity for matrices -- the latter being the dedup case,
	# so a value-identical global naming the file is acceptable). Copyfiles are
	# named by basename, not by variable, so they are skipped here.
	candidates <- list()
	for (nm in ls(envir = .GlobalEnv)) {
		val <- get(nm, envir = .GlobalEnv, inherits = FALSE)
		if (inherits(val, c("RunVars", "PopVars", "PatchVars", "ClassVars")) ||
				is.matrix(val)) {
			candidates[[nm]] <- val
		}
	}
	lookup <- function(payload) {
		for (nm in names(candidates)) {
			if (identical(candidates[[nm]], payload)) return(nm)
		}
		NA_character_
	}
	for (i in seq_along(reg$nodes)) {
		if (reg$nodes[[i]]$kind == "copyfile") next
		reg$nodes[[i]]$varname <- lookup(reg$nodes[[i]]$payload)
	}

	# --- Pass B: filename assignment, per subdirectory ---------------------
	# Uniqueness is per-subdir (two files with the same basename in different
	# subdirs are fine -- they have distinct relpaths). Within a subdir,
	# definite names (root/copyfile/varname/source-basename) are assigned
	# first so they keep their clean form; fallback type+index names are
	# assigned second, yielding to (skipping) any name a definite node took --
	# so a fallback "classvars1.csv" never clobbers a user variable literally
	# named "classvars1". Residual collisions (e.g. two copied files sharing a
	# basename) get "_k"-suffixed by .wif_uniquify().
	for (sd in unique(vapply(reg$nodes, function(n) n$subdir, character(1)))) {
		ids <- which(vapply(reg$nodes, function(n) identical(n$subdir, sd), logical(1)))
		used <- character(0)

		needs_fallback <- integer(0)
		for (id in ids) {
			desired <- .wif_preferred_name(reg$nodes[[id]])
			if (is.na(desired)) { needs_fallback <- c(needs_fallback, id); next }
			nm <- .wif_uniquify(desired, used)
			reg$nodes[[id]]$filename <- nm
			used <- c(used, nm)
		}
		for (id in needs_fallback) {
			prefix <- if (reg$nodes[[id]]$kind == "matrix") "matrix" else tolower(reg$nodes[[id]]$kind)
			k <- 1L
			repeat {
				cand <- sprintf("%s%d.csv", prefix, k)
				if (!cand %in% used) break
				k <- k + 1L
			}
			reg$nodes[[id]]$filename <- cand
			used <- c(used, cand)
		}
	}

	# --- Pass C: canonical relative path -----------------------------------
	# What gets written into a parent's reference cells (root subdir "" -> the
	# bare filename, since RunVars.csv sits at the run-directory root).
	for (i in seq_along(reg$nodes)) {
		node <- reg$nodes[[i]]
		reg$nodes[[i]]$relpath <- if (nzchar(node$subdir)) {
			paste0(node$subdir, "/", node$filename)
		} else {
			node$filename
		}
	}
	invisible(reg)
}

# =====================================================================
# SUB-TASK 3: per-object csv writing (references resolved from the registry)
#
# Serializes each OBJECT node (RunVars/PopVars/PatchVars/ClassVars) to its
# csv, rewriting every child-reference cell to the child's canonical relative
# path (assigned in sub-task 2). This rebuilds the serialization the removed
# public `write_cdmetapop` methods once had, but resolves child cells from the
# registry rather than a per-object `location`. Matrix files and copied leaf
# files are NOT written here -- that is sub-task 4; this only emits the object
# tables, whose cells already point at where those files WILL be written.
#
# The objects' stored data frames already carry CDMetaPOP's expected column
# names/order (ClassVars/PatchVars use header text, matched by position;
# PopVars/RunVars use field=header text, matched by name), so serialization is
# just: take `as_data_frame()`, replace the reference columns with their
# resolved-path character form, and write with quote = FALSE (byte-matching
# CDMetaPOP's own examples; do NOT quote the "N"/"|"/";" cells).
# =====================================================================

# Look up the canonical relpath of an already-registered node. These three
# mirror the discovery-time resolution, but are LOOKUP-ONLY (everything was
# registered in sub-task 1); a miss indicates an internal inconsistency.
.wif_relpath_of_object <- function(reg, obj) {
	id <- .wif_find_object_node(reg, obj)
	if (is.na(id)) stop("internal: object node not found in registry during write.")
	reg$nodes[[id]]$relpath
}
.wif_relpath_of_matrix <- function(reg, m, subdir) {
	id <- .wif_find_matrix_node(reg, m, require_subdir = subdir)
	if (is.na(id)) stop("internal: matrix node not found in registry during write.")
	reg$nodes[[id]]$relpath
}
# Works for BOTH a Tier-1 object read from a path and a Tier-2 copied leaf
# file -- both are keyed in `path_cache` by (subdir, normalized path).
.wif_relpath_of_cached_path <- function(reg, path, subdir) {
	id <- reg$path_cache[[.wif_path_key(subdir, path)]]
	if (is.null(id)) {
		stop(sprintf("internal: no registered node for path '%s' (%s) during write.", path, subdir))
	}
	reg$nodes[[id]]$relpath
}

# Rewrite a Tier-1 object list column (each cell a flat list of R6 objects /
# path strings) to a character vector of `sep`-joined canonical relpaths.
.wif_rewrite_object_column <- function(reg, col, target_kind, sep) {
	type_subdir <- .wif_type_subdir[[target_kind]]
	vapply(col, function(cell) {
		paths <- vapply(cell, function(item) {
			if (inherits(item, target_kind)) {
				.wif_relpath_of_object(reg, item)
			} else {
				# a path string -> the object node it was read into (Tier-1)
				.wif_relpath_of_cached_path(reg, item, type_subdir)
			}
		}, character(1))
		paste(paths, collapse = sep)
	}, character(1))
}

# Rewrite a delimited path string, mapping each path segment to its node's
# relpath while preserving the `outer`/`inner` delimiter structure. A segment
# equal to a `keyword`, or empty, is passed through unchanged (for
# genes_initialize's random/random_var; empties should not occur but are left
# untouched rather than looked up). Used for matrix paths ('|' then '~') and
# genes_initialize ('|' then ';').
.wif_rewrite_delimited <- function(reg, str, subdir, outer, inner, keywords = character(0)) {
	outer_groups <- strsplit(str, outer, fixed = TRUE)[[1]]
	new_outer <- vapply(outer_groups, function(g) {
		inner_segs <- strsplit(g, inner, fixed = TRUE)[[1]]
		new_inner <- vapply(inner_segs, function(s) {
			if (!nzchar(s) || s %in% keywords) return(s)
			.wif_relpath_of_cached_path(reg, s, subdir)
		}, character(1))
		paste(new_inner, collapse = inner)
	}, character(1))
	paste(new_outer, collapse = outer)
}

# Rewrite one matrix-field cell (a matrix, a path, or "N") to its canonical
# string. A matrix -> its assigned relpath; "N" -> "N"; a path may carry
# '|'/'~' delimiters, rewritten segment-by-segment with structure preserved.
.wif_rewrite_matrix_cell <- function(reg, item, subdir) {
	if (is.matrix(item)) return(.wif_relpath_of_matrix(reg, item, subdir))
	if (identical(item, "N")) return("N")
	.wif_rewrite_delimited(reg, item, subdir, outer = "|", inner = "~")
}

# Build the write-ready data frame for one object node: its stored table with
# reference columns rewritten to canonical relpaths. Dispatches on kind.
.wif_object_dataframe <- function(reg, node) {
	obj <- node$payload
	df <- obj$as_data_frame()

	if (node$kind == "ClassVars") {
		return(df)  # a leaf: no references to rewrite
	}

	if (node$kind == "RunVars") {
		# Popvars: object list column, ';'-joined (one relpath per species).
		df[["Popvars"]] <- .wif_rewrite_object_column(reg, df[["Popvars"]], "PopVars", ";")
		return(df)
	}

	if (node$kind == "PopVars") {
		# xyfilename: object list column, '|'-joined.
		df[["xyfilename"]] <- .wif_rewrite_object_column(reg, df[["xyfilename"]], "PatchVars", "|")
		# Matrix fields: one item per cell (matrix / path / "N").
		for (mf in .popv_matrix_fields) {
			subdir <- .wif_leaf_field_subdir[[mf]]
			df[[mf]] <- vapply(df[[mf]], function(item) {
				.wif_rewrite_matrix_cell(reg, item, subdir)
			}, character(1))
		}
		# betaFile_selection: a plain path or "N" (no delimiters).
		beta_subdir <- .wif_leaf_field_subdir[["betaFile_selection"]]
		df[["betaFile_selection"]] <- vapply(df[["betaFile_selection"]], function(v) {
			if (is.na(v) || !nzchar(v) || identical(v, "N")) return(v)
			.wif_relpath_of_cached_path(reg, v, beta_subdir)
		}, character(1))
		return(df)
	}

	if (node$kind == "PatchVars") {
		# Class Vars: object list column, '|'-joined (column is named by its
		# header text, "Class Vars", in PatchVars' stored data frame).
		df[["Class Vars"]] <- .wif_rewrite_object_column(reg, df[["Class Vars"]], "ClassVars", "|")
		# Genes Initialize: '|' outer / ';' inner; keep random/random_var.
		genes_subdir <- .wif_leaf_field_subdir[["genes_initialize"]]
		df[["Genes Initialize"]] <- vapply(df[["Genes Initialize"]], function(v) {
			.wif_rewrite_delimited(reg, v, genes_subdir, outer = "|", inner = ";",
				keywords = c("random", "random_var"))
		}, character(1))
		return(df)
	}

	stop(sprintf("internal: cannot serialize node kind '%s'.", node$kind))
}

# Write one object node's csv into `run_dir` at its canonical relpath, creating
# the parent subdirectory if needed. Uses quote = FALSE / row.names = FALSE to
# byte-match CDMetaPOP's own example files. Returns the written path.
.wif_write_object_csv <- function(reg, node, run_dir) {
	df <- .wif_object_dataframe(reg, node)
	path <- file.path(run_dir, node$relpath)
	dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
	utils::write.csv(df, path, row.names = FALSE, quote = FALSE)
	invisible(path)
}

# =====================================================================
# SUB-TASK 4: leaf writing -- matrices + external-file copies
#
# Writes the leaf nodes that the object csvs (sub-task 3) point at:
#   - `matrix` nodes: the raw R matrix serialized NxN, no header, no row
#     names -- the format CDMetaPOP's ReadCDMatrix() expects (it splits each
#     line on ',' into floats; see CDMetaPOP/src/CDmetaPOP_PreProcess.py).
#   - `copyfile` nodes: the external source file copied verbatim (by basename)
#     into its canonical subdir; errors if the source is missing AT LAUNCH
#     (Tier-2 existence is deliberately deferred from discovery to here).
# Object csvs are NOT (re)written here (sub-task 3). Parent-subdir creation is
# done per node so each writer is self-contained; run-directory creation is
# sub-task 6.
# =====================================================================

# The field that first referenced a node (for error messages). Skips the
# root's NA field; returns "?" if somehow none is set.
.wif_first_field <- function(node) {
	for (p in node$provenance) {
		if (!is.na(p$field)) return(p$field)
	}
	"?"
}

# Write one matrix node NxN (comma-separated, no header/row names --
# CDMetaPOP ReadCDMatrix() format). Returns the written path.
.wif_write_matrix_csv <- function(reg, node, run_dir) {
	path <- file.path(run_dir, node$relpath)
	dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
	utils::write.table(node$payload, path, sep = ",",
		row.names = FALSE, col.names = FALSE, quote = FALSE)
	invisible(path)
}

# Copy one copyfile node's source file into its canonical location (by
# basename). Errors if the source no longer exists at launch, or if the copy
# operation fails. Returns the written path.
.wif_copy_leaf_file <- function(reg, node, run_dir) {
	src <- node$source_path
	if (!file.exists(src)) {
		stop(sprintf(
			"Cannot find the file referenced by `%s`: \"%s\" does not exist.",
			.wif_first_field(node), src
		), call. = FALSE)
	}
	path <- file.path(run_dir, node$relpath)
	dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
	if (!file.copy(src, path, overwrite = TRUE)) {
		stop(sprintf("Failed to copy \"%s\" to \"%s\".", src, path), call. = FALSE)
	}
	invisible(path)
}

# =====================================================================
# SUB-TASK 5: manifest.csv
#
# Writes a human-facing `manifest.csv` at the run-directory root, mapping every
# generated file back to the R object/variable it came from. This is the
# "receipt" for the naming/placement the graph-writer does automatically (Key
# Design Decision 6): since the user never names or places a file, the manifest
# is how they trace each csv to its source -- especially the fallback-named
# ones. CDMetaPOP never reads it (it only consumes RunVars.csv and what that
# references), so the format is ours to choose. Columns:
#   - file          : canonical relative path of the generated file
#   - kind          : node kind (RunVars/PopVars/PatchVars/ClassVars/matrix/copyfile)
#   - source        : the `.GlobalEnv` variable name; or, for a copied file or
#                     a path-read object, the original source path; or
#                     "<inline>" for an object/matrix built inline (no variable)
#   - referenced_by : the field(s) that pointed at this node ("<root>" for the
#                     top-level RunVars), "; "-joined if more than one
# =====================================================================

# Build the manifest data frame (one row per node, in discovery/id order --
# root RunVars first, then its descendants).
.wif_manifest_dataframe <- function(reg) {
	rows <- lapply(reg$nodes, function(node) {
		source <- if (node$kind == "copyfile") {
			node$source_path                       # copied files: original path
		} else if (!is.na(node$varname)) {
			node$varname                           # named object/matrix
		} else if (!is.na(node$source_path)) {
			node$source_path                       # Tier-1 object read from a path
		} else {
			"<inline>"                             # built inline, no variable
		}
		fields <- vapply(node$provenance, function(p) {
			if (is.na(p$field)) "<root>" else p$field
		}, character(1))
		data.frame(
			file = node$relpath,
			kind = node$kind,
			source = source,
			referenced_by = paste(unique(fields), collapse = "; "),
			stringsAsFactors = FALSE
		)
	})
	do.call(rbind, rows)
}

# Write manifest.csv at the run-directory root. Returns the written path.
# quote = FALSE for readability (the columns hold our controlled relpaths /
# kinds / field names; source paths with embedded commas -- vanishingly rare --
# are the only theoretical risk, and this file is documentation, not input).
.wif_write_manifest <- function(reg, run_dir) {
	df <- .wif_manifest_dataframe(reg)
	path <- file.path(run_dir, "manifest.csv")
	utils::write.csv(df, path, row.names = FALSE, quote = FALSE)
	invisible(path)
}

# =====================================================================
# SUB-TASK 6: top-level driver
#
# `.write_cdmetapop_inputfiles(runvars)` ties sub-tasks 1-5 together: it
# creates a fresh timestamped run directory, discovers + names the node graph,
# writes every object/matrix/copied file plus the manifest, and returns the
# run directory (and the RunVars.csv / manifest.csv paths). UNEXPORTED --
# called only by launch_cdmetapop() (Task 8), which will pass the RunVars
# object through and hand the returned run_dir to the Python subprocess as its
# data directory.
# =====================================================================

# Dispatch a single node to the appropriate writer.
.wif_write_node <- function(reg, node, run_dir) {
	if (node$kind == "matrix")   return(.wif_write_matrix_csv(reg, node, run_dir))
	if (node$kind == "copyfile") return(.wif_copy_leaf_file(reg, node, run_dir))
	.wif_write_object_csv(reg, node, run_dir)  # the four object kinds
}

# Pre-flight: every Tier-2 copyfile source must exist, so we never create a
# half-written run directory. All missing sources are reported together (a
# better experience than failing on the first). Tier-1 object paths are not
# checked here -- they were already read (and thus required to exist) during
# discovery.
.wif_check_sources <- function(reg) {
	missing <- character(0)
	for (node in reg$nodes) {
		if (node$kind == "copyfile" && !file.exists(node$source_path)) {
			missing <- c(missing, sprintf("  \"%s\" (referenced by %s)",
				node$source_path, .wif_first_field(node)))
		}
	}
	if (length(missing) > 0) {
		stop(sprintf("Cannot find %d referenced file(s):\n%s",
			length(missing), paste(missing, collapse = "\n")), call. = FALSE)
	}
	invisible(NULL)
}

# Create a fresh, non-overwriting run directory `cdmetapop_run_<timestamp>`
# under `base_dir`. A numeric suffix disambiguates the (unlikely) case of two
# calls within the same second. Returns the created directory's path.
.wif_make_run_dir <- function(base_dir) {
	stamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
	run_dir <- file.path(base_dir, paste0("cdmetapop_run_", stamp))
	orig <- run_dir
	k <- 2L
	while (dir.exists(run_dir) || file.exists(run_dir)) {
		run_dir <- paste0(orig, "_", k)
		k <- k + 1L
	}
	dir.create(run_dir, recursive = TRUE)
	run_dir
}

# Write a RunVars object's full input-file graph to a fresh run directory.
#
# @param runvars A RunVars object (the top of the graph).
# @param base_dir Parent directory under which the fresh run directory is
#   created. Defaults to the working directory; launch_cdmetapop() (Task 8)
#   will expose this as an override.
# @return A list: `run_dir` (the created directory), `runvars_csv` (its
#   RunVars.csv path -- what launch hands Python), and `manifest` (its
#   manifest.csv path).
.write_cdmetapop_inputfiles <- function(runvars, base_dir = getwd()) {
	if (!inherits(runvars, "RunVars")) {
		stop("`runvars` must be a RunVars object.")
	}

	# Discover (reads any Tier-1 object paths -> errors here if those are
	# missing) and assign filenames, BEFORE creating any directory.
	reg <- .wif_discover_nodes(runvars)
	.wif_assign_names(reg)
	# Fail fast if any Tier-2 source file is missing (no half-written dir).
	.wif_check_sources(reg)

	# Create the fresh run directory, then write everything into it.
	run_dir <- .wif_make_run_dir(base_dir)
	for (node in reg$nodes) .wif_write_node(reg, node, run_dir)
	.wif_write_manifest(reg, run_dir)

	list(
		run_dir     = run_dir,
		runvars_csv = file.path(run_dir, "RunVars.csv"),
		manifest    = file.path(run_dir, "manifest.csv")
	)
}
