# --- configBusinessLogic.PractI.GaleKoumas.R ---
# --- Part G: Stored Procedures ---
# --- Priamos Koumas & Amanda Gale ---
# --- Fall 2026 ---


if (!requireNamespace("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
suppressPackageStartupMessages(pacman::p_load(DBI, RMariaDB, testthat))


check_table_existence <- function(dbc, table) {
  # Check for table existence, stop script if non-existent
  if (!dbExistsTable(dbc, table)) {
    stop(paste0("Table ", table, " not yet in database. Execute createDB script before proceeding."),
         call. = FALSE
    )
  }
}

drop_stored_procedure <- function(con, storedProc) {
  sqlq <- paste0("DROP PROCEDURE IF EXISTS ", storedProc, ";")
  dbExecute(con, sqlq)
  print(paste0("Dropped stored procedure ", storedProc))
}

sqlq_modifyServer <- function(con) {
  sql <- paste0("CREATE PROCEDURE modifyServer (IN id INTEGER, IN updatedname VARCHAR(50), IN updatedrate DECIMAL(4,2))",
                " BEGIN",
                "   IF NOT EXISTS (SELECT 1 FROM servers WHERE empid = id) THEN",
                "     SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: no server found';",
                "   END IF;",
                "   UPDATE servers",
                "      SET servername = updatedname,",
                "          hourlyrate = updatedrate",
                "    WHERE empid = id;",
                " END")

  rs <- dbExecute(con, sql)
  print("Created stored procedure modifyServer")
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
  
  drop_stored_procedure(dbcon, 'storeNewVisit')
  drop_stored_procedure(dbcon, 'modifyServer')
  
  sql_modifyServer(dbcon)
  
  # --- Store information pertaining to a new visit ---
  
  # check for customer id, if not exists, store info
  # Insert customer info, bill info
  # mt and payment info hopefully already exist 
  # store visit info using select statements to get 
  # corresponding customerid and mtids 
  sqlq_storeNewVisit <- paste0(
  "CREATE PROCEDURE storeNewVisit(newValues)",
  "BEGIN",
  "END")
  
  
  # dbExecute(dbcon, sqlq)
}

main()