# ============================================================
# LADAL — Zenodo DOI Consistency Checker
# ============================================================
# Compares the DOI in each tutorial's params$doi field against
# what Zenodo actually has on record for that deposit.
#
# Reports:
#   - MATCH:     params$doi matches the Zenodo reserved DOI
#   - MISMATCH:  params$doi differs from the Zenodo reserved DOI
#   - NOT FOUND: params$doi is not found on Zenodo (deleted draft?)
#   - EMPTY:     tutorial has no DOI in params — needs draft created
#
# Run from the root of the ladal repo.
# ============================================================

library(httr)
library(here)

ZENODO_TOKEN <- Sys.getenv("ZENODO_TOKEN")

if (nchar(ZENODO_TOKEN) == 0) {
  stop("No ZENODO_TOKEN found. Set it with Sys.setenv(ZENODO_TOKEN = 'your_token')")
}

# ── Step 1: Read all tutorial DOIs from params blocks ─────────────────────

cat("============================================================\n")
cat("LADAL Zenodo DOI Consistency Checker\n")
cat("============================================================\n\n")

all_qmds <- list.files(
  here("tutorials"),
  pattern    = "\\.qmd$",
  recursive  = TRUE,
  full.names = TRUE
)

cat(sprintf("Scanning %d tutorial .qmd files...\n\n", length(all_qmds)))

get_doi <- function(f) {
  lines    <- readLines(f, warn = FALSE, encoding = "UTF-8")
  doi_line <- grep("^\\s+doi:\\s*", lines, value = TRUE)
  if (length(doi_line) == 0) return("")
  trimws(gsub('^\\s+doi:\\s*["\']?|["\']?\\s*$', "", doi_line[1]))
}

get_title <- function(f) {
  lines      <- readLines(f, warn = FALSE, encoding = "UTF-8")
  title_line <- grep("^\\s+title:\\s*", lines, value = TRUE)
  if (length(title_line) == 0) return(basename(dirname(f)))
  trimws(gsub('^\\s+title:\\s*["\']?|["\']?\\s*$', "", title_line[1]))
}

tutorials <- data.frame(
  folder    = basename(dirname(all_qmds)),
  file      = sub(paste0(here(), "/"), "", all_qmds),
  title     = sapply(all_qmds, get_title),
  params_doi = sapply(all_qmds, get_doi),
  stringsAsFactors = FALSE
)

# ── Step 2: Check each non-empty DOI against Zenodo API ──────────────────

check_doi <- function(doi, token) {
  if (nchar(doi) == 0) return(list(status = "EMPTY", zenodo_doi = ""))

  # Extract record ID from DOI string
  record_id <- gsub(".*zenodo\\.", "", trimws(doi))

  # Try the deposit API (works for both drafts and published)
  resp <- tryCatch(
    httr::GET(
      paste0("https://zenodo.org/api/deposit/depositions/", record_id),
      httr::add_headers(Authorization = paste("Bearer", token))
    ),
    error = function(e) NULL
  )

  if (is.null(resp)) return(list(status = "ERROR", zenodo_doi = ""))

  code <- httr::status_code(resp)

  if (code == 200) {
    content    <- httr::content(resp, as = "parsed")
    zenodo_doi <- content$metadata$prereserve_doi$doi %||% ""
    published  <- isTRUE(content$submitted)
    status <- if (nchar(zenodo_doi) == 0) {
      "FOUND (no reserved DOI)"
    } else if (tolower(trimws(doi)) == tolower(trimws(zenodo_doi))) {
      if (published) "MATCH (published)" else "MATCH (draft)"
    } else {
      "MISMATCH"
    }
    return(list(status = status, zenodo_doi = zenodo_doi,
                published = published))
  } else if (code == 404) {
    return(list(status = "NOT FOUND ON ZENODO", zenodo_doi = ""))
  } else {
    return(list(status = paste0("HTTP ", code), zenodo_doi = ""))
  }
}

`%||%` <- function(a, b) if (!is.null(a) && length(a) > 0) a else b

cat("Checking DOIs against Zenodo API...\n")
cat("(This may take a minute — one API call per tutorial)\n\n")

results <- tutorials
results$zenodo_doi <- ""
results$check      <- ""
results$published  <- FALSE

