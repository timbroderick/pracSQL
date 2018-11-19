# set working directory

setwd("~/anaconda3/envs/pracSQL/Chapter_06_joining")

library("RPostgreSQL")
#https://www.r-bloggers.com/getting-started-with-postgresql-in-r/

# loads the PostgreSQL driver
drv <- dbDriver("PostgreSQL")
# creates a connection to the postgres database
con <- dbConnect(drv, dbname = "aranalysis",
                 host = "localhost", port = 5432,
                 user = "tbroderick")#, password = pw)

# create two tables to explore join types
# --------------------
# left join table

sql <- "CREATE TABLE schools_left (
  id integer CONSTRAINT left_id_key PRIMARY KEY,
  left_school varchar(30)
);"

dbGetQuery(con, sql)

sql <- "INSERT INTO schools_left (id, left_school) VALUES
(1, 'Oak Street School'),
(2, 'Roosevelt High School'),
(5, 'Washington Middle School'),
(6, 'Jefferson High School');"

dbGetQuery(con, sql)

# --------------------
# right join table
sql <- "CREATE TABLE schools_right (
    id integer CONSTRAINT right_id_key PRIMARY KEY,
right_school varchar(30)
);"

dbGetQuery(con, sql)

sql <- "INSERT INTO schools_right (id, right_school) VALUES
    (1, 'Oak Street School'),
(2, 'Roosevelt High School'),
(3, 'Morrison Elementary'),
(4, 'Chase Magnet Academy'),
(6, 'Jefferson High School');"

dbGetQuery(con, sql)

# --------------------
# one to one or an INNER JOIN
# returns only lines from either table that match
# otherwise known as a one to one join

sql <- "SELECT *
FROM schools_left JOIN schools_right
ON schools_left.id = schools_right.id;"

df <- dbGetQuery(con, sql)

head(df)

# --------------------
# left join. Returns all the items from the left table
# and only those from the right table that match
sql <- "SELECT *
FROM schools_left LEFT JOIN schools_right
ON schools_left.id = schools_right.id;"

df <- dbGetQuery(con, sql)

head(df)

# --------------------
# right join. opposite of left join
sql <- "SELECT *
FROM schools_left RIGHT JOIN schools_right
ON schools_left.id = schools_right.id;"

df <- dbGetQuery(con, sql)

head(df)

# --------------------
# full outer join
# returns all lines from either table, with those that can be matched
sql <- "SELECT *
FROM schools_left FULL OUTER JOIN schools_right
ON schools_left.id = schools_right.id;"

df <- dbGetQuery(con, sql)

head(df)

# --------------------
# cross join
# not really sure what the purpose of this is

sql <- "SELECT *
FROM schools_left CROSS JOIN schools_right;"

df <- dbGetQuery(con, sql)

head(df)

# --------------------
# using null to find missing values, or unmatched items

sql <- "SELECT *
FROM schools_left LEFT JOIN schools_right
ON schools_left.id = schools_right.id
WHERE schools_right.id IS NULL;"

df <- dbGetQuery(con, sql)

head(df)

# --------------------
# selecting specific columns
sql <- "SELECT schools_left.id,
       schools_left.left_school,
schools_right.right_school
FROM schools_left LEFT JOIN schools_right
ON schools_left.id = schools_right.id;"

df <- dbGetQuery(con, sql)

head(df)

# --------------------
# other types of joins 
# one to many, where one value in a table can be matched with multiple values in another
# and many to many, where there are multiple matches on either side

# --------------------
# now, doing joins in R
library(tidyverse)
# first read in the data from CSVs
schools_left <- read.csv("schools_left.csv", header=T)
schools_right <- read.csv("schools_right.csv", header=T)


# --------------------
# inner join (defaults to inner)
dfinner <- merge(x = schools_left, y = schools_right, by.x="id", by.y="id")

head(dfinner)

# --------------------
# left join uses all.x Right join would be all.y
dfleft <- merge(x = schools_left, y = schools_right, by.x="id", by.y="id", all.x=TRUE)

head(dfleft)

# --------------------
# outer join
dfout <- merge(x = schools_left, y = schools_right, by.x="id", by.y="id", all=TRUE)

head(dfout)

#https://stackoverflow.com/questions/1299871/how-to-join-merge-data-frames-inner-outer-left-right

# --------------------
# Now, some custom joins with some pre-loaded tables

# selecting specfic rows, joining three tables
# and simplifying column names all at the same time
sql <- "SELECT schools_left.id,
       schools_left.left_school,
schools_right.right_school
FROM schools_left LEFT JOIN schools_right
ON schools_left.id = schools_right.id;"

df <- dbGetQuery(con, sql)

head(df)

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


# ---------------
# finally, disconnect
dbDisconnect(con)
dbUnloadDriver(drv)
