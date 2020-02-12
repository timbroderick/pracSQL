# set directory
setwd("~/Desktop/template")

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
sql <- "SELECT cms_id, fyear, system, prov_type, own_type, cbsa, urban_rural FROM descrip;"
df <- dbGetQuery(con, sql)

uniq <- unique(df$cms_id)

dfbind = data.frame()

for (u in uniq) {
  print(paste(u),quote=FALSE)
  getid <- filter(df, cms_id == u)
  dfget <- getid %>% 
    arrange(desc(fyear)) %>% 
    slice(1)
  dfbind <- rbind(dfbind,dfget)
}


write_csv(dfbind,'2_output/latest_descrip.csv', na = '')

# disconnect
dbDisconnect(con)
dbUnloadDriver(drv)

