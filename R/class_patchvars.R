# PatchVars: R6 wrapper for CDMetaPOP's PatchVars.csv input file.
#
# A PatchVars.csv file holds one row per patch, with one column per
# patch-level parameter (carrying capacity, mortality, migration, growth,
# fitness, etc.). Like ClassVars (see class_classvars.R), this class stores
# that table internally as a data frame and exposes each *column* as an R6
# active binding, since users are expected to edit whole parameter columns
# (e.g. carrying capacity across all patches), not individual patch rows.
# Headers below are copied verbatim from example_files/patchvars/
# PatchVarsS1.csv, the package's canonical example (CDMetaPOP reads column
# *order*, not header text -- see class_classvars.R's top-of-file note).
#
# Scope note: CDMetaPOP's user manual (section "Patch level controls --
# PatchVars.csv file") also documents disease-related columns (Disease_file,
# Env Res, DiseaseDefense1_CC/Cc/cc, DiseaseDefense1_DD/Dd/dd) appended after
# comp_coef. These are intentionally NOT included here, since they are
# absent from PatchVarsS1.csv (the basic, non-disease canonical example this
# package's other defaults are drawn from); add them as a follow-up task if
# disease-model support is needed.

# Canonical column headers, in CDMetaPOP's expected order. "PatchID" is
# handled separately from the other columns (see `patch_id` active binding
# below), since it is immutable after construction and drives the row count
# for every other column (mirrors ClassVars' "Age class" handling).
.pv_headers <- c(
	"PatchID", "X", "Y", "SubpatchNO", "K", "K StDev", "N0", "Natal Grounds",
	"Migration Grounds", "Genes Initialize", "Class Vars", "Mortality Out %",
	"Mortality Out StDev", "Mortality Back", "Mortality Back StDev",
	"Mortality Eggs", "Mortality Eggs StDev", "Migration", "Set Migration",
	"Migration Back Prob", "Straying Prob", "Dispersal Prob",
	"GrowthTemperatureOut", "GrowthTemperatureOutStDev", "GrowDaysOut",
	"GrowDaysOutStDev", "GrowthTemperatureBack", "GrowthTemperatureBackStDev",
	"GrowDaysBack", "GrowDaysBackStDev", "Capture Probability Out",
	"Capture Probability Back", "HabitatOut", "HabitatBack", "Fitness_AA",
	"Fitness_Aa", "Fitness_aa", "Fitness_BB", "Fitness_Bb", "Fitness_bb",
	"Fitness_AABB", "Fitness_AaBB", "Fitness_aaBB", "Fitness_AABb",
	"Fitness_AaBb", "Fitness_aaBb", "Fitness_AAbb", "Fitness_Aabb",
	"Fitness_aabb", "comp_coef"
)

# snake_case field names, in the same order as `.pv_headers[-1]` (i.e.
# excluding "PatchID"). Genotype-suffixed fitness fields keep their
# original mixed case (e.g. `fitness_Aa` vs `fitness_aa`) since fully
# lowercasing would collide two distinct genotypes onto one name.
.pv_fields <- c(
	"x", "y", "subpatch_no", "k", "k_stdev", "n0", "natal_grounds",
	"migration_grounds", "genes_initialize", "class_vars", "mortality_out",
	"mortality_out_stdev", "mortality_back", "mortality_back_stdev",
	"mortality_eggs", "mortality_eggs_stdev", "migration", "set_migration",
	"migration_back_prob", "straying_prob", "dispersal_prob",
	"growth_temp_out", "growth_temp_out_stdev", "grow_days_out",
	"grow_days_out_stdev", "growth_temp_back", "growth_temp_back_stdev",
	"grow_days_back", "grow_days_back_stdev", "capture_prob_out",
	"capture_prob_back", "habitat_out", "habitat_back", "fitness_AA",
	"fitness_Aa", "fitness_aa", "fitness_BB", "fitness_Bb", "fitness_bb",
	"fitness_AABB", "fitness_AaBB", "fitness_aaBB", "fitness_AABb",
	"fitness_AaBb", "fitness_aaBb", "fitness_AAbb", "fitness_Aabb",
	"fitness_aabb", "comp_coef"
)

