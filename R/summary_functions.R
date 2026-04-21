# --- INTERNAL HELPERS (Not Exported) ---

.summary_filename <- function(summary_type) {
  if (identical(summary_type, "class")) {
    return("summary_classAllTime.csv")
  }

  "summary_popAllTime.csv"
}

.parse_cdmetapop_metadata <- function(path) {
  run_dir <- basename(dirname(path))
  source_group <- basename(dirname(dirname(path)))

  match <- regexec("^run([0-9]+)batch([0-9]+)mc([0-9]+)species([0-9]+)$", run_dir)
  pieces <- regmatches(run_dir, match)[[1]]

  if (length(pieces) == 5) {
    run <- as.integer(pieces[2])
    batch <- as.integer(pieces[3])
    mc <- as.integer(pieces[4])
    species <- as.integer(pieces[5])
  } else {
    run <- NA_integer_
    batch <- NA_integer_
    mc <- NA_integer_
    species <- NA_integer_
  }

  source_id <- paste(
    source_group,
    paste0("run", run),
    paste0("batch", batch),
    paste0("mc", mc),
    paste0("species", species),
    sep = "_"
  )

  data.frame(
    .source_file = normalizePath(path, winslash = "/", mustWork = FALSE),
    .source_group = source_group,
    .source_id = source_id,
    .run = run,
    .batch = batch,
    .mc = mc,
    .species = species,
    stringsAsFactors = FALSE
  )
}

.attach_cdmetapop_metadata <- function(data, path = NULL) {
  if (!is.data.frame(data)) {
    stop("Expected a data frame after reading input data.")
  }

  metadata_cols <- c(".source_file", ".source_group", ".source_id", ".run", ".batch", ".mc", ".species")
  missing_metadata <- setdiff(metadata_cols, names(data))

  if (length(missing_metadata) == 0) {
    return(data)
  }

  if (is.null(path)) {
    data$.source_file <- NA_character_
    data$.source_group <- "input"
    data$.source_id <- "input_1"
    data$.run <- NA_integer_
    data$.batch <- NA_integer_
    data$.mc <- NA_integer_
    data$.species <- NA_integer_
    return(data)
  }

  metadata <- .parse_cdmetapop_metadata(path)

  for (nm in names(metadata)) {
    data[[nm]] <- metadata[[nm]][1]
  }

  data
}

.discover_cdmetapop_files <- function(paths, summary_type) {
  target_name <- .summary_filename(summary_type)
  discovered <- character()

  for (path in paths) {
    if (dir.exists(path)) {
      found <- list.files(
        path = path,
        pattern = paste0("^", target_name, "$"),
        recursive = TRUE,
        full.names = TRUE
      )
      discovered <- c(discovered, found)
    } else if (file.exists(path)) {
      discovered <- c(discovered, path)
    } else {
      stop("Path does not exist: ", path)
    }
  }

  discovered <- unique(discovered[file.exists(discovered)])

  if (length(discovered) == 0) {
    stop("No ", target_name, " files were found in the supplied input.")
  }

  discovered
}

.load_cdmetapop_source <- function(path) {
  ext <- tolower(tools::file_ext(path))

  if (ext == "rds") {
    return(.attach_cdmetapop_metadata(readRDS(path), path))
  }

  if (ext %in% c("rda", "rdata")) {
    e <- new.env(parent = emptyenv())
    nm <- load(path, envir = e)
    return(.attach_cdmetapop_metadata(e[[nm]], path))
  }

  if (ext == "csv") {
    return(.attach_cdmetapop_metadata(utils::read.csv(path, stringsAsFactors = FALSE), path))
  }

  stop("Unsupported file type: .", ext)
}

.resolve_cdmetapop_input <- function(x, summary_type = c("pop", "class")) {
  summary_type <- match.arg(summary_type)

  if (is.data.frame(x)) {
    return(.attach_cdmetapop_metadata(x))
  }

  if (!is.character(x) || length(x) < 1) {
    stop("Input must be a data frame, a file path, a directory, or a character vector of paths.")
  }

  file_paths <- .discover_cdmetapop_files(x, summary_type)
  loaded <- lapply(file_paths, .load_cdmetapop_source)

  if (length(loaded) == 1) {
    return(loaded[[1]])
  }

  do.call(rbind, loaded)
}

