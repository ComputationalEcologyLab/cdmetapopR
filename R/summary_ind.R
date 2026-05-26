# --- INTERNAL HELPERS (Not Exported) ---

.ind_file_pattern <- function(file_type = c("ind", "ind_Sample")) {
  file_type <- match.arg(file_type)
  if (identical(file_type, "ind_Sample")) {
    "^indSample([0-9]+)\\.csv$"
  } else {
    "^ind([0-9]+)\\.csv$"
  }
}

.ind_file_label <- function(file_type = c("ind", "ind_Sample")) {
  file_type <- match.arg(file_type)
  if (identical(file_type, "ind_Sample")) "indSample##.csv" else "ind##.csv"
}

.parse_ind_metadata <- function(path, file_type = c("ind", "ind_Sample")) {
  file_type <- match.arg(file_type)
  file_name <- basename(path)
  run_dir <- basename(dirname(path))

  year_match <- regexec(.ind_file_pattern(file_type), file_name)
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
    .file_type = file_type,
    Year = year,
    stringsAsFactors = FALSE
  )
}

.discover_ind_files <- function(paths, run = 0, batch = 0, mc = 0, species = 0, years = NULL, file_type = c("ind", "ind_Sample")) {
  file_type <- match.arg(file_type)
  file_pattern <- .ind_file_pattern(file_type)
  file_label <- .ind_file_label(file_type)

  if (!is.character(paths) || length(paths) < 1) {
    stop("path must be a file path, directory path, or character vector of paths.")
  }

  discovered <- data.frame(path = character(), from_directory = logical(), stringsAsFactors = FALSE)

  for (path in paths) {
    if (dir.exists(path)) {
      files <- list.files(
        path = path,
        pattern = file_pattern,
        recursive = TRUE,
        full.names = TRUE
      )
      if (length(files) > 0) {
        discovered <- rbind(
          discovered,
          data.frame(path = files, from_directory = TRUE, stringsAsFactors = FALSE)
        )
      }
    } else if (file.exists(path)) {
      if (!grepl(file_pattern, basename(path))) {
        stop("Expected a ", file_label, " file: ", path)
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
    stop("No ", file_label, " files were found in the supplied input.")
  }

  metadata <- do.call(rbind, lapply(discovered$path, .parse_ind_metadata, file_type = file_type))
  metadata$.from_directory <- discovered$from_directory

  if (any(metadata$.from_directory)) {
    keep <- !metadata$.from_directory |
      (
        .matches_cdmetapop_filter(metadata$.run, run) &
          .matches_cdmetapop_filter(metadata$.batch, batch) &
          .matches_cdmetapop_filter(metadata$.mc, mc) &
          .matches_cdmetapop_filter(metadata$.species, species)
      )
    metadata <- metadata[keep, , drop = FALSE]
  }

  if (!is.null(years)) {
    metadata <- metadata[!metadata$.from_directory | metadata$Year %in% years, , drop = FALSE]
  }

  metadata <- metadata[order(metadata$.batch, metadata$.mc, metadata$Year), , drop = FALSE]

  if (nrow(metadata) == 0) {
    stop("No ", file_label, " files matched the requested run, batch, MC, species, and year filters.")
  }

  metadata
}

.read_ind_files <- function(file_metadata) {
  loaded <- lapply(seq_len(nrow(file_metadata)), function(i) {
    df <- utils::read.csv(file_metadata$.source_file[i], stringsAsFactors = FALSE)
    meta_cols <- c(".source_file", ".source_group", ".source_id", ".run", ".batch", ".mc", ".species", ".file_type", "Year")

    for (nm in meta_cols) {
      df[[nm]] <- file_metadata[[nm]][i]
    }

    df
  })

  all_cols <- unique(unlist(lapply(loaded, names), use.names = FALSE))
  loaded <- lapply(loaded, function(df) {
    missing_cols <- setdiff(all_cols, names(df))
    for (nm in missing_cols) {
      df[[nm]] <- NA
    }
    df[, all_cols, drop = FALSE]
  })

  do.call(rbind, loaded)
}

.patch_filter_is_all <- function(patches) {
  is.character(patches) && length(patches) == 1 && identical(tolower(patches), "all")
}

.filter_ind_patches <- function(data, patches = "all") {
  if (.patch_filter_is_all(patches)) {
    return(data)
  }

  .check_ind_columns(data, "PatchID")
  patch_values <- as.character(patches)
  existing_patches <- unique(as.character(data$PatchID))
  missing_patches <- setdiff(patch_values, existing_patches)

  if (length(missing_patches) > 0) {
    warning(
      "Patches ",
      paste(missing_patches, collapse = ", "),
      " do not exist; including only patches that exist in the specified range.",
      call. = FALSE
    )
  }

  data <- data[as.character(data$PatchID) %in% patch_values, , drop = FALSE]

  if (nrow(data) == 0) {
    stop("No individuals matched the requested patches.")
  }

  data
}

.resolve_ind_input <- function(path, run = 0, batch = 0, mc = 0, species = 0, years = NULL, file_type = c("ind", "ind_Sample"), patches = "all") {
  file_type <- match.arg(file_type)

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
    path$.file_type <- if (".file_type" %in% names(path)) path$.file_type else file_type
    return(.filter_ind_patches(path, patches = patches))
  }

  file_metadata <- .discover_ind_files(
    paths = path,
    run = run,
    batch = batch,
    mc = mc,
    species = species,
    years = years,
    file_type = file_type
  )

  .filter_ind_patches(.read_ind_files(file_metadata), patches = patches)
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
#' Plots simple summaries from CDMetaPOP `ind##.csv` or
#' `ind##_Sample.csv` files. Inputs can be a data frame, one individual file,
#' multiple individual files, a single run folder, or a top-level CDMetaPOP
#' output directory containing run folders.
#'
#' @param path A dataframe, file path, vector of file paths, run directory, or
#'   top-level output directory containing individual files.
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
#' @param file_type Character. Which individual file type to read. Use
#'   `"ind"` for `ind##.csv` files or `"ind_Sample"` for `ind##_Sample.csv`
#'   files. Defaults to `"ind"`.
#' @param patches Patch IDs to include. Use `"all"` to include all patches, a
#'   single patch ID such as `5`, or a vector/range such as `c(1, 3, 8)` or
#'   `1:20`. Defaults to `"all"`.
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
                        file_type = "ind",
                        patches = "all",
                        bins = 30) {
  file_type <- match.arg(file_type, c("ind", "ind_Sample"))
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
    years = years_to_read,
    file_type = file_type,
    patches = patches
  )

  if (type %in% one_year_types && length(unique(stats::na.omit(data$Year))) > 1) {
    stop("One-year plot types require a single year. Supply one year or one individual file.")
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
    ggplot2::geom_point(size = 2) +
    ggplot2::facet_wrap(~ .batch, labeller = ggplot2::label_both) +
    ggplot2::labs(
      title = "Individual Movement Over Time",
      x = "Year",
      y = "Proportion Moved",
      color = "Monte Carlo"
    )
}
