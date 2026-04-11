# ============================================================
# LADAL — DOI Checker
# ============================================================
# Scans every tutorial .qmd file, extracts the params$doi field,
# and validates each DOI by hitting the Zenodo API.
#
# Reports:
#   OK        — DOI resolves correctly on Zenodo
#   NOT FOUND — DOI is not in the Zenodo system (bad/typo DOI)
#   HTTP XXX  — unexpected HTTP status code from Zenodo
#   MISSING   — params block has no doi field at all
#   EMPTY     — doi field present but blank
#   PARSE ERR — could not read/parse the .qmd file
#
# Output:
#   Prints a summary table to the console
#   Saves helpers/doi_check_results.csv for further inspection
#
# REQUIRES:
#   install.packages(c("httr", "yaml", "here"))
# ============================================================

library(httr)
library(yaml)
library(here)

# ── Configuration ─────────────────────────────────────────────────────────────

# Path to tutorials folder
TUTORIALS_DIR <- here("tutorials")

# Zenodo API base — no token required for public record lookups
ZENODO_BASE <- "https://zenodo.org/api"

# Pause between API calls (seconds) to avoid rate limiting
SLEEP_BETWEEN_CALLS <- 0.5

# ── Helper: extract params from .qmd YAML front matter ───────────────────────

extract_params <- function(qmd_path) {
  lines <- readLines(qmd_path, warn = FALSE)
  yaml_delimiters <- which(trimws(lines) == "---")
  if (length(yaml_delimiters) < 2) return(NULL)
  yaml_block <- lines[(yaml_delimiters[1] + 1):(yaml_delimiters[2] - 1)]
  parsed <- tryCatch(
    yaml::yaml.load(paste(yaml_block, collapse = "\n")),
    error = function(e) NULL
  )
  if (is.null(parsed)) return(NULL)
  parsed$params
}

# ── Helper: check a single DOI against Zenodo ────────────────────────────────
# Uses the /records endpoint — works for concept DOIs and version DOIs.
# Returns a list with: status ("OK", "NOT FOUND", "HTTP XXX"), record_id, title

check_doi <- function(doi) {

  if (is.null(doi) || nchar(trimws(doi)) == 0) {
    return(list(status = "EMPTY", record_id = NA, title = NA, doi_used = doi))
  }

  doi <- trimws(doi)

  # Strip any leading "https://doi.org/" that may have crept in
  doi_clean <- sub("^https?://doi\\.org/", "", doi)

  # Extract the Zenodo record ID from the DOI: 10.5281/zenodo.XXXXXXX
  # Concept DOIs and version DOIs both contain the record number
  zenodo_id <- sub("^10\\.5281/zenodo\\.", "", doi_clean)

  if (!grepl("^[0-9]+$", zenodo_id)) {
    # DOI doesn't look like a Zenodo DOI at all
    return(list(
      status     = "MALFORMED",
      record_id  = NA,
      title      = NA,
      doi_used   = doi_clean
    ))
  }

  # Hit the Zenodo records API
  url <- paste0(ZENODO_BASE, "/records/", zenodo_id)
  response <- tryCatch(
    httr::GET(
      url,
      httr::add_headers("Accept" = "application/json"),
      httr::timeout(10)
    ),
    error = function(e) NULL
  )

  if (is.null(response)) {
    return(list(
      status    = "NETWORK ERROR",
      record_id = zenodo_id,
      title     = NA,
      doi_used  = doi_clean
    ))
  }

  http_status <- httr::status_code(response)

  if (http_status == 200) {
    content <- tryCatch(
      httr::content(response, as = "parsed", type = "application/json"),
      error = function(e) list()
    )
    # Title is nested differently for concept vs version records
    title <- content$metadata$title %||% content$title %||% NA
    return(list(
      status    = "OK",
      record_id = zenodo_id,
      title     = title,
      doi_used  = doi_clean
    ))
  }

  if (http_status == 404) {
    return(list(
      status    = "NOT FOUND",
      record_id = zenodo_id,
      title     = NA,
      doi_used  = doi_clean
    ))
  }

  # Unexpected status
  return(list(
    status    = paste0("HTTP ", http_status),
    record_id = zenodo_id,
    title     = NA,
    doi_used  = doi_clean
  ))
}

# Null-coalescing helper
`%||%` <- function(a, b) if (!is.null(a) && length(a) > 0 && !is.na(a)) a else b

# ── Main ──────────────────────────────────────────────────────────────────────

cat("============================================================\n")
cat("LADAL DOI Checker\n")
cat("============================================================\n\n")

qmd_files <- list.files(
  path      = TUTORIALS_DIR,
  pattern   = "\\.qmd$",
  recursive = TRUE,
  full.names = TRUE
)

