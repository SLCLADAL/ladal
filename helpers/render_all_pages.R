qmd_files <- list.files("tutorials", pattern = "\\.qmd$", 
                        recursive = TRUE, full.names = TRUE)

failed <- c()
for (f in qmd_files) {
  cat("Rendering:", f, "\n")
  result <- tryCatch(
    quarto::quarto_render(f),
    error = function(e) e
  )
  if (inherits(result, "error")) {
    cat("  FAILED:", conditionMessage(result), "\n")
    failed <- c(failed, f)
  }
}

cat("\nFailed tutorials:\n")
cat(failed, sep = "\n")