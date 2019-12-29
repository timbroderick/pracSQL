# set directory
setwd("~/anaconda3/envs/notebook/MHMetrics/work/")

# load libraries
library(tidyverse)
#library('readxl')
library("RPostgreSQL")
options("scipen" = 10)

# connect to postgres (remembert to turn it on)
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "gis_analysis",
                   host = "localhost", port = 5432,
                   user = "tbroderick")



# testing to see if postgis is installed
sql <- "SELECT postgis_full_version();"
dbGetQuery(con, sql)

# getting the spatial reference system
sql <- "
SELECT srtext
FROM spatial_ref_sys
WHERE srid = 4326;
"
dbGetQuery(con, sql)

# some common feature queries
sql <- "SELECT ST_GeomFromText('POINT(-74.9233606 42.699992)', 4326);
"
dbGetQuery(con, sql)

sql <- "SELECT ST_GeomFromText('LINESTRING(-74.9 42.7, -75.1 42.7)', 4326);"
dbGetQuery(con, sql)

sql <- "SELECT ST_GeomFromText('POLYGON((-74.9 42.7, -75.1 42.7,
-75.1 42.6, -74.9 42.7))', 4326);"
dbGetQuery(con, sql)

sql <- "SELECT ST_GeomFromText('MULTIPOINT (-74.9 42.7, -75.1 42.7)', 4326);"
dbGetQuery(con, sql)

sql <- "SELECT ST_GeomFromText('MULTILINESTRING((-76.27 43.1, -76.06 43.08),
(-76.2 43.3, -76.2 43.4,
-76.4 43.1))', 4326);"
dbGetQuery(con, sql)

sql <- "SELECT ST_GeomFromText('MULTIPOLYGON((
(-74.92 42.7, -75.06 42.71,
-75.07 42.64, -74.92 42.7),
(-75.0 42.66, -75.0 42.64,
-74.98 42.64, -74.98 42.66,
-75.0 42.66)))', 4326);"
dbGetQuery(con, sql)

# so it looks like I can get this info, but R doesn't like the response
# there are also line functions and polygon functions

# but let's skip ahead to examine farmers market data
sql <- "
CREATE TABLE farmers_markets (
    fmid bigint PRIMARY KEY,
market_name varchar(100) NOT NULL,
street varchar(180),
city varchar(60),
county varchar(25),
st varchar(20) NOT NULL,
zip varchar(10),
longitude numeric(10,7),
latitude numeric(10,7),
organic varchar(1) NOT NULL
);

COPY farmers_markets
FROM '/Users/tbroderick/anaconda3/envs/pracSQL/Chapter_14_mapping/farmers_markets.csv'
WITH (FORMAT CSV, HEADER);"
dbGetQuery(con, sql)

# and check this
sql <- "SELECT count(*) FROM farmers_markets;"
dbGetQuery(con, sql)

sql <- "SELECT * FROM farmers_markets 
WHERE city = 'Chicago' LIMIT 100;"
farmers <- dbGetQuery(con, sql)

# This might not work in R, but we're going to create a column that's a spacial data type
# in order to run queries on it
sql <- "
ALTER TABLE farmers_markets ADD COLUMN geog_point geography(POINT,4326);
"
dbGetQuery(con, sql)

# seems ok. Now we'll update it with the lat/long data
sql <- "
UPDATE farmers_markets
SET geog_point = ST_SetSRID(
ST_MakePoint(longitude,latitude),4326
)::geography;
"
dbGetQuery(con, sql)

# create an index on that column
sql <- "CREATE INDEX market_pts_idx ON farmers_markets USING GIST (geog_point);"
dbGetQuery(con, sql)

# finally, let's select data to see how it responds here
sql <- "
SELECT longitude,
       latitude,
geog_point,
ST_AsText(geog_point)
FROM farmers_markets
WHERE longitude IS NOT NULL
LIMIT 5;
"
suppressWarnings( dbGetQuery(con, sql) )

# really doesn't like those columns, but supress warnings works
# now we can do math on these.


# Here we're going to find the markets within 10 kilometers of the main Des Moines market
sql <- "
SELECT market_name,
       city,st
