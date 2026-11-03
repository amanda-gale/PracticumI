# --- testBusinessLogic.R ---
# --- Part G: Test Business Logic ---
# --- Priamos Koumas & Amanda Gale ---
# --- Fall 2026 ---


if (!requireNamespace("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
suppressPackageStartupMessages(pacman::p_load(DBI, RMariaDB))

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

  server <- dbGetQuery(dbcon, "SELECT * FROM servers ORDER BY empid LIMIT 1")
  visits <- as.numeric(dbGetQuery(dbcon, "SELECT COUNT(*) AS n FROM visits")$n)

  test_that("storeNewVisit adds a new visit", {
    dbExecute(dbcon, paste0("CALL storeNewVisit(", server$rid, ", ", server$empid,
                            ", 'Dinner', '2026-11-04', '01:23:00', 7, 20, 'Priamos', '(508) 123-4567', 'priamos@mail.org', 1, 'Mobile Payment', 100.00, 100.00, 0, 0, 0)"))
    ex <- as.numeric(dbGetQuery(dbcon, "SELECT COUNT(*) AS n FROM visits")$n)
    expect_equal(ex, visits + 1)
  })

  test_that("storeNewVisit rejects an invalid meal type", {
    expect_error(dbExecute(dbcon, paste0("CALL storeNewVisit(", server$rid, ", ", server$empid,
                                         ", 'Brunch', '2026-11-04', '01:23:00', 7, 20, 'Priamos', '(508) 123-4567', 'priamos@mail.org', 1, 'Mobile Payment', 100.00, 100.00, 0, 0, 0)")))
  })

  test_that("modifyServer updates a server", {
    dbExecute(dbcon, paste0("CALL modifyServer(", server$empid, ", 'Priamos', 25.00)"))
    ex <- dbGetQuery(dbcon, paste0("SELECT servername FROM servers WHERE empid = ", server$empid))
    expect_equal(ex$servername, "Priamos")
  })

  test_that("modifyServer rejects a server that does not exist", {
    expect_error(dbExecute(dbcon, "CALL modifyServer(0, 'Priamos', 10.00)"))
  })

  dbExecute(dbcon, paste0("CALL modifyServer(", server$empid, ", '", server$servername, "', ", server$hourlyrate, ")"))
  test.visit <- dbGetQuery(dbcon, "SELECT visitid, billid, customerid FROM visits ORDER BY visitid DESC LIMIT 1")
  dbExecute(dbcon, paste0("DELETE FROM visits WHERE visitid = ", test.visit$visitid))
  dbExecute(dbcon, paste0("DELETE FROM bill WHERE billid = ", test.visit$billid))
  dbExecute(dbcon, paste0("DELETE FROM customers WHERE cid = ", test.visit$customerid))
}

main()
