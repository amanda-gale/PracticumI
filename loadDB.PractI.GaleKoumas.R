# --- Part E: Populate Database ---
# --- Priamos Koumas & Amanda Gale ---
# --- Fall 2026 ---


if (!requireNamespace("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
suppressPackageStartupMessages(pacman::p_load(DBI, dplyr, RMariaDB, RSQLite))


# --- Utility Functions ---

check_table_existence <- function(dbc, table) {
  # Check for table existence, stop script if non-existent
  if (!dbExistsTable(dbc, table)) {
    stop(paste0("Table ", table, " not yet in database. Execute createDB script before proceeding."),
      call. = FALSE
    )
  }
}

replace_values <- function(df, target = "N/A", replacement = "") {
  df[] <- lapply(df, function(col) {
    if (is.character(col) || is.factor(col)) {
      col <- as.character(col)
      col[col %in% target] <- replacement
    }
    col
  })
  df
}

clear_tables <- function(dbc, tables) {
  # Function derived from Claude
  # Clear all tables so the script can be re-run safely.
  # FK checks are disabled so TRUNCATE works on referenced tables;
  # TRUNCATE also resets AUTO_INCREMENT counters.

  dbExecute(dbc, "SET FOREIGN_KEY_CHECKS = 0")
  on.exit(dbExecute(dbc, "SET FOREIGN_KEY_CHECKS = 1"), add = TRUE)

  for (tbl in tables) {
    dbExecute(dbc, paste0("TRUNCATE TABLE ", dbQuoteIdentifier(dbc, tbl)))
  }
  invisible(TRUE)
}

insert_data <- function(dbc, table, data) {
  # Write a data frame to an existing table using manufactured
  # INSERT statements (Lesson 6.302). Rows are sent 1000 at a time
  # instead of one at a time to reduce round trips to the database.
  batch.size <- 1000
  n.rows <- nrow(data)

  # Treat every value as text so missing values become NULL
  data[] <- lapply(data, as.character)

  for (r in seq(1, n.rows, by = batch.size)) {
    last <- min(r + batch.size - 1, n.rows)
    sqlStmt <- sqlAppendTable(dbc, table, data[r:last, , drop = FALSE], row.names = FALSE)
    dbExecute(dbc, sqlStmt)
  }

  TRUE
}


main <- function() {
  # Main function workflow:
  # Connect to both SQLite and MySQL DBs
  # Ensure that required tables exist in MySQL SB
  # Clear existing data from DB tables
  # Clean CSV data
  # Save SQLite data locally
  # Organize data to MySQL schema
  # Insert data into MySQL database

  print("Loading data into database")

  # --- Connect to MariaDB ---

  dbcon <- dbConnect(
    RMariaDB::MariaDB(),
    host     = "ph.ms",
    port     = 3306,
    dbname   = "Restaurant_Project",
    user     = "cs5200practicum",
    password = "galekoumasfall2026"
  )
  on.exit(dbDisconnect(dbcon), add = TRUE)


  # --- Check for Table Existence ---

  tables <- c(
    "restaurants", "customers", "paymentmethods",
    "mealtypes", "servers", "bill", "visits"
  )
  for (tbl in tables) {
    # Halt execution is a table is non-existent
    check_table_existence(dbcon, tbl)
  }


  # --- Clear Existing Data ---
  clear_tables(dbcon, tables)


  # --- Load Data ---

  # Load CSV data into a data frame
  df.data <- read.csv("restaurant-visits-209874.csv")

  # Load SQLite data into data frames
  conn <- dbConnect(SQLite(), "restaurants-db-02102026.sqlitedb")
  on.exit(dbDisconnect(conn), add = TRUE)
  df.restaurants <- dbReadTable(conn, "restaurants")
  df.servers <- dbReadTable(conn, "servers")


  # --- Clean Data ---
  
  # Change N/A values into empty strings
  df.data <- replace_values(df.data, target = "N/A", replacement = NA)
  df.restaurants <- replace_values(df.restaurants, target = "N/A", replacement = NA)
  df.servers <- replace_values(df.servers, target = "N/A", replacement =  NA)

  # Change empty strings into NA values
  df.data <- replace_values(df.data, target = "", replacement = NA)
  df.restaurants <- replace_values(df.restaurants, target = "", replacement = NA)
  df.servers <- replace_values(df.servers, target = "", replacement = NA)

  # Change logicals to 0,1
  df.data$LoyaltyMember <- as.integer(df.data$LoyaltyMember)
  df.data$orderedAlcohol <- as.integer(df.data$orderedAlcohol == "yes")
  df.restaurants$hasTableService <- as.integer(df.restaurants$hasTableService == "yes")

  # Change party size 99 to the mode
  party_counts <- table(df.data$PartySize[df.data$PartySize != 99])
  mode_party <- as.numeric(names(party_counts)[which.max(party_counts)])
  df.data$PartySize[which(df.data$PartySize == 99)] <- mode_party
  stopifnot(!any(df.data$PartySize == 99))

  # Change wait time negative values
  wait_counts <- table(df.data$WaitTime[df.data$WaitTime >= 0])
  mode_wait <- as.numeric(names(wait_counts)[which.max(wait_counts)])
  df.data$WaitTime[which(df.data$WaitTime < 0)] <- mode_wait
  stopifnot(!any(df.data$WaitTime < 0))

  # Change BirthDate format
  df.servers$BirthDate <- format(as.Date(df.servers$BirthDate, "%m/%d/%Y"), "%Y-%m-%d")

  # Add a default primary key to the data for the bill and visits tables
  df.data$billid <- seq_len(nrow(df.data))
  df.data$visitid <- seq_len(nrow(df.data))

  # Remove duplicate primary key from the servers table
  df.servers <- distinct(df.servers)
  # Two servers got raises, keep their higher pay rate
  df.servers <- df.servers[-5, ]
  df.servers <- df.servers[-2, ]

  print("Data cleaning complete.")


  # --- Create Data Frames for DB Tables ---

  # Load restaurants
  # just change col names to lowercase
  df.restaurants <- df.restaurants %>%
    rename(
      rid = rID,
      restaurantname = RestaurantName,
      city = City,
      state = State,
      hastableservice = hasTableService
    )

  # Load customers
  df.customers <- df.data %>%
    filter(!is.na(CustomerEmail)) %>%
    select(CustomerName, CustomerPhone, CustomerEmail, LoyaltyMember) %>%
    distinct() %>%
    rename(
      customername = CustomerName,
      customerphone = CustomerPhone,
      customeremail = CustomerEmail,
      loyaltymember = LoyaltyMember
    )

  # Load paymentmethods
  df.paymentmethods <- df.data %>%
    select(PaymentMethod) %>%
    distinct() %>%
    rename(paymentmethod = PaymentMethod)

  # Load mealtypes
  df.mealtypes <- df.data %>%
    select(MealType) %>%
    distinct() %>%
    rename(mealtype = MealType)

  # Load servers
  # just change col names to lowercase
  df.servers <- df.servers %>%
    rename(
      empid = EmpID,
      rid = rID,
      servername = ServerName,
      startdatehired = StartDateHired,
      enddatehired = EndDateHired,
      hourlyrate = HourlyRate,
      birthdate = BirthDate,
      ssn = SSN
    )


  # --- Populate DB Part 1 ---

  data_tables <- list(
    restaurants = df.restaurants,
    customers = df.customers,
    paymentmethods = df.paymentmethods,
    mealtypes = df.mealtypes,
    servers = df.servers
  )

  for (tbl in names(data_tables)) {
    if (!insert_data(dbcon, tbl, data_tables[[tbl]])) {
      stop("Load halted at table '", tbl, "'.", call. = FALSE)
    }
  }


  # Load bill
  db.paymentmethods <- dbReadTable(dbcon, "paymentmethods")

  df.bill <- df.data %>%
    left_join(db.paymentmethods, by = c("PaymentMethod" = "paymentmethod")) %>%
    select(
      billid, FoodBill, TipAmount, FoodDiscountPercentage,
      pmid, orderedAlcohol, AlcoholBill
    ) %>%
    rename(
      foodbill = FoodBill,
      tipamount = TipAmount,
      fooddiscountpercentage = FoodDiscountPercentage,
      orderedalcohol = orderedAlcohol,
      alcoholbill = AlcoholBill
    )

  stopifnot(nrow(df.bill) == nrow(df.data), !anyNA(df.bill$pmid))

  # Load visits
  db.customers <- dbReadTable(dbcon, "customers") # get cid to reference FKs
  db.mealtypes <- dbReadTable(dbcon, "mealtypes") # get mtid to reference FKs

  df.visits <- df.data %>%
    left_join(db.customers,
      by = c(
        "CustomerName" = "customername",
        "CustomerPhone" = "customerphone",
        "CustomerEmail" = "customeremail"
      ),
      na_matches = "never"
    ) %>%
    left_join(db.mealtypes, by = c("MealType" = "mealtype")) %>%
    select(
      billid, cid, RestaurantID, ServerEmpID, mtid,
      VisitDate, VisitTime, PartySize, WaitTime
    ) %>%
    rename(
      customerid = cid,
      restaurantid = RestaurantID,
      serverempid = ServerEmpID,
      visitdate = VisitDate,
      visittime = VisitTime,
      partysize = PartySize,
      waittime = WaitTime
    )

  stopifnot(
    nrow(df.visits) == nrow(df.data),
    !anyNA(df.visits$mtid),
    !anyNA(df.visits$billid)
  )


  # --- Populate DB Part 2 ---

  data_tables <- list(
    bill = df.bill,
    visits = df.visits
  )

  # Insert clean data into database tables
  for (tbl in names(data_tables)) {
    if (!insert_data(dbcon, tbl, data_tables[[tbl]])) {
      stop("Load halted at table '", tbl, "'.", call. = FALSE)
    }
  }
}

tryCatch(main(), error = function(e) {
  cat("Error occurred:", e$message, "\n")
})