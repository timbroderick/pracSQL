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

# load crime data
sql <- "CREATE TABLE crime_reports (
    crime_id bigserial PRIMARY KEY,
date_1 timestamp with time zone,
date_2 timestamp with time zone,
street varchar(250),
city varchar(100),
crime_type varchar(100),
description text,
case_number varchar(50),
original_text text NOT NULL
);"

dbGetQuery(con, sql)

sql <- "COPY crime_reports (original_text)
FROM '/Users/tbroderick/anaconda3/envs/pracSQL/Chapter_13_text/crime_reports.csv'
WITH (FORMAT CSV, HEADER OFF, QUOTE '\"');"
dbGetQuery(con, sql)


# use regexp_match to grab the first dates
# remember we need to escape \
sql <- "SELECT crime_id,
       regexp_match(original_text, '\\d{1,2}\\/\\d{1,2}\\/\\d{2}')
FROM crime_reports;"
dbGetQuery(con, sql)
# gets the first date as an array.
# but we can store that in a datafame if we want. 
# curly brackets turn into parenthesis
dfdates <- dbGetQuery(con, sql)

# can I do this with pure R? 
# As far as I can tell, I need to turn this into a vector
sql <- "SELECT original_text FROM crime_reports;"
df <- dbGetQuery(con, sql)

# turn the data into a vector
dfv <- df %>% pull(original_text)
# and this works without any errors
?data.frame
ext <- data.frame( str_extract(dfv , '\\d{1,2}\\/\\d{1,2}\\/\\d{2}') )
colnames(ext) <- c("dates")

str_extract(dfv[1] , '\\d{1,2}\\/\\d{1,2}\\/\\d{2}')

?str_extract

# to grab all dates wih regexp_matches
# remember we need to escape \
sql <- "SELECT crime_id,
regexp_matches(original_text, '\\d{1,2}\\/\\d{1,2}\\/\\d{2}', 'g')
FROM crime_reports;"
dbGetQuery(con, sql)

# in R
ext <- data.frame( str_extract_all(dfv, '\\d{1,2}\\/\\d{1,2}\\/\\d{2}') ) 
# not a great result. I can get everything that I get out of postgres
# but the data frame in R is messy. This might help: https://www.garrickadenbuie.com/project/regexplain/

# if we just wanted the second value, we could use regexp_match
# and look for a date with a hypen in front of it.
# to grab just the date and not the hyphen, place what we want in ()

sql <- "SELECT crime_id,
       regexp_match(original_text, '-(\\d{1,2}\\/\\d{1,2}\\/\\d{2})')
FROM crime_reports;"
dbGetQuery(con, sql)

# Let's go on without the R versions

# get first hour or second hour. Note what's in () gets returned
sql <- "SELECT crime_id,
       regexp_match(original_text, '\\d{2}\\n\\d{4}-(\\d{4})')
FROM crime_reports;"
dbGetQuery(con, sql)

# get street only
# \d+ matches any digit appearing one or more times
# space, then .+ is any character appearing one or more times
# until the (?:) which looks for what should be the end
sql <- "SELECT crime_id,
regexp_match(original_text, 'hrs.\\n(\\d+ .+(?:Sq.|Plz.|Dr.|Ter.|Rd.))')
FROM crime_reports;"
dbGetQuery(con, sql)

# get the city
# look for one word \w+ or up to three words \\w+|\\w+|\\w+
sql <- "SELECT crime_id,
regexp_match(original_text, '(?:Sq.|Plz.|Dr.|Ter.|Rd.)\\n(\\w+ \\w+|\\w+|\\w+)\\n')
FROM crime_reports;"
dbGetQuery(con, sql)

# crime type
sql <- "SELECT crime_id,
regexp_match(original_text, '\\n(?:\\w+ \\w+|\\w+|\\w+)\\n(.*):')
FROM crime_reports;"
dbGetQuery(con, sql)

# description
sql <- "SELECT crime_id,
regexp_match(original_text, ':\\s(.+)(?:C0|SO)')
FROM crime_reports;"
dbGetQuery(con, sql)

# case number
sql <- "SELECT crime_id,
regexp_match(original_text, '(?:C0|SO)[0-9]+')
FROM crime_reports;"
dbGetQuery(con, sql)


# let's put it all together in a dataframe
sql <- "SELECT 
    regexp_match(original_text, '(?:C0|SO)[0-9]+') AS case_number,
regexp_match(original_text, '\\d{1,2}\\/\\d{1,2}\\/\\d{2}') AS date_1,
regexp_match(original_text, '\\n(?:\\w+ \\w+|\\w+|\\w+)\\n(.*):') AS crime_type,
regexp_match(original_text, '(?:Sq.|Plz.|Dr.|Ter.|Rd.)\\n(\\w+ \\w+|\\w+|\\w+)\n') AS city
FROM crime_reports;"
df <- dbGetQuery(con, sql)

