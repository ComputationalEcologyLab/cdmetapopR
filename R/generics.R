# Standalone, non-`$`-based functions for working with cdmetapopR's R6
# input-file objects (ClassVars, PatchVars, PopVars, RunVars, DiseaseVars).
#
# These are thin S3 generics dispatching on each object's R6 class name; the
# actual implementation lives on the R6 object itself (e.g. `x$add_row()`),
# so this file should only ever contain a `<generic>` definition plus one
# `<generic>.<ClassName>` method per cdmetapopR input-file class -- not
# class-specific logic. Add one new `.<ClassName>` method per generic here
# as each new input-file class is implemented.
#
# Note: the csv-writer here is not a generic. Writing input files is handled
# by the graph-writer at launch_cdmetapop() time (see plan.md Key Design
# Decision 6); write_cdmetapop() (R/write_cdmetapop.R) is a plain function
# providing a convenience fallback for writing one object by hand.

#' Add one or more rows to a cdmetapopR input-file object
#'
#' Generic function used to add rows to a [ClassVars()],
#' [PatchVars()], [PopVars()], or [RunVars()] object. Adds `n` new rows,
#' each initialized as a copy of the current last row; edit the new row(s)
#' afterward via the column active bindings (e.g.
#' `myclassvars$maturation <- ...`). What a "row" represents depends on the
#' class: an age class ([ClassVars()]), a patch ([PatchVars()]), a batch
#' ([PopVars()]), or a run ([RunVars()]).
#'
#' A [DiseaseVars()] object holds exactly one row -- CDMetaPOP reads a single
#' disease model from `DiseaseVars.csv` and ignores any further rows -- so
#' calling this on one is an error rather than a no-op. Create another
#' [DiseaseVars()] object to describe a second disease model.
#'
#' @param x A cdmetapopR input-file object: a [ClassVars()], [PatchVars()],
#'   [PopVars()], or [RunVars()] object.
#' @param n Number of rows to add. Defaults to `1`.
#' @return `x`, invisibly (modified in place, since `x` is an R6 object).
#' @export
#'
#' @examples
#' myclassvars <- ClassVars()
#' add_rows(myclassvars)
#' myclassvars$ages
add_rows <- function(x, n = 1) UseMethod("add_rows")

#' @export
add_rows.ClassVars <- function(x, n = 1) x$add_row(n)

#' @export
add_rows.PatchVars <- function(x, n = 1) x$add_row(n)

#' @export
add_rows.PopVars <- function(x, n = 1) x$add_row(n)

#' @export
add_rows.RunVars <- function(x, n = 1) x$add_row(n)

# Errors, by way of the method on the object itself (which explains why).
#' @export
add_rows.DiseaseVars <- function(x, n = 1) x$add_row(n)

#' View a cdmetapopR input-file object as a plain data frame
#'
#' Returns an ordinary (independent) `data.frame` copy of `x`'s underlying
#' table -- e.g. for inspection with `View()`, or for any other base-R/
#' tidyverse workflow expecting a data frame. Editing the returned copy
#' never affects `x` itself; edit `x` through its column active bindings
#' (e.g. `x$maturation <- ...`) instead.
#'
#' @param x A cdmetapopR input-file object: a [ClassVars()], [PatchVars()],
#'   [PopVars()], [RunVars()], or [DiseaseVars()] object.
#' @param ... Currently unused; present for S3 consistency with
#'   [base::as.data.frame()].
#' @return A `data.frame`.
#' @export
#'
#' @examples
#' myclassvars <- ClassVars()
#' as.data.frame(myclassvars)
as.data.frame.ClassVars <- function(x, ...) x$as_data_frame()

#' @export
as.data.frame.PatchVars <- function(x, ...) x$as_data_frame()

#' @export
as.data.frame.PopVars <- function(x, ...) x$as_data_frame()

#' @export
as.data.frame.RunVars <- function(x, ...) x$as_data_frame()

#' @export
as.data.frame.DiseaseVars <- function(x, ...) x$as_data_frame()