.theme_cdmetapop <- function() {
  theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
      panel.grid.minor = element_blank(),
      strip.background = element_rect(fill = "grey90", color = NA),
      strip.text = element_text(face = "bold")
    )
}

.facet_labeler_cdmetapop <- function(batch_labels = NULL) {
  if (is.null(batch_labels)) {
    return(ggplot2::label_value)
  }

  force(batch_labels)

  function(values) {
    out <- unname(batch_labels[values])
    out[is.na(out)] <- values[is.na(out)]
    out
  }
}

.plot_has_multiple_sources <- function(data) {
  ".source_id" %in% names(data) && length(unique(stats::na.omit(data$.source_id))) > 1
}

.summarize_ci_cdmetapop <- function(data, value_col, group_cols) {
  split_index <- split(
    seq_len(nrow(data)),
    interaction(data[group_cols], drop = TRUE, lex.order = TRUE)
  )

  summary_rows <- lapply(split_index, function(idx) {
    vals <- as.numeric(data[[value_col]][idx])
    vals <- vals[!is.na(vals)]
    key <- data[idx[1], group_cols, drop = FALSE]

    n_vals <- length(vals)
    mean_val <- if (n_vals > 0) mean(vals) else NA_real_
    sd_val <- if (n_vals > 1) stats::sd(vals) else 0
    ci_half_width <- if (n_vals > 1) {
      stats::qt(0.975, df = n_vals - 1) * (sd_val / sqrt(n_vals))
    } else {
      0
    }

    cbind(
      key,
      mean = mean_val,
      lower = mean_val - ci_half_width,
      upper = mean_val + ci_half_width,
      n = n_vals
    )
  })

  do.call(rbind, summary_rows)
}

.plot_line_by_source <- function(
  data,
  y,
  title,
  ylab,
  color = "steelblue",
  batch_labels = NULL,
  show_mc = TRUE,
  show_ci = TRUE
) {
  if (.plot_has_multiple_sources(data)) {
    summary_df <- .summarize_ci_cdmetapop(
      data = data,
      value_col = y,
      group_cols = c(".source_group", "Year")
    )

    p <- ggplot(
      data,
      aes(
        x = .data$Year,
        y = .data[[y]],
        group = .data$.source_id,
        color = factor(.data$.mc)
      )
    )

    if (show_ci) {
      p <- p +
        geom_ribbon(
          data = summary_df,
          aes(
            x = .data$Year,
            ymin = .data$lower,
            ymax = .data$upper,
            group = .data$.source_group
          ),
          inherit.aes = FALSE,
          fill = color,
          alpha = 0.18
        ) +
        geom_line(
          data = summary_df,
          aes(x = .data$Year, y = .data$mean, group = .data$.source_group),
          inherit.aes = FALSE,
          color = color,
          linewidth = 1
        )
    }

    if (show_mc) {
      p <- p + geom_line(alpha = 0.35, linewidth = 0.6)
    }

    p <- p +
      facet_wrap(
        ~ .source_group,
        scales = "free_y",
        labeller = ggplot2::labeller(.source_group = .facet_labeler_cdmetapop(batch_labels))
      ) +
      labs(color = "Monte Carlo")
  } else {
    p <- ggplot(data, aes(x = .data$Year, y = .data[[y]])) +
      geom_line(color = color, linewidth = 0.8)
  }

  p + labs(title = title, y = ylab, x = "Year")
}

.extract_pipe_table <- function(x) {
  out <- utils::read.table(
    text = x,
    sep = "|",
    stringsAsFactors = FALSE,
    fill = TRUE,
    comment.char = "",
    na.strings = c("NA", "NaN", "nan", "")
  )

  keep_cols <- vapply(out, function(col) !all(is.na(col)), logical(1))
  out[, keep_cols, drop = FALSE]
}

.summary_type_for_plot <- function(type) {
  if (type %in% c("age_class", "age_plus_one")) {
    return("class")
  }

  "pop"
}

# --- THE MASTER FUNCTION ---

