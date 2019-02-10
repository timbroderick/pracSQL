# This file automates the data process for our databreach tracker
# https://www.modernhealthcare.com/assets/graphics/evergreen/breachtracker-20181022/child.html

# first step is to download the data from https://ocrportal.hhs.gov/ocr/breach/breach_report.jsf
# we'll need both the cases under investigation (what you see there)
# and the archive (click the archive button)

# To download a csv of both, look a the gray bar just above the table
# called "Breach Report Results." On that bar and to the right there are four little icons
# hover over them and a little tooltip will popup with a description
# you'll want to click the third icon, "Export as CSV"

# this script assumes that you've downloaded and placed the two files
# in a folder called csv, that's in the same overall folder with this script

# set the working directory
setwd("~/anaconda3/envs/notebook/databreaches")

# load libraries
library(tidyverse)
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
# add in the status just in case
dfopen$status <- "open"
dfclosed$status <- "closed"

# now append the two together
df <- rbind(dfopen, dfclosed)

# saving combined
write_csv(df,'csv/combined.csv')

lapply(df, class) # check the classes of the columns. We want the dates to be dates

# select just the columns we want and rename them
dfa <- select(df,"Individuals Affected","Breach Submission Date")
colnames(dfa) <- c("individuals","breaches")

# create columns of year, month to prep for grouping
dfa$breachd <- format(as.Date(dfa$breaches), "%Y-%m") # need this to sort
dfa$breachdate <- format(as.Date(dfa$breaches), "%b-%Y") # need this for presentation

# now take a look at what we have so far
head(dfa)

# we have everything we need to do essentially a pivot table in R
# what we want to end up with is three columns
# A column with a month an year like Jan-2019
# A column that counts the number of breaches in each month
# A column that totals the number of individuals affected by breaches for each month
# https://www.rforexcelusers.com/make-pivottable-in-r/
# here's how we do that:

# first group by year, month, then sort descending
dfgroup <- group_by(dfa, breachd,breachdate) %>% arrange(desc(breachd))
# for each month, count the number of breaches and total up the individuals affected
dfgroup <- summarise(dfgroup,countbr = n(),sumind = sum(individuals)) 

# take a look at what we have
head(dfgroup)

# save to csv 
write_csv(dfgroup,'csv/update.csv')

#------ 
# Finally, we create our top ten list for the month we're examining
# that's just a matter of slicing and sorting

# first get the columns we want
dflist <- select(dfopen,'Name of Covered Entity','State','Covered Entity Type','Individuals Affected','Breach Submission Date','Type of Breach','Location of Breached Information') 
# rename them
colnames(dflist) <- c('entity','state','org','affect','date','type','location')
# slice the month we want and sort by top number of indv. affected
dflist <- filter(dflist, (date >= '2019-01-01') & (date <= '2019-01-31') ) %>% arrange(desc(affect))
# get the top ten
dflist <- dflist[1:10,]
# save to csv 
write_csv(dflist,'csv/topten.csv')
