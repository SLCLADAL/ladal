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
USE_SANDBOX <- FALSE

ZENODO_BASE <- if (USE_SANDBOX) {
  "https://sandbox.zenodo.org/api"
} else {
  "https://zenodo.org/api"
}

# Path to tutorials folder (relative to repo root)
TUTORIALS_DIR <- here("tutorials")

# Zenodo community ID (your LADAL community)
COMMUNITY_ID <- "ladal"

# Maximum number of NEW draft records to create in this run.
# Tutorials that already have a DOI do not count toward this limit.
# Set to Inf to process all tutorials with no DOI in one run.
# Recommended: start with 5 to test the full workflow before running at scale.
LIMIT <- 20

# Target a single specific tutorial by folder name.
# When set, ONLY that tutorial is processed regardless of LIMIT.
# The tutorial's doi: field must be empty for a draft to be created.
# Set to "" to process all tutorials up to LIMIT as normal.
#
# Example — create a draft for cluster_analysis only:
#   TARGET_TUTORIAL <- "cluster_analysis"
#
# Example — batch mode (process up to LIMIT tutorials):
#   TARGET_TUTORIAL <- ""
TARGET_TUTORIAL <- "readability"

# Mapping of old slcladal.github.io slugs for tutorials that were RENAMED.
# For tutorials whose folder name matches the old slug, the old URL is derived
# automatically. Only add entries here for tutorials where the name changed.
#
# This list has TWO layers of renaming:
#   Layer 1 — original slcladal.github.io slug -> intermediate LADAL name
#   Layer 2 — intermediate LADAL name -> new coherent name (post-2026 rename)
#
# The script derives old_url from the FINAL new folder name, so all entries
# here map new_folder_name -> original slcladal.github.io slug.
#
# Format: "new_folder_name" = "old_slcladal_slug"
RENAMED_TUTORIALS <- list(
  # ── Originally renamed on migration from slcladal.github.io ──────────────
  "vowelchart"                  = "vc",
  "collocations"                = "coll",       # was collocation_tutorial
  "semantic_vectors"            = "svm",        # was semanticvectors_tutorial
  "working_with_computers"      = "comp",       # was workingwithcomputers_tutorial
  "descriptive_stats"           = "dstats",     # was descriptivestats_tutorial
  "corpus_linguistics"          = "corplingr",  # was corpuslinguistics_showcase

  # ── Post-2026 coherence renames (old intermediate -> slcladal slug) ───────
  # These tutorials had no slcladal predecessor; the old ladal.edu.au URL
  # (intermediate name) is used as the isNewVersionOf identifier instead.
  # Format: "new_folder_name" = "intermediate_ladal_slug"
  "learner_language"            = "llr",
  "lexicography"                = "lex",
  "keywords"                    = "key",
  "network_analysis"            = "net",
  "structural_equations"        = "sem",
  "tree_models"                 = "tree",
  "cluster_analysis"            = "clust",
  "reproducibility"             = "repro",
  "data_loading"                = "load",
  "regular_expressions"         = "regex",
  "data_simulation"             = "simulate",
  "data_viz_advanced"           = "dviz",
  "interactive_viz"             = "motion",
  "power_analysis"              = "power",
  "why_r"                       = "whyr",
  "corpus_compilation"          = "corpuscompilation_tutorial",
  "concordancing"               = "concordancing_tutorial",
  "dimension_reduction"         = "dimensionredux_tutorial",
  "conceptual_maps_comparison"  = "conceptualmaps_showcase",
  "phylogenetic_methods"        = "phylogenetic_showcase",
  "llm_privacy"                 = "localllm_showcase",
  "topic_modelling_dickens"     = "topicmodel_showcase",
  "quant_intro"                 = "introquant",
  "quant_basics"                = "basicquant",
  "r_intro"                     = "intror",
  "viz_intro"                   = "introviz",
  "text_analysis_intro"         = "introta",
  "inferential_stats"           = "basicstatz",
  "pdf_to_text"                 = "pdf2txt",
  "text_summarisation"          = "txtsum",
  "pos_tagging"                 = "postag",
  "bert_roberta"                = "rbert",
  "reinforcement_nlp"           = "reinfnlp",
  "lexical_similarity"          = "lexsim",
  "deep_learning"               = "deeplearning_tutorial"
)

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

  # date_published: use params$date_published (YYYY-MM-DD) when available,
  # otherwise fall back to year + "-01-01"
  date_published_raw <- trimws(as.character(params$date_published %||% ""))
  publication_date <- if (
    nchar(date_published_raw) >= 10 &&
    grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}", date_published_raw)
  ) {
    substr(date_published_raw, 1, 10)
  } else {
    paste0(year, "-01-01")
  }

  # Auto-correct URL from folder name if params$url looks stale
  # (i.e. the folder name in the URL doesn't match the actual folder name)
  folder_name_check <- basename(dirname(qmd_path))
  url_folder        <- basename(dirname(gsub(".html$", "", url)))
  if (nchar(url) > 0 && url_folder != folder_name_check) {
    url <- paste0(
      "https://ladal.edu.au/tutorials/",
      folder_name_check, "/", folder_name_check, ".html"
    )
    message("  ℹ URL auto-corrected to: ", url)
  }

  # Derive the predecessor URL for this tutorial.
  # If the folder name is in RENAMED_TUTORIALS, the value is used as the
  # old slug. For post-2026 renames the value is the intermediate ladal.edu.au
  # slug, so we check whether it looks like a slcladal.github.io slug (no
  # underscores, short) or a ladal.edu.au slug and build the URL accordingly.
  folder_name <- basename(dirname(qmd_path))
  old_slug    <- RENAMED_TUTORIALS[[folder_name]] %||% folder_name

  # Determine whether old_slug is a slcladal.github.io slug or a ladal.edu.au
  # intermediate folder name. Intermediate names contain underscores or are
  # longer than typical slcladal slugs (>12 chars with underscore).
  is_ladal_intermediate <- grepl("_", old_slug) && nchar(old_slug) > 5
  old_url <- if (is_ladal_intermediate) {
    paste0("https://ladal.edu.au/tutorials/", old_slug, "/", old_slug, ".html")
  } else {
    paste0("https://slcladal.github.io/", old_slug, ".html")
  }

  # Build keywords — merge tutorial-specific keywords with fixed LADAL keywords
  # params$keywords should be a comma-separated string e.g.
  # "corpus linguistics, KWIC, concordancing, text analysis"
  custom_kw_string <- trimws(as.character(params$keywords %||% ""))
  custom_keywords  <- if (nchar(custom_kw_string) > 0) {
    # Split on commas, trim whitespace from each keyword, remove empty strings
    kw <- trimws(strsplit(custom_kw_string, ",")[[1]])
    kw[nchar(kw) > 0]
  } else {
    character(0)
  }
  # Combine tutorial-specific keywords with fixed LADAL keywords
  # Tutorial-specific keywords come first, fixed ones appended
  # Duplicates removed (case-insensitive)
  all_keywords <- c(custom_keywords, FIXED_KEYWORDS)
  all_keywords <- all_keywords[!duplicated(tolower(all_keywords))]

  # Build description — use params$description if present, otherwise auto-generate
  custom_desc <- trimws(as.character(params$description %||% ""))
  description <- if (nchar(custom_desc) > 0) {
    # Use the author-supplied description, append the standard LADAL suffix
    paste0(custom_desc, FIXED_DESCRIPTION_SUFFIX)
  } else {
    # Fall back to auto-generated description from title/version/url
    paste0(
      title, ". ",
      "Version ", version, ". ",
      institution, ". ",
      if (nchar(url) > 0) paste0("Available at: ", url, ".") else "",
      FIXED_DESCRIPTION_SUFFIX
    )
  }

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
    publication_date = publication_date,
    version     = version,
    license     = "cc-by-4.0",
    keywords    = as.list(all_keywords),
    communities = list(list(identifier = COMMUNITY_ID)),
    related_identifiers = Filter(Negate(is.null), list(
      # Current tutorial page on ladal.edu.au
      if (nchar(url) > 0) list(
        identifier    = url,
        relation      = "isSupplementTo",
        scheme        = "url",
        resource_type = "other"
      ) else NULL,
      # Predecessor on slcladal.github.io (isNewVersionOf)
      if (nchar(old_url) > 0) list(
        identifier    = old_url,
        relation      = "isNewVersionOf",
        scheme        = "url",
        resource_type = "other"
      ) else NULL,
      list(
        identifier    = "https://ladal.edu.au",
        relation      = "isPartOf",
        scheme        = "url",
        resource_type = "other"
      ),
      list(
        identifier    = "https://github.com/SLCLADAL/ladal",
        relation      = "isSupplementTo",
        scheme        = "url",
        resource_type = "software"
      ),
      list(
        identifier    = "https://www.ldaca.edu.au",
        relation      = "isPartOf",
        scheme        = "url",
        resource_type = "other"
      )
    )),
    access_right = "open"
    # Note: grants field removed — Zenodo requires a specific internal grant ID
    # format. Add funding information manually in the Zenodo UI if needed.
  )

  metadata
}

