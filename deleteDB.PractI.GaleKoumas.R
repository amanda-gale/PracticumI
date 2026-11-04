# --- Part D: Delete Database ---
# --- Priamos Koumas & Amanda Gale ---
# --- CS 5200 Fall 2026 ---
# --- deleteDB.PractI.GaleKoumas.R ---

if (!requireNamespace("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
suppressPackageStartupMessages(pacman::p_load(DBI, RMariaDB))

# --- Utility Functions ---

delete_table <- function(con, table) {
  print(paste0("Deleting table ", table))
  dbExecute(con, paste0("DROP TABLE IF EXISTS ", table, ";"))
}

main <- function() {
  
  print("Resetting Restaurant_Project Database")
  
  dbcon <- dbConnect(
  RMariaDB::MariaDB(),
  host     = "ph.ms",
  port     = 3306,
  dbname   = "Restaurant_Project",
  user     = "cs5200practicum",
  password = "galekoumasfall2026"
  )
  on.exit(dbDisconnect(dbcon), add = TRUE)
  
  db_tables <- c("restaurants", "servers", "visits", "customers",
                 "bill", "paymentmethods", "mealtypes")

  
  dbExecute(dbcon, "SET FOREIGN_KEY_CHECKS = 0;")
  for (tbl in db_tables) {
    delete_table(dbcon, tbl)
  }
  dbExecute(dbcon, "SET FOREIGN_KEY_CHECKS = 1;")
  
  print("Database cleared.")
}


tryCatch(main(), error = function(e) {
  cat("Error occurred:", e$message, "\n")
})