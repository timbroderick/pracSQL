
setwd("~/anaconda3/envs/pracSQL/Chapter_08_grouping")

library("RPostgreSQL")
#https://www.r-bloggers.com/getting-started-with-postgresql-in-r/

# loads the PostgreSQL driver
drv <- dbDriver("PostgreSQL")
# creates a connection to the postgres database
con <- dbConnect(drv, dbname = "aranalysis",
                 host = "localhost", port = 5432,
                 user = "tbroderick")#, password = pw)

# load 2009 and 2014 data into postgres
# for each, set a primary key and index key columns
sql <- "
CREATE TABLE pls_fy2014_pupld14a (
    stabr varchar(2) NOT NULL,
fscskey varchar(6) CONSTRAINT fscskey2014_key PRIMARY KEY,
libid varchar(20) NOT NULL,
libname varchar(100) NOT NULL,
obereg varchar(2) NOT NULL,
rstatus integer NOT NULL,
statstru varchar(2) NOT NULL,
statname varchar(2) NOT NULL,
stataddr varchar(2) NOT NULL,
longitud numeric(10,7) NOT NULL,
latitude numeric(10,7) NOT NULL,
fipsst varchar(2) NOT NULL,
fipsco varchar(3) NOT NULL,
address varchar(35) NOT NULL,
city varchar(20) NOT NULL,
zip varchar(5) NOT NULL,
zip4 varchar(4) NOT NULL,
cnty varchar(20) NOT NULL,
phone varchar(10) NOT NULL,
c_relatn varchar(2) NOT NULL,
c_legbas varchar(2) NOT NULL,
c_admin varchar(2) NOT NULL,
geocode varchar(3) NOT NULL,
lsabound varchar(1) NOT NULL,
startdat varchar(10),
enddate varchar(10),
popu_lsa integer NOT NULL,
centlib integer NOT NULL,
branlib integer NOT NULL,
bkmob integer NOT NULL,
master numeric(8,2) NOT NULL,
libraria numeric(8,2) NOT NULL,
totstaff numeric(8,2) NOT NULL,
locgvt integer NOT NULL,
stgvt integer NOT NULL,
fedgvt integer NOT NULL,
totincm integer NOT NULL,
salaries integer,
benefit integer,
staffexp integer,
prmatexp integer NOT NULL,
elmatexp integer NOT NULL,
totexpco integer NOT NULL,
totopexp integer NOT NULL,
lcap_rev integer NOT NULL,
scap_rev integer NOT NULL,
fcap_rev integer NOT NULL,
cap_rev integer NOT NULL,
capital integer NOT NULL,
bkvol integer NOT NULL,
ebook integer NOT NULL,
audio_ph integer NOT NULL,
audio_dl float NOT NULL,
video_ph integer NOT NULL,
video_dl float NOT NULL,
databases integer NOT NULL,
subscrip integer NOT NULL,
hrs_open integer NOT NULL,
visits integer NOT NULL,
referenc integer NOT NULL,
regbor integer NOT NULL,
totcir integer NOT NULL,
kidcircl integer NOT NULL,
elmatcir integer NOT NULL,
loanto integer NOT NULL,
loanfm integer NOT NULL,
totpro integer NOT NULL,
totatten integer NOT NULL,
gpterms integer NOT NULL,
pitusr integer NOT NULL,
wifisess integer NOT NULL,
yr_sub integer NOT NULL
);
"
dbGetQuery(con, sql)

# now the index. See Chapter 7 on design.

sql <- "
CREATE INDEX libname2014_idx ON pls_fy2014_pupld14a (libname);
CREATE INDEX stabr2014_idx ON pls_fy2014_pupld14a (stabr);
CREATE INDEX city2014_idx ON pls_fy2014_pupld14a (city);
CREATE INDEX visits2014_idx ON pls_fy2014_pupld14a (visits);

COPY pls_fy2014_pupld14a
FROM '/Users/tbroderick/anaconda3/envs/pracSQL/Chapter_08/pls_fy2014_pupld14a.csv'
WITH (FORMAT CSV, HEADER);
"
dbGetQuery(con, sql)

