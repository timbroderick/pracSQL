# set working directory

setwd("~/anaconda3/envs/pracSQL/Chapter_07_design")

library("RPostgreSQL")
#https://www.r-bloggers.com/getting-started-with-postgresql-in-r/

# loads the PostgreSQL driver
drv <- dbDriver("PostgreSQL")
# creates a connection to the postgres database
con <- dbConnect(drv, dbname = "aranalysis",
                 host = "localhost", port = 5432,
                 user = "tbroderick")#, password = pw)

# Let's do some table optimization
# first create and load data in to the big table
sql <- "
CREATE TABLE new_york_addresses (
longitude numeric(9,6),
latitude numeric(9,6),
street_number varchar(10),
street varchar(32),
unit varchar(7),
postcode varchar(5),
id integer CONSTRAINT new_york_key PRIMARY KEY
);
"
dbGetQuery(con, sql)

sql <- "
COPY new_york_addresses
FROM '/Users/tbroderick/anaconda3/envs/pracSQL/Chapter_07_design/city_of_new_york.csv'
WITH (FORMAT CSV, HEADER);
"
dbGetQuery(con, sql)

# select it to see if we have it all
sql <- "SELECT * FROM new_york_addresses"
df <- dbGetQuery(con, sql)
head(df)
summary(df)

# Now see if we can get performance stats
sql <- "
EXPLAIN ANALYZE SELECT * FROM new_york_addresses
WHERE street = 'BROADWAY';
"
dbGetQuery(con, sql)

# yes! Now let's apply an index to the table
sql <- "
CREATE INDEX street_idx ON new_york_addresses (street);
"
dbGetQuery(con, sql)

# wait, assuming this takes a few minutes
# now run the performance query again
sql <- "
EXPLAIN ANALYZE SELECT * FROM new_york_addresses
WHERE street = 'BROADWAY';
"
dbGetQuery(con, sql)

# yes, it's significantly improved through R. 
# however, it's slightly slower than directly querying in pgAdmin

# ---------------
# finally, disconnect
dbDisconnect(con)
dbUnloadDriver(drv)
