# set directory
setwd("~/anaconda3/envs/notebook/MHMetrics/mhm_data")

# load libraries
library(tidyverse)
#library('readxl')
library("RPostgreSQL")
options("scipen" = 10)

# connect to postgres (remembert to turn it on)
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "mhmetrics",
                 host = "localhost", port = 5432,
                 user = "tbroderick")


# Getting a basic count
sql <- "SELECT count(*) FROM hospitals
WHERE what != 'closed' OR active != 'no';"
dbGetQuery(con, sql)

# grabbing data across tables
# making sure to filter out closed or inactive cms_ids
# get complete fiscal years (when dealing with numbers)
# and making sure to have fyears match
sql <- "SELECT hospitals.cms_id, hospitals.facility, descrip.fyear, descrip.fydays, descrip.prov_type, 
quality.nurses, quality.doctors, quality.recommend, quality.high_rating 
FROM hospitals LEFT JOIN descrip ON hospitals.cms_id = descrip.cms_id
LEFT JOIN quality ON hospitals.cms_id = quality.cms_id
WHERE descrip.fyear = quality.fyear AND (descrip.fydays = '365' OR descrip.fydays = '366')
AND (what != 'closed' OR active != 'no') AND 
(descrip.prov_type = 'Short-Term' OR descrip.prov_type = 'Critical Access Hospitals' OR descrip.prov_type = 'Childrens Hospitals');"
df <- dbGetQuery(con, sql)

# summarise by year and prov_type
dfsum <- df %>% 
  group_by(fyear,prov_type) %>%
  summarise(reports = n(),nurses = mean(nurses, na.rm=TRUE), doctors = mean(doctors, na.rm=TRUE), recommend = mean(recommend, na.rm=TRUE), high_rating = mean(high_rating, na.rm=TRUE) )

# selecting, grouping and counting as in pivot tables
sql <- "SELECT hospitals.cms_id, hospitals.facility, hospitals.state,
descrip.prov_type, descrip.system, regions.region 
FROM hospitals LEFT JOIN descrip ON hospitals.cms_id = descrip.cms_id
LEFT JOIN regions ON hospitals.state = regions.state 
WHERE descrip.fyear = '2017'  AND (what != 'closed' OR active != 'no') AND
(descrip.prov_type = 'Short-Term' OR descrip.prov_type = 'Critical Access Hospitals' OR descrip.prov_type = 'Childrens Hospitals');"
df <- dbGetQuery(con, sql)

dfsum <- df %>% 
  group_by(region) %>%
  count(system,state)

dfsum2 <- df %>% 
  group_by(system) %>%
  count(region,state)

dfsum3 <- df %>% 
  group_by(region) %>%
  summarise(systems = n_distinct(system), facilites = n_distinct(cms_id))

dfsum4 <- df %>% 
  group_by(region,subregion) %>%
  summarise(systems = n_distinct(system), facilites = n_distinct(cms_id))

# getting results by year and appending
# connect to aranalysis
conar <- dbConnect(drv, dbname = "aranalysis",
                 host = "localhost", port = 5432,
                 user = "tbroderick")


# more elaborate
sql <- "SELECT taxdoc, ein, entity, fyend, name, base, all_adjtotal FROM salaries;"
df <- dbGetQuery(conar, sql) 

# first we get and establish a dataframe
getyear <- filter(df, `fyend` == '2013')
# group by ein, sort by total, take top three
allthree <- getyear %>% 
  group_by(taxdoc) %>% 
  arrange(desc(all_adjtotal), .by_group = TRUE) %>% 
  slice(1) 

# then we do the same thing for each subsequent year
# appending that data to the df we already established
years <- c("2014","2015","2016","2017","2018")
for (year in years) {
  print(paste(year),quote=FALSE) # prints the year
  getyear <- filter(df, `fyend` == year)
  # group by ein, sort by total, take top three
  dfget <- getyear %>% 
    group_by(taxdoc) %>% 
    arrange(desc(all_adjtotal), .by_group = TRUE) %>% 
    slice(1)
  allthree <- rbind(allthree,dfget)
}

getcount <- allthree %>% 
  group_by(`fyend`) %>% 
  summarise( count = n() )

write_csv(df,'.csv')

# disconnect
dbDisconnect(con)
dbDisconnect(conar)
dbUnloadDriver(drv)