# create the 2009 data, index it and copy to
sql <- "
CREATE TABLE pls_fy2009_pupld09a (
    stabr varchar(2) NOT NULL,
fscskey varchar(6) CONSTRAINT fscskey2009_key PRIMARY KEY,
libid varchar(20) NOT NULL,
libname varchar(100) NOT NULL,
address varchar(35) NOT NULL,
city varchar(20) NOT NULL,
zip varchar(5) NOT NULL,
zip4 varchar(4) NOT NULL,
cnty varchar(20) NOT NULL,
phone varchar(10) NOT NULL,
c_relatn varchar(2) NOT NULL,
c_legbas varchar(2) NOT NULL,
c_admin varchar(2) NOT NULL,
geocode varchar(3) NOT NULL,
lsabound varchar(1) NOT NULL,
startdat varchar(10),
enddate varchar(10),
popu_lsa integer NOT NULL,
centlib integer NOT NULL,
branlib integer NOT NULL,
bkmob integer NOT NULL,
master numeric(8,2) NOT NULL,
libraria numeric(8,2) NOT NULL,
totstaff numeric(8,2) NOT NULL,
locgvt integer NOT NULL,
stgvt integer NOT NULL,
fedgvt integer NOT NULL,
totincm integer NOT NULL,
salaries integer,
benefit integer,
staffexp integer,
prmatexp integer NOT NULL,
elmatexp integer NOT NULL,
totexpco integer NOT NULL,
totopexp integer NOT NULL,
lcap_rev integer NOT NULL,
scap_rev integer NOT NULL,
fcap_rev integer NOT NULL,
cap_rev integer NOT NULL,
capital integer NOT NULL,
bkvol integer NOT NULL,
ebook integer NOT NULL,
audio integer NOT NULL,
video integer NOT NULL,
databases integer NOT NULL,
subscrip integer NOT NULL,
hrs_open integer NOT NULL,
visits integer NOT NULL,
referenc integer NOT NULL,
regbor integer NOT NULL,
totcir integer NOT NULL,
kidcircl integer NOT NULL,
loanto integer NOT NULL,
loanfm integer NOT NULL,
totpro integer NOT NULL,
totatten integer NOT NULL,
gpterms integer NOT NULL,
pitusr integer NOT NULL,
yr_sub integer NOT NULL,
obereg varchar(2) NOT NULL,
rstatus integer NOT NULL,
statstru varchar(2) NOT NULL,
statname varchar(2) NOT NULL,
stataddr varchar(2) NOT NULL,
longitud numeric(10,7) NOT NULL,
latitude numeric(10,7) NOT NULL,
fipsst varchar(2) NOT NULL,
fipsco varchar(3) NOT NULL
);

CREATE INDEX libname2009_idx ON pls_fy2009_pupld09a (libname);
CREATE INDEX stabr2009_idx ON pls_fy2009_pupld09a (stabr);
CREATE INDEX city2009_idx ON pls_fy2009_pupld09a (city);
CREATE INDEX visits2009_idx ON pls_fy2009_pupld09a (visits);

COPY pls_fy2009_pupld09a
FROM '/Users/tbroderick/anaconda3/envs/pracSQL/Chapter_08/pls_fy2009_pupld09a.csv'
WITH (FORMAT CSV, HEADER);
"
dbGetQuery(con, sql)

# check the imports
sql <- "SELECT count(*) FROM pls_fy2014_pupld14a;"
dbGetQuery(con, sql)
#nrow() does the same thing here, gets number of rows

sql <- "SELECT count(*) FROM pls_fy2009_pupld09a;"
dbGetQuery(con, sql)


# count the values in the salary column
sql <- "
SELECT count(salaries) FROM pls_fy2014_pupld14a;
"
dbGetQuery(con, sql)

# count the values in the libname column
sql <- "
SELECT count(libname) FROM pls_fy2014_pupld14a;
"
dbGetQuery(con, sql)

