# ============================================================
# Remove format: block from all tutorial YAML headers
# ============================================================
# Run from the root of the ladal repo.
#
# Removes the entire format: block from every tutorial .qmd
# file since these settings are now defined globally in
# _quarto.yml and do not need to be repeated per tutorial.
#
# Set DRY_RUN <- TRUE to preview changes without writing,
# Set DRY_RUN <- FALSE to apply changes.
# ============================================================

library(here)

DRY_RUN       <- FALSE
TUTORIALS_DIR <- here("tutorials")

# ── Find all tutorial .qmd files ─────────────────────────────────────────

all_qmds <- list.files(
  TUTORIALS_DIR,
  pattern    = "\\.qmd$",
  recursive  = TRUE,
  full.names = TRUE
)

cat("============================================================\n")
cat("Remove format: block from tutorial YAML headers\n")
cat(sprintf("Mode: %s\n",
    if (DRY_RUN) "DRY RUN (no files written)" else "LIVE (files will be modified)"))
cat(sprintf("Tutorials found: %d\n", length(all_qmds)))
cat("============================================================\n\n")

# ── Helper: remove format block from YAML front matter ───────────────────
# Removes everything from the line "format:" up to (but not including)
# the next top-level key (a line that starts with a word character
# and is not indented) or the closing "---".

remove_format_block <- function(lines) {

  # Find the two YAML delimiters
  delims <- which(trimws(lines) == "---")
  if (length(delims) < 2) return(list(lines = lines, changed = FALSE))

  yaml_start <- delims[1] + 1
  yaml_end   <- delims[2] - 1

  if (yaml_start > yaml_end) return(list(lines = lines, changed = FALSE))

  yaml_lines <- lines[yaml_start:yaml_end]

  # Find the line index (within yaml_lines) where "format:" starts
  format_idx <- grep("^format\\s*:", yaml_lines)
  if (length(format_idx) == 0) {
    return(list(lines = lines, changed = FALSE))
  }

  format_start <- format_idx[1]

  # Find where the format block ends — the next top-level key
  # (a line that starts with a non-space character and contains ":")
  # or the end of the YAML block
  block_end <- length(yaml_lines)  # default: goes to end of YAML

  if (format_start < length(yaml_lines)) {
    for (i in (format_start + 1):length(yaml_lines)) {
      line <- yaml_lines[i]
      # A top-level key: starts with a letter/word char, not indented
      if (grepl("^[a-zA-Z_]", line) && grepl(":", line)) {
        block_end <- i - 1
        break
      }
    }
  }

  # Remove the format block lines from yaml_lines
  lines_to_remove <- format_start:block_end
  yaml_lines_new  <- yaml_lines[-lines_to_remove]

  # Reconstruct the full file
  lines_new <- c(
    lines[1:delims[1]],          # opening ---
    yaml_lines_new,              # YAML without format block
    lines[delims[2]:length(lines)] # closing --- and rest of file
  )

  list(lines = lines_new, changed = TRUE)
}

# ── Process each file ─────────────────────────────────────────────────────

n_changed  <- 0
n_skipped  <- 0
n_no_block <- 0

for (qmd_path in all_qmds) {

  rel_path <- sub(paste0(here(), "/"), "", qmd_path)
  lines    <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")

  result <- tryCatch(
    remove_format_block(lines),
    error = function(e) list(lines = lines, changed = FALSE, error = TRUE)
  )

  if (isTRUE(result$error)) {
    cat(sprintf("  ERROR    %s\n", rel_path))
    next
  }

  if (!result$changed) {
    n_no_block <- n_no_block + 1
    next
  }

  # Show a preview of what will be removed
  old_format_lines <- lines[
    grep("^format\\s*:", lines)[1]:
    (grep("^format\\s*:", lines)[1] +
     (length(lines) - length(result$lines)))
  ]

  if (DRY_RUN) {
    cat(sprintf("  WOULD REMOVE from %s:\n", rel_path))
    for (l in old_format_lines) cat(sprintf("    %s\n", l))
    cat("\n")
  } else {
    writeLines(result$lines, qmd_path, useBytes = FALSE)
    cat(sprintf("  UPDATED  %s (%d lines removed)\n",
        rel_path,
        length(lines) - length(result$lines)))
  }

  n_changed <- n_changed + 1
}

# ── Summary ───────────────────────────────────────────────────────────────

cat("\n============================================================\n")
cat("SUMMARY\n")
cat("============================================================\n\n")
cat(sprintf("  format: block found and %s: %d\n",
    if (DRY_RUN) "would be removed" else "removed", n_changed))
cat(sprintf("  No format: block (skipped):  %d\n", n_no_block))

if (DRY_RUN && n_changed > 0) {
  cat("\n  Set DRY_RUN <- FALSE and re-run to apply changes.\n")
}
cat("\n")
