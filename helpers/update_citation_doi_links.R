# ============================================================
# Update citation callouts to include clickable DOI links
# ============================================================
# Run from the root of the ladal repo.
#
# Handles three citation callout variants found across tutorials:
#   Variant A: top callout without doi field
#   Variant B: top callout with plain text doi
#   Variant C: bottom callout with plain text doi
#
# All three are updated to produce a clickable DOI hyperlink
# when params$doi is non-empty.
#
# Set DRY_RUN <- TRUE to preview, FALSE to apply.
# ============================================================

library(here)

DRY_RUN <- FALSE

TUTORIALS_DIR <- here("tutorials")

# ── New citation chunk — used for ALL variants ────────────────────────────
# Produces a clickable DOI link when params$doi is set, nothing when empty.

NEW_CITATION_CHUNK <- function(chunk_label) {
  paste0(
    '```{r ', chunk_label, ', echo=FALSE, results=\'asis\'}
doi_link <- if (nchar(trimws(params$doi)) > 0) {
  paste0(
    " doi: <a href=\\"https://doi.org/", params$doi,
    "\\" target=\\"_blank\\">", params$doi, "</a>."
  )
} else { "" }
cat(
  params$author, ". ",
  params$year,   ". *",
  params$title,  "*. ",
  params$institution, ". ",
  "url: ", params$url, " ",
  "(Version ", params$version, ").",
  doi_link,
  sep = ""
)
```'
  )
}

NEW_TOP    <- NEW_CITATION_CHUNK("citation-callout-top")
NEW_BOTTOM <- NEW_CITATION_CHUNK("citation-callout")

# ── Patterns to find ─────────────────────────────────────────────────────

# Variant A: top callout WITHOUT doi (ends with params$version, ").")
VARIANT_A <- '```{r citation-callout-top, echo=FALSE, results=\'asis\'}
cat(
  params$author, ". ",
  params$year,   ". *",
  params$title,  "*. ",
  params$institution, ". ",
  "url: ", params$url, " ",
  "(Version ", params$version, ").",
  sep = ""
)
```'

# Variant B: top callout WITH plain text doi (ends with params$doi, ".")
VARIANT_B <- '```{r citation-callout-top, echo=FALSE, results=\'asis\'}
cat(
  params$author, ". ",
  params$year,   ". *",
  params$title,  "*. ",
  params$institution, ". ",
  "url: ", params$url, " ",
  "(Version ", params$version, "), ",
  "doi: ", params$doi, ".",
  sep = ""
)
```'

# Variant C: bottom callout with plain text doi
VARIANT_C <- '```{r citation-callout, echo=FALSE, results=\'asis\'}
cat(
  params$author, ". ",
  params$year,   ". *",
  params$title,  "*. ",
  params$institution, ". ",
  "url: ", params$url, " ",
  "(Version ", params$version, "), ",
  "doi: ", params$doi, ".",
  sep = ""
)
```'

# ── Process each tutorial ─────────────────────────────────────────────────

all_qmds <- list.files(
  TUTORIALS_DIR,
  pattern    = "\\.qmd$",
  recursive  = TRUE,
  full.names = TRUE
)

cat("============================================================\n")
cat("Update citation callouts with clickable DOI links\n")
cat(sprintf("Mode: %s\n",
            if (DRY_RUN) "DRY RUN (no files written)" else "LIVE (files modified)"))
cat(sprintf("Tutorials to scan: %d\n", length(all_qmds)))
cat("============================================================\n\n")

n_updated   <- 0
n_unchanged <- 0
counts      <- c(A = 0L, B = 0L, C = 0L)

for (qmd_path in all_qmds) {
  
  rel_path <- sub(paste0(here(), "/"), "", qmd_path)
  lines    <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")
  content  <- paste(lines, collapse = "\n")
  updated  <- content
  changed  <- FALSE
  
  # Variant A: top callout without doi
  if (grepl(VARIANT_A, updated, fixed = TRUE)) {
    updated  <- sub(VARIANT_A, NEW_TOP, updated, fixed = TRUE)
    changed  <- TRUE
    counts["A"] <- counts["A"] + 1L
    if (DRY_RUN) cat(sprintf("  [A] TOP (no doi):    %s\n", rel_path))
  }
  
  # Variant B: top callout with plain text doi
  if (grepl(VARIANT_B, updated, fixed = TRUE)) {
    updated  <- sub(VARIANT_B, NEW_TOP, updated, fixed = TRUE)
    changed  <- TRUE
    counts["B"] <- counts["B"] + 1L
    if (DRY_RUN) cat(sprintf("  [B] TOP (plain doi): %s\n", rel_path))
  }
  
  # Variant C: bottom callout with plain text doi
  if (grepl(VARIANT_C, updated, fixed = TRUE)) {
    updated  <- sub(VARIANT_C, NEW_BOTTOM, updated, fixed = TRUE)
    changed  <- TRUE
    counts["C"] <- counts["C"] + 1L
    if (DRY_RUN) cat(sprintf("  [C] BOTTOM:          %s\n", rel_path))
  }
  
  if (!changed) {
    n_unchanged <- n_unchanged + 1
    next
  }
  
  n_updated <- n_updated + 1
  
  if (!DRY_RUN) {
    writeLines(
      unlist(strsplit(updated, "\n")),
      qmd_path,
      useBytes = FALSE
    )
    cat(sprintf("  UPDATED  %s\n", rel_path))
  }
}

# ── Summary ───────────────────────────────────────────────────────────────

cat("\n============================================================\n")
cat("SUMMARY\n")
cat("============================================================\n\n")
cat(sprintf("  Files updated:           %d\n", n_updated))
cat(sprintf("  Variant A (top, no doi): %d\n", counts["A"]))
cat(sprintf("  Variant B (top, plain):  %d\n", counts["B"]))
cat(sprintf("  Variant C (bottom):      %d\n", counts["C"]))
cat(sprintf("  Files unchanged:         %d\n", n_unchanged))

if (n_unchanged > 0 && DRY_RUN) {
  cat(sprintf(
    "\n  %d files had no matching citation pattern.\n",
    n_unchanged))
  cat("  These may use a non-standard citation chunk format.\n")
  cat("  Check them manually if the count seems high.\n")
}

if (DRY_RUN && n_updated > 0) {
  cat("\n  Set DRY_RUN <- FALSE and re-run to apply changes.\n")
}
cat("\n")