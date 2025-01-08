#' Counts number of individuals that move each year by reading in each ind file
#'
#' @param path Character. The path to the directory containing the output files.
#' @param run Integer. The run index. A run is each row of the RunVars file - Defaults to 0.
#' @param batch Integer. The batch index. See RunVars PreProcess Run parameters in the CDMetaPOP user manual.
#' @param mc Integer. The Monte Carlo index. It refers to the number of Monte Carlo simulations output files to examine. It refers to the mcruns option in the RunVars CDMetaPOP input file. It defaults to 0, which is one run.
#' @param gen Integer. The number of generations. Simulation run time (generation or year). Refers to runtime in the RunVars of CDMetaPOP input file. It defaults to 49.
#' @param species Integer. The species index. If the simulation includes multiple species. It defaults to 0, meaning one species only.
#' @param ind Logical. Whether to use ind files ('TRUE') or sample files ('FALSE').
#' @param plot Logical. If TRUE, a histogram of the proportion of movers across the ind file defined by the chosen parameters will be displayed. Defaults to FALSE. NOTE: The histogram of movers only reflects the counts for the given combination of parameters (not across all iterations).
#' @return A data frame with proportions of movers or a plot of the count of movers per year. The data returned is a dataframe that lists the proportion of dispersors for each year and for each Monte Carlo simulation.
#' @examples 
#' # Example: using the example directory provided in the package
#' my_output <- system.file("extdata/output_test1732137064/", package = "cdmetapop_R")
#' # Alternatively use a custom path:
#' my_output <- "/your_path/cdmetapop_R_package/inst/extdata/output_test1732137064/"
#' 
#' # Example: Run the function to output a dataframe for all the generations and replicas specified:
#'   dispersal (path = my_output, run = 1, batch = 0, mc = 2, gen = 9, species = 0, ind = FALSE, plot = FALSE)
#' 
#' # Example: Generating a barplot for the example directory
#' dispersal(path = my_output, run = 0, batch = 0, mc = 0, gen = 9, species = 1, ind = FALSE, plot = TRUE)
#' @export
#' @details 
#' This function was partially developed with assistance from ChatGPT, an AI model by OpenAI.

dispersal <- function (path = path, run = 0, batch = 0, mc = 0, gen = 49, species = 0, ind = TRUE, plot = FALSE) {
  
  # Initialize a matrix to store the data (if plot is FALSE)
  if(!plot) {
    dispersors_matrix <- matrix(data=NA, nrow=gen+1, ncol=(run+1)*(mc+1)*(batch+1)*(species+1))
  }
  
  # Initialize a data frame to store the data for the barplot (if plot is TRUE)
  if(plot) {
    dispersors <- data.frame(Year = 0:gen, movers = NA)
  }
  
  # Iterate through each run, mc, batch, species (if plot is FALSE)
  if(!plot) {
    for(m in 0:mc){ 
      for(b in 0:batch){ 
        for(s in 0:species){
          for(r in 0:run){ 
            for(g in 0:gen){ 
              
              # Check whether examining ind or sample files
              if(ind){
                mydata <- read.csv(paste0(path, "run", r, "batch", b, "mc", m, "species", s, "/ind", g, ".csv"))
              } else {
                mydata <- read.csv(paste0(path, "run", r, "batch", b, "mc", m, "species", s, "/indSample", g, ".csv"))
              }
              
              # Count of movers
              movers <- sum(mydata$CDist != -9999)
              
              # Calculate the proportion of movers in the current generation
              proportion_movers <- movers / nrow(mydata)
              
              # Store the results into the matrix
              dispersors_matrix[g + 1, (r + 1) * (m + 1) * (b + 1) * (s + 1)] <- proportion_movers 
            }
          }
        }
      }
    }
    
    # Generate a grid of names for column names
    combine_names <- expand.grid(run = 0:run, mc = 0:mc, batch = 0:batch, species = 0:species)
    
    # Assign column and row names
    colnames(dispersors_matrix) <- paste0("run", combine_names$run, 
                                          "batch", combine_names$batch, 
                                          "mc", combine_names$mc, 
                                          "species", combine_names$species)
    
    row.names(dispersors_matrix) <- c(paste0("Y", 0:gen))
    
    dispersors <- as.data.frame(dispersors_matrix)
    return(dispersors)
  }
  
  # If plot is TRUE, generate the barplot (only iterate through gen)
  for(g in 0:gen){ 
    
    # Check whether examining ind or sample files
    if(ind){
      mydata <- read.csv(paste0(path, "run", run, "batch", batch, "mc", mc, "species", species, "/ind", g, ".csv"))
    } else {
      mydata <- read.csv(paste0(path, "run", run, "batch", batch, "mc", mc, "species", species, "/indSample", g, ".csv"))
    }
    
    # Count of movers (where CDist is not -9999)
    movers <- sum(mydata$CDist != -9999)
    
    # Store the movers count in the dispersors data frame
    dispersors$movers[g + 1] <- movers
  }
  
  # Construct the title dynamically without spaces or colons
  dynamic_title <- paste0(
    "Movers_run", run, 
    "batch", batch, 
    "mc", mc, 
    "species", species
  )
  
  # Generate the barplot
  barplot(dispersors$movers, 
          names.arg = paste0("Y", 0:gen),  # Label the bars with years (Y0, Y1, ...)
          col = "blue", 
          xlab = "Year", 
          ylab = "Number of Movers", 
          main = dynamic_title,  # Use the dynamic title
          border = "white")  # Remove borders around bars
  
  # Return the dispersors data frame (with movers per year)
  return(dispersors)
}