FROM farmers_markets
WHERE ST_DWithin(
geog_point,
ST_GeogFromText('POINT(-93.6204386 41.5853202)'),
10000
)
ORDER BY market_name;
"
dbGetQuery(con, sql)
# no suppress warning needed because we're returning a list of standard columns

# so with ST_DWithin
# first input is the column we're searching
# second is the point we're starting from
# third is the distance in meters from that point
# and we return market_name, city and state

# finding the distance between two points
sql <- "
SELECT ST_Distance(
                   ST_GeogFromText('POINT(-73.9283685 40.8296466)'),
ST_GeogFromText('POINT(-73.8480153 40.7570917)')
) / 1609.344 AS mets_to_yanks;
"
dbGetQuery(con, sql)

# geography type columns returns distances in meters. 
# To convert to miles, divide by 1609.344

# now we combine the two to find the distance for each market
sql <- "
SELECT market_name,city,
round( (ST_Distance(geog_point,
        ST_GeogFromText('POINT(-93.6204386 41.5853202)')
        ) / 1609.344)::numeric(8,5), 2) 
AS miles_from_dt
FROM farmers_markets
WHERE ST_DWithin(
geog_point,
ST_GeogFromText('POINT(-93.6204386 41.5853202)'),
10000)
ORDER BY miles_from_dt ASC;
"
dbGetQuery(con, sql)

# Need to load shapefiles through terminal
# shp2pgsql -I -s 4269 -W Latin1 nameofshapefile.shp nameoftable | psql -d gis_analysis -U postgres
# for this to work, must navigate to the folder where the shapefile is

# let's see if we're able to work with shapefiles in R

sql <- "
SELECT ST_AsText(geom)
FROM us_counties_2010_shp
LIMIT 1;
"
dbGetQuery(con, sql)
# sweet!

# find largest counties by area
sql <- "
SELECT name10,statefp10 AS st,
round(
( ST_Area(geom::geography) / 2589988.110336 )::numeric, 2
)  AS square_miles
FROM us_counties_2010_shp
ORDER BY square_miles DESC
LIMIT 5;
"
dbGetQuery(con, sql)
# that took some time!
# appears they're all in Alaska

# find out where a specific point is located
sql <- "SELECT name10,
       statefp10
FROM us_counties_2010_shp
WHERE ST_Within('SRID=4269;POINT(-118.3419063 44.0977076)'::geometry, geom);
"
dbGetQuery(con, sql)
# name10 returns name of a county, and the state fip

# I'm curious to see what columns are available in this shapefile
sql <- "
SELECT *
FROM us_counties_2010_shp
LIMIT 1;
"
shapefile <- dbGetQuery(con, sql)
colnames(shapefile)


# load new shapefiles, test input
# santafe_linearwater_2016
# santafe_roads_2016
sql <- "SELECT count(*) FROM santafe_linearwater_2016;"
dbGetQuery(con, sql)

# check the geometries
sql <- "
SELECT ST_GeometryType(geom)
FROM santafe_linearwater_2016
LIMIT 1;
"
dbGetQuery(con, sql)

# Now we'll see where roads and water in these two files intersect
sql <- "
SELECT water.fullname AS waterway,
       roads.rttyp,
roads.fullname AS road
FROM santafe_linearwater_2016 water JOIN santafe_roads_2016 roads
ON ST_Intersects(water.geom, roads.geom)
WHERE water.fullname = 'Santa Fe Riv'
ORDER BY roads.fullname;
"
dbGetQuery(con, sql)

# include the point where they intersect
sql <- "
SELECT water.fullname AS waterway,
       roads.rttyp,
roads.fullname AS road,
ST_AsText(ST_Intersection(water.geom, roads.geom))
FROM santafe_linearwater_2016 water JOIN santafe_roads_2016 roads
ON ST_Intersects(water.geom, roads.geom)
WHERE water.fullname = 'Santa Fe Riv'
ORDER BY roads.fullname
LIMIT 5;
"
dbGetQuery(con, sql)

# disconnect
dbDisconnect(con)
dbUnloadDriver(drv)

