# ============================================================
# LADAL — Inject schema-org chunk into all tutorial .qmd files
# ============================================================
#
# Inserts the Schema.org LearningResource JSON-LD chunk into
# every tutorial that doesn't already have it. The chunk reads
# from each tutorial's own params block at render time, so no
# manual editing per tutorial is needed.
#
# Insertion point: immediately after the setup chunk closing ```
# (i.e. after the first code chunk closer following the YAML).
#
# Safe behaviour:
#   - DRY_RUN = TRUE previews all changes without writing anything
#   - Skips any tutorial that already contains "schema-org"
#   - Saves a log CSV to helpers/inject_schema_org_log.csv
#
# After running with DRY_RUN <- FALSE:
#   - Re-render all tutorials with render_all_pages.R
#   - Verify one rendered HTML contains the JSON-LD block
#     by searching the page source for "application/ld+json"
#
# REQUIRES: here
#   install.packages("here")
# ============================================================

library(here)

DRY_RUN <- FALSE   # <- Set to FALSE to write changes

TUTORIALS_DIR <- here("tutorials")

# ── The chunk to inject ───────────────────────────────────────────────────────
# Stored as a character vector (one element per line) to avoid any
# escaping issues that arise from storing R code inside an R string.

CHUNK_LINES <- c(
  '```{r schema-org, echo=FALSE, results=\'asis\'}',
  '# Schema.org structured data - read by Google for rich search results',
  'schema_keywords <- paste0(',
  '  \'"\', trimws(strsplit(params$keywords, ",")[[1]]), \'"\',',
  '  collapse = ", "',
  ')',
  'doi_url <- if (nchar(trimws(params$doi)) > 0) {',
  '  paste0(\'    "sameAs": "https://doi.org/\', params$doi, \'",\\n\')',
  '} else { "" }',
  'cat(paste0(',
  '\'<script type="application/ld+json">',
  '{',
  '  "@context": "https://schema.org",',
  '  "@type": "LearningResource",',
  '  "name": "\', params$title, \'",',
  '  "description": "\', gsub(\'"\', \'\\\\\\\\"\', params$description), \'",',
  '  "url": "\', params$url, \'",',
  '\', doi_url,',
  '\'  "datePublished": "\', params$date_published, \'",',
  '  "version": "\', params$version, \'",',
  '  "inLanguage": "en",',
  '  "educationalLevel": "Graduate",',
  '  "learningResourceType": "Tutorial",',
  '  "keywords": [\', schema_keywords, \'],',
  '  "license": "https://creativecommons.org/licenses/by/4.0/",',
  '  "author": {',
  '    "@type": "Person",',
  '    "name": "\', params$author, \'",',
  '    "sameAs": "https://orcid.org/0000-0003-1923-9153"',
  '  },',
  '  "publisher": {',
  '    "@type": "EducationalOrganization",',
  '    "name": "Language Technology and Data Analysis Laboratory (LADAL)",',
  '    "url": "https://ladal.edu.au",',
  '    "parentOrganization": {',
  '      "@type": "CollegeOrUniversity",',
  '      "name": "The University of Queensland"',
  '    }',
  '  },',
  '  "isPartOf": {',
  '    "@type": "WebSite",',
  '    "name": "LADAL",',
  '    "url": "https://ladal.edu.au"',
  '  }',
  '}',
  '</script>\'))',
  '```'
)

# ── Find all tutorial .qmd files ──────────────────────────────────────────────

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

for (qmd_path in qmd_files) {
  rel_path <- gsub(paste0(here(), "/"), "", qmd_path)
  lines    <- readLines(qmd_path, warn = FALSE)
  content  <- paste(lines, collapse = "\n")

  # Skip if already has the schema-org chunk
  if (grepl("schema-org", content, fixed = TRUE)) {
    cat("SKIPPED (already has schema-org chunk):", rel_path, "\n")
    results <- rbind(results, data.frame(
      file = rel_path, status = "SKIPPED - already has schema-org",
      stringsAsFactors = FALSE
    ))
    next
  }

  # Find YAML end (second --- delimiter)
  delimiters <- which(trimws(lines) == "---")
  if (length(delimiters) < 2) {
    cat("SKIPPED (no YAML found):", rel_path, "\n")
    results <- rbind(results, data.frame(
      file = rel_path, status = "SKIPPED - no YAML",
      stringsAsFactors = FALSE
    ))
    next
  }
  yaml_end <- delimiters[2]

  # Find the first chunk-closing ``` after the YAML
  # (a line that is exactly ``` with nothing else)
  chunk_closers <- which(trimws(lines) == "```")
  chunk_closers_after_yaml <- chunk_closers[chunk_closers > yaml_end]

  if (length(chunk_closers_after_yaml) == 0) {
    cat("SKIPPED (no setup chunk found):", rel_path, "\n")
    results <- rbind(results, data.frame(
      file = rel_path, status = "SKIPPED - no setup chunk closer found",
      stringsAsFactors = FALSE
    ))
    next
  }

  # Insert after the first chunk closer (= after the setup chunk)
  insert_after <- chunk_closers_after_yaml[1]

  # Build the new file: lines up to insertion point, blank line,
  # the chunk, blank line, then the rest of the file
  new_lines <- c(
    lines[1:insert_after],
    "",
    CHUNK_LINES,
    "",
    lines[(insert_after + 1):length(lines)]
  )

  if (DRY_RUN) {
    cat("WOULD INSERT after line", insert_after, "in:", rel_path, "\n")
    results <- rbind(results, data.frame(
      file   = rel_path,
      status = paste("DRY RUN - would insert after line", insert_after),
      stringsAsFactors = FALSE
    ))
  } else {
    writeLines(new_lines, qmd_path)
    cat("INSERTED in:", rel_path, "\n")
    results <- rbind(results, data.frame(
      file   = rel_path,
      status = paste("INSERTED after line", insert_after),
      stringsAsFactors = FALSE
    ))
  }
}

# ── Summary ───────────────────────────────────────────────────────────────────

cat("\n============================================================\n")
cat("Summary\n")
cat("============================================================\n")
cat("Inserted / would insert:", sum(grepl("INSERT", results$status)), "\n")
cat("Skipped:                ", sum(grepl("SKIPPED", results$status)), "\n")

log_path <- here("helpers", "inject_schema_org_log.csv")
write.csv(results, log_path, row.names = FALSE)
cat("\nLog saved to:", log_path, "\n")

if (DRY_RUN) {
  cat("\nSet DRY_RUN <- FALSE and re-run to apply changes.\n")
} else {
  cat("\nDone. Now re-render all tutorials with render_all_pages.R\n")
  cat("Verify by opening a rendered HTML and searching for 'application/ld+json'\n")
}
