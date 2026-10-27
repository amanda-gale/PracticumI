# Part D: Delete Database
# Priamos Koumas  
# Amanda Gale
# Fall 2026


delete_table <- function(con, table) {
  tbl_exists <- dbExecute(con, paste0("DROP TABLE IF EXISTS ", table, ";"))
  if (tbl_exists > 0) {
    print(paste0("Deleted table ", table, "."))
  }
}


main <- function() {
  
  if (!requireNamespace("pacman", quietly = TRUE)) {
    install.packages("pacman")
  }
  pacman::p_load(DBI, RMariaDB)
  
  dbcon <- dbConnect(
  RMariaDB::MariaDB(),
  host     = "ph.ms",
  port     = 3306,
  dbname   = "Restaurant_Project",
  user     = "cs5200practicum",
  password = "galekoumasfall2026"
  )
  
  on.exit(dbDisconnect(dbcon), add = TRUE)
  
  # tables to delete
  db_tables <- c("restaurants", "servers", "visits", "customers",
                 "bill", "paymentmethods", "mealtypes")

  print("Resetting Restaurant_Project Database")
  dbExecute(dbcon, "SET FOREIGN_KEY_CHECKS = 0;")
  for (tbl in db_tables) {
    delete_table(dbcon, tbl)
  }
  dbExecute(dbcon, "SET FOREIGN_KEY_CHECKS = 1;")
  
  print("Database cleared.")
}


main()