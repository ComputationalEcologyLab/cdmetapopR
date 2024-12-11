#' This function counts the number of individuals that move each year by reading in each ind file
#'
#' @param path path to the simulation folder
#' @param mc integer referring to the number of montecarlo simulations output files to examine. It refers to the mcruns option in the RunVars CDMetaPOP input file. Right now it defaults to 0, which would be only one  run.
#' @param run A run is each row of the RunVars file - Fix description
#' @param gen Simulation run time (generation or year). Refers to runtime in the RunVars of CDMetaPOP input file. Currently defaults to 49
#' @param species If the simulation includes more species...  It defaults to species = 0, which means one species only 
#' @param batch see RunVars PreProcess Run parameters in cdmetapop user manual
#' @param ind If ind is true, the function will return calculations based on the ind files, otherwise on the sample files
#' @return a dataframe The data returned is a dataframe that lists the proportion of dispersors for each year and for each mc simulation
#' @examples 
#' define  your path to the output_test folder: mypath = "your_path/your_output_test/" For example "~/UM/CDMetaPop/EBT/EBT_Inputs/data/output_test1728487700/"
#' @export

dispersal <- function(path = path, run = 0, batch = 0, mc = 0, gen = 49, species = 0, ind = TRUE) {
  
  # Initialize a matrix to store the data
  dispersors_matrix <- matrix(data=NA, nrow=gen+1, ncol=(run+1)*(mc+1)*(batch+1)*(species+1))
  
  # Iterate through each ind 
  for(m in 0:mc){ 
  for(b in 0: batch){ 
    for(s in 0:species){
      for(r in 0:run){ 
    for(g in 0:gen){ 
    
  # check whether examining ind or sample files
    if(ind){
      mydata<-read.csv(paste0(path, "run",r,"batch",b,"mc",m,"species",s,"/ind",g,".csv"))
    }  else {mydata<-read.csv(paste0(path, "run",r,"batch",b,"mc",m,"species",s,"/indSample",g,".csv"))
      }
  # Count of movers
    movers <- sum(mydata$CDist != -9999 )
    
    
  # calculate the proportion of movers in the current generation
    proportion_movers<- movers/nrow(mydata)
    
  # store the results into the matrix
    dispersors_matrix[g+1,(r+1)*(m+1)*(b+1)*(s+1)] <-proportion_movers 
  }
  }
  }
  }
  }
  # generate a grid of names
  combine_names <- expand.grid(run = 0:run, mc = 0:mc, batch = 0:batch, species = 0:species)
  
  # assign column and row names 
  colnames(dispersors_matrix) <- paste0("run", combine_names$run, 
                                        "batch", combine_names$batch, 
                                        "mc", combine_names$mc, 
                                        "species", combine_names$species)
  
  row.names(dispersors_matrix) <- c(paste0("Y",0:gen))
  
  dispersors <- as.data.frame(dispersors_matrix)
  
  return (dispersors)
}






