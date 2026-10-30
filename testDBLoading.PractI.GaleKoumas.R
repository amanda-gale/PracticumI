# --- testDBLoading.PractI.GaleKoumas.R ---
# --- Part F: Test Data Loading Process ---
# --- Priamos Koumas & Amanda Gale ---
# --- Fall 2026 ---


if (!requireNamespace("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
suppressPackageStartupMessages(pacman::p_load(DBI, RMariaDB, RSQLite, testthat))

main <- function() {
  
  dbcon <- dbConnect(
    RMariaDB::MariaDB(),
    host     = Sys.getenv("DB_HOST"),
    port     = as.integer(Sys.getenv("DB_PORT")),
    dbname   = Sys.getenv("DB_NAME"),
    user     = Sys.getenv("DB_USER"),
    password = Sys.getenv("DB_PASS")
  )
  on.exit(dbDisconnect(dbcon), add = TRUE)
  
  conn <- dbConnect(SQLite(), "restaurants-db-02102026.sqlitedb")
  on.exit(dbDisconnect(conn), add = TRUE)
  
  df.data <- read.csv("restaurant-visits-209874.csv")
  
  test_that("restaurant total rows matches CSV", {
    rs <- dbGetQuery(dbcon, "SELECT COUNT(*) AS n FROM restaurants")
    expect_equal(rs$n, length(unique(df.data$RestaurantID)))
  })
  
  test_that("customer total rows matches CSV", {
    rs <- dbGetQuery(dbcon, "SELECT COUNT(*) AS n FROM customers")
    expect_equal(rs$n, length(unique(df.data$CustomerEmail[df.data$CustomerEmail != ""])))
  })
  
  test_that("server total rows matches CSV", {
    rs <- dbGetQuery(dbcon, "SELECT COUNT(*) AS n FROM servers")
    expect_equal(rs$n, length(unique(na.omit(df.data$ServerEmpID))))
  })
  
  test_that("visit total rows matches CSV", {
    rs <- dbGetQuery(dbcon, "SELECT COUNT(*) AS n FROM visits")
    expect_equal(rs$n, nrow(df.data))
  })
  
  test_that("food sum matches CSV", {
    rs <- dbGetQuery(dbcon, "SELECT SUM(foodbill) AS total FROM bill")
    expect_equal(as.numeric(rs$total), sum(df.data$FoodBill))
  })
  
  test_that("alcohol sum matches CSV", {
    rs <- dbGetQuery(dbcon, "SELECT SUM(alcoholbill) AS total FROM bill")
    expect_equal(as.numeric(rs$total), sum(df.data$AlcoholBill))
  })
  
  test_that("tip sum matches CSV", {
    rs <- dbGetQuery(dbcon, "SELECT SUM(tipamount) AS total FROM bill")
    expect_equal(as.numeric(rs$total), sum(df.data$TipAmount))
  })
}

main()