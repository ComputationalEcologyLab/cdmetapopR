# Standalone, non-`$`-based functions for working with cdmetapopR's R6
# input-file objects (ClassVars, and eventually PatchVars/PopVars/RunVars).
#
# These are thin S3 generics dispatching on each object's R6 class name; the
# actual implementation lives on the R6 object itself (e.g. `x$write_cdmetapop()`),
# so this file should only ever contain a `<generic>` definition plus one
# `<generic>.<ClassName>` method per cdmetapopR input-file class -- not
# class-specific logic. Add one new `.<ClassName>` method per generic here
# as each new class (PatchVars, PopVars, RunVars, ...) is implemented.

#' Write a cdmetapopR input-file object to a CDMetaPOP-readable csv
#'
#' Generic function dispatching on the class of `x` (e.g. [ClassVars()]).
#' This is the standalone, non-`$`-based equivalent of calling
#' `x$write_cdmetapop(path)` directly; both have identical effect.
#'
#' @param x A cdmetapopR input-file object, e.g. a [ClassVars()] object.
#' @param path Destination file path. Defaults to `x`'s own `location`
#'   field if not supplied.
#' @return `path`, invisibly.
#' @export
#'
#' @examples
#' myclassvars <- ClassVars(location = tempfile(fileext = ".csv"))
#' write_cdmetapop(myclassvars)
write_cdmetapop <- function(x, path = NULL) UseMethod("write_cdmetapop")

#' @export
write_cdmetapop.ClassVars <- function(x, path = NULL) x$write_cdmetapop(path)

#' @export
write_cdmetapop.PatchVars <- function(x, path = NULL) x$write_cdmetapop(path)

#' Add one or more rows to a cdmetapopR input-file object
#'
#' Generic function dispatching on the class of `x` (e.g. [ClassVars()]).
#' For a [ClassVars()] object, this adds `n` new age classes, each
#' initialized as a copy of the current oldest (last) age class; edit the
#' new row(s) afterward via the column active bindings (e.g.
#' `myclassvars$maturation <- ...`).
#'
#' @param x A cdmetapopR input-file object, e.g. a [ClassVars()] object.
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

#' View a cdmetapopR input-file object as a plain data frame
#'
#' Returns an ordinary (independent) `data.frame` copy of `x`'s underlying
#' table -- e.g. for inspection with `View()`, or for any other base-R/
#' tidyverse workflow expecting a data frame. Editing the returned copy
#' never affects `x` itself; edit `x` through its column active bindings
#' (e.g. `x$maturation <- ...`) instead.
#'
#' @param x A cdmetapopR input-file object, e.g. a [ClassVars()] object.
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
