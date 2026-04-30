# ============================================================
# LADAL — Zenodo File URL Fetcher
# ============================================================
# Scans all tutorial .qmd files, extracts params$doi (concept DOI),
# queries the Zenodo API to resolve each concept DOI to its latest
# version record ID and uploaded filename, then saves a lookup CSV
# to helpers/zenodo_file_index.csv.
#
# This CSV is consumed by helpers/inject_scholar_meta.R to build
# accurate citation_pdf_url meta tags in every rendered tutorial.
#
# Run this script:
#   - Once after initial Zenodo publishing
#   - Again whenever you publish a new tutorial or upload a new file
#
# REQUIRES:
#   install.packages(c("httr", "jsonlite", "yaml", "here"))
#
# ZENODO TOKEN:
#   Needed for higher rate limits (5000/hr vs 60/hr unauthenticated).
#   Set via: usethis::edit_r_environ() → add ZENODO_TOKEN=your_token
# ============================================================

library(httr)
library(jsonlite)
library(yaml)
library(here)

# ── Configuration ─────────────────────────────────────────────────────────────

ZENODO_TOKEN  <- Sys.getenv("ZENODO_TOKEN")
ZENODO_BASE   <- "https://zenodo.org/api"
TUTORIALS_DIR <- here("tutorials")
OUTPUT_CSV    <- here("helpers", "zenodo_file_index.csv")

# Seconds to pause between API calls — stay well within rate limits
SLEEP <- 0.5

# ── Helper: extract params from .qmd YAML front matter ───────────────────────

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

# ── Helper: query Zenodo API for a concept DOI ────────────────────────────────
# Returns list(record_id, filename, file_url, title) or NULL on failure.

fetch_zenodo_record <- function(concept_doi, token, base_url) {

  # Extract the numeric ID from the concept DOI (10.5281/zenodo.XXXXXXX)
  concept_id <- sub("^10\\.5281/zenodo\\.", "", trimws(concept_doi))

  # Build request headers
  headers <- if (nchar(token) > 0) {
    httr::add_headers(
      "Authorization" = paste("Bearer", token),
      "Accept"        = "application/json"
    )
  } else {
    httr::add_headers("Accept" = "application/json")
  }

  # The concept DOI record lists all versions; the "latest" link gives
  # the most recent version record directly.
  url      <- paste0(base_url, "/records/", concept_id)
  response <- httr::GET(url, config = headers)
  status   <- httr::status_code(response)

  if (status != 200) {
    message("  ✗ HTTP ", status, " for concept DOI ", concept_doi)
    return(NULL)
  }

  content <- tryCatch(
    httr::content(response, as = "parsed", type = "application/json"),
    error = function(e) NULL
  )
  if (is.null(content)) return(NULL)

  # The concept record's "latest" field points to the latest version record
  latest_url <- content$links$latest
  if (is.null(latest_url)) {
    # This IS already the latest version record (single-version deposit)
    latest_url <- paste0(base_url, "/records/", concept_id)
  }

  # Fetch the latest version record to get the file list
  latest_response <- httr::GET(latest_url, config = headers)
  latest_status   <- httr::status_code(latest_response)

  if (latest_status != 200) {
    message("  ✗ HTTP ", latest_status, " fetching latest version for ", concept_doi)
    return(NULL)
  }

  latest_content <- tryCatch(
    httr::content(latest_response, as = "parsed", type = "application/json"),
    error = function(e) NULL
  )
  if (is.null(latest_content)) return(NULL)

  # Extract version record ID
  record_id <- as.character(latest_content$id)

  # Extract the first (and typically only) file entry
  files <- latest_content$files
  if (is.null(files) || length(files) == 0) {
    message("  ⚠ No files found for record ", record_id, " (concept: ", concept_doi, ")")
    return(list(
      record_id = record_id,
      filename  = NA_character_,
      file_url  = NA_character_,
      title     = latest_content$metadata$title %||% NA_character_
    ))
  }

  # Pick the first HTML or any file if no HTML present
  file_entry <- NULL
  for (f in files) {
    fname <- f$key %||% f$filename %||% ""
    if (grepl("\\.html$", fname, ignore.case = TRUE)) {
      file_entry <- f
      break
    }
  }
  # Fall back to first file if no HTML found
  if (is.null(file_entry)) file_entry <- files[[1]]

  filename <- file_entry$key %||% file_entry$filename %||% NA_character_
  # Build the direct download URL
  file_url <- if (!is.na(filename)) {
    paste0("https://zenodo.org/records/", record_id, "/files/", filename)
  } else {
    NA_character_
  }

  list(
    record_id = record_id,
    filename  = filename,
    file_url  = file_url,
    title     = latest_content$metadata$title %||% NA_character_
  )
}