# Default values taken from example_files/patchvars/PatchVarsS1.csv (the
# basic, 7-patch example referenced by this package's default RunVars.csv /
# PopVars.csv pair, and the same file ClassVars_AS1.csv's PatchVars-level
# counterpart). One 7-element vector per column, indexed by patch (patch 1
# is element 1, patch 2 is element 2, etc.). Used by .pv_default_for() to
# fill in any column a user does not specify at construction.
.pv_s1_defaults <- list(
	x = c(2540470.832, 2536859.926, 2532969.44, 2539041.489, 2535011.582, 2545325.475, 2527429.642),
	y = c(712452.2021, 708059.4624, 705413.5711, 728416.6747, 720257.8531, 726552.0418, 708511.8011),
	subpatch_no = c("1", "1", "2", "2", "3", "3", "3"),
	k = rep(300, 7),
	k_stdev = rep(0, 7),
	n0 = rep(150, 7),
	natal_grounds = rep(1, 7),
	migration_grounds = rep(1, 7),
	genes_initialize = c("genes/allelefrequencyA.csv", rep("random", 6)),
	class_vars = rep("classvars/ClassVars_AS1.csv", 7),
	mortality_out = rep(0, 7),
	mortality_out_stdev = rep(0, 7),
	mortality_back = rep(0, 7),
	mortality_back_stdev = rep(0, 7),
	mortality_eggs = rep(0, 7),
	mortality_eggs_stdev = rep(0, 7),
	migration = rep(1, 7),
	set_migration = rep("Y", 7),
	migration_back_prob = rep(1, 7),
	straying_prob = rep(1, 7),
	dispersal_prob = rep(1, 7),
	growth_temp_out = rep(1, 7),
	growth_temp_out_stdev = c(0, 0.2, 0.1, 1, 0.4, 0.2, 0),
	grow_days_out = c(155, 150, 150, 150, 150, 150, 150),
	grow_days_out_stdev = c(0, 20, 20, 20, 20, 20, 20),
	growth_temp_back = c(14, 18, 22, 8, 8, 8, 8),
	growth_temp_back_stdev = rep(0, 7),
	grow_days_back = c(210, 150, 150, 150, 150, 150, 150),
	grow_days_back_stdev = c(0, 20, 20, 20, 20, 20, 20),
	capture_prob_out = rep("N", 7),
	capture_prob_back = rep("N", 7),
	habitat_out = rep(1, 7),
	habitat_back = rep(1, 7),
	fitness_AA = rep(0, 7), fitness_Aa = rep(0, 7), fitness_aa = rep(0, 7),
	fitness_BB = rep(0, 7), fitness_Bb = rep(0, 7), fitness_bb = rep(0, 7),
	fitness_AABB = rep(0, 7), fitness_AaBB = rep(0, 7), fitness_aaBB = rep(0, 7),
	fitness_AABb = rep(0, 7), fitness_AaBb = rep(0, 7), fitness_aaBb = rep(0, 7),
	fitness_AAbb = rep(0, 7), fitness_Aabb = rep(0, 7), fitness_aabb = rep(0, 7),
	comp_coef = rep("0.5;0.1", 7)
)

# Validation rule for each column, drawn from CDMetaPOP's user manual
# ("Patch level controls -- PatchVars.csv file" section) and cross-checked
# against PatchVarsS1.csv. Each rule has a `type`:
#   - "numeric": a bare number within [lower, upper] (NA bound =
#     unbounded); "N" additionally allowed if allow_N; "E" additionally
#     allowed if allow_E (CDMetaPOP's "eradication" override, only
#     documented for the three Mortality columns).
#   - "binary01": must be exactly 0 or 1 (Natal Grounds, Migration
#     Grounds -- on/off flags for occupancy).
#   - "YN": must be exactly "Y" or "N" (Set Migration).
#   - "free_numeric": any finite number, unbounded (coordinates, habitat
#     quality -- no documented constraint beyond "is a number").
#   - "free_char": any non-NA scalar, stored as character -- used for
#     fields whose valid format depends on context this package does not
#     yet model (e.g. Fitness_* depends on PopVars$cdevolveans, not
#     implemented yet; comp_coef is a ';'-separated list sized to the
#     number of species in the RunVars$Popvars list, not yet implemented).
#     Validation here is deliberately permissive; revisit once PopVars/
#     RunVars exist and these dependencies can be checked for real.
#   - "genes_initialize": a path string (or ';'-separated multiple paths),
#     or the literal keywords "random"/"random_var". Not yet able to hold
#     an AlleleFrequency object directly, since that class does not exist
#     yet (see plan.md Proposed Task Order) -- revisit when it does.
#   - "class_vars": either a ClassVars object (see class_classvars.R) or a
#     character path string (or ';'-separated multiple paths), per plan.md
#     Key Design Decision 2's object-or-path generalization.
.pv_rules <- list(
	x                          = list(type = "free_numeric"),
	y                          = list(type = "free_numeric"),
	subpatch_no                = list(type = "free_char"),
	k                          = list(type = "numeric", lower = 0, upper = Inf, allow_N = FALSE, allow_E = FALSE),
	k_stdev                    = list(type = "numeric", lower = 0, upper = Inf, allow_N = FALSE, allow_E = FALSE),
	n0                         = list(type = "numeric", lower = 0, upper = Inf, allow_N = FALSE, allow_E = FALSE),
	natal_grounds              = list(type = "binary01"),
	migration_grounds          = list(type = "binary01"),
	genes_initialize           = list(type = "genes_initialize"),
	class_vars                 = list(type = "class_vars"),
	mortality_out              = list(type = "numeric", lower = 0, upper = 1,   allow_N = TRUE,  allow_E = TRUE),
	mortality_out_stdev        = list(type = "numeric", lower = 0, upper = Inf, allow_N = TRUE,  allow_E = TRUE),
	mortality_back             = list(type = "numeric", lower = 0, upper = 1,   allow_N = TRUE,  allow_E = TRUE),
	mortality_back_stdev       = list(type = "numeric", lower = 0, upper = Inf, allow_N = TRUE,  allow_E = TRUE),
	mortality_eggs             = list(type = "numeric", lower = 0, upper = 1,   allow_N = TRUE,  allow_E = TRUE),
	mortality_eggs_stdev       = list(type = "numeric", lower = 0, upper = Inf, allow_N = TRUE,  allow_E = TRUE),
	migration                  = list(type = "numeric", lower = 0, upper = 1,   allow_N = FALSE, allow_E = FALSE),
	set_migration              = list(type = "YN"),
	migration_back_prob        = list(type = "numeric", lower = 0, upper = 1,   allow_N = FALSE, allow_E = FALSE),
	straying_prob               = list(type = "numeric", lower = 0, upper = 1,   allow_N = FALSE, allow_E = FALSE),
	dispersal_prob             = list(type = "numeric", lower = 0, upper = 1,   allow_N = FALSE, allow_E = FALSE),
	growth_temp_out            = list(type = "numeric", lower = -Inf, upper = Inf, allow_N = TRUE,  allow_E = FALSE),
	growth_temp_out_stdev      = list(type = "numeric", lower = 0, upper = Inf, allow_N = FALSE, allow_E = FALSE),
	grow_days_out              = list(type = "numeric", lower = 0, upper = 365, allow_N = TRUE,  allow_E = FALSE),
	grow_days_out_stdev        = list(type = "numeric", lower = 0, upper = Inf, allow_N = FALSE, allow_E = FALSE),
	growth_temp_back           = list(type = "numeric", lower = -Inf, upper = Inf, allow_N = TRUE,  allow_E = FALSE),
	growth_temp_back_stdev     = list(type = "numeric", lower = 0, upper = Inf, allow_N = FALSE, allow_E = FALSE),
	grow_days_back             = list(type = "numeric", lower = 0, upper = 365, allow_N = TRUE,  allow_E = FALSE),
	grow_days_back_stdev       = list(type = "numeric", lower = 0, upper = Inf, allow_N = FALSE, allow_E = FALSE),
	capture_prob_out           = list(type = "numeric", lower = 0, upper = 1,   allow_N = TRUE,  allow_E = FALSE),
	capture_prob_back          = list(type = "numeric", lower = 0, upper = 1,   allow_N = TRUE,  allow_E = FALSE),
	habitat_out                = list(type = "free_numeric"),
	habitat_back               = list(type = "free_numeric"),
	fitness_AA = list(type = "free_char"), fitness_Aa = list(type = "free_char"), fitness_aa = list(type = "free_char"),
	fitness_BB = list(type = "free_char"), fitness_Bb = list(type = "free_char"), fitness_bb = list(type = "free_char"),
	fitness_AABB = list(type = "free_char"), fitness_AaBB = list(type = "free_char"), fitness_aaBB = list(type = "free_char"),
	fitness_AABb = list(type = "free_char"), fitness_AaBb = list(type = "free_char"), fitness_aaBb = list(type = "free_char"),
	fitness_AAbb = list(type = "free_char"), fitness_Aabb = list(type = "free_char"), fitness_aabb = list(type = "free_char"),
	comp_coef = list(type = "free_char")
)

