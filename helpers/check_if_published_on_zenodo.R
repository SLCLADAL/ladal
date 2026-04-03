library(here)
library(httr)

ZENODO_TOKEN <- Sys.getenv("ZENODO_TOKEN")

# ── Get all DOIs from tutorial front matter ───────────────────────────────

all_qmds <- list.files(here("tutorials"), pattern = "\\.qmd$",
                       recursive = TRUE, full.names = TRUE)

get_doi <- function(f) {
  lines    <- readLines(f, warn = FALSE, encoding = "UTF-8")
  doi_line <- grep("^\\s+doi:\\s*", lines, value = TRUE)
  if (length(doi_line) == 0) return(NA)
  trimws(gsub('^\\s+doi:\\s*["\']?|["\']?\\s*$', "", doi_line[1]))
}

tutorials <- data.frame(
  folder = basename(dirname(all_qmds)),
  file   = sub(paste0(here(), "/"), "", all_qmds),
  doi    = sapply(all_qmds, get_doi),
  stringsAsFactors = FALSE
)

# Keep only tutorials with a non-empty DOI
tutorials <- tutorials[!is.na(tutorials$doi) & nchar(tutorials$doi) > 0, ]
cat(sprintf("Tutorials with a reserved DOI: %d\n\n", nrow(tutorials)))

# ── Check each DOI against Zenodo API ────────────────────────────────────

check_zenodo_status <- function(doi, token) {
  # Extract the Zenodo record ID from the DOI
  # DOI format: 10.5281/zenodo.XXXXXXX
  record_id <- gsub(".*zenodo\\.", "", doi)
  if (nchar(record_id) == 0) return("INVALID DOI")
  
  resp <- tryCatch(
    httr::GET(
      paste0("https://zenodo.org/api/records/", record_id),
      httr::add_headers(Authorization = paste("Bearer", token))
    ),
    error = function(e) NULL
  )
  
  if (is.null(resp)) return("ERROR")
  
  status <- httr::status_code(resp)
  
  if (status == 200) {
    # Record is publicly accessible = published
    return("PUBLISHED")
  } else if (status == 404) {
    # Not found publicly — check deposits (drafts)
    resp2 <- tryCatch(
      httr::GET(
        paste0("https://zenodo.org/api/deposit/depositions/", record_id),
        httr::add_headers(Authorization = paste("Bearer", token))
      ),
      error = function(e) NULL
    )
    if (!is.null(resp2) && httr::status_code(resp2) == 200) {
      content <- httr::content(resp2, as = "parsed")
      if (isTRUE(content$submitted)) return("PUBLISHED")
      return("DRAFT (not published)")
    }
    return("NOT FOUND")
  } else {
    return(paste0("HTTP ", status))
  }
}

cat("Checking Zenodo status for each DOI...\n\n")

tutorials$status <- sapply(seq_len(nrow(tutorials)), function(i) {
  status <- check_zenodo_status(tutorials$doi[i], ZENODO_TOKEN)
  cat(sprintf("  %-45s %s\n", tutorials$folder[i], status))
  Sys.sleep(0.3)  # be polite to the API
  status
})

# ── Summary ───────────────────────────────────────────────────────────────

cat("\n============================================================\n")
cat(sprintf("PUBLISHED:         %d\n", sum(tutorials$status == "PUBLISHED")))
cat(sprintf("DRAFT (unpublished): %d\n", sum(grepl("DRAFT", tutorials$status))))
cat(sprintf("NOT FOUND / ERROR: %d\n",
            sum(!tutorials$status %in% c("PUBLISHED") & !grepl("DRAFT", tutorials$status))))
cat("============================================================\n\n")

cat("── Drafts still needing publication ─────────────────────\n")
drafts <- tutorials[grepl("DRAFT", tutorials$status), ]
for (i in seq_len(nrow(drafts))) {
  cat(sprintf("  %-45s %s\n", drafts$folder[i], drafts$doi[i]))
}

# Save full log
write.csv(tutorials, here("helpers", "zenodo_publication_status.csv"),
          row.names = FALSE)
cat("\nFull log saved to helpers/zenodo_publication_status.csv\n")