for (i in seq_len(nrow(results))) {
  doi    <- results$params_doi[i]
  folder <- results$folder[i]

  if (nchar(doi) == 0) {
    results$check[i] <- "EMPTY"
    cat(sprintf("  %-45s EMPTY\n", folder))
    next
  }

  check <- check_doi(doi, ZENODO_TOKEN)
  results$check[i]     <- check$status
  results$zenodo_doi[i] <- check$zenodo_doi %||% ""
  results$published[i]  <- isTRUE(check$published)

  cat(sprintf("  %-45s %s\n", folder, check$status))
  Sys.sleep(0.3)  # be polite to the API
}

# ── Step 3: Report ────────────────────────────────────────────────────────

cat("\n============================================================\n")
cat("RESULTS\n")
cat("============================================================\n\n")

# Published and matching
published <- results[results$check == "MATCH (published)", ]
cat(sprintf("✓ PUBLISHED and matching DOI:  %d\n", nrow(published)))

# Draft and matching  
drafts <- results[results$check == "MATCH (draft)", ]
cat(sprintf("◷ DRAFT (not yet published):   %d\n", nrow(drafts)))

# Mismatches
mismatches <- results[results$check == "MISMATCH", ]
cat(sprintf("✗ MISMATCH (doi field wrong):  %d\n", nrow(mismatches)))

# Not found
not_found <- results[results$check == "NOT FOUND ON ZENODO", ]
cat(sprintf("✗ NOT FOUND on Zenodo:         %d\n", nrow(not_found)))

# Empty
empty <- results[results$check == "EMPTY", ]
cat(sprintf("○ NO DOI (needs draft):        %d\n", nrow(empty)))

# ── Detailed sections ─────────────────────────────────────────────────────

if (nrow(drafts) > 0) {
  cat("\n── Drafts to publish ────────────────────────────────────\n")
  cat("  These have matching DOIs but are not yet published.\n")
  cat("  Upload the HTML and publish at zenodo.org/me/uploads\n\n")
  for (i in seq_len(nrow(drafts))) {
    cat(sprintf("  %-40s %s\n", drafts$folder[i], drafts$params_doi[i]))
    cat(sprintf("  %-40s https://zenodo.org/records/%s\n\n",
        "",
        gsub(".*zenodo\\.", "", drafts$params_doi[i])))
  }
}

if (nrow(mismatches) > 0) {
  cat("\n── DOI mismatches ───────────────────────────────────────\n")
  cat("  params$doi differs from Zenodo reserved DOI.\n")
  cat("  Update the params$doi field in the .qmd file.\n\n")
  for (i in seq_len(nrow(mismatches))) {
    cat(sprintf("  Folder:      %s\n", mismatches$folder[i]))
    cat(sprintf("  params$doi:  %s\n", mismatches$params_doi[i]))
    cat(sprintf("  Zenodo DOI:  %s\n\n", mismatches$zenodo_doi[i]))
  }
}

if (nrow(not_found) > 0) {
  cat("\n── Not found on Zenodo ──────────────────────────────────\n")
  cat("  These DOIs exist in params but the Zenodo record was\n")
  cat("  deleted or never created. Clear the doi field and\n")
  cat("  re-run zenodo_create_drafts.R for these tutorials.\n\n")
  for (i in seq_len(nrow(not_found))) {
    cat(sprintf("  %-40s %s\n", not_found$folder[i],
                not_found$params_doi[i]))
  }
}

if (nrow(empty) > 0) {
  cat("\n── No DOI yet ───────────────────────────────────────────\n")
  cat("  Run zenodo_create_drafts.R with TARGET_TUTORIAL to\n")
  cat("  create drafts for these tutorials.\n\n")
  for (i in seq_len(nrow(empty))) {
    cat(sprintf("  %s\n", empty$folder[i]))
  }
}

# ── Save report ───────────────────────────────────────────────────────────

report_path <- here("helpers", "zenodo_doi_check.csv")
write.csv(results[, c("folder", "title", "params_doi",
                       "zenodo_doi", "check", "published")],
          report_path, row.names = FALSE)
cat(sprintf("\nFull report saved to: %s\n\n", report_path))
