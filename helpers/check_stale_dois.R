# ============================================================
# LADAL — Find tutorials with stale or mismatched DOIs
# ============================================================
# After deleting and recreating Zenodo drafts, some tutorials
# may have an old (deleted) DOI in their params$doi field
# that no longer matches the published record.
#
# This script:
#   1. Reads params$doi from every tutorial .qmd
#   2. Checks each DOI against the Zenodo API
#   3. If the record is NOT FOUND (deleted draft), searches
#      Zenodo for a published record with the same title
#      and reports the correct DOI to use instead
#   4. Reports mismatches so you can update the .qmd files
#
# Run from the root of the ladal repo.
# ============================================================

library(httr)
library(jsonlite)
library(here)

ZENODO_TOKEN <- Sys.getenv("ZENODO_TOKEN")

if (nchar(ZENODO_TOKEN) == 0) {
  stop("No ZENODO_TOKEN found. Set it with Sys.setenv(ZENODO_TOKEN = 'your_token')")
}

`%||%` <- function(a, b) if (!is.null(a) && length(a) > 0) a else b

# ── Step 1: Read all tutorial DOIs ───────────────────────────────────────

all_qmds <- list.files(
  here("tutorials"),
  pattern    = "\\.qmd$",
  recursive  = TRUE,
  full.names = TRUE
)

cat("============================================================\n")
cat("LADAL — Stale DOI Checker\n")
cat("============================================================\n\n")
cat(sprintf("Scanning %d tutorial .qmd files...\n\n", length(all_qmds)))

get_param <- function(f, field) {
  lines    <- readLines(f, warn = FALSE, encoding = "UTF-8")
  pat      <- paste0("^\\s+", field, ":\\s*")
  hit      <- grep(pat, lines, value = TRUE)
  if (length(hit) == 0) return("")
  trimws(gsub(paste0(pat, '["\']?|["\']?\\s*$'), "", hit[1]))
}

tutorials <- data.frame(
  folder     = basename(dirname(all_qmds)),
  file       = sub(paste0(here(), "/"), "", all_qmds),
  title      = sapply(all_qmds, get_param, field = "title"),
  params_doi = sapply(all_qmds, get_param, field = "doi"),
  stringsAsFactors = FALSE
)

# Keep only tutorials that have a DOI
has_doi <- nchar(tutorials$params_doi) > 0
cat(sprintf("Tutorials with a DOI: %d\n", sum(has_doi)))
cat(sprintf("Tutorials without a DOI: %d\n\n", sum(!has_doi)))
tutorials_with_doi <- tutorials[has_doi, ]

# ── Step 2: Check each DOI against Zenodo ────────────────────────────────

check_record <- function(doi, token) {
  record_id <- gsub(".*zenodo\\.", "", trimws(doi))

  # Check deposit API (finds drafts and published)
  r <- tryCatch(
    httr::GET(
      paste0("https://zenodo.org/api/deposit/depositions/", record_id),
      httr::add_headers(Authorization = paste("Bearer", token))
    ),
    error = function(e) NULL
  )

  if (is.null(r)) return(list(status = "ERROR", published = FALSE,
                               zenodo_doi = "", concept_doi = ""))

  code <- httr::status_code(r)

  if (code == 200) {
    ct        <- httr::content(r, as = "parsed")
    published <- isTRUE(ct$submitted)
    zen_doi   <- ct$metadata$prereserve_doi$doi %||% doi
    # Get concept DOI from links if available
    concept   <- ct$conceptdoi %||% ""
    return(list(
      status     = if (published) "PUBLISHED" else "DRAFT",
      published  = published,
      zenodo_doi = zen_doi,
      concept_doi = concept
    ))
  }

  # Try public records API (for published records)
  r2 <- tryCatch(
    httr::GET(
      paste0("https://zenodo.org/api/records/", record_id),
      httr::add_headers(Authorization = paste("Bearer", token))
    ),
    error = function(e) NULL
  )

  if (!is.null(r2) && httr::status_code(r2) == 200) {
    ct2      <- httr::content(r2, as = "parsed")
    zen_doi  <- ct2$doi %||% doi
    concept  <- ct2$conceptdoi %||% ""
    return(list(
      status      = "PUBLISHED",
      published   = TRUE,
      zenodo_doi  = zen_doi,
      concept_doi = concept
    ))
  }

  list(status = "NOT FOUND", published = FALSE,
       zenodo_doi = "", concept_doi = "")
}

search_by_title <- function(title, token) {
  # Search Zenodo for a published record matching this title
  r <- tryCatch(
    httr::GET(
      paste0("https://zenodo.org/api/records?q=",
             utils::URLencode(paste0('title:"', title, '"')),
             "&type=other&size=5"),
      httr::add_headers(Authorization = paste("Bearer", token))
    ),
    error = function(e) NULL
  )

  if (is.null(r) || httr::status_code(r) != 200) return(NULL)

  ct   <- httr::content(r, as = "parsed")
  hits <- ct$hits$hits
  if (length(hits) == 0) return(NULL)

  # Return first hit
  hit <- hits[[1]]
  list(
    doi         = hit$doi %||% "",
    concept_doi = hit$conceptdoi %||% "",
    title       = hit$metadata$title %||% "",
    url         = hit$links$html %||% ""
  )
}

