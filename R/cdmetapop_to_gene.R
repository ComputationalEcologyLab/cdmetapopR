#' Convert CDMetaPOP data to GENEPOP or GENALEX format
#'
#' This function reads a `CDMetaPOP` CSV file, processes the genetic loci,
#' and converts the data into `GENEPOP` or `GENALEX` formats.
#'
#' @param path Character string; the file path to the `CDMetaPOP` CSV file.
#' @param format A character string indicating the desired output format:
#'   "genepop" or "genalex". Genepop is default.
#' @param output_dir Character string; the directory where output files
#'   will be written. Defaults to tempdir().
#'
#' @return The function writes the GENEPOP or GENALEX formatted data to the
#'   specified output directory.
#' @examples
#' path <- system.file("extdata", "Example_dat",
#'   "run0batch0mc0species0", "ind9.csv",
#'   package = "cdmetapopR")
#' cdmetapop_to_gene(path = path, format = "genepop")
#' cdmetapop_to_gene(path = path, format = "genalex")
#' @import adegenet
#' @import graph4lg
#' @import poppr
#' @export
cdmetapop_to_gene <- function(path, format = "genepop",
                              output_dir = tempdir()) {
  # Read the input data
  mydata <- read.csv(path, stringsAsFactors = FALSE)
  col_names <- names(mydata)
  # Identify loci columns
  locus_names <- grepl("L[[:digit:]]+A[[:digit:]]+$", col_names)
  loci <- mydata[, col_names[locus_names]]
  df <- mydata[, col_names[!locus_names]]
  locus_names <- names(loci)
  # Process loci into alleles
  process_alleles <- function(x) {
    alleles <- which(x != 0) - 1
    if (length(alleles) == 1) alleles <- rep(alleles, 2)
    paste(alleles, collapse = ":")
  }
  for (locus in unique(gsub("A[[:digit:]]+$", "", locus_names))) {
    idx <- grep(locus, locus_names)
    alleles <- apply(loci[, idx, drop = FALSE], 1, process_alleles)
    df[[locus]] <- alleles
  }
  loc_columns <- unique(gsub("A.*$", "", locus_names))
  new <- df[, loc_columns]
  # Use a column from df as rownames (e.g., 'ID')
  rownames(new) <- df$ID
  # Create a vector 'PatchID' for 'POP'
  pop <- df$PatchID
  tmp <- adegenet::df2genind(new, sep = ":", pop = pop)
  # Handle GENEPOP output
  if (format == "genepop") {
    output_file <- file.path(output_dir,
                             paste0("my_genepop_",
                                    tools::file_path_sans_ext(basename(path)),
                                    ".txt"))
    graph4lg::genind_to_genepop(tmp, output = output_file)
    message("GENEPOP file written to: ", output_file)
  }
  # Handle GENALEX output
  if (format == "genalex") {
    output_file <- file.path(output_dir,
                             paste0("my_genalex_",
                                    tools::file_path_sans_ext(basename(path)),
                                    ".csv"))
    poppr::genind2genalex(tmp, filename = output_file,
                          overwrite = TRUE)
    message("GENALEX file written to: ", output_file)
  }
}
