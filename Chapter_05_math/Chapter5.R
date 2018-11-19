# set working directory

setwd("~/anaconda3/envs/pracSQL/Chapter_05")

library("RPostgreSQL")
#https://www.r-bloggers.com/getting-started-with-postgresql-in-r/

# loads the PostgreSQL driver
drv <- dbDriver("PostgreSQL")
# creates a connection to the postgres database
con <- dbConnect(drv, dbname = "aranalysis",
                 host = "localhost", port = 5432,
                 user = "tbroderick")#, password = pw)

# let's see if we can get these math operators out of sequel 

sql <- "SELECT 2 + 2;"
dbGetQuery(con, sql)

# and in R

2+2

# very cool. Let's do some math

#Integer division
sql <- "SELECT 11/6;"
dbGetQuery(con, sql)
# answer is 1
# and in R
11%/%6

# modulo division - returns the remainder
sql <- "SELECT 11%6;"
dbGetQuery(con, sql)
# answer is 5 (because 6+5 is 11)
# and in R
11%%6

# decimal division
sql <- "SELECT 11.0 / 6;"
dbGetQuery(con, sql)
# in R
11/6

# In SQL, at least one of the numbers needs to be a numeric,
# or a non-integer
# alternatively, use CAST to change 11 

sql <- "SELECT CAST(11 AS numeric(3,1)) / 6;"
dbGetQuery(con, sql)

# exponentiation
sql <- "SELECT 3 ^ 4;"
dbGetQuery(con, sql)
# in R
3 ^ 4
# 3 x 3 x 3 x 3 is 81

# square root (operator)
sql <- "SELECT |/ 9;"
dbGetQuery(con, sql)
# in R
sqrt(9)
# because 3 x 3 is 9

# square root (function)
sql <- "SELECT sqrt(10);"
dbGetQuery(con, sql)
# returns pie

# cube root
sql <- "SELECT ||/ 10;"
dbGetQuery(con, sql)
# in R, no native function?
27^(1/3)
# the cube root of 27 is 3 (3x3x3)

# factorial
sql <- "SELECT 4 !;"
dbGetQuery(con, sql)
# in R
factorial(4)
# 1 x 2 x 3 x 4 = 24
factorial(5)
# 1 x 2 x 3 x 4 X 5 = 120

# ---------------
# finally, disconnect
dbDisconnect(con)
dbUnloadDriver(drv)
