# --- Part C: Realize Database ---
# --- Priamos Koumas & Amanda Gale ---
# --- CS 5200 Fall 2026 ---
# --- createDB.PractI.GaleKoumas.R ---

if (!requireNamespace("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
suppressPackageStartupMessages(pacman::p_load(DBI, RMariaDB))

main <- function() {
  
  print("Creating tables in Restaurant_Project Database")
  
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

tryCatch(main(), error = function(e) {
  cat("Error occurred:", e$message, "\n")
})