# now the number of distinct values in the libname column
sql <- "
SELECT count(DISTINCT libname) FROM pls_fy2014_pupld14a;
"
dbGetQuery(con, sql)

# count duplicate names
sql <- "SELECT libname, count(libname)
FROM pls_fy2014_pupld14a
GROUP BY libname
ORDER BY count(libname) DESC;"
dups <- dbGetQuery(con, sql)

# interesting. Here's how to see location of every Oxford Public Library
sql <- "SELECT libname, city, stabr
FROM pls_fy2014_pupld14a
WHERE libname = 'OXFORD PUBLIC LIBRARY';
"
dbGetQuery(con, sql)

# let's see min and max visits
sql <- "
SELECT max(visits), min(visits) FROM pls_fy2014_pupld14a;"
dbGetQuery(con, sql)

# shows us all the states in the db
sql <- "
SELECT stabr FROM pls_fy2014_pupld14a
GROUP BY stabr ORDER BY stabr;
"
dbGetQuery(con, sql)

# list of cities and states
sql <- "
SELECT city, stabr FROM pls_fy2014_pupld14a
GROUP BY city, stabr ORDER BY city, stabr;
"
dfcity <- dbGetQuery(con, sql)
nrow(dfcity)

# get a count
sql <- "SELECT city, stabr, count(*)
FROM pls_fy2014_pupld14a
GROUP BY city, stabr
ORDER BY count(*) DESC;
"
dbGetQuery(con, sql)
# that's interesting. Pittsburgh has the most? Let's see them
sql <- "SELECT libname, city, stabr
FROM pls_fy2014_pupld14a
WHERE city = 'PITTSBURGH'
AND stabr = 'PA';
"
dbGetQuery(con, sql)
# So Pittsburgh doesn't have a unified library district? Huh

# count of agencies per state
sql <- "
SELECT stabr, count(*) FROM pls_fy2014_pupld14a
GROUP BY stabr ORDER BY count(*) DESC;
"
dfcount <- dbGetQuery(con, sql)

#-----
# Here we digress

# let's try and count centlib by state
# first, we know there are a few -3, indicating no response
sql <- "
SELECT sum(centlib) FROM pls_fy2014_pupld14a
WHERE centlib != -3;
"
dbGetQuery(con, sql)

# now we select state, sum of centlib where there are no -3
# and groupby state and centlib, while ordering by sum
sql <- "
SELECT stabr, sum(centlib) FROM pls_fy2014_pupld14a
WHERE centlib != -3
GROUP BY stabr, centlib
ORDER BY sum(centlib) DESC;
"
dfcenlib <- dbGetQuery(con, sql)


# let's do the same with branch libraries
# Remember, count won't work here because of the minuses

sql <- "
SELECT sum(branlib) FROM pls_fy2014_pupld14a
WHERE branlib != -3;
"
dbGetQuery(con, sql)

# is it enough to just exclude -3?
sql <- "
SELECT sum(branlib) FROM pls_fy2014_pupld14a
WHERE branlib > 0;
"
dbGetQuery(con, sql)

sql <- "
SELECT stabr, sum(branlib) FROM pls_fy2014_pupld14a
WHERE branlib > 0
GROUP BY stabr, branlib
ORDER BY sum(branlib) DESC;
"
dfbranlib <- dbGetQuery(con, sql)

# interesting that there are far fewer branch libraries per state.
# what if we did that by city?

sql <- "
SELECT city, stabr, sum(branlib) FROM pls_fy2014_pupld14a
WHERE branlib > 0
GROUP BY city, stabr, branlib
ORDER BY sum(branlib) DESC;
"
dfbrancit <- dbGetQuery(con, sql)

# I've never heard of Downey Calif, but it has more branch libraries than Chicago and Los Angeles
# let's double check this

sql <- "
SELECT libname, city, stabr, branlib FROM pls_fy2014_pupld14a
WHERE city = 'DOWNEY';
"
df <- dbGetQuery(con, sql)

# Ah, the county of LA library system is located in Downey
# so let's revise our query a bit

