# set directory
setwd("~/anaconda3/envs/pracSQL/Chapter_09")

# load libraries
library(tidyverse)
library("RPostgreSQL")
options("scipen" = 10)

# connect to postgres (remembert to turn it on)
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "aranalysis",
                 host = "localhost", port = 5432,
                 user = "tbroderick")

# working on updating info in postgres

# first let's load some data to work with
sql <- "
CREATE TABLE meat_poultry_egg_inspect (
    est_number varchar(50) CONSTRAINT est_number_key PRIMARY KEY,
company varchar(100),
street varchar(100),
city varchar(30),
st varchar(2),
zip varchar(5),
phone varchar(14),
grant_date date,
activities text,
dbas text
);
COPY meat_poultry_egg_inspect
FROM '/Users/tbroderick/anaconda3/envs/pracSQL/Chapter_09/MPI_Directory_by_Establishment_Name.csv'
WITH (FORMAT CSV, HEADER, DELIMITER ',');
CREATE INDEX company_idx ON meat_poultry_egg_inspect (company);"
dbGetQuery(con, sql)

# get a count
sql <- "SELECT count(*) FROM meat_poultry_egg_inspect;"
dbGetQuery(con, sql)

# how many companies at the same address
sql <- "SELECT company,
       street,
city,
st,
count(*) AS address_count
FROM meat_poultry_egg_inspect
GROUP BY company, street, city, st
HAVING count(*) > 1
ORDER BY company, street, city, st;"
df <- dbGetQuery(con, sql)

# grouping and counting states
sql <- "SELECT st, 
       count(*) AS st_count
FROM meat_poultry_egg_inspect
GROUP BY st
ORDER BY st_count DESC;"
dbGetQuery(con, sql)

# use null to find missing values
sql <- "SELECT est_number,
       company,
city,
st,
zip
FROM meat_poultry_egg_inspect
WHERE st IS NULL;"
dbGetQuery(con, sql)

#Using GROUP BY and count() to find inconsistent company names
sql <- "SELECT company,
       count(*) AS company_count
FROM meat_poultry_egg_inspect
GROUP BY company
ORDER BY company ASC;
"
dbGetQuery(con, sql)

# Using length() and count() to test the zip column
sql <- "SELECT length(zip),
       count(*) AS length_count
FROM meat_poultry_egg_inspect
GROUP BY length(zip)
ORDER BY length(zip) ASC;"
dbGetQuery(con, sql)

# Filtering with length() to find short zip values
sql <- "SELECT st,
       count(*) AS st_count
FROM meat_poultry_egg_inspect
WHERE length(zip) < 5
GROUP BY st
ORDER BY st ASC;
"
dbGetQuery(con, sql)

# Backing up a table then checking the number of records
sql <- "
CREATE TABLE meat_poultry_egg_inspect_backup AS
SELECT * FROM meat_poultry_egg_inspect;
"
dbGetQuery(con, sql)

sql <- "
SELECT 
(SELECT count(*) FROM meat_poultry_egg_inspect) AS original,
(SELECT count(*) FROM meat_poultry_egg_inspect_backup) AS backup;"
dbGetQuery(con, sql)

# Creating and filling the st_copy column with ALTER TABLE and UPDATE
# we're creating this as a backup to the state column since we're going to 
# update the values in case we make a mistake
sql <- "ALTER TABLE meat_poultry_egg_inspect ADD COLUMN st_copy varchar(2);
UPDATE meat_poultry_egg_inspect
SET st_copy = st;"
dbGetQuery(con, sql)

# Checking values in the st and st_copy columns 
sql <- "SELECT st,
       st_copy
FROM meat_poultry_egg_inspect
ORDER BY st;"
dbGetQuery(con, sql)

# Updating the st column for three establishments
# we still have the st copy column in case we err
sql <- "UPDATE meat_poultry_egg_inspect
SET st = 'MN'
WHERE est_number = 'V18677A';

UPDATE meat_poultry_egg_inspect
SET st = 'AL'
WHERE est_number = 'M45319+P45319';

