#' Create abundance by year plot
#'
#' This function plots population dynamics overtime showing a count of the individuals over the years of the simulation. It is based off the N_Initial column of the CDMetaPOP output file summary_popAllTime
#'
#' @param dataframe Import the summary_popAllTime.csv dataframe
#' @import ggplot2
#' @import reshape2
#' @importFrom utils read.table
#' @return a ggplot object representing the overtime general population size
#' @examples
#' path <- system.file("extdata", "summary_popAllTime.csv", package = "cdmetapopR")
#' data <- read.csv(path)
#' pop_count_plot(data)
#' @export


pop_count_plot <- function(data) {
  mydata<-read.table(text = data$N_Initial, sep = "|")  
  mydata_1 <- mydata[,1]
  mydf <- data.frame(cbind (data$Year, mydata_1))
  colnames(mydf)<-c("Year", "N_Initial_1")
  # Create the plot
  p <- ggplot(mydf, aes(x = as.numeric(Year), y = as.numeric(N_Initial_1))) +
    geom_line() +
    labs(title = "Population Size Timeseries",
         y = "Population Size",
         x = "Year")
  return(p)
}


#' Create abundance by year plots for the different sex - Male/Female/MYY/FYY
#'
#' This function plots population dynamics overtime showing the count of the individuals separated by sex over the years of the simulation. It is based off the following columns: N_Males_1, N_YYMales_1, N_Females_1 and N_YYFemales of the CDMetaPOP output file summary_popAllTime
#'
#' @param dataframe Import the summary_popAllTime.csv dataframe
#' @return a ggplot object representing the overtime  population size for the four sexes
#' @import ggplot2
#' @importFrom utils read.table
#' @importFrom tidyr pivot_longer
#' @examples
#' path <- system.file("extdata", "summary_popAllTime.csv", package = "cdmetapopR")
#' data <- read.csv(path)
#' pop_sex_plot(data)
#' @export

pop_sex_plot <- function(data) {

  N_males<-read.table(text = data$N_Males, sep = "|")  
  N_Males_1 <- N_males[,1]
  N_females<-read.table(text = data$N_Females, sep = "|")  
  N_Females_1 <- N_females[,1]
  N_yymales<-read.table(text = data$N_YYMales, sep = "|")  
  N_YYMales_1 <- N_yymales[,1]
  N_YYfemales<-read.table(text = data$N_YYFemales, sep = "|")  
  N_YYFemales_1 <- N_YYfemales[,1]
  
  sex_df <- data.frame(cbind (data[,1], N_Males_1, N_YYMales_1, N_Females_1, N_YYFemales_1))
  colnames(sex_df) <- c("Year", "Wild-males", "YYMales", "Wild-females", "YYFemales")
  
  # Reshaping the data
  long_data <- pivot_longer(sex_df, 
                            cols = c("Wild-males", "YYMales", "Wild-females", "YYFemales"), 
                            names_to = "category", 
                            values_to = "value")
  
  # Create the plot
p<- ggplot(long_data, aes(x = as.numeric(Year), y = as.numeric(value))) +
    geom_line() +  
    facet_wrap(~ category) +
    labs(title = "Population sizes by sex",
         x = "Year",
         y = "Population Size")
  
  return(p)
}
  
#' Create abundance by year plot showing the numbers of mature individuals of all sexes
#'
#' This function plots population dynamics overtime showing a count of the mature individuals over the years of the simulation separated by their sex. It is based off the N_Mature columns of the CDMetaPOP output file summary_popAllTime
#'
#' @param x Specify the path to the summary_popAllTime.csv dataframe
#' @import ggplot2
#' @importFrom utils read.table
#' @importFrom tidyr pivot_longer
#' @return a ggplot object representing the overtime population size of sexually mature individuals
#' @examples
#' path <- system.file("extdata", "summary_popAllTime.csv", package = "cdmetapopR")
#' pop_mature_plot(path)
#' @export

