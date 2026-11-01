# --- testDBLoading.PractI.GaleKoumas.R ---
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
  
  test_that("restaurant total rows equals SQLite total rows", {
    rs <- dbGetQuery(dbcon, "SELECT COUNT(*) AS n FROM restaurants")
    expect_equal(rs$n, dbGetQuery(conn, "SELECT COUNT(*) AS n FROM restaurants")$n)
    cat('\n')
    print(paste0("Restaurant total rows from DB: ", rs$n))
    print(paste0("Restaurant total rows from SQLite: ", 
                 dbGetQuery(conn, "SELECT COUNT(*) AS n FROM restaurants")$n))
  })

  test_that("customer total rows equals CSV total rows", {
    rs <- dbGetQuery(dbcon, "SELECT COUNT(*) AS n FROM customers")
    ls <- length(unique(df.data$CustomerEmail[df.data$CustomerEmail != ""]))
    expect_equal(rs$n, ls)
    cat('\n')
    print(paste0("Customer total rows from DB: ", rs$n))
    print(paste0("Customer total rows from CSV: ", ls))
  })

  test_that("server total rows equals SQLite total rows", {
    rs <- dbGetQuery(dbcon, "SELECT COUNT(*) AS n FROM servers")
    expect_equal(rs$n, length(unique(dbReadTable(conn, "servers")$EmpID)))
    cat('\n')
    print(paste0("Server total rows from DB: ", rs$n))
    print(paste0("Server total rows from SQLite: ", 
                 length(unique(dbReadTable(conn, "servers")$EmpID))))
  })


  test_that("visit total rows equals CSV", {
    rs <- dbGetQuery(dbcon, "SELECT COUNT(*) AS n FROM visits")
    expect_equal(rs$n, nrow(df.data))
    cat('\n')
    print(paste0("Visit total rows from DB: ", rs$n))
    print(paste0("Visit total rows from CSV: ", nrow(df.data)))
  })

  test_that("food sum equals CSV sum", {
    rs <- dbGetQuery(dbcon, "SELECT SUM(foodbill) AS total FROM bill")
    expect_equal(as.numeric(rs$total), sum(df.data$FoodBill))
    cat('\n')
    print(paste0("Food sum from DB:", rs$total))
    print(paste0("Food sum from CSV: ", sum(df.data$FoodBill)))
  })

  test_that("alcohol sum equals CSV sum", {
    rs <- dbGetQuery(dbcon, "SELECT SUM(alcoholbill) AS total FROM bill")
    expect_equal(as.numeric(rs$total), sum(df.data$AlcoholBill))
    cat('\n')
    print(paste0("Alcohol sum from DB: ", rs$total))
    print(paste0("Alcohol sum from CSV: ", sum(df.data$AlcoholBill)))
  })

  test_that("tip sum equals CSV sum", {
    rs <- dbGetQuery(dbcon, "SELECT SUM(tipamount) AS total FROM bill")
    expect_equal(as.numeric(rs$total), sum(df.data$TipAmount))
    cat('\n')
    print(paste0("Tip sum from DB: ", rs$total))
    print(paste0("Tip sum from CSV: ", sum(df.data$TipAmount)))
  })
}

main()
