# stuff specific to dyndoc
## Not supposed to be used by the user

require(rb4R)

init.dynArray <- function() {
  local({
    # envir and not list to immediate sync in  "[[<-.dynArray"
		.dynArray<-list(vars=new.env())
		class(.dynArray)<-"dynArray"
	},globalenv())
}

"[[.dynArray" <- function(obj,key) {
  obj$vars[[key]]
}

"[[<-.dynArray" <- function(obj,key,value) {
  obj$vars[[key]] <- value
  #if(sync) { # Easily convertible to Julia!  
    # Clever: no need to convert ruby object in R object (done in the ruby part!)
    ##cat("sync",key,"\n")
    .rb(paste("Dyndoc::Vector[\"",key,"\"].sync(:r)",sep=""))
    #cat("sync",key,"\n")
  #}
  obj   
}

init.dynArray()