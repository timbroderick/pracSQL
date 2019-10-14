library(tidyverse)


sayhi <- function(myStringOrVector) {
  print(paste("Hello", myStringOrVector, length(myStringOrVector) ) )
}

sayhi("Geoff")
sayhi(c("Geoff", "Sharon"))


