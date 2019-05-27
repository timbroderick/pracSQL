# set directory
setwd("~/anaconda3/envs/pracSQL/Chapter_11/")

# load libraries
library(tidyverse)
library("RPostgreSQL")
options("scipen" = 10)

# connect to postgres (remembert to turn it on)
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "aranalysis",
                 host = "localhost", port = 5432,
                 user = "tbroderick")


# Extracting components of a timestamp value using date_part()
sql <- "SELECT
date_part('year', '2019-12-01 18:37:12 EST'::timestamptz) AS \"year\",
date_part('month', '2019-12-01 18:37:12 EST'::timestamptz) AS \"month\",
date_part('day', '2019-12-01 18:37:12 EST'::timestamptz) AS \"day\",
date_part('hour', '2019-12-01 18:37:12 EST'::timestamptz) AS \"hour\",
date_part('minute', '2019-12-01 18:37:12 EST'::timestamptz) AS \"minute\",
date_part('seconds', '2019-12-01 18:37:12 EST'::timestamptz) AS \"seconds\",
date_part('timezone_hour', '2019-12-01 18:37:12 EST'::timestamptz) AS \"tz\",
date_part('week', '2019-12-01 18:37:12 EST'::timestamptz) AS \"week\",
date_part('quarter', '2019-12-01 18:37:12 EST'::timestamptz) AS \"quarter\",
date_part('epoch', '2019-12-01 18:37:12 EST'::timestamptz) AS \"epoch\";"
dbGetQuery(con, sql)

# year month day hour minute seconds tz week quarter      epoch
# 1 2019    12   1   17     37      12 -6   48       4 1575243432

# make a date
sql <- "SELECT make_date(2018, 2, 22);"
dbGetQuery(con, sql)

# make a time
sql <- "SELECT make_time(18, 4, 30.3);"
dbGetQuery(con, sql)


# make a timestamp with time zone
sql <- "SELECT make_timestamptz(2018, 2, 22, 18, 4, 30.3, 'Europe/Lisbon');"
dbGetQuery(con, sql)

# get current time info
sql <- "SELECT current_date;"
dbGetQuery(con, sql)

sql <- "SELECT current_time;"
dbGetQuery(con, sql)

sql <- "SELECT current_timestamp;"
dbGetQuery(con, sql)

sql <- "SELECT localtime;"
dbGetQuery(con, sql)

sql <- "SELECT localtimestamp;"
dbGetQuery(con, sql)

sql <- "SELECT now();"
dbGetQuery(con, sql)

# exctract year from now
sql <- "SELECT date_part('year', now()) AS \"year\";"
dbGetQuery(con, sql)

# Comparing current_timestamp and clock_timestamp() during row insert

# create table (table created)
sql <- "DROP TABLE IF EXISTS current_time_example;"
dbGetQuery(con, sql)

sql <- "CREATE TABLE current_time_example (
    time_id bigserial,
current_timestamp_col timestamp with time zone,
clock_timestamp_col timestamp with time zone
);"
dbGetQuery(con, sql)

sql <- "INSERT INTO current_time_example (current_timestamp_col, clock_timestamp_col)
    (SELECT current_timestamp, clock_timestamp() FROM generate_series(1,1000));"
dbGetQuery(con, sql)

sql <- "SELECT * FROM current_time_example;"
df <- dbGetQuery(con, sql)

# compare
sql <- "(SELECT current_timestamp,
clock_timestamp()
FROM generate_series(1,1000));"
df2 <- dbGetQuery(con, sql)

# Need to see this in PGadmin. current timestamp records time at beginning of query, 
# clock returns constant time so it will change as query continues


# get postgressql defaults
sql <- "SHOW ALL;"
show <- dbGetQuery(con, sql)

sql <- "SHOW timezone;"
dbGetQuery(con, sql)

sql <- "SELECT * FROM pg_timezone_abbrevs;"
dbGetQuery(con, sql)

# ooh, gets UTC offsets too
sql <- "SELECT * FROM pg_timezone_names;"
dbGetQuery(con, sql)

# Filter to find one
sql <- "SELECT * FROM pg_timezone_names
WHERE name LIKE 'Europe%';"
dbGetQuery(con, sql)

# set different time zone
# not that this doesn't work in R via postgres. Works in pgadmin only

# create a test table (table created)
#sql <- "CREATE TABLE time_zone_test (test_date timestamp with time zone);
#INSERT INTO time_zone_test VALUES ('2020-01-01 4:00');"
#dbGetQuery(con, sql)

# make sure timezone is US/Central
sql <- "SET timezone TO 'US/Central';"
dbGetQuery(con, sql)

sql <- "SHOW timezone;"
dbGetQuery(con, sql)

# get a date from the test table
sql <- "SELECT test_date FROM time_zone_test;"
dbGetQuery(con, sql)

# set a new timezone
sql <- "SET timezone TO 'US/Pacific';"
dbGetQuery(con, sql)

sql <- "SHOW timezone;"
dbGetQuery(con, sql)

# get a date from the test table
sql <- "SELECT test_date FROM time_zone_test;"
dbGetQuery(con, sql)

# we get the same date and time
# here's how to get date time according to different timezones
sql <- "SELECT test_date AT TIME ZONE 'Asia/Seoul'
FROM time_zone_test;"
dbGetQuery(con, sql)

# make sure timezone is US/Central
sql <- "SET timezone TO 'US/Central';"
dbGetQuery(con, sql)

sql <- "SHOW timezone;"
dbGetQuery(con, sql)

# math with dates
sql <- "SELECT '9/30/1929'::date - '9/27/1929'::date;"
dbGetQuery(con, sql)

sql <- "SELECT '9/30/1929'::date + '5 years'::interval;"
dbGetQuery(con, sql)

# disconnect
dbDisconnect(con)
dbUnloadDriver(drv)

