# set directory
setwd("~/anaconda3/envs/notebook/MHMetrics/work/")

# load libraries
library(tidyverse)
#library('readxl')
library("RPostgreSQL")
options("scipen" = 10)

# connect to postgres (remembert to turn it on)
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "mhmetrics",
                 host = "localhost", port = 5432,
                 user = "tbroderick")
# connect to aranalysis (for salaries)
#conar <- dbConnect(drv, dbname = "aranalysis",
#                   host = "localhost", port = 5432,
#                   user = "tbroderick")



# execute query
sql <- "SELECT count(*) FROM hospitals;"
dbGetQuery(con, sql)


write_csv(df,'csv/xxx.csv', na = '')

# disconnect
dbDisconnect(con)
dbUnloadDriver(drv)

