# set directory
setwd("~/anaconda3/envs/pracSQL/Chapter_12_advanced")

# load libraries
library(tidyverse)
#library('readxl')
library("RPostgreSQL")
options("scipen" = 10)

# connect to postgres (remembert to turn it on)
drv <- dbDriver("PostgreSQL")
#con <- dbConnect(drv, dbname = "analysis",
#                 host = "localhost", port = 5432,
#                 user = "tbroderick")
# connect to aranalysis (for salaries)
con <- dbConnect(drv, dbname = "aranalysis",
                   host = "localhost", port = 5432,
                   user = "tbroderick")

sql <- "select * from information_schema.tables"
tables <- dbGetQuery(con, sql)

# subquery can do a calculation (finding the 90th percentile)
# and return the result to the main query
sql <- "SELECT geo_name,state_us_abbreviation,p0010001 
FROM us_counties_2010
WHERE p0010001 >= (
SELECT percentile_cont(.9) WITHIN GROUP (ORDER BY p0010001)
FROM us_counties_2010
)
ORDER BY p0010001 DESC;"

df <- dbGetQuery(con, sql)

# Use case - select a set of data from a larger set
# to make it easier to work with

sql <- "CREATE TABLE us_counties_2010_top10 AS
SELECT * FROM us_counties_2010;

DELETE FROM us_counties_2010_top10
WHERE p0010001 < (
SELECT percentile_cont(.9) WITHIN GROUP (ORDER BY p0010001)
FROM us_counties_2010_top10
);

SELECT count(*) FROM us_counties_2010_top10;"

dbGetQuery(con, sql)

# the R equivelant is filter

sql <- "SELECT * FROM us_counties_2010;"
df <- dbGetQuery(con, sql)

df <- df %>% 
  filter(p0010001>=quantile(df$p0010001,.9))

# find average, median and difference between the two
sql <- "SELECT 
round(calcs.average, 0) as average,
calcs.median, 
round(calcs.average - calcs.median, 0) AS median_average_diff
FROM ( SELECT avg(p0010001) AS average, 
percentile_cont(.5)
WITHIN GROUP (ORDER BY p0010001)::numeric(10,1) 
AS median
FROM us_counties_2010
)
AS calcs;"
dbGetQuery(con,sql)

# in R

sql <- "SELECT p0010001 FROM us_counties_2010;"
df <- dbGetQuery(con, sql)

avg <- round(mean(df$p0010001),2)
med <- round(median(df$p0010001),2)
print(paste(avg," | ",med," | ",avg-med),quote=FALSE)


# joining derived tables
# plants per million calculated on the fly in a subquery
# with :: specifying the type
# then a subquery select state, gets a count of plants and groups by state
# finally we join
# first we select the state abbreviation and sum the county populations
# to get state populations, then join the two datasets

sql <- "
SELECT census.state_us_abbreviation AS st,
census.st_population,
plants.plant_count,
round((plants.plant_count/census.st_population::numeric(10,1)) * 1000000, 1)
AS plants_per_million
FROM
(
  SELECT st,
  count(*) AS plant_count
  FROM meat_poultry_egg_inspect
  GROUP BY st
)
AS plants
JOIN
(
  SELECT state_us_abbreviation,
  sum(p0010001) AS st_population
  FROM us_counties_2010
  GROUP BY state_us_abbreviation
)
AS census
ON plants.st = census.state_us_abbreviation
ORDER BY plants_per_million DESC;"

df <- dbGetQuery(con,sql)

# to do this in R I first grab the two datesets
sql <- "SELECT state_us_abbreviation AS st,p0010001
FROM us_counties_2010;"
dfpop <- dbGetQuery(con, sql)
sql <- "SELECT est_number, st FROM meat_poultry_egg_inspect;"
dfplants <- dbGetQuery(con, sql)
# then we group by st and count the plants
dfplantsg <- dfplants %>% 
  group_by(st) %>% 
  summarise(plant_count = n())
# now we group the census by state and sum the population
dfpopg <- dfpop %>% 
  group_by(st) %>% 
  summarise(st_population = sum(p0010001))
# finally join the two tables and calculate the rate
dfjoin <- merge(x = dfpopg, y=dfplantsg, on="st",all.x=TRUE)
dfjoin$plants_per_million <- round( (dfjoin$plant_count/dfjoin$st_population)*1000000,2)
dfjoin <- dfjoin[order(-dfjoin$plants_per_million),] 

# adding a new column as a subquery

