library(DBI)

conn <- dbConnect(
  RMariaDB::MariaDB(),
  host     = "ph.ms",
  port     = 3306,
  dbname   = "Restaurant_Project",
  user     = "cs5200practicum",
  password = "galekoumasfall2026"
)

sqlq <- "SHOW DATABASES;"

print(dbGetQuery(conn, sqlq))

dbDisconnect(conn)