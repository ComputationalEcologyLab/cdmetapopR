# PopVars: R6 wrapper for CDMetaPOP's PopVars.csv input file.
#
# A PopVars.csv file holds one row per species-level parameter set -- but
# unlike ClassVars (rows = age classes of ONE simulation) and PatchVars
# (rows = patches of ONE simulation), each PopVars row is its OWN
# independent "batch" (confirmed against CDMetaPOP/example_files/
# popvars/PopVars.csv, whose 4 rows each point at a different combination of
# PatchVars file / parameter values -- see the user manual's Run Parameters
# section: "each line in the PopVars file corresponds to a separate 'batch'").
# The matching RunVars-level concept is a "run" (each RunVars row); the
# argument names follow that vocabulary -- PopVars() takes `n_batches`,
# RunVars() takes `n_runs`. Despite that different semantic, the
# column-active-binding pattern from ClassVars/PatchVars is kept here for
# consistency -- `mypopvars$matemoveno <- c(6, 6, 4, 6)` edits all 4
# batches' values at once.
#
# CRITICAL DEVIATION from ClassVars/PatchVars: CDMetaPOP reads PopVars.csv
# headers as dictionary KEYS, not just column order -- so (a) every column
# documented in the user manual must be present and (b) header text must match exactly.
# Every PopVars.csv header is a valid R name with no
# spaces, so -- unlike ClassVars/PatchVars -- there is no separate
# snake_case field-name layer here: `.popv_fields` IS the header text, used
# directly as both the data frame's column name and the active binding name
# (e.g. `mypopvars$AssortativeMate_Model`).
#
# Headers/defaults are drawn verbatim from example_files/popvars/PopVars.csv
# (the package's canonical PopVars example -- NOT PopVarsS1.csv, despite
# that naming pattern holding for other classes).
# Rules are drawn from the user manual's section 3.2, "Run parameters and
# output -- PopVars.csv file" (and its subsections 3.2.1-3.2.8).

# Canonical column headers/field names, in CDMetaPOP's expected order and
# exact spelling/case (these are read as dictionary keys by CDMetaPOP, so
# unlike ClassVars/PatchVars, no human-readable-vs-snake_case distinction is
# needed or wanted here).
.popv_fields <- c(
	"xyfilename", "mate_cdmat", "matemoveno", "matemoveparA", "matemoveparB",
	"matemoveparC", "matemovethresh", "migrateout_cdmat", "migratemoveOutno",
	"migratemoveOutparA", "migratemoveOutparB", "migratemoveOutparC",
	"migratemoveOutthresh", "migrateback_cdmat", "migratemoveBackno",
	"migratemoveBackparA", "migratemoveBackparB", "migratemoveBackparC",
	"migratemoveBackthresh", "stray_cdmat", "StrayBackno", "StrayBackparA",
	"StrayBackparB", "StrayBackparC", "StrayBackthresh", "disperseLocal_cdmat",
	"disperseLocalno", "disperseLocalparA", "disperseLocalparB",
	"disperseLocalparC", "disperseLocalthresh", "HomeAttempt", "sex_chromo",
	"sexans", "selfans", "Freplace", "Mreplace", "AssortativeMate_Model",
	"AssortativeMate_Factor", "mature_default", "mature_eqn_slope",
	"mature_eqn_int", "offno", "offans_InheritClassVars", "equalClutchSize",
	"Egg_Freq_Mean", "Egg_Freq_StDev", "Egg_Mean_ans", "Egg_Mean_par1",
	"Egg_Mean_par2", "Egg_Mortality", "Egg_Mortality_StDev", "Egg_FemaleProb",
	"startGenes", "loci", "alleles", "muterate", "mutationtype", "mtdna",
	"cdevolveans", "startSelection", "implementSelection", "betaFile_selection",
	"plasticgeneans", "plasticSignalResponse", "plasticBehavioralResponse",
	"startPlasticgene", "implementPlasticgene",
	"growth_option", "growth_Loo", "growth_R0", "growth_temp_max",
	"growth_temp_CV", "growth_temp_t0", "popmodel", "popmodel_par1",
	"correlation_matrix", "subpopmort_file", "egg_delay", "egg_add",
	"implement_disease"
)

# `xyfilename` (the nested PatchVars reference) is an object-or-path list
# column: it holds a PatchVars object or a path, with `.GlobalEnv` name
# resolution (the `class_vars` pattern from PatchVars). It is the ONLY field
# that resolves an R6 object by name.
.popv_object_fields <- c("xyfilename")

# Matrix fields (the five movement matrices plus the two matrix-shaped
# auxiliary files) are also list columns, but follow a different rule (Key
# Design Decision 4, settled 2026-06-28): each holds, per batch, EITHER a
# single raw matrix (a lone value, no `|`/`~`), OR a filepath string (which
# may itself carry `|`/`~` delimiters, stored verbatim), OR -- for the three
# fields in `.popv_matrix_allow_N` -- the literal `"N"`. A matrix is never
# combined with `|`/`~`; temporal/per-sex variation must be given as
# filepaths (supporting matrices there too is parked until the package is
# finished). At write time a matrix becomes the placeholder path
# `cdmats/<fieldname>.csv` (serialized later by launch_cdmetapop()); a path
# and `"N"` are written verbatim. No `.GlobalEnv` resolution (matrices/paths
# are never looked up by name).
.popv_matrix_fields <- c(
	"mate_cdmat", "migrateout_cdmat", "migrateback_cdmat", "stray_cdmat",
	"disperseLocal_cdmat", "correlation_matrix", "subpopmort_file"
)

# Of the matrix fields, only these three are documented to accept `"N"` (the
# off-switch): migrateout_cdmat skips the emigration module; correlation_matrix
# and subpopmort_file turn off the correlated-draw / subpopulation-mortality
# features. The other four require an actual matrix or path.
.popv_matrix_allow_N <- c("migrateout_cdmat", "correlation_matrix", "subpopmort_file")

# Default values, taken verbatim (one 4-element vector per column, one
# element per example row) from example_files/popvars/PopVars.csv -- the
# package's canonical PopVars example. Generated programmatically from the
# csv (not hand-transcribed) to avoid copy errors in an 83-column x 4-row
# table. Used by `.popv_default_for()` to fill in any column a user does
# not specify at construction.
.popv_s1_defaults <- list(
	xyfilename = c("patchvars/PatchVars.csv", "patchvars/PatchVars_anadromy.csv", "patchvars/PatchVars.csv", "patchvars/PatchVars.csv"),
	mate_cdmat = c("cdmats/Patch7_CdmatrixS1.csv", "cdmats/Patch7_CdmatrixS1.csv", "cdmats/Patch7_CdmatrixS1.csv", "cdmats/Patch7_CdmatrixS1.csv"),
	matemoveno = c("6", "6", "4", "6"),
	matemoveparA = c("1.346", "1.346", "1.346", "1.346"),
	matemoveparB = c("202.4846", "202.4846", "202.4846", "202.4846"),
	matemoveparC = c("6", "6", "6", "6"),
	matemovethresh = c("6000", "6000", "6000", "6000"),
	migrateout_cdmat = c("cdmats/Patch7_Probmatrix_onewayBarriersXRiverineS1.csv", "cdmats/Patch7_Probmatrix_onewayBarriersXRiverineS1.csv", "cdmats/Patch7_Probmatrix_onewayBarriersXRiverineS1.csv", "cdmats/Patch7_Probmatrix_onewayBarriersXRiverineS1.csv"),
	migratemoveOutno = c("4", "4", "9", "9"),
	migratemoveOutparA = c("0", "0", "0", "0"),
	migratemoveOutparB = c("0", "0", "0", "0"),
	migratemoveOutparC = c("0", "0", "0", "0"),
	migratemoveOutthresh = c("max~max", "max~max", "max~max", "max~max"),
	migrateback_cdmat = c("cdmats/Patch7_Probmatrix_onewayBarriersXRiverineS1.csv", "cdmats/Patch7_Probmatrix_onewayBarriersXRiverineS1.csv", "cdmats/Patch7_Probmatrix_onewayBarriersXRiverineS1.csv", "cdmats/Patch7_Probmatrix_onewayBarriersXRiverineS1.csv"),
	migratemoveBackno = c("4", "4", "9", "9"),
	migratemoveBackparA = c("0", "0", "0", "0"),
	migratemoveBackparB = c("0", "0", "0", "0"),
	migratemoveBackparC = c("0", "0", "0", "0"),
	migratemoveBackthresh = c("max~max", "max~max", "max~max", "max~max"),
	stray_cdmat = c("cdmats/Patch7_CdmatrixS1.csv", "cdmats/Patch7_CdmatrixS1.csv", "cdmats/Patch7_CdmatrixS1.csv", "cdmats/Patch7_CdmatrixS1.csv"),
	StrayBackno = c("1", "1", "4", "2"),
	StrayBackparA = c("0.01", "0.01", "0.01", "0.01"),
	StrayBackparB = c("0.01", "0.01", "0.01", "0.01"),
	StrayBackparC = c("0", "0", "0", "0"),
	StrayBackthresh = c("max", "max", "max", "max"),
	disperseLocal_cdmat = c("cdmats/Patch7_Probmatrix_Dispersal.csv", "cdmats/Patch7_Probmatrix_Dispersal.csv", "cdmats/Patch7_CdmatrixS1.csv", "cdmats/Patch7_CdmatrixS1.csv"),
	disperseLocalno = c("9", "9", "2", "2"),
	disperseLocalparA = c("0.01", "0.01", "0.01", "0.01"),
	disperseLocalparB = c("0.01", "0.01", "0.01", "0.01"),
	disperseLocalparC = c("0", "0", "0", "0"),
	disperseLocalthresh = c("max", "max", "max", "max"),
	HomeAttempt = c("mortality", "mortality", "mortality", "mortality"),
	sex_chromo = c("2", "2", "2", "2"),
	sexans = c("Y", "Y", "Y", "H"),
	selfans = c("N", "N", "N", "0.5"),
	Freplace = c("Y", "Y", "Y", "Y"),
	Mreplace = c("Y", "Y", "Y", "Y"),
	AssortativeMate_Model = c("1", "1", "1", "1"),
	AssortativeMate_Factor = c("1", "1", "1", "1"),
	mature_default = c("age3|age6|age3", "age3", "size300", "N"),
	mature_eqn_slope = c("0.13~0.06|0.13~0.06|0.13~0.06", "0.0539", "0.13~0.06", "0.13~0.06"),
	mature_eqn_int = c("-20.28~-8.09|-20.28~-8.09|-20.28~-8.09", "-6.313", "-20.28~-8.09", "-20.28~-8.09"),
	offno = c("2", "2", "2", "2"),
	offans_InheritClassVars = c("random", "random", "random", "random"),
	equalClutchSize = c("N", "N", "N", "N"),
	Egg_Freq_Mean = c("1", "1", "1", "0.5"),
	Egg_Freq_StDev = c("1", "1", "0", "0.1"),
	Egg_Mean_ans = c("linear", "linear", "exp", "exp"),
	Egg_Mean_par1 = c("-445", "-445", "126.07", "126.07"),
	Egg_Mean_par2 = c("3.78", "3.78", "0.0061", "0.0061"),
	Egg_Mortality = c("N", "0.62", "0.62", "0"),
	Egg_Mortality_StDev = c("0", "0", "0.18", "0"),
	Egg_FemaleProb = c("0.5", "0.5", "0.5", "0.5"),
	startGenes = c("0", "0", "0", "0"),
	loci = c("2", "2", "2", "2"),
	alleles = c("2", "2", "2", "2"),
	muterate = c("0", "0", "0", "0"),
	mutationtype = c("random", "random", "random", "random"),
	mtdna = c("N", "N", "N", "N"),
	cdevolveans = c("N", "N", "N", "N"),
	startSelection = c("0", "0", "0", "0"),
	implementSelection = c("Out:Back", "Out:Back", "Eggs", "Back"),
	betaFile_selection = c("N", "N", "N", "N"),
	plasticgeneans = c("N", "N", "N", "N"),
	plasticSignalResponse = c("0", "0", "0", "0"),
	plasticBehavioralResponse = c("0", "0", "0", "0"),
	startPlasticgene = c("0", "0", "0", "0"),
	implementPlasticgene = c("Back:0", "Back:0", "Back", "Back"),
	growth_option = c("temperature", "temperature", "temperature", "temperature"),
	growth_Loo = c("400", "400", "250", "250"),
	growth_R0 = c("0.47", "0.47", "0.57", "0.57"),
	growth_temp_max = c("10.5", "10.5", "12", "12"),
	growth_temp_CV = c("0.33", "0.33", "0.25", "0.25"),
	growth_temp_t0 = c("-0.075", "-0.075", "-0.196", "-0.196"),
	popmodel = c("packing", "anadromy", "logistic_back", "N"),
	popmodel_par1 = c("-0.6821", "-0.6821", "-0.6821", "-0.6821"),
	correlation_matrix = c("N", "N", "N", "N"),
	subpopmort_file = c("N", "N", "N", "N"),
	egg_delay = c("0", "0", "0", "0"),
	egg_add = c("mating", "mating", "mating", "mating"),
	implement_disease = c("N", "N", "N", "N")
)