sql <- "
SELECT geo_name,
state_us_abbreviation AS st,
p0010001 AS total_pop,
(
SELECT percentile_cont(.5) 
WITHIN GROUP (ORDER BY p0010001)
FROM us_counties_2010
) AS us_median
FROM us_counties_2010;"

df <-  dbGetQuery(con, sql)

# in R, it's a simple as
df$rmedian <- median(df$total_pop)


# adding a new column as a subquery, and figuring difference

sql <- "
SELECT geo_name, state_us_abbreviation AS st,
p0010001 AS total_pop,
(
SELECT percentile_cont(.5) 
WITHIN GROUP (ORDER BY p0010001)
FROM us_counties_2010
) AS us_median,
p0010001 - (
SELECT percentile_cont(.5) 
WITHIN GROUP (ORDER BY p0010001)
FROM us_counties_2010
) AS diff_from_median
FROM us_counties_2010
WHERE (
p0010001 - (SELECT percentile_cont(.5) WITHIN GROUP (ORDER BY p0010001)
FROM us_counties_2010)
)
BETWEEN -1000 AND 1000;"
  
df <-  dbGetQuery(con, sql)

# in R, it's a simple as
df$r_difmedian <- df$total_pop - df$us_median # median(df$total_pop)
# and filtering like so
df <- df %>% filter( (r_difmedian > -500) & (r_difmedian < 500) )

# common table expressions (CTE)

# with creates a table with three columns,
# AS selects the three columns with condition
# then a further query groups by state and counts

sql <- "WITH
large_counties (geo_name, st, p0010001)
AS
(
  SELECT geo_name, state_us_abbreviation, p0010001
  FROM us_counties_2010
  WHERE p0010001 >= 100000
)
SELECT st, count(*)
FROM large_counties
GROUP BY st
ORDER BY count(*) DESC;"

df <-  dbGetQuery(con, sql)

# alt
sql <- "SELECT state_us_abbreviation, count(*)
FROM us_counties_2010
WHERE p0010001 >= 100000
GROUP BY state_us_abbreviation
ORDER BY count(*) DESC;
"
df <-  dbGetQuery(con, sql)

# CTEs help queries be clearer
# new plants count

sql <- "WITH
    counties (st, population) AS
(SELECT state_us_abbreviation, sum(population_count_100_percent)
FROM us_counties_2010
GROUP BY state_us_abbreviation),

plants (st, plants) AS
(SELECT st, count(*) AS plants
FROM meat_poultry_egg_inspect
GROUP BY st)

SELECT counties.st,
population,
plants,
round((plants/population::numeric(10,1))*1000000, 1) AS per_million
FROM counties JOIN plants
ON counties.st = plants.st
ORDER BY per_million DESC;"
df <-  dbGetQuery(con, sql)

# Using CTEs to minimize redundant code
# as in the us median example

sql <- "WITH us_median AS 
(SELECT percentile_cont(.5) 
  WITHIN GROUP (ORDER BY p0010001) AS us_median_pop
  FROM us_counties_2010)

SELECT geo_name,
state_us_abbreviation AS st,
p0010001 AS total_pop,
us_median_pop,
p0010001 - us_median_pop AS diff_from_median 
FROM us_counties_2010 CROSS JOIN us_median
WHERE (p0010001 - us_median_pop)
BETWEEN -1000 AND 1000;"
df <-  dbGetQuery(con, sql)


# cross tabs

# first create and load data into a table

sql <- "
CREATE TABLE ice_cream_survey (
response_id integer PRIMARY KEY,
office varchar(20),
flavor varchar(20)
);"
dbGetQuery(con, sql)

sql <- "COPY ice_cream_survey
FROM '/Users/tbroderick/anaconda3/envs/pracSQL/Chapter_12_advanced/ice_cream_survey.csv'
WITH (FORMAT CSV, HEADER);"
dbGetQuery(con, sql)

sql <- "SELECT * from ice_cream_survey;"
df <- dbGetQuery(con, sql)

# now generate a crosstab
sql <- "SELECT *
FROM crosstab(
'SELECT office,
flavor, count(*)
FROM ice_cream_survey
GROUP BY office, flavor
ORDER BY office',

'SELECT flavor
FROM ice_cream_survey
GROUP BY flavor
ORDER BY flavor'
)

AS (
office varchar(20),
chocolate bigint,
strawberry bigint,
vanilla bigint
);"
df <- dbGetQuery(con, sql)

# in R this is just group by with summarizze
sql <- "SELECT * FROM ice_cream_survey;"
df <- dbGetQuery(con, sql)

