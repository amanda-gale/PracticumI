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
  
  df.data <- read.csv("small-restaurant-visits-209874.csv")
  
  test_that("restaurant total rows equals SQLite total rows", {
    rs <- dbGetQuery(dbcon, "SELECT COUNT(*) AS n FROM restaurants")
    expect_equal(rs$n, dbGetQuery(conn, "SELECT COUNT(*) AS n FROM restaurants")$n)
  })
  
  test_that("customer total rows equals CSV total rows", {
    rs <- dbGetQuery(dbcon, "SELECT COUNT(*) AS n FROM customers")
    expect_equal(rs$n, length(unique(df.data$CustomerEmail[df.data$CustomerEmail != ""])))
  })
  
  test_that("server total rows equals SQLite total rows", {
    rs <- dbGetQuery(dbcon, "SELECT COUNT(*) AS n FROM servers")
    expect_equal(rs$n, length(unique(dbReadTable(conn, "servers")$EmpID)))
  })
  
  test_that("visit total rows equals CSV", {
    rs <- dbGetQuery(dbcon, "SELECT COUNT(*) AS n FROM visits")
    expect_equal(rs$n, nrow(df.data))
  })
  
  test_that("food sum equals CSV sum", {
    rs <- dbGetQuery(dbcon, "SELECT SUM(foodbill) AS total FROM bill")
    expect_equal(as.numeric(rs$total), sum(df.data$FoodBill))
  })
  
  test_that("alcohol sum equals CSV sum", {
    rs <- dbGetQuery(dbcon, "SELECT SUM(alcoholbill) AS total FROM bill")
    expect_equal(as.numeric(rs$total), sum(df.data$AlcoholBill))
  })
  
  test_that("tip sum equals CSV sum", {
    rs <- dbGetQuery(dbcon, "SELECT SUM(tipamount) AS total FROM bill")
    expect_equal(as.numeric(rs$total), sum(df.data$TipAmount))
  })
}

main()