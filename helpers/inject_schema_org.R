# ============================================================
# LADAL — Schema.org LearningResource chunk template
# ============================================================
#
# This file contains two things:
#
#   PART A — The R chunk to paste into each tutorial .qmd,
#             placed anywhere in the document body (recommended:
#             just after the YAML front matter, before the
#             first heading, alongside the setup chunk).
#
#   PART B — A script to inject the chunk automatically into
#             all tutorials that don't already have it.
#
# The chunk emits a <script type="application/ld+json"> block
# using each tutorial's own params values. This tells Google
# exactly what kind of content the page is, who wrote it,
# when it was published, and what the DOI is.
#
# Google uses LearningResource schema to generate rich results
# for educational content — course cards, knowledge panels,
# and structured snippets in search results.
# ============================================================


# ── PART A: Paste this chunk into each tutorial ───────────────────────────────
#
# Place it after the setup chunk, before the first heading (# Introduction).
# It runs silently (echo=FALSE, results='asis') and emits JSON-LD into the page.

CHUNK_TEMPLATE <- r"(
```{r schema-org, echo=FALSE, results='asis'}
# Schema.org structured data — read by Google for rich search results
schema_keywords <- paste0(
  '"', trimws(strsplit(params$keywords, ",")[[1]]), '"',
  collapse = ", "
)
doi_url <- if (nchar(trimws(params$doi)) > 0) {
  paste0('    "sameAs": "https://doi.org/', params$doi, '",\n')
} else { "" }
cat(paste0(
'<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "LearningResource",
  "name": "', params$title, '",
  "description": "', gsub('"', '\\\\"', params$description), '",
  "url": "', params$url, '",
', doi_url,
'  "datePublished": "', params$date_published, '",
  "version": "', params$version, '",
  "inLanguage": "en",
  "educationalLevel": "Graduate",
  "learningResourceType": "Tutorial",
  "keywords": [', schema_keywords, '],
  "license": "https://creativecommons.org/licenses/by/4.0/",
  "author": {
    "@type": "Person",
    "name": "', params$author, '",
    "sameAs": "https://orcid.org/0000-0003-1923-9153"
  },
  "publisher": {
    "@type": "EducationalOrganization",
    "name": "Language Technology and Data Analysis Laboratory (LADAL)",
    "url": "https://ladal.edu.au",
    "parentOrganization": {
      "@type": "CollegeOrUniversity",
      "name": "The University of Queensland"
    }
  },
  "isPartOf": {
    "@type": "WebSite",
    "name": "LADAL",
    "url": "https://ladal.edu.au"
  }
}
<\/script>'))
```
)"


# ── PART B: Script to inject the chunk into all tutorials ─────────────────────

library(here)

DRY_RUN <- TRUE   # Set to FALSE to actually write changes

TUTORIALS_DIR <- here("tutorials")

# Marker string — if this appears in a file, we skip it (already injected)
MARKER <- "schema-org"

qmd_files <- list.files(
  path       = TUTORIALS_DIR,
  pattern    = "\\.qmd$",
  recursive  = TRUE,
  full.names = TRUE
)

cat("Found", length(qmd_files), "tutorial .qmd files\n")
cat("DRY_RUN:", DRY_RUN, "\n\n")

injected <- 0
skipped  <- 0

for (qmd_path in qmd_files) {
  rel_path <- gsub(paste0(here(), "/"), "", qmd_path)
  content  <- paste(readLines(qmd_path, warn = FALSE), collapse = "\n")

  # Skip if already has schema-org chunk
  if (grepl(MARKER, content, fixed = TRUE)) {
    cat("SKIPPED (already has schema chunk):", rel_path, "\n")
    skipped <- skipped + 1
    next
  }

  # Find the setup chunk — inject schema chunk immediately after it
  # Pattern: end of the ```{r setup ...} ... ``` block
  # We look for the closing ``` of the setup chunk followed by newlines,
  # then the banner image line (which follows setup in all tutorials).
  #
  # Strategy: find the first ``` that closes the setup chunk.
  # The setup chunk is always the first code chunk after the YAML.
  lines <- strsplit(content, "\n")[[1]]

  # Find YAML end
  delimiters <- which(trimws(lines) == "---")
  if (length(delimiters) < 2) {
    cat("SKIPPED (no YAML):", rel_path, "\n")
    skipped <- skipped + 1
    next
  }
  yaml_end <- delimiters[2]

  # Find the first ``` that closes a chunk after YAML
  # (i.e., a line that is exactly ``` with nothing else)
  chunk_closers <- which(trimws(lines) == "```")
  chunk_closers_after_yaml <- chunk_closers[chunk_closers > yaml_end]

  if (length(chunk_closers_after_yaml) == 0) {
    cat("SKIPPED (no chunk closer found):", rel_path, "\n")
    skipped <- skipped + 1
    next
  }

  # Insert point: after the first chunk closer (= after setup chunk)
  insert_after <- chunk_closers_after_yaml[1]

  # Build modified content
  chunk_lines <- strsplit(trimws(CHUNK_TEMPLATE), "\n")[[1]]
  new_lines <- c(
    lines[1:insert_after],
    "",
    chunk_lines,
    "",
    lines[(insert_after + 1):length(lines)]
  )

  if (DRY_RUN) {
    cat("WOULD INJECT schema chunk after line", insert_after, "in:", rel_path, "\n")
  } else {
    writeLines(new_lines, qmd_path)
    cat("INJECTED:", rel_path, "\n")
  }
  injected <- injected + 1
}

cat("\n============================================================\n")
cat("Summary\n")
cat("============================================================\n")
cat(if (DRY_RUN) "Would inject: " else "Injected: ", injected, "\n")
cat("Skipped:  ", skipped, "\n")
cat("\nSet DRY_RUN <- FALSE and re-run to apply changes.\n")
