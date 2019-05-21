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
sql <- "CREATE TABLE current_time_example (
time_id bigserial,
current_timestamp_col timestamp with time zone,
clock_timestamp_col timestamp with time zone);
INSERT INTO current_time_example (current_timestamp_col, clock_timestamp_col);"
dbGetQuery(con, sql)

# compare
sql <- "(SELECT current_timestamp,
clock_timestamp()
FROM generate_series(1,1000));"
df <- dbGetQuery(con, sql)

sql <- "SELECT * FROM current_time_example;"
df2 <- dbGetQuery(con, sql)


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


# disconnect
dbDisconnect(con)
dbUnloadDriver(drv)

