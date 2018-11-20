setwd("~/anaconda3/envs/pracSQL/Chapter_02_slicing")
library("RPostgreSQL")
library("tidyverse")
#https://www.r-bloggers.com/getting-started-with-postgresql-in-r/

# loads the PostgreSQL driver
drv <- dbDriver("PostgreSQL")
# creates a connection to the postgres database
con <- dbConnect(drv, dbname = "aranalysis",
                 host = "localhost", port = 5432,
                 user = "tbroderick")#, password = pw)

#test to see if connection works, and teachers table is there
dbExistsTable(con, "teachers")

# Basic syntax for running sql requests
teachers <- dbGetQuery(con, "SELECT * from teachers")



#---------------------------------
# Here's how to things in R as opposed to SQL

# select only a few columns
df <- select(teachers,'last_name','first_name','salary')
df


# distinct names of schools
?distinct
df <- teachers %>% distinct(school)
df

# distinct schools and salaries
df <- teachers %>% distinct( school,salary )
df

# ordered by salary descending
df <- select(teachers,'last_name','first_name','salary') %>% arrange(desc(salary))
df
# ordered by salary ascending
df <- select(teachers,'last_name','first_name','salary') %>% arrange(salary)
df

# ordering by two things
df <- select(teachers,'last_name','school','hire_date') %>% arrange(school,desc(hire_date))
df

# filter rows
df <- select(teachers,'last_name','school','hire_date') %>% filter(school == "Myers Middle School")
df

# filtering using WHERE and different comparison operators

# this is does not equal
df <- select(teachers,'school') %>% filter(school != "F.D. Roosevelt HS")
df

# hire date is before
df <- select(teachers,'last_name','school','hire_date') %>% filter(hire_date < "2000-01-01")
df

# salary is greater than or equal to
df <- select(teachers,'last_name','first_name','salary') %>% filter(salary >= 43500)
df

# salary is between
df <- select(teachers,'last_name','first_name','salary') %>% filter( (salary > 40000) & (salary < 65000) )
df

# like and ILIKE
# like is case sensitive, ILIKE is not case sensitive
# and sql requests using % wildcard need to be escaped using %%

df <- select(teachers,'first_name') %>% filter( str_detect(first_name, 'Sam' ) )
df

df <- select(teachers,'first_name') %>% filter( str_detect(first_name, regex('sam', ignore_case=TRUE) ) )
df

# with a wildcard
df <- select(teachers,'school') %>% filter( str_detect(school, regex('roo.', ignore_case=TRUE) ) )
df


# And or
# last name cole or bush
df <- select(teachers,'last_name','first_name','salary') %>% filter( (last_name == "Cole") | (last_name == "Bush") )
df

# school is Roo, salary is < 38999 or > 40000 
df <- select(teachers,'last_name','first_name','school','salary') %>% filter( school == "F.D. Roosevelt HS" & (salary < 38000 | salary > 40000)  )
df

# select first, last school hire salary, school roo sort desc salary
df <- select(teachers,'last_name','first_name','school','hire_date','salary') %>% filter( str_detect(school, regex('roo.', ignore_case=TRUE) ) ) %>% arrange(desc(hire_date))
df


#---------------------------------------
# disconnect and unload driver when done
dbDisconnect(con)
dbUnloadDriver(drv)