cat("Checking DOIs against Zenodo API...\n\n")

results <- tutorials_with_doi
results$status      <- ""
results$published   <- FALSE
results$zenodo_doi  <- ""
results$concept_doi <- ""
results$suggested_doi <- ""
results$action      <- ""

for (i in seq_len(nrow(results))) {
  doi    <- results$params_doi[i]
  title  <- results$title[i]
  folder <- results$folder[i]

  check <- check_record(doi, ZENODO_TOKEN)
  results$status[i]      <- check$status
  results$published[i]   <- check$published
  results$zenodo_doi[i]  <- check$zenodo_doi
  results$concept_doi[i] <- check$concept_doi

  if (check$status == "NOT FOUND") {
    # Search for the correct published record by title
    Sys.sleep(0.5)
    found <- search_by_title(title, ZENODO_TOKEN)
    if (!is.null(found) && nchar(found$concept_doi) > 0) {
      results$suggested_doi[i] <- found$concept_doi
      results$action[i] <- paste0("UPDATE doi to: ", found$concept_doi)
      cat(sprintf("  ✗ NOT FOUND  %-35s → suggest: %s\n",
                  folder, found$concept_doi))
    } else {
      results$action[i] <- "CREATE new draft — record not found on Zenodo"
      cat(sprintf("  ✗ NOT FOUND  %-35s → no match found on Zenodo\n", folder))
    }
  } else if (check$status == "PUBLISHED") {
    # Check if params$doi matches the concept DOI (preferred)
    concept <- check$concept_doi
    if (nchar(concept) > 0 && tolower(doi) != tolower(concept)) {
      results$suggested_doi[i] <- concept
      results$action[i] <- paste0("UPDATE to concept DOI: ", concept)
      cat(sprintf("  ⚠ USE CONCEPT DOI %-30s → %s\n", folder, concept))
    } else {
      results$action[i] <- "OK"
      cat(sprintf("  ✓ OK         %s\n", folder))
    }
  } else if (check$status == "DRAFT") {
    results$action[i] <- "PUBLISH draft on Zenodo"
    cat(sprintf("  ◷ DRAFT      %s\n", folder))
  } else {
    results$action[i] <- "Check manually"
    cat(sprintf("  ? %s  %s\n", check$status, folder))
  }

  Sys.sleep(0.3)
}

# ── Step 3: Summary ───────────────────────────────────────────────────────

cat("\n============================================================\n")
cat("SUMMARY\n")
cat("============================================================\n\n")

ok          <- results[results$action == "OK", ]
concept_upd <- results[grepl("concept DOI", results$action), ]
not_found   <- results[results$status == "NOT FOUND", ]
drafts      <- results[results$status == "DRAFT", ]

cat(sprintf("✓ Published and DOI correct:    %d\n", nrow(ok)))
cat(sprintf("⚠ Should use concept DOI:       %d\n", nrow(concept_upd)))
cat(sprintf("✗ NOT FOUND (stale/deleted):    %d\n", nrow(not_found)))
cat(sprintf("◷ Unpublished drafts:           %d\n", nrow(drafts)))

if (nrow(concept_upd) > 0) {
  cat("\n── Update to concept DOI ────────────────────────────────\n")
  cat("  Using the concept DOI ensures the link always resolves\n")
  cat("  to the latest version. Update params$doi in each .qmd:\n\n")
  for (i in seq_len(nrow(concept_upd))) {
    cat(sprintf("  Folder:      %s\n", concept_upd$folder[i]))
    cat(sprintf("  Current DOI: %s\n", concept_upd$params_doi[i]))
    cat(sprintf("  Concept DOI: %s\n\n", concept_upd$suggested_doi[i]))
  }
}

if (nrow(not_found) > 0) {
  cat("\n── Stale DOIs (record not found) ────────────────────────\n")
  cat("  These DOIs point to deleted or missing Zenodo records.\n\n")
  for (i in seq_len(nrow(not_found))) {
    cat(sprintf("  Folder:      %s\n", not_found$folder[i]))
    cat(sprintf("  Stale DOI:   %s\n", not_found$params_doi[i]))
    cat(sprintf("  Action:      %s\n\n", not_found$action[i]))
  }
}

if (nrow(drafts) > 0) {
  cat("\n── Unpublished drafts ───────────────────────────────────\n")
  cat("  Go to zenodo.org/me/uploads to publish these.\n\n")
  for (i in seq_len(nrow(drafts))) {
    record_id <- gsub(".*zenodo\\.", "", drafts$params_doi[i])
    cat(sprintf("  %-40s https://zenodo.org/deposit/%s\n",
                drafts$folder[i], record_id))
  }
}

# ── Save report ───────────────────────────────────────────────────────────

report <- results[, c("folder", "title", "params_doi", "zenodo_doi",
                       "concept_doi", "status", "published", "action")]
report_path <- here("helpers", "zenodo_doi_stale_check.csv")
write.csv(report, report_path, row.names = FALSE)
cat(sprintf("\nFull report saved to: %s\n\n", report_path))
