# ============================================================
# LADAL — Google Scholar Meta Tag Injector
# ============================================================
# Reads each rendered tutorial HTML in docs/tutorials/,
# injects Google Scholar citation meta tags into <head>,
# and writes the file back in place.
#
# Depends on helpers/zenodo_file_index.csv produced by
# helpers/fetch_zenodo_file_urls.R — run that script first.
#
# This script is registered as a post-render step in _quarto.yml:
#
#   post-render:
#     - helpers/generate_redirects.R
#     - helpers/inject_scholar_meta.R
#
# It is idempotent: re-running after a re-render removes any
# previously injected tags before injecting fresh ones, so
# tags are never duplicated.
#
# REQUIRES:
#   install.packages(c("yaml", "here"))
# ============================================================

library(yaml)
library(here)

# ── Configuration ─────────────────────────────────────────────────────────────

TUTORIALS_DIR <- here("tutorials")
DOCS_DIR      <- here("docs", "tutorials")
INDEX_CSV     <- here("helpers", "zenodo_file_index.csv")

# Set TRUE to preview changes without writing any files
DRY_RUN <- FALSE

# ── Helpers ───────────────────────────────────────────────────────────────────

`%||%` <- function(a, b) if (!is.null(a) && length(a) > 0 && nchar(as.character(a)) > 0) a else b

extract_params <- function(qmd_path) {
  lines <- readLines(qmd_path, warn = FALSE)
  delimiters <- which(trimws(lines) == "---")
  if (length(delimiters) < 2) return(NULL)
  yaml_block <- lines[(delimiters[1] + 1):(delimiters[2] - 1)]
  parsed <- tryCatch(
    yaml::yaml.load(paste(yaml_block, collapse = "\n")),
    error = function(e) NULL
  )
  if (is.null(parsed)) return(NULL)
  parsed$params
}

# Build the block of citation meta tags for one tutorial
build_meta_block <- function(params, file_url) {

  title       <- trimws(as.character(params$title       %||% ""))
  author      <- trimws(as.character(params$author      %||% "Martin Schweinberger"))
  year        <- trimws(as.character(params$year        %||% "2026"))
  date_pub    <- trimws(as.character(params$date_published %||% ""))
  doi         <- trimws(as.character(params$doi         %||% ""))
  url         <- trimws(as.character(params$url         %||% ""))
  institution <- trimws(as.character(
    params$institution %||%
    "Language Technology and Data Analysis Laboratory (LADAL), The University of Queensland"
  ))

  # Format date as YYYY/MM/DD for citation_online_date
  online_date <- if (
    nchar(date_pub) >= 10 &&
    grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}", date_pub)
  ) {
    gsub("-", "/", substr(date_pub, 1, 10))
  } else {
    paste0(year, "/01/01")
  }

  # Handle multiple authors ("A and B" → two separate tags)
  authors <- trimws(strsplit(author, " and ")[[1]])
  author_tags <- paste0(
    sapply(authors, function(a) {
      # Reformat "Firstname Lastname" → "Lastname, Firstname" for Scholar
      parts <- strsplit(trimws(a), " ")[[1]]
      if (length(parts) >= 2) {
        formatted <- paste0(tail(parts, 1), ", ", paste(head(parts, -1), collapse = " "))
      } else {
        formatted <- a
      }
      paste0('  <meta name="citation_author" content="', formatted, '">')
    }),
    collapse = "\n"
  )

  # Assemble all tags
  tags <- c(
    "  <!-- Google Scholar citation meta tags — injected by inject_scholar_meta.R -->",
    paste0('  <meta name="citation_title" content="',
           gsub('"', '&quot;', title), '">'),
    author_tags,
    paste0('  <meta name="citation_publication_date" content="', year, '">'),
    paste0('  <meta name="citation_online_date" content="', online_date, '">'),
    paste0('  <meta name="citation_language" content="en">'),
    paste0('  <meta name="citation_publisher" content="',
           gsub('"', '&quot;', institution), '">'),
    if (nchar(doi) > 0)
      paste0('  <meta name="citation_doi" content="', doi, '">'),
    if (nchar(file_url) > 0)
      paste0('  <meta name="citation_pdf_url" content="', file_url, '">'),
    if (nchar(url) > 0)
      paste0('  <meta name="citation_fulltext_html_url" content="', url, '">'),
    "  <!-- end citation meta tags -->"
  )

  paste(tags, collapse = "\n")
}

