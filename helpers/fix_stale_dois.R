# ============================================================
# LADAL — Correct stale or wrong DOIs in tutorial .qmd files
# ============================================================
# Run AFTER check_stale_dois.R has produced:
#   helpers/zenodo_doi_stale_check.csv
#
# This script reads that report and updates params$doi in
# each tutorial .qmd file where the DOI needs correcting:
#
#   - NOT FOUND: replaces stale DOI with suggested concept DOI
#   - Use concept DOI: replaces version DOI with concept DOI
#
# Set DRY_RUN <- TRUE to preview changes without writing.
# Set DRY_RUN <- FALSE to apply changes.
# ============================================================

library(here)

DRY_RUN <- TRUE

# ── Load the stale check report ───────────────────────────────────────────

report_path <- here("helpers", "zenodo_doi_stale_check.csv")

if (!file.exists(report_path)) {
  stop(
    "Report not found: ", report_path, "\n",
    "Run helpers/check_stale_dois.R first to generate it."
  )
}

report <- read.csv(report_path, stringsAsFactors = FALSE)

cat("============================================================\n")
cat("LADAL — DOI Corrector\n")
cat(sprintf("Mode: %s\n",
    if (DRY_RUN) "DRY RUN (no files written)" else "LIVE (files modified)"))
cat("============================================================\n\n")

# ── Identify tutorials that need updating ────────────────────────────────

# The check script puts the replacement DOI in either:
#   suggested_doi — for NOT FOUND cases (found by title search)
#   concept_doi   — for USE CONCEPT DOI cases
# We consolidate these into a single "new_doi" column.

report$new_doi <- ifelse(
  nchar(trimws(report$suggested_doi)) > 0,
  trimws(report$suggested_doi),   # NOT FOUND: use title-search result
  ifelse(
    nchar(trimws(report$concept_doi)) > 0,
    trimws(report$concept_doi),   # USE CONCEPT DOI: use concept_doi
    ""
  )
)

needs_update <- report[
  nchar(report$new_doi) > 0 &
  report$new_doi != trimws(report$params_doi),
]

cat(sprintf("Tutorials needing DOI correction: %d\n\n", nrow(needs_update)))

if (nrow(needs_update) == 0) {
  cat("Nothing to update — all DOIs are correct.\n\n")
  quit(save = "no")
}

# ── Preview all proposed changes ─────────────────────────────────────────

cat("── Proposed changes ─────────────────────────────────────\n\n")
for (i in seq_len(nrow(needs_update))) {
  cat(sprintf("  Folder:      %s\n", needs_update$folder[i]))
  cat(sprintf("  Status:      %s\n", needs_update$status[i]))
  cat(sprintf("  Current DOI: %s\n", needs_update$params_doi[i]))
  cat(sprintf("  New DOI:     %s\n", needs_update$new_doi[i]))
  cat("\n")
}

if (DRY_RUN) {
  cat("── DRY RUN — no files modified ──────────────────────────\n")
  cat("  Review the proposed changes above.\n")
  cat("  Set DRY_RUN <- FALSE and re-run to apply.\n\n")
  quit(save = "no")
}

# ── Apply changes ─────────────────────────────────────────────────────────

cat("── Applying changes ─────────────────────────────────────\n\n")

n_updated <- 0
n_failed  <- 0

for (i in seq_len(nrow(needs_update))) {

  folder      <- needs_update$folder[i]
  old_doi     <- trimws(needs_update$params_doi[i])
  new_doi     <- trimws(needs_update$new_doi[i])

  # Find the .qmd file for this tutorial
  qmd_files <- list.files(
    here("tutorials", folder),
    pattern    = "\\.qmd$",
    full.names = TRUE
  )

  if (length(qmd_files) == 0) {
    cat(sprintf("  SKIP  %-40s (no .qmd found)\n", folder))
    n_failed <- n_failed + 1
    next
  }

  qmd_path <- qmd_files[1]
  lines    <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")

  # Find the doi: line in the params block
  doi_pattern <- "^(\\s+doi:\\s*)['\"]?.*['\"]?\\s*$"
  doi_idx     <- grep(doi_pattern, lines, perl = TRUE)

  if (length(doi_idx) == 0) {
    cat(sprintf("  SKIP  %-40s (no doi: field found)\n", folder))
    n_failed <- n_failed + 1
    next
  }

  # Verify the current value matches what the report expects
  current_line <- lines[doi_idx[1]]
  current_val  <- trimws(gsub('^\\s+doi:\\s*["\']?|["\']?\\s*$', "",
                               current_line))

  if (nchar(old_doi) > 0 && current_val != old_doi) {
    cat(sprintf("  SKIP  %-40s (doi changed since report — check manually)\n",
                folder))
    cat(sprintf("        Expected: %s\n", old_doi))
    cat(sprintf("        Found:    %s\n", current_val))
    n_failed <- n_failed + 1
    next
  }

  # Replace the doi line with the new value
  # Preserve the original indentation
  indent       <- regmatches(current_line,
                              regexpr("^\\s+", current_line))
  new_line     <- paste0(indent, 'doi:         "', new_doi, '"')
  lines[doi_idx[1]] <- new_line

  writeLines(lines, qmd_path, useBytes = FALSE)
  cat(sprintf("  UPDATED  %-38s\n", folder))
  cat(sprintf("           %s\n", old_doi))
  cat(sprintf("        -> %s\n\n", new_doi))
  n_updated <- n_updated + 1
}

# ── Summary ───────────────────────────────────────────────────────────────

cat("============================================================\n")
cat("SUMMARY\n")
cat("============================================================\n\n")
cat(sprintf("  Updated: %d\n", n_updated))
cat(sprintf("  Skipped: %d\n", n_failed))

if (n_updated > 0) {
  cat("\n  Next steps:\n")
  cat("  1. Re-render the updated tutorials\n")
  cat("  2. Commit and push\n\n")
}
