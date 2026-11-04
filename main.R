# main.R: runs the project scripts in order

# ---- Fill in your file names, in the order they should run ----
scripts <- c(
  "deleteDB.PractI.GaleKoumas.R",   
  "createDB.PractI.GaleKoumas.R",   
  "loadDB.PractI.GaleKoumas.R",   
  "testDBLoading.PractI.GaleKoumas.R",    
  "configBusinessLogic.PractI.GaleKoumas.R",   
  "testBusinessLogic.R"
)

# ---- Check that every file exists before running anything ----
missing <- scripts[!file.exists(scripts)]
if (length(missing) > 0) {
  stop("Script file(s) not found: ", paste(missing, collapse = ", "),
       "\nWorking directory is: ", getwd(), call. = FALSE)
}

# ---- Run each script in order; stop at the first failure ----
for (i in seq_along(scripts)) {
  cat("\n=====================================================\n")
  cat(sprintf("Step %d of %d: %s\n", i, length(scripts), scripts[i]))
  cat("=====================================================\n")
  
  start <- Sys.time()
  tryCatch(
    source(scripts[i], echo = FALSE),
    error = function(e) {
      stop(sprintf("Step %d (%s) failed: %s", i, scripts[i], conditionMessage(e)),
           call. = FALSE)
    }
  )
  cat(sprintf("Finished %s in %.1f seconds\n", scripts[i],
              as.numeric(difftime(Sys.time(), start, units = "secs"))))
}

cat("\nAll scripts completed successfully.\n")