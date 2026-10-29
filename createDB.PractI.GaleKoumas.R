
library(DBI)
library(RMariaDB)

main <- function() {
  # Connect to the MariaDB database
  dbcon <- dbConnect(
    RMariaDB::MariaDB(),
    host     = "ph.ms",
    port     = 3306,
    dbname   = "Restaurant_Project",
    user     = "cs5200practicum",
    password = "galekoumasfall2026"
  )
  
  # Disconnect even if the script encounters an error
  on.exit(dbDisconnect(dbcon), add = TRUE)
  
  # Read the SQL file
  sql_script <- paste(
    readLines("schema.GaleKoumas.sql", warn = FALSE),
    collapse = "\n"
  )
  
  # Split the file into individual SQL statements
  statements <- strsplit(
    sql_script,
    ";",
    fixed = TRUE
  )[[1]]
  
  # Remove empty statements and execute each statement
  statements <- trimws(statements)
  statements <- statements[nzchar(statements)]
  
  for (statement in statements) {
    dbExecute(dbcon, statement)
  }
  
  print("All tables created successfully:")
  print(dbListTables(dbcon))
}

main()