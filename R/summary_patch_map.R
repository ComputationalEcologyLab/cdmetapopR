#' Map CDMetaPOP Patch Abundance and Movement
#'
#' Creates a faceted patch map from CDMetaPOP `ind##.csv` files. Points are
#' drawn at patch coordinates and scaled by the number of individuals in each
#' patch.
#'
#' @param path A dataframe, file path, vector of file paths, run directory, or
#'   top-level output directory containing `ind##.csv` files.
#' @param years Integer vector. Years/generations to map. Defaults to `0`.
#' @param run Integer. Run index used when `path` is a directory. Defaults to
#'   `0`.
#' @param batch Integer. Batch index used when `path` is a directory. Defaults
#'   to `0`.
#' @param mc Integer. Monte Carlo index used when `path` is a directory.
#'   Defaults to `0`.
#' @param species Integer. Species index used when `path` is a directory.
#'   Defaults to `0`.
#' @param states Optional vector of disease states to include. If `NULL`, all
#'   individuals are used.
#' @param facet_by_state Logical. If `TRUE`, facet by disease state as well as
#'   year. Defaults to `FALSE`.
#' @param crs Optional coordinate reference system label. For example, use
#'   `5070` or `"EPSG:5070"` for NAD83 / Conus Albers. Coordinates are not
#'   transformed; this is used for labeling and stored as plot data metadata.
#'
#' @return A ggplot object with patch-level summary data in `plot$data`.
#' @examples
#' ex_dir <- system.file("extdata", "Adaptive_Run_08", package = "cdmetapopR")
#'
#' summary_patch_map(ex_dir, years = c(0, 5, 9), crs = 5070)
#' summary_patch_map(ex_dir, years = c(0, 5, 9), states = 1, crs = 5070)
#' summary_patch_map(ex_dir, years = c(0, 9), states = c(0, 1), facet_by_state = TRUE, crs = 5070)
#' @export
summary_patch_map <- function(path,
                              years = 0,
                              run = 0,
                              batch = 0,
                              mc = 0,
                              species = 0,
                              states = NULL,
                              facet_by_state = FALSE,
                              crs = NULL) {
  data <- .resolve_ind_input(
    path = path,
    run = run,
    batch = batch,
    mc = mc,
    species = species,
    years = years
  )

  .check_ind_columns(data, c("PatchID", "XCOORD", "YCOORD", "Year", "state"))

  if (!is.null(states)) {
    data <- data[data$state %in% states, , drop = FALSE]
  }

  if (nrow(data) == 0) {
    stop("No individuals matched the requested years, run, batch, MC, species, and states.")
  }

  if (!facet_by_state) {
    data$.plot_state <- "All selected states"
  } else {
    data$.plot_state <- paste("State", data$state)
  }

  split_groups <- split(
    data,
    interaction(data$Year, data$.plot_state, data$PatchID, drop = TRUE, lex.order = TRUE)
  )

  plot_data <- do.call(
    rbind,
    lapply(split_groups, function(df) {
      data.frame(
        Year = df$Year[1],
        State = df$.plot_state[1],
        PatchID = df$PatchID[1],
        XCOORD = mean(as.numeric(df$XCOORD), na.rm = TRUE),
        YCOORD = mean(as.numeric(df$YCOORD), na.rm = TRUE),
        count = nrow(df),
        stringsAsFactors = FALSE
      )
    })
  )

  year_levels <- sort(unique(plot_data$Year))
  plot_data$Year <- factor(plot_data$Year, levels = year_levels)
  plot_data$PatchID <- factor(
    plot_data$PatchID,
    levels = as.character(sort(unique(as.numeric(as.character(plot_data$PatchID)))))
  )

  crs_label <- NULL
  if (!is.null(crs)) {
    crs_label <- if (is.numeric(crs)) paste0("EPSG:", crs) else as.character(crs)
    attr(plot_data, "crs") <- crs_label
  }

  x_lab <- if (is.null(crs_label)) "X coordinate" else paste0("X coordinate (", crs_label, ")")
  y_lab <- if (is.null(crs_label)) "Y coordinate" else paste0("Y coordinate (", crs_label, ")")

  p <- ggplot2::ggplot(
    plot_data,
    ggplot2::aes(
      x = .data$XCOORD,
      y = .data$YCOORD,
      size = .data$count
    )
  ) +
    ggplot2::geom_point(alpha = 0.75, color = "steelblue") +
    ggplot2::coord_equal() +
    ggplot2::labs(
      title = "Patch Abundance",
      x = x_lab,
      y = y_lab,
      size = "Individuals"
    )

  if (facet_by_state) {
    p <- p + ggplot2::facet_grid(State ~ Year)
  } else {
    p <- p + ggplot2::facet_wrap(~ Year)
  }

  p + .theme_cdmetapop()
}