# Null-coalescing operator
`%||%` <- function(a, b) if (!is.null(a) && length(a) > 0) a else b

# ── Main ──────────────────────────────────────────────────────────────────────

cat("============================================================\n")
cat("LADAL — Zenodo File URL Fetcher\n")
cat("============================================================\n\n")

if (nchar(ZENODO_TOKEN) == 0) {
  message("⚠ No ZENODO_TOKEN found — using unauthenticated API (60 req/hr limit).")
  message("  If you hit rate limits, set ZENODO_TOKEN in ~/.Renviron and restart R.\n")
} else {
  cat("Token loaded (authenticated — 5000 req/hr limit)\n\n")
}

# Find all tutorial .qmd files
qmd_files <- list.files(
  path      = TUTORIALS_DIR,
  pattern   = "\\.qmd$",
  recursive = TRUE,
  full.names = TRUE
)
cat("Found", length(qmd_files), "tutorial .qmd files\n\n")

# Build results table
results <- data.frame(
  folder     = character(),
  qmd_file   = character(),
  concept_doi = character(),
  record_id  = character(),
  filename   = character(),
  file_url   = character(),
  title      = character(),
  status     = character(),
  stringsAsFactors = FALSE
)

for (qmd_path in qmd_files) {

  folder   <- basename(dirname(qmd_path))
  rel_path <- gsub(paste0(here(), "/"), "", qmd_path)
  cat("Processing:", folder, "\n")

  params <- extract_params(qmd_path)

  if (is.null(params)) {
    cat("  → Skipped (could not parse params)\n\n")
    results <- rbind(results, data.frame(
      folder = folder, qmd_file = rel_path,
      concept_doi = "", record_id = "", filename = "",
      file_url = "", title = "", status = "PARSE ERROR",
      stringsAsFactors = FALSE
    ))
    next
  }

  doi <- trimws(as.character(params$doi %||% ""))

  if (nchar(doi) == 0) {
    cat("  → Skipped (no DOI in params)\n\n")
    results <- rbind(results, data.frame(
      folder = folder, qmd_file = rel_path,
      concept_doi = "", record_id = "", filename = "",
      file_url = "", title = params$title %||% "",
      status = "NO DOI",
      stringsAsFactors = FALSE
    ))
    next
  }

  cat("  Concept DOI:", doi, "\n")

  record <- fetch_zenodo_record(doi, ZENODO_TOKEN, ZENODO_BASE)
  Sys.sleep(SLEEP)

  if (is.null(record)) {
    cat("  → Failed (API error)\n\n")
    results <- rbind(results, data.frame(
      folder = folder, qmd_file = rel_path,
      concept_doi = doi, record_id = "", filename = "",
      file_url = "", title = params$title %||% "",
      status = "API ERROR",
      stringsAsFactors = FALSE
    ))
    next
  }

  cat("  Record ID:", record$record_id, "\n")
  cat("  Filename: ", record$filename %||% "(none)", "\n")
  cat("  File URL: ", record$file_url  %||% "(none)", "\n\n")

  results <- rbind(results, data.frame(
    folder      = folder,
    qmd_file    = rel_path,
    concept_doi = doi,
    record_id   = record$record_id,
    filename    = record$filename  %||% "",
    file_url    = record$file_url  %||% "",
    title       = record$title     %||% (params$title %||% ""),
    status      = if (!is.na(record$filename)) "OK" else "NO FILE",
    stringsAsFactors = FALSE
  ))
}

# ── Summary ───────────────────────────────────────────────────────────────────

cat("============================================================\n")
cat("Summary\n")
cat("============================================================\n")
cat("Total processed: ", nrow(results), "\n")
cat("OK (file found): ", sum(results$status == "OK"), "\n")
cat("No file:         ", sum(results$status == "NO FILE"), "\n")
cat("No DOI:          ", sum(results$status == "NO DOI"), "\n")
cat("API errors:      ", sum(results$status == "API ERROR"), "\n")
cat("Parse errors:    ", sum(results$status == "PARSE ERROR"), "\n\n")

# Save lookup CSV
write.csv(results, OUTPUT_CSV, row.names = FALSE)
cat("Lookup table saved to:", OUTPUT_CSV, "\n\n")

# Print any problems
problems <- results[results$status != "OK", ]
if (nrow(problems) > 0) {
  cat("── Tutorials needing attention ──────────────────────────\n")
  for (i in seq_len(nrow(problems))) {
    cat("  ", problems$folder[i], "—", problems$status[i], "\n")
  }
}

cat("\nDone. Run helpers/inject_scholar_meta.R next.\n")
