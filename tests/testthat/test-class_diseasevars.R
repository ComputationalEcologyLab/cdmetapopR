# Tests for the DiseaseVars class: construction, per-field validation, the
# cross-field error/warning split, the single-row rule, and the generics.
#
# `warnings_of()` is used instead of expect_no_warning() so these run against
# the testthat version DESCRIPTION asks for (>= 3.0.0).

warnings_of <- function(expr) {
	w <- character(0)
	withCallingHandlers(expr, warning = function(cond) {
		w <<- c(w, conditionMessage(cond))
		invokeRestart("muffleWarning")
	})
	w
}

test_that("DiseaseVars() builds the default SIR model", {
	dv <- DiseaseVars()
	df <- dv$as_data_frame()

	expect_s3_class(dv, "DiseaseVars")
	expect_equal(nrow(df), 1)
	expect_identical(colnames(df), .dv_headers)
	expect_identical(dv$n_states, "3")
	expect_identical(dv$initial_conditions, "0.9;0.1;0.0")
	expect_identical(dv$transmission_mode, "Direct")
	expect_identical(dv$death_states, "N")
	expect_length(warnings_of(DiseaseVars()), 0)
})

test_that("transition_rates is stored as a one-item list column", {
	dv <- DiseaseVars()
	cell <- dv$as_data_frame()[["Transition Rates"]]

	expect_true(is.list(cell))
	expect_length(cell, 1)
	expect_identical(cell[[1]], "otherfiles/disease/TransitionMatrix_SIR.csv")
})

test_that("numeric fields are validated", {
	expect_error(DiseaseVars(n_states = 2.5), "whole number")
	expect_error(DiseaseVars(n_states = 0), "outside the allowed range")
	expect_error(DiseaseVars(start_disease = -1), "outside the allowed range")
	expect_error(DiseaseVars(initial_conditions = "1.5;-0.5"), "outside \\[0, 1\\]")
	expect_error(DiseaseVars(initial_conditions = "a;b;c"), "proportions")
})

test_that("transmission_mode is matched exactly, including case", {
	# CDMetaPOP's own check lowercases this value but every use of it is a
	# case-sensitive comparison against "Indirect", so a lowercase spelling
	# would silently run as Direct.
	expect_error(DiseaseVars(transmission_mode = "indirect"), "matched exactly")
	expect_error(DiseaseVars(transmission_mode = "Both"), "must be one of")
})

test_that("death_states takes one index or \"N\"", {
	expect_identical(DiseaseVars(death_states = "N")$death_states, "N")
	expect_identical(DiseaseVars(death_states = 2)$death_states, "2")
	expect_error(
		DiseaseVars(n_states = 4, initial_conditions = "0.7;0.1;0.1;0.1",
			death_states = "2;3"),
		"single state index"
	)
})

test_that("the offspring rule follows the engine, not the manual", {
	# The manual and the Shiny app document "Vertical_X:Y" and a "Random"
	# option; the engine reads "Vertical;<rate>" and has no Random branch.
	expect_identical(
		DiseaseVars(initial_conditions_offspring = "Vertical;0.5")$initial_conditions_offspring,
		"Vertical;0.5"
	)
	expect_error(DiseaseVars(initial_conditions_offspring = "Random"), "Susceptible")
	expect_error(DiseaseVars(initial_conditions_offspring = "Vertical_0.5:0.1"), "Susceptible")
	expect_error(DiseaseVars(initial_conditions_offspring = "Vertical;2"), "between 0 and 1")
})

test_that("defense specs are state-pair lists or \"N\"", {
	expect_identical(DiseaseVars(disease_resistant = "0_1")$disease_resistant, "0_1")
	expect_identical(DiseaseVars(disease_tolerant = "N")$disease_tolerant, "N")
	expect_error(DiseaseVars(disease_resistant = "0"), "from>_<to")
	expect_error(DiseaseVars(disease_resistant = "0_1_2"), "from>_<to")
})

