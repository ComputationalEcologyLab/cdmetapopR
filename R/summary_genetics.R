# --- INTERNAL HELPERS (Not Exported) ---

.detect_locus_allele_columns <- function(data, loci = NULL) {
  allele_cols <- grep("^L[0-9]+A[0-9]+$", names(data), value = TRUE)

  if (length(allele_cols) == 0) {
    stop("No genotype columns matching L#A# were found.")
  }

  pieces <- do.call(
    rbind,
    regmatches(allele_cols, regexec("^L([0-9]+)A([0-9]+)$", allele_cols))
  )

  out <- data.frame(
    column = allele_cols,
    locus = paste0("L", pieces[, 2]),
    allele = paste0("A", pieces[, 3]),
    stringsAsFactors = FALSE
  )

  if (!is.null(loci)) {
    loci <- ifelse(grepl("^L", loci), loci, paste0("L", loci))
    out <- out[out$locus %in% loci, , drop = FALSE]
  }

  if (nrow(out) == 0) {
    stop("No genotype columns matched the requested loci.")
  }

  out[order(out$locus, out$allele), , drop = FALSE]
}

.locus_groups <- function(locus_cols) {
  split(locus_cols$column, locus_cols$locus)
}

.allele_frequency_rows <- function(data, locus_cols, group_col) {
  .check_ind_columns(data, group_col)

  rows <- lapply(seq_len(nrow(locus_cols)), function(i) {
    col <- locus_cols$column[i]
    split_index <- split(seq_len(nrow(data)), data[[group_col]], drop = TRUE)

    do.call(
      rbind,
      lapply(names(split_index), function(group) {
        idx <- split_index[[group]]
        locus <- locus_cols$locus[i]
        locus_total <- rowSums(data[idx, .locus_groups(locus_cols)[[locus]], drop = FALSE], na.rm = TRUE)
        allele_count <- sum(as.numeric(data[[col]][idx]), na.rm = TRUE)
        total_count <- sum(locus_total, na.rm = TRUE)

        data.frame(
          Group = group,
          Locus = locus,
          Allele = locus_cols$allele[i],
          frequency = if (total_count > 0) allele_count / total_count else NA_real_,
          allele_count = allele_count,
          total_count = total_count,
          stringsAsFactors = FALSE
        )
      })
    )
  })

  do.call(rbind, rows)
}

.heterozygosity_rows <- function(data, locus_cols, group_col) {
  .check_ind_columns(data, group_col)
  loci <- .locus_groups(locus_cols)
  split_index <- split(seq_len(nrow(data)), data[[group_col]], drop = TRUE)

  rows <- lapply(names(split_index), function(group) {
    idx <- split_index[[group]]

    do.call(
      rbind,
      lapply(names(loci), function(locus) {
        cols <- loci[[locus]]
        locus_data <- data[idx, cols, drop = FALSE]
        allele_totals <- colSums(locus_data, na.rm = TRUE)
        total_alleles <- sum(allele_totals)
        freqs <- if (total_alleles > 0) allele_totals / total_alleles else rep(NA_real_, length(allele_totals))

        data.frame(
          Group = group,
          Locus = locus,
          Ho = mean(rowSums(locus_data > 0, na.rm = TRUE) > 1, na.rm = TRUE),
          He = 1 - sum(freqs^2, na.rm = TRUE),
          n = nrow(locus_data),
          stringsAsFactors = FALSE
        )
      })
    )
  })

  do.call(rbind, rows)
}

.pairwise_fst_for_locus <- function(data, cols, group_col) {
  split_index <- split(seq_len(nrow(data)), data[[group_col]], drop = TRUE)
  groups <- names(split_index)

  if (length(groups) < 2) {
    stop("Pairwise FST requires at least two groups in ", group_col, ".")
  }

  pairs <- utils::combn(groups, 2, simplify = FALSE)

  do.call(
    rbind,
    lapply(pairs, function(pair) {
      idx1 <- split_index[[pair[1]]]
      idx2 <- split_index[[pair[2]]]

      counts1 <- colSums(data[idx1, cols, drop = FALSE], na.rm = TRUE)
      counts2 <- colSums(data[idx2, cols, drop = FALSE], na.rm = TRUE)
      total1 <- sum(counts1)
      total2 <- sum(counts2)

      if (total1 == 0 || total2 == 0) {
        fst <- NA_real_
      } else {
        p1 <- counts1 / total1
        p2 <- counts2 / total2
        p_total <- (counts1 + counts2) / (total1 + total2)
        hs <- (total1 * (1 - sum(p1^2)) + total2 * (1 - sum(p2^2))) / (total1 + total2)
        ht <- 1 - sum(p_total^2)
        fst <- if (ht > 0) (ht - hs) / ht else NA_real_
      }

      data.frame(Group1 = pair[1], Group2 = pair[2], FST = fst, stringsAsFactors = FALSE)
    })
  )
}