# Inject (or replace) meta block in HTML string
# Removes any previously injected block first, then inserts before </head>
inject_into_html <- function(html_text, meta_block) {

  # Remove previously injected block (idempotent)
  html_text <- gsub(
    "\\s*<!-- Google Scholar citation meta tags[^<]*inject_scholar_meta\\.R -->.*?<!-- end citation meta tags -->",
    "",
    html_text,
    perl = TRUE
  )

  # Insert just before </head>
  if (!grepl("</head>", html_text, fixed = TRUE)) {
    message("  ⚠ No </head> tag found — skipping injection")
    return(html_text)
  }

  sub(
    "</head>",
    paste0(meta_block, "\n</head>"),
    html_text,
    fixed = TRUE
  )
}

# ── Main ──────────────────────────────────────────────────────────────────────

cat("============================================================\n")
cat("LADAL — Google Scholar Meta Tag Injector\n")
if (DRY_RUN) cat("MODE: DRY RUN (no files will be written)\n")
cat("============================================================\n\n")

# Load the Zenodo file index
if (!file.exists(INDEX_CSV)) {
  stop(
    "helpers/zenodo_file_index.csv not found.\n",
    "Run helpers/fetch_zenodo_file_urls.R first."
  )
}
index <- read.csv(INDEX_CSV, stringsAsFactors = FALSE)
cat("Loaded Zenodo file index:", nrow(index), "entries\n\n")

# Find all tutorial .qmd files (source of metadata)
qmd_files <- list.files(
  path       = TUTORIALS_DIR,
  pattern    = "\\.qmd$",
  recursive  = TRUE,
  full.names = TRUE
)
cat("Found", length(qmd_files), "tutorial .qmd files\n\n")

# Counters
n_ok      <- 0
n_skipped <- 0
n_missing <- 0
n_error   <- 0

for (qmd_path in qmd_files) {

  folder   <- basename(dirname(qmd_path))
  html_out <- file.path(DOCS_DIR, folder, paste0(folder, ".html"))

  cat("Processing:", folder, "\n")

  # Check rendered HTML exists
  if (!file.exists(html_out)) {
    cat("  → Skipped (rendered HTML not found:", html_out, ")\n\n")
    n_missing <- n_missing + 1
    next
  }

  # Extract params
  params <- extract_params(qmd_path)
  if (is.null(params)) {
    cat("  → Skipped (could not parse .qmd params)\n\n")
    n_skipped <- n_skipped + 1
    next
  }

  # Look up file_url from the index
  idx_row  <- index[index$folder == folder, ]
  file_url <- if (nrow(idx_row) > 0 && nchar(idx_row$file_url[1]) > 0) {
    idx_row$file_url[1]
  } else {
    ""
  }

  if (nchar(file_url) == 0) {
    cat("  ⚠ No file_url in index — citation_pdf_url will be omitted\n")
  } else {
    cat("  File URL:", file_url, "\n")
  }

  # Build meta block
  meta_block <- tryCatch(
    build_meta_block(params, file_url),
    error = function(e) {
      message("  ✗ Error building meta block: ", e$message)
      NULL
    }
  )
  if (is.null(meta_block)) {
    n_error <- n_error + 1
    next
  }

  # Read, inject, write
  html_text <- paste(readLines(html_out, warn = FALSE), collapse = "\n")
  html_new  <- inject_into_html(html_text, meta_block)

  if (DRY_RUN) {
    cat("  [DRY RUN] Would inject meta tags into:", html_out, "\n\n")
  } else {
    writeLines(html_new, html_out)
    cat("  ✓ Injected into:", html_out, "\n\n")
  }

  n_ok <- n_ok + 1
}

# ── Summary ───────────────────────────────────────────────────────────────────

cat("============================================================\n")
cat("Summary\n")
cat("============================================================\n")
cat("Injected:     ", n_ok, "\n")
cat("Missing HTML: ", n_missing, "\n")
cat("Skipped:      ", n_skipped, "\n")
cat("Errors:       ", n_error, "\n\n")

if (DRY_RUN) {
  cat("Dry run complete. Set DRY_RUN <- FALSE to apply changes.\n")
} else {
  cat("Done. Commit and push docs/ to deploy.\n\n")
  cat("Next steps:\n")
  cat("  1. Verify a tutorial in browser: right-click → View Page Source\n")
  cat("     Search for 'citation_title' — it should appear in <head>\n")
  cat("  2. Commit and push\n")
  cat("  3. Request Google Scholar re-indexing via Search Console\n")
  cat("     (Coverage → Inspect URL → Request Indexing)\n")
}
