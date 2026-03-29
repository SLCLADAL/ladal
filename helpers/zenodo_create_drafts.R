# ============================================================
# LADAL — Zenodo Draft Record Creator
# ============================================================
# This script scans all tutorial .qmd files in the tutorials/
# folder, extracts metadata from the params block, and creates
# a Zenodo DRAFT record for any tutorial that does not yet
# have a DOI.
#
# After running:
#   1. Log in to zenodo.org and review each draft
#   2. Add the rendered HTML file to each draft
#   3. Publish when ready
#   4. Copy the minted DOI back into the tutorial's params:doi field
#
# REQUIRES:
#   install.packages(c("httr", "jsonlite", "yaml", "here"))
#
# ZENODO API TOKEN:
#   Get one at: zenodo.org → Account → Applications → Personal access tokens
#   Scope required: deposit:write
# ============================================================

library(httr)
library(jsonlite)
library(yaml)
library(here)

# ── Configuration ─────────────────────────────────────────────────────────────

# Paste your Zenodo API token here, or set it as an environment variable:
#   Sys.setenv(ZENODO_TOKEN = "your_token_here")
# Then the line below will pick it up automatically.
ZENODO_TOKEN <- Sys.getenv("ZENODO_TOKEN")

# If you haven't set the environment variable, uncomment and fill in:
# ZENODO_TOKEN <- "paste_your_token_here"

# Use sandbox for testing (recommended first run):
#   sandbox.zenodo.org — records are not public and don't mint real DOIs
# Switch to FALSE when you're ready to create real records:
USE_SANDBOX <- TRUE

ZENODO_BASE <- if (USE_SANDBOX) {
  "https://sandbox.zenodo.org/api"
} else {
  "https://zenodo.org/api"
}

# Path to tutorials folder (relative to repo root)
TUTORIALS_DIR <- here("tutorials")

# Zenodo community ID (your LADAL community)
COMMUNITY_ID <- "ladal"

# Fixed metadata applied to every record — update as needed
FIXED_KEYWORDS <- c(
  "LADAL",
  "language technology",
  "open educational resource",
  "University of Queensland",
  "corpus linguistics",
  "text analysis",
  "R"
)

FIXED_DESCRIPTION_SUFFIX <- paste0(
  "\n\nThis tutorial is part of the Language Technology and Data Analysis ",
  "Laboratory (LADAL), a free, open-access research infrastructure at the ",
  "University of Queensland. LADAL provides tutorials, tools, and courses ",
  "for researchers working with language data. All materials are freely ",
  "available at https://ladal.edu.au and are part of the Language Data ",
  "Commons of Australia (LDaCA), funded by ARDC and NCRIS."
)

# ── Helper functions ──────────────────────────────────────────────────────────

# Extract the params block from a .qmd file
extract_params <- function(qmd_path) {
  lines <- readLines(qmd_path, warn = FALSE)

  # Find YAML front matter boundaries (between --- delimiters)
  yaml_delimiters <- which(trimws(lines) == "---")
  if (length(yaml_delimiters) < 2) {
    message("  ⚠ No valid YAML front matter found in: ", basename(qmd_path))
    return(NULL)
  }

  yaml_block <- lines[(yaml_delimiters[1] + 1):(yaml_delimiters[2] - 1)]
  parsed <- tryCatch(
    yaml::yaml.load(paste(yaml_block, collapse = "\n")),
    error = function(e) {
      message("  ⚠ Failed to parse YAML in: ", basename(qmd_path), " — ", e$message)
      NULL
    }
  )

  if (is.null(parsed)) return(NULL)
  parsed$params
}