pop_mature_plot <- function(file_path) {
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
  
  mature_df <- data.frame(cbind (data[,1], data$N_MatureFemales_1, data$N_MatureMales_1, data$N_MatureYYMales_1,data$N_MatureYYFemales_1))
  colnames(mature_df) <- c("Year", "Mature Wild-females", "Mature Wild-males", "Mature YYMales", "Mature YYFemales")
  
  # Reshaping the data
  long_data <- pivot_longer(mature_df, 
                            cols = c("Mature Wild-females", "Mature Wild-males", "Mature YYMales", "Mature YYFemales"), 
                            names_to = "category", 
                            values_to = "value")
  
  # Create the plot
  p<- ggplot(long_data, aes(x = Year, y = value)) +
    geom_line() +  
    facet_wrap(~ category) +
    labs(title = "Population sizes of Mature individual separated by sex",
         x = "Year",
         y = "Population Size")
  
  return(p)
}

#' Create a plot with the proportion of young of the year. Note here that this proportion includes only age 0 progeny that survived egg mortality.
#'
#' This function plots the proportion of progeny over the total, after egg deaths are taken into account
#'
#' @param x Specify the path to the summary_popAllTime.csv dataframe
#' @importFrom utils read.table
#' @return a ggplot object representing the size of progeny surviving egg deaths every year
#' @examples
#' path <- system.file("extdata", "summary_popAllTime.csv", package = "cdmetapopR")
#' births(path)
#' @export


births <- function(file_path){
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
  
  births_df <- data.frame(cbind (data[,1], data$Births_1-data$EggDeaths_1))
  colnames(births_df) <- c("Year", "Births")
 
 
  # Create the plot
  p<- ggplot(births_df, aes(x = Year, y = Births)) +
    geom_line() +  
    labs(title = "Progeny by Year",
         x = "Year",
         y = "Progeny")
  
  return(p)
}

#' Plot the proportion of exclusive Myy progeny over the total 
#'
#' This function plots the ratio of the Myy progeny overtime 
#'
#' @param x Specify the path to the summary_popAllTime.csv dataframe
#' @importFrom utils read.table
#' @examples
#' path <- system.file("extdata", "summary_popAllTime.csv", package = "cdmetapopR")
#' myy_progeny_plot(path)
#' @return a ggplot object representing the overtime progeny size of YYMales
#' @export

myy_progeny_plot <- function(file_path) {
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
  
  # if (!"package:ggplot2" %in% search()) {
  #   message("The 'ggplot2' package is not loaded. Please load it using library(ggplot2)")
  #   return(NULL)  # Exit the function if ggplot2 isn't loaded
  }
  
  #calculate proportion of exclusive Myy progeny over the total, after egg deaths are taken into account
  yy_progeny_ratio <- data$MyyProgeny_1/(data$Births_1 - data$EggDeaths_1)
  
  # make a new dataframe with the myy progeny information
  progeny <- data.frame (data$Year, data$Births_1, data$EggDeaths_1,data$MyyProgeny_1, yy_progeny_ratio)
  colnames(progeny) <- c("Year", "Births", "EggDeaths", "MyyProgeny", "MyyProgeny_ratio")
   
  # Create the plot
  p<- ggplot(progeny, aes(x = Year, y = MyyProgeny_ratio)) +
    geom_line() +  
    labs(title = "Myy Progeny ratio",
         x = "Year",
         y = "Proportion of MYY Young of the Year")
  
  return(p)
}

#' Create abundance by year for each age class
#'
#' This function plots population dynamics overtime according by the age of the individuals. It shows the count of the individuals over the years of the simulation separated by age. It is based off the N_Initial_Class column of the CDMetaPOP output file summary_classAllTime
#'
#' @param x Specify the path to the summary_classAllTime.csv dataframe
#' @param n An integer that specifies the time intervals of the time series. It defaults to 5 years.
#' @importFrom utils read.table
#' @return a ggplot object representing the  general population size at 5 years intervals for the different age classes. 
#' @examples
#' path <- system.file("extdata", "summary_classAllTime.csv", package = "cdmetapopR")
#' pop_year_class(path, n = 2)

#' @export

pop_year_class <- function(file_path, n = 5) {
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
  df <- t(data[, grep("^N_Initial_Class", colnames(data))])
  colnames(df) <- data$Year
  rownames(df) <- paste("age", 1:nrow(df), sep = "")
  df.melted <- melt(df, id = "x")
  colnames(df.melted) <- c("Ages", "Year", "N_Initial_Class")
  # Filter the data to include every 'n' years
  df_filtered <- df.melted[df.melted[["Year"]] %% n == 0, ]
  p <- ggplot(data = df_filtered, mapping = aes(x = Year, y = N_Initial_Class, fill = Ages)) +
    geom_bar(position = "dodge", stat = "identity")+
    labs(title = "Population size by age class",
         x = "Year",
         y = "Population Size")
  
  return(p)
}
 
