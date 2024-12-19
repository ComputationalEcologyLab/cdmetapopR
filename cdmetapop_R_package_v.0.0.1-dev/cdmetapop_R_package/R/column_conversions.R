#' Column symbol separator 
#'
#' This function eases the separation of column content generated from cdmetapop outputs. CDMetaPOP uses delimiters and different delimiter options are specified for different fields. Delimiter ‘|’ or ‘bar’ is used time parameters. The delimiter ‘~’ (‘tilda’) is used to assign parameters based on sex. The delimiter ‘;’ is the default and used in various contexts to split fields and patches parameters. The delimiter ‘:’ is used to split parameters used for functions. Note that Loo uses one instance of ‘;’ in an Hindex option. See CDMetaPOP manual for more specific uses and examples. 
#'
#' @param x Specify the file name and path.
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
#' This replicates the function 'unite' from tidyr which can actually be used :)
#'
#' @param x A data frame
#' @return Description of the returned value.
#' @export
unite_column <- function(dataframe, column_name, sep){
  if (!requireNamespace("tidyr", quietly = TRUE)) {
    message("The 'tidyr' package is not installed or loaded. Please install it using install.packages('tidyr') and load it using library(dplyr).")
    return(NULL)  # Exit if tidyr is not loaded
  }
  
  #  If tidyr is installed, check if it's loaded
  if (!"package:tidyr" %in% search()) {
    message("The 'tidyr' package is not loaded. Please load it using library(tidyr)")
    return(NULL)  # Exit the function if tidyr isn't loaded
  }
  my_new_column <- unite (dataframe, column_name, sep = sep)
}

