#' Deprecated 'locus' function from gstudio
#'
#' This function is a copy of the deprecated locus function from the `gstudio` package.
#' It has been included in this package because `gstudio` is no longer maintained.
#'
#' @note This function is provided as-is, without guarantees of future updates.
#'       Users are encouraged to transition to more modern alternatives if available.
#'
#' @source The original implementation is from the `gstudio` package 
#'         (\url{https://github.com/dyerlab/gstudio}).
#'
#' @section Deprecated:
#' This function is deprecated and may be removed in future versions of this package.
#' Users will see a warning message if this function is called.
#'
#' @examples
#' \dontrun{
#'   # Example usage
#'   result <- locus(c("0", "1"), type = "snp")
#' }
#'
#' @keywords internal
#' @export
locus <- function( x, type="codom", phased=FALSE ){
  
  # missing data
  if(  (missing(x) || all(is.na(x)) ) ) {
    ret <- ""
  }
  
  # default, sort and collapse em.
  else if( type=="codom" ) {  
    ret <- as.character(x)
    if( any(nchar(ret))) {
      if( !phased )
        ret <- as.character(sort(x))
      ret <- paste(ret,collapse=":")
      if( ret == "NA:NA")
        ret <- ""
    }
  }
  
  # aflp
  else if( type == "aflp" ){
    if( length(x) > 1 ) 
      ret <- unlist(lapply(x,function(x) locus(as.character(x),type="aflp"))) 
    else if( !(x %in% c("0","1")) )
      ret <- ""
    else
      ret <- x
  }
  
  else if( type == "snp"){
    if( length(x) > 1 )
      ret <- unlist(lapply(x,function(x) locus(as.character(x),type="snp")))
    else 
      ret <- switch( as.character(x),"0"=c("A:A"),"1"=c("A:B"),"2"=c("B:B"),"")
  }
  
  # column types
  else if( type == "column") 
    ret <- apply( x, 1, function(x) locus(as.character(x), phased=phased))
  
  else if( type == "separated" ) {
    if( length(x) > 1)
      ret <- unlist(lapply(x,function(x) locus(x)))
    else {
      if( x == "NA:NA" || x == "NA")
        ret <- ""
      else 
        ret <- locus( strsplit( x, split=":")[[1]], phased=phased)
    }
  } 
  
  else if( type == "zyme" ){
    if( length(x) > 1 )
      ret <- unlist( lapply(x, function(x) locus(x,type="zyme") ) )
    else {
      N <- nchar(x)
      n <- N/2
      l <- substr(x,1,n)
      r <- substr(x,(n+1),N)
      ret <- apply(cbind(l,r),MARGIN=1,FUN=locus)      
    }
  }
  
  class(ret) <- "locus"
  return(ret)
}
