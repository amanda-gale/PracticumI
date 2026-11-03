# --- Part G: Stored Procedures ---
# --- Priamos Koumas & Amanda Gale ---
# --- Fall 2026 ---


if (!requireNamespace("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
suppressPackageStartupMessages(pacman::p_load(DBI, RMariaDB))


check_table_existence <- function(dbc, table) {
  # Check for table existence, stop script if non-existent
  if (!dbExistsTable(dbc, table)) {
    stop(paste0("Table ", table, " not yet in database. Execute createDB script before proceeding."),
         call. = FALSE
    )
  }
}


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
  
  tables <- c(
    "restaurants", "customers", "paymentmethods",
    "mealtypes", "servers", "bill", "visits"
  )
  
  for (tbl in tables) {
    # Halt execution is a table is non-existent
    check_table_existence(dbcon, tbl)
  }
  
  # --- Generate Testing Data ---
  newVisitPass <- NA   # row inserted properly for existing customer
  newVisitPass <- NA   # v_cid should be NULL if email, phone and name are null
  newVisitPass <- NA   # v_cid should have associated row in customers table if new info provided,
                       # and only one row should be added if called twice
  newVisitFail2 <- NA   # negative value for foodbill
  newVisitFail3 <- NA   # invalid mealtype
  newVisitFail4 <- NA   # invalid payment type
  
  
  
  modifyServerPass <- NA    # line from df with lower rate, server demotion
  modifyServerFail1 <- NA   # nonexistent server value, should give error
  modifyServerFail2 <- NA   # NULL values for name and hourly rate
  modifyServerFail3 <- NA   # negative hourly rate
  
  tryCatch({
    dbExecute(con, "CALL modifyServer(999, 'Test', 15.00)")
    cat("Unexpected success\n")
  }, error = function(e) {
    cat("Expected error caught:", conditionMessage(e), "\n")
  })
  
}

main()