#' Create abundance by patch plot
#'
#' This function plots the population abundance per Patch. It is based off the N_Initial column of the CDMetaPOP output file summary_popAllTime. 
#'
#' @param dataframe summary_popAllTime.csv dataframe
#' @param years vector of values referring to the years to select. It defaults to c(1,25,50,100)
#' @return a ggplot boxplot showing the population numbers of different patches
#' @import ggplot2
#' @importFrom utils read.table
#' @importFrom tidyr pivot_longer
#' @examples
#' path <- system.file("extdata", "summary_popAllTime.csv", package = "cdmetapopR")
#' data <- read.csv(path)
#' pop_patch_count(data, years = c(0,2,4,8))
#' @export

pop_patch_count <- function(data, years = c(1,25,50,100)) {
  abundance <- read.table(text = data$N_Initial, sep = "|")
  colnames(abundance) <- c("pop", paste("patch", seq_len(ncol(abundance)-1), sep = ""))
  abundance <-cbind(1:nrow(abundance), abundance [,-1])
  colnames(abundance)[1] <- "Year"
  patch_columns <- colnames(abundance)[2:ncol(abundance)]
  df.melted <- abundance %>%
    pivot_longer(cols = starts_with("patch"), names_to = "Patch", values_to = "Value")
  colnames(df.melted) <- c("Year", "Patch", "Abundance")
  df.filtered <- df.melted %>%
    dplyr::filter(Year %in% years)
  
  # Plot
  p<- ggplot(df.filtered, aes(x = as.factor(Year), y = Abundance)) +
    geom_boxplot(fill = "steelblue") +  # Use a single color
    theme_minimal() +
    labs(x = "Year", y = "Abundance", title = "Patch Population by Year")
return(p)
}

#' Check which patch(es) went extinct (no more individuals left) at a particular year
#'
#' This function produces a vector with the number of patches that suffered extinction at a given year. It is based off the N_Initial column of the CDMetaPOP output file summary_popAllTime. 
#' @param dataframe summary_popAllTime.csv dataframe
#' @param year value referring to the year to select. It defaults to 100
#' @importFrom utils read.table
#' @return integer vector
#' @examples
#' path <- system.file("extdata", "summary_popAllTime.csv", package = "cdmetapopR")
#' data <- read.csv(path)
#' extinct_patch(data, year = 8)
#' @export

extinct_patch <- function(data, year = 100) {
  abundance <- read.table(text = data$N_Initial, sep = "|")
  colnames(abundance) <- c("pop", paste("patch", seq_len(ncol(abundance)-1), sep = ""))
  abundance <-cbind(1:nrow(abundance), abundance [,-1])
  colnames(abundance)[1] <- "Year"
  patch_columns <- colnames(abundance)[2:ncol(abundance)]
  extinct <- which(abundance[year,]== 0)
return(extinct)  
}

#' Function to extract  population sizes of age +1 individuals
#'
#' This function produces a  plot with population sizes of age 1+ individuals. It is based on the N_Initial_class column of the CDMetaPOP output file summary_classAllTime. 
#' @param dataframe summary_classAllTime.csv dataframe
#' @importFrom utils read.table
#' @examples
#' path <- system.file("extdata", "summary_classAllTime.csv", package = "cdmetapopR")
#' data <- read.csv(path)
#' age_plus_one_plot(data)
#' @return ggplot
#' @export

age_plus_one_plot <- function(data){
  age_class <- read.table(text = data$N_Initial_Class, sep = "|")
  aged <-  data.frame (data$Year, rowSums(age_class[,c(3:ncol(age_class))], na.rm = TRUE))
  colnames(aged) <- c("Year","Pop")
  p <- ggplot(aged, aes(x = Year, y = Pop)) +
  geom_line() +
  labs(title = "Population Size of +1 individuals",
       y = "+1 Population Size",
       x = "Year")
return(p)
}