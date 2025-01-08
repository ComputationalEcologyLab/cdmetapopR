#' Convert CDMetaPOP data to GENEPOP format
#'
#' This function reads a `CDMetaPOP` CSV file, processes the genetic loci, and converts the data into `GENEPOP` format.
#'
#' @param path Character string; the file path to the `CDMetaPOP` CSV file.
#' @param stratum Character string; the column name in the input data that specifies the population (e.g., `PatchID`).
#' @param output_file Character string; the file path for the output GENEPOP file.
#'
#' @return The function writes the GENEPOP-formatted data to the specified file.
#' 
#' @examples
#' \dontrun{
#' # Convert a CDMetaPOP file to GENEPOP format
#' cdmetapop_to_genepop(
#'   path = "your_path/ind1.csv",
#'   stratum = "PatchID",
#'   output_file = "cdmetapop_to_genepop_output.gen"
#' )
#' }
#' @export
cdmetapop_to_genepop <- function(path, stratum, output_file) {
  mydata <- read.csv(path, stringsAsFactors = FALSE)
  col_names <- names(mydata)
  locus_names <- grepl("L[[:digit:]]+A[[:digit:]]+$", col_names)
  loci <- mydata[, col_names[locus_names]]
  df <- mydata[, col_names[!locus_names]]
  locus_names <- names(loci)
  
  # Determine the number of loci
  last_loc <- names(loci)[length(locus_names)]
  l <- strsplit(last_loc, split = "A")[[1]][1]
  l <- as.numeric(substr(l, 2, nchar(l)))
  
  # Process loci into alleles
  for (i in 0:l) {
    locus_name <- paste("Locus", i, sep = "-")
    idx <- grep(paste("L", i, "A", sep = ""), locus_names)
    x <- loci[, idx]
    get_alleles <- function(x) {
      a <- which(x != 0)
      a <- a - 1
      if (length(a) == 1) a <- c(a, a)
      return(paste(a, collapse = ":"))
    }
    alleles <- apply(x, 1, get_alleles)
    df[[locus_name]] <- alleles
  }
  
  # Write to GENEPOP
  output <- file(output_file, "w")
  writeLines("CDMetaPOP outfile into Genepop", output)
  writeLines(names(loci), output)
  
  unique_pops <- unique(df[[stratum]])
  for (pop in unique_pops) {
    writeLines(paste("PatchID", pop, sep = ""), output)
    pop_data <- df[df[[stratum]] == pop, ]
    for (i in 1:nrow(pop_data)) {
      individual_id <- pop_data$ID[i]
      alleles <- sapply(names(loci), function(locus) {
        tryCatch(
          {
            allele_data <- strsplit(as.character(pop_data[i, locus]), ":")[[1]]
            paste(allele_data, collapse = "")
          },
          error = function(e) {
            warning(paste("Missing data for locus", locus, "individual", i))
            return("")
          }
        )
      })
      genotype_data <- paste(individual_id, paste(alleles, collapse = " "), sep = ", ")
      writeLines(genotype_data, output)
    }
  }
  
  close(output)
  cat("GENEPOP file has been written to", output_file, "\n")
}