# Build the Zenodo metadata payload for one tutorial
build_metadata <- function(params, qmd_path) {

  title       <- params$title       %||% basename(dirname(qmd_path))
  author      <- params$author      %||% "Martin Schweinberger"
  year        <- params$year        %||% format(Sys.Date(), "%Y")
  version     <- params$version     %||% format(Sys.Date(), "%Y.%m.%d")
  url         <- params$url         %||% ""
  institution <- params$institution %||% "The University of Queensland, School of Languages and Cultures"

  # Build description from available fields
  description <- paste0(
    title, ". ",
    "Version ", version, ". ",
    institution, ". ",
    if (nchar(url) > 0) paste0("Available at: ", url, ".") else "",
    FIXED_DESCRIPTION_SUFFIX
  )

  # Parse author name (assumes "Firstname Lastname" format)
  name_parts  <- strsplit(trimws(author), " ")[[1]]
  family_name <- tail(name_parts, 1)
  given_name  <- paste(head(name_parts, -1), collapse = " ")

  # Assemble the Zenodo metadata object
  metadata <- list(
    title       = title,
    upload_type = "publication",
    publication_type = "other",
    description = description,
    creators    = list(
      list(
        name        = paste0(family_name, ", ", given_name),
        affiliation = institution,
        orcid       = "0000-0003-1923-9153"   # update if author varies
      )
    ),
    publication_date = paste0(year, "-01-01"),
    version     = version,
    license     = "cc-by-4.0",
    keywords    = FIXED_KEYWORDS,
    communities = list(list(identifier = COMMUNITY_ID)),
    related_identifiers = Filter(Negate(is.null), list(
      if (nchar(url) > 0) list(
        identifier = url,
        relation   = "isSupplementTo",
        scheme     = "url",
        resource_type = "other"
      ) else NULL,
      list(
        identifier = "https://ladal.edu.au",
        relation   = "isPartOf",
        scheme     = "url",
        resource_type = "other"
      ),
      list(
        identifier = "https://github.com/SLCLADAL/ladal",
        relation   = "isSupplementTo",
        scheme     = "url",
        resource_type = "software"
      ),
      list(
        identifier = "https://www.ldaca.edu.au",
        relation   = "isPartOf",
        scheme     = "url",
        resource_type = "other"
      )
    )),
    grants = list(
      list(id = "10.13039/501100001779::DP200101863")  # ARDC NCRIS grant
    )
  )

  metadata
}

# Null-coalescing operator
`%||%` <- function(a, b) if (!is.null(a) && nchar(as.character(a)) > 0) a else b

# Create a Zenodo draft record via the API
create_zenodo_draft <- function(metadata, token, base_url) {
  response <- httr::POST(
    url   = paste0(base_url, "/deposit/depositions"),
    httr::add_headers(
      Authorization  = paste("Bearer", token),
      `Content-Type` = "application/json"
    ),
    body   = jsonlite::toJSON(list(metadata = metadata), auto_unbox = TRUE),
    encode = "raw"
  )

  status <- httr::status_code(response)
  content <- httr::content(response, as = "parsed")

  if (status == 201) {
    list(
      success    = TRUE,
      deposit_id = content$id,
      doi        = content$metadata$prereserve_doi$doi,
      edit_url   = content$links$html
    )
  } else {
    list(
      success = FALSE,
      status  = status,
      message = content$message %||% "Unknown error"
    )
  }
}

# ── Main script ───────────────────────────────────────────────────────────────

cat("============================================================\n")
cat("LADAL Zenodo Draft Creator\n")
cat("Mode:", if (USE_SANDBOX) "SANDBOX (test run)" else "LIVE", "\n")
cat("============================================================\n\n")

# Validate token
if (nchar(ZENODO_TOKEN) == 0) {
  stop(
    "No Zenodo API token found.\n",
    "Set it with: Sys.setenv(ZENODO_TOKEN = 'your_token_here')\n",
    "Or paste it directly into the ZENODO_TOKEN variable at the top of this script."
  )
}

# Find all .qmd files in tutorials/ subfolders
qmd_files <- list.files(
  path       = TUTORIALS_DIR,
  pattern    = "\\.qmd$",
  recursive  = TRUE,
  full.names = TRUE
)

cat("Found", length(qmd_files), "tutorial .qmd files\n\n")

