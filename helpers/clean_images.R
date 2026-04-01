# ============================================================
# LADAL Unused Image Cleaner — Fast Version (fixed)
# ============================================================
# Run from the root of the ladal repo.
# Set DRY_RUN <- TRUE to preview, FALSE to actually delete.
# ============================================================

library(here)

DRY_RUN    <- FALSE
IMAGES_DIR <- here("images")

cat("============================================================\n")
cat("LADAL Unused Image Cleaner\n")
cat(sprintf("Mode: %s\n",
    if (DRY_RUN) "DRY RUN (no files deleted)" else "LIVE (will delete)"))
cat("============================================================\n\n")

# ── Step 1: Get all images ────────────────────────────────────────────────

all_images <- list.files(IMAGES_DIR, recursive = FALSE, full.names = FALSE)
cat(sprintf("Images in images/: %d\n", length(all_images)))

# ── Step 2: Collect source files — with tight exclusions ─────────────────

cat("Finding source files...\n")

# Only scan these top-level folders (not renv, .git, node_modules etc.)
scan_dirs <- c(
  here("tutorials"),   # all tutorial .qmd files
  here("assets"),      # CSS, JS assets
  here("helpers")      # helper scripts
)

# Also scan .qmd and .yml files at the repo root only (not recursive)
root_files <- list.files(
  here(),
  pattern    = "\\.(qmd|yml|yaml|css|md)$",
  recursive  = FALSE,
  full.names = TRUE
)

# Recursively scan the focused directories
subdir_files <- unlist(lapply(scan_dirs, function(d) {
  if (!dir.exists(d)) return(character(0))
  list.files(
    d,
    pattern    = "\\.(qmd|yml|yaml|css|md|Rmd|R)$",
    recursive  = TRUE,
    full.names = TRUE
  )
}))

all_source_files <- unique(c(root_files, subdir_files))

# Safety: exclude anything inside docs/, renv/, .git/, node_modules/
exclude_patterns <- c("/docs/", "/renv/", "/.git/", "/node_modules/",
                      "/.Rproj.user/", "/packrat/")
for (pat in exclude_patterns) {
  all_source_files <- all_source_files[
    !grepl(pat, all_source_files, fixed = TRUE)
  ]
}

cat(sprintf("Source files to search: %d\n\n", length(all_source_files)))

# ── Step 3: Read all source files safely into one string ─────────────────

cat("Loading source content...\n")

read_safe <- function(path) {
  # Try UTF-8 first, fall back to latin1, return "" on any error
  tryCatch({
    lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
    paste(lines, collapse = " ")
  }, error = function(e) {
    tryCatch({
      lines <- readLines(path, warn = FALSE, encoding = "latin1")
      # Convert to ASCII-safe by removing non-ASCII characters
      iconv(paste(lines, collapse = " "), from = "latin1",
            to = "ASCII", sub = "")
    }, error = function(e2) ""
    )
  })
}

all_content <- paste(
  vapply(all_source_files, read_safe, character(1)),
  collapse = " "
)

cat(sprintf("Content loaded: %.1f MB\n\n",
    nchar(all_content, type = "bytes") / 1e6))

# ── Step 4: Check each image ──────────────────────────────────────────────

cat("Checking images...\n")

referenced   <- character(0)
unreferenced <- character(0)

for (img in all_images) {
  if (grepl(img, all_content, fixed = TRUE)) {
    referenced <- c(referenced, img)
  } else {
    unreferenced <- c(unreferenced, img)
  }
}

# ── Step 5: Report ────────────────────────────────────────────────────────

cat("\n============================================================\n")
cat("RESULTS\n")
cat("============================================================\n\n")
cat(sprintf("Referenced (KEEP):     %d\n", length(referenced)))
cat(sprintf("Unreferenced (REMOVE): %d\n\n", length(unreferenced)))

if (length(unreferenced) > 0) {
  cat("── Images to remove ─────────────────────────────────────\n")
  for (img in sort(unreferenced)) {
    size_kb <- round(
      file.info(file.path(IMAGES_DIR, img))$size / 1024, 1)
    cat(sprintf("  %-50s (%s KB)\n", img, size_kb))
  }
  total_mb <- round(
    sum(file.info(file.path(IMAGES_DIR, unreferenced))$size,
        na.rm = TRUE) / 1024 / 1024, 2)
  cat(sprintf("\n  Total recoverable: %.2f MB\n\n", total_mb))
} else {
  cat("  No unreferenced images found — images/ is clean.\n\n")
}

cat("── Images to keep ───────────────────────────────────────\n")
for (img in sort(referenced)) cat(sprintf("  %s\n", img))
cat("\n")

# ── Step 6: Delete if not dry run ─────────────────────────────────────────

if (!DRY_RUN && length(unreferenced) > 0) {
  cat("============================================================\n")
  cat("DELETING unreferenced images...\n")
  cat("============================================================\n\n")
  deleted <- 0
  for (img in unreferenced) {
    if (file.remove(file.path(IMAGES_DIR, img))) {
      cat(sprintf("  DELETED  %s\n", img))
      deleted <- deleted + 1
    } else {
      cat(sprintf("  FAILED   %s\n", img))
    }
  }
  cat(sprintf("\nDeleted %d files.\n\n", deleted))
} else if (DRY_RUN && length(unreferenced) > 0) {
  cat("============================================================\n")
  cat("DRY RUN — nothing deleted.\n")
  cat("Set DRY_RUN <- FALSE and re-run to delete.\n")
  cat("============================================================\n\n")
}

# ── Step 7: Save audit CSV ────────────────────────────────────────────────

report <- data.frame(
  image   = c(referenced, unreferenced),
  status  = c(rep("KEEP",   length(referenced)),
              rep("REMOVE", length(unreferenced))),
  size_kb = round(
    file.info(
      file.path(IMAGES_DIR, c(referenced, unreferenced))
    )$size / 1024, 1),
  stringsAsFactors = FALSE
)
report <- report[order(report$status, report$image), ]
report_path <- here("helpers", "image_audit.csv")
write.csv(report, report_path, row.names = FALSE)
cat(sprintf("Audit saved to: %s\n\n", report_path))
