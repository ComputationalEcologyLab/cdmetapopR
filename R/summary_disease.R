# --- INTERNAL HELPERS (Not Exported) ---

.discover_disease_state_files <- function(base_path) {
  if (!is.character(base_path) || length(base_path) < 1) {
    stop("base_path must be a file path, directory path, or character vector of paths.")
  }

  files <- character()

  for (path in base_path) {
    if (dir.exists(path)) {
      files <- c(
        files,
        list.files(
          path = path,
          pattern = "^summary_popAllTime_DiseaseStates\\.csv$",
          recursive = TRUE,
          full.names = TRUE
        )
      )
    } else if (file.exists(path)) {
      if (!identical(basename(path), "summary_popAllTime_DiseaseStates.csv")) {
        stop("Expected a summary_popAllTime_DiseaseStates.csv file: ", path)
      }
      files <- c(files, path)
    } else {
      stop("Path does not exist: ", path)
    }

  }

  if (length(files) == 0) {
    stop("No summary_popAllTime_DiseaseStates.csv files found in the supplied input.")
  }

  unique(files)
}

.parse_disease_state_metadata <- function(path) {
  run_dir <- basename(dirname(path))
  pattern <- "^run([0-9]+)batch([0-9]+)mc([0-9]+)species([0-9]+)$"
  pieces <- regmatches(run_dir, regexec(pattern, run_dir))[[1]]

  if (length(pieces) != 5) {
    stop("Could not parse run/batch/MC/species metadata from folder: ", run_dir)
  }

  data.frame(
    Run = as.integer(pieces[2]),
    Batch = as.integer(pieces[3]),
    MC = as.integer(pieces[4]),
    Species = as.integer(pieces[5]),
    Source = basename(dirname(dirname(path))),
    .source_file = normalizePath(path, winslash = "/", mustWork = FALSE),
    .source_group = basename(dirname(dirname(path))),
    .source_id = paste(run_dir, basename(path), sep = "_"),
    .run = as.integer(pieces[2]),
    .batch = as.integer(pieces[3]),
    .mc = as.integer(pieces[4]),
    .species = as.integer(pieces[5]),
    stringsAsFactors = FALSE
  )
}

.disease_state_totals <- function(x) {
  first_patch <- sub("\\|.*", "", as.character(x))
  pieces <- strsplit(first_patch, ";", fixed = TRUE)
  max_len <- max(lengths(pieces))

  out <- do.call(
    rbind,
    lapply(pieces, function(vals) {
      vals <- as.numeric(vals)
      length(vals) <- max_len
      vals
    })
  )

  as.data.frame(out, stringsAsFactors = FALSE)
}

.detect_disease_state_count <- function(path, state_column) {
  sample_df <- utils::read.csv(path, nrows = 1, stringsAsFactors = FALSE)

  if (!state_column %in% names(sample_df)) {
    stop("Column not found in disease summary file: ", state_column)
  }

  ncol(.disease_state_totals(sample_df[[state_column]][1]))
}

.resolve_disease_state_input <- function(base_path,
                                         run = 0,
                                         batch = 0,
                                         mc = 0,
                                         species = 0,
                                         state_names = NULL,
                                         cumulative_states = NULL,
                                         state_column = "States_SecondUpdate",
                                         long = TRUE) {
  disease_files <- .discover_disease_state_files(base_path)
  metadata <- do.call(rbind, lapply(disease_files, .parse_disease_state_metadata))

  keep <- .matches_cdmetapop_filter(metadata$.run, run) &
    .matches_cdmetapop_filter(metadata$.batch, batch) &
    .matches_cdmetapop_filter(metadata$.mc, mc) &
    .matches_cdmetapop_filter(metadata$.species, species)
  disease_files <- disease_files[keep]
  metadata <- metadata[keep, , drop = FALSE]

  if (length(disease_files) == 0) {
    stop("No summary_popAllTime_DiseaseStates.csv files matched the requested run, batch, MC, and species filters.")
  }

  detected_count <- .detect_disease_state_count(disease_files[1], state_column)

  if (is.null(state_names)) {
    state_names <- as.character(seq_len(detected_count))
  }

  if (length(state_names) != detected_count) {
    stop("Length of state_names does not match detected states (", detected_count, ").")
  }

  if (!is.null(cumulative_states) && !all(cumulative_states %in% state_names)) {
    stop("cumulative_states must be names from state_names.")
  }

  wide_data <- do.call(
    rbind,
    lapply(seq_along(disease_files), function(i) {
      path <- disease_files[i]
      df <- utils::read.csv(path, stringsAsFactors = FALSE)

      if (!state_column %in% names(df)) {
        stop("Column not found in disease summary file: ", state_column)
      }

      state_df <- .disease_state_totals(df[[state_column]])
      if (ncol(state_df) != length(state_names)) {
        stop("State count in ", path, " does not match state_names.")
      }

      names(state_df) <- state_names
      out <- cbind(
        data.frame(
          Year = as.numeric(df$Year),
          Run = metadata$Run[i],
          Batch = metadata$Batch[i],
          MC = metadata$MC[i],
          Species = metadata$Species[i],
          Source = metadata$Source[i],
          .source_file = metadata$.source_file[i],
          .source_group = metadata$.source_group[i],
          .source_id = metadata$.source_id[i],
          .run = metadata$.run[i],
          .batch = metadata$.batch[i],
          .mc = metadata$.mc[i],
          .species = metadata$.species[i],
          stringsAsFactors = FALSE
        ),
        state_df
      )

      if (!is.null(cumulative_states)) {
        for (state in cumulative_states) {
          out[[state]] <- cumsum(out[[state]])
        }
      }

      out
    })
  )

  if (!long) {
    return(wide_data)
  }

  long_data <- tidyr::pivot_longer(
    wide_data,
    cols = dplyr::all_of(state_names),
    names_to = "State",
    values_to = "Count"
  )
  long_data$Count <- as.numeric(long_data$Count)
  long_data$State <- factor(long_data$State, levels = state_names)
  long_data
}

