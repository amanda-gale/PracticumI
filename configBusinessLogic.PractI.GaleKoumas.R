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

drop_stored_procedure <- function(con, storedProc) {
  sqlq <- paste0("DROP PROCEDURE IF EXISTS ", storedProc, ";")
  dbExecute(con, sqlq)
  print(paste0("Dropped stored procedure ", storedProc))
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
  
  # --- Store information pertaining to a new visit ---
  
  # check for customer id, if not exists, store info
  # SELECT customerid FROM customers WHERE customername = newValues.customername AND customerphone = newValues.customerphone AND customeremail = newValues.customeremail
  # Insert customer info, bill info
  # INSERT INTO bill (foodbill, tipamount, 
          # fooddiscountpercentage, orderedalcohol, alcoholbill
          #(SELECT pmid FROM paymentmethods WHERE paymentmethod 
                          # = newValues.paymentmethod) as pmid) 
          # VALUES (newValues.billamount, newValues.billdate, newValues.paymentmethodid)
  # mt and payment info hopefully already exist 
  # SELECT mtid FROM mealtype WHERE mealtype = newValues.mealtype
  # store visit info using select statements to get
  # corresponding customerid and mtids 
  
  sqlq_storeNewVisit <- paste0(
  "CREATE PROCEDURE storeNewVisit(newValues)",
  "BEGIN",
  "END")
  
  
  dbExecute(dbcon, sqlq)
  
  
}