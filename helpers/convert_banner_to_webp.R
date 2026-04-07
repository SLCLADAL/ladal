# ============================================================
# Convert uq1.jpg to WebP and update all tutorial .qmd files
# ============================================================
# Run from the root of the ladal repo.
#
# This script:
#   1. Converts images/uq1.jpg to images/uq1.webp using magick
#   2. Scans all tutorial .qmd files for any variant of the
#      uq1 image insertion and replaces it with the correct
#      standardised form:
#
#      ![Great Court, The University of Queensland](/images/uq1.webp){width="100%" height="200px" loading="lazy" fetchpriority="high"}
#
# Set DRY_RUN <- TRUE to preview changes without writing.
# Set DRY_RUN <- FALSE to apply changes.
# ============================================================

library(here)
library(magick)

DRY_RUN <- FALSE

# ── Correct image insertion line ──────────────────────────────────────────

CORRECT_LINE <- '![Great Court, The University of Queensland](/images/uq1.webp){width="100%" height="200px" loading="lazy" fetchpriority="high"}'

# ── Step 1: Convert uq1.jpg to uq1.webp ──────────────────────────────────

cat("============================================================\n")
cat("Step 1 — Convert uq1.jpg to uq1.webp\n")
cat("============================================================\n\n")

jpg_path  <- here("images", "uq1.jpg")
webp_path <- here("images", "uq1.webp")

if (!file.exists(jpg_path)) {
  stop("images/uq1.jpg not found. Check the path and try again.")
}

jpg_size_kb <- round(file.info(jpg_path)$size / 1024)
cat(sprintf("Source: uq1.jpg (%d KB)\n", jpg_size_kb))

if (!DRY_RUN) {
  img <- magick::image_read(jpg_path)

  # Resize to max 1600px wide (sufficient for full-width display)
  # and convert to WebP with quality 82 (good balance of size/quality)
  img <- magick::image_resize(img, "1600x")
  magick::image_write(img, path = webp_path,
                       format = "webp", quality = 82)

  webp_size_kb <- round(file.info(webp_path)$size / 1024)
  saving_pct   <- round((1 - webp_size_kb / jpg_size_kb) * 100)
  cat(sprintf("Output: uq1.webp (%d KB) — %d%% smaller\n\n",
              webp_size_kb, saving_pct))
} else {
  cat("DRY RUN — conversion skipped\n\n")
}

# ── Step 2: Update image lines in all tutorial .qmd files ─────────────────

cat("============================================================\n")
cat("Step 2 — Update image lines in tutorial .qmd files\n")
cat("============================================================\n\n")

all_qmds <- c(
  list.files(here("tutorials"), pattern = "\\.qmd$",
             recursive = TRUE, full.names = TRUE),
  list.files(here(), pattern = "\\.qmd$",
             recursive = FALSE, full.names = TRUE)
)

# Pattern to match ANY variant of the uq1 image line:
#   - jpg or webp
#   - with or without alt text
#   - with any combination of attributes
#   - with or without attributes block entirely
UQ1_PATTERN <- "^!\\[.*\\]\\(/images/uq1\\.(jpg|webp)\\).*$"

n_updated   <- 0
n_correct   <- 0
n_no_image  <- 0

for (qmd_path in all_qmds) {

  rel_path <- sub(paste0(here(), "/"), "", qmd_path)
  lines    <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")

  # Find lines matching the uq1 image pattern
  img_idx  <- grep(UQ1_PATTERN, lines, perl = TRUE)

  if (length(img_idx) == 0) {
    n_no_image <- n_no_image + 1
    next
  }

  changed <- FALSE

  for (idx in img_idx) {
    current <- lines[idx]

    if (current == CORRECT_LINE) {
      # Already correct
      next
    }

    # Replace with correct line
    if (DRY_RUN) {
      cat(sprintf("  WOULD UPDATE  %s\n", rel_path))
      cat(sprintf("    FROM: %s\n", current))
      cat(sprintf("    TO:   %s\n\n", CORRECT_LINE))
    }
    lines[idx] <- CORRECT_LINE
    changed    <- TRUE
  }

  if (changed) {
    n_updated <- n_updated + 1
    if (!DRY_RUN) {
      writeLines(lines, qmd_path, useBytes = FALSE)
      cat(sprintf("  UPDATED  %s\n", rel_path))
    }
  } else {
    n_correct <- n_correct + 1
  }
}

# ── Summary ───────────────────────────────────────────────────────────────

cat("\n============================================================\n")
cat("SUMMARY\n")
cat("============================================================\n\n")
cat(sprintf("  Files updated:          %d\n", n_updated))
cat(sprintf("  Files already correct:  %d\n", n_correct))
cat(sprintf("  Files without image:    %d\n", n_no_image))

if (DRY_RUN) {
  cat("\n  Set DRY_RUN <- FALSE and re-run to apply changes.\n")
} else {
  cat("\n  Next steps:\n")
  cat("  1. Verify uq1.webp looks correct in a browser\n")
  cat("  2. Re-render all tutorials with render_all.R\n")
  cat("  3. Commit and push\n")
  cat("  4. Submit tutorial URLs to Google Search Console\n")
}
cat("\n")
