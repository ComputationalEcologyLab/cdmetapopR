#' Plot CDMetaPOP Class Summary Dynamics
#'
#' Summarizes and plots data from `summary_classAllTime.csv` files. Inputs can
#' be a data frame, one file path, multiple file paths, or a CDMetaPOP output
#' directory containing `summary_classAllTime.csv` files.
#'
#' @param data A dataframe, file path (`.csv`, `.rds`, `.RData`), vector of file
#'   paths, or a directory containing `summary_classAllTime.csv` files.
#' @param type String specifying the plot type: `"age_class"` or
#'   `"age_plus_one"`.
#' @param batch_labels Optional named character vector used to relabel faceted
#'   source groups. Names should match folder names such as `N.out1776184541`
#'   and values should be the labels displayed in the facet strips.
#' @param show_mc Logical. If `TRUE`, plot individual Monte Carlo trajectories
#'   when multiple source files are supplied for line-based plots. Defaults to
#'   `TRUE`.
#' @param show_ci Logical. If `TRUE`, plot the mean and a 95% confidence band
#'   across Monte Carlo replicates when multiple source files are supplied for
#'   line-based plots. Defaults to `TRUE`.
#' @param ... Additional arguments passed to specific plot types. Use `n` to
#'   choose the year interval for `"age_class"` plots.
#'
#' @return A ggplot object.
#' @examples
#' ex_dir <- system.file("extdata", "Adaptive_Run_08", package = "cdmetapopR")
#'
#' summary_class(ex_dir, type = "age_class", n = 10)
#' summary_class(ex_dir, type = "age_plus_one")
#' @export
summary_class <- function(data, type = "age_class", batch_labels = NULL, show_mc = TRUE, show_ci = TRUE, ...) {
  type <- strsplit(tolower(type), " ")[[1]][1]
  data <- .resolve_cdmetapop_input(data, summary_type = "class")

  p <- switch(
    type,
    "age_class" = helper_plot_age_class(data, batch_labels = batch_labels, ...),
    "age_plus_one" = helper_plot_age_plus(
      data,
      batch_labels = batch_labels,
      show_mc = show_mc,
      show_ci = show_ci
    ),
    stop("Invalid type for summary_class. Choose: 'age_class' or 'age_plus_one'.")
  )

  p + .theme_cdmetapop()
}
