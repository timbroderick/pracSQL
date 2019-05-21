# This file goes beyond what we need for our databreach tracker
# https://www.modernhealthcare.com/assets/graphics/evergreen/breachtracker-20181022/child.html
# to look at results by year

# first step is to download the data from https://ocrportal.hhs.gov/ocr/breach/breach_report.jsf
# we'll need both the cases under investigation (what you see there)
# and the archive (click the archive button)

# To download a csv of both, look a the gray bar just above the table
# called "Breach Report Results." On that bar and to the right there are four little icons
# hover over them and a little tooltip will popup with a description
# you'll want to click the third icon, "Export as CSV"

# this script assumes that you've downloaded and placed those two files
# in a folder called csv within the same overall folder as this script

# set the working directory
setwd("~/anaconda3/envs/notebook/databreaches")

# load libraries
library(tidyverse)
library(lubridate) # will allow us to do a lot with dates
options("scipen" = 10) # this makes sure big numbers don't devolve into scientific notation

# check the file names. This is for a mac. Windows may be different
# learn more at: https://stat.ethz.ch/R-manual/R-devel/library/base/html/list.files.html
files <- list.files("csv/")
for (file in files) {
  print(paste(file),quote=FALSE) # this should print the filenames that are in the csv dir
}

# Reading these dates in requires a special format: %m/%d/%Y
# Note the capitol Y for years as 0000
dfopen <- read_csv("csv/breach_report.csv", col_types = cols("Breach Submission Date" = col_date(format = "%m/%d/%Y")), na = "")
dfclosed <- read_csv("csv/breach_report(1).csv", col_types = cols("Breach Submission Date" = col_date(format = "%m/%d/%Y")), na = "")
# add in the status just in case we want to examine open v closed at some point
dfopen$status <- "open"
dfclosed$status <- "closed"

# now append the two together
df <- rbind(dfopen, dfclosed)

# select just the columns we want and rename them
dfa <- select(df,"Individuals Affected","Breach Submission Date","Type of Breach","Location of Breached Information")
colnames(dfa) <- c("individuals","breaches","type","location")

head(dfa) # now take a look at what we have so far

# I want to examine breaches by type and location by year,
# but I also want to end up with a file suitable for a spreadsheet 
# that a reporter can open and review as well
# https://www.rforexcelusers.com/make-pivottable-in-r/

# still getting used to chaining commands
# Here we use lubridate and mutate to create a year column
# then we groupby year, count type, sort descending within groups
# and finally slice the top one for each group
bytype <- dfa %>% 
  mutate( year = year(breaches) ) %>% 
  group_by(year) %>% 
  count(type) %>% 
  arrange(desc(n), .by_group = TRUE) %>% 
  slice(1)

# Do that again, but for locations
bylocate <- dfa %>% 
  mutate( year = year(breaches) ) %>% 
  group_by(year) %>% 
  count(location) %>% 
  arrange(desc(n), .by_group = TRUE) %>% 
  slice(1)

# Now we count the number of breaches and total of individuals affected, by year
dfsum <- dfa %>% 
  mutate(year = year(breaches) ) %>% 
  group_by(year) %>% 
  filter(!is.na(individuals)) %>% 
  summarise(number_breaches = n(),indv_affected = sum(individuals)) 

# join dfsum with bytype, and figure type by percent of total breaches
dfjoin1 <- merge(x = dfsum, y = bytype, by.x="year", by.y="year", all.x=TRUE)
dfjoin1$type_perctotal <- round( (dfjoin1$n / dfjoin1$number_breaches) * 100,2)

# join the location data, and figure by percent of total breacehs
dfjoin2 <- merge(x = dfjoin1, y = bylocate, by.x="year", by.y="year", all.x=TRUE)
dfjoin2$locate_perctotal <- round( (dfjoin2$n.y / dfjoin2$number_breaches) * 100,2)

# rename the columns to be more reader friendly, then save as csv
colnames(dfjoin2) <- c("Year","Number of breaches","Individuals affected","Top breach by type","type (count)","type (as percent of all breaches)","top breach by location","location (count)","location (as percent of all breaches)")
write_csv(dfjoin2,'csv/breaches_byyear.csv')
