# --- INTERNAL HELPERS (Not Exported) ---

.parse_ind_metadata <- function(path) {
  file_name <- basename(path)
  run_dir <- basename(dirname(path))

  year_match <- regexec("^ind([0-9]+)\\.csv$", file_name)
  year_pieces <- regmatches(file_name, year_match)[[1]]
  year <- if (length(year_pieces) == 2) as.integer(year_pieces[2]) else NA_integer_

  run_match <- regexec("^run([0-9]+)batch([0-9]+)mc([0-9]+)species([0-9]+)$", run_dir)
  run_pieces <- regmatches(run_dir, run_match)[[1]]

  if (length(run_pieces) == 5) {
    run <- as.integer(run_pieces[2])
    batch <- as.integer(run_pieces[3])
    mc <- as.integer(run_pieces[4])
    species <- as.integer(run_pieces[5])
  } else {
    run <- NA_integer_
    batch <- NA_integer_
    mc <- NA_integer_
    species <- NA_integer_
  }

  data.frame(
    .source_file = normalizePath(path, winslash = "/", mustWork = FALSE),
    .source_group = basename(dirname(dirname(path))),
    .source_id = paste(run_dir, file_name, sep = "_"),
    .run = run,
    .batch = batch,
    .mc = mc,
    .species = species,
    Year = year,
    stringsAsFactors = FALSE
  )
}

.discover_ind_files <- function(paths, run = 0, batch = 0, mc = 0, species = 0, years = NULL) {
  if (!is.character(paths) || length(paths) < 1) {
    stop("path must be a file path, directory path, or character vector of paths.")
  }

  discovered <- data.frame(path = character(), from_directory = logical(), stringsAsFactors = FALSE)

  for (path in paths) {
    if (dir.exists(path)) {
      files <- list.files(
        path = path,
        pattern = "^ind[0-9]+\\.csv$",
        recursive = TRUE,
        full.names = TRUE
      )
      discovered <- rbind(
        discovered,
        data.frame(path = files, from_directory = TRUE, stringsAsFactors = FALSE)
      )
    } else if (file.exists(path)) {
      if (!grepl("^ind[0-9]+\\.csv$", basename(path))) {
        stop("Expected an ind##.csv file: ", path)
      }
      discovered <- rbind(
        discovered,
        data.frame(path = path, from_directory = FALSE, stringsAsFactors = FALSE)
      )
    } else {
      stop("Path does not exist: ", path)
    }
  }

  if (nrow(discovered) == 0) {
    stop("No ind##.csv files were found in the supplied input.")
  }

  metadata <- do.call(rbind, lapply(discovered$path, .parse_ind_metadata))
  metadata$.from_directory <- discovered$from_directory

  if (any(metadata$.from_directory)) {
    keep <- !metadata$.from_directory |
      ((is.na(metadata$.run) | metadata$.run == run) &
        (is.na(metadata$.batch) | metadata$.batch == batch) &
        (is.na(metadata$.mc) | metadata$.mc == mc) &
        (is.na(metadata$.species) | metadata$.species == species))
    metadata <- metadata[keep, , drop = FALSE]
  }

  if (!is.null(years)) {
    metadata <- metadata[!metadata$.from_directory | metadata$Year %in% years, , drop = FALSE]
  }

  metadata <- metadata[order(metadata$.batch, metadata$.mc, metadata$Year), , drop = FALSE]

  if (nrow(metadata) == 0) {
    stop("No ind##.csv files matched the requested run, batch, MC, species, and year filters.")
  }

  metadata
}

.read_ind_files <- function(file_metadata) {
  loaded <- lapply(seq_len(nrow(file_metadata)), function(i) {
    df <- utils::read.csv(file_metadata$.source_file[i], stringsAsFactors = FALSE)
    meta_cols <- c(".source_file", ".source_group", ".source_id", ".run", ".batch", ".mc", ".species", "Year")

    for (nm in meta_cols) {
      df[[nm]] <- file_metadata[[nm]][i]
    }

    df
  })

  do.call(rbind, loaded)
}

