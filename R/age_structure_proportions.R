#' Determine the proportions of the age structure of the population
#'
#' This function summarizes the proportions of the age structure in the simulated population. It is calculated counting the values in the column 'age' of the chosen 'ind' generation. 
#'
#' @param path path to the simulation folder
#' @param runs integer referring to the number of montecarlo simulations output files to examine. It refers to the mcruns option in the RunVars CDMetaPOP input file. Right now it defaults to 1, which would be only one montecarlo run.
#' @param gen Simulation run time (generation or year). Refers to runtime in the RunVars of CDMetaPOP input file. Currently defaults to 49.
#' @param species If the simulation includes more species... The code for this needs to be adjusted
#' @return a dataframe with a  column for each montecarlo run (MC) with the proportion of the population for each given age (in rows) and the last column with the average value across all montecarlo runs at any given age. 
#' @examples
#' mypath <- system.file("extdata", "Example_dat", package = "cdmetapopR")
#' age_structure_proportions(path = paste0(mypath, "/"), runs = 1, gen = 9)
#' @export

age_structure_proportions <- function(path = system.file("extdata", "Example_dat", package = "cdmetapopR"), runs = 1, gen = 49, species = 0) {

  foo<-read.csv(paste0(path, "run0batch0mc",runs-1,"species",species,"/ind",gen,".csv"))

  # calculate how many inds are of age + 1
  tot <- sum(foo$age>1)

  # count how many age classes there are
  count_age <- length(unique(foo$age))

  # Initialize a matrix to store the data
  age.structure <- matrix(data=NA, nrow=count_age, ncol=runs+1)

  # Iterate through each element of the vector
  for (i in 1:count_age){

  # calculate the percentage of individuals at each age over the total
  temp<- sum(foo$age==i)/tot
  
  # store the results into the matrix
 age.structure[i,runs] <- temp 
}

age.structure[,runs+1] <- rowMeans(age.structure, na.rm=T)

colnames(age.structure) <- c(paste0("MC", runs), "Avg")
row.names(age.structure) <- c(paste0("Age",1:count_age))

age.structure

}