#' Plot CDMetaPOP Population Dynamics
#'
#' A unified plotting function for CDMetaPOP output files.
#'
#' @param data A dataframe, file path (`.csv`, `.rds`, `.RData`), vector of file
#'   paths, or a directory containing `summary_popAllTime.csv` and
#'   `summary_classAllTime.csv` files.
#' @param type String specifying the plot type: "count", "sex", "mature",
#'   "births", "myy_ratio", "age_class", "patch", or "age_plus_one".
#' @param batch_labels Optional named character vector used to relabel faceted
#'   source groups. Names should match folder names such as `N.out1776184541`
#'   and values should be the labels you want displayed in the facet strips.
#' @param show_mc Logical. If `TRUE`, plot individual Monte Carlo trajectories
#'   when multiple source files are supplied. Defaults to `TRUE`.
#' @param show_ci Logical. If `TRUE`, plot the mean and a 95% confidence band
#'   across Monte Carlo replicates when multiple source files are supplied.
#'   Defaults to `TRUE`.
#' @param ... Additional arguments passed to specific plot types (e.g., `n` for
#'   age_class or `years` for patch).
#'
#' @details
#' `plot_population()` can now work with individual summary files, multiple
#' summary files, or a top-level CDMetaPOP output directory containing many
#' `run0batch#mc#species#` folders. When a directory is supplied, the function
#' recursively discovers the summary files needed for the requested plot type:
#'
#' - `"count"`, `"sex"`, `"mature"`, `"births"`, `"myy_ratio"`, and `"patch"`
#'   use `summary_popAllTime.csv`
#' - `"age_class"` and `"age_plus_one"` use `summary_classAllTime.csv`
#'
#' The function reads all matching files, combines them into a single data
#' frame, and adds metadata columns describing the source of each record:
#'
#' - `.source_file`: full file path used to read the summary
#' - `.source_group`: parent output folder such as `N.out...` or `R.out...`
#' - `.source_id`: unique identifier for one run / batch / Monte Carlo / species
#' - `.run`, `.batch`, `.mc`, `.species`: parsed integer identifiers from the
#'   `run0batch0mc0species0` folder name
#'
#' This makes it possible to compare multiple Monte Carlo replicates in one plot
#' without manually binding files together first. For line-based plots, the
#' function can also overlay a mean trajectory and a 95% confidence interval
#' band across Monte Carlo replicates.
#'
#' The packaged example directory `inst/extdata/package_ex_out_example`
#' intentionally includes a very small subset of the full example output:
#'
#' - 2 source groups (`N.out...` and `R.out...`)
#' - 2 Monte Carlo folders in each group (`mc0` and `mc1`)
#' - both `summary_popAllTime.csv` and `summary_classAllTime.csv`
#'
#' This is small enough for package examples while still demonstrating the
#' multi-file directory workflow.
#'
#' @examples
#' # Example 1: plot a single packaged summary_popAllTime file
#' pop_file <- system.file("extdata", "summary_popAllTime.csv", package = "cdmetapopR")
#' plot_population(pop_file, type = "count")
#'
#' # Example 2: plot a single packaged summary_classAllTime file
#' class_file <- system.file("extdata", "summary_classAllTime.csv", package = "cdmetapopR")
#' plot_population(class_file, type = "age_class", n = 10)
#'
#' # Example 3: use the packaged multi-file example directory
#' ex_dir <- system.file("extdata", "package_ex_out_example", package = "cdmetapopR")
#' plot_population(ex_dir, type = "count")
#' plot_population(ex_dir, type = "sex")
#' plot_population(ex_dir, type = "age_plus_one")
#'
#' # Example 3b: relabel the faceted source groups
#' batch_labels <- c(
#'   "N.out1776184541" = "Scenario N",
#'   "R.out1776189704" = "Scenario R"
#' )
#' plot_population(ex_dir, type = "count", batch_labels = batch_labels)
#'
#' # Example 3c: suppress individual Monte Carlo lines and keep only the
#' # mean plus 95% confidence interval
#' plot_population(ex_dir, type = "count", show_mc = FALSE, show_ci = TRUE)
#'
#' # Example 4: pass several files directly
#' example_files <- list.files(
#'   ex_dir,
#'   pattern = "summary_popAllTime.csv$",
#'   recursive = TRUE,
#'   full.names = TRUE
#' )
#' plot_population(example_files, type = "births")
#' @import ggplot2
#' @importFrom tidyr pivot_longer
#' @importFrom utils read.table
#' @importFrom tools file_ext
#' @return A ggplot object.
#' @export
plot_population <- function(data, type = "count", batch_labels = NULL, show_mc = TRUE, show_ci = TRUE, ...) {
  type <- strsplit(tolower(type), " ")[[1]][1]
  summary_type <- .summary_type_for_plot(type)
  data <- .resolve_cdmetapop_input(data, summary_type = summary_type)

  p <- switch(
    type,
    "count"        = helper_plot_count(data, batch_labels = batch_labels, show_mc = show_mc, show_ci = show_ci),
    "sex"          = helper_plot_sex(data, batch_labels = batch_labels, show_mc = show_mc, show_ci = show_ci),
    "mature"       = helper_plot_mature(data, batch_labels = batch_labels, show_mc = show_mc, show_ci = show_ci),
    "births"       = helper_plot_births(data, batch_labels = batch_labels, show_mc = show_mc, show_ci = show_ci),
    "myy_ratio"    = helper_plot_myy(data, batch_labels = batch_labels, show_mc = show_mc, show_ci = show_ci),
    "age_class"    = helper_plot_age_class(data, batch_labels = batch_labels, ...),
    "patch"        = helper_plot_patch(data, batch_labels = batch_labels, ...),
    "age_plus_one" = helper_plot_age_plus(data, batch_labels = batch_labels, show_mc = show_mc, show_ci = show_ci),
    stop("Invalid type. Choose: 'count', 'sex', 'mature', 'births', 'myy_ratio', 'age_class', 'patch', or 'age_plus_one'.")
  )

  p + .theme_cdmetapop()
}

