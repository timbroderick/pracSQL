# set directory
setwd("~/anaconda3/envs/pracSQL/Chapter_10_stats")

# load libraries
library(tidyverse)
library("RPostgreSQL")
options("scipen" = 20)

# connect to postgres (remembert to turn it on)
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "aranalysis",
                 host = "localhost", port = 5432,
                 user = "tbroderick")

# Load up the census data we're examining
sql <- "CREATE TABLE acs_2011_2015_stats (
geoid varchar(14) CONSTRAINT geoid_key PRIMARY KEY,
county varchar(50) NOT NULL,
st varchar(20) NOT NULL,
pct_travel_60_min numeric(5,3) NOT NULL,
pct_bachelors_higher numeric(5,3) NOT NULL,
pct_masters_higher numeric(5,3) NOT NULL,
median_hh_income integer,
CHECK (pct_masters_higher <= pct_bachelors_higher)
);"
dbGetQuery(con, sql)

sql <- "COPY acs_2011_2015_stats
FROM '/Users/tbroderick/anaconda3/envs/pracSQL/Chapter_10_stats/acs_2011_2015_stats.csv'
WITH (FORMAT CSV, HEADER, DELIMITER ',');"
dbGetQuery(con, sql)

sql <- "SELECT count(*) FROM acs_2011_2015_stats"
dbGetQuery(con, sql)

sql <- "SELECT * FROM acs_2011_2015_stats"
df <- dbGetQuery(con, sql)



# Always good to also check distribution of the data as well
qplot(median_hh_income,
      data=df,
      bins = 100
)

median(df$median_hh_income, na.rm = TRUE)

qplot(pct_bachelors_higher,
      data=df,
      bins = 100
)
median(df$pct_bachelors_higher, na.rm = TRUE)

# get the R value for the correlation between education and income
sql <- "SELECT corr(median_hh_income, pct_bachelors_higher)
    AS bachelors_income_r
FROM acs_2011_2015_stats;"
dbGetQuery(con, sql)

# that is a different number than the R squared because it's just the R value
# r squared is this: https://www.postgresql.org/docs/9.1/functions-aggregate.html
sql <- "SELECT regr_r2(median_hh_income, pct_bachelors_higher)
AS bachelors_income_r
FROM acs_2011_2015_stats;"
dbGetQuery(con, sql)

# corr( y, x)
# y is the dependent variable, whose value depends on the value of something else
# x is the independent variable, what we're testing to see if y relies on it.

# let's see what that looks like with qplot
qplot(pct_bachelors_higher,median_hh_income,
      data=df) + 
  stat_smooth(method="lm")


# Here's how we can see everything in R
income <- lm(median_hh_income ~ pct_bachelors_higher, data = df)
summary(income)
# and here's how we get the R value with R
cor.test(df$pct_bachelors_higher,df$median_hh_income)

# Here's how we can show just R squared
summary(income)$r.squared



# R, correlation-coefficient found with cor.test shows the strength and direction
# of the relationship between two variables. Between 1 and -1, higher being stronger
# with 0 being no relationship and -1 being a negative correlation
# http://www.r-tutor.com/elementary-statistics/numerical-measures/correlation-coefficient

# R squared -> The coefficient of determination represents the percent of the data that is the closest
# to the line of best fit.  For example, if r = 0.922, then r 2 = 0.850, which means that
# 85% of the total variation in y can be explained by the linear relationship between x
# and y (as described by the regression equation).  The other 15% of the total variation
# in y remains unexplained.

# R measures the strength of the relationship, R squared measures how much of y 
# can be explained by the relationship to x

# https://www.investopedia.com/ask/answers/012615/whats-difference-between-rsquared-and-correlation.asp

# let's check additional correlations, both R and R squared
sql <- "SELECT 
round( corr(median_hh_income, pct_bachelors_higher)::numeric, 2) AS bachelors_income_r,
round(corr(pct_travel_60_min, median_hh_income)::numeric, 2) AS income_travel_r,
round(corr(pct_travel_60_min, pct_bachelors_higher)::numeric, 2) AS bachelors_travel_r
FROM acs_2011_2015_stats;"
dbGetQuery(con, sql)

sql <- "SELECT 
round( regr_r2(median_hh_income, pct_bachelors_higher)::numeric, 2) AS bachelors_income_r,
round( regr_r2(pct_travel_60_min, median_hh_income)::numeric, 2) AS income_travel_r,
round( regr_r2(pct_travel_60_min, pct_bachelors_higher)::numeric, 2) AS bachelors_travel_r
FROM acs_2011_2015_stats;"
dbGetQuery(con, sql)

