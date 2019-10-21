# set directory
setwd("~/anaconda3/envs/pracSQL/Chapter_13_text")

# load libraries
library(tidyverse)
#library('readxl')
library("RPostgreSQL")
options("scipen" = 10)

# connect to postgres (remembert to turn it on)
drv <- dbDriver("PostgreSQL")
# connect to aranalysis (for pracSQL)
con <- dbConnect(drv, dbname = "aranalysis",
                   host = "localhost", port = 5432,
                   user = "tbroderick")



# upper(), lower(), initcap
sql <- "SELECT initcap('hello');"
dbGetQuery(con, sql)
# in R
str_to_lower('hello')
str_to_upper('HELLO')
str_to_title('hello')


# get length of a string
sql <- "SELECT char_length(' Pat ');"
dbGetQuery(con, sql)
# in R
str_length(' Pat ')

# find position of a character
sql <- "SELECT position(', ' in 'Tan, Bella');"
dbGetQuery(con, sql)
# in R 
str_locate_all(pattern =', ','Tan, Bella')
# https://stringr.tidyverse.org/index.html
# https://stackoverflow.com/questions/14249562/find-the-location-of-a-character-in-string


# get length of a string while triming spaces
sql <- "SELECT char_length(trim(' Pat '));"
dbGetQuery(con, sql)
# in R
str_length(str_trim(' Pat '))

# removing characters
sql <- "SELECT trim('s' from 'socks');"
dbGetQuery(con, sql)
# ltrim and rtrim
sql <- "SELECT ltrim('socks','s');"
dbGetQuery(con, sql)
# in R
?str_remove
str_remove('socks','s')
str_remove('socks','^s') # ^ beginning of a word
str_remove('socks','s$') # $ end of a word
#http://www2.stat.duke.edu/~cr173/Sta523_Fa15/regex.html

# extracting characters
sql <- "SELECT left('708-555-1212',3);"
dbGetQuery(con, sql)
sql <- "SELECT right('708-555-1212',8);"
dbGetQuery(con, sql)
# in r
str_sub('708-555-1212',1,3)
str_sub('708-555-1212',-8)

# replace items in a string
sql <- "SELECT replace('bat','b','c');"
dbGetQuery(con, sql)
# In R
str_replace("bat","b","c")

# regular expressions
# Table 13-2: Regular Expression Matching Examples

# Any character one or more times
sql <- "SELECT substring('The game starts at 7 p.m. on May 2, 2019.' from '.+');"
dbGetQuery(con, sql)
# in R
str_match('The game starts at 7 p.m. on May 2, 2019.','.+')

# One or two digits followed by a space and p.m. 
# Note that we need to escape an \ for this to work
sql <- "SELECT substring('The game starts at 7 p.m. on May 2, 2019.' from '\\d{1,2} (?:a.m.|p.m.)');"
dbGetQuery(con, sql)
str_match('The game starts at 7 p.m. on May 2, 2019.','\\d{1,2} (?:a.m.|p.m.)')

# One or more word characters at the start
sql <- "SELECT substring('The game starts at 7 p.m. on May 2, 2019.' from '^\\w+');"
dbGetQuery(con, sql)
str_match('The game starts at 7 p.m. on May 2, 2019.' , '^\\w+')

# One or more word characters followed by any character at the end.
sql <- "SELECT substring('The game starts at 7 p.m. on May 2, 2019.' from '\\w+.$');"
dbGetQuery(con, sql)
str_match('The game starts at 7 p.m. on May 2, 2019.' , '\\w+.$')

# The words May or June
sql <- "SELECT substring('The game starts at 7 p.m. on May 2, 2019.' from 'May|June');"
dbGetQuery(con, sql)
str_match('The game starts at 7 p.m. on May 2, 2019.' , 'May|June')

# Four digits
sql <- "SELECT substring('The game starts at 7 p.m. on May 2, 2019.' from '\\d{4}');"
dbGetQuery(con, sql)
str_match('The game starts at 7 p.m. on May 2, 2019.' , '\\d{4}')

# May followed by a space, digit, comma, space, and four digits.
sql <- "SELECT substring('The game starts at 7 p.m. on May 2, 2019.' from 'May \\d, \\d{4}');"
dbGetQuery(con, sql)
str_match('The game starts at 7 p.m. on May 2, 2019.' , 'May \\d, \\d{4}')

#write_csv(df,'csv/xxx.csv', na = '')


# disconnect
dbDisconnect(con)
dbUnloadDriver(drv)

