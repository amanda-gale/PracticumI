# --- Part G: Stored Procedures ---
# --- Priamos Koumas & Amanda Gale ---
# --- CS 5200 Fall 2026 ---
# --- testBusinessLogic.R ---

if (!requireNamespace("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
suppressPackageStartupMessages(pacman::p_load(DBI, RMariaDB, testthat))


# --- Utility Functions ---

check_procedure_existence <- function(dbc, required_procs) {
  found <- dbGetQuery(dbc, "
  SELECT ROUTINE_NAME
    FROM information_schema.ROUTINES
   WHERE ROUTINE_SCHEMA = DATABASE()
     AND ROUTINE_TYPE = 'PROCEDURE'")[[1]]
  
  missing <- required_procs[!tolower(required_procs) %in% tolower(found)]
  
  if (length(missing) > 0) {
    stop("Missing stored procedure(s): ", paste(missing, collapse = ", "),
         ". Run the procedure creation script first.", call. = FALSE)
  }
}

check_table_existence <- function(dbc, table) {
  # Check for table existence, stop script if non-existent
  if (!dbExistsTable(dbc, table)) {
    stop(paste0("Table ", table, " not yet in database. Execute createDB script before proceeding."),
         call. = FALSE
    )
  }
}

max_id <- function(dbc, col, tbl) {
  as.numeric(dbGetQuery(dbc,
                        paste0("SELECT COALESCE(MAX(", col, "), 0) AS m FROM ", tbl))$m)
}

cleanup <- function() {
  tryCatch({
    dbExecute(dbcon, paste0("DELETE FROM visits WHERE visitid > ", base_visit))
    dbExecute(dbcon, paste0("DELETE FROM bill WHERE billid > ", base_bill))
    dbExecute(dbcon, paste0("DELETE FROM customers WHERE cid > ", base_cust))
    dbExecute(dbcon, "UPDATE servers SET servername = ?, hourlyrate = ? WHERE empid = ?",
              params = list(server$servername, server$hourlyrate, server$empid))
    cat("\nTest data removed and server row restored.\n")
  }, error = function(e) cat("\nWARNING: cleanup failed:", conditionMessage(e), "\n"))
}



main <- function() {
  
  # --- Connect to DB ---
  
  dbcon <- dbConnect(
    RMariaDB::MariaDB(),
    host     = "ph.ms",
    port     = 3306,
    dbname   = "Restaurant_Project",
    user     = "cs5200practicum",
    password = "galekoumasfall2026"
  )
  on.exit(dbDisconnect(dbcon), add = TRUE)
  
  # --- Check for Procedures and Tables ---
  
  required_procs <- c("modifyServer", "storeNewVisit")
  check_procedure_existence(dbcon, required_procs)
  
  tables <- c(
    "restaurants", "customers", "paymentmethods",
    "mealtypes", "servers", "bill", "visits"
  )
  
  for (tbl in tables) {
    # Halt execution is a table is non-existent
    check_table_existence(dbcon, tbl)
  }
  
  # --- Store Values for Testing and Rollback ---
  server <- dbGetQuery(dbcon, "SELECT * FROM servers ORDER BY empid LIMIT 1")
  visits <- as.numeric(dbGetQuery(dbcon, "SELECT COUNT(*) AS n FROM visits")$n)
  customers <- as.numeric(dbGetQuery(dbcon, "SELECT COUNT(*) AS n FROM customers")$n)
  base_visit <- max_id(dbcon, "visitid", "visits")
  base_bill  <- max_id(dbcon, "billid",  "bill")
  base_cust  <- max_id(dbcon, "cid",     "customers")
  
  
  # --- Test storeNewVisit ---
  
  # Accepts row for new customer
  test_that("storeNewVisit adds a new visit", {
    rs <- visits + 1
    dbExecute(dbcon, paste0("CALL storeNewVisit(", server$rid, ", ", server$empid,
                            ", 'Dinner', '2026-11-04', '01:23:00', 7, 20, 'Priamos', 
                            '(508) 123-4567', 'priamos@mail.org', 1, 'Mobile Payment', 
                            100.00, 100.00, 0, 0, 0)"))
    ex <- as.numeric(dbGetQuery(dbcon, "SELECT COUNT(*) AS n FROM visits")$n)
    
    cat("\n")
    print(if (rs == ex) "MATCH" else "MISMATCH")
    print(paste0("Number of visits before call: ", rs))
    print(paste0("Number of visits after call: ", ex))
    expect_equal(rs, ex)
  })
  
  # Adds row to customer table, but only one row (row would have been added in previous txn)
  test_that("storeNewVisit does not add the customer a second time", {
    rs <- customers + 1
    dbExecute(dbcon, paste0("CALL storeNewVisit(", server$rid, ", ", server$empid,
                            ", 'Breakfast', '2026-11-05', '08:23:00', 7, 20, 'Priamos', 
                            '(508) 123-4567', 'priamos@mail.org', 1, 'Mobile Payment', 
                            100.00, 100.00, 0, 0, 0)"))
    ex <- as.numeric(dbGetQuery(dbcon, "SELECT COUNT(*) AS n FROM customers")$n)
    
    cat("\n")
    print(if (rs == ex) "MATCH" else "MISMATCH")
    print(paste0("Number of customers after last call: ", rs))
    print(paste0("Number of customers after this call: ", ex))
    expect_equal(rs, ex)
  })
  
  # Rejects negative value for food bill
  test_that("storeNewVisit does not add negative bill value", {
    expect_error(dbExecute(dbcon, paste0("CALL storeNewVisit(", server$rid, ", ", server$empid,
                                         ", 'Breakfast', '2026-11-05', '08:23:00', 7, 20, 'Priamos', 
                            '(508) 123-4567', 'priamos@mail.org', 1, 'Mobile Payment', 
                            -100.00, 100.00, 0, 0, 0)")))
  })
  
  # Rejects invalid meal type
  test_that("storeNewVisit rejects an invalid meal type", {
    expect_error(dbExecute(dbcon, paste0("CALL storeNewVisit(", server$rid, ", ", server$empid,
                                         ", 'Brunch', '2026-11-04', '01:23:00', 7, 20, 'Priamos', '(508) 123-4567', 'priamos@mail.org', 1, 'Mobile Payment', 100.00, 100.00, 0, 0, 0)")))
  })
  
  # Rejects invalid payment type
  test_that("storeNewVisit rejects an invalid payment type", {
    expect_error(dbExecute(dbcon, paste0("CALL storeNewVisit(", server$rid, ", ", server$empid,
                                         ", 'Lunch', '2026-11-04', '01:23:00', 7, 20, 'Priamos', 
                                         '(508) 123-4567', 'priamos@mail.org', 1, 'Check', 100.00, 
                                         100.00, 0, 0, 0)")))
  })
  
  # v_cid should be NULL if email, phone and name are NULL
  test_that("storeNewVisit stores a NULL customerid when no customer info is given", {
    null_visits_before <- as.numeric(dbGetQuery(dbcon,
                                                "SELECT COUNT(*) AS n FROM visits WHERE customerid IS NULL")$n)
    customers_before <- as.numeric(dbGetQuery(dbcon,
                                              "SELECT COUNT(*) AS n FROM customers")$n)
    
    dbExecute(dbcon, paste0("CALL storeNewVisit(", server$rid, ", ", server$empid,
                            ", 'Lunch', '2026-11-06', '12:15:00', 2, 5, NULL, NULL, NULL, 0,
                            'Mobile Payment', 50.00, 10.00, 0, 0, 0)"))
    
    null_visits_after <- as.numeric(dbGetQuery(dbcon,
                                               "SELECT COUNT(*) AS n FROM visits WHERE customerid IS NULL")$n)
    customers_after <- as.numeric(dbGetQuery(dbcon,
                                             "SELECT COUNT(*) AS n FROM customers")$n)
    rs1 <- null_visits_before +1 
    rs2 <- customers_before
    ex1 <- null_visits_after
    ex2 <- customers_after
    
    cat('\n')
    print(if (rs1 == ex1) "MATCH" else "MISMATCH")
    print(if (rs2 == ex2) "MATCH" else "MISMATCH")
    print("Before Call:")
    print(paste0("Visits: ", rs1, " Customers: ", rs2))
    print("After Call:")
    print(paste0("Visits: ", ex1, " Customers: ", ex2))
    expect_equal(rs1, ex1)  # visit saved with NULL customerid
    expect_equal(rs2, ex2)          # no customer row created
  })
  
  
  # --- Test modifyServer ---
  
  # Accepts new modified entry for existing EmpID
  test_that("modifyServer updates a server", {
    rs <- "Priamos"
    dbExecute(dbcon, paste0("CALL modifyServer(", server$empid, ", 'Priamos', 25.00)"))
    ex <- dbGetQuery(dbcon, paste0("SELECT servername FROM servers WHERE empid = ", server$empid))
    ex <- ex$servername
    
    print(if (rs == ex) "MATCH" else "MISMATCH")
    expect_equal(rs, ex)
  })
  
  # Accepts updated hourly rate for existing EmpID
  test_that("modifyServer gives Priamos a raise", {
    before_raise <- as.numeric(dbGetQuery(dbcon,
                                          paste0("SELECT hourlyrate FROM servers WHERE empid = ", server$empid))$hourlyrate)
    rs <- before_raise + 10
    dbExecute(dbcon, paste0("CALL modifyServer(", server$empid, ", 'Priamos', ",
                            sprintf("%.2f", rs), ")"))
    ex <- as.numeric(dbGetQuery(dbcon,
                                paste0("SELECT hourlyrate FROM servers WHERE empid = ", server$empid))$hourlyrate)
    
    cat("\n")
    print("modifyServer gives Priamos a raise")
    print(if (rs == ex) "MATCH" else "MISMATCH")
    print(paste0("Expected hourly rate: ", rs))
    print(paste0("Hourly rate from DB: ", ex))
    expect_equal(rs, ex)
  })
  
  # Rejects nonexistent EmpID
  test_that("modifyServer rejects a server that does not exist", {
    expect_error(dbExecute(dbcon, "CALL modifyServer(0, 'Priamos', 10.00)"))
  })
  
  # Rejects NULL value for hourly rate
  test_that("modifyServer rejects a NULL hourly rate", {
    expect_error(dbExecute(dbcon, paste0("CALL modifyServer(", server$empid, ", 'Priamos', NULL)")))
  })
  
  # Rejects NULL value for server name
  test_that("modifyServer rejects a NULL server name", {
    expect_error(dbExecute(dbcon, paste0("CALL modifyServer(", server$empid, ", NULL, 10.00)")))
  })
  
  # Rejects Negative hourly rate
  test_that("modifyServer rejects a negative hourly rate", {
    expect_error(dbExecute(dbcon, paste0("CALL modifyServer(", server$empid, ", 'Priamos', -10.00)")))
  })
  
  cleanup()  # Rollback test data and restore server row
}

tryCatch(main(), error = function(e) {
  cat("Error occurred:", e$message, "\n")
})