# Rule constructor helpers, used below to build `.popv_rules` compactly --
# 77 plain-value fields (the 6 object-or-path fields are excluded, handled
# separately) would otherwise need 77 near-identical hand-written lists.
# `allow_pipe`/`allow_tilde` mirror PatchVars' mechanism (temporal-change
# '|', per-sex '~'); per the user manual's '*'/'**' markers, applied
# per-field below.
.popv_rule_numeric    <- function(lower = -Inf, upper = Inf, allow_N = FALSE, allow_pipe = FALSE, allow_tilde = FALSE)
	list(type = "numeric", lower = lower, upper = upper, allow_N = allow_N, allow_pipe = allow_pipe, allow_tilde = allow_tilde)
.popv_rule_free_num   <- function(allow_pipe = FALSE, allow_tilde = FALSE)
	list(type = "free_numeric", allow_pipe = allow_pipe, allow_tilde = allow_tilde)
.popv_rule_free_char  <- function(allow_pipe = FALSE, allow_tilde = FALSE)
	list(type = "free_char", allow_pipe = allow_pipe, allow_tilde = allow_tilde)
.popv_rule_enum       <- function(values, allow_pipe = FALSE, allow_tilde = FALSE, case_insensitive = FALSE)
	list(type = "enum", values = values, allow_pipe = allow_pipe, allow_tilde = allow_tilde, case_insensitive = case_insensitive)
.popv_rule_enum_num   <- function(values, allow_pipe = FALSE, allow_tilde = FALSE)
	list(type = "enum_numeric", values = values, allow_pipe = allow_pipe, allow_tilde = allow_tilde)
.popv_rule_yn         <- function(allow_pipe = FALSE, allow_tilde = FALSE)
	list(type = "YN", allow_pipe = allow_pipe, allow_tilde = allow_tilde)
.popv_rule_threshold  <- function(allow_pipe = FALSE, allow_tilde = FALSE)
	list(type = "threshold", allow_pipe = allow_pipe, allow_tilde = allow_tilde)
.popv_rule_file_or_N  <- function() list(type = "file_or_N")

# Validation rules for every plain-value (non-object-or-path) column,
# drawn from the user manual's section 3.2 ("Run parameters and output --
# PopVars.csv file") and its subsections 3.2.1-3.2.8. Several fields use
# manual-documented mechanisms beyond '|'/'~' that don't generalize to a
# simple per-field flag, and are validated by dedicated types instead of
# `.popv_rule_*()` helpers (see `.popv_check_segment()`):
#   - "alleles": single integer >= 2, OR multiple ':'-separated per-locus
#     integers (e.g. "2:5:3") -- the manual's one documented use of ':' as a
#     per-locus list, distinct from "colon_tokens"' timing-token joining.
#   - "colon_tokens" (`implementSelection`, `implementPlasticgene`): ':'-
#     joined timing keywords (e.g. "Out:Back"). Validation here is
#     deliberately permissive (any non-empty token) rather than a strict
#     enum/`_{age}`-suffix grammar -- PopVars.csv's own canonical example
#     contains a token ("Back:0" for implementPlasticgene) not described by
#     the manual's documented Out/Back vocabulary, so a strict enum would
#     reject the package's own canonical default. Revisit if CDMetaPOP's
#     source clarifies the full grammar.
#   - "growth_loo" (`growth_Loo` only): free numeric, OR two numbers joined
#     by ';' (not '|') for the genotype-linked Loo_1;Loo_2 form -- the only
#     field in PopVars documented to use ';' for this purpose. Also
#     allows '~' (per-sex), applied outside the ';' pair per the manual's
#     "growth_Loo**" marking.
#   - "prob_or_wrightfisher" (`Egg_FemaleProb` only): numeric [0, 1], or the
#     literal keyword "WrightFisher".
#   - "yn_or_prob" (`selfans` only): "Y"/"N", or numeric [0, 1] (used for the
#     sexans = 'H' hermaphroditic self-fertilization probability).
# `cdevolveans` and `plasticgeneans` use "free_char": the manual documents
# an extensive, open-ended mini-grammar for each (e.g.
# "Hindex_Gauss_8:10:0.5:0.5:0.1:0.9", "Temp_dom_0") that this package does
# not yet parse/validate -- deliberately permissive, mirroring PatchVars'
# treatment of Fitness_*/comp_coef pending deeper modeling. Revisit as a
# follow-up task if stricter validation is wanted.
.popv_rules <- list(
	matemoveno            = .popv_rule_enum_num(1:11, allow_pipe = TRUE),
	matemoveparA          = .popv_rule_free_num(allow_pipe = TRUE),
	matemoveparB          = .popv_rule_free_num(allow_pipe = TRUE),
	matemoveparC          = .popv_rule_free_num(allow_pipe = TRUE),
	matemovethresh        = .popv_rule_threshold(allow_pipe = TRUE),
	migratemoveOutno      = .popv_rule_enum_num(1:11, allow_pipe = TRUE, allow_tilde = TRUE),
	migratemoveOutparA    = .popv_rule_free_num(allow_pipe = TRUE, allow_tilde = TRUE),
	migratemoveOutparB    = .popv_rule_free_num(allow_pipe = TRUE, allow_tilde = TRUE),
	migratemoveOutparC    = .popv_rule_free_num(allow_pipe = TRUE, allow_tilde = TRUE),
	migratemoveOutthresh  = .popv_rule_threshold(allow_pipe = TRUE, allow_tilde = TRUE),
	migratemoveBackno     = .popv_rule_enum_num(1:11, allow_pipe = TRUE, allow_tilde = TRUE),
	migratemoveBackparA   = .popv_rule_free_num(allow_pipe = TRUE, allow_tilde = TRUE),
	migratemoveBackparB   = .popv_rule_free_num(allow_pipe = TRUE, allow_tilde = TRUE),
	migratemoveBackparC   = .popv_rule_free_num(allow_pipe = TRUE, allow_tilde = TRUE),
	migratemoveBackthresh = .popv_rule_threshold(allow_pipe = TRUE, allow_tilde = TRUE),
	StrayBackno           = .popv_rule_enum_num(1:11, allow_pipe = TRUE, allow_tilde = TRUE),
	StrayBackparA         = .popv_rule_free_num(allow_pipe = TRUE, allow_tilde = TRUE),
	StrayBackparB         = .popv_rule_free_num(allow_pipe = TRUE, allow_tilde = TRUE),
	StrayBackparC         = .popv_rule_free_num(allow_pipe = TRUE, allow_tilde = TRUE),
	StrayBackthresh       = .popv_rule_threshold(allow_pipe = TRUE, allow_tilde = TRUE),
	disperseLocalno       = .popv_rule_enum_num(1:11, allow_pipe = TRUE, allow_tilde = TRUE),
	disperseLocalparA     = .popv_rule_free_num(allow_pipe = TRUE, allow_tilde = TRUE),
	disperseLocalparB     = .popv_rule_free_num(allow_pipe = TRUE, allow_tilde = TRUE),
	disperseLocalparC     = .popv_rule_free_num(allow_pipe = TRUE, allow_tilde = TRUE),
	disperseLocalthresh   = .popv_rule_threshold(allow_pipe = TRUE, allow_tilde = TRUE),
	HomeAttempt              = .popv_rule_enum(c("mortality", "stray_emiPop", "stray_natalPop")),
	sex_chromo               = .popv_rule_enum_num(c(2, 3, 4)),
	sexans                   = .popv_rule_enum(c("Y", "N", "H")),
	selfans                  = list(type = "yn_or_prob"),
	Freplace                 = .popv_rule_yn(),
	Mreplace                 = .popv_rule_yn(),
	AssortativeMate_Model    = .popv_rule_enum(c("1", "2", "3a", "3b", "4", "5")),
	AssortativeMate_Factor   = .popv_rule_numeric(lower = 1, upper = 1000000),
	mature_default           = .popv_rule_free_char(allow_pipe = TRUE, allow_tilde = TRUE),
	mature_eqn_slope         = .popv_rule_free_num(allow_pipe = TRUE, allow_tilde = TRUE),
	mature_eqn_int           = .popv_rule_free_num(allow_pipe = TRUE, allow_tilde = TRUE),
	offno                    = .popv_rule_enum_num(c(1, 2, 3, 4)),
	offans_InheritClassVars  = .popv_rule_enum(c("random", "Hindex", "mother")),
	equalClutchSize          = .popv_rule_yn(),
	Egg_Freq_Mean            = .popv_rule_numeric(lower = 0),
	Egg_Freq_StDev           = .popv_rule_numeric(lower = 0),
	Egg_Mean_ans             = .popv_rule_enum(c("exp", "linear", "pow")),
	Egg_Mean_par1            = .popv_rule_free_num(),
	Egg_Mean_par2            = .popv_rule_free_num(),
	Egg_Mortality            = .popv_rule_numeric(lower = 0, upper = 1, allow_N = TRUE),
	Egg_Mortality_StDev      = .popv_rule_numeric(lower = 0, allow_N = TRUE),
	Egg_FemaleProb           = list(type = "prob_or_wrightfisher"),
	startGenes               = .popv_rule_numeric(lower = 0),
	loci                     = .popv_rule_numeric(lower = 2),
	alleles                  = list(type = "alleles"),
	muterate                 = .popv_rule_numeric(lower = 0, upper = 1),
	mutationtype             = .popv_rule_enum(c("random", "forward", "backward", "forwardbackward", "forwardAbackwardBrandomN")),
	mtdna                    = .popv_rule_yn(),
	cdevolveans              = .popv_rule_free_char(),
	startSelection           = .popv_rule_numeric(lower = 0),
	implementSelection       = list(type = "colon_tokens"),
	betaFile_selection       = .popv_rule_file_or_N(),
	plasticgeneans           = .popv_rule_free_char(),
	plasticSignalResponse    = .popv_rule_free_num(),
	plasticBehavioralResponse = .popv_rule_free_num(),
	startPlasticgene         = .popv_rule_numeric(lower = 0),
	implementPlasticgene     = list(type = "colon_tokens"),
	growth_option            = .popv_rule_enum(c("N", "known", "vonB", "temperature", "temperature_hindex", "bioenergetics")),
	growth_Loo               = list(type = "growth_loo"),
	growth_R0                = .popv_rule_free_num(allow_tilde = TRUE),
	growth_temp_max          = .popv_rule_free_num(allow_tilde = TRUE),
	growth_temp_CV           = .popv_rule_free_num(allow_tilde = TRUE),
	growth_temp_t0           = .popv_rule_free_num(allow_tilde = TRUE),
	popmodel                 = .popv_rule_enum(c("N", "logistic_out", "logistic_back", "packing", "packing_1", "anadromy")),
	popmodel_par1            = .popv_rule_free_num(),
	# correlation_matrix / subpopmort_file are NOT here -- they are matrix
	# fields (see `.popv_matrix_fields`), validated by
	# `.validate_popv_matrix_field()`, not `.popv_rules`.
	egg_delay                = .popv_rule_numeric(lower = 0),
	egg_add                  = .popv_rule_enum(c("mating", "nonmating"), case_insensitive = TRUE),
	implement_disease        = .popv_rule_enum(c("N", "Back", "Out", "Both"))
)