# Null-coalescing operator
`%||%` <- function(a, b) if (!is.null(a) && nchar(as.character(a)) > 0) a else b

# Create a Zenodo draft record via the API
create_zenodo_draft <- function(metadata, token, base_url) {

  # Remove communities from metadata — we submit to community separately
  # after creation using a dedicated API call (Zenodo API v2 requirement)
  metadata_no_community        <- metadata
  metadata_no_community$communities <- NULL

  # Serialize metadata to JSON manually
  body_json <- jsonlite::toJSON(
    list(metadata = metadata_no_community),
    auto_unbox = TRUE
  )

  response <- httr::POST(
    url    = paste0(base_url, "/deposit/depositions"),
    config = httr::add_headers(
      "Authorization"  = paste("Bearer", token),
      "Content-Type"   = "application/json",
      "Accept"         = "application/json",
      "X-CSRFToken"    = ""
    ),
    body   = body_json,
    encode = "raw"
  )

  status  <- httr::status_code(response)
  content <- tryCatch(
    httr::content(response, as = "parsed", type = "application/json"),
    error = function(e) list(message = "Could not parse response")
  )

  if (status != 201) {
    message("  Full API response: ",
            jsonlite::toJSON(content, auto_unbox = TRUE, pretty = TRUE))
    return(list(
      success = FALSE,
      status  = status,
      message = content$message %||% content$errors[[1]]$message %||% "Unknown error"
    ))
  }

  deposit_id <- content$id
  doi        <- content$metadata$prereserve_doi$doi
  edit_url   <- content$links$html

  # Submit to LADAL community via separate API call
  # This is required for Zenodo API v2 — communities cannot be set at creation
  community_submitted <- FALSE
  community_id        <- metadata$communities[[1]]$identifier

  if (!is.null(community_id) && nchar(community_id) > 0) {
    comm_body <- jsonlite::toJSON(
      list(communities = list(list(identifier = community_id))),
      auto_unbox = TRUE
    )
    comm_response <- httr::POST(
      url    = paste0(base_url, "/deposit/depositions/", deposit_id, "/actions/community"),
      config = httr::add_headers(
        "Authorization" = paste("Bearer", token),
        "Content-Type"  = "application/json",
        "Accept"        = "application/json"
      ),
      body   = comm_body,
      encode = "raw"
    )
    comm_status <- httr::status_code(comm_response)

    if (comm_status %in% c(200, 201, 204)) {
      community_submitted <- TRUE
      cat("  ✓ Submitted to community:", community_id, "\n")
    } else {
      comm_content <- tryCatch(
        httr::content(comm_response, as = "parsed", type = "application/json"),
        error = function(e) list(message = "Could not parse response")
      )
      cat("  ⚠ Community submission failed (HTTP", comm_status, ")\n")
      cat("    You can add it manually via the Zenodo record page.\n")
    }
  }

  list(
    success             = TRUE,
    deposit_id          = deposit_id,
    doi                 = doi,
    edit_url            = edit_url,
    community_submitted = community_submitted
  )
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
    "Or add ZENODO_TOKEN=your_token to ~/.Renviron and restart R."
  )
}