# get the y intercept and slope
sql <- "SELECT
round( regr_slope(median_hh_income, pct_bachelors_higher )::numeric, 2 ) AS slope,
round( regr_intercept(median_hh_income, pct_bachelors_higher)::numeric, 2 ) AS y_intercept
FROM acs_2011_2015_stats;"
dbGetQuery(con, sql)

# in R
coefficients(income)

# so the value of y when x = 0 is 27901.1487
# it increases by 926.9503 for every point along X
# which means that at 100% bachelors degrees,
# Y would be
yvalue <- (926.9503 * 100) + 27901.1487
yvalue
# y value at 50%
yvalue50 <- (926.9503 * 50) + 27901.1487
yvalue50

# These values allow us to plot a predictive regression line

# population variance
sql <- "SELECT var_pop(median_hh_income)
FROM acs_2011_2015_stats;"
dbGetQuery(con, sql)

# Variance in R - Gets close but not quite
n <- nrow(df)
var(df$median_hh_income, na.rm = TRUE) * ( n - 1) / n

# standard deviation
sql <- "SELECT stddev_pop(median_hh_income)
FROM acs_2011_2015_stats;
"
dbGetQuery(con, sql)

# standard deviation in R
sd(df$median_hh_income, na.rm = TRUE)

# Covariance population
sql <- "SELECT covar_pop(median_hh_income, pct_bachelors_higher)
FROM acs_2011_2015_stats;"
dbGetQuery(con, sql)

# maybe in R, but I would need to filter na values

cov.pop <- function(x,y=NULL) {
  cov(x,y)*(NROW(x)-1)/NROW(x)
}

cov.pop(df$median_hh_income, df$pct_bachelors_higher)


# ------
# rankings

sql <- "CREATE TABLE widget_companies (
    id bigserial,
company varchar(30) NOT NULL,
widget_output integer NOT NULL
);

INSERT INTO widget_companies (company, widget_output)
VALUES
('Morse Widgets', 125000),
('Springfield Widget Masters', 143000),
('Best Widgets', 196000),
('Acme Inc.', 133000),
('District Widget Inc.', 201000),
('Clarke Amalgamated', 620000),
('Stavesacre Industries', 244000),
('Bowers Widget Emporium', 201000);"
dbGetQuery(con, sql)

sql <- "SELECT count(*) FROM widget_companies"
dbGetQuery(con, sql)

sql <- "SELECT
    company,
widget_output,
rank() OVER (ORDER BY widget_output DESC),
dense_rank() OVER (ORDER BY widget_output DESC)
FROM widget_companies;"
dfrank <- dbGetQuery(con, sql)

# rank within groups with partition
sql <- "CREATE TABLE store_sales (
    store varchar(30),
category varchar(30) NOT NULL,
unit_sales bigint NOT NULL,
CONSTRAINT store_category_key PRIMARY KEY (store, category)
);

INSERT INTO store_sales (store, category, unit_sales)
VALUES
('Broders', 'Cereal', 1104),
('Wallace', 'Ice Cream', 1863),
('Broders', 'Ice Cream', 2517),
('Cramers', 'Ice Cream', 2112),
('Broders', 'Beer', 641),
('Cramers', 'Cereal', 1003),
('Cramers', 'Beer', 640),
('Wallace', 'Cereal', 980),
('Wallace', 'Beer', 988);"
dbGetQuery(con, sql)

sql <- "SELECT
    category,
store,
unit_sales,
rank() OVER (PARTITION BY category ORDER BY unit_sales DESC)
FROM store_sales;"
dfpartition <- dbGetQuery(con, sql)


# finally, 
sql  <- "CREATE TABLE fbi_crime_data_2015 (
    st varchar(20),
city varchar(50),
population integer,
violent_crime integer,
property_crime integer,
burglary integer,
larceny_theft integer,
motor_vehicle_theft integer,
CONSTRAINT st_city_key PRIMARY KEY (st, city)
);

COPY fbi_crime_data_2015
FROM '/Users/tbroderick/anaconda3/envs/pracSQL/Chapter_10_stats/fbi_crime_data_2015.csv'
WITH (FORMAT CSV, HEADER, DELIMITER ',');"
dbGetQuery(con, sql)

sql <- "SELECT * FROM fbi_crime_data_2015
ORDER BY population DESC;"
dffbi <- dbGetQuery(con, sql)

sql <- "SELECT
    city,
st,
population,
property_crime,
round(
(property_crime::numeric / population) * 1000, 1
) AS pc_per_1000
FROM fbi_crime_data_2015
WHERE population >= 500000
ORDER BY (property_crime::numeric / population) DESC;"
df_crime <- dbGetQuery(con, sql)

# disconnect
dbDisconnect(con)
dbUnloadDriver(drv)

