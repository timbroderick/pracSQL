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
str_to_lower('HELLO')
str_to_upper('hello')
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
df <- dbGetQuery(con, sql)

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

# grab it out of the {} by adding [1] at the end of the query
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

# Using Case to update and handle inconsistencies in the data
# from page 26

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

# let's test the results
sql <- "
SELECT date_1,street,city,crime_type FROM crime_reports;
"
dfcrime <- dbGetQuery(con, sql)

# using regular expressions with WHERE
sql <- "SELECT geo_name
FROM us_counties_2010
WHERE geo_name ~* '(.+lade.+|.+lare.+)'
ORDER BY geo_name;
"
dbGetQuery(con, sql)

# ~ matches case sensitive, ~* is insenstive.
# So !~ is not match case senstive for anything starting with Wash

sql <- "SELECT geo_name
FROM us_counties_2010
WHERE geo_name ~* '.+ash.+' AND geo_name !~ 'Wash.+'
ORDER BY geo_name;;
"
dbGetQuery(con, sql)

#Regular expression functions to replace and split

sql <- "SELECT regexp_replace('05/12/2018', '\\d{4}', '2017');"
dbGetQuery(con, sql)
sql <- "SELECT regexp_split_to_table('Four,score,and,seven,years,ago', ',');"
dbGetQuery(con, sql)
sql <- "SELECT regexp_split_to_array('Phil Mike Tony Steve', ' ');"
df <- dbGetQuery(con, sql)
# arrays are a problem, returning curly brackets
# regexp_split_to_array
# {Phil,Mike,Tony,Steve}
# here's a few ways to remove those

gsub("\\{|\\}", "",df)
gsub("[{}]", "", df)
gsub("^\\{+(.+)\\}+$", '\\1', df)

# so let's see what that gives us
dftry <- as.array( gsub("\\{|\\}", "",df) )
dftry <- as.data.frame( unlist(strsplit(dftry, ",")) )

# Find the length of an array
sql <- "SELECT array_length(regexp_split_to_array('Phil Mike Tony Steve', ' '), 1);"
dbGetQuery(con, sql)

# FULL TEXT SEARCH

# Full-text search operators:
# & (AND)
# | (OR)
# ! (NOT)

# Listing 13-15: Converting text to tsvector data

sql <- "SELECT to_tsvector('I am walking across the sitting room to sit with you.');"
dbGetQuery(con, sql)

# alas, here is where we're unable to use R apparently
# as we get an error that to_tsvector is unrecognized field type
# continue using pgAdmin 4, but notes included here

# this returns 
# 'across':4 'room':7 'sit':6,9 'walk':3

# to_tsvector automatically removes non-helpful search terms like I and am to
# it reduces words to their base, removing sufffixes - walking to walk
# the numbers represent the word's positions in the original string
# key word is lexemes

# loading the speeches table
# wonder what kind of full-text search I can do in R with this?
sql <- "
CREATE TABLE president_speeches (
    sotu_id serial PRIMARY KEY,
president varchar(100) NOT NULL,
title varchar(250) NOT NULL,
speech_date date NOT NULL,
speech_text text NOT NULL,
search_speech_text tsvector
);

COPY president_speeches (president, title, speech_date, speech_text)
FROM '/Users/tbroderick/anaconda3/envs/pracSQL/Chapter_13_text/sotu-1946-1977.csv'
WITH (FORMAT CSV, DELIMITER '|', HEADER OFF, QUOTE '@');
"
dbGetQuery(con, sql)

# R really doesn't like tsvector
sql <- "SELECT * FROM president_speeches;"
speeches <- dbGetQuery(con, sql)

# but apparently once things are set up in pgadmin
# it returns results just fine!

sql <- "SELECT president, speech_date
FROM president_speeches
WHERE search_speech_text @@ to_tsquery('Vietnam')
ORDER BY speech_date;"
dbGetQuery(con, sql)

# the previous search returned where the term Vietname showed up in the data
# ts_headline does that but grabs some context as well
sql <- "
SELECT president,
       speech_date,
ts_headline(speech_text, to_tsquery('Vietnam'),
'StartSel = <,
StopSel = >,
MinWords=5,
MaxWords=7,
MaxFragments=1')
FROM president_speeches
WHERE search_speech_text @@ to_tsquery('Vietnam');
"
dbGetQuery(con, sql)

# using multiple words (not roads)
sql <- "
SELECT president,
       speech_date,
ts_headline(speech_text, to_tsquery('transportation & !roads'),
'StartSel = <,
StopSel = >,
MinWords=5,
MaxWords=7,
MaxFragments=1')
FROM president_speeches
WHERE search_speech_text @@ to_tsquery('transportation & !roads');
"
dbGetQuery(con, sql)

# <-> finds adjacent words, in this case 'defense' immediatly following 'military'
sql <- "
SELECT president,
       speech_date,
ts_headline(speech_text, to_tsquery('military <-> defense'),
'StartSel = <,
StopSel = >,
MinWords=5,
MaxWords=7,
MaxFragments=1')
FROM president_speeches
WHERE search_speech_text @@ to_tsquery('military <-> defense');
"
dbGetQuery(con, sql)

# change <-> to <2> gets you defense exactly two words away from military
# such as military and defense
sql <- "
SELECT president,
speech_date,
ts_headline(speech_text, to_tsquery('military <2> defense'),
'StartSel = <,
StopSel = >,
MinWords=5,
MaxWords=7,
MaxFragments=1')
FROM president_speeches
WHERE search_speech_text @@ to_tsquery('military <2> defense');
"
dbGetQuery(con, sql)

# Scoring relevance with ts_rank()
# returns speeches ordered by the number of times the terms were found

sql <- "
SELECT president,
speech_date,
ts_rank(search_speech_text,
        to_tsquery('war & security & threat & enemy')) AS score
FROM president_speeches
WHERE search_speech_text @@ to_tsquery('war & security & threat & enemy')
ORDER BY score DESC
LIMIT 5;"
dbGetQuery(con, sql)

# partly due to the length of the speeches too
sql <- "SELECT president,
speech_date,
char_length(speech_text) FROM president_speeches
ORDER BY char_length DESC;"
dbGetQuery(con, sql)


# we can normalize the results by dividing by length

sql <- "
SELECT president,
       speech_date,
ts_rank(search_speech_text,
to_tsquery('war & security & threat & enemy'), 2)::numeric
AS score
FROM president_speeches
WHERE search_speech_text @@ to_tsquery('war & security & threat & enemy')
ORDER BY score DESC
LIMIT 5;
"
dbGetQuery(con, sql)


# disconnect
dbDisconnect(con)
dbUnloadDriver(drv)