# Results log
results <- data.frame(
  file       = character(),
  title      = character(),
  status     = character(),
  doi        = character(),
  edit_url   = character(),
  stringsAsFactors = FALSE
)

# Process each tutorial
for (qmd_path in qmd_files) {

  rel_path <- gsub(paste0(here(), "/"), "", qmd_path)
  cat("Processing:", rel_path, "\n")

  # Extract params
  params <- extract_params(qmd_path)

  if (is.null(params)) {
    cat("  → Skipped (could not parse params)\n\n")
    results <- rbind(results, data.frame(
      file = rel_path, title = "", status = "SKIPPED — parse error",
      doi = "", edit_url = "", stringsAsFactors = FALSE
    ))
    next
  }

  # Skip if DOI already exists
  existing_doi <- trimws(as.character(params$doi %||% ""))
  if (nchar(existing_doi) > 0) {
    cat("  → Skipped (DOI already present:", existing_doi, ")\n\n")
    results <- rbind(results, data.frame(
      file = rel_path, title = params$title %||% "",
      status = "SKIPPED — DOI exists", doi = existing_doi,
      edit_url = "", stringsAsFactors = FALSE
    ))
    next
  }

  # Build metadata
  metadata <- build_metadata(params, qmd_path)
  cat("  Title:", metadata$title, "\n")

  # Create draft on Zenodo
  result <- create_zenodo_draft(metadata, ZENODO_TOKEN, ZENODO_BASE)

  if (result$success) {
    cat("  ✓ Draft created\n")
    cat("  Reserved DOI:", result$doi, "\n")
    cat("  Edit at:", result$edit_url, "\n\n")
    results <- rbind(results, data.frame(
      file = rel_path, title = metadata$title,
      status = "DRAFT CREATED", doi = result$doi,
      edit_url = result$edit_url, stringsAsFactors = FALSE
    ))
  } else {
    cat("  ✗ Failed (HTTP", result$status, "):", result$message, "\n\n")
    results <- rbind(results, data.frame(
      file = rel_path, title = metadata$title,
      status = paste0("FAILED — HTTP ", result$status),
      doi = "", edit_url = "", stringsAsFactors = FALSE
    ))
  }

  # Brief pause to avoid hitting API rate limits
  Sys.sleep(1)
}

# ── Summary ───────────────────────────────────────────────────────────────────

cat("============================================================\n")
cat("Summary\n")
cat("============================================================\n")
cat("Total files scanned:  ", nrow(results), "\n")
cat("Drafts created:       ", sum(results$status == "DRAFT CREATED"), "\n")
cat("Already had DOI:      ", sum(grepl("DOI exists", results$status)), "\n")
cat("Skipped (parse error):", sum(grepl("parse error", results$status)), "\n")
cat("Failed:               ", sum(grepl("FAILED", results$status)), "\n\n")

# Save results log
log_path <- here("helpers", "zenodo_draft_log.csv")
write.csv(results, log_path, row.names = FALSE)
cat("Full results saved to:", log_path, "\n\n")

# Print the DOI table for easy copy-pasting back into .qmd files
new_dois <- results[results$status == "DRAFT CREATED", c("file", "title", "doi", "edit_url")]
if (nrow(new_dois) > 0) {
  cat("============================================================\n")
  cat("Reserved DOIs — copy these into your .qmd params blocks:\n")
  cat("============================================================\n")
  for (i in seq_len(nrow(new_dois))) {
    cat("\nFile:  ", new_dois$file[i], "\n")
    cat("Title: ", new_dois$title[i], "\n")
    cat("DOI:   ", new_dois$doi[i], "\n")
    cat("Edit:  ", new_dois$edit_url[i], "\n")
  }
}

cat("\nDone! Review and complete your drafts at:\n")
cat(if (USE_SANDBOX) "https://sandbox.zenodo.org/me/uploads\n" else "https://zenodo.org/me/uploads\n")