# --- EXPORTED FUNCTIONS ---

#' Summarize CDMetaPOP Disease States
#'
#' Scans CDMetaPOP output directories, pulls state totals from
#' `summary_popAllTime_DiseaseStates.csv` files, and returns a faceted ggplot
#' comparing disease states across batches.
#'
#' @param base_path Character. Path to a CDMetaPOP output directory containing
#'   `run#batch#mc#species#` folders, or a parent directory containing those
#'   folders.
#' @param state_names Character vector. Optional labels for disease states. If
#'   `NULL`, states are named numerically (`"1"`, `"2"`, `"3"`, ...).
#' @param scenario_names Character vector. Optional labels for batches. The
#'   first value labels batch 0, the second labels batch 1, and so on.
#' @param cumulative_states Character vector. Names of states to calculate as
#'   running totals within each Monte Carlo replicate.
#' @param state_column Character. Disease-state column to summarize. Defaults
#'   to `"States_SecondUpdate"`.
#'
#' @return A ggplot object.
#' @examples
#' ex_dir <- system.file(
#'   "extdata",
#'   "Adaptive_Run_08",
#'   package = "cdmetapopR"
#' )
#'
#' summarize_states(ex_dir)
#'
#' summarize_states(
#'   ex_dir,
#'   state_names = c("Susceptible", "Infected", "Recovered"),
#'   scenario_names = c("Batch 0", "Batch 1"),
#'   cumulative_states = "Recovered"
#' )
#' @export
summarize_states <- function(base_path,
                             state_names = NULL,
                             scenario_names = NULL,
                             cumulative_states = NULL,
                             state_column = "States_SecondUpdate") {
  disease_files <- .discover_disease_state_files(base_path)
  detected_count <- .detect_disease_state_count(disease_files[1], state_column)

  if (is.null(state_names)) {
    state_names <- as.character(seq_len(detected_count))
    message("No state_names provided. Using: ", paste(state_names, collapse = ", "))
  }

  if (length(state_names) != detected_count) {
    stop("Length of state_names does not match detected states (", detected_count, ").")
  }

  if (!is.null(cumulative_states) && !all(cumulative_states %in% state_names)) {
    stop("cumulative_states must be names from state_names.")
  }

  long_data <- .resolve_disease_state_input(
    base_path,
    run = "all",
    batch = "all",
    mc = "all",
    species = "all",
    state_names = state_names,
    cumulative_states = cumulative_states,
    state_column = state_column,
    long = TRUE
  )

  summary_df <- dplyr::summarise(
    dplyr::group_by(long_data, .data$Batch, .data$Year, .data$State),
    mean_val = mean(.data$Count, na.rm = TRUE),
    sd_val = stats::sd(.data$Count, na.rm = TRUE),
    n = dplyr::n(),
    .groups = "drop"
  )

  summary_df$sd_val[is.na(summary_df$sd_val)] <- 0

  if (!is.null(scenario_names)) {
    batch_levels <- sort(unique(summary_df$Batch))
    if (length(scenario_names) < max(batch_levels) + 1) {
      stop("scenario_names must include labels through the highest detected batch index.")
    }

    summary_df$Scenario <- factor(
      scenario_names[summary_df$Batch + 1],
      levels = scenario_names[batch_levels + 1]
    )
  } else {
    summary_df$Scenario <- factor(paste("Batch", summary_df$Batch))
  }

  ggplot2::ggplot(
    summary_df,
    ggplot2::aes(
      x = .data$Year,
      y = .data$mean_val,
      color = .data$Scenario,
      fill = .data$Scenario
    )
  ) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_ribbon(
      ggplot2::aes(
        ymin = .data$mean_val - .data$sd_val,
        ymax = .data$mean_val + .data$sd_val
      ),
      alpha = 0.15,
      color = NA
    ) +
    ggplot2::facet_wrap(~ State, scales = "free_y", ncol = 2) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      panel.border = ggplot2::element_rect(color = "black", fill = NA, linewidth = 0.5),
      legend.position = "bottom",
      strip.background = ggplot2::element_rect(fill = "gray95", color = NA)
    ) +
    ggplot2::labs(
      y = "Count",
      x = "Year",
      title = "Disease State Summary",
      subtitle = paste("Averaged across", length(unique(long_data$MC)), "replications")
    )
}
