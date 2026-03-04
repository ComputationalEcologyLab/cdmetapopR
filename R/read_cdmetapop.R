#' Read cdmetapop file as dataframe 
#'
#' This function imports in r a cdmetapop output file as a dataframe
#'
#' @param x Specify the file name and path.
#' @importFrom utils read.table
#' @return Dataframe
#' @export
read.cdmetapop <- function(file_path) {
  
  # Read the file
  mydata <- read.csv(file_path)
  
  #Read the column names from the file
  mycolumn_names <- read.table(file_path, 
                               nrows = 1, 
                               colClasses = 'character', 
                               header = FALSE, 
                               sep = ",")
  
  #Read the dataframe from the file 
  mydata <- read.table(file_path, 
                       sep = ",", 
                       stringsAsFactors = FALSE,
                       colClasses = "character",
                       skip = 1)
  
  colnames(mydata) <- mycolumn_names   
  
  # Return the file as a dataframe
  return(mydata)
}
  