#' Validate and normalize one PatchVars column
#'
#' Internal helper used by every PatchVars active binding except
#' `class_vars`, which is handled separately by `.validate_pv_class_vars()`
#' since it is the one column that can hold R6 objects rather than plain
#' values, and so cannot be stored as a vector in `private$data` the way
#' every other column is.
#'
#' @param field snake_case column name (must be in `.pv_fields`, excluding
#'   `"class_vars"`).
#' @param values Vector of values to validate; recycled to length `n` if it
#'   has length 1.
#' @param n Expected length (the number of patches already defined on the
#'   object).
#' @return A validated vector of length `n`: numeric for "numeric"/
#'   "binary01"/"free_numeric" columns whose rule forbids non-numeric
#'   literals, character otherwise.
#' @keywords internal
.validate_pv_field <- function(field, values, n) {
	rule <- .pv_rules[[field]]
	if (length(values) == 1) values <- rep(values, n)
	if (length(values) != n) {
		stop(sprintf(
			"`%s` must have length 1 or %d (the number of patches), not %d.",
			field, n, length(values)
		))
	}

	if (rule$type == "free_char") {
		if (anyNA(values)) stop(sprintf("`%s` cannot contain NA.", field))
		return(as.character(values))
	}

	if (rule$type == "free_numeric") {
		out <- suppressWarnings(as.numeric(values))
		if (anyNA(out)) {
			stop(sprintf("`%s` must contain only numbers.", field))
		}
		return(out)
	}

	if (rule$type == "binary01") {
		out <- suppressWarnings(as.numeric(values))
		if (anyNA(out) || any(!out %in% c(0, 1))) {
			stop(sprintf("`%s` must be 0 or 1 for every patch.", field))
		}
		return(out)
	}

	if (rule$type == "YN") {
		out <- as.character(values)
		if (any(!out %in% c("Y", "N"))) {
			stop(sprintf("`%s` must be \"Y\" or \"N\" for every patch.", field))
		}
		return(out)
	}

	if (rule$type == "genes_initialize") {
		out <- as.character(values)
		if (anyNA(out)) stop(sprintf("`%s` cannot contain NA.", field))
		return(out)
	}

	# rule$type == "numeric" from here on.
	as_character_storage <- rule$allow_N || rule$allow_E
	out <- vector(if (as_character_storage) "character" else "numeric", n)
	for (i in seq_len(n)) {
		val <- values[i]
		if (rule$allow_N && identical(as.character(val), "N")) {
			out[i] <- "N"
			next
		}
		if (rule$allow_E && identical(as.character(val), "E")) {
			out[i] <- "E"
			next
		}
		num <- suppressWarnings(as.numeric(val))
		if (is.na(num)) {
			stop(sprintf(
				"`%s`[%d] = \"%s\" is not a valid value (expected a number%s%s).",
				field, i, val,
				if (rule$allow_N) ", \"N\"" else "",
				if (rule$allow_E) ", \"E\"" else ""
			))
		}
		if (num < rule$lower || num > rule$upper) {
			stop(sprintf(
				"`%s`[%d] = %s is outside the allowed range [%s, %s].",
				field, i, num, rule$lower, rule$upper
			))
		}
		out[i] <- if (as_character_storage) as.character(num) else num
	}
	out
}

