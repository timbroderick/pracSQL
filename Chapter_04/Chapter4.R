# set working directory

setwd("~/anaconda3/envs/pracSQL/Chapter_04")

library("RPostgreSQL")
#https://www.r-bloggers.com/getting-started-with-postgresql-in-r/

# loads the PostgreSQL driver
drv <- dbDriver("PostgreSQL")
# creates a connection to the postgres database
con <- dbConnect(drv, dbname = "aranalysis",
                 host = "localhost", port = 5432,
                 user = "tbroderick")#, password = pw)

# let's create a table

sql <- "
    CREATE TABLE us_counties_2010 (
        geo_name varchar(90),
state_us_abbreviation varchar(2),
summary_level varchar(3),
region smallint,
division smallint,
state_fips varchar(2),
county_fips varchar(3),
area_land bigint,
area_water bigint,
population_count_100_percent integer,
housing_unit_count_100_percent integer,
internal_point_lat numeric(10,7),
internal_point_lon numeric(10,7),
p0010001 integer,
p0010002 integer,
p0010003 integer,
p0010004 integer,
p0010005 integer,
p0010006 integer,
p0010007 integer,
p0010008 integer,
p0010009 integer,
p0010010 integer,
p0010011 integer,
p0010012 integer,
p0010013 integer,
p0010014 integer,
p0010015 integer,
p0010016 integer,
p0010017 integer,
p0010018 integer,
p0010019 integer,
p0010020 integer,
p0010021 integer,
p0010022 integer,
p0010023 integer,
p0010024 integer,
p0010025 integer,
p0010026 integer,
p0010047 integer,
p0010063 integer,
p0010070 integer,
p0020001 integer,
p0020002 integer,
p0020003 integer,
p0020004 integer,
p0020005 integer,
p0020006 integer,
p0020007 integer,
p0020008 integer,
p0020009 integer,
p0020010 integer,
p0020011 integer,
p0020012 integer,
p0020028 integer,
p0020049 integer,
p0020065 integer,
p0020072 integer,
p0030001 integer,
p0030002 integer,
p0030003 integer,
p0030004 integer,
p0030005 integer,
p0030006 integer,
p0030007 integer,
p0030008 integer,
p0030009 integer,
p0030010 integer,
p0030026 integer,
p0030047 integer,
p0030063 integer,
p0030070 integer,
p0040001 integer,
p0040002 integer,
p0040003 integer,
p0040004 integer,
p0040005 integer,
p0040006 integer,
p0040007 integer,
p0040008 integer,
p0040009 integer,
p0040010 integer,
p0040011 integer,
p0040012 integer,
p0040028 integer,
p0040049 integer,
p0040065 integer,
p0040072 integer,
h0010001 integer,
h0010002 integer,
h0010003 integer
);
"
dbGetQuery(con, sql)


# success. Now let's see how copy works

sql <- "
COPY us_counties_2010
FROM '/Users/tbroderick/anaconda3/envs/pracSQL/Chapter_04/us_counties_2010.csv'
WITH (FORMAT CSV, HEADER);
"

dbGetQuery(con, sql)

# yay! this worked easily
df <- dbGetQuery(con, "SELECT * FROM us_counties_2010")

summary(df)

# just in case, this is an alternative
#sapply(sql, function(x) dbGetQuery(con,x))

# other queries seem to work really well too

sql <- "
SELECT geo_name, state_us_abbreviation, area_land
FROM us_counties_2010
ORDER BY area_land DESC
LIMIT 3;
"

dfquery <- dbGetQuery(con, sql)
head(dfquery)


# now let's see if the temporary table works
# first we create the table

sql <- "
CREATE TABLE supervisor_salaries (
    town varchar(30),
county varchar(30),
supervisor varchar(30),
start_date date,
salary money,
benefits money
);
"
dbGetQuery(con, sql)

# copy the data into it
sql <- "
COPY supervisor_salaries (town, supervisor, salary)
FROM '/Users/tbroderick/anaconda3/envs/pracSQL/Chapter_04/supervisor_salaries.csv'
WITH (FORMAT CSV, HEADER);
"
dbGetQuery(con, sql)

sql <- "
SELECT * FROM supervisor_salaries LIMIT 2;
"
dfquery <- dbGetQuery(con, sql)
dfquery

# intersting, I get a warning based on type

# now let's clear the table data
sql <- "
DELETE FROM supervisor_salaries;
"
dfquery <- dbGetQuery(con, sql)
dfquery

# let's try this big series of queries

sql <- "
CREATE TEMPORARY TABLE supervisor_salaries_temp (LIKE supervisor_salaries);
COPY supervisor_salaries_temp (town, supervisor, salary)
FROM '/Users/tbroderick/anaconda3/envs/pracSQL/Chapter_04/supervisor_salaries.csv'
WITH (FORMAT CSV, HEADER);
INSERT INTO supervisor_salaries (town, county, supervisor, salary)
SELECT town, 'Some County', supervisor, salary
FROM supervisor_salaries_temp;
DROP TABLE supervisor_salaries_temp;
"
dbGetQuery(con, sql)

sql <- "
SELECT * FROM supervisor_salaries LIMIT 4;
"
dfquery <- dbGetQuery(con, sql)
dfquery

# that rocks so good
# I'm assuming this will continue, so let's see how
# the most complex querie works

sql <- "
COPY (
    SELECT geo_name, state_us_abbreviation
FROM us_counties_2010
WHERE geo_name ILIKE '%mill%'
)
TO '/Users/tbroderick/anaconda3/envs/pracSQL/Chapter_04/us_counties_mill_exportR.txt'
WITH (FORMAT CSV, HEADER, DELIMITER '|');
"
dbGetQuery(con, sql)

# so that works. Need to ignore the message
# data frame with 0 columns and 0 rows

# ---------------
# finally, disconnect
dbDisconnect(con)
dbUnloadDriver(drv)
