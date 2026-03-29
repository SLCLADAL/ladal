# ============================================================
# LADAL — Zenodo Community Request Acceptor
# ============================================================
# After publishing Zenodo records that were submitted to the
# LADAL community, this script automatically accepts all
# pending community inclusion requests on your behalf.
#
# Run this AFTER you have published your draft records.
#
# REQUIRES:
#   install.packages(c("httr", "jsonlite"))
#
# ZENODO API TOKEN:
#   Must have scope: community:admin
#   Set via: Sys.setenv(ZENODO_TOKEN = "your_token_here")
#   Or add to ~/.Renviron: ZENODO_TOKEN=your_token_here
# ============================================================

library(httr)
library(jsonlite)

# ── Configuration ─────────────────────────────────────────────────────────────

ZENODO_TOKEN <- Sys.getenv("ZENODO_TOKEN")
# ZENODO_TOKEN <- "paste_your_token_here"  # fallback — never commit this

# Match sandbox setting to zenodo_create_drafts.R
USE_SANDBOX  <- FALSE   # set TRUE if testing on sandbox.zenodo.org

ZENODO_BASE  <- if (USE_SANDBOX) {
  "https://sandbox.zenodo.org/api"
} else {
  "https://zenodo.org/api"
}

# Your Zenodo community slug — exactly as it appears in the URL
# e.g. zenodo.org/communities/ladal → "ladal"
COMMUNITY_ID <- "ladal"

# ── Helper: make authenticated GET request ────────────────────────────────────

zen_get <- function(url, token, query = list()) {
  httr::GET(
    url,
    httr::add_headers(Authorization = paste("Bearer", token)),
    query = query
  )
}

# ── Helper: make authenticated POST request ───────────────────────────────────

zen_post <- function(url, token, body = list()) {
  httr::POST(
    url,
    httr::add_headers(
      Authorization  = paste("Bearer", token),
      `Content-Type` = "application/json"
    ),
    body   = jsonlite::toJSON(body, auto_unbox = TRUE),
    encode = "raw"
  )
}

# ── Main script ───────────────────────────────────────────────────────────────

cat("============================================================\n")
cat("LADAL Zenodo Community Request Acceptor\n")
cat("Community:", COMMUNITY_ID, "\n")
cat("Mode:", if (USE_SANDBOX) "SANDBOX" else "LIVE", "\n")
cat("============================================================\n\n")

# Validate token
if (nchar(ZENODO_TOKEN) == 0) {
  stop(
    "No Zenodo API token found.\n",
    "Set it with: Sys.setenv(ZENODO_TOKEN = 'your_token_here')\n",
    "Or add ZENODO_TOKEN=your_token to ~/.Renviron and restart R."
  )
}

# ── Step 1: Fetch pending community requests ──────────────────────────────────

cat("Fetching pending requests for community:", COMMUNITY_ID, "...\n")

requests_url <- paste0(ZENODO_BASE, "/communities/", COMMUNITY_ID, "/requests")

response <- zen_get(requests_url, ZENODO_TOKEN, query = list(
  status = "pending",
  size   = 100          # fetch up to 100 pending requests at once
))

status <- httr::status_code(response)

if (status != 200) {
  content <- httr::content(response, as = "parsed")
  stop(
    "Failed to fetch community requests (HTTP ", status, ").\n",
    "Message: ", content$message %||% "Unknown error", "\n",
    "Check that your token has the 'community:admin' scope and that ",
    "the community ID '", COMMUNITY_ID, "' is correct."
  )
}

content  <- httr::content(response, as = "parsed")
requests <- content$hits$hits

if (length(requests) == 0) {
  cat("No pending requests found for community:", COMMUNITY_ID, "\n")
  cat("Either all requests have already been accepted, or no new\n")
  cat("records have been submitted to this community yet.\n")
  quit(save = "no")
}

cat("Found", length(requests), "pending request(s)\n\n")

# ── Step 2: Accept each pending request ──────────────────────────────────────

accepted <- 0
failed   <- 0

for (req in requests) {

  req_id    <- req$id
  rec_title <- req$topic$record$metadata$title %||% "(unknown title)"
  rec_doi   <- req$topic$record$doi            %||% "(no DOI)"

  cat("Processing request:", req_id, "\n")
  cat("  Title:", rec_title, "\n")
  cat("  DOI:  ", rec_doi, "\n")

  # Accept the request via the API
  accept_url <- paste0(requests_url, "/", req_id, "/actions/accept")

  accept_response <- zen_post(
    accept_url,
    ZENODO_TOKEN,
    body = list(payload = list(content = "Accepted via LADAL automation script"))
  )

  accept_status <- httr::status_code(accept_response)

  if (accept_status %in% c(200, 201, 204)) {
    cat("  ✓ Accepted\n\n")
    accepted <- accepted + 1
  } else {
    accept_content <- httr::content(accept_response, as = "parsed")
    cat("  ✗ Failed (HTTP", accept_status, "):",
        accept_content$message %||% "Unknown error", "\n\n")
    failed <- failed + 1
  }

  Sys.sleep(0.5)   # brief pause to avoid rate limiting
}

# ── Summary ───────────────────────────────────────────────────────────────────

cat("============================================================\n")
cat("Summary\n")
cat("============================================================\n")
cat("Requests found:    ", length(requests), "\n")
cat("Successfully accepted:", accepted, "\n")
cat("Failed:            ", failed, "\n\n")

if (accepted > 0) {
  cat("Accepted records should now appear in your LADAL community at:\n")
  cat(if (USE_SANDBOX)
    paste0("https://sandbox.zenodo.org/communities/", COMMUNITY_ID, "\n")
  else
    paste0("https://zenodo.org/communities/", COMMUNITY_ID, "\n"))
}

if (failed > 0) {
  cat("\nFor failed requests, accept them manually at:\n")
  cat(if (USE_SANDBOX)
    paste0("https://sandbox.zenodo.org/communities/", COMMUNITY_ID, "/requests\n")
  else
    paste0("https://zenodo.org/communities/", COMMUNITY_ID, "/requests\n"))
}

# Null-coalescing operator (in case not loaded from other script)
`%||%` <- function(a, b) if (!is.null(a) && nchar(as.character(a)) > 0) a else b