#' Validate and normalize the `class_vars` column
#'
#' Each element may be either a [ClassVars()] object directly, or a
#' character path (optionally multiple paths separated by `;`, per the
#' user manual). Stored as a list column (rather than an atomic vector)
#' since R6 objects cannot be stored in a plain character/numeric vector.
#'
#' @param values A single value, or a list/vector of length `n`, each
#'   element a ClassVars object or a character path.
#' @param n Expected length (the number of patches).
#' @return A list of length `n`.
#' @keywords internal
.validate_pv_class_vars <- function(values, n) {
	# A single ClassVars object is itself an R6 environment, not a list of
	# per-patch values -- as.list() on it would wrongly unroll its internal
	# fields/methods into separate list elements. Detect and recycle it (or
	# a single bare character path) as one scalar value before falling
	# back to as.list() for genuine vectors/lists of per-patch values.
	is_scalar_value <- inherits(values, "ClassVars") ||
		(is.character(values) && length(values) == 1)
	if (is_scalar_value) {
		values <- rep(list(values), n)
	} else if (!is.list(values)) {
		values <- as.list(values)
	}
	if (length(values) == 1 && n != 1) values <- rep(values, n)
	if (length(values) != n) {
		stop(sprintf(
			"`class_vars` must have length 1 or %d (the number of patches), not %d.",
			n, length(values)
		))
	}
	for (i in seq_len(n)) {
		val <- values[[i]]
		if (!inherits(val, "ClassVars") && !(is.character(val) && length(val) == 1 && !is.na(val))) {
			stop(sprintf(
				"`class_vars`[%d] must be a ClassVars object or a single character path, not %s.",
				i, class(val)[1]
			))
		}
	}
	values
}

# Default values for one PatchVars column, for a given set of patch ids.
# Looks up `.pv_s1_defaults` by patch index. Patches beyond what
# PatchVarsS1.csv defines (i.e. above patch 7) have no principled default,
# so the last defined default (patch 7) is recycled, with a warning (see
# class_classvars.R's `.cv_default_for()`, which this mirrors).
.pv_default_for <- function(field, patch_ids) {
	defaults <- .pv_s1_defaults[[field]]
	n <- length(patch_ids)
	if (n <= length(defaults)) return(defaults[patch_ids])

	c(defaults, rep(defaults[length(defaults)], n - length(defaults)))
}

# The R6 generator itself is not exported; users construct instances via
# the PatchVars() wrapper function below. See class_classvars.R's note
# above `.ClassVarsR6` for why this is wrapped in local() + `#' @noRd`
# (roxygen2 would otherwise auto-document every active binding/method).