# --- EXPORTED FUNCTIONS ---

#' Plot Individual-Level Allele Frequencies
#'
#' Calculates allele frequencies from `L#A#` genotype columns in CDMetaPOP
#' `ind##.csv` files.
#'
#' @inheritParams summary_ind
#' @param loci Optional vector of loci to include, such as `c("L0", "L1")` or
#'   `c(0, 1)`. Defaults to all detected loci.
#' @param group_col Column used for grouping frequencies. Defaults to
#'   `"PatchID"`.
#' @param mean_across_patches Logical. If `TRUE`, plot the mean allele
#'   frequency across patches for the specified year. Defaults to `FALSE`.
#'
#' @return A ggplot object with frequency data in `plot$data`.
#' @examples
#' ex_dir <- system.file("extdata", "Adaptive_Run_08", package = "cdmetapopR")
#' allele_frequencies_ind(ex_dir, year = 9)
#' allele_frequencies_ind(ex_dir, year = 9, mean_across_patches = TRUE)
#' @export
allele_frequencies_ind <- function(path,
                                   year = 0,
                                   run = 0,
                                   batch = 0,
                                   mc = 0,
                                   species = 0,
                                   loci = NULL,
                                   group_col = "PatchID",
                                   mean_across_patches = FALSE) {
  data <- .resolve_ind_input(path, run = run, batch = batch, mc = mc, species = species, years = year)
  locus_cols <- .detect_locus_allele_columns(data, loci = loci)
  freq_data <- .allele_frequency_rows(data, locus_cols, group_col = group_col)

  if (mean_across_patches) {
    split_index <- split(
      seq_len(nrow(freq_data)),
      interaction(freq_data$Locus, freq_data$Allele, drop = TRUE, lex.order = TRUE)
    )

    freq_data <- do.call(
      rbind,
      lapply(split_index, function(idx) {
        data.frame(
          Locus = freq_data$Locus[idx[1]],
          Allele = freq_data$Allele[idx[1]],
          frequency = mean(freq_data$frequency[idx], na.rm = TRUE),
          sd_frequency = stats::sd(freq_data$frequency[idx], na.rm = TRUE),
          n_groups = sum(!is.na(freq_data$frequency[idx])),
          stringsAsFactors = FALSE
        )
      })
    )

    freq_data$sd_frequency[is.na(freq_data$sd_frequency)] <- 0

    return(
      ggplot2::ggplot(freq_data, ggplot2::aes(x = .data$Allele, y = .data$frequency, fill = .data$Allele)) +
        ggplot2::geom_col() +
        ggplot2::geom_errorbar(
          ggplot2::aes(
            ymin = pmax(0, .data$frequency - .data$sd_frequency),
            ymax = pmin(1, .data$frequency + .data$sd_frequency)
          ),
          width = 0.2
        ) +
        ggplot2::facet_wrap(~ Locus) +
        ggplot2::labs(title = "Mean Allele Frequencies Across Groups", x = "Allele", y = "Mean Frequency") +
        .theme_cdmetapop()
    )
  }

  ggplot2::ggplot(freq_data, ggplot2::aes(x = .data$Allele, y = .data$frequency, fill = .data$Allele)) +
    ggplot2::geom_col() +
    ggplot2::facet_grid(Locus ~ Group) +
    ggplot2::labs(title = "Allele Frequencies", x = "Allele", y = "Frequency") +
    .theme_cdmetapop()
}

