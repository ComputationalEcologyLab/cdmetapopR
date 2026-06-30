#' Return CDMetaPOP Output Data as Data Frames
#'
#' Reads CDMetaPOP population, class, disease-state, or individual output files
#' and returns data frames for custom plotting or downstream summaries.
#'
#' @param data A data frame, file path, vector of file paths, run directory, or
#'   top-level CDMetaPOP output directory.
#' @param type Character. Which file type to read: `"pop"` for
#'   `summary_popAllTime.csv`, `"class"` for `summary_classAllTime.csv`,
#'   `"disease"` for `summary_popAllTime_DiseaseStates.csv`, or `"ind"` for
#'   `ind##.csv` / `ind##_Sample.csv` files.
#' @param run Integer run index used when `data` is a directory. Defaults to
#'   `0`. Use `"all"` to include all runs.
#' @param batch Integer batch index used when `data` is a directory. Defaults
#'   to `0`. Use `"all"` to include all batches.
#' @param mc Integer Monte Carlo index used when `data` is a directory.
#'   Defaults to `0`. Use `"all"` to include all Monte Carlo replicates.
#' @param species Integer species index used when `data` is a directory.
#'   Defaults to `0`. Use `"all"` to include all species.
#' @param years Optional integer vector of years/generations to include for
#'   `type = "ind"`.
#' @param file_type Character. Which individual file type to read for
#'   `type = "ind"`. Use `"ind"` for `ind##.csv` files or `"ind_Sample"` for
#'   `ind##_Sample.csv` files. Defaults to `"ind"`.
#' @param patches Patch IDs to include for `type = "ind"`. Use `"all"` to
#'   include all patches, a single patch ID, or a vector/range of patch IDs.
#'   Defaults to `"all"`.
#' @param state_names Character vector used to name disease states for
#'   `type = "disease"`. If `NULL`, states are named numerically.
#' @param cumulative_states Character vector of disease state names to
#'   calculate as running totals for `type = "disease"`.
#' @param state_column Character. Disease-state column to parse for
#'   `type = "disease"`. Defaults to `"States_SecondUpdate"`.
#' @param disease_format Character. Use `"long"` to return one row per
#'   year/source/state, or `"wide"` to return one column per state. Defaults to
#'   `"long"`.
#' @param summary_format Character. Use `"long"` to split pipe-delimited
#'   `summary_popAllTime.csv` and `summary_classAllTime.csv` columns into one
#'   row per patch or class while keeping metrics in separate columns. Use
#'   `"wide"` to return the raw summary columns with metadata. Defaults to
#'   `"long"`.
#'
#' @return A data frame with source metadata columns. For `type = "pop"` and
#'   `type = "class"`, the default long format includes `PatchID` or `ClassID`
#'   indexing values split from pipe-delimited metric columns. For
#'   `type = "disease"`, the default long format includes `State` and `Count`
#'   columns.
#' @examples
#' ex_dir <- system.file("extdata", "Example_dat", package = "cdmetapopR")
#'
#' pop_df <- summary_dataframe(ex_dir, type = "pop")
#' class_df <- summary_dataframe(ex_dir, type = "class")
#' disease_df <- summary_dataframe(ex_dir, type = "disease")
#' ind_df <- summary_dataframe(ex_dir, type = "ind", years = 9)
#'
#' all_mc_pop_df <- summary_dataframe(ex_dir, type = "pop", mc = "all")
#' @export
summary_dataframe <- function(data,
                              type = c("pop", "class", "disease", "ind"),
                              run = 0,
                              batch = 0,
                              mc = 0,
                              species = 0,
                              years = NULL,
                              file_type = "ind",
                              patches = "all",
                              state_names = NULL,
                              cumulative_states = NULL,
                              state_column = "States_SecondUpdate",
                              disease_format = c("long", "wide"),
                              summary_format = c("long", "wide")) {
  type <- match.arg(type)
  disease_format <- match.arg(disease_format)
  summary_format <- match.arg(summary_format)

  if (identical(type, "ind")) {
    return(.resolve_ind_input(
      path = data,
      run = run,
      batch = batch,
      mc = mc,
      species = species,
      years = years,
      file_type = file_type,
      patches = patches
    ))
  }

  if (identical(type, "disease")) {
    return(.resolve_disease_state_input(
      base_path = data,
      run = run,
      batch = batch,
      mc = mc,
      species = species,
      state_names = state_names,
      cumulative_states = cumulative_states,
      state_column = state_column,
      long = identical(disease_format, "long")
    ))
  }

  summary_data <- .resolve_cdmetapop_input(
    x = data,
    summary_type = type,
    run = run,
    batch = batch,
    mc = mc,
    species = species
  )

  if (identical(summary_format, "wide")) {
    return(summary_data)
  }

  .long_summary_dataframe(summary_data, summary_type = type)
}

.has_pipe_values <- function(x) {
  any(grepl("\\|", as.character(x), fixed = FALSE), na.rm = TRUE)
}

.split_pipe_values <- function(x) {
  vals <- strsplit(as.character(x), "|", fixed = TRUE)[[1]]
  vals <- vals[nzchar(vals)]
  suppressWarnings(as.numeric(vals))
}

.long_summary_dataframe <- function(data, summary_type) {
  metadata_cols <- c(".source_file", ".source_group", ".source_id", ".run", ".batch", ".mc", ".species")
  id_cols <- intersect(c("Year", metadata_cols), names(data))
  pipe_cols <- names(data)[vapply(data, .has_pipe_values, logical(1))]

  if (length(pipe_cols) == 0) {
    return(data)
  }

  scalar_cols <- setdiff(names(data), c(id_cols, pipe_cols))

  rows <- lapply(seq_len(nrow(data)), function(i) {
    split_values <- lapply(pipe_cols, function(metric) .split_pipe_values(data[[metric]][i]))
    names(split_values) <- pipe_cols
    max_len <- max(lengths(split_values))

    index_name <- if (identical(summary_type, "pop")) "PatchID" else "ClassID"
    index_values <- if (identical(summary_type, "pop")) seq_len(max_len) - 1L else seq_len(max_len)
    split_df <- data.frame(index_values, stringsAsFactors = FALSE)
    names(split_df) <- index_name
    for (metric in pipe_cols) {
      values <- split_values[[metric]]
      length(values) <- max_len
      split_df[[metric]] <- values
    }

    cbind(
      data[i, c(id_cols, scalar_cols), drop = FALSE][rep(1, max_len), , drop = FALSE],
      split_df
    )
  })

  out <- do.call(rbind, rows)
  row.names(out) <- NULL

  front_cols <- c(intersect("Year", names(out)), intersect(metadata_cols, names(out)))
  index_cols <- intersect(c("PatchID", "ClassID"), names(out))
  out[, c(front_cols, index_cols, setdiff(names(out), c(front_cols, index_cols))), drop = FALSE]
}