sql <- "
SELECT libname, city, stabr, branlib FROM pls_fy2014_pupld14a
WHERE branlib > 0
ORDER BY branlib DESC;
"
dfbrancit <- dbGetQuery(con, sql)
# that tells us the library name too

# --------------------
# OK, back to exercises

# GROUP BY with count() on the stabr and stataddr columns
sql <- "SELECT stabr, stataddr, count(*)
FROM pls_fy2014_pupld14a
GROUP BY stabr, stataddr
ORDER BY stabr ASC, count(*) DESC;
"
dbGetQuery(con, sql)

# 00 means no change in address, 07 is a minor change and 15 big change


# Using the sum() aggregate function to total visits to
# libraries in 2014 and 2009

#2014
sql <- "
SELECT sum(visits) AS visits_2014
FROM pls_fy2014_pupld14a
WHERE visits >= 0;
"
dbGetQuery(con, sql)

#2009
sql <- "
SELECT sum(visits) AS visits_2009
FROM pls_fy2009_pupld09a
WHERE visits >= 0;
"
dbGetQuery(con, sql)

# let's join the tables to get results side-by-side
sql <- "SELECT sum(pls14.visits) AS visits_2014,
sum(pls09.visits) AS visits_2009
FROM pls_fy2014_pupld14a pls14 JOIN pls_fy2009_pupld09a pls09
ON pls14.fscskey = pls09.fscskey
WHERE pls14.visits >= 0 AND pls09.visits >= 0;
"
dbGetQuery(con, sql)

# Using GROUP BY to track percent change in library visits by state
sql <- "SELECT pls14.stabr,
       sum(pls14.visits) AS visits_2014,
sum(pls09.visits) AS visits_2009,
round( (CAST(sum(pls14.visits) AS decimal(10,1)) - sum(pls09.visits)) /
sum(pls09.visits) * 100, 2 ) AS pct_change
FROM pls_fy2014_pupld14a pls14 JOIN pls_fy2009_pupld09a pls09
ON pls14.fscskey = pls09.fscskey
WHERE pls14.visits >= 0 AND pls09.visits >= 0
GROUP BY pls14.stabr
ORDER BY pct_change DESC;"
dbGetQuery(con, sql)

# this line
# FROM pls_fy2014_pupld14a pls14 JOIN pls_fy2009_pupld09a pls09
# creates the alias for the two tables. 
# let's see what happens if we modify it

sql <- "SELECT pls14.stabr,
       sum(pls14.visits) AS visits_2014,
sum(pls09.visits) AS visits_2009,
round( (CAST(sum(pls14.visits) AS decimal(10,1)) - sum(pls09.visits)) /
sum(pls09.visits) * 100, 2 ) AS pct_change
FROM pls_fy2014_pupld14a JOIN pls_fy2009_pupld09a
ON pls14.fscskey = pls09.fscskey
WHERE pls14.visits >= 0 AND pls09.visits >= 0
GROUP BY pls14.stabr
ORDER BY pct_change DESC;"
dbGetQuery(con, sql)
# the query fails. That's a neat trick to remember

# Using HAVING to filter the results of an aggregate query
# in this case, to get only the places in 2014 with more than X visits

sql <- "SELECT pls14.stabr,
       sum(pls14.visits) AS visits_2014,
sum(pls09.visits) AS visits_2009,
round( (CAST(sum(pls14.visits) AS decimal(10,1)) - sum(pls09.visits)) /
sum(pls09.visits) * 100, 2 ) AS pct_change
FROM pls_fy2014_pupld14a pls14 JOIN pls_fy2009_pupld09a pls09
ON pls14.fscskey = pls09.fscskey
WHERE pls14.visits >= 0 AND pls09.visits >= 0
GROUP BY pls14.stabr
HAVING sum(pls14.visits) > 50000000
ORDER BY pct_change DESC;
"
dbGetQuery(con, sql)

# That results in the percent change in vists
# for the 6 largest states by total 2014 visits

# one query for me - do visits account for
# rise of borrowing ebooks?

# ---------------
# finally, disconnect
dbDisconnect(con)
dbUnloadDriver(drv)