#' Validate a single (post-'|'/'~'-split) PopVars value against its
#' column's base type rule
#'
#' Internal helper called once per innermost segment by
#' `.validate_popv_field()` -- mirrors PatchVars' `.pv_check_segment()`, with
#' additional types for PopVars-specific mechanisms (see `.popv_rules`'
#' doc comment above for "alleles"/"colon_tokens"/"growth_loo"/
#' "prob_or_wrightfisher"/"yn_or_prob").
#'
#' @keywords internal
.popv_check_segment <- function(rule, seg, field, i) {
	type <- rule$type

	if (type == "free_char") {
		if (is.na(seg) || !nzchar(seg)) stop(sprintf("`%s`[%d] cannot be an empty/NA value.", field, i))
		return(invisible(NULL))
	}
	if (type == "free_numeric") {
		if (is.na(suppressWarnings(as.numeric(seg)))) stop(sprintf("`%s`[%d] = \"%s\" is not a valid number.", field, i, seg))
		return(invisible(NULL))
	}
	if (type == "enum") {
		# `egg_add` is the one field documented as case-insensitive
		# ("mating"/"nonmating", case should not matter) -- `rule$case_insensitive`
		# lets that field opt in without affecting every other
		# (case-sensitive) enum field.
		matched <- if (isTRUE(rule$case_insensitive)) tolower(seg) %in% tolower(rule$values) else seg %in% rule$values
		if (!matched) stop(sprintf("`%s`[%d] = \"%s\" must be one of: %s.", field, i, seg, paste(rule$values, collapse = ", ")))
		return(invisible(NULL))
	}
	if (type == "enum_numeric") {
		num <- suppressWarnings(as.numeric(seg))
		if (is.na(num) || !(num %in% rule$values)) stop(sprintf("`%s`[%d] = \"%s\" must be one of: %s.", field, i, seg, paste(rule$values, collapse = ", ")))
		return(invisible(NULL))
	}
	if (type == "YN") {
		if (!seg %in% c("Y", "N")) stop(sprintf("`%s`[%d] = \"%s\" must be \"Y\" or \"N\".", field, i, seg))
		return(invisible(NULL))
	}
	if (type == "threshold") {
		if (identical(seg, "max")) return(invisible(NULL))
		if (grepl("^[0-9]+max$", seg)) {
			pct <- as.numeric(sub("max$", "", seg))
			if (pct < 1 || pct > 100) stop(sprintf("`%s`[%d] = \"%s\" must have a percent between 1 and 100 (e.g. \"10max\").", field, i, seg))
			return(invisible(NULL))
		}
		if (is.na(suppressWarnings(as.numeric(seg)))) {
			stop(sprintf("`%s`[%d] = \"%s\" must be \"max\", \"<percent>max\" (e.g. \"10max\"), or a cost-distance number.", field, i, seg))
		}
		return(invisible(NULL))
	}
	if (type == "file_or_N") {
		if (is.na(seg) || !nzchar(seg)) stop(sprintf("`%s`[%d] cannot be an empty/NA value.", field, i))
		return(invisible(NULL))
	}
	if (type == "yn_or_prob") {
		if (seg %in% c("Y", "N")) return(invisible(NULL))
		num <- suppressWarnings(as.numeric(seg))
		if (is.na(num) || num < 0 || num > 1) stop(sprintf("`%s`[%d] = \"%s\" must be \"Y\", \"N\", or a probability in [0, 1].", field, i, seg))
		return(invisible(NULL))
	}
	if (type == "prob_or_wrightfisher") {
		if (identical(seg, "WrightFisher")) return(invisible(NULL))
		num <- suppressWarnings(as.numeric(seg))
		if (is.na(num) || num < 0 || num > 1) stop(sprintf("`%s`[%d] = \"%s\" must be \"WrightFisher\" or a probability in [0, 1].", field, i, seg))
		return(invisible(NULL))
	}
	if (type == "alleles") {
		parts <- strsplit(seg, ":", fixed = TRUE)[[1]]
		nums <- suppressWarnings(as.numeric(parts))
		if (any(is.na(nums)) || any(nums < 2)) {
			stop(sprintf("`%s`[%d] = \"%s\" must be an integer >= 2, or ':'-separated integers >= 2 (one per locus).", field, i, seg))
		}
		return(invisible(NULL))
	}
	if (type == "colon_tokens") {
		tokens <- strsplit(seg, ":", fixed = TRUE)[[1]]
		if (any(!nzchar(tokens))) stop(sprintf("`%s`[%d] = \"%s\" has an empty ':'-separated token.", field, i, seg))
		return(invisible(NULL))
	}
	if (type == "growth_loo") {
		parts <- strsplit(seg, ";", fixed = TRUE)[[1]]
		if (length(parts) > 2) stop(sprintf("`%s`[%d] = \"%s\" must be one number, or two ';'-separated numbers (Loo_1;Loo_2).", field, i, seg))
		nums <- suppressWarnings(as.numeric(parts))
		if (any(is.na(nums))) stop(sprintf("`%s`[%d] = \"%s\" is not a valid number (or ';'-separated pair).", field, i, seg))
		return(invisible(NULL))
	}

	# type == "numeric" from here on.
	if (rule$allow_N && identical(seg, "N")) return(invisible(NULL))
	num <- suppressWarnings(as.numeric(seg))
	if (is.na(num)) {
		stop(sprintf(
			"`%s`[%d] = \"%s\" is not a valid value (expected a number%s).",
			field, i, seg, if (rule$allow_N) " or \"N\"" else ""
		))
	}
	if (num < rule$lower || num > rule$upper) {
		stop(sprintf("`%s`[%d] = %s is outside the allowed range [%s, %s].", field, i, num, rule$lower, rule$upper))
	}
	invisible(NULL)
}

#' Validate and normalize one plain-value PopVars column
#'
#' Mirrors PatchVars' `.validate_pv_field()`: splits on '|' first (if
#' `allow_pipe`), then '~' within each '|'-segment (if `allow_tilde`),
#' validating each innermost segment independently via
#' `.popv_check_segment()`, but always storing the whole original string
#' verbatim as character (the literal text CDMetaPOP expects).
#'
#' @param field Column name (must be a key in `.popv_rules`, i.e. not one of
#'   `.popv_object_fields`).
#' @param values Vector of values to validate; recycled to length `n` if it
#'   has length 1.
#' @param n Expected length (the number of batches already defined
#'   on the object).
#' @keywords internal
.validate_popv_field <- function(field, values, n) {
	rule <- .popv_rules[[field]]
	if (length(values) == 1) values <- rep(values, n)
	if (length(values) != n) {
		stop(sprintf("`%s` must have length 1 or %d (the number of batches), not %d.", field, n, length(values)))
	}

	out <- character(n)
	for (i in seq_len(n)) {
		raw_chr <- as.character(values[i])
		if (is.na(raw_chr)) stop(sprintf("`%s`[%d] cannot be NA.", field, i))

		pipe_segments <- if (isTRUE(rule$allow_pipe) && grepl("|", raw_chr, fixed = TRUE)) {
			strsplit(raw_chr, "|", fixed = TRUE)[[1]]
		} else {
			raw_chr
		}
		for (pseg in pipe_segments) {
			tilde_segments <- if (isTRUE(rule$allow_tilde) && grepl("~", pseg, fixed = TRUE)) {
				strsplit(pseg, "~", fixed = TRUE)[[1]]
			} else {
				pseg
			}
			for (tseg in tilde_segments) .popv_check_segment(rule, tseg, field, i)
		}
		out[i] <- raw_chr
	}
	out
}