# grab it out of the {}
sql <- "SELECT crime_id,
(regexp_match(original_text, '(?:C0|SO)[0-9]+'))[1] AS case_number
FROM crime_reports;"
dbGetQuery(con, sql)

# can I do that here?

sql <- "SELECT 
(regexp_match(original_text, '(?:C0|SO)[0-9]+'))[1] AS case_number,
(regexp_match(original_text, '\\d{1,2}\\/\\d{1,2}\\/\\d{2}'))[1] AS date_1,
(regexp_match(original_text, '(?:Sq.|Plz.|Dr.|Ter.|Rd.)\\n(\\w+ \\w+|\\w+|\\w+)\n'))[1] AS city,
(regexp_match(original_text, '\\n(?:\\w+ \\w+|\\w+|\\w+)\\n(.*):'))[1] AS crime_type,
(regexp_match(original_text, ':\\s(.+)(?:C0|SO)'))[1] AS description
FROM crime_reports;"
df <- dbGetQuery(con, sql)

# let's see what it looks like when we save it
write_csv(df,'test.csv', na = '')

# we know there are line breaks in the description field, so we can fix that in R
df$description <- str_replace(df$description,"\n"," ")

# let's see if that worked
write_csv(df,'test2.csv', na = '')

# almost. Is there a str_replace all?
# recreate the df, then
df$description <- str_replace_all(df$description,"\n"," ")

# let's see if that worked
write_csv(df,'test3.csv', na = '')
# yes

sql <- "SELECT * FROM crime_reports;"
dbGetQuery(con, sql)

# updating crime_reports table with extracted data
sql <- "UPDATE crime_reports SET date_1 = (
  (regexp_match(original_text, '\\d{1,2}\\/\\d{1,2}\\/\\d{2}'))[1]
  || ' ' ||
  (regexp_match(original_text, '\\/\\d{2}\\n(\\d{4})'))[1] 
  ||' US/Eastern')::timestamptz;"
  
dbGetQuery(con, sql)

sql <- "SELECT crime_id, date_1, original_text FROM crime_reports;"
dfx <- dbGetQuery(con, sql)


sql <- "UPDATE crime_reports 
  SET date_1 = ((regexp_match(original_text, '\\d{1,2}\\/\\d{1,2}\\/\\d{2}'))[1]
  || ' ' ||
  (regexp_match(original_text, '\\/\\d{2}\\n(\\d{4})'))[1] 
  ||' US/Eastern')::timestamptz,
  date_2 = 
  CASE 
  WHEN (SELECT regexp_match(original_text, '-(\\d{1,2}\\/\\d{1,2}\\/\\d{1,2})') IS NULL)
  AND (SELECT regexp_match(original_text, '\\/\\d{2}\\n\\d{4}-(\\d{4})') IS NOT NULL)
  THEN 
  ((regexp_match(original_text, '\\d{1,2}\\/\\d{1,2}\\/\\d{2}'))[1]
  || ' ' ||
  (regexp_match(original_text, '\\/\\d{2}\\n\\d{4}-(\\d{4})'))[1] 
  ||' US/Eastern')::timestamptz 
  WHEN (SELECT regexp_match(original_text, '-(\\d{1,2}\\/\\d{1,2}\\/\\d{1,2})') IS NOT NULL)
  AND (SELECT regexp_match(original_text, '\\/\\d{2}\\n\\d{4}-(\\d{4})') IS NOT NULL)
  THEN 
  ((regexp_match(original_text, '-(\\d{1,2}\\/\\d{1,2}\\/\\d{1,2})'))[1]
  || ' ' ||
  (regexp_match(original_text, '\\/\\d{2}\\n\\d{4}-(\\d{4})'))[1] 
  ||' US/Eastern')::timestamptz 
  ELSE NULL 
  END,
  street = (regexp_match(original_text, 'hrs.\\n(\\d+ .+(?:Sq.|Plz.|Dr.|Ter.|Rd.))'))[1],
  city = (regexp_match(original_text,'(?:Sq.|Plz.|Dr.|Ter.|Rd.)\\n(\\w+ \\w+|\\w+|\\w+)\\n'))[1],
  crime_type = (regexp_match(original_text, '\\n(?:\\w+ \\w+|\\w+|\\w+)\\n(.*):'))[1],
  description = (regexp_match(original_text, ':\\s(.+)(?:C0|SO)'))[1],
  case_number = (regexp_match(original_text, '(?:C0|SO)[0-9]+'))[1];"
dbGetQuery(con, sql)

sql <- "SELECT case_number, date_1, street, city, crime_type, description
FROM crime_reports;"
dfy <- dbGetQuery(con, sql)

# disconnect
dbDisconnect(con)
dbUnloadDriver(drv)

