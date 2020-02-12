# set directory
setwd("~/anaconda3/envs/notebook/Cost_reports")

# load libraries
library(tidyverse)
#library('readxl')
library("RPostgreSQL")
options("scipen" = 10)


# read from an excel file
#url <- '1_data/xxx.xlsx'
#excel_sheets(url)
#read excel and skip first line"
#dfread <- read_excel(url, sheet="xxx",skip=1)


# connect to postgres (remembert to turn it on)
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "crs",
                 host = "localhost", port = 5432,
                 user = "tbroderick")


# execute query
sql <- "SELECT count(*) FROM hospitals;"
dbGetQuery(con, sql)

# excludes territories
sql <- "SELECT count(*) FROM reports_fyear;"
dbGetQuery(con, sql)

# all territories, including Puerto Rico
sql <- "SELECT count(*) FROM reportsall_fyear;"
dbGetQuery(con, sql)
# filter those territories except for PR
#df <- df %>% filter(!state %in% c("Virgin Islands","Other","Guam"))


sql <- "SELECT count(*) FROM ws_g3s;"
dbGetQuery(con, sql)

sql <- "SELECT count(*) FROM ws_else;"
dbGetQuery(con, sql)



# let's grab the columns we need to calculate margins
sql <- "SELECT rpt_rec_num,g300000_00100_00300,g300000_00100_02500,g300000_00100_02900 FROM ws_g3s;"
ws <- dbGetQuery(con, sql)
summary(ws)

# now grab the reports_fyear
sql <- "SELECT * FROM reports_fyear;"
peers <- dbGetQuery(con, sql)

dfa <- merge(x=peers,y=ws,by="rpt_rec_num",all.x=TRUE)

# calculate margin - make sure not to round too much to account for extremely small nets!
dfa$margin <- as.numeric( ifelse(dfa$g300000_00100_00300+dfa$g300000_00100_02500=='0','0',round( (dfa$g300000_00100_02900/(dfa$g300000_00100_00300+dfa$g300000_00100_02500))*100,10) ) )
# check numbers
summary(dfa$margin)

############## filter for na's and truly zero margins
df <- dfa %>% filter(margin !=0.000000000&!is.na(margin)) 

############## IQR range
# first we set the years we want in a variable called years
years <- c("2013","2014","2015","2016","2017","2018")
# next we're going to create an empty dataframe with the columns we want to fill
df_byyear <- data.frame(
  fyear=integer(),
  count=integer(),
  lower=numeric(),
  q25=numeric(),
  q50=numeric(),
  q75=numeric(),
  upper=numeric(),
  iqr=numeric(),
  cut_off=numeric(),
  mean=numeric(),
  trimmedmean=numeric(),
  count_lower=integer(),
  count_upper=integer(),
  outliers_perc=numeric()
)

# create an empty dataframe to hold data without outliers
df_nooutliers <- df[0,]

# then we iterate over the data, by year,
# and fill those columns
for (year in years) {
  print(paste(year),quote=FALSE)
  dfget <- filter(df,fyear==year)
  # first find the quartiles 
  dfbind <- setNames(data.frame(matrix(ncol = 14, nrow = 1)), 
                     c("fyear","count","q25","q50","q75","iqr","cut_off","lower","upper","mean","trimmedmean","count_lower","count_upper","outliers_perc"))
  dfbind$fyear <- as.integer(year)
  dfbind$count <- as.integer(nrow(dfget))
  dfbind$q25 <- round( quantile(dfget$margin, .25, na.rm=TRUE),2)
  dfbind$q50 <- round( quantile(dfget$margin, .50, na.rm=TRUE),2)
  dfbind$q75 <- round( quantile(dfget$margin, .75, na.rm=TRUE),2)
  # now find the interquartile range
  dfbind$iqr <- dfbind$q75 - dfbind$q25
  # calculate the outlier cutoff, which is 1.5 of the iqr
  dfbind$cut_off <- round( dfbind$iqr * 1.5,2)
  # that means anything below the lower bound or higher than the upper bound is considered an outlier
  dfbind$lower <- dfbind$q25 - dfbind$cut_off
  dfbind$upper <- dfbind$q75 + dfbind$cut_off
  dfbind$mean <- round( mean(dfget$margin, na.rm=TRUE) ,2)
  dfbind$trimmedmean <- round( mean( dfget$margin[dfget$margin>=dfbind$lower&dfget$margin<=dfbind$upper], na.rm=TRUE),5 )
  dfbind$count_lower <- as.integer( nrow( filter(dfget,margin <= dfbind$lower) ) )
  dfbind$count_upper <- as.integer( nrow( filter(dfget,margin > dfbind$upper) ) )
  dfbind <- select(dfbind,"fyear","count","lower","q25","q50","q75","upper","iqr","cut_off","mean","trimmedmean","count_lower","count_upper","outliers_perc")
  dfbind$outliers_perc <- round( ((dfbind$count_lower+dfbind$count_upper)/dfbind$count)*100,2)
  df_byyear <- bind_rows(df_byyear,dfbind)
  # create a dataframe that excludes the outliers
  dffilter <- dfget %>% filter(margin>=dfbind$lower&margin<=dfbind$upper)
  df_nooutliers <- bind_rows(df_nooutliers,dffilter)
}

# save the IQR info
write_csv(df_byyear,'2_output/margins_iqr.csv', na = '')
# Save the base dataframe
write_csv(df,'2_output/margins_all.csv', na = '')
# Save the dataframe with no outliers
write_csv(df_nooutliers,'2_output/margins_trimmed.csv', na = '')

# now let's get our summaries using df_nooutliers
dfsum_trimmed <- df_nooutliers %>% 
  group_by(fyear,ownership,type) %>% 
  summarize(count=n(),
            med_margin=round(median(margin,na.rm=TRUE),2),
            avg_margin=round(mean(margin,na.rm=TRUE),2))

# save
write_csv(dfsum_trimmed,'2_output/margins_sum_trimmed.csv', na = '')


# if we want to go wide, here's how
#dfsum_trimmed <- pivot_wider(dfsum_trimmed,id_cols = c("type","ownership"), 
#                             names_from = "fyear", 
#                             values_from = c("med_margin","avg_margin") )


# disconnect
dbDisconnect(con)
dbUnloadDriver(drv)