#' Resolve one `xyfilename` `|`-segment to a live PatchVars object or a path
#'
#' Mirrors PatchVars' `.pv_resolve_class_vars_segment()`: if `seg` is the
#' name of a `PatchVars` object in `.GlobalEnv`, return that object (a live
#' reference); otherwise return `seg` unchanged, to be treated as a literal
#' path. `xyfilename` is the only PopVars field that resolves an object by
#' name (the matrix fields never do — see `.validate_popv_matrix_field()`).
#'
#' @param seg A single character segment, or already a `PatchVars` object
#'   (passed through unchanged).
#' @param resolve If `FALSE`, skip the lookup entirely (see
#'   `.pv_resolve_class_vars_segment()`'s `resolve` argument for the
#'   `read_cdmetapop()` rationale, which applies identically here).
#' @keywords internal
.popv_resolve_object_segment <- function(seg, resolve = TRUE) {
	if (resolve && is.character(seg) && length(seg) == 1 &&
			!is.na(seg) && nzchar(seg) && exists(seg, envir = .GlobalEnv, inherits = FALSE)) {
		candidate <- get(seg, envir = .GlobalEnv, inherits = FALSE)
		if (inherits(candidate, "PatchVars")) return(candidate)
	}
	seg
}

#' Normalize one batch's `xyfilename` entry into a flat list of items
#'
#' Mirrors PatchVars' `.pv_normalize_class_vars_patch()`: accepts a
#' `PatchVars` object, a character string (`|`-split, each segment resolved
#' via `.popv_resolve_object_segment()`), or a list/vector of such items.
#'
#' @keywords internal
.popv_normalize_object_row <- function(x, resolve = TRUE) {
	if (inherits(x, "PatchVars")) return(list(x))
	if (is.character(x) && length(x) == 1) {
		segs <- strsplit(x, "|", fixed = TRUE)[[1]]
		return(lapply(segs, .popv_resolve_object_segment, resolve = resolve))
	}
	if (is.list(x) || is.character(x)) {
		items <- if (is.list(x)) x else as.list(x)
		return(Reduce(c, lapply(items, .popv_normalize_object_row, resolve = resolve), list()))
	}
	stop("`xyfilename` items must each be a PatchVars object or a single character string.")
}

#' Validate and normalize the `xyfilename` object-or-path column
#'
#' Stored as a list column (R6 objects cannot live in an atomic vector).
#' Each element is itself a flat list of one or more items, normalized by
#' `.popv_normalize_object_row()` -- mirrors PatchVars' `.validate_pv_class_vars()`.
#'
#' @param values A single value, or a list/vector of length `n`, each
#'   element one batch's worth of input.
#' @param n Expected length (the number of batches).
#' @param resolve Forwarded to `.popv_normalize_object_row()` -- `FALSE`
#'   disables `.GlobalEnv` name resolution (used by `read_cdmetapop()`,
#'   where a value read from an existing csv is always a literal path).
#' @keywords internal
.validate_popv_object_field <- function(field, values, n, resolve = TRUE) {
	is_scalar_value <- inherits(values, "PatchVars") ||
		(is.character(values) && length(values) == 1)
	if (is_scalar_value) {
		one_row <- .popv_normalize_object_row(values, resolve = resolve)
		return(rep(list(one_row), n))
	}

	if (!is.list(values)) values <- as.list(values)
	if (length(values) == 1 && n != 1) values <- rep(values, n)
	if (length(values) != n) {
		stop(sprintf("`%s` must have length 1 or %d (the number of batches), not %d.", field, n, length(values)))
	}
	lapply(values, .popv_normalize_object_row, resolve = resolve)
}

#' Validate and normalize one matrix-or-path column
#'
#' Matrix fields (`.popv_matrix_fields`: the five movement matrices plus
#' `correlation_matrix`/`subpopmort_file`) accept, per batch row, one of:
#'   - a single raw `matrix` (a lone value, no `|`/`~`);
#'   - a filepath string (which may itself carry `|`/`~` delimiters; stored
#'     verbatim, since CDMetaPOP reads the literal text);
#'   - the literal `"N"`, only for fields in `.popv_matrix_allow_N`.
#' Stored as a list column with ONE item per batch (matrix, path string, or
#' `"N"`) -- not a flat list of items, since a matrix is never combined with
#' anything (multiple-matrices-over-time/per-sex must be supplied as
#' filepaths; see Key Design Decision 4 / Parking Lot). A list/vector of
#' length `n` assigns one value per batch; a single matrix/string is
#' recycled across all batches.
#'
#' @param field One of `.popv_matrix_fields`.
#' @param values A single value, or a list/vector of length `n`.
#' @param n Expected length (the number of batches).
#' @keywords internal
.validate_popv_matrix_field <- function(field, values, n) {
	allow_N <- field %in% .popv_matrix_allow_N

	# A single matrix or single string is one batch's value, recycled to n.
	if (is.matrix(values) || (is.character(values) && length(values) == 1)) {
		values <- rep(list(values), n)
	} else if (!is.list(values)) {
		values <- as.list(values)
	}
	if (length(values) == 1 && n != 1) values <- rep(values, n)
	if (length(values) != n) {
		stop(sprintf("`%s` must have length 1 or %d (the number of batches), not %d.", field, n, length(values)))
	}

	lapply(seq_len(n), function(i) {
		v <- values[[i]]
		if (is.matrix(v)) return(v)
		if (is.character(v) && length(v) == 1 && !is.na(v)) {
			if (identical(v, "N")) {
				if (!allow_N) {
					stop(sprintf("`%s`[%d] does not accept \"N\" (only %s do).", field, i, paste(.popv_matrix_allow_N, collapse = ", ")))
				}
				return("N")
			}
			if (!nzchar(v)) stop(sprintf("`%s`[%d] cannot be an empty string.", field, i))
			return(v)
		}
		stop(sprintf("`%s`[%d] must be a single matrix, a filepath string, or \"N\" -- to vary a matrix over time (`|`) or by sex (`~`), supply filepaths, not a matrix.", field, i))
	})
}

# Default value for one column, for a given set of simulation-row indices.
# Looks up `.popv_s1_defaults` by row index. Rows beyond what PopVars.csv
# defines (i.e. above row 4) have no principled default, so the last
# defined default (row 4) is recycled, with a warning (mirrors
# class_classvars.R's `.cv_default_for()`/class_patchvars.R's
# `.pv_default_for()`).
.popv_default_for <- function(field, row_ids) {
	defaults <- .popv_s1_defaults[[field]]
	n <- length(row_ids)
	if (n <= length(defaults)) return(defaults[row_ids])
	c(defaults, rep(defaults[length(defaults)], n - length(defaults)))
}

# The R6 generator itself is not exported; users construct instances via the
# PopVars() wrapper function below. See class_classvars.R's note above
# `.ClassVarsR6` for why this is wrapped in local() + `#' @noRd`.