# Show first 6 characters of token as confirmation (safe — does not expose full token)
cat("Token loaded — first 6 characters:", substr(ZENODO_TOKEN, 1, 6), "...\n")
cat("Token length:", nchar(ZENODO_TOKEN), "characters\n\n")

# Find all .qmd files in tutorials/ subfolders
qmd_files <- list.files(
  path       = TUTORIALS_DIR,
  pattern    = "\\.qmd$",
  recursive  = TRUE,
  full.names = TRUE
)

cat("Found", length(qmd_files), "tutorial .qmd files\n")
cat("Limit: will create at most", LIMIT, "new draft(s) this run\n\n")

# If TARGET_TUTORIAL is set, filter to only that tutorial
if (nchar(trimws(TARGET_TUTORIAL)) > 0) {
  target_matches <- qmd_files[
    basename(dirname(qmd_files)) == trimws(TARGET_TUTORIAL)
  ]
  if (length(target_matches) == 0) {
    stop(
      "TARGET_TUTORIAL '", TARGET_TUTORIAL, "' not found.\n",
      "Check the folder name in tutorials/ and try again."
    )
  }
  qmd_files <- target_matches
  cat("TARGET_TUTORIAL mode: processing only '", TARGET_TUTORIAL, "'\n\n", sep = "")
}

# Results log
results <- data.frame(
  file       = character(),
  title      = character(),
  status     = character(),
  doi        = character(),
  edit_url   = character(),
  stringsAsFactors = FALSE
)

# Counter for newly created drafts
drafts_created <- 0

# Process each tutorial
for (qmd_path in qmd_files) {

  # Stop if we've hit the limit for new drafts
  if (drafts_created >= LIMIT) {
    cat("── Limit of", LIMIT, "draft(s) reached — stopping here.\n")
    cat("   Run the script again to continue with the next batch.\n\n")
    break
  }

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
    drafts_created <- drafts_created + 1
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
cat("Failed:               ", sum(grepl("FAILED", results$status)), "\n")

remaining <- sum(results$status != "DRAFT CREATED" &
                 !grepl("DOI exists|parse error|FAILED", results$status))
still_needed <- length(qmd_files) - nrow(results)
if (still_needed > 0) {
  cat("\nNot yet processed (hit limit):", still_needed, "tutorial(s)\n")
  cat("Run the script again to continue with the next batch.\n")
}
cat("\n")

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
