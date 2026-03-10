# --- INTERNAL HELPERS (Not Exported) ---

.resolve_cdmetapop_input <- function(x) {
  if (is.character(x) && length(x) == 1) {
    ext <- tolower(tools::file_ext(x))
    if (ext == "rds") return(readRDS(x))
    if (ext %in% c("rda", "rdata")) {
      e <- new.env(parent = emptyenv())
      nm <- load(x, envir = e)
      return(e[[nm]])
    }
    if (ext == "csv") return(utils::read.csv(x, stringsAsFactors = FALSE))
    stop("Unsupported file type: .", ext)
  }
  x
}

.theme_cdmetapop <- function() {
  theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
      panel.grid.minor = element_blank(),
      #axis.title = element_text(face = "italic"),
      strip.background = element_rect(fill = "grey90", color = NA),
      strip.text = element_text(face = "bold")
    )
}

# --- THE MASTER FUNCTION ---

#' Plot CDMetaPOP Population Dynamics
#'
#' A unified plotting function for CDMetaPOP output files.
#'
#' @param data A dataframe or file path (.csv, .rds, .RData).
#' @param type String specifying the plot type: "count", "sex", "mature", "births", "myy_ratio", "age_class", "patch", or "age_plus_one".
#' @param ... Additional arguments passed to specific plot types (e.g., 'n' for age_class or 'years' for patch).
#' @import ggplot2
#' @importFrom tidyr pivot_longer
#' @importFrom utils read.table
#' @importFrom tools file_ext
#' @return A ggplot object.
#' @export
plot_population <- function(data, type = "count", ...) {
  
  data <- .resolve_cdmetapop_input(data)
  type <- strsplit(tolower(type), " ")[[1]][1]
  
  p <- switch(type,
              "count"        = helper_plot_count(data),
              "sex"          = helper_plot_sex(data),
              "mature"       = helper_plot_mature(data),
              "births"       = helper_plot_births(data),
              "myy_ratio"    = helper_plot_myy(data),
              "age_class"    = helper_plot_age_class(data, ...),
              "patch"        = helper_plot_patch(data, ...),
              "age_plus_one" = helper_plot_age_plus(data),
              stop("Invalid type. Choose: 'count', 'sex', 'mature', 'births', 'myy_ratio', 'age_class', 'patch', or 'age_plus_one'.")
  )
  
  return(p + .theme_cdmetapop())
}

# --- SUB-HELPER FUNCTIONS ---

helper_plot_count <- function(data) {
  n_init <- read.table(text = data$N_Initial, sep = "|")[,1]
  df <- data.frame(Year = as.numeric(data$Year), N = as.numeric(n_init))
  
  ggplot(df, aes(x = Year, y = N)) +
    geom_line(color = "steelblue", linewidth = 0.8) +
    labs(title = "Population Size Timeseries", y = "Population Size", x = "Year")
}

helper_plot_sex <- function(data) {
  df <- data.frame(
    Year = data$Year,
    "Wild-males"   = read.table(text = data$N_Males, sep = "|")[,1],
    "YYMales"      = read.table(text = data$N_YYMales, sep = "|")[,1],
    "Wild-females" = read.table(text = data$N_Females, sep = "|")[,1],
    "YYFemales"    = read.table(text = data$N_YYFemales, sep = "|")[,1]
  )
  long_data <- tidyr::pivot_longer(df, cols = -Year, names_to = "category", values_to = "value")
  
  ggplot(long_data, aes(x = as.numeric(Year), y = as.numeric(value))) +
    geom_line(linewidth = 0.8) +  
    facet_wrap(~ category) +
    labs(title = "Population Sizes by Sex", x = "Year", y = "Count")
}

helper_plot_mature <- function(data) {
  df <- data.frame(
    Year = data$Year,
    "Mature Wild-F" = read.table(text = data$N_MatureFemales, sep = "|")[,1],
    "Mature Wild-M" = read.table(text = data$N_MatureMales, sep = "|")[,1],
    "Mature YYM"    = read.table(text = data$N_MatureYYMales, sep = "|")[,1],
    "Mature YYF"    = read.table(text = data$N_MatureYYFemales, sep = "|")[,1]
  )
  long_data <- tidyr::pivot_longer(df, cols = -Year, names_to = "category", values_to = "value")
  
  ggplot(long_data, aes(x = as.numeric(Year), y = as.numeric(value))) +
    geom_line(color = "darkgreen", linewidth = 0.8) +  
    facet_wrap(~ category) +
    labs(title = "Sexually Mature Population", x = "Year", y = "Count")
}

helper_plot_births <- function(data) {
  births <- read.table(text = data$Births, sep = "|")[,1]
  deaths <- read.table(text = data$EggDeaths, sep = "|")[,1]
  df <- data.frame(Year = data$Year, Progeny = births - deaths)
  
  ggplot(df, aes(x = Year, y = Progeny)) +
    geom_line(color = "purple", linewidth = 0.8) +
    labs(title = "Progeny by Year (Post Egg-Mortality)", x = "Year", y = "Count")
}

helper_plot_myy <- function(data) {
  births <- read.table(text = data$Births, sep = "|")[,1]
  deaths <- read.table(text = data$EggDeaths, sep = "|")[,1]
  myy    <- read.table(text = data$MyyProgeny, sep = "|")[,1]
  
  ratio <- myy / (births - deaths)
  df <- data.frame(Year = data$Year, Ratio = ratio)
  
  ggplot(df, aes(x = Year, y = Ratio)) +
    geom_line(color = "firebrick", linewidth = 0.8) +
    labs(title = "MYY Progeny Ratio", x = "Year", y = "Proportion")
}

helper_plot_age_class <- function(data, n = 5) {
  age_data <- read.table(text = data$N_Initial_Class, sep = "|")
  colnames(age_data) <- paste0("Age_", 0:(ncol(age_data)-1))
  age_data$Year <- data$Year
  
  long_data <- tidyr::pivot_longer(age_data, cols = starts_with("Age_"), names_to = "Ages", values_to = "Count")
  df_filtered <- long_data[long_data$Year %% n == 0, ]
  
  ggplot(df_filtered, aes(x = as.factor(Year), y = Count, fill = Ages)) +
    geom_bar(position = "dodge", stat = "identity") +
    labs(title = "Population Size by Age Class", x = "Year", y = "Count")
}

helper_plot_patch <- function(data, years = c(1, 25, 50, 100)) {
  abundance <- read.table(text = data$N_Initial, sep = "|")
  abundance <- abundance[, -1] # Remove total
  colnames(abundance) <- paste0("Patch_", 1:ncol(abundance))
  abundance$Year <- data$Year
  
  long_data <- tidyr::pivot_longer(abundance, cols = starts_with("Patch_"), names_to = "Patch", values_to = "Abundance")
  df_filtered <- long_data[long_data$Year %in% years, ]
  
  ggplot(df_filtered, aes(x = as.factor(Year), y = Abundance)) +
    geom_boxplot(fill = "steelblue", outlier.alpha = 0.5) +
    labs(title = "Patch Population Distribution", x = "Year", y = "Abundance")
}

helper_plot_age_plus <- function(data) {
  age_class <- read.table(text = data$N_Initial_Class, sep = "|")
  pop_plus <- rowSums(age_class[, 3:ncol(age_class)], na.rm = TRUE)
  df <- data.frame(Year = data$Year, Pop = pop_plus)
  
  ggplot(df, aes(x = Year, y = Pop)) +
    geom_line(color = "orange", linewidth = 0.8) +
    labs(title = "Population Size (Age 1+)", x = "Year", y = "Count")
}