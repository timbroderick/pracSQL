# set directory
setwd("~/anaconda3/envs/pracSQL/")

# load libraries
library(tidyverse)
library("RPostgreSQL")
options("scipen" = 10)

# connect to postgres (remembert to turn it on)
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "aranalysis",
                 host = "localhost", port = 5432,
                 user = "tbroderick")

# execute a query 
sql <- ""
dbGetQuery(con, sql)



# disconnect
dbDisconnect(con)
dbUnloadDriver(drv)