#' @noRd
.PatchVarsR6 <- local(R6::R6Class("PatchVars",
	public = list(
		initialize = function(
			patch_id = 1:7,
			x = NULL, y = NULL, subpatch_no = NULL, k = NULL, k_stdev = NULL,
			n0 = NULL, natal_grounds = NULL, migration_grounds = NULL,
			genes_initialize = NULL, class_vars = NULL, mortality_out = NULL,
			mortality_out_stdev = NULL, mortality_back = NULL,
			mortality_back_stdev = NULL, mortality_eggs = NULL,
			mortality_eggs_stdev = NULL, migration = NULL, set_migration = NULL,
			migration_back_prob = NULL, straying_prob = NULL,
			dispersal_prob = NULL, growth_temp_out = NULL,
			growth_temp_out_stdev = NULL, grow_days_out = NULL,
			grow_days_out_stdev = NULL, growth_temp_back = NULL,
			growth_temp_back_stdev = NULL, grow_days_back = NULL,
			grow_days_back_stdev = NULL, capture_prob_out = NULL,
			capture_prob_back = NULL, habitat_out = NULL, habitat_back = NULL,
			fitness_AA = NULL, fitness_Aa = NULL, fitness_aa = NULL,
			fitness_BB = NULL, fitness_Bb = NULL, fitness_bb = NULL,
			fitness_AABB = NULL, fitness_AaBB = NULL, fitness_aaBB = NULL,
			fitness_AABb = NULL, fitness_AaBb = NULL, fitness_aaBb = NULL,
			fitness_AAbb = NULL, fitness_Aabb = NULL, fitness_aabb = NULL,
			comp_coef = NULL,
			location = NULL
		) {
			# `patch_id` must be sequential integers starting at 1 (per the
			# user manual: "Begin label 1 through n in consecutive order").
			# Immutable after construction -- see the `patch_id` active
			# binding -- changing the number of patches is handled via
			# add_row(), not by re-setting `patch_id` directly.
			if (!is.numeric(patch_id) || anyNA(patch_id) ||
					!identical(as.numeric(patch_id), as.numeric(seq_len(length(patch_id))))) {
				stop("`patch_id` must be sequential integers starting at 1 (e.g. 1:7 or c(1, 2, 3)).")
			}
			patch_id <- as.integer(patch_id)
			n <- length(patch_id)

			# Collect the user-supplied column arguments by name so they can
			# be looped over alongside `.pv_fields` below, rather than
			# writing out 49 near-identical "if not supplied, use default"
			# blocks by hand (mirrors ClassVars' `initialize()`).
			supplied <- list(
				x = x, y = y, subpatch_no = subpatch_no, k = k, k_stdev = k_stdev,
				n0 = n0, natal_grounds = natal_grounds, migration_grounds = migration_grounds,
				genes_initialize = genes_initialize, class_vars = class_vars,
				mortality_out = mortality_out, mortality_out_stdev = mortality_out_stdev,
				mortality_back = mortality_back, mortality_back_stdev = mortality_back_stdev,
				mortality_eggs = mortality_eggs, mortality_eggs_stdev = mortality_eggs_stdev,
				migration = migration, set_migration = set_migration,
				migration_back_prob = migration_back_prob, straying_prob = straying_prob,
				dispersal_prob = dispersal_prob, growth_temp_out = growth_temp_out,
				growth_temp_out_stdev = growth_temp_out_stdev, grow_days_out = grow_days_out,
				grow_days_out_stdev = grow_days_out_stdev, growth_temp_back = growth_temp_back,
				growth_temp_back_stdev = growth_temp_back_stdev, grow_days_back = grow_days_back,
				grow_days_back_stdev = grow_days_back_stdev, capture_prob_out = capture_prob_out,
				capture_prob_back = capture_prob_back, habitat_out = habitat_out, habitat_back = habitat_back,
				fitness_AA = fitness_AA, fitness_Aa = fitness_Aa, fitness_aa = fitness_aa,
				fitness_BB = fitness_BB, fitness_Bb = fitness_Bb, fitness_bb = fitness_bb,
				fitness_AABB = fitness_AABB, fitness_AaBB = fitness_AaBB, fitness_aaBB = fitness_aaBB,
				fitness_AABb = fitness_AABb, fitness_AaBb = fitness_AaBb, fitness_aaBb = fitness_aaBb,
				fitness_AAbb = fitness_AAbb, fitness_Aabb = fitness_Aabb, fitness_aabb = fitness_aabb,
				comp_coef = comp_coef
			)

			private$data <- as.data.frame(matrix(nrow = n, ncol = length(.pv_headers)))
			colnames(private$data) <- .pv_headers
			private$data[["PatchID"]] <- patch_id
			# "Class Vars" is a list column (can hold ClassVars objects), so
			# it must be assigned via `[[<-`, not the matrix-fill above.
			private$data[["Class Vars"]] <- vector("list", n)

			# PatchVarsS1.csv only defines defaults for patches 1-7. If more
			# patches are requested and any column is left unspecified, warn
			# once (not once per column) that the patch-7 default is being
			# recycled for those extra patches.
			max_default_n <- length(.pv_s1_defaults[[1]])
			any_unspecified <- any(vapply(supplied, is.null, logical(1)))
			if (n > max_default_n && any_unspecified) {
				warning(sprintf(
					"No default values exist in PatchVarsS1.csv for patches above %d; the patch-%d default is being recycled for any unspecified column on the extra patches.",
					max_default_n, max_default_n
				), call. = FALSE)
			}

			for (field in .pv_fields) {
				raw <- supplied[[field]]
				if (is.null(raw)) raw <- .pv_default_for(field, patch_id)
				header <- .pv_headers[match(field, .pv_fields) + 1]
				if (field == "class_vars") {
					private$data[["Class Vars"]] <- private$validate_class_vars(raw)
				} else {
					private$data[[header]] <- private$validate(field, raw)
				}
			}

			private$location_path <- location
		},

		# Add one or more patches, copying the current last row. All new
		# rows are initialized as a copy of the current last patch; edit the
		# new row(s) afterward via the column active bindings. Unlike
		# ClassVars' add_row() (where copying the last age class is a
		# meaningful default), copying the last patch's coordinates/fitness
		# values is mostly a placeholder -- this is a deliberate reuse of
		# the established convention for consistency, not a claim that it is
		# semantically ideal for patches; users are expected to overwrite at
		# least `x`/`y` afterward.
		add_row = function(n = 1) {
			last_row <- private$data[nrow(private$data), , drop = FALSE]
			new_rows <- last_row[rep(1, n), , drop = FALSE]
			new_rows[["PatchID"]] <- seq(max(private$data[["PatchID"]]) + 1, length.out = n)
			private$data <- rbind(private$data, new_rows)
			# See class_classvars.R's add_row() for why row names are reset.
			rownames(private$data) <- NULL
			invisible(self)
		},

		# Write this PatchVars object to a csv file. `path` defaults to this
		# object's `location` field if not supplied. The `Class Vars`
		# column is resolved from a list column (objects or paths) to plain
		# path strings at write time: any ClassVars object must itself have
		# a `location` set (this does NOT recursively write the nested
		# ClassVars file -- that orchestration belongs to the "write object
		# graph to disk" routine in plan.md's Proposed Task Order, not here).
		write_cdmetapop = function(path = NULL) {
			if (is.null(path)) path <- private$location_path
			if (is.null(path)) {
				stop("No `path` supplied and no `location` set on this PatchVars object.")
			}
			out <- private$data
			out[["Class Vars"]] <- vapply(private$data[["Class Vars"]], function(val) {
				if (inherits(val, "ClassVars")) {
					loc <- val$location
					if (is.null(loc)) {
						stop("A `class_vars` entry holds a ClassVars object with no `location` set; set one (or write it manually) before writing this PatchVars object.")
					}
					loc
				} else {
					val
				}
			}, character(1))
			utils::write.csv(out, path, row.names = FALSE, quote = FALSE)
			invisible(path)
		},

		print = function(...) {
			cat("<PatchVars>", nrow(private$data), "patches\n")
			out <- private$data
			out[["Class Vars"]] <- vapply(out[["Class Vars"]], function(val) {
				if (inherits(val, "ClassVars")) "<ClassVars object>" else val
			}, character(1))
			print(out)
			invisible(self)
		},

		# Returns a plain (independent) copy of the underlying table -- see
		# class_classvars.R's as_data_frame() for rationale. The `Class
		# Vars` list column is left as-is (still possibly holding ClassVars
		# objects), since collapsing it to character here would silently
		# lose information for callers who want the actual objects.
		as_data_frame = function() private$data
	),

	private = list(
		data = NULL,
		location_path = NULL,

		validate = function(field, values) {
			.validate_pv_field(field, values, nrow(private$data))
		},
		validate_class_vars = function(values) {
			.validate_pv_class_vars(values, nrow(private$data))
		}
	),

	active = list(
		patch_id = function(value) {
			if (missing(value)) return(private$data[["PatchID"]])
			stop("`patch_id` cannot be reassigned after construction; create a new PatchVars() object (or use add_row()) instead.")
		},
		x = function(value) {
			if (missing(value)) return(private$data[["X"]])
			private$data[["X"]] <- private$validate("x", value)
		},
		y = function(value) {
			if (missing(value)) return(private$data[["Y"]])
			private$data[["Y"]] <- private$validate("y", value)
		},
		subpatch_no = function(value) {
			if (missing(value)) return(private$data[["SubpatchNO"]])
			private$data[["SubpatchNO"]] <- private$validate("subpatch_no", value)
		},
		k = function(value) {
			if (missing(value)) return(private$data[["K"]])
			private$data[["K"]] <- private$validate("k", value)
		},
		k_stdev = function(value) {
			if (missing(value)) return(private$data[["K StDev"]])
			private$data[["K StDev"]] <- private$validate("k_stdev", value)
		},
		n0 = function(value) {
			if (missing(value)) return(private$data[["N0"]])
			private$data[["N0"]] <- private$validate("n0", value)
		},
		natal_grounds = function(value) {
			if (missing(value)) return(private$data[["Natal Grounds"]])
			private$data[["Natal Grounds"]] <- private$validate("natal_grounds", value)
		},
		migration_grounds = function(value) {
			if (missing(value)) return(private$data[["Migration Grounds"]])
			private$data[["Migration Grounds"]] <- private$validate("migration_grounds", value)
		},
		genes_initialize = function(value) {
			if (missing(value)) return(private$data[["Genes Initialize"]])
			private$data[["Genes Initialize"]] <- private$validate("genes_initialize", value)
		},
		class_vars = function(value) {
			if (missing(value)) return(private$data[["Class Vars"]])
			private$data[["Class Vars"]] <- private$validate_class_vars(value)
		},
		mortality_out = function(value) {
			if (missing(value)) return(private$data[["Mortality Out %"]])
			private$data[["Mortality Out %"]] <- private$validate("mortality_out", value)
		},
		mortality_out_stdev = function(value) {
			if (missing(value)) return(private$data[["Mortality Out StDev"]])
			private$data[["Mortality Out StDev"]] <- private$validate("mortality_out_stdev", value)
		},
		mortality_back = function(value) {
			if (missing(value)) return(private$data[["Mortality Back"]])
			private$data[["Mortality Back"]] <- private$validate("mortality_back", value)
		},
		mortality_back_stdev = function(value) {
			if (missing(value)) return(private$data[["Mortality Back StDev"]])
			private$data[["Mortality Back StDev"]] <- private$validate("mortality_back_stdev", value)
		},
		mortality_eggs = function(value) {
			if (missing(value)) return(private$data[["Mortality Eggs"]])
			private$data[["Mortality Eggs"]] <- private$validate("mortality_eggs", value)
		},
		mortality_eggs_stdev = function(value) {
			if (missing(value)) return(private$data[["Mortality Eggs StDev"]])
			private$data[["Mortality Eggs StDev"]] <- private$validate("mortality_eggs_stdev", value)
		},
		migration = function(value) {
			if (missing(value)) return(private$data[["Migration"]])
			private$data[["Migration"]] <- private$validate("migration", value)
		},
		set_migration = function(value) {
			if (missing(value)) return(private$data[["Set Migration"]])
			private$data[["Set Migration"]] <- private$validate("set_migration", value)
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
		growth_temp_out = function(value) {
			if (missing(value)) return(private$data[["GrowthTemperatureOut"]])
			private$data[["GrowthTemperatureOut"]] <- private$validate("growth_temp_out", value)
		},
		growth_temp_out_stdev = function(value) {
			if (missing(value)) return(private$data[["GrowthTemperatureOutStDev"]])
			private$data[["GrowthTemperatureOutStDev"]] <- private$validate("growth_temp_out_stdev", value)
		},
		grow_days_out = function(value) {
			if (missing(value)) return(private$data[["GrowDaysOut"]])
			private$data[["GrowDaysOut"]] <- private$validate("grow_days_out", value)
		},
		grow_days_out_stdev = function(value) {
			if (missing(value)) return(private$data[["GrowDaysOutStDev"]])
			private$data[["GrowDaysOutStDev"]] <- private$validate("grow_days_out_stdev", value)
		},
		growth_temp_back = function(value) {
			if (missing(value)) return(private$data[["GrowthTemperatureBack"]])
			private$data[["GrowthTemperatureBack"]] <- private$validate("growth_temp_back", value)
		},
		growth_temp_back_stdev = function(value) {
			if (missing(value)) return(private$data[["GrowthTemperatureBackStDev"]])
			private$data[["GrowthTemperatureBackStDev"]] <- private$validate("growth_temp_back_stdev", value)
		},
		grow_days_back = function(value) {
			if (missing(value)) return(private$data[["GrowDaysBack"]])
			private$data[["GrowDaysBack"]] <- private$validate("grow_days_back", value)
		},
		grow_days_back_stdev = function(value) {
			if (missing(value)) return(private$data[["GrowDaysBackStDev"]])
			private$data[["GrowDaysBackStDev"]] <- private$validate("grow_days_back_stdev", value)
		},
		capture_prob_out = function(value) {
			if (missing(value)) return(private$data[["Capture Probability Out"]])
			private$data[["Capture Probability Out"]] <- private$validate("capture_prob_out", value)
		},
		capture_prob_back = function(value) {
			if (missing(value)) return(private$data[["Capture Probability Back"]])
			private$data[["Capture Probability Back"]] <- private$validate("capture_prob_back", value)
		},
		habitat_out = function(value) {
			if (missing(value)) return(private$data[["HabitatOut"]])
			private$data[["HabitatOut"]] <- private$validate("habitat_out", value)
		},
		habitat_back = function(value) {
			if (missing(value)) return(private$data[["HabitatBack"]])
			private$data[["HabitatBack"]] <- private$validate("habitat_back", value)
		},
		fitness_AA = function(value) {
			if (missing(value)) return(private$data[["Fitness_AA"]])
			private$data[["Fitness_AA"]] <- private$validate("fitness_AA", value)
		},
		fitness_Aa = function(value) {
			if (missing(value)) return(private$data[["Fitness_Aa"]])
			private$data[["Fitness_Aa"]] <- private$validate("fitness_Aa", value)
		},
		fitness_aa = function(value) {
			if (missing(value)) return(private$data[["Fitness_aa"]])
			private$data[["Fitness_aa"]] <- private$validate("fitness_aa", value)
		},
		fitness_BB = function(value) {
			if (missing(value)) return(private$data[["Fitness_BB"]])
			private$data[["Fitness_BB"]] <- private$validate("fitness_BB", value)
		},
		fitness_Bb = function(value) {
			if (missing(value)) return(private$data[["Fitness_Bb"]])
			private$data[["Fitness_Bb"]] <- private$validate("fitness_Bb", value)
		},
		fitness_bb = function(value) {
			if (missing(value)) return(private$data[["Fitness_bb"]])
			private$data[["Fitness_bb"]] <- private$validate("fitness_bb", value)
		},
		fitness_AABB = function(value) {
			if (missing(value)) return(private$data[["Fitness_AABB"]])
			private$data[["Fitness_AABB"]] <- private$validate("fitness_AABB", value)
		},
		fitness_AaBB = function(value) {
			if (missing(value)) return(private$data[["Fitness_AaBB"]])
			private$data[["Fitness_AaBB"]] <- private$validate("fitness_AaBB", value)
		},
		fitness_aaBB = function(value) {
			if (missing(value)) return(private$data[["Fitness_aaBB"]])
			private$data[["Fitness_aaBB"]] <- private$validate("fitness_aaBB", value)
		},
		fitness_AABb = function(value) {
			if (missing(value)) return(private$data[["Fitness_AABb"]])
			private$data[["Fitness_AABb"]] <- private$validate("fitness_AABb", value)
		},
		fitness_AaBb = function(value) {
			if (missing(value)) return(private$data[["Fitness_AaBb"]])
			private$data[["Fitness_AaBb"]] <- private$validate("fitness_AaBb", value)
		},
		fitness_aaBb = function(value) {
			if (missing(value)) return(private$data[["Fitness_aaBb"]])
			private$data[["Fitness_aaBb"]] <- private$validate("fitness_aaBb", value)
		},
		fitness_AAbb = function(value) {
			if (missing(value)) return(private$data[["Fitness_AAbb"]])
			private$data[["Fitness_AAbb"]] <- private$validate("fitness_AAbb", value)
		},
		fitness_Aabb = function(value) {
			if (missing(value)) return(private$data[["Fitness_Aabb"]])
			private$data[["Fitness_Aabb"]] <- private$validate("fitness_Aabb", value)
		},
		fitness_aabb = function(value) {
			if (missing(value)) return(private$data[["Fitness_aabb"]])
			private$data[["Fitness_aabb"]] <- private$validate("fitness_aabb", value)
		},
		comp_coef = function(value) {
			if (missing(value)) return(private$data[["comp_coef"]])
			private$data[["comp_coef"]] <- private$validate("comp_coef", value)
		},
		location = function(value) {
			if (missing(value)) return(private$location_path)
			if (!is.null(value) && (!is.character(value) || length(value) != 1)) {
				stop("`location` must be a single character path, or NULL.")
			}
			private$location_path <- value
		}
	)
))

#' Create a PatchVars object
#'
#' Constructs an R6 object representing a CDMetaPOP `PatchVars.csv` input
#' file: one row per patch, with one column per patch-level parameter
#' (carrying capacity, mortality, migration, growth, fitness, etc.). Columns
#' are edited as a whole after construction via `$`, e.g.
#' `mypatchvars$k <- c(300, 300, 500)`.
#'
#' Any column argument left as `NULL` defaults to the corresponding values
#' in `example_files/patchvars/PatchVarsS1.csv`, matched to each requested
#' patch (recycling the patch-7 default, with a warning, for patches beyond
#' what that file defines).
#'
#' @param patch_id Integer vector of sequential patches starting at 1 (e.g.
#'   `1:7`). Determines the number of rows; cannot be changed after
#'   construction (use `add_row()` or [add_rows()] instead).
#' @param x,y Coordinate locations for each patch.
#' @param subpatch_no Identifier (numeric or character) tagging individuals
#'   to a particular region; reported in output files.
#' @param k,k_stdev Carrying capacity and its annual standard deviation. `0`
#'   means individuals cannot move into the patch.
#' @param n0 Number of individuals to initialize the patch at year 0.
#' @param natal_grounds,migration_grounds `0`/`1` flags for whether
#'   individuals may occupy the patch at natal grounds ("back") or
#'   migration/overwintering grounds ("out") respectively.
#' @param genes_initialize Genotype initialization: `"random"`,
#'   `"random_var"`, or an allele-frequency file path (`;`-separated for
#'   multiple).
#' @param class_vars A [ClassVars()] object, or a character path to a
#'   ClassVars csv (`;`-separated for multiple), governing this patch.
#' @param mortality_out,mortality_back,mortality_eggs Density-independent
#'   mortality `[0, 1]`, `"N"` (no patch-level mortality), or `"E"`
#'   (eradication override).
#' @param mortality_out_stdev,mortality_back_stdev,mortality_eggs_stdev
#'   Standard deviation for the above; numeric, `"N"`, or `"E"`.
#' @param migration Emigration probability `[0, 1]`.
#' @param set_migration `"Y"` or `"N"`: whether a migrant individual stays a
#'   migrant with probability 1.
#' @param migration_back_prob,straying_prob,dispersal_prob Movement
#'   probabilities `[0, 1]`.
#' @param growth_temp_out,growth_temp_back Temperature values influencing
#'   body size growth; numeric or `"N"` (turn off).
#' @param growth_temp_out_stdev,growth_temp_back_stdev Standard deviation
#'   for the above; numeric.
#' @param grow_days_out,grow_days_back Growing days `[0, 365]`, or `"N"`
#'   (ignored).
#' @param grow_days_out_stdev,grow_days_back_stdev Standard deviation for
#'   the above; numeric.
#' @param capture_prob_out,capture_prob_back Capture/detection probability
#'   `[0, 1]`, or `"N"` (ignore).
#' @param habitat_out,habitat_back Habitat quality values for the
#'   plasticity module.
#' @param fitness_AA,fitness_Aa,fitness_aa,fitness_BB,fitness_Bb,fitness_bb,
#'   fitness_AABB,fitness_AaBB,fitness_aaBB,fitness_AABb,fitness_AaBb,
#'   fitness_aaBb,fitness_AAbb,fitness_Aabb,fitness_aabb Genotype-specific
#'   fitness/selection values; format depends on `PopVars$cdevolveans`
#'   (not yet implemented), so validation here is permissive.
#' @param comp_coef Lotka-Volterra competition coefficient(s) for
#'   multispecies applications, `;`-separated if more than 2 species.
#' @param location Optional file path where this object should be written
#'   by default when [write_cdmetapop()] is called without a `path`.
#'
#' @return An R6 `PatchVars` object.
#' @export
#'
#' @examples
#' # Default 7-patch object, matching PatchVarsS1.csv:
#' mypatchvars <- PatchVars()
#'
#' # 3 patches, defaults taken from PatchVarsS1.csv's first 3 rows:
#' mypatchvars <- PatchVars(patch_id = 1:3)
#'
#' # Edit a column in place:
#' mypatchvars$k <- c(300, 300, 500)
#'
#' # Add a patch (copies the last row; edit afterward):
#' mypatchvars$add_row()
#' # or equivalently:
#' add_rows(mypatchvars)
PatchVars <- function(
	patch_id = 1:7,
	x = c(2540470.832, 2536859.926, 2532969.44, 2539041.489, 2535011.582, 2545325.475, 2527429.642),
	y = c(712452.2021, 708059.4624, 705413.5711, 728416.6747, 720257.8531, 726552.0418, 708511.8011),
	subpatch_no = c("1", "1", "2", "2", "3", "3", "3"),
	k = rep(300, 7),
	k_stdev = rep(0, 7),
	n0 = rep(150, 7),
	natal_grounds = rep(1, 7),
	migration_grounds = rep(1, 7),
	genes_initialize = c("genes/allelefrequencyA.csv", rep("random", 6)),
	class_vars = rep("classvars/ClassVars_AS1.csv", 7),
	mortality_out = rep(0, 7),
	mortality_out_stdev = rep(0, 7),
	mortality_back = rep(0, 7),
	mortality_back_stdev = rep(0, 7),
	mortality_eggs = rep(0, 7),
	mortality_eggs_stdev = rep(0, 7),
	migration = rep(1, 7),
	set_migration = rep("Y", 7),
	migration_back_prob = rep(1, 7),
	straying_prob = rep(1, 7),
	dispersal_prob = rep(1, 7),
	growth_temp_out = rep(1, 7),
	growth_temp_out_stdev = c(0, 0.2, 0.1, 1, 0.4, 0.2, 0),
	grow_days_out = c(155, 150, 150, 150, 150, 150, 150),
	grow_days_out_stdev = c(0, 20, 20, 20, 20, 20, 20),
	growth_temp_back = c(14, 18, 22, 8, 8, 8, 8),
	growth_temp_back_stdev = rep(0, 7),
	grow_days_back = c(210, 150, 150, 150, 150, 150, 150),
	grow_days_back_stdev = c(0, 20, 20, 20, 20, 20, 20),
	capture_prob_out = rep("N", 7),
	capture_prob_back = rep("N", 7),
	habitat_out = rep(1, 7),
	habitat_back = rep(1, 7),
	fitness_AA = rep(0, 7), fitness_Aa = rep(0, 7), fitness_aa = rep(0, 7),
	fitness_BB = rep(0, 7), fitness_Bb = rep(0, 7), fitness_bb = rep(0, 7),
	fitness_AABB = rep(0, 7), fitness_AaBB = rep(0, 7), fitness_aaBB = rep(0, 7),
	fitness_AABb = rep(0, 7), fitness_AaBb = rep(0, 7), fitness_aaBb = rep(0, 7),
	fitness_AAbb = rep(0, 7), fitness_Aabb = rep(0, 7), fitness_aabb = rep(0, 7),
	comp_coef = rep("0.5;0.1", 7),
	location = NULL
) {
	# See ClassVars()'s wrapper function for why these literal defaults are
	# forwarded as NULL to .PatchVarsR6$new() when not actually supplied by
	# the caller (preserves the initializer's own patch-count-based
	# default-resizing logic).
	this_env <- environment()
	supplied <- vapply(.pv_fields, function(field) {
		!eval(substitute(missing(x), list(x = as.name(field))), envir = this_env)
	}, logical(1))
	names(supplied) <- .pv_fields

	column_args <- mget(.pv_fields, envir = environment())
	column_args[!supplied] <- list(NULL)

	do.call(.PatchVarsR6$new, c(list(patch_id = patch_id, location = location), column_args))
}
