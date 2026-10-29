library(DBI)

dbcon <- dbConnect(
  RMariaDB::MariaDB(),
  host     = "ph.ms",
  port     = 3306,
  dbname   = "Restaurant_Project",
  user     = "cs5200practicum",
  password = "galekoumasfall2026"
)

sqlq <- "SHOW DATABASES;"

print(dbGetQuery(dbcon, sqlq))

print(dbListTables(dbcon))

dbDisconnect(dbcon)