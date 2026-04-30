# ============================================================
# LADAL — Fix banner image loading attribute
# ============================================================
# Changes loading="lazy" to loading="eager" on the banner image
# in all tutorial .qmd files.
#
# The banner image is the LCP element on every tutorial page.
# Using loading="lazy" on the LCP element delays it, increasing
# LCP time. loading="eager" tells the browser to load it
# immediately, which combined with the preload link in
# custom_header.html should bring LCP below 2.5s on mobile.
#
# Safe behaviour:
#   - DRY_RUN = TRUE previews changes without writing anything
#   - Only modifies lines containing the exact banner pattern
#   - Saves a log to helpers/fix_banner_loading_log.csv
#
# After running with DRY_RUN <- FALSE:
#   - Re-render all tutorials with render_all_pages.R
#   - Check Core Web Vitals in Search Console in ~4 weeks
# ============================================================

library(here)

DRY_RUN <- FALSE   # <- Set to FALSE to write changes

TUTORIALS_DIR <- here("tutorials")

OLD_ATTR <- 'loading="lazy" fetchpriority="high"'
NEW_ATTR <- 'loading="eager" fetchpriority="high"'

qmd_files <- list.files(
  path       = TUTORIALS_DIR,
  pattern    = "\\.qmd$",
  recursive  = TRUE,
  full.names = TRUE
)

cat("Found", length(qmd_files), "tutorial .qmd files\n")
cat("DRY_RUN:", DRY_RUN, "\n\n")

results <- data.frame(
  file   = character(),
  status = character(),
  stringsAsFactors = FALSE
)

modified <- 0
skipped  <- 0

for (qmd_path in qmd_files) {
  rel_path <- gsub(paste0(here(), "/"), "", qmd_path)
  lines    <- readLines(qmd_path, warn = FALSE)

  # Find lines containing the old attribute
  match_idx <- which(grepl(OLD_ATTR, lines, fixed = TRUE))

  if (length(match_idx) == 0) {
    skipped <- skipped + 1
    results <- rbind(results, data.frame(
      file = rel_path, status = "SKIPPED - pattern not found",
      stringsAsFactors = FALSE
    ))
    next
  }

  # Replace old attribute with new on matching lines only
  new_lines <- lines
  new_lines[match_idx] <- gsub(OLD_ATTR, NEW_ATTR,
                                lines[match_idx], fixed = TRUE)

  if (DRY_RUN) {
    cat("WOULD MODIFY:", rel_path, "\n")
    cat("  Line", match_idx, ":\n")
    cat("  OLD:", trimws(lines[match_idx]), "\n")
    cat("  NEW:", trimws(new_lines[match_idx]), "\n\n")
  } else {
    writeLines(new_lines, qmd_path)
    cat("MODIFIED:", rel_path, "\n")
  }

  modified <- modified + 1
  results <- rbind(results, data.frame(
    file   = rel_path,
    status = if (DRY_RUN) "DRY RUN - would modify" else "MODIFIED",
    stringsAsFactors = FALSE
  ))
}

# ── Summary ───────────────────────────────────────────────────────────────────
cat("\n============================================================\n")
cat("Summary\n")
cat("============================================================\n")
cat(if (DRY_RUN) "Would modify: " else "Modified: ", modified, "\n")
cat("Skipped:  ", skipped, "\n")

log_path <- here("helpers", "fix_banner_loading_log.csv")
write.csv(results, log_path, row.names = FALSE)
cat("\nLog saved to:", log_path, "\n")

if (DRY_RUN) {
  cat("\nSet DRY_RUN <- FALSE and re-run to apply changes.\n")
} else {
  cat("\nDone. Re-render all tutorials with render_all_pages.R\n")
}
