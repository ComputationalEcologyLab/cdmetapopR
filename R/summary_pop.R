#' Plot CDMetaPOP Population Summary Dynamics
#'
#' Summarizes and plots data from `summary_popAllTime.csv` files. Inputs can be
#' a data frame, one file path, multiple file paths, or a CDMetaPOP output
#' directory containing `summary_popAllTime.csv` files.
#'
#' @param data A dataframe, file path (`.csv`, `.rds`, `.RData`), vector of file
#'   paths, or a directory containing `summary_popAllTime.csv` files.
#' @param type String specifying the plot type: `"N_initial"`, `"sex"`,
#'   `"mature"`, `"births"`, `"myy_ratio"`, or `"patch"`.
#' @param batch_labels Optional named character vector used to relabel faceted
#'   source groups. Names should match folder names such as `N.out1776184541`
#'   and values should be the labels displayed in the facet strips.
#' @param show_mc Logical. If `TRUE`, plot individual Monte Carlo trajectories
#'   when multiple source files are supplied. Defaults to `TRUE`.
#' @param show_ci Logical. If `TRUE`, plot the mean and a 95% confidence band
#'   across Monte Carlo replicates when multiple source files are supplied.
#'   Defaults to `TRUE`.
#' @param ... Additional arguments passed to specific plot types. Use
#'   `include_yys = TRUE` for `"sex"` or `"mature"` plots, or `years` for
#'   `"patch"` plots.
#'
#' @return A ggplot object.
#' @examples
#' ex_dir <- system.file("extdata", "Adaptive_Run_08", package = "cdmetapopR")
#'
#' summary_pop(ex_dir, type = "N_initial")
#' summary_pop(ex_dir, type = "sex")
#' summary_pop(ex_dir, type = "mature", include_yys = TRUE)
#' @export
summary_pop <- function(data, type = "N_initial", batch_labels = NULL, show_mc = TRUE, show_ci = TRUE, ...) {
  type <- strsplit(tolower(type), " ")[[1]][1]
  data <- .resolve_cdmetapop_input(data, summary_type = "pop")

  p <- switch(
    type,
    "n_initial" = helper_plot_n_initial(
      data,
      batch_labels = batch_labels,
      show_mc = show_mc,
      show_ci = show_ci
    ),
    "sex" = helper_plot_sex(
      data,
      batch_labels = batch_labels,
      show_mc = show_mc,
      show_ci = show_ci,
      ...
    ),
    "mature" = helper_plot_mature(
      data,
      batch_labels = batch_labels,
      show_mc = show_mc,
      show_ci = show_ci,
      ...
    ),
    "births" = helper_plot_births(
      data,
      batch_labels = batch_labels,
      show_mc = show_mc,
      show_ci = show_ci
    ),
    "myy_ratio" = helper_plot_myy(
      data,
      batch_labels = batch_labels,
      show_mc = show_mc,
      show_ci = show_ci
    ),
    "patch" = helper_plot_patch(data, batch_labels = batch_labels, ...),
    stop("Invalid type for summary_pop. Choose: 'N_initial', 'sex', 'mature', 'births', 'myy_ratio', or 'patch'.")
  )

  p + .theme_cdmetapop()
}
