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
WHERE what != 'closed' AND active != 'no';"
dbGetQuery(con, sql)

sql <- "SELECT * FROM hospitals
WHERE what != 'closed' AND active != 'no';"
df <- dbGetQuery(con, sql)


# grabbing data across tables
# making sure to filter out closed or inactive cms_ids
# get complete fiscal years (when dealing with numbers)
# and making sure to have fyears match
sql <- "SELECT hospitals.cms_id, hospitals.facility, hospitals.state,
hospitals.active, hospitals.what, descrip.system, 
descrip.fyear, descrip.fydays, descrip.prov_type, quality.hsp_lmv, 
regions.region, regions.subregion
FROM hospitals LEFT JOIN descrip ON hospitals.cms_id = descrip.cms_id
LEFT JOIN quality ON hospitals.cms_id = quality.cms_id
LEFT JOIN regions ON hospitals.state = regions.state
WHERE descrip.fyear = quality.fyear AND (descrip.fydays = '365' OR descrip.fydays = '366')
AND hospitals.active != 'no' AND 
(descrip.prov_type = 'Short-Term' OR descrip.prov_type = 'Critical Access Hospitals' OR descrip.prov_type = 'Childrens Hospitals');"
df <- dbGetQuery(con, sql)

unique(df$active)
unique(df$what)

dfcheck <- filter(df,active =="yes" & what == "closed")
dfcount <- dfcheck %>% 
  group_by(cms_id) %>% 
  summarize(count=n())

# summarise by year and prov_type
dfsum <- df %>% 
  group_by(fyear,prov_type) %>%
  summarise(reports = n(),hsp_lmv_mean = mean(hsp_lmv, na.rm=TRUE), hsp_lmv_median = median(hsp_lmv, na.rm=TRUE) )


dfsum <- df %>% 
  group_by(region) %>%
  count(system,state)

dfsum <- df %>% 
  group_by(system) %>%
  count(region,state)

dfsum <- df %>% 
  group_by(region) %>%
  summarise(systems = n_distinct(system), facilites = n_distinct(cms_id))

dfsum <- df %>% 
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

