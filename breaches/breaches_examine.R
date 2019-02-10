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
dfa <- select(df,"Individuals Affected","Breach Submission Date","Type of Breach","Location of Breached Information")
colnames(dfa) <- c("individuals","breaches","type","location")

# create columns of year, month to prep for grouping
dfa$breachd <- format(as.Date(dfa$breaches), "%Y-%m") # need this to sort

dfa$breachdate <- format(as.Date(dfa$breaches), "%b-%Y") # need this for presentation

dfa$year <- format(as.Date(dfa$breaches), "%Y") # need this to examine by year

write_csv(dfa,'csv/examine.csv') # save to file

# now take a look at what we have so far
head(dfa)

# I want to examine breaches by type and location by year.
# I know how to do that using excel, will play with that using google
# but I want to learn how to do that with R
# https://www.rforexcelusers.com/make-pivottable-in-r/


# grouping by year
dfgroup <- group_by(dfa, year) %>% arrange(desc(year))

countype <- dfgroup %>% count(type) # counts the type for each year
countlocate <- dfgroup %>% count(location) # counts the locations for each year
dfgroup <- summarise(dfgroup,countbr = n(),sumind = sum(individuals)) # why is 2013 NA ?

