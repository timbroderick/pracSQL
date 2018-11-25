# set working directory

setwd("~/anaconda3/envs/pracSQL/Chapter_05_math")

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

# finding sum and average of columns
# " has a specific meaning in sql, ' does not

sql <- 'SELECT sum(p0010001) AS "County Sum",
round(avg(p0010001), 0) AS "County Average"
FROM us_counties_2010;'
dbGetQuery(con, sql)

# in R
# get the data
sql <-'SELECT p0010001 as "County" FROM us_counties_2010;'
df <- dbGetQuery(con, sql)
head(df)

# create an empty dataframe
empty <- data_frame(
  County_Sum=double(),
  County_Average=double(),
  County_Median=double(),
  County_Mode=double()
)

# if we want to find the mode, we need to create a function
getmode <- function(v) {
  uniqv <- unique(v)
  uniqv[which.max(tabulate(match(v, uniqv)))]
}

dfcalc <- rbind(empty, 
                data.frame(County_Sum = sum(df$County), 
                           County_Average = mean(df$County), 
                           County_Median = median(df$County), 
                           County_mode = getmode(df$County) 
                           ) )
dfcalc

# and we can check some of that with summary stats
summary(df)

# --------------------
# performing math on joining rows
# what we should see is the result of an inner join, which returns only those matching criteria
# state fips, county fips and where population is not the same
# returns only certain tables
# from 2010 table: geo_name, state, pop
# from 2000 table: pop
# raw_change and pct_change are calculated
# with pct_change rounded to 1 decimal

sql <- "
SELECT c2010.geo_name,
c2010.state_us_abbreviation AS state,
c2010.p0010001 AS pop_2010,
c2000.p0010001 AS pop_2000,
c2010.p0010001 - c2000.p0010001 AS raw_change,
round( (CAST(c2010.p0010001 AS numeric(8,1)) - c2000.p0010001)
/ c2000.p0010001 * 100, 1 ) AS pct_change
FROM us_counties_2010 c2010 INNER JOIN us_counties_2000 c2000
ON c2010.state_fips = c2000.state_fips
AND c2010.county_fips = c2000.county_fips
AND c2010.p0010001 <> c2000.p0010001
ORDER BY pct_change DESC;
"

df <- dbGetQuery(con, sql)

head(df)

# here's how we'd do that in R

library(tidyverse)

sql <- "
SELECT c2010.geo_name,
c2010.state_us_abbreviation AS state,
c2010.p0010001 AS pop_2010,
c2000.p0010001 AS pop_2000
FROM us_counties_2010 c2010 INNER JOIN us_counties_2000 c2000
ON c2010.state_fips = c2000.state_fips
AND c2010.county_fips = c2000.county_fips
AND c2010.p0010001 <> c2000.p0010001
"

df <- dbGetQuery(con, sql)

# Add the raw_change column
df$raw_change <- df$pop_2010 - df$pop_2000
# add the pct_change column
df$pct_change <-  round( ( (df$pop_2010 - df$pop_2000)/df$pop_2000 )* 100,1) 
# sort the df on pct_change
df <- arrange(df, desc(pct_change))

head(df)


# ---------------
# finally, disconnect
dbDisconnect(con)
dbUnloadDriver(drv)