cat("Found", length(qmd_files), "tutorial .qmd files\n\n")

results <- data.frame(
  file      = character(),
  folder    = character(),
  title     = character(),
  doi       = character(),
  status    = character(),
  zenodo_id = character(),
  zenodo_title = character(),
  stringsAsFactors = FALSE
)

for (qmd_path in sort(qmd_files)) {

  folder   <- basename(dirname(qmd_path))
  rel_path <- sub(paste0(here(), "/"), "", qmd_path)

  params <- extract_params(qmd_path)

  if (is.null(params)) {
    cat(sprintf("  %-40s  PARSE ERR\n", folder))
    results <- rbind(results, data.frame(
      file = rel_path, folder = folder, title = "",
      doi = "", status = "PARSE ERR",
      zenodo_id = NA, zenodo_title = NA,
      stringsAsFactors = FALSE
    ))
    next
  }

  tutorial_title <- trimws(as.character(params$title %||% folder))
  doi_raw        <- params$doi

  if (is.null(doi_raw)) {
    cat(sprintf("  %-40s  MISSING doi\n", folder))
    results <- rbind(results, data.frame(
      file = rel_path, folder = folder, title = tutorial_title,
      doi = "", status = "MISSING",
      zenodo_id = NA, zenodo_title = NA,
      stringsAsFactors = FALSE
    ))
    next
  }

  doi_str <- trimws(as.character(doi_raw))

  if (nchar(doi_str) == 0) {
    cat(sprintf("  %-40s  EMPTY doi\n", folder))
    results <- rbind(results, data.frame(
      file = rel_path, folder = folder, title = tutorial_title,
      doi = doi_str, status = "EMPTY",
      zenodo_id = NA, zenodo_title = NA,
      stringsAsFactors = FALSE
    ))
    next
  }

  # Check with Zenodo
  check <- check_doi(doi_str)
  status_symbol <- if (check$status == "OK") "✓" else "✗"

  cat(sprintf(
    "  %s  %-40s  %-12s  %s\n",
    status_symbol, folder, check$status, doi_str
  ))

  results <- rbind(results, data.frame(
    file         = rel_path,
    folder       = folder,
    title        = tutorial_title,
    doi          = doi_str,
    status       = check$status,
    zenodo_id    = check$record_id %||% NA,
    zenodo_title = check$title %||% NA,
    stringsAsFactors = FALSE
  ))

  Sys.sleep(SLEEP_BETWEEN_CALLS)
}

# ── Summary ───────────────────────────────────────────────────────────────────

cat("\n============================================================\n")
cat("Summary\n")
cat("============================================================\n")
cat(sprintf("  %-20s  %d\n", "Total scanned:",    nrow(results)))
cat(sprintf("  %-20s  %d\n", "OK:",               sum(results$status == "OK")))
cat(sprintf("  %-20s  %d\n", "NOT FOUND:",        sum(results$status == "NOT FOUND")))
cat(sprintf("  %-20s  %d\n", "MISSING doi:",      sum(results$status == "MISSING")))
cat(sprintf("  %-20s  %d\n", "EMPTY doi:",        sum(results$status == "EMPTY")))
cat(sprintf("  %-20s  %d\n", "MALFORMED doi:",    sum(results$status == "MALFORMED")))
cat(sprintf("  %-20s  %d\n", "NETWORK ERROR:",    sum(results$status == "NETWORK ERROR")))
cat(sprintf("  %-20s  %d\n", "PARSE ERR:",        sum(results$status == "PARSE ERR")))
other_count <- sum(!results$status %in% c("OK","NOT FOUND","MISSING","EMPTY","MALFORMED","NETWORK ERROR","PARSE ERR"))
if (other_count > 0) cat(sprintf("  %-20s  %d\n", "Other HTTP errors:", other_count))
cat("\n")

# ── Problem list ──────────────────────────────────────────────────────────────

problems <- results[results$status != "OK", ]
if (nrow(problems) > 0) {
  cat("============================================================\n")
  cat("Problems requiring attention:\n")
  cat("============================================================\n")
  for (i in seq_len(nrow(problems))) {
    cat(sprintf(
      "\n  Folder:  %s\n  Title:   %s\n  DOI:     %s\n  Status:  %s\n",
      problems$folder[i],
      problems$title[i],
      problems$doi[i],
      problems$status[i]
    ))
  }
} else {
  cat("All DOIs resolved correctly. Nothing to fix!\n")
}

# ── Save results ──────────────────────────────────────────────────────────────

log_path <- here("helpers", "doi_check_results.csv")
write.csv(results, log_path, row.names = FALSE)
cat(sprintf("\nFull results saved to: %s\n", log_path))
cat("\nDone.\n")