.resolve_ind_input <- function(path, run = 0, batch = 0, mc = 0, species = 0, years = NULL) {
  if (is.data.frame(path)) {
    if (!"Year" %in% names(path)) {
      path$Year <- NA_integer_
    }
    path$.source_group <- if (".source_group" %in% names(path)) path$.source_group else "input"
    path$.source_id <- if (".source_id" %in% names(path)) path$.source_id else "input_1"
    path$.run <- if (".run" %in% names(path)) path$.run else NA_integer_
    path$.batch <- if (".batch" %in% names(path)) path$.batch else NA_integer_
    path$.mc <- if (".mc" %in% names(path)) path$.mc else NA_integer_
    path$.species <- if (".species" %in% names(path)) path$.species else NA_integer_
    return(path)
  }

  file_metadata <- .discover_ind_files(
    paths = path,
    run = run,
    batch = batch,
    mc = mc,
    species = species,
    years = years
  )

  .read_ind_files(file_metadata)
}

.check_ind_columns <- function(data, cols) {
  missing_cols <- setdiff(cols, names(data))
  if (length(missing_cols) > 0) {
    stop("Missing required ind file column(s): ", paste(missing_cols, collapse = ", "))
  }
}

# --- EXPORTED FUNCTIONS ---

#' Plot CDMetaPOP Individual File Summaries
#'
#' Plots simple summaries from CDMetaPOP `ind##.csv` files. Inputs can be a
#' data frame, one `ind##.csv` file, multiple `ind##.csv` files, a single run
#' folder, or a top-level CDMetaPOP output directory containing run folders.
#'
#' @param path A dataframe, file path, vector of file paths, run directory, or
#'   top-level output directory containing `ind##.csv` files.
#' @param type String specifying the plot type: `"cdist"`, `"hindex"`,
#'   `"age"`, `"size"`, `"age_size"`, or `"movement"`.
#' @param year Integer. Year/generation to plot for one-year plots. Defaults to
#'   `0`.
#' @param years Integer vector. Years/generations to include for movement
#'   plots. If `NULL`, all discovered years are used for `"movement"`.
#' @param run Integer. Run index used when `path` is a directory. Defaults to
#'   `0`.
#' @param batch Integer. Batch index used when `path` is a directory. Defaults
#'   to `0`.
#' @param mc Integer. Monte Carlo index used when `path` is a directory.
#'   Defaults to `0`.
#' @param species Integer. Species index used when `path` is a directory.
#'   Defaults to `0`.
#' @param bins Integer. Number of bins for continuous histograms. Defaults to
#'   `30`.
#'
#' @return A ggplot object.
#' @examples
#' ex_dir <- system.file("extdata", "Adaptive_Run_08", package = "cdmetapopR")
#'
#' summary_ind(ex_dir, type = "age", year = 9)
#' summary_ind(ex_dir, type = "age_size", year = 9)
#' summary_ind(ex_dir, type = "movement", years = 0:9, batch = 1, mc = 1)
#' @export
summary_ind <- function(path,
                        type = "age",
                        year = 0,
                        years = NULL,
                        run = 0,
                        batch = 0,
                        mc = 0,
                        species = 0,
                        bins = 30) {
  type <- strsplit(tolower(type), " ")[[1]][1]

  one_year_types <- c("cdist", "hindex", "age", "size", "age_size")
  if (type %in% one_year_types) {
    years_to_read <- year
  } else if (identical(type, "movement")) {
    years_to_read <- years
  } else {
    stop("Invalid type for summary_ind. Choose: 'cdist', 'hindex', 'age', 'size', 'age_size', or 'movement'.")
  }

  data <- .resolve_ind_input(
    path = path,
    run = run,
    batch = batch,
    mc = mc,
    species = species,
    years = years_to_read
  )

  if (type %in% one_year_types && length(unique(stats::na.omit(data$Year))) > 1) {
    stop("One-year plot types require a single year. Supply one year or one ind##.csv file.")
  }

  p <- switch(
    type,
    "cdist" = helper_plot_ind_cdist(data, bins = bins),
    "hindex" = helper_plot_ind_hindex(data, bins = bins),
    "age" = helper_plot_ind_age(data),
    "size" = helper_plot_ind_size(data, bins = bins),
    "age_size" = helper_plot_ind_age_size(data),
    "movement" = helper_plot_ind_movement(data)
  )

  p + .theme_cdmetapop()
}

