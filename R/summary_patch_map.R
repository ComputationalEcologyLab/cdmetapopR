#' Map CDMetaPOP Patch Abundance
#'
#' Creates a faceted patch map from CDMetaPOP `ind##.csv` or
#' `ind##_Sample.csv` files. Points are drawn at patch coordinates and scaled
#' by the number of individuals in each patch.
#'
#' @param path A dataframe, file path, vector of file paths, run directory, or
#'   top-level output directory containing individual files.
#' @param type Character. What to map: `"abundance"`, `"allele_frequency"`,
#'   or `"heterozygosity"`. Defaults to `"abundance"`.
#' @param years Integer vector. Years/generations to map. Defaults to `0`.
#' @param run Integer. Run index used when `path` is a directory. Defaults to
#'   `0`.
#' @param batch Integer. Batch index used when `path` is a directory. Defaults
#'   to `0`.
#' @param mc Integer. Monte Carlo index used when `path` is a directory.
#'   Defaults to `0`.
#' @param species Integer. Species index used when `path` is a directory.
#'   Defaults to `0`.
#' @param file_type Character. Which individual file type to read. Use
#'   `"ind"` for `ind##.csv` files or `"ind_Sample"` for `ind##_Sample.csv`
#'   files. Defaults to `"ind"`.
#' @param patches Patch IDs to include. Use `"all"` to include all patches, a
#'   single patch ID such as `5`, or a vector/range such as `c(1, 3, 8)` or
#'   `1:20`. Defaults to `"all"`.
#' @param states Optional vector of disease states to include. If `NULL`, all
#'   individuals are used.
#' @param facet_by_state Logical. If `TRUE`, facet by disease state as well as
#'   year. Defaults to `FALSE`.
#' @param locus Locus to map for genetic summaries, such as `"L0"` or `0`.
#'   Required when `type` is `"allele_frequency"` or `"heterozygosity"`.
#' @param allele Allele to map for `type = "allele_frequency"`, such as
#'   `"A1"` or `1`.
#' @param metric Heterozygosity metric to map for `type = "heterozygosity"`.
#'   Use `"Ho"` or `"He"`. Defaults to `"Ho"`.
#' @param labels Logical. If `TRUE`, add patch ID labels to the map. Defaults
#'   to `FALSE`.
#' @param log_scale Logical. If `TRUE`, use log1p-transformed abundance for
#'   point sizes when `type = "abundance"`. Defaults to `FALSE`.
#' @param crs Optional coordinate reference system label. For example, use
#'   `5070` or `"EPSG:5070"` for NAD83 / Conus Albers. Coordinates are not
#'   transformed; this is used for labeling and stored as plot data metadata.
#'
#' @return A ggplot object with patch-level summary data in `plot$data`.
#' @examples
#' ex_dir <- system.file("extdata", "Example_dat", package = "cdmetapopR")
#'
#' summary_patch_map(ex_dir, years = c(0, 5, 9), crs = 5070)
#' summary_patch_map(ex_dir, years = c(0, 5, 9), states = 1, crs = 5070)
#' summary_patch_map(ex_dir, years = c(0, 9), states = c(0, 1), facet_by_state = TRUE, crs = 5070)
#' summary_patch_map(ex_dir, type = "allele_frequency", years = 9, locus = "L0", allele = "A1")
#' summary_patch_map(ex_dir, type = "heterozygosity", years = 9, locus = "L0", metric = "Ho")
#' @export
summary_patch_map <- function(path,
                              type = "abundance",
                              years = 0,
                              run = 0,
                              batch = 0,
                              mc = 0,
                              species = 0,
                              file_type = "ind",
                              patches = "all",
                              states = NULL,
                              facet_by_state = FALSE,
                              locus = NULL,
                              allele = NULL,
                              metric = "Ho",
                              labels = FALSE,
                              log_scale = FALSE,
                              crs = NULL) {
  type <- match.arg(type, c("abundance", "allele_frequency", "heterozygosity"))
  file_type <- match.arg(file_type, c("ind", "ind_Sample"))

  data <- .resolve_ind_input(
    path = path,
    run = run,
    batch = batch,
    mc = mc,
    species = species,
    years = years,
    file_type = file_type,
    patches = patches
  )

  .check_ind_columns(data, c("PatchID", "XCOORD", "YCOORD", "Year", "state"))

  if (!is.null(states)) {
    data <- data[data$state %in% states, , drop = FALSE]
  }

  if (nrow(data) == 0) {
    stop("No individuals matched the requested years, run, batch, MC, species, and states.")
  }

  if (identical(type, "allele_frequency")) {
    plot_data <- .patch_map_allele_frequency_data(data, locus = locus, allele = allele)
    legend_label <- "Frequency"
    plot_title <- paste("Allele Frequency", unique(plot_data$Locus), unique(plot_data$Allele))
  } else if (identical(type, "heterozygosity")) {
    plot_data <- .patch_map_heterozygosity_data(data, locus = locus, metric = metric)
    legend_label <- unique(plot_data$Metric)
    plot_title <- paste("Heterozygosity", unique(plot_data$Locus), unique(plot_data$Metric))
  } else if (!facet_by_state) {
    data$.plot_state <- "All selected states"
    plot_data <- .patch_map_abundance_data(data)
    legend_label <- "Individuals"
    plot_title <- "Patch Abundance"
  } else {
    data$.plot_state <- paste("State", data$state)
    plot_data <- .patch_map_abundance_data(data)
    legend_label <- "Individuals"
    plot_title <- "Patch Abundance"
  }

  year_levels <- sort(unique(plot_data$Year))
  plot_data$Year <- factor(plot_data$Year, levels = year_levels)
  plot_data$PatchID <- factor(
    plot_data$PatchID,
    levels = .numeric_label_levels(plot_data$PatchID)
  )

  crs_label <- NULL
  if (!is.null(crs)) {
    crs_label <- if (is.numeric(crs)) paste0("EPSG:", crs) else as.character(crs)
    attr(plot_data, "crs") <- crs_label
  }

  x_lab <- if (is.null(crs_label)) "X coordinate" else paste0("X coordinate (", crs_label, ")")
  y_lab <- if (is.null(crs_label)) "Y coordinate" else paste0("Y coordinate (", crs_label, ")")

  if (identical(type, "abundance")) {
    plot_data$size_value <- if (log_scale) log1p(plot_data$count) else plot_data$count
    size_label <- if (log_scale) "Individuals (log1p)" else legend_label

    p <- ggplot2::ggplot(
      plot_data,
      ggplot2::aes(x = .data$XCOORD, y = .data$YCOORD, size = .data$size_value)
    ) +
      ggplot2::geom_point(alpha = 0.75, color = "steelblue") +
      ggplot2::labs(size = size_label)
  } else {
    p <- ggplot2::ggplot(
      plot_data,
      ggplot2::aes(x = .data$XCOORD, y = .data$YCOORD, fill = .data$value)
    ) +
      ggplot2::geom_point(shape = 21, size = 3.2, color = "black", alpha = 0.85) +
      ggplot2::scale_fill_gradient(low = "white", high = "steelblue", limits = c(0, 1), na.value = "grey90") +
      ggplot2::labs(fill = legend_label)
  }

  p <- p +
    ggplot2::coord_equal() +
    ggplot2::labs(
      title = plot_title,
      x = x_lab,
      y = y_lab
    )

  if (labels) {
    p <- p + ggplot2::geom_text(ggplot2::aes(label = .data$PatchID), vjust = -0.7, size = 3)
  }

  if (identical(type, "abundance") && facet_by_state) {
    p <- p + ggplot2::facet_grid(State ~ Year)
  } else {
    p <- p + ggplot2::facet_wrap(~ Year)
  }

  p + .theme_cdmetapop()
}

