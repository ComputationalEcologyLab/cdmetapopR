#' Plot CDMetaPOP Population Summary Dynamics
#'
#' Summarizes and plots data from `summary_popAllTime.csv` files. Inputs can be
#' a data frame, one file path, multiple file paths, or a CDMetaPOP output
#' directory containing `summary_popAllTime.csv` files.
#'
#' @param data A dataframe, file path (`.csv`, `.rds`, `.RData`), vector of file
#'   paths, or a directory containing `summary_popAllTime.csv` files.
#' @param type String specifying the plot type: `"N_initial"`, `"sex"`,
#'   `"mature"`, `"births"`, `"myy_ratio"`, `"patch"`,
#'   `"allelic_richness"`, or `"het"`.
#' @param batch_labels Optional named character vector used to relabel faceted
#'   source groups. Names should match folder names such as `N.out1776184541`
#'   and values should be the labels displayed in the facet strips.
#' @param show_mc Logical. If `TRUE`, plot individual Monte Carlo trajectories
#'   when multiple source files are supplied. Defaults to `TRUE`.
#' @param show_ci Logical. If `TRUE`, plot the mean and a 95% confidence band
#'   across Monte Carlo replicates when multiple source files are supplied.
#'   Defaults to `TRUE`.
#' @param run Integer run index used when `data` is a directory. Defaults to
#'   `0`. Use `"all"` to include all runs.
#' @param batch Integer batch index used when `data` is a directory. Defaults
#'   to `0`. Use `"all"` to include all batches.
#' @param mc Integer Monte Carlo index used when `data` is a directory.
#'   Defaults to `0`. Use `"all"` to include all Monte Carlo replicates.
#' @param species Integer species index used when `data` is a directory.
#'   Defaults to `0`. Use `"all"` to include all species.
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
#' summary_pop(ex_dir, type = "allelic_richness")
#' summary_pop(ex_dir, type = "het")
#' @export
summary_pop <- function(data, type = "N_initial", batch_labels = NULL, show_mc = TRUE, show_ci = TRUE, run = 0, batch = 0, mc = 0, species = 0, ...) {
  type <- strsplit(tolower(type), " ")[[1]][1]
  data <- .resolve_cdmetapop_input(
    data,
    summary_type = "pop",
    run = run,
    batch = batch,
    mc = mc,
    species = species
  )

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
    "allelic_richness" = helper_plot_allelic_richness(
      data,
      batch_labels = batch_labels,
      show_mc = show_mc,
      show_ci = show_ci
    ),
    "het" = helper_plot_het(
      data,
      batch_labels = batch_labels,
      show_mc = show_mc,
      show_ci = show_ci
    ),
    "patch" = helper_plot_patch(data, batch_labels = batch_labels, ...),
    stop("Invalid type for summary_pop. Choose: 'N_initial', 'sex', 'mature', 'births', 'myy_ratio', 'patch', 'allelic_richness', or 'het'.")
  )

  p + .theme_cdmetapop()
}