dfsum <- df %>% 
  group_by(office,flavor) %>% 
  summarize(n=n()) %>% 
  spread(flavor,n)

# http://analyticswithr.com/contingencytables.html

# and gmodels does even more
install.packages("gmodels")
library(gmodels)
CrossTable(df$office, df$flavor)

# examining city temperature readings
sql <- "CREATE TABLE temperature_readings (
    reading_id bigserial PRIMARY KEY,
station_name varchar(50),
observation_date date,
max_temp integer,
min_temp integer
);"
dbGetQuery(con, sql)

sql <- "COPY temperature_readings 
     (station_name, observation_date, max_temp, min_temp)
FROM '/Users/tbroderick/anaconda3/envs/pracSQL/Chapter_12_advanced/temperature_readings.csv'
WITH (FORMAT CSV, HEADER);"
dbGetQuery(con, sql)

# use cross tabs to find median maximum temperature per month

sql <- "SELECT *
FROM crosstab('SELECT
station_name,
date_part(''month'', observation_date),
percentile_cont(.5)
WITHIN GROUP (ORDER BY max_temp)
FROM temperature_readings
GROUP BY station_name,
date_part(''month'', observation_date)
ORDER BY station_name',

'SELECT month
FROM generate_series(1,12) month')

AS (station varchar(50),
jan numeric(3,0),
feb numeric(3,0),
mar numeric(3,0),
apr numeric(3,0),
may numeric(3,0),
jun numeric(3,0),
jul numeric(3,0),
aug numeric(3,0),
sep numeric(3,0),
oct numeric(3,0),
nov numeric(3,0),
dec numeric(3,0)
);"
dft <- dbGetQuery(con, sql)

# in R using lubridate
library(lubridate)
sql <- "SELECT * FROM temperature_readings;"
dftemp <- dbGetQuery(con, sql)
# find the month for each entry
dftemp$month <- month(dftemp$observation_date,label = TRUE)
dfgettemp <- dftemp %>% 
  group_by(station_name,month) %>% 
  summarize(n=median(max_temp)) %>% 
  spread(month,n)


# using CASE in a common table expression
sql <- "
SELECT max_temp,
CASE WHEN max_temp >= 90 THEN 'Hot'
WHEN max_temp BETWEEN 70 AND 89 THEN 'Warm'
WHEN max_temp BETWEEN 50 AND 69 THEN 'Pleasant'
WHEN max_temp BETWEEN 33 AND 49 THEN 'Cold'
WHEN max_temp BETWEEN 20 AND 32 THEN 'Freezing'
ELSE 'Inhumane'
END AS temperature_group
FROM temperature_readings;
"
df <- dbGetQuery(con, sql)

# now generate a temps_collaptes and analysis

sql <- "WITH temps_collapsed (station_name, max_temperature_group) AS
    (SELECT station_name,
CASE WHEN max_temp >= 90 THEN 'Hot'
WHEN max_temp BETWEEN 70 AND 89 THEN 'Warm'
WHEN max_temp BETWEEN 50 AND 69 THEN 'Pleasant'
WHEN max_temp BETWEEN 33 AND 49 THEN 'Cold'
WHEN max_temp BETWEEN 20 AND 32 THEN 'Freezing'
ELSE 'Inhumane'
END
FROM temperature_readings)

SELECT station_name, max_temperature_group, count(*)
FROM temps_collapsed
GROUP BY station_name, max_temperature_group
ORDER BY station_name, count(*) DESC;"
df <- dbGetQuery(con, sql)


# this seems to be a nested ifelse

dftemp$temp_group <- with(dftemp, 
                          ifelse(dftemp$max_temp >= 20 & dftemp$max_temp < 33,"Freezing",
                                 ifelse(dftemp$max_temp >= 33 & dftemp$max_temp < 50,"Cold",
                                        ifelse(dftemp$max_temp >= 50 & dftemp$max_temp < 70,"Pleasant",
                                               ifelse(dftemp$max_temp >= 70 & dftemp$max_temp < 90,"Warm",
                                                      ifelse(dftemp$max_temp >= 90,"Hot","Inhumane")
                                                      )))))
# and then group by
dfgettemp <- dftemp %>% 
  group_by(station_name,temp_group) %>% 
  summarize(n=n()) %>% 
  spread(temp_group,n)

colnames(dfgettemp)
# let's get it in a better order
dfgettemp <- select(dfgettemp,"station_name","Inhumane","Freezing","Cold","Pleasant","Warm","Hot")


# disconnect
dbDisconnect(con)
dbUnloadDriver(drv)

