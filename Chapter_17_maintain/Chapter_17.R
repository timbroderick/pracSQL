# set directory
setwd("~/anaconda3/envs/pracSQL/Chapter_17_maintain")

# load libraries
library(tidyverse)
#library('readxl')
library("RPostgreSQL")
options("scipen" = 10)

# connect to postgres (remembert to turn it on)
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "aranalysis",
                   host = "localhost", port = 5432,
                   user = "tbroderick")

# tracking table sizes
# create a table to view how changes change the size


sql <- "CREATE TABLE vacuum_test (
    integer_column integer
);"
dbGetQuery(con, sql)

# let's see how much space that takes up
sql <- "SELECT pg_size_pretty(
           pg_total_relation_size('vacuum_test')
);
"
dbGetQuery(con, sql)

# how about the database as a whole
sql <- "SELECT pg_size_pretty(
           pg_database_size('aranalysis')
);
"
dbGetQuery(con, sql)

# add data then check size
sql <- "INSERT INTO vacuum_test
SELECT * FROM generate_series(1,500000);"
dbGetQuery(con, sql)

sql <- "SELECT count(*) FROM vacuum_test;"
dbGetQuery(con, sql)


# 500,000 rows. How large is it
sql <- "SELECT pg_size_pretty(
           pg_total_relation_size('vacuum_test')
);"
dbGetQuery(con, sql)

# now make it larger and check again
sql <- "UPDATE vacuum_test
SET integer_column = integer_column + 1;"
dbGetQuery(con, sql)

# How large is it
sql <- "SELECT pg_size_pretty(
pg_total_relation_size('vacuum_test')
);"
dbGetQuery(con, sql)

# even though the number of rows is the same and the updated values insignificant, 
# the database has doubled due to the dead rows

# check autovacuum activity
sql <- "SELECT relname,
       last_vacuum,
last_autovacuum,
vacuum_count,
autovacuum_count
FROM pg_stat_all_tables
WHERE relname = 'vacuum_test';
"
dbGetQuery(con, sql)


sql <- "VACUUM vacuum_test;"
dbGetQuery(con, sql)

# vacuum designates dead rows but doesn't remove them
# vacuum full returns the dead rows back to the disk
sql <- "VACUUM FULL vacuum_test;"
dbGetQuery(con, sql)

sql <- "SELECT relname,
       last_vacuum,
last_autovacuum,
vacuum_count,
autovacuum_count
FROM pg_stat_all_tables
WHERE relname = 'vacuum_test';
"
dbGetQuery(con, sql)

sql <- "SELECT pg_size_pretty(
pg_total_relation_size('vacuum_test')
);"
dbGetQuery(con, sql)


# and the size is back to 17 mb


# disconnect
dbDisconnect(con)
dbUnloadDriver(drv)