#' @noRd
.PopVarsR6 <- local(R6::R6Class("PopVars",
	public = list(
		initialize = function(
				n_batches = 4,
				xyfilename = NULL,
				mate_cdmat = NULL,
				matemoveno = NULL,
				matemoveparA = NULL,
				matemoveparB = NULL,
				matemoveparC = NULL,
				matemovethresh = NULL,
				migrateout_cdmat = NULL,
				migratemoveOutno = NULL,
				migratemoveOutparA = NULL,
				migratemoveOutparB = NULL,
				migratemoveOutparC = NULL,
				migratemoveOutthresh = NULL,
				migrateback_cdmat = NULL,
				migratemoveBackno = NULL,
				migratemoveBackparA = NULL,
				migratemoveBackparB = NULL,
				migratemoveBackparC = NULL,
				migratemoveBackthresh = NULL,
				stray_cdmat = NULL,
				StrayBackno = NULL,
				StrayBackparA = NULL,
				StrayBackparB = NULL,
				StrayBackparC = NULL,
				StrayBackthresh = NULL,
				disperseLocal_cdmat = NULL,
				disperseLocalno = NULL,
				disperseLocalparA = NULL,
				disperseLocalparB = NULL,
				disperseLocalparC = NULL,
				disperseLocalthresh = NULL,
				HomeAttempt = NULL,
				sex_chromo = NULL,
				sexans = NULL,
				selfans = NULL,
				Freplace = NULL,
				Mreplace = NULL,
				AssortativeMate_Model = NULL,
				AssortativeMate_Factor = NULL,
				mature_default = NULL,
				mature_eqn_slope = NULL,
				mature_eqn_int = NULL,
				offno = NULL,
				offans_InheritClassVars = NULL,
				equalClutchSize = NULL,
				Egg_Freq_Mean = NULL,
				Egg_Freq_StDev = NULL,
				Egg_Mean_ans = NULL,
				Egg_Mean_par1 = NULL,
				Egg_Mean_par2 = NULL,
				Egg_Mortality = NULL,
				Egg_Mortality_StDev = NULL,
				Egg_FemaleProb = NULL,
				startGenes = NULL,
				loci = NULL,
				alleles = NULL,
				muterate = NULL,
				mutationtype = NULL,
				mtdna = NULL,
				cdevolveans = NULL,
				startSelection = NULL,
				implementSelection = NULL,
				betaFile_selection = NULL,
				plasticgeneans = NULL,
				plasticSignalResponse = NULL,
				plasticBehavioralResponse = NULL,
				startPlasticgene = NULL,
				implementPlasticgene = NULL,
				growth_option = NULL,
				growth_Loo = NULL,
				growth_R0 = NULL,
				growth_temp_max = NULL,
				growth_temp_CV = NULL,
				growth_temp_t0 = NULL,
				popmodel = NULL,
				popmodel_par1 = NULL,
				correlation_matrix = NULL,
				subpopmort_file = NULL,
				egg_delay = NULL,
				egg_add = NULL,
				implement_disease = NULL,
				resolve_xyfilename = TRUE
		) {
			# Unlike ClassVars'/PatchVars' immutable id column ("Age class"/
			# "PatchID"), PopVars.csv has no id column at all -- row order in
			# the file is the only thing that matters (CDMetaPOP labels runs
			# by row position, "counting from 0", per the user manual). So
			# row count is just a plain integer, `n_batches`, not a validated
			# sequential-id vector.
			if (!is.numeric(n_batches) || length(n_batches) != 1 || n_batches < 1 || n_batches != as.integer(n_batches)) {
				stop("`n_batches` must be a single positive integer.")
			}
			n <- as.integer(n_batches)

			# Collect the user-supplied column arguments by name so they can
			# be looped over alongside `.popv_fields` below, rather than
			# writing out 83 near-identical "if not supplied, use default"
			# blocks by hand (mirrors ClassVars'/PatchVars' initialize()).
			supplied <- list(
				xyfilename = xyfilename,
				mate_cdmat = mate_cdmat,
				matemoveno = matemoveno,
				matemoveparA = matemoveparA,
				matemoveparB = matemoveparB,
				matemoveparC = matemoveparC,
				matemovethresh = matemovethresh,
				migrateout_cdmat = migrateout_cdmat,
				migratemoveOutno = migratemoveOutno,
				migratemoveOutparA = migratemoveOutparA,
				migratemoveOutparB = migratemoveOutparB,
				migratemoveOutparC = migratemoveOutparC,
				migratemoveOutthresh = migratemoveOutthresh,
				migrateback_cdmat = migrateback_cdmat,
				migratemoveBackno = migratemoveBackno,
				migratemoveBackparA = migratemoveBackparA,
				migratemoveBackparB = migratemoveBackparB,
				migratemoveBackparC = migratemoveBackparC,
				migratemoveBackthresh = migratemoveBackthresh,
				stray_cdmat = stray_cdmat,
				StrayBackno = StrayBackno,
				StrayBackparA = StrayBackparA,
				StrayBackparB = StrayBackparB,
				StrayBackparC = StrayBackparC,
				StrayBackthresh = StrayBackthresh,
				disperseLocal_cdmat = disperseLocal_cdmat,
				disperseLocalno = disperseLocalno,
				disperseLocalparA = disperseLocalparA,
				disperseLocalparB = disperseLocalparB,
				disperseLocalparC = disperseLocalparC,
				disperseLocalthresh = disperseLocalthresh,
				HomeAttempt = HomeAttempt,
				sex_chromo = sex_chromo,
				sexans = sexans,
				selfans = selfans,
				Freplace = Freplace,
				Mreplace = Mreplace,
				AssortativeMate_Model = AssortativeMate_Model,
				AssortativeMate_Factor = AssortativeMate_Factor,
				mature_default = mature_default,
				mature_eqn_slope = mature_eqn_slope,
				mature_eqn_int = mature_eqn_int,
				offno = offno,
				offans_InheritClassVars = offans_InheritClassVars,
				equalClutchSize = equalClutchSize,
				Egg_Freq_Mean = Egg_Freq_Mean,
				Egg_Freq_StDev = Egg_Freq_StDev,
				Egg_Mean_ans = Egg_Mean_ans,
				Egg_Mean_par1 = Egg_Mean_par1,
				Egg_Mean_par2 = Egg_Mean_par2,
				Egg_Mortality = Egg_Mortality,
				Egg_Mortality_StDev = Egg_Mortality_StDev,
				Egg_FemaleProb = Egg_FemaleProb,
				startGenes = startGenes,
				loci = loci,
				alleles = alleles,
				muterate = muterate,
				mutationtype = mutationtype,
				mtdna = mtdna,
				cdevolveans = cdevolveans,
				startSelection = startSelection,
				implementSelection = implementSelection,
				betaFile_selection = betaFile_selection,
				plasticgeneans = plasticgeneans,
				plasticSignalResponse = plasticSignalResponse,
				plasticBehavioralResponse = plasticBehavioralResponse,
				startPlasticgene = startPlasticgene,
				implementPlasticgene = implementPlasticgene,
				growth_option = growth_option,
				growth_Loo = growth_Loo,
				growth_R0 = growth_R0,
				growth_temp_max = growth_temp_max,
				growth_temp_CV = growth_temp_CV,
				growth_temp_t0 = growth_temp_t0,
				popmodel = popmodel,
				popmodel_par1 = popmodel_par1,
				correlation_matrix = correlation_matrix,
				subpopmort_file = subpopmort_file,
				egg_delay = egg_delay,
				egg_add = egg_add,
				implement_disease = implement_disease
			)

			private$data <- as.data.frame(matrix(nrow = n, ncol = length(.popv_fields)))
			colnames(private$data) <- .popv_fields
			# `xyfilename` (object-or-path) and the matrix fields are list
			# columns (they can hold R6 objects / raw matrices); must be
			# assigned via `[[<-`, not the matrix-fill above (mirrors
			# PatchVars' "Class Vars" handling).
			for (lc_field in c(.popv_object_fields, .popv_matrix_fields)) {
				private$data[[lc_field]] <- vector("list", n)
			}

			# PopVars.csv only defines defaults for 4 batches. If
			# more rows are requested and any column is left unspecified,
			# warn once (not once per column) that the row-4 default is
			# being recycled for those extra rows.
			max_default_n <- length(.popv_s1_defaults[[1]])
			any_unspecified <- any(!.popv_fields %in% names(supplied))
			if (n > max_default_n && any_unspecified) {
				warning(sprintf(
					"No default values exist in PopVars.csv for batches above %d; the row-%d default is being recycled for any unspecified column on the extra rows.",
					max_default_n, max_default_n
				), call. = FALSE)
			}

			for (field in .popv_fields) {
				raw <- supplied[[field]]
				if (is.null(raw)) raw <- .popv_default_for(field, seq_len(n))
				if (field %in% .popv_object_fields) {
					private$data[[field]] <- private$validate_object(field, raw, resolve = resolve_xyfilename)
				} else if (field %in% .popv_matrix_fields) {
					private$data[[field]] <- private$validate_matrix(field, raw)
				} else {
					private$data[[field]] <- private$validate(field, raw)
				}
			}
		},

		# Add one or more batches, copying the current last row. See
		# class_classvars.R's add_row() for why row names are reset
		# afterward.
		add_row = function(n = 1) {
			last_row <- private$data[nrow(private$data), , drop = FALSE]
			new_rows <- last_row[rep(1, n), , drop = FALSE]
			private$data <- rbind(private$data, new_rows)
			rownames(private$data) <- NULL
			invisible(self)
		},

		print = function(...) {
			cat("<PopVars>", nrow(private$data), "batch(es)\n")
			out <- private$data
			for (field in .popv_object_fields) {
				out[[field]] <- vapply(private$data[[field]], function(items) {
					paste(vapply(items, function(val) {
						if (inherits(val, "PatchVars")) "<PatchVars object>" else val
					}, character(1)), collapse = "|")
				}, character(1))
			}
			for (field in .popv_matrix_fields) {
				out[[field]] <- vapply(private$data[[field]], function(item) {
					if (is.matrix(item)) sprintf("<matrix %dx%d>", nrow(item), ncol(item)) else item
				}, character(1))
			}
			print(out)
			invisible(self)
		},

		# Returns a plain (independent) copy of the underlying table -- see
		# class_classvars.R's as_data_frame() for rationale. Object-or-path
		# list columns are left as-is.
		as_data_frame = function() private$data
	),

	private = list(
		data = NULL,

		validate = function(field, values) {
			.validate_popv_field(field, values, nrow(private$data))
		},
		validate_object = function(field, values, resolve = TRUE) {
			.validate_popv_object_field(field, values, nrow(private$data), resolve = resolve)
		},
		validate_matrix = function(field, values) {
			.validate_popv_matrix_field(field, values, nrow(private$data))
		}
	),

	active = list(
		xyfilename = function(value) {
			if (missing(value)) return(private$data[["xyfilename"]])
			private$data[["xyfilename"]] <- private$validate_object("xyfilename", value)
		},
		mate_cdmat = function(value) {
			if (missing(value)) return(private$data[["mate_cdmat"]])
			private$data[["mate_cdmat"]] <- private$validate_matrix("mate_cdmat", value)
		},
		matemoveno = function(value) {
			if (missing(value)) return(private$data[["matemoveno"]])
			private$data[["matemoveno"]] <- private$validate("matemoveno", value)
		},
		matemoveparA = function(value) {
			if (missing(value)) return(private$data[["matemoveparA"]])
			private$data[["matemoveparA"]] <- private$validate("matemoveparA", value)
		},
		matemoveparB = function(value) {
			if (missing(value)) return(private$data[["matemoveparB"]])
			private$data[["matemoveparB"]] <- private$validate("matemoveparB", value)
		},
		matemoveparC = function(value) {
			if (missing(value)) return(private$data[["matemoveparC"]])
			private$data[["matemoveparC"]] <- private$validate("matemoveparC", value)
		},
		matemovethresh = function(value) {
			if (missing(value)) return(private$data[["matemovethresh"]])
			private$data[["matemovethresh"]] <- private$validate("matemovethresh", value)
		},
		migrateout_cdmat = function(value) {
			if (missing(value)) return(private$data[["migrateout_cdmat"]])
			private$data[["migrateout_cdmat"]] <- private$validate_matrix("migrateout_cdmat", value)
		},
		migratemoveOutno = function(value) {
			if (missing(value)) return(private$data[["migratemoveOutno"]])
			private$data[["migratemoveOutno"]] <- private$validate("migratemoveOutno", value)
		},
		migratemoveOutparA = function(value) {
			if (missing(value)) return(private$data[["migratemoveOutparA"]])
			private$data[["migratemoveOutparA"]] <- private$validate("migratemoveOutparA", value)
		},
		migratemoveOutparB = function(value) {
			if (missing(value)) return(private$data[["migratemoveOutparB"]])
			private$data[["migratemoveOutparB"]] <- private$validate("migratemoveOutparB", value)
		},
		migratemoveOutparC = function(value) {
			if (missing(value)) return(private$data[["migratemoveOutparC"]])
			private$data[["migratemoveOutparC"]] <- private$validate("migratemoveOutparC", value)
		},
		migratemoveOutthresh = function(value) {
			if (missing(value)) return(private$data[["migratemoveOutthresh"]])
			private$data[["migratemoveOutthresh"]] <- private$validate("migratemoveOutthresh", value)
		},
		migrateback_cdmat = function(value) {
			if (missing(value)) return(private$data[["migrateback_cdmat"]])
			private$data[["migrateback_cdmat"]] <- private$validate_matrix("migrateback_cdmat", value)
		},
		migratemoveBackno = function(value) {
			if (missing(value)) return(private$data[["migratemoveBackno"]])
			private$data[["migratemoveBackno"]] <- private$validate("migratemoveBackno", value)
		},
		migratemoveBackparA = function(value) {
			if (missing(value)) return(private$data[["migratemoveBackparA"]])
			private$data[["migratemoveBackparA"]] <- private$validate("migratemoveBackparA", value)
		},
		migratemoveBackparB = function(value) {
			if (missing(value)) return(private$data[["migratemoveBackparB"]])
			private$data[["migratemoveBackparB"]] <- private$validate("migratemoveBackparB", value)
		},
		migratemoveBackparC = function(value) {
			if (missing(value)) return(private$data[["migratemoveBackparC"]])
			private$data[["migratemoveBackparC"]] <- private$validate("migratemoveBackparC", value)
		},
		migratemoveBackthresh = function(value) {
			if (missing(value)) return(private$data[["migratemoveBackthresh"]])
			private$data[["migratemoveBackthresh"]] <- private$validate("migratemoveBackthresh", value)
		},
		stray_cdmat = function(value) {
			if (missing(value)) return(private$data[["stray_cdmat"]])
			private$data[["stray_cdmat"]] <- private$validate_matrix("stray_cdmat", value)
		},
		StrayBackno = function(value) {
			if (missing(value)) return(private$data[["StrayBackno"]])
			private$data[["StrayBackno"]] <- private$validate("StrayBackno", value)
		},
		StrayBackparA = function(value) {
			if (missing(value)) return(private$data[["StrayBackparA"]])
			private$data[["StrayBackparA"]] <- private$validate("StrayBackparA", value)
		},
		StrayBackparB = function(value) {
			if (missing(value)) return(private$data[["StrayBackparB"]])
			private$data[["StrayBackparB"]] <- private$validate("StrayBackparB", value)
		},
		StrayBackparC = function(value) {
			if (missing(value)) return(private$data[["StrayBackparC"]])
			private$data[["StrayBackparC"]] <- private$validate("StrayBackparC", value)
		},
		StrayBackthresh = function(value) {
			if (missing(value)) return(private$data[["StrayBackthresh"]])
			private$data[["StrayBackthresh"]] <- private$validate("StrayBackthresh", value)
		},
		disperseLocal_cdmat = function(value) {
			if (missing(value)) return(private$data[["disperseLocal_cdmat"]])
			private$data[["disperseLocal_cdmat"]] <- private$validate_matrix("disperseLocal_cdmat", value)
		},
		disperseLocalno = function(value) {
			if (missing(value)) return(private$data[["disperseLocalno"]])
			private$data[["disperseLocalno"]] <- private$validate("disperseLocalno", value)
		},
		disperseLocalparA = function(value) {
			if (missing(value)) return(private$data[["disperseLocalparA"]])
			private$data[["disperseLocalparA"]] <- private$validate("disperseLocalparA", value)
		},
		disperseLocalparB = function(value) {
			if (missing(value)) return(private$data[["disperseLocalparB"]])
			private$data[["disperseLocalparB"]] <- private$validate("disperseLocalparB", value)
		},
		disperseLocalparC = function(value) {
			if (missing(value)) return(private$data[["disperseLocalparC"]])
			private$data[["disperseLocalparC"]] <- private$validate("disperseLocalparC", value)
		},
		disperseLocalthresh = function(value) {
			if (missing(value)) return(private$data[["disperseLocalthresh"]])
			private$data[["disperseLocalthresh"]] <- private$validate("disperseLocalthresh", value)
		},
		HomeAttempt = function(value) {
			if (missing(value)) return(private$data[["HomeAttempt"]])
			private$data[["HomeAttempt"]] <- private$validate("HomeAttempt", value)
		},
		sex_chromo = function(value) {
			if (missing(value)) return(private$data[["sex_chromo"]])
			private$data[["sex_chromo"]] <- private$validate("sex_chromo", value)
		},
		sexans = function(value) {
			if (missing(value)) return(private$data[["sexans"]])
			private$data[["sexans"]] <- private$validate("sexans", value)
		},
		selfans = function(value) {
			if (missing(value)) return(private$data[["selfans"]])
			private$data[["selfans"]] <- private$validate("selfans", value)
		},
		Freplace = function(value) {
			if (missing(value)) return(private$data[["Freplace"]])
			private$data[["Freplace"]] <- private$validate("Freplace", value)
		},
		Mreplace = function(value) {
			if (missing(value)) return(private$data[["Mreplace"]])
			private$data[["Mreplace"]] <- private$validate("Mreplace", value)
		},
		AssortativeMate_Model = function(value) {
			if (missing(value)) return(private$data[["AssortativeMate_Model"]])
			private$data[["AssortativeMate_Model"]] <- private$validate("AssortativeMate_Model", value)
		},
		AssortativeMate_Factor = function(value) {
			if (missing(value)) return(private$data[["AssortativeMate_Factor"]])
			private$data[["AssortativeMate_Factor"]] <- private$validate("AssortativeMate_Factor", value)
		},
		mature_default = function(value) {
			if (missing(value)) return(private$data[["mature_default"]])
			private$data[["mature_default"]] <- private$validate("mature_default", value)
		},
		mature_eqn_slope = function(value) {
			if (missing(value)) return(private$data[["mature_eqn_slope"]])
			private$data[["mature_eqn_slope"]] <- private$validate("mature_eqn_slope", value)
		},
		mature_eqn_int = function(value) {
			if (missing(value)) return(private$data[["mature_eqn_int"]])
			private$data[["mature_eqn_int"]] <- private$validate("mature_eqn_int", value)
		},
		offno = function(value) {
			if (missing(value)) return(private$data[["offno"]])
			private$data[["offno"]] <- private$validate("offno", value)
		},
		offans_InheritClassVars = function(value) {
			if (missing(value)) return(private$data[["offans_InheritClassVars"]])
			private$data[["offans_InheritClassVars"]] <- private$validate("offans_InheritClassVars", value)
		},
		equalClutchSize = function(value) {
			if (missing(value)) return(private$data[["equalClutchSize"]])
			private$data[["equalClutchSize"]] <- private$validate("equalClutchSize", value)
		},
		Egg_Freq_Mean = function(value) {
			if (missing(value)) return(private$data[["Egg_Freq_Mean"]])
			private$data[["Egg_Freq_Mean"]] <- private$validate("Egg_Freq_Mean", value)
		},
		Egg_Freq_StDev = function(value) {
			if (missing(value)) return(private$data[["Egg_Freq_StDev"]])
			private$data[["Egg_Freq_StDev"]] <- private$validate("Egg_Freq_StDev", value)
		},
		Egg_Mean_ans = function(value) {
			if (missing(value)) return(private$data[["Egg_Mean_ans"]])
			private$data[["Egg_Mean_ans"]] <- private$validate("Egg_Mean_ans", value)
		},
		Egg_Mean_par1 = function(value) {
			if (missing(value)) return(private$data[["Egg_Mean_par1"]])
			private$data[["Egg_Mean_par1"]] <- private$validate("Egg_Mean_par1", value)
		},
		Egg_Mean_par2 = function(value) {
			if (missing(value)) return(private$data[["Egg_Mean_par2"]])
			private$data[["Egg_Mean_par2"]] <- private$validate("Egg_Mean_par2", value)
		},
		Egg_Mortality = function(value) {
			if (missing(value)) return(private$data[["Egg_Mortality"]])
			private$data[["Egg_Mortality"]] <- private$validate("Egg_Mortality", value)
		},
		Egg_Mortality_StDev = function(value) {
			if (missing(value)) return(private$data[["Egg_Mortality_StDev"]])
			private$data[["Egg_Mortality_StDev"]] <- private$validate("Egg_Mortality_StDev", value)
		},
		Egg_FemaleProb = function(value) {
			if (missing(value)) return(private$data[["Egg_FemaleProb"]])
			private$data[["Egg_FemaleProb"]] <- private$validate("Egg_FemaleProb", value)
		},
		startGenes = function(value) {
			if (missing(value)) return(private$data[["startGenes"]])
			private$data[["startGenes"]] <- private$validate("startGenes", value)
		},
		loci = function(value) {
			if (missing(value)) return(private$data[["loci"]])
			private$data[["loci"]] <- private$validate("loci", value)
		},
		alleles = function(value) {
			if (missing(value)) return(private$data[["alleles"]])
			private$data[["alleles"]] <- private$validate("alleles", value)
		},
		muterate = function(value) {
			if (missing(value)) return(private$data[["muterate"]])
			private$data[["muterate"]] <- private$validate("muterate", value)
		},
		mutationtype = function(value) {
			if (missing(value)) return(private$data[["mutationtype"]])
			private$data[["mutationtype"]] <- private$validate("mutationtype", value)
		},
		mtdna = function(value) {
			if (missing(value)) return(private$data[["mtdna"]])
			private$data[["mtdna"]] <- private$validate("mtdna", value)
		},
		cdevolveans = function(value) {
			if (missing(value)) return(private$data[["cdevolveans"]])
			private$data[["cdevolveans"]] <- private$validate("cdevolveans", value)
		},
		startSelection = function(value) {
			if (missing(value)) return(private$data[["startSelection"]])
			private$data[["startSelection"]] <- private$validate("startSelection", value)
		},
		implementSelection = function(value) {
			if (missing(value)) return(private$data[["implementSelection"]])
			private$data[["implementSelection"]] <- private$validate("implementSelection", value)
		},
		betaFile_selection = function(value) {
			if (missing(value)) return(private$data[["betaFile_selection"]])
			private$data[["betaFile_selection"]] <- private$validate("betaFile_selection", value)
		},
		plasticgeneans = function(value) {
			if (missing(value)) return(private$data[["plasticgeneans"]])
			private$data[["plasticgeneans"]] <- private$validate("plasticgeneans", value)
		},
		plasticSignalResponse = function(value) {
			if (missing(value)) return(private$data[["plasticSignalResponse"]])
			private$data[["plasticSignalResponse"]] <- private$validate("plasticSignalResponse", value)
		},
		plasticBehavioralResponse = function(value) {
			if (missing(value)) return(private$data[["plasticBehavioralResponse"]])
			private$data[["plasticBehavioralResponse"]] <- private$validate("plasticBehavioralResponse", value)
		},
		startPlasticgene = function(value) {
			if (missing(value)) return(private$data[["startPlasticgene"]])
			private$data[["startPlasticgene"]] <- private$validate("startPlasticgene", value)
		},
		implementPlasticgene = function(value) {
			if (missing(value)) return(private$data[["implementPlasticgene"]])
			private$data[["implementPlasticgene"]] <- private$validate("implementPlasticgene", value)
		},
		growth_option = function(value) {
			if (missing(value)) return(private$data[["growth_option"]])
			private$data[["growth_option"]] <- private$validate("growth_option", value)
		},
		growth_Loo = function(value) {
			if (missing(value)) return(private$data[["growth_Loo"]])
			private$data[["growth_Loo"]] <- private$validate("growth_Loo", value)
		},
		growth_R0 = function(value) {
			if (missing(value)) return(private$data[["growth_R0"]])
			private$data[["growth_R0"]] <- private$validate("growth_R0", value)
		},
		growth_temp_max = function(value) {
			if (missing(value)) return(private$data[["growth_temp_max"]])
			private$data[["growth_temp_max"]] <- private$validate("growth_temp_max", value)
		},
		growth_temp_CV = function(value) {
			if (missing(value)) return(private$data[["growth_temp_CV"]])
			private$data[["growth_temp_CV"]] <- private$validate("growth_temp_CV", value)
		},
		growth_temp_t0 = function(value) {
			if (missing(value)) return(private$data[["growth_temp_t0"]])
			private$data[["growth_temp_t0"]] <- private$validate("growth_temp_t0", value)
		},
		popmodel = function(value) {
			if (missing(value)) return(private$data[["popmodel"]])
			private$data[["popmodel"]] <- private$validate("popmodel", value)
		},
		popmodel_par1 = function(value) {
			if (missing(value)) return(private$data[["popmodel_par1"]])
			private$data[["popmodel_par1"]] <- private$validate("popmodel_par1", value)
		},
		correlation_matrix = function(value) {
			if (missing(value)) return(private$data[["correlation_matrix"]])
			private$data[["correlation_matrix"]] <- private$validate_matrix("correlation_matrix", value)
		},
		subpopmort_file = function(value) {
			if (missing(value)) return(private$data[["subpopmort_file"]])
			private$data[["subpopmort_file"]] <- private$validate_matrix("subpopmort_file", value)
		},
		egg_delay = function(value) {
			if (missing(value)) return(private$data[["egg_delay"]])
			private$data[["egg_delay"]] <- private$validate("egg_delay", value)
		},
		egg_add = function(value) {
			if (missing(value)) return(private$data[["egg_add"]])
			private$data[["egg_add"]] <- private$validate("egg_add", value)
		},
		implement_disease = function(value) {
			if (missing(value)) return(private$data[["implement_disease"]])
			private$data[["implement_disease"]] <- private$validate("implement_disease", value)
		},
		n_batches = function(value) {
			if (missing(value)) return(nrow(private$data))
			stop("`n_batches` cannot be reassigned after construction; create a new PopVars() object (or use add_row()) instead.")
		}
	)
))

