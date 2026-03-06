#' Function to facilitate the running of CDMetaPOP software from R
#' @description Function to run CDMetaPOP from R
#' 
#' @param pythonFilepath Location of Python executable, or just 'python' if the environment is already established
#' @param CDMetaPOPFilepath Location of the CDMetaPOP.py file, if already in the working directory then this can just be 'CDMetaPOP.py'
#' @param runvarsDirectory Location of the directory where the RunVars.csv file is stored for the run
#' @param runvarsFilename Name of the RunVars file to run
#' @param outputDirectory Name of output directory to be stored in the same location as runvarsDirectory
#' 
#' @details This function will launch a command prompt (Windows) or terminal (Linux/Mac) that will call Python and supply the 5 arguments needed to launch CDMetaPOP simulations
#' 
#' @export
#' 
#' @examples
#' pythonFilepath="C:/Users/User1/anaconda3/python.exe" 
#' CDMetaPOPFilepath="C:/Users/User1/CDMetaPOP_v3.03/src/CDMetaPOP.py"
#' runvarsDirectory = "C:/Users/User1/CDMetaPOP_v3.03/example_files/"
#' runvarsFilename = "RunVars.csv"
#' outputDirectory = "test_" 
#'
#' mymodel <- launch_cdmetapop(pythonFilepath,
#'                            CDMetaPOPFilepath,
#'                            runvarsDirectory,
#'                            runvarsFilename,
#'                            outputDirectory = "test_")
#' 


launch_cdmetapop <- function(pythonFilepath = python,
                             CDMetaPOPFilepath = "CDMetaPOP.py",
                             runvarsDirectory = NULL,
                             runvarsFilename = "RunVars.csv",
                             outputDirectory = "test_"
){
  if(.Platform$OS.type == "windows"){
    shell(paste(pythonFilepath, CDMetaPOPFilepath, runvarsDirectory, runvarsFilename, outputDirectory, "& pause"),
          invisible=FALSE, wait=FALSE)
  } else{
    system(paste(pythonFilepath, CDMetaPOPFilepath, runvarsFilename, runVars, 
                 outputDirectory, "; read -p 'Press enter to continue'"), wait=FALSE)
  }
}
