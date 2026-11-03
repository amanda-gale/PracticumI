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


sqlq_storeNewVisit <- function(con) {
  sql <- paste0(
    "CREATE PROCEDURE storeNewVisit(\n",
    "  IN in_restaurantid INT,\n",
    "  IN in_serverempid INT,\n",
    "  IN in_mealtype VARCHAR(10),\n",
    "  IN in_visitdate DATE,\n",
    "  IN in_visittime TIME,\n",
    "  IN in_partysize INT,\n",
    "  IN in_waittime INT,\n",
    "  IN in_customername VARCHAR(50),\n",
    "  IN in_customerphone VARCHAR(20),\n",
    "  IN in_customeremail VARCHAR(50),\n",
    "  IN in_loyaltymember TINYINT(1),\n",
    "  IN in_paymentmethod VARCHAR(15),\n",
    "  IN in_foodbill DECIMAL(10,2),\n",
    "  IN in_tipamount DECIMAL(10,2),\n",
    "  IN in_fooddiscountpercentage DECIMAL(10,2),\n",
    "  IN in_orderedalcohol TINYINT(1),\n",
    "  IN in_alcoholbill DECIMAL(10,2)\n",
    ")\n",
    "BEGIN\n",
    "  DECLARE v_mtid INT DEFAULT NULL;\n",
    "  DECLARE v_pmid INT DEFAULT NULL;\n",
    "  DECLARE v_cid INT DEFAULT NULL;\n",
    "  DECLARE v_billid INT DEFAULT NULL;\n",
    "\n",
    "  DECLARE EXIT HANDLER FOR SQLEXCEPTION\n",
    "  BEGIN\n",
    "    ROLLBACK;\n",
    "    RESIGNAL;\n",
    "  END;\n",
    "\n",
    "  START TRANSACTION;\n",
    "\n",
    "  SELECT mtid INTO v_mtid FROM mealtypes WHERE mealtype = in_mealtype;\n",
    "  IF v_mtid IS NULL THEN\n",
    "    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid meal type';\n",
    "  END IF;\n",
    "\n",
    "  SELECT pmid INTO v_pmid FROM paymentmethods WHERE paymentmethod = in_paymentmethod;\n",
    "  IF v_pmid IS NULL THEN\n",
    "    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid payment method';\n",
    "  END IF;\n",
    "\n",
    "  IF in_customername IS NOT NULL\n",
    "     OR in_customerphone IS NOT NULL\n",
    "     OR in_customeremail IS NOT NULL THEN\n",
    "\n",
    "    SELECT cid INTO v_cid\n",
    "    FROM customers\n",
    "    WHERE customername  <=> in_customername\n",
    "      AND customerphone <=> in_customerphone\n",
    "      AND customeremail <=> in_customeremail\n",
    "      AND loyaltymember = COALESCE(in_loyaltymember, 0)\n",
    "    LIMIT 1;\n",
    "\n",
    "    IF v_cid IS NULL THEN\n",
    "      INSERT INTO customers (customername, customerphone, customeremail, loyaltymember)\n",
    "      VALUES (in_customername, in_customerphone, in_customeremail,\n",
    "              COALESCE(in_loyaltymember, 0));\n",
    "      SET v_cid = LAST_INSERT_ID();\n",
    "    END IF;\n",
    "  END IF;\n",
    "\n",
    "  INSERT INTO bill (foodbill, tipamount, fooddiscountpercentage, pmid,\n",
    "                    orderedalcohol, alcoholbill)\n",
    "  VALUES (in_foodbill, in_tipamount, in_fooddiscountpercentage, v_pmid,\n",
    "          COALESCE(in_orderedalcohol, 0), in_alcoholbill);\n",
    "\n",
    "  SET v_billid = LAST_INSERT_ID();\n",
    "\n",
    "  INSERT INTO visits (customerid, restaurantid, serverempid, billid,\n",
    "                      mtid, visitdate, visittime, partysize, waittime)\n",
    "  VALUES (v_cid, in_restaurantid, in_serverempid, v_billid, v_mtid,\n",
    "          in_visitdate, in_visittime, in_partysize, in_waittime);\n",
    "\n",
    "  COMMIT;\n",
    "END"
  )
  
  rs <- dbExecute(con, sql)
  print("Created stored procedure storeNewVisit")
}


sqlq_modifyServer <- function(con) {
  sql <- paste0("CREATE PROCEDURE modifyServer(",
                "  IN in_empid INTEGER,",
                "  IN in_servername VARCHAR(50),",
                "  IN in_hourlyrate DECIMAL(4,2)",
                ")",
                " BEGIN",
                "   IF NOT EXISTS (SELECT 1 FROM servers WHERE empid = in_empid) THEN",
                "     SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: no server found';",
                "   END IF;",
                "   IF in_servername IS NULL OR in_servername = '' THEN",
                "     SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: server name is required';",
                "  END IF;",
                "   IF in_hourlyrate IS NULL THEN",
                "     SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: hourly rate is required';",
                "   END IF;",
                "   IF in_hourlyrate < 0 THEN",
                "     SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: hourly rate cannot be negative';",
                "   END IF;",
                "   UPDATE servers",
                "      SET servername = in_servername,",
                "          hourlyrate = in_hourlyrate",
                "    WHERE empid = in_empid;",
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
  
  sqlq_storeNewVisit(dbcon)
  sqlq_modifyServer(dbcon)
  
  # --- Store information pertaining to a new visit ---
  
  dbExecute(dbcon, "DROP PROCEDURE IF EXISTS storeNewVisit")
  
  
  
  dbExecute(dbcon, storeNewVisit)
  
}