# --- Part F: Test Data Loading Process ---
# --- Priamos Koumas & Amanda Gale ---
# --- Fall 2026 ---


if (!requireNamespace("pacman", quietly = TRUE)) {
  install.packages("pacman", repos = "https://cloud.r-project.org")
}
suppressPackageStartupMessages(pacman::p_load(DBI, RMariaDB, RSQLite, testthat))


main <- function() {
  
  dbcon <- dbConnect(
    RMariaDB::MariaDB(),
    host     = "ph.ms",
    port     = 3306,
    dbname   = "Restaurant_Project",
    user     = "cs5200practicum",
    password = "galekoumasfall2026"
  )
  on.exit(dbDisconnect(dbcon), add = TRUE)

  conn <- dbConnect(SQLite(), "restaurants-db-02102026.sqlitedb")
  on.exit(dbDisconnect(conn), add = TRUE)

  df.data <- read.csv("restaurant-visits-209874.csv")

  test_that("Unique restaurants in CSV row count of restaurants table", {
    rs <- length(unique(df.data[, c("RestaurantID")]))
    ex <- dbGetQuery(dbcon, "SELECT COUNT(*) AS n FROM restaurants")$n
    ex <- as.numeric(ex)

    cat("\n")
    print(if (rs == ex) "MATCH" else "MISMATCH")
    print(paste0("Unique restaurants in CSV: ", rs))
    print(paste0("Restaurant total rows from DB: ", ex))
    expect_equal(rs, ex)
  })

  test_that("Unique servers in CSV row count of servers table", {
    rs <- length(unique(na.omit(df.data[, c("ServerEmpID")])))
    ex <- dbGetQuery(dbcon, "SELECT COUNT(*) AS n FROM servers
    WHERE empid IN (SELECT DISTINCT serverempid FROM visits)")$n
    ex <- as.numeric(ex)

    cat("\n")
    print(if (rs == ex) "MATCH" else "MISMATCH")
    print(paste0("Unique servers in CSV: ", rs))
    print(paste0("Server total rows from DB: ", ex))
    expect_equal(rs, ex)
  })

  test_that("Unique customers in CSV row count of customers table", {
    rs <- unique(df.data[, c("CustomerName", "CustomerPhone", "CustomerEmail")])
    rs <- rs[!(is.na(rs$CustomerEmail) | rs$CustomerEmail == ""), ]
    rs <- nrow(rs)
    ex <- dbGetQuery(dbcon, "SELECT COUNT(*) AS n FROM customers")$n
    ex <- as.numeric(ex)

    cat("\n")
    print(if (rs == ex) "MATCH" else "MISMATCH")
    print(paste0("Unique customers in CSV: ", rs))
    print(paste0("Customer total rows from DB: ", ex))
    expect_equal(rs, ex)
  })

  test_that("Unique visits in CSV row count of visits table", {
    rs <- nrow(df.data) # each row in the CSV represents a unique visit
    ex <- dbGetQuery(dbcon, "SELECT COUNT(*) AS n FROM visits")$n
    ex <- as.numeric(ex)

    cat("\n")
    print(if (rs == ex) "MATCH" else "MISMATCH")
    print(paste0("Unique visits in CSV: ", rs))
    print(paste0("Visit total rows from DB: ", ex))
    expect_equal(rs, ex)
  })

  test_that("food sum equals CSV sum", {
    rs <- dbGetQuery(dbcon, "SELECT SUM(foodbill) AS total FROM bill")
    rs <- as.numeric(rs$total)
    ex <- sum(df.data$FoodBill)

    cat("\n")
    print(if (rs == ex) "MATCH" else "MISMATCH")
    print(paste0("Food sum from DB:", rs))
    print(paste0("Food sum from CSV: ", ex))
    expect_equal(rs, ex)
  })

  test_that("alcohol sum equals CSV sum", {
    rs <- dbGetQuery(dbcon, "SELECT SUM(alcoholbill) AS total FROM bill")
    rs <- as.numeric(rs$total)
    ex <- sum(df.data$AlcoholBill)

    cat("\n")
    print(if (rs == ex) "MATCH" else "MISMATCH")
    print(paste0("Alcohol sum from DB: ", rs))
    print(paste0("Alcohol sum from CSV: ", ex))
    expect_equal(rs, ex)
  })

  test_that("tip sum equals CSV sum", {
    rs <- dbGetQuery(dbcon, "SELECT SUM(tipamount) AS total FROM bill")
    rs <- as.numeric(rs$total)
    ex <- sum(df.data$TipAmount)

    cat("\n")
    print(if (rs == ex) "MATCH" else "MISMATCH")
    print(paste0("Tip sum from DB: ", rs))
    print(paste0("Tip sum from CSV: ", ex))
    expect_equal(rs, ex)
  })
}

main()
