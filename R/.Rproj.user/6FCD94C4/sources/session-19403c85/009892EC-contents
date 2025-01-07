#' Create heterozygosity plot
#'
#' This function plots heterozygosity overtime. It is based on the Ho and He columns of the CDMetaPOP output file summary_popAllTime
#' @import ggplot2
#' @param x dataframe summary_popAllTime.csv 
#' @return a ggplot object representing the overtime observed and expected heterozygosities values in the simulation. 
#' @export

hets_plot <- function(data) {
  He<-read.table(text = data$He, sep = "|")  
  He_1 <- He[,1]
  Ho <- read.table(text = data$Ho, sep = "|")
  Ho_1 <- Ho[,1]
  het_df <- data.frame(cbind (data$Year, He_1, Ho_1))
    colnames(het_df) <- c("Year", "He", "Ho")
    
    # Reshaping the data
    long_data <- pivot_longer(het_df, 
                              cols = c("He", "Ho"), 
                              names_to = "category", 
                              values_to = "value")
    
    # Create the plot
    p<- ggplot(long_data, aes(x = as.numeric(Year), y = as.numeric(value))) +
      geom_line() +  
      facet_wrap(~ category) +
      labs(title = "Expected vs Observed Heterozygosity",
           x = "Year",
           y = "Heterozygosity")
    return(p)
}

#' Function extracts and plots allele count overtime
#'
#' This function plots the total number of unique alleles for every year of the simulation. It is based on the Allele column of the CDMetaPOP output file summary_popAllTime
#'
#' @param dataframe summary_popAllTime.csv 
#' @param n An integer that specifies the time intervals of the time series. It defaults to 5 years. 
#' @import ggplot2 
#' @import dplyr
#' @return a ggplot object representing the overtime observed and expected heterozygosities values in the simulation. 
#' @export
alleles_by_year <- function(data, n = 5){
  alleles<-read.table(text = data$Alleles, sep = "|")
  allele_names <- paste ("Allele", seq_len(ncol(alleles)), sep = "_")
  colnames(alleles) <- paste("allele", seq_len(ncol(alleles)-1), sep = "")
  alleles$Year <-  1:nrow(alleles)
  allele_columns <- grep("allele", names(alleles), value = TRUE)
  alleles.melted <- reshape2::melt(alleles, measure.vars = allele_columns,  id.vars = "Year")
  colnames(alleles.melted) <- c("Year", "Alleles", "Allele_number")
  # Filter the data to include every 'n' years
  alleles.melted_filtered <- alleles.melted[alleles.melted[["Year"]] %% n == 0, ]
  allele_count <- alleles.melted_filtered %>%
    group_by(Year) %>%
    summarize(allele_count = sum(Allele_number))
  p <- ggplot(allele_count, aes (x = Year, y = allele_count)) +
    geom_bar(stat = "identity", fill = "steelblue") + 
    labs(title = "Total Number of Unique Alleles by Year", x = "Year", y = "Unique allele count")+
    theme_minimal()
  return(p)
}