#' Plot Individual-Level Heterozygosity
#'
#' Calculates observed and expected heterozygosity from `L#A#` genotype columns
#' in CDMetaPOP `ind##.csv` files.
#'
#' @inheritParams allele_frequencies_ind
#'
#' @return A ggplot object with heterozygosity data in `plot$data`.
#' @examples
#' ex_dir <- system.file("extdata", "Adaptive_Run_08", package = "cdmetapopR")
#' heterozygosity_ind(ex_dir, year = 9)
#' heterozygosity_ind(ex_dir, year = 9, mean_across_patches = TRUE)
#' @export
heterozygosity_ind <- function(path,
                               year = 0,
                               run = 0,
                               batch = 0,
                               mc = 0,
                               species = 0,
                               loci = NULL,
                               group_col = "PatchID",
                               mean_across_patches = FALSE) {
  data <- .resolve_ind_input(path, run = run, batch = batch, mc = mc, species = species, years = year)
  locus_cols <- .detect_locus_allele_columns(data, loci = loci)
  het_data <- .heterozygosity_rows(data, locus_cols, group_col = group_col)
  plot_data <- tidyr::pivot_longer(het_data, cols = c("Ho", "He"), names_to = "Metric", values_to = "Value")

  if (mean_across_patches) {
    split_index <- split(
      seq_len(nrow(plot_data)),
      interaction(plot_data$Locus, plot_data$Metric, drop = TRUE, lex.order = TRUE)
    )

    plot_data <- do.call(
      rbind,
      lapply(split_index, function(idx) {
        data.frame(
          Locus = plot_data$Locus[idx[1]],
          Metric = plot_data$Metric[idx[1]],
          Value = mean(plot_data$Value[idx], na.rm = TRUE),
          sd_value = stats::sd(plot_data$Value[idx], na.rm = TRUE),
          n_groups = sum(!is.na(plot_data$Value[idx])),
          stringsAsFactors = FALSE
        )
      })
    )

    plot_data$sd_value[is.na(plot_data$sd_value)] <- 0

    return(
      ggplot2::ggplot(plot_data, ggplot2::aes(x = .data$Locus, y = .data$Value, fill = .data$Metric)) +
        ggplot2::geom_col(position = "dodge") +
        ggplot2::geom_errorbar(
          ggplot2::aes(
            ymin = pmax(0, .data$Value - .data$sd_value),
            ymax = pmin(1, .data$Value + .data$sd_value)
          ),
          position = ggplot2::position_dodge(width = 0.9),
          width = 0.2
        ) +
        ggplot2::labs(title = "Mean Observed and Expected Heterozygosity Across Patches", x = "Locus", y = "Mean Heterozygosity") +
        .theme_cdmetapop()
    )
  }

  ggplot2::ggplot(plot_data, ggplot2::aes(x = .data$Locus, y = .data$Value, fill = .data$Metric)) +
    ggplot2::geom_col(position = "dodge") +
    ggplot2::facet_wrap(~ Group) +
    ggplot2::labs(title = "Observed and Expected Heterozygosity", x = "Locus", y = "Heterozygosity") +
    .theme_cdmetapop()
}

#' Plot Pairwise FST Between Individual Groups
#'
#' Calculates pairwise FST between groups, usually patches, from `L#A#`
#' genotype columns in CDMetaPOP `ind##.csv` files. FST is calculated per locus
#' and then averaged across loci for each pair.
#'
#' @inheritParams allele_frequencies_ind
#'
#' @return A ggplot heatmap with pairwise FST data in `plot$data`.
#' @examples
#' ex_dir <- system.file("extdata", "Adaptive_Run_08", package = "cdmetapopR")
#' pairwise_fst_ind(ex_dir, year = 9)
#' @export
pairwise_fst_ind <- function(path,
                             year = 0,
                             run = 0,
                             batch = 0,
                             mc = 0,
                             species = 0,
                             loci = NULL,
                             group_col = "PatchID") {
  data <- .resolve_ind_input(path, run = run, batch = batch, mc = mc, species = species, years = year)
  .check_ind_columns(data, group_col)
  locus_cols <- .detect_locus_allele_columns(data, loci = loci)
  loci_list <- .locus_groups(locus_cols)

  fst_by_locus <- do.call(
    rbind,
    lapply(names(loci_list), function(locus) {
      out <- .pairwise_fst_for_locus(data, loci_list[[locus]], group_col = group_col)
      out$Locus <- locus
      out
    })
  )

  split_pairs <- split(seq_len(nrow(fst_by_locus)), interaction(fst_by_locus$Group1, fst_by_locus$Group2, drop = TRUE))
  fst_data <- do.call(
    rbind,
    lapply(split_pairs, function(idx) {
      data.frame(
        Group1 = fst_by_locus$Group1[idx[1]],
        Group2 = fst_by_locus$Group2[idx[1]],
        FST = mean(fst_by_locus$FST[idx], na.rm = TRUE),
        stringsAsFactors = FALSE
      )
    })
  )

  group_levels <- unique(c(fst_data$Group1, fst_data$Group2))
  numeric_levels <- suppressWarnings(as.numeric(group_levels))
  if (all(!is.na(numeric_levels))) {
    group_levels <- group_levels[order(numeric_levels)]
  } else {
    group_levels <- sort(group_levels)
  }

  fst_data$Group1 <- factor(fst_data$Group1, levels = group_levels)
  fst_data$Group2 <- factor(fst_data$Group2, levels = group_levels)

  ggplot2::ggplot(fst_data, ggplot2::aes(x = .data$Group1, y = .data$Group2, fill = .data$FST)) +
    ggplot2::geom_tile(color = "white") +
    ggplot2::scale_fill_gradient(low = "white", high = "steelblue", na.value = "grey90") +
    ggplot2::labs(title = "Pairwise FST", x = group_col, y = group_col, fill = "FST") +
    .theme_cdmetapop()
}