UPDATE meat_poultry_egg_inspect
SET st = 'WI'
WHERE est_number = 'M263A+P263A+V263A';"
dbGetQuery(con, sql)

# if we erred, we could restore the changes we made to the state column entirely
# with a sql command like this
# UPDATE meat_poultry_egg_inspect
# SET st = st_copy;

# can also restore from the backup table

# now we're creating a new column in order to standardize the company names
sql <- "ALTER TABLE meat_poultry_egg_inspect ADD COLUMN company_standard varchar(100);
UPDATE meat_poultry_egg_inspect
SET company_standard = company;"
dbGetQuery(con, sql)

# let's just double check to see where we are
sql <- "SELECT * FROM meat_poultry_egg_inspect;"
df <- dbGetQuery(con, sql)
nrow(df)
colnames(df)


# Use UPDATE to modify field values that match a string

sql <- "UPDATE meat_poultry_egg_inspect
SET company_standard = 'Armour-Eckrich Meats'
WHERE company LIKE 'Armour%';"
dbGetQuery(con, sql)

# that should have found all the places with Armour at the beginning
# and standardized them
# let's check that
sql <- "SELECT company, company_standard
FROM meat_poultry_egg_inspect
WHERE company LIKE 'Armour%';"
df <- dbGetQuery(con, sql)

# now let's fix the zip codes. They're missing leading 0s
# first we create a copy of the column
sql <- "ALTER TABLE meat_poultry_egg_inspect ADD COLUMN zip_copy varchar(5);
UPDATE meat_poultry_egg_inspect
SET zip_copy = zip;"
dbGetQuery(con, sql)

# then we update zips where there are two missing 0s
sql <- "UPDATE meat_poultry_egg_inspect
SET zip = '00' || zip
WHERE st IN('PR','VI') AND length(zip) = 3;"
dbGetQuery(con, sql)
# then one missing 0
sql <- "UPDATE meat_poultry_egg_inspect
SET zip = '0' || zip
WHERE st IN('CT','MA','ME','NH','NJ','RI','VT') AND length(zip) = 4;"
dbGetQuery(con, sql)

# let's check that
# Using length() and count() to test the zip column
sql <- "SELECT length(zip),
count(*) AS length_count
FROM meat_poultry_egg_inspect
GROUP BY length(zip)
ORDER BY length(zip) ASC;"
dbGetQuery(con, sql)

# Creating and filling a state_regions table

sql <- "CREATE TABLE state_regions (
  st varchar(2) CONSTRAINT st_key PRIMARY KEY,
  region varchar(20) NOT NULL
);
COPY state_regions
FROM '/Users/tbroderick/anaconda3/envs/pracSQL/Chapter_09/state_regions.csv'
WITH (FORMAT CSV, HEADER, DELIMITER ',');"
dbGetQuery(con, sql)

# Adding and updating an inspection_date column
# we did that with a subquery where we joined the regional data in the WHERE EXISTS part

sql <- "ALTER TABLE meat_poultry_egg_inspect ADD COLUMN inspection_date date;
UPDATE meat_poultry_egg_inspect inspect
SET inspection_date = '2019-12-01'
WHERE EXISTS (SELECT state_regions.region
FROM state_regions
WHERE inspect.st = state_regions.st
AND state_regions.region = 'New England');"
dbGetQuery(con, sql)

# view results
sql <- "SELECT st, inspection_date
FROM meat_poultry_egg_inspect
GROUP BY st, inspection_date
ORDER BY st;"
df <- dbGetQuery(con, sql)


# do some clean up
# Delete rows matching an expression
# Remove a column from a table using DROP
# Remove a table from a database using DROP

sql <- "DELETE FROM meat_poultry_egg_inspect
WHERE st IN('PR','VI');
ALTER TABLE meat_poultry_egg_inspect DROP COLUMN zip_copy;
DROP TABLE meat_poultry_egg_inspect_backup;"
dbGetQuery(con, sql)

# transaction blocks
# and copying/updating


# execute a query 
sql <- ""
dbGetQuery(con, sql)

# disconnect
dbDisconnect(con)
dbUnloadDriver(drv)