#' Create a PopVars object
#'
#' Constructs an R6 object representing a CDMetaPOP `PopVars.csv` input
#' file. Unlike [ClassVars()] (rows = age classes) and [PatchVars()] (rows =
#' patches), each row of a `PopVars` object is its own independent "batch"
#' -- CDMetaPOP runs each `RunVars` row (a "run") x each `PopVars` row (a
#' "batch") as a separate simulation (see the user manual's run-parameters
#' section). Despite that, columns are still edited as a whole via `$`, e.g.
#' `mypopvars$matemoveno <- c(6, 6, 4, 6)`, for consistency with
#' `ClassVars`/`PatchVars`.
#'
#' Any column argument left unsupplied defaults to the corresponding values
#' in `example_files/popvars/PopVars.csv`, matched to each requested
#' batch (recycling the row-4 default, with a warning, for rows
#' beyond what that file defines).
#'
#' @details
#' **CDMetaPOP reads `PopVars.csv` headers as dictionary keys**, unlike
#' `ClassVars.csv`/`PatchVars.csv` (column *order* only) -- so every column
#' name below is used verbatim as both the data frame's column name and this
#' function's argument/active-binding name, with no separate human-readable
#' header text. All manual-documented columns are included, even the
#' disease-related ones (`egg_add`, `implement_disease`). `cdinfect`/
#' `transmissionprob` were present in the canonical example file but are
#' deliberately excluded -- confirmed stale leftovers; CDMetaPOP runs fine
#' without them.
#'
#' **Delimiters:** most columns support CDMetaPOP's `|` (temporal change,
#' see [PatchVars()]'s Details) and/or `~` (per-sex, see [ClassVars()]'s
#' Details) mechanisms, per the user manual's `†`/`**` markers respectively.
#' A few fields use other manual-documented delimiters for a specific
#' purpose: `alleles` and `implementSelection`/`implementPlasticgene` use
#' `:` (per-locus allele counts; ':'-joined timing keywords, respectively),
#' and `growth_Loo` uses `;` for its two genotype-linked values
#' (`Loo_1;Loo_2`) -- see `.popv_rules`' doc comment in class_popvars.R for
#' the full per-field delimiter design and known open questions.
#'
#' **`xyfilename` (nested PatchVars reference)** accepts a [PatchVars()]
#' object directly, a character path, or the name of a `PatchVars` object in
#' `.GlobalEnv` (see [PatchVars()]'s Details for the identical `class_vars`
#' name-resolution mechanism and its caveats).
#'
#' **Matrix fields** (`mate_cdmat`, `migrateout_cdmat`, `migrateback_cdmat`,
#' `stray_cdmat`, `disperseLocal_cdmat`, `correlation_matrix`,
#' `subpopmort_file`) each accept, per batch, ONE of: a single raw R
#' `matrix`; a file path; or (for `migrateout_cdmat`, `correlation_matrix`,
#' `subpopmort_file`) the literal `"N"`. **A raw matrix may only be a single
#' value** -- to vary a matrix over time (the `|` cdclimate mechanism) or by
#' sex (`~`), you must supply file *paths*, not matrices (e.g.
#' `pv$mate_cdmat <- "surface0.csv|surface5.csv"`). Supplying a matrix is an
#' opt-in convenience for the common single-surface case; the field defaults
#' remain the canonical csv paths, so a no-argument `PopVars()` is valid.
#' When a matrix is supplied, it is serialized to a csv by
#' [launch_cdmetapop()] (named after your R variable; see the package's file
#' organization documentation), not by you. If you want control over a
#' matrix file's location/format, supply a path and write that file
#' yourself.
#'
#' @param n_batches Number of independent batches. Defaults to 4,
#'   matching `PopVars.csv`. Cannot be changed after construction (use
#'   `add_row()` or [add_rows()] instead).
#' @param xyfilename A [PatchVars()] object, object-name/path string, for
#'   each batch.
#' @param mate_cdmat,migrateout_cdmat,migrateback_cdmat,stray_cdmat,disperseLocal_cdmat
#'   A cost-distance/probability `matrix` (single value only) or a file path
#'   (`|`/`~`-delimited for temporal/per-sex), or `"N"` for
#'   `migrateout_cdmat` (skip the emigration module). See Details.
#' @param matemoveno,migratemoveOutno,migratemoveBackno,StrayBackno,disperseLocalno
#'   Movement function code, `1`-`11` (see manual for the function each code
#'   selects).
#' @param matemoveparA,matemoveparB,matemoveparC,migratemoveOutparA,migratemoveOutparB,migratemoveOutparC,migratemoveBackparA,migratemoveBackparB,migratemoveBackparC,StrayBackparA,StrayBackparB,StrayBackparC,disperseLocalparA,disperseLocalparB,disperseLocalparC
#'   Movement function parameters A/B/C (meaning depends on the
#'   corresponding `*no` function code).
#' @param matemovethresh,migratemoveOutthresh,migratemoveBackthresh,StrayBackthresh,disperseLocalthresh
#'   Movement threshold: `"max"`, `"<percent>max"` (e.g. `"10max"`), or a
#'   cost-distance value.
#' @param HomeAttempt How a migrant that cannot return home is handled:
#'   `"mortality"`, `"stray_emiPop"`, or `"stray_natalPop"`.
#' @param sex_chromo Number of sex chromosome combinations: `2`, `3`, or `4`.
#' @param sexans Reproduction mode: `"Y"` (sexual), `"N"` (asexual), or
#'   `"H"` (hermaphroditic).
#' @param selfans Selfing: `"Y"`, `"N"`, or a `[0, 1]` probability (for
#'   `sexans = "H"`).
#' @param Freplace,Mreplace Mating-with-replacement flags, `"Y"`/`"N"`.
#' @param AssortativeMate_Model Assortative mating model: `"1"`, `"2"`,
#'   `"3a"`, `"3b"`, `"4"`, or `"5"`.
#' @param AssortativeMate_Factor Assortative mating factor, `[1, 1000000]`.
#' @param mature_default Default maturation trigger, e.g. `"age6"`,
#'   `"size200"`, or `"N"`.
#' @param mature_eqn_slope,mature_eqn_int Size-based maturation probability
#'   function parameters.
#' @param offno Offspring-count draw choice: `1` (uniform), `2` (Poisson),
#'   `3` (constant), or `4` (normal).
#' @param offans_InheritClassVars How offspring inherit `ClassVars` when
#'   multiple are specified: `"random"`, `"Hindex"`, or `"mother"`.
#' @param equalClutchSize `"Y"`/`"N"`: equal clutch size per mate pair.
#' @param Egg_Freq_Mean,Egg_Freq_StDev Egg-laying frequency mean/standard
#'   deviation.
#' @param Egg_Mean_ans Size-based fecundity function: `"exp"`, `"linear"`,
#'   or `"pow"`.
#' @param Egg_Mean_par1,Egg_Mean_par2 Parameters for the above function.
#' @param Egg_Mortality,Egg_Mortality_StDev Egg mortality `[0, 1]` (or
#'   `"N"`) and its standard deviation.
#' @param Egg_FemaleProb Probability an egg is female, `[0, 1]`, or
#'   `"WrightFisher"`.
#' @param startGenes Time unit genetic exchange begins.
#' @param loci,alleles Number of loci (>= 2); number of starting alleles per
#'   locus (>= 2), or `:`-separated per-locus counts (e.g. `"2:5:3"`).
#' @param muterate Allele mutation rate, `[0, 1]`.
#' @param mutationtype Mutation model: `"random"`, `"forward"`,
#'   `"backward"`, `"forwardbackward"`, or `"forwardAbackwardBrandomN"`.
#' @param mtdna `"Y"`/`"N"`: track a maternal (mtDNA) marker locus.
#' @param cdevolveans Selection model/mechanism (open-ended; see manual for
#'   the full grammar, e.g. `"N"`, `"1"`, `"M"`, `"Hindex_Gauss_..."`).
#' @param startSelection Time unit selection begins.
#' @param implementSelection `:`-joined timing keyword(s), e.g.
#'   `"Out:Back"`.
#' @param betaFile_selection Polygenic-selection beta-value file path, or
#'   `"N"`.
#' @param plasticgeneans Phenotypic plasticity signal/response spec (open-
#'   ended; see manual), or `"N"`.
#' @param plasticSignalResponse,plasticBehavioralResponse Plasticity signal
#'   trigger value and behavioral response threshold.
#' @param startPlasticgene Time unit the plastic process begins.
#' @param implementPlasticgene `:`-joined timing keyword(s), e.g.
#'   `"Back"`.
#' @param growth_option Growth function: `"N"`, `"known"`, `"vonB"`,
#'   `"temperature"`, `"temperature_hindex"`, or `"bioenergetics"`.
#' @param growth_Loo Von Bertalanffy L-infinity, or two `;`-separated
#'   genotype-linked values (`"Loo_1;Loo_2"`).
#' @param growth_R0,growth_temp_max,growth_temp_CV,growth_temp_t0 Remaining
#'   growth function parameters.
#' @param popmodel Population growth model: `"N"`, `"logistic_out"`,
#'   `"logistic_back"`, `"packing"`, `"packing_1"`, or `"anadromy"`.
#' @param popmodel_par1 Parameter for the `"packing"`/`"packing_1"` models.
#' @param correlation_matrix Patch-level correlation matrix: a `matrix`
#'   (single value), a file path, or `"N"`. A matrix field -- see Details.
#' @param subpopmort_file Sub-population dispersal mortality matrix: a
#'   `matrix` (single value), a file path, or `"N"`. A matrix field -- see
#'   Details.
#' @param egg_delay Integer >= 0: years between mating and
#'   gestation/emergence.
#' @param egg_add `"mating"` or `"nonmating"` (case-insensitive).
#' @param implement_disease Disease module timing: `"N"`, `"Back"`,
#'   `"Out"`, or `"Both"`.
#' @param resolve_xyfilename Whether `xyfilename` character entries should
#'   be resolved against `PatchVars` objects in `.GlobalEnv` by name (see
#'   Details). Defaults to `TRUE`; set to `FALSE` when every `xyfilename`
#'   value is known to already be a literal path (e.g.
#'   `read_cdmetapop(..., type = "PopVars")` does this automatically).
#'
#' @return An R6 `PopVars` object.
#' @export
#'
#' @examples
#' # Default 4-batch object, matching PopVars.csv:
#' mypopvars <- PopVars()
#'
#' # 1 batch, defaults taken from PopVars.csv's first row:
#' mypopvars <- PopVars(n_batches = 1)
#'
#' # Edit a column in place (one value per batch):
#' mypopvars$matemoveno <- c(6, 6, 4, 6)
#'
#' # Add a batch (copies the last row; edit afterward):
#' mypopvars$add_row()
#' # or equivalently:
#' add_rows(mypopvars)
PopVars <- function(
	n_batches = 4,
	xyfilename = c("patchvars/PatchVars.csv", "patchvars/PatchVars_anadromy.csv", "patchvars/PatchVars.csv", "patchvars/PatchVars.csv"),
	mate_cdmat = c("cdmats/Patch7_CdmatrixS1.csv", "cdmats/Patch7_CdmatrixS1.csv", "cdmats/Patch7_CdmatrixS1.csv", "cdmats/Patch7_CdmatrixS1.csv"),
	matemoveno = c("6", "6", "4", "6"),
	matemoveparA = c("1.346", "1.346", "1.346", "1.346"),
	matemoveparB = c("202.4846", "202.4846", "202.4846", "202.4846"),
	matemoveparC = c("6", "6", "6", "6"),
	matemovethresh = c("6000", "6000", "6000", "6000"),
	migrateout_cdmat = c("cdmats/Patch7_Probmatrix_onewayBarriersXRiverineS1.csv", "cdmats/Patch7_Probmatrix_onewayBarriersXRiverineS1.csv", "cdmats/Patch7_Probmatrix_onewayBarriersXRiverineS1.csv", "cdmats/Patch7_Probmatrix_onewayBarriersXRiverineS1.csv"),
	migratemoveOutno = c("4", "4", "9", "9"),
	migratemoveOutparA = c("0", "0", "0", "0"),
	migratemoveOutparB = c("0", "0", "0", "0"),
	migratemoveOutparC = c("0", "0", "0", "0"),
	migratemoveOutthresh = c("max~max", "max~max", "max~max", "max~max"),
	migrateback_cdmat = c("cdmats/Patch7_Probmatrix_onewayBarriersXRiverineS1.csv", "cdmats/Patch7_Probmatrix_onewayBarriersXRiverineS1.csv", "cdmats/Patch7_Probmatrix_onewayBarriersXRiverineS1.csv", "cdmats/Patch7_Probmatrix_onewayBarriersXRiverineS1.csv"),
	migratemoveBackno = c("4", "4", "9", "9"),
	migratemoveBackparA = c("0", "0", "0", "0"),
	migratemoveBackparB = c("0", "0", "0", "0"),
	migratemoveBackparC = c("0", "0", "0", "0"),
	migratemoveBackthresh = c("max~max", "max~max", "max~max", "max~max"),
	stray_cdmat = c("cdmats/Patch7_CdmatrixS1.csv", "cdmats/Patch7_CdmatrixS1.csv", "cdmats/Patch7_CdmatrixS1.csv", "cdmats/Patch7_CdmatrixS1.csv"),
	StrayBackno = c("1", "1", "4", "2"),
	StrayBackparA = c("0.01", "0.01", "0.01", "0.01"),
	StrayBackparB = c("0.01", "0.01", "0.01", "0.01"),
	StrayBackparC = c("0", "0", "0", "0"),
	StrayBackthresh = c("max", "max", "max", "max"),
	disperseLocal_cdmat = c("cdmats/Patch7_Probmatrix_Dispersal.csv", "cdmats/Patch7_Probmatrix_Dispersal.csv", "cdmats/Patch7_CdmatrixS1.csv", "cdmats/Patch7_CdmatrixS1.csv"),
	disperseLocalno = c("9", "9", "2", "2"),
	disperseLocalparA = c("0.01", "0.01", "0.01", "0.01"),
	disperseLocalparB = c("0.01", "0.01", "0.01", "0.01"),
	disperseLocalparC = c("0", "0", "0", "0"),
	disperseLocalthresh = c("max", "max", "max", "max"),
	HomeAttempt = c("mortality", "mortality", "mortality", "mortality"),
	sex_chromo = c("2", "2", "2", "2"),
	sexans = c("Y", "Y", "Y", "H"),
	selfans = c("N", "N", "N", "0.5"),
	Freplace = c("Y", "Y", "Y", "Y"),
	Mreplace = c("Y", "Y", "Y", "Y"),
	AssortativeMate_Model = c("1", "1", "1", "1"),
	AssortativeMate_Factor = c("1", "1", "1", "1"),
	mature_default = c("age3|age6|age3", "age3", "size300", "N"),
	mature_eqn_slope = c("0.13~0.06|0.13~0.06|0.13~0.06", "0.0539", "0.13~0.06", "0.13~0.06"),
	mature_eqn_int = c("-20.28~-8.09|-20.28~-8.09|-20.28~-8.09", "-6.313", "-20.28~-8.09", "-20.28~-8.09"),
	offno = c("2", "2", "2", "2"),
	offans_InheritClassVars = c("random", "random", "random", "random"),
	equalClutchSize = c("N", "N", "N", "N"),
	Egg_Freq_Mean = c("1", "1", "1", "0.5"),
	Egg_Freq_StDev = c("1", "1", "0", "0.1"),
	Egg_Mean_ans = c("linear", "linear", "exp", "exp"),
	Egg_Mean_par1 = c("-445", "-445", "126.07", "126.07"),
	Egg_Mean_par2 = c("3.78", "3.78", "0.0061", "0.0061"),
	Egg_Mortality = c("N", "0.62", "0.62", "0"),
	Egg_Mortality_StDev = c("0", "0", "0.18", "0"),
	Egg_FemaleProb = c("0.5", "0.5", "0.5", "0.5"),
	startGenes = c("0", "0", "0", "0"),
	loci = c("2", "2", "2", "2"),
	alleles = c("2", "2", "2", "2"),
	muterate = c("0", "0", "0", "0"),
	mutationtype = c("random", "random", "random", "random"),
	mtdna = c("N", "N", "N", "N"),
	cdevolveans = c("N", "N", "N", "N"),
	startSelection = c("0", "0", "0", "0"),
	implementSelection = c("Out:Back", "Out:Back", "Eggs", "Back"),
	betaFile_selection = c("N", "N", "N", "N"),
	plasticgeneans = c("N", "N", "N", "N"),
	plasticSignalResponse = c("0", "0", "0", "0"),
	plasticBehavioralResponse = c("0", "0", "0", "0"),
	startPlasticgene = c("0", "0", "0", "0"),
	implementPlasticgene = c("Back:0", "Back:0", "Back", "Back"),
	growth_option = c("temperature", "temperature", "temperature", "temperature"),
	growth_Loo = c("400", "400", "250", "250"),
	growth_R0 = c("0.47", "0.47", "0.57", "0.57"),
	growth_temp_max = c("10.5", "10.5", "12", "12"),
	growth_temp_CV = c("0.33", "0.33", "0.25", "0.25"),
	growth_temp_t0 = c("-0.075", "-0.075", "-0.196", "-0.196"),
	popmodel = c("packing", "anadromy", "logistic_back", "N"),
	popmodel_par1 = c("-0.6821", "-0.6821", "-0.6821", "-0.6821"),
	correlation_matrix = c("N", "N", "N", "N"),
	subpopmort_file = c("N", "N", "N", "N"),
	egg_delay = c("0", "0", "0", "0"),
	egg_add = c("mating", "mating", "mating", "mating"),
	implement_disease = c("N", "N", "N", "N"),
	resolve_xyfilename = TRUE
) {
	# See ClassVars()'s wrapper function for why these literal defaults are
	# forwarded as NULL to .PopVarsR6$new() when not actually supplied by
	# the caller (preserves the initializer's own row-count-based
	# default-resizing logic).
	this_env <- environment()
	supplied <- vapply(.popv_fields, function(field) {
		!eval(substitute(missing(x), list(x = as.name(field))), envir = this_env)
	}, logical(1))
	names(supplied) <- .popv_fields

	column_args <- mget(.popv_fields, envir = environment())
	column_args[!supplied] <- list(NULL)

	do.call(.PopVarsR6$new, c(
		list(n_batches = n_batches, resolve_xyfilename = resolve_xyfilename),
		column_args
	))
}
