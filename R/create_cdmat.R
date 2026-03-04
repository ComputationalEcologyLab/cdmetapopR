
#' @title Create cost distance matrix for CDMetaPOP simulation
#'
#' @description Takes input coordinates and produces a symmetrical cost distance matrix with options for Euclidean distance, equal distance, or least cost paths based on a provided resistance surface
#'
#' @param coords A set of spatial coordinates in the form of a 2-column data frame or matrix
#' @param method Method for creating the cost distance matrix, must be "euclidean", "equal", or "lcp"
#' @param resistance Raster object representing resistance surface for generating cost distance matrix
#'
#' @details Hello
#'
#'
#' @import gdistance
#' @importFrom terra extract rast
#' @importFrom grDevices is.raster
#'
#' @return An NxN matrix of cost distances among patch locations
#'
#' @export
#'
#' @examples
#' x <- c(1,2,3,4,5,6)
#' y <- c(1,2,3,4,5,6)
#' test <- data.frame(x=x, y=y)
#' create_cdmat(coords=test)
#'
#' x <- runif(6, min=0, max=10)
#' y <- runif(6, min=0, max=10)
#' coords <- data.frame(x=x, y=y)
#' r <- terra::rast(nrows=10, ncols=10, xmin = 0, xmax = 10, ymin = 0, ymax = 10)
#' terra::values(r) <- 1
#' create_cdmat(coords=coords, method="lcp", resistance=r)

# Function reads in a 2-column set of coordinates and creates
# a distance matrix

create_cdmat <- function(coords, method=c("euclidean", "equal", "lcp"), resistance=NULL){

  # Check for correct arguments
  method <- match.arg(method)

  #Number of patches
  patchN <- dim(coords)[1]

  # Check that input is a two column data frame or matrix
  if(!is.data.frame(coords) && !is.matrix(coords)){
    stop("coords must be a 2-column data frame or matrix")
  }

  if(dim(coords)[2] != 2){
    stop("coords must be a 2-column data frame or matrix")
  }

  # Check for resistance raster and that coordinates fall inside raster extent
  if(!is.null(resistance)){
    if(!is.raster(resistance) && class(resistance)[1] != "SpatRaster"){
      stop("resistance surface must be a raster or SpatRaster (terra) object")
    }

    # extract values at coordinates
    extracted <- terra::extract(raster(resistance), coords)

    if(sum(extracted)<patchN){
      stop("Provided coordinates fall outside the resistance raster extent")
    }

    # Check that if a resistance matrix is provided, the method specified is least cost path
    if(method != "lcp"){
      stop("If using a resistance matrix, method must = 'lcp'")
    }

    if(method == "lcp" && is.null(resistance)){
      stop("If using least cost path method, a raster object representing resistance must be provided.")
    }
  }

    # Euclidean distance cost matrix
  if(method == "euclidean"){
    distmat <- dist(coords, method="euclidean", upper=TRUE, diag=TRUE)
  }

  # Cost matrix with equal probability to move to any patch
  if(method == "equal"){
    distmat <- matrix(1, nrow = patchN, ncol = patchN)
  }

  if(method == "lcp"){
    #Create transition matrix
    tr <- gdistance::transition(raster(resistance), function(x) 1/mean(x),8)
    tr <- gdistance::geoCorrection(tr, type="c")
    # Run least cost path
    distmat <- gdistance::costDistance(tr,as.matrix(coords))
    #Convert to symmetrical matrix with 0s on the diagonal
    distmat <- as.matrix(distmat)
  }

  message(paste0("Created ",patchN, "x", patchN," ", method, " cost distance matrix"))

  return(distmat)

}