helper_plot_ind_cdist <- function(data, bins = 30) {
  .check_ind_columns(data, "CDist")
  plot_data <- data[!is.na(data$CDist) & as.numeric(data$CDist) != -9999, , drop = FALSE]

  if (nrow(plot_data) == 0) {
    plot_data <- data.frame(CDist = numeric())
  }

  ggplot2::ggplot(plot_data, ggplot2::aes(x = as.numeric(.data$CDist))) +
    ggplot2::geom_histogram(bins = bins, fill = "steelblue", color = "white") +
    ggplot2::labs(title = "Individual Movement Distance", x = "CDist", y = "Count")
}

helper_plot_ind_hindex <- function(data, bins = 30) {
  .check_ind_columns(data, "Hindex")

  ggplot2::ggplot(data, ggplot2::aes(x = as.numeric(.data$Hindex))) +
    ggplot2::geom_histogram(bins = bins, fill = "darkgreen", color = "white") +
    ggplot2::labs(title = "Individual Hindex Distribution", x = "Hindex", y = "Count")
}

helper_plot_ind_age <- function(data) {
  .check_ind_columns(data, "age")

  ggplot2::ggplot(data, ggplot2::aes(x = factor(.data$age))) +
    ggplot2::geom_bar(fill = "steelblue") +
    ggplot2::labs(title = "Individual Age Distribution", x = "Age", y = "Count")
}

helper_plot_ind_size <- function(data, bins = 30) {
  .check_ind_columns(data, "size")

  ggplot2::ggplot(data, ggplot2::aes(x = as.numeric(.data$size))) +
    ggplot2::geom_histogram(bins = bins, fill = "steelblue", color = "white") +
    ggplot2::labs(title = "Individual Size Distribution", x = "Size", y = "Count")
}

helper_plot_ind_age_size <- function(data) {
  .check_ind_columns(data, c("age", "size"))

  ggplot2::ggplot(data, ggplot2::aes(x = as.numeric(.data$age), y = as.numeric(.data$size))) +
    ggplot2::geom_point(alpha = 0.35, color = "steelblue") +
    ggplot2::geom_smooth(method = "loess", se = FALSE, color = "black", linewidth = 0.8) +
    ggplot2::labs(title = "Individual Size by Age", x = "Age", y = "Size")
}

helper_plot_ind_movement <- function(data) {
  .check_ind_columns(data, c("Year", "CDist"))

  split_groups <- split(
    data,
    interaction(data$.source_group, data$.batch, data$.mc, data$Year, drop = TRUE, lex.order = TRUE)
  )

  movement_data <- do.call(
    rbind,
    lapply(split_groups, function(df) {
      moved <- !is.na(df$CDist) & as.numeric(df$CDist) != -9999
      data.frame(
        .source_group = df$.source_group[1],
        .batch = df$.batch[1],
        .mc = df$.mc[1],
        Year = df$Year[1],
        moved = sum(moved),
        total = nrow(df),
        prop_moved = sum(moved) / nrow(df),
        stringsAsFactors = FALSE
      )
    })
  )

  ggplot2::ggplot(
    movement_data,
    ggplot2::aes(
      x = .data$Year,
      y = .data$prop_moved,
      group = interaction(.data$.batch, .data$.mc),
      color = factor(.data$.mc)
    )
  ) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_point(size = 2) +
    ggplot2::facet_wrap(~ .batch, labeller = ggplot2::label_both) +
    ggplot2::labs(
      title = "Individual Movement Over Time",
      x = "Year",
      y = "Proportion Moved",
      color = "Monte Carlo"
    )
}
