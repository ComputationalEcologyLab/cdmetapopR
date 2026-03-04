#' Column symbol separator 
#'
#' This function eases the separation of column content generated from cdmetapop outputs. CDMetaPOP uses delimiters and different delimiter options are specified for different fields. Delimiter ‘|’ or ‘bar’ is used time parameters. The delimiter ‘~’ (‘tilda’) is used to assign parameters based on sex. The delimiter ‘;’ is the default and used in various contexts to split fields and patches parameters. The delimiter ‘:’ is used to split parameters used for functions. Note that Loo uses one instance of ‘;’ in an Hindex option. See CDMetaPOP manual for more specific uses and examples. 
#'
#' @param x Specify the file name and path.
#' @importFrom utils read.table
#' @return Dataframe of columns for each value that was originally separated by the delimiter.
#' @export
separate_column <- function(file_path, column_name, sep) {
  
  #get the column names
  my_columm_names <- read.table(file_path, 
                  nrows = 1, 
                  colClasses = 'character', 
                  header = FALSE, 
                  sep = ",")
  #get the dataframe
  my_data <- read.table(file_path, 
                  sep = ",", 
                  stringsAsFactors = FALSE,
                  colClasses = "character",
                  skip = 1)
  
  colnames(my_data) <- my_columm_names

  my_data_split <- read.table(text = my_data[,column_name], sep = sep)
  
                                  
  # Return the selected column as a dataframe
  return(my_data_split)
}

#' Unite multiple columns into one 
#'
#' A wrapper for tidyr::unite designed specifically to handle large cdmetapop column outputs
#'
#' @param dataframe A data frame
#' @param column_name Name of the new column 
#' @param sep Separator for united columns
#' @param cols Columns to unite (character vector of column names)
#' @return A data frame with the united columns
#' @importFrom tidyr unite
#' @export
#' 
#' @examples
#' # example code
#' df <- data.frame(
#'   Subpatch = c("A", "B", "C"),
#'   N = c(25, 30, 35),
#'   N_1 = c(34, 44, 34),
#'   N_2 = c(21, 43, 54)
#' )
#'
#' # Specify the columns to unite
#' cols_to_unite <- c("N_1", "N_2")
#'
#' # Call the function to unite the columns
    #' result <- unite_column(df, column_name = "N", sep = "|", cols = cols_to_unite)
#' print(result)
#'
#' # Example with column names X1 to X100
#' df2 <- data.frame(matrix(1:10000, ncol = 100))
#' cols <- names(df2)
#' result2 <- unite_column(df2, column_name = "All_X", sep = ",", cols = cols)
#' head(result2)
#'
#' 
unite_column <- function(dataframe, column_name, sep, cols){
  if (!requireNamespace("tidyr", quietly = TRUE)) {
    message("The 'tidyr' package is not installed. Please install it using install.packages('tidyr').")
     }
  
  # Ensure specified columns exist in the dataframe
  missing_cols <- setdiff(cols, names(dataframe))
  if (length(missing_cols) > 0) {
    stop("The following columns are missing from the dataframe: ", paste(missing_cols, collapse = ", "))
  }
  # Use tidyr::unite
  tidyr::unite(dataframe, {{ column_name }}, all_of(cols), sep = sep, remove = TRUE)
}

