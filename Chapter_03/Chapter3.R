setwd("~/anaconda3/envs/pracSQL/Chapter_03")
library("RPostgreSQL")
#https://www.r-bloggers.com/getting-started-with-postgresql-in-r/

# loads the PostgreSQL driver
drv <- dbDriver("PostgreSQL")
# creates a connection to the postgres database
con <- dbConnect(drv, dbname = "aranalysis",
                 host = "localhost", port = 5432,
                 user = "tbroderick")#, password = pw)

# create a table of character types
char_data <- "CREATE TABLE char_data_types (
varchar_column varchar(10),
char_column char(10),
text_column text
);"

dbGetQuery(con, char_data)

# add the values 
add_char <- "INSERT INTO char_data_types
VALUES ('abc', 'abc', 'abc'),
('defghi', 'defghi', 'defghi');
"
dbGetQuery(con, add_char)

# let's see if it's there
dbExistsTable(con, "char_data_types")

# save it to a text file
save_char <- "COPY char_data_types TO '/Users/tbroderick/anaconda3/envs/pracSQL/Chapter_03/typetestR.txt'
WITH (FORMAT CSV, HEADER, DELIMITER '|');
"
dbGetQuery(con, save_char)

# let's get it and see what we see in R
df <- dbGetQuery(con, "SELECT * from char_data_types")
summary(df)
# how about data types
sapply(df, class)


#--------------
# Number types

# create a table of number types
num_data <- "CREATE TABLE number_data_types (
numeric_column numeric(20,5),
real_column real,
double_column double precision
);
"

dbGetQuery(con, num_data)

# add the values 
add_num <- "INSERT INTO number_data_types
VALUES (.7, .7, .7),
(2.13579, 2.13579, 2.13579),
(2.1357987654, 2.1357987654, 2.1357987654);
"
dbGetQuery(con, add_num)

# let's see if it's there
dbExistsTable(con, "number_data_types")

# let's get it and see what we see in R
df <- dbGetQuery(con, "SELECT * from number_data_types")
summary(df)
# how about data types
sapply(df, class)

# let's get it and see what we see in R
df <- dbGetQuery(con, 'SELECT
numeric_column * 10000000 AS "Fixed",
real_column * 10000000 AS "Float"
FROM number_data_types
WHERE numeric_column = .7;
')
write.csv(df,'dftest.csv')
# interesting. Float shows the same problem as sql


#--------------
# Date time types

# create a table of date types
date_data <- "CREATE TABLE date_time_types (
timestamp_column timestamp with time zone,
interval_column interval
);
"

dbGetQuery(con, date_data)

# add the values 
add_date <- "INSERT INTO date_time_types
VALUES('2018-12-31 01:00 EST','2 days'),
('2018-12-31 01:00 -8','1 month'),
('2018-12-31 01:00 Australia/Melbourne','1 century'),
(now(),'1 week');
"
dbGetQuery(con, add_date)

# let's see if it's there
dbExistsTable(con, "date_time_types")

# let's get it and see what we see in R
df <- dbGetQuery(con, "SELECT * from date_time_types")
summary(df)
# how about data types
sapply(df, class)

# doing math with date time fields
df <- dbGetQuery(con, "SELECT
    timestamp_column,
    interval_column,
    timestamp_column - interval_column AS new_date
    FROM date_time_types;
")
df


#--------------
# Changing types

# casting datetime fields as characters
df <- dbGetQuery(con, "SELECT timestamp_column, CAST(timestamp_column AS varchar(10))
FROM date_time_types;
")
summary(df)
sapply(df, class)

# casting numerics as different things
df <- dbGetQuery(con, "SELECT numeric_column,
CAST(numeric_column AS integer),
CAST(numeric_column AS varchar(6))
FROM number_data_types;
")
summary(df)
sapply(df, class)


#---------------------------------------
# disconnect and unload driver when done
dbDisconnect(con)
dbUnloadDriver(drv)


