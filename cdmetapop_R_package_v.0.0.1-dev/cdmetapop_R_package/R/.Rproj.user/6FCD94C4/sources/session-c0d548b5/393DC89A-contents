#' This function counts the number of individuals that move each year by reading in each ind file
#'
#' @param path path to the simulation folder
#' @param mc integer referring to the number of montecarlo simulations output files to examine. It refers to the mcruns option in the RunVars CDMetaPOP input file. Right now it defaults to 0, which would be only one  run.
#' @param run A run is each row of the RunVars file - Fix description
#' @param gen Simulation run time (generation or year). Refers to runtime in the RunVars of CDMetaPOP input file. Currently defaults to 49
#' @param species If the simulation includes more species... The code for this needs to be adjusted. Right now, species = 0, means one species only and it is the default
#' @param ind If ind is true, the function will return calculations based on the ind files, otherwise on the sample files
#' @return a dataframe The data returned is a dataframe that lists the proportion of dispersors for each year and for each mc simulation
#' @examples 
#' define  your path to the output_test folder: mypath = "your_path/your_output_test/" For example "~/UM/CDMetaPop/EBT/EBT_Inputs/data/output_test1728487700/"
#' @export

dispersal <- function(path = path, run = 0, batch = 0, mc = 0, gen = 9, species = 0, ind = TRUE) {
  
  # Initialize a matrix to store the data
  dispersors_matrix <- matrix(data=NA, nrow=gen, ncol=mc+1)
  
  # Iterate through each ind 
  for(k in 0:mc){ 
    for(i in 0:gen){ 
    
    if(ind){
      mydata<-read.csv(paste0(path, "run",run,"batch",batch,"mc",k,"species",species,"/ind",i,".csv"))
    }  else {mydata<-read.csv(paste0(path, "run",run,"batch",batch,"mc",k,"species",species,"/indSample",i,".csv"))
      }
    
    movers <- sum(mydata$CDist != -9999) # Count of movers
    
    # calculate the proportion of movers in the current generation
    proportion_movers<- movers/nrow(mydata)
    
    # store the results into the matrix
    dispersors_matrix[i,k+1] <-proportion_movers 
  }
  }
  colnames(dispersors_matrix) <- paste0("MC", 0:mc)
  row.names(dispersors_matrix) <- c(paste0("Y",1:gen))
  
  dispersors <- as.data.frame(dispersors_matrix)
  return (dispersors)
}






