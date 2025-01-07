#' Function to create a plot of size at age overtime
#'
#' This function plots the overtime average size of individuals at a specific age. It is based on the AgeSize_mean columns of the CDMetaPOP output file summary_classAllTime
#'
#' @param x Specify the path to the summary_popAllTime.csv dataframe
#' @return a ggplot object representing the overtime average sizes of the individuals in the simulation separated by age. 
#' @import ggplot2
#' @import reshape2
#' @export

size_age_class <- function(file_path) {
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
  
  namevec <- colnames(my_data)
  data <- data.frame(as.integer(my_data[,1]))
  colnames(data) <- namevec[1]
  
  for(i in 2:length(namevec)){
    tmp <- read.table(text = my_data[,i], sep = "|")
    tmp2 <- paste (namevec[i], seq_len(ncol(tmp)), sep = "_")
    colnames(tmp) <- tmp2
    data <- cbind(data, tmp)
    rm(tmp, tmp2)
  }
  
  if (!"package:ggplot2" %in% search()) {
    message("The 'ggplot2' package is not loaded. Please load it using library(ggplot2)")
    return(NULL)  # Exit the function if ggplot2 isn't loaded
  }
  df <- t(data[, grep("^AgeSize_Mean", colnames(data))])
  colnames(df) <- data$Year
  rownames(df) <- paste("age", 1:nrow(df), sep = "")
  df.melted <- melt(df, id = "x")
  colnames(df.melted) <- c("Ages", "Year", "Size")
  p <- ggplot(data = df.melted, aes(x = Year, y = Size, color = Ages)) +
    #geom_bar(position = "dodge", stat = "identity")+
    geom_line(linewidth = .8)+
    geom_point(size = 2)
    labs(title = "Size by age class",
         x = "Year",
         y = "Size")+
  theme_minimal()
  return(p)
}