.patch_map_abundance_data <- function(data) {
  split_groups <- split(
    data,
    interaction(data$Year, data$.plot_state, data$PatchID, drop = TRUE, lex.order = TRUE)
  )

  do.call(
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
}

.patch_map_locus_cols <- function(data, locus) {
  if (is.null(locus) || length(locus) != 1) {
    stop("Provide exactly one locus for genetic patch maps.")
  }

  locus <- if (grepl("^L", as.character(locus))) as.character(locus) else paste0("L", locus)
  locus_cols <- .detect_locus_allele_columns(data, loci = locus)
  if (length(unique(locus_cols$locus)) != 1) {
    stop("Provide exactly one locus for genetic patch maps.")
  }
  locus_cols
}

.patch_map_allele_frequency_data <- function(data, locus, allele) {
  if (is.null(allele) || length(allele) != 1) {
    stop("Provide exactly one allele for allele-frequency patch maps.")
  }

  locus_cols <- .patch_map_locus_cols(data, locus)
  allele <- if (grepl("^A", as.character(allele))) as.character(allele) else paste0("A", allele)
  allele_row <- locus_cols[locus_cols$allele == allele, , drop = FALSE]
  if (nrow(allele_row) != 1) {
    stop("Requested allele was not found for locus ", unique(locus_cols$locus), ".")
  }

  all_locus_cols <- .locus_groups(locus_cols)[[unique(locus_cols$locus)]]
  split_groups <- split(
    data,
    interaction(data$Year, data$PatchID, drop = TRUE, lex.order = TRUE)
  )

  out <- do.call(
    rbind,
    lapply(split_groups, function(df) {
      locus_total <- rowSums(df[, all_locus_cols, drop = FALSE], na.rm = TRUE)
      allele_count <- sum(as.numeric(df[[allele_row$column]]), na.rm = TRUE)
      total_count <- sum(locus_total, na.rm = TRUE)
      data.frame(
        Year = df$Year[1],
        PatchID = df$PatchID[1],
        XCOORD = mean(as.numeric(df$XCOORD), na.rm = TRUE),
        YCOORD = mean(as.numeric(df$YCOORD), na.rm = TRUE),
        Locus = unique(locus_cols$locus),
        Allele = allele,
        value = if (total_count > 0) allele_count / total_count else NA_real_,
        allele_count = allele_count,
        total_count = total_count,
        stringsAsFactors = FALSE
      )
    })
  )

  out
}

.patch_map_heterozygosity_data <- function(data, locus, metric = "Ho") {
  metric <- match.arg(metric, c("Ho", "He"))
  locus_cols <- .patch_map_locus_cols(data, locus)
  all_locus_cols <- .locus_groups(locus_cols)[[unique(locus_cols$locus)]]
  split_groups <- split(
    data,
    interaction(data$Year, data$PatchID, drop = TRUE, lex.order = TRUE)
  )

  do.call(
    rbind,
    lapply(split_groups, function(df) {
      locus_data <- df[, all_locus_cols, drop = FALSE]
      allele_totals <- colSums(locus_data, na.rm = TRUE)
      total_alleles <- sum(allele_totals)
      freqs <- if (total_alleles > 0) allele_totals / total_alleles else rep(NA_real_, length(allele_totals))
      ho <- mean(rowSums(locus_data > 0, na.rm = TRUE) > 1, na.rm = TRUE)
      he <- 1 - sum(freqs^2, na.rm = TRUE)
      data.frame(
        Year = df$Year[1],
        PatchID = df$PatchID[1],
        XCOORD = mean(as.numeric(df$XCOORD), na.rm = TRUE),
        YCOORD = mean(as.numeric(df$YCOORD), na.rm = TRUE),
        Locus = unique(locus_cols$locus),
        Metric = metric,
        value = if (identical(metric, "Ho")) ho else he,
        n = nrow(df),
        stringsAsFactors = FALSE
      )
    })
  )
}