test_that("multiple susceptible and infection states are accepted", {
	dv <- DiseaseVars(n_states = 4, initial_conditions = "0.7;0.1;0.1;0.1",
		susceptible_states = "0;3", infection_states = "1;2")

	expect_identical(dv$susceptible_states, "0;3")
	expect_identical(dv$infection_states, "1;2")
})

test_that("only one value per field is accepted", {
	expect_error(DiseaseVars(start_disease = c(0, 1)), "exactly one row")
})

test_that("a transition-rates matrix is validated", {
	m <- matrix(0, 3, 3)
	m[2, 1] <- 0.5
	m[3, 2] <- 0.2
	expect_identical(DiseaseVars(transition_rates = m)$transition_rates[[1]], m)

	# A character matrix carries "mu;sigma" cells, which CDMetaPOP redraws from
	# a normal distribution at each CDClimate step.
	cm <- matrix("0", 3, 3)
	cm[2, 1] <- "0.5;0.05"
	expect_true(is.matrix(DiseaseVars(transition_rates = cm)$transition_rates[[1]]))

	expect_error(DiseaseVars(transition_rates = matrix(0, 3, 4)), "square")
	expect_error(DiseaseVars(transition_rates = matrix("x", 3, 3)), "must be a number")
	expect_error(DiseaseVars(transition_rates = matrix(NA_real_, 3, 3)), "cannot contain NA")
	expect_error(DiseaseVars(transition_rates = "N"), "does not accept")
})

test_that("cross-field rules error at construction", {
	expect_error(DiseaseVars(n_states = 4), "one per state")
	expect_error(DiseaseVars(initial_conditions = "0.5;0.1;0.1"), "sums to")
	expect_error(DiseaseVars(infection_states = "3"), "highest valid index")
	expect_error(DiseaseVars(death_states = "3"), "highest valid index")
	expect_error(DiseaseVars(transition_rates = matrix(0, 4, 4)), "requires 3 x 3")
	expect_error(
		DiseaseVars(transmission_mode = "Indirect", transition_rates = matrix(0, 3, 3)),
		"requires 4 x 4"
	)
})

test_that("the environmental reservoir is a valid defense source only when Indirect", {
	# With 3 states the reservoir is index 3, which is why the canonical
	# "0_1;3_1" is legal under Indirect transmission and not under Direct.
	expect_identical(
		DiseaseVars(transmission_mode = "Indirect", transition_rates = matrix(0, 4, 4),
			disease_resistant = "0_1;3_1")$disease_resistant,
		"0_1;3_1"
	)
	expect_error(DiseaseVars(disease_resistant = "0_1;3_1"), "highest valid index")
})

test_that("editing one column warns instead of erroring, in either order", {
	# Consistency cannot be maintained assignment-by-assignment: moving from 3
	# to 4 states needs two separate assignments, so whichever comes first
	# would otherwise be rejected.
	dv <- DiseaseVars()
	w <- warnings_of(dv$n_states <- 4)
	expect_length(w, 1)
	expect_match(w, "one per state")
	expect_identical(dv$n_states, "4")
	expect_error(dv$check(), "Inconsistent DiseaseVars")

	expect_length(warnings_of(dv$initial_conditions <- "0.7;0.1;0.1;0.1"), 0)
	expect_silent(dv$check())

	dv2 <- DiseaseVars()
	expect_length(warnings_of(dv2$initial_conditions <- "0.7;0.1;0.1;0.1"), 1)
	expect_length(warnings_of(dv2$n_states <- 4), 0)
	expect_silent(dv2$check())
})

test_that("a DiseaseVars object holds exactly one row", {
	expect_error(DiseaseVars()$add_row(), "exactly one row")
	expect_error(add_rows(DiseaseVars()), "exactly one row")
})

test_that("the generics dispatch", {
	dv <- DiseaseVars()
	expect_true(is.data.frame(as.data.frame(dv)))
	expect_equal(ncol(as.data.frame(dv)), 11)
	expect_output(print(dv), "<DiseaseVars>")
})