# --- SUB-HELPER FUNCTIONS ---

helper_plot_count <- function(data, batch_labels = NULL, show_mc = TRUE, show_ci = TRUE) {
  n_init <- .extract_pipe_table(data$N_Initial)[, 1]
  df <- data.frame(
    Year = as.numeric(data$Year),
    N = as.numeric(n_init),
    .source_group = data$.source_group,
    .source_id = data$.source_id,
    .mc = data$.mc,
    stringsAsFactors = FALSE
  )

  .plot_line_by_source(
    df,
    "N",
    "Population Size Timeseries",
    "Population Size",
    batch_labels = batch_labels,
    show_mc = show_mc,
    show_ci = show_ci
  )
}

helper_plot_sex <- function(data, batch_labels = NULL, show_mc = TRUE, show_ci = TRUE) {
  df <- data.frame(
    Year = as.numeric(data$Year),
    "Wild-males" = as.numeric(.extract_pipe_table(data$N_Males)[, 1]),
    "YYMales" = as.numeric(.extract_pipe_table(data$N_YYMales)[, 1]),
    "Wild-females" = as.numeric(.extract_pipe_table(data$N_Females)[, 1]),
    "YYFemales" = as.numeric(.extract_pipe_table(data$N_YYFemales)[, 1]),
    .source_group = data$.source_group,
    .source_id = data$.source_id,
    .mc = data$.mc,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  long_data <- tidyr::pivot_longer(
    df,
    cols = c("Wild-males", "YYMales", "Wild-females", "YYFemales"),
    names_to = "category",
    values_to = "value"
  )

  p <- ggplot(
    long_data,
    aes(
      x = .data$Year,
      y = .data$value,
      group = interaction(.data$.source_id, .data$category)
    )
  )

  if (.plot_has_multiple_sources(long_data)) {
    summary_df <- .summarize_ci_cdmetapop(
      data = long_data,
      value_col = "value",
      group_cols = c(".source_group", "category", "Year")
    )

    if (show_ci) {
      p <- p +
        geom_ribbon(
          data = summary_df,
          aes(x = .data$Year, ymin = .data$lower, ymax = .data$upper, group = interaction(.data$.source_group, .data$category)),
          inherit.aes = FALSE,
          fill = "steelblue",
          alpha = 0.18
        ) +
        geom_line(
          data = summary_df,
          aes(x = .data$Year, y = .data$mean, group = interaction(.data$.source_group, .data$category)),
          inherit.aes = FALSE,
          color = "steelblue4",
          linewidth = 0.9
        )
    }

    if (show_mc) {
      p <- p + geom_line(aes(color = factor(.data$.mc)), alpha = 0.35, linewidth = 0.6)
    }

    p <- p +
      facet_grid(
        category ~ .source_group,
        scales = "free_y",
        labeller = ggplot2::labeller(.source_group = .facet_labeler_cdmetapop(batch_labels))
      ) +
      labs(color = "Monte Carlo")
  } else {
    p <- p +
      geom_line(linewidth = 0.8) +
      facet_wrap(~ category)
  }

  p + labs(title = "Population Sizes by Sex", x = "Year", y = "Count")
}

helper_plot_mature <- function(data, batch_labels = NULL, show_mc = TRUE, show_ci = TRUE) {
  df <- data.frame(
    Year = as.numeric(data$Year),
    "Mature Wild-F" = as.numeric(.extract_pipe_table(data$N_MatureFemales)[, 1]),
    "Mature Wild-M" = as.numeric(.extract_pipe_table(data$N_MatureMales)[, 1]),
    "Mature YYM" = as.numeric(.extract_pipe_table(data$N_MatureYYMales)[, 1]),
    "Mature YYF" = as.numeric(.extract_pipe_table(data$N_MatureYYFemales)[, 1]),
    .source_group = data$.source_group,
    .source_id = data$.source_id,
    .mc = data$.mc,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  long_data <- tidyr::pivot_longer(
    df,
    cols = c("Mature Wild-F", "Mature Wild-M", "Mature YYM", "Mature YYF"),
    names_to = "category",
    values_to = "value"
  )

  p <- ggplot(
    long_data,
    aes(
      x = .data$Year,
      y = .data$value,
      group = interaction(.data$.source_id, .data$category)
    )
  )

  if (.plot_has_multiple_sources(long_data)) {
    summary_df <- .summarize_ci_cdmetapop(
      data = long_data,
      value_col = "value",
      group_cols = c(".source_group", "category", "Year")
    )

    if (show_ci) {
      p <- p +
        geom_ribbon(
          data = summary_df,
          aes(x = .data$Year, ymin = .data$lower, ymax = .data$upper, group = interaction(.data$.source_group, .data$category)),
          inherit.aes = FALSE,
          fill = "darkgreen",
          alpha = 0.18
        ) +
        geom_line(
          data = summary_df,
          aes(x = .data$Year, y = .data$mean, group = interaction(.data$.source_group, .data$category)),
          inherit.aes = FALSE,
          color = "darkgreen",
          linewidth = 0.9
        )
    }

    if (show_mc) {
      p <- p + geom_line(aes(color = factor(.data$.mc)), alpha = 0.35, linewidth = 0.6)
    }

    p <- p +
      facet_grid(
        category ~ .source_group,
        scales = "free_y",
        labeller = ggplot2::labeller(.source_group = .facet_labeler_cdmetapop(batch_labels))
      ) +
      labs(color = "Monte Carlo")
  } else {
    p <- p +
      geom_line(color = "darkgreen", linewidth = 0.8) +
      facet_wrap(~ category)
  }

  p + labs(title = "Sexually Mature Population", x = "Year", y = "Count")
}

helper_plot_births <- function(data, batch_labels = NULL, show_mc = TRUE, show_ci = TRUE) {
  births <- as.numeric(.extract_pipe_table(data$Births)[, 1])
  deaths <- as.numeric(.extract_pipe_table(data$EggDeaths)[, 1])

  df <- data.frame(
    Year = as.numeric(data$Year),
    Progeny = births - deaths,
    .source_group = data$.source_group,
    .source_id = data$.source_id,
    .mc = data$.mc,
    stringsAsFactors = FALSE
  )

  .plot_line_by_source(
    df,
    "Progeny",
    "Progeny by Year (Post Egg-Mortality)",
    "Count",
    color = "purple",
    batch_labels = batch_labels,
    show_mc = show_mc,
    show_ci = show_ci
  )
}

helper_plot_myy <- function(data, batch_labels = NULL, show_mc = TRUE, show_ci = TRUE) {
  births <- as.numeric(.extract_pipe_table(data$Births)[, 1])
  deaths <- as.numeric(.extract_pipe_table(data$EggDeaths)[, 1])
  myy <- as.numeric(.extract_pipe_table(data$MyyProgeny)[, 1])

  df <- data.frame(
    Year = as.numeric(data$Year),
    Ratio = myy / (births - deaths),
    .source_group = data$.source_group,
    .source_id = data$.source_id,
    .mc = data$.mc,
    stringsAsFactors = FALSE
  )

  .plot_line_by_source(
    df,
    "Ratio",
    "MYY Progeny Ratio",
    "Proportion",
    color = "firebrick",
    batch_labels = batch_labels,
    show_mc = show_mc,
    show_ci = show_ci
  )
}

helper_plot_age_class <- function(data, n = 5, batch_labels = NULL) {
  count_col <- if ("N_Initial_Age" %in% names(data)) "N_Initial_Age" else "N_Initial_Class"
  count_data <- .extract_pipe_table(data[[count_col]])

  if ("Ages" %in% names(data)) {
    age_labels <- strsplit(as.character(data$Ages[1]), "\\|")[[1]]
  } else {
    age_labels <- 0:(ncol(count_data) - 1)
  }

  colnames(count_data) <- paste0("Age_", age_labels)
  count_data$Year <- as.numeric(data$Year)
  count_data$.source_group <- data$.source_group
  count_data$.source_id <- data$.source_id

  long_data <- tidyr::pivot_longer(
    count_data,
    cols = grep("^Age_", names(count_data), value = TRUE),
    names_to = "Ages",
    values_to = "Count"
  )

  long_data$Count <- as.numeric(long_data$Count)
  df_filtered <- long_data[long_data$Year %% n == 0, ]

  if (.plot_has_multiple_sources(df_filtered)) {
    df_summary <- .summarize_ci_cdmetapop(
      data = df_filtered,
      value_col = "Count",
      group_cols = c(".source_group", "Year", "Ages")
    )

    return(
      ggplot(df_summary, aes(x = as.factor(.data$Year), y = .data$mean, fill = .data$Ages)) +
        geom_bar(position = "dodge", stat = "identity") +
        geom_errorbar(
          aes(ymin = .data$lower, ymax = .data$upper),
          position = position_dodge(width = 0.9),
          width = 0.2,
          alpha = 0.5
        ) +
        facet_wrap(
          ~ .source_group,
          scales = "free_y",
          labeller = ggplot2::labeller(.source_group = .facet_labeler_cdmetapop(batch_labels))
        ) +
        labs(title = "Population Size by Age Class", x = "Year", y = "Mean Count")
    )
  }

  ggplot(df_filtered, aes(x = as.factor(.data$Year), y = .data$Count, fill = .data$Ages)) +
    geom_bar(position = "dodge", stat = "identity") +
    labs(title = "Population Size by Age Class", x = "Year", y = "Count")
}

helper_plot_patch <- function(data, years = c(1, 25, 50, 100), batch_labels = NULL) {
  abundance <- .extract_pipe_table(data$N_Initial)
  abundance <- abundance[, -1, drop = FALSE]
  colnames(abundance) <- paste0("Patch_", seq_len(ncol(abundance)))
  abundance$Year <- as.numeric(data$Year)
  abundance$.source_group <- data$.source_group
  abundance$.source_id <- data$.source_id

  long_data <- tidyr::pivot_longer(
    abundance,
    cols = grep("^Patch_", names(abundance), value = TRUE),
    names_to = "Patch",
    values_to = "Abundance"
  )

  long_data$Abundance <- as.numeric(long_data$Abundance)
  df_filtered <- long_data[long_data$Year %in% years, ]

  p <- ggplot(df_filtered, aes(x = as.factor(.data$Year), y = .data$Abundance)) +
    geom_boxplot(fill = "steelblue", outlier.alpha = 0.5) +
    labs(title = "Patch Population Distribution", x = "Year", y = "Abundance")

  if (.plot_has_multiple_sources(df_filtered)) {
    p <- p +
      facet_wrap(
        ~ .source_group,
        scales = "free_y",
        labeller = ggplot2::labeller(.source_group = .facet_labeler_cdmetapop(batch_labels))
      )
  }

  p
}

helper_plot_age_plus <- function(data, batch_labels = NULL, show_mc = TRUE, show_ci = TRUE) {
  count_col <- if ("N_Initial_Age" %in% names(data)) "N_Initial_Age" else "N_Initial_Class"
  age_class <- .extract_pipe_table(data[[count_col]])

  if (ncol(age_class) < 2) {
    stop("Age data must contain at least two age classes to calculate age 1+ population size.")
  }

  pop_plus <- rowSums(age_class[, 2:ncol(age_class), drop = FALSE], na.rm = TRUE)
  df <- data.frame(
    Year = as.numeric(data$Year),
    Pop = as.numeric(pop_plus),
    .source_group = data$.source_group,
    .source_id = data$.source_id,
    .mc = data$.mc,
    stringsAsFactors = FALSE
  )

  .plot_line_by_source(
    df,
    "Pop",
    "Population Size (Age 1+)",
    "Count",
    color = "orange",
    batch_labels = batch_labels,
    show_mc = show_mc,
    show_ci = show_ci
  )
}
