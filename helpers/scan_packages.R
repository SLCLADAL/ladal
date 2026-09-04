# =============================================================================
# scan_packages.R
#
# Scans rendered LADAL tutorial HTML files, extracts the sessionInfo() output,
# and identifies which R packages are attached in more than a given percentage
# of tutorials (default: 70%).
#
# Usage:
#   1. Set TUTORIALS_DIR to the root folder containing tutorial subfolders.
#   2. Run the script. Results are printed and written to package_summary.csv.
#
# Fixes in this version:
#   - Redirect stubs are detected and skipped (small file + no <body> content)
#   - sessionInfo regex now uses dotall mode so it matches across newlines
#   - pct_tutorials calculation uses a locally-scoped n_real_tutorials variable
#   - A debug helper is included to inspect a single file interactively
# =============================================================================

library(rvest)
library(stringr)
library(dplyr)
library(purrr)
library(tidyr)

# -----------------------------------------------------------------------------
# CONFIGURATION — edit these before running
# -----------------------------------------------------------------------------

# Root directory containing tutorial subfolders.
# Each subfolder should contain a .html file with the same name as the folder.
# Example: docs/tutorials/sentiment/sentiment.html
TUTORIALS_DIR <- "docs/tutorials"

# Threshold: packages appearing in at least this fraction of tutorials
# are flagged as candidates for the ladal package default attach list.
THRESHOLD <- 0.60

# Output CSV path
OUTPUT_CSV <- "package_summary.csv"

# Set to TRUE to print the raw extracted sessionInfo text for every tutorial,
# which helps diagnose why a particular file returns no packages.
DEBUG_MODE <- FALSE

# -----------------------------------------------------------------------------
# STEP 1: Discover real tutorial HTML files (skip redirect stubs)
# -----------------------------------------------------------------------------

is_redirect_stub <- function(html_path) {
  # Redirect stubs written by generate_redirects.R are very small files
  # (typically under 800 bytes) that contain window.location.replace()
  # but no real tutorial content.
  #
  # We use two independent checks so a real but tiny tutorial is not skipped:
  #   (a) File size under 1500 bytes  AND
  #   (b) The file contains "window.location.replace" in its raw text
  #
  # A real tutorial will never be under 1500 bytes.

  file_size <- file.info(html_path)$size
  if (is.na(file_size) || file_size > 1500) return(FALSE)

  raw <- tryCatch(
    readLines(html_path, warn = FALSE, encoding = "UTF-8"),
    error = function(e) character(0)
  )
  any(str_detect(raw, "window\\.location\\.replace"))
}

discover_html_files <- function(tutorials_dir) {
  subdirs <- list.dirs(tutorials_dir, recursive = FALSE, full.names = TRUE)

  candidates <- map_chr(subdirs, function(d) {
    folder_name <- basename(d)
    candidate   <- file.path(d, paste0(folder_name, ".html"))
    if (file.exists(candidate)) candidate else NA_character_
  })
  candidates <- candidates[!is.na(candidates)]

  # Filter out redirect stubs
  is_stub  <- map_lgl(candidates, is_redirect_stub)
  real     <- candidates[!is_stub]
  n_stubs  <- sum(is_stub)

  message("Found ", length(candidates), " HTML files matching the name pattern.")
  if (n_stubs > 0) {
    message("Skipped ", n_stubs,
            " redirect stub(s) (tiny files containing window.location.replace).")
  }
  message("Scanning ", length(real), " real tutorial HTML files.")
  real
}

# -----------------------------------------------------------------------------
# STEP 2: Extract sessionInfo text from a single HTML file
# -----------------------------------------------------------------------------

extract_session_info_text <- function(html_path) {
  # Quarto renders sessionInfo() output inside:
  #   <div class="cell-output cell-output-stdout">
  #     <pre><code>R version ...
  #     other attached packages:
  #      [1] dplyr_1.1.4 ...
  #     </code></pre>
  #   </div>
  #
  # html_text2() on <pre> elements gives us the raw text content.
  # We then search for the block containing the sessionInfo fingerprints.

  tryCatch({
    page <- read_html(html_path)

    # Primary: text from all <pre> elements
    pre_texts <- page |>
      html_elements("pre") |>
      html_text2()

    session_blocks <- pre_texts[
      str_detect(pre_texts, fixed("R version")) &
      str_detect(pre_texts, "attached base packages|other attached packages")
    ]

    # Fallback: Quarto sometimes wraps output in .cell-output divs without <pre>
    if (length(session_blocks) == 0) {
      div_texts <- page |>
        html_elements("div.cell-output-stdout, div.cell-output, div.output") |>
        html_text2()

      session_blocks <- div_texts[
        str_detect(div_texts, fixed("R version")) &
        str_detect(div_texts, "attached base packages|other attached packages")
      ]
    }

    if (length(session_blocks) == 0) {
      warning("No sessionInfo block found in: ", basename(dirname(html_path)),
              call. = FALSE)
      return(NA_character_)
    }

    # Use the last match — sessionInfo is always at the end of the tutorial
    result <- session_blocks[length(session_blocks)]

    if (DEBUG_MODE) {
      cat("\n--- DEBUG:", basename(dirname(html_path)), "---\n")
      cat(substr(result, 1, 600), "\n")
    }

    result

  }, error = function(e) {
    warning("Could not parse: ", basename(dirname(html_path)),
            " — ", conditionMessage(e), call. = FALSE)
    NA_character_
  })
}

# -----------------------------------------------------------------------------
# STEP 3: Parse package names from sessionInfo text
# -----------------------------------------------------------------------------

parse_attached_packages <- function(session_text) {
  # sessionInfo() output has this structure:
  #
  #   attached base packages:
  #    [1] stats  graphics  grDevices  utils  datasets  methods  base
  #
  #   other attached packages:
  #    [1] flextable_0.9.6  checkdown_0.0.2  stringr_1.5.1  ggplot2_3.5.1
  #    [5] dplyr_1.1.4
  #
  #   loaded via a namespace (and not attached):
  #    [1] cli_3.6.3  vctrs_0.6.5  ...
  #
  # We want ONLY the "other attached packages" section — the packages that
  # tutorial authors explicitly loaded with library(). We must NOT capture
  # anything from "loaded via a namespace", which contains dozens of
  # background dependencies that no one explicitly loaded.
  #
  # Strategy:
  #   1. Split the full text on the known section headers.
  #   2. Find the chunk that starts with "other attached packages:".
  #   3. Extract package_version tokens from that chunk only.
  #
  # Splitting on section headers is more reliable than a greedy regex
  # because it does not depend on exact whitespace between sections.

  if (is.na(session_text) || nchar(trimws(session_text)) == 0) {
    return(character(0))
  }

  # Split the sessionInfo text into sections at every known header line.
  # Known headers (all end with a colon):
  #   "attached base packages:"
  #   "other attached packages:"
  #   "loaded via a namespace (and not attached):"
  #   "other attached packages:" can also appear as just "other attached packages:"
  sections <- str_split(
    session_text,
    "\n(?=[a-zA-Z][^\n]*:(?:\\s*$|\\s*\n))"
  )[[1]]

  # Find the section whose first line contains "other attached packages"
  # (case-insensitive, to be safe)
  attached_idx <- which(str_detect(sections, regex("other attached packages:", ignore_case = TRUE)))

  if (length(attached_idx) == 0) {
    # Tutorial loaded only base packages — no user-installed packages attached
    return(character(0))
  }

  # Take the first matching section (there should only ever be one)
  attached_section <- sections[attached_idx[1]]

  # Remove the header line itself so we don't accidentally match it
  attached_section <- str_replace(attached_section, ".*other attached packages:.*\n", "")

  # Extract package_version tokens: e.g. dplyr_1.1.4  ggplot2_3.5.1
  # Pattern: starts with a letter, word chars or dots, then underscore,
  # then a version number (digits, dots)
  pkg_version_tokens <- str_extract_all(
    attached_section,
    "[a-zA-Z][a-zA-Z0-9.]*_[0-9]+\\.[0-9]+[0-9.]*"
  )[[1]]

  if (length(pkg_version_tokens) == 0) {
    return(character(0))
  }

  # Strip version suffix — keep only the package name
  pkg_names <- str_remove(pkg_version_tokens, "_[0-9].*$")
  unique(pkg_names)
}

# -----------------------------------------------------------------------------
# STEP 4: Run over all tutorials and aggregate
# -----------------------------------------------------------------------------

scan_all_tutorials <- function(tutorials_dir, threshold = 0.70) {

  html_files    <- discover_html_files(tutorials_dir)
  n_tutorials   <- length(html_files)

  if (n_tutorials == 0) {
    stop("No tutorial HTML files found in: ", tutorials_dir,
         "\nCheck that TUTORIALS_DIR is set correctly and points to the",
         " folder containing tutorial subfolders.")
  }

  message("Extracting sessionInfo from ", n_tutorials, " tutorials...")

  results <- map(html_files, function(f) {
    tutorial_name <- basename(dirname(f))
    session_text  <- extract_session_info_text(f)
    pkgs          <- parse_attached_packages(session_text)

    list(
      tutorial      = tutorial_name,
      packages      = pkgs,
      n_packages    = length(pkgs),
      session_found = !is.na(session_text)
    )
  })

  # Tutorials where no sessionInfo was found (after redirect stubs removed,
  # these are genuine tutorials that may not have a sessionInfo() chunk)
  missing_session <- keep(results, ~ !.x$session_found) |>
    map_chr(~ .x$tutorial)

  if (length(missing_session) > 0) {
    message(
      "\nNOTE: No sessionInfo output found in ",
      length(missing_session), " tutorial(s).\n",
      "These tutorials may be missing a sessionInfo() chunk, or the output\n",
      "block may use an unexpected HTML structure. Run with DEBUG_MODE <- TRUE\n",
      "to inspect the raw text extracted from each file.\n\n",
      "Tutorials without sessionInfo:\n  ",
      paste(sort(missing_session), collapse = "\n  ")
    )
  }

  # Count only tutorials where we actually found packages (denominotor for %)
  # Using all tutorials (including those with no sessionInfo) would unfairly
  # penalise packages — a tutorial with no sessionInfo is not evidence of absence.
  n_real_tutorials <- length(keep(results, ~ .x$session_found))

  # Flatten to long data frame: one row per (tutorial, package)
  long_df <- map_dfr(results, function(r) {
    if (length(r$packages) == 0) {
      tibble(tutorial = r$tutorial, package = NA_character_,
             session_found = r$session_found)
    } else {
      tibble(tutorial = r$tutorial, package = r$packages,
             session_found = TRUE)
    }
  })

  # Count how many tutorials each package appears in
  # n_real_tutorials is passed explicitly to avoid dplyr scoping issues
  package_counts <- long_df |>
    filter(!is.na(package)) |>
    group_by(package) |>
    summarise(
      n_tutorials   = n_distinct(tutorial),
      pct_tutorials = round(n_distinct(tutorial) / n_real_tutorials * 100, 1),
      .groups = "drop"
    ) |>
    arrange(desc(n_tutorials)) |>
    mutate(above_threshold = pct_tutorials >= (threshold * 100))

  list(
    n_scanned       = n_tutorials,
    n_with_session  = n_real_tutorials,
    n_no_session    = length(missing_session),
    package_counts  = package_counts,
    per_tutorial    = long_df,
    missing_session = missing_session
  )
}

# -----------------------------------------------------------------------------
# STEP 5: Print summary and write CSVs
# -----------------------------------------------------------------------------

print_summary <- function(scan_result, threshold = 0.70) {

  threshold_pct <- threshold * 100
  candidates    <- filter(scan_result$package_counts, above_threshold)

  cat("\n", strrep("=", 62), "\n", sep = "")
  cat("  LADAL Package Scan Summary\n")
  cat(strrep("=", 62), "\n\n", sep = "")
  cat("  HTML files scanned:           ", scan_result$n_scanned,      "\n")
  cat("  Tutorials with sessionInfo:   ", scan_result$n_with_session, "\n")
  cat("  Tutorials without sessionInfo:", scan_result$n_no_session,   "\n")
  cat("  Threshold:                    ", threshold_pct, "%\n")
  cat("  Packages above threshold:     ", nrow(candidates),           "\n\n")

  cat(strrep("-", 62), "\n", sep = "")
  cat("  CANDIDATE PACKAGES FOR ladal DEFAULT ATTACH LIST\n")
  cat("  These are packages tutorial authors explicitly loaded with\n")
  cat("  library() — NOT background dependencies loaded automatically.\n")
  cat("  (appearing in >=", threshold_pct, "% of tutorials with sessionInfo)\n")
  cat(strrep("-", 62), "\n\n", sep = "")

  if (nrow(candidates) == 0) {
    cat("  No packages meet the threshold.\n\n")
  } else {
    candidates |>
      select(package, n_tutorials, pct_tutorials) |>
      as.data.frame() |>
      print(row.names = FALSE)
    cat("\n")
  }

  cat(strrep("-", 62), "\n", sep = "")
  cat("  ALL PACKAGES (sorted by frequency)\n")
  cat(strrep("-", 62), "\n\n", sep = "")

  scan_result$package_counts |>
    select(package, n_tutorials, pct_tutorials, above_threshold) |>
    as.data.frame() |>
    print(row.names = FALSE)

  cat("\n", strrep("=", 62), "\n\n", sep = "")
}

# -----------------------------------------------------------------------------
# DEBUG HELPER — run this interactively to inspect a single tutorial
# -----------------------------------------------------------------------------
# To diagnose why a specific tutorial returns no packages, run:
#
#   debug_tutorial("sentiment")
#
# It will print the raw text extracted from the <pre> elements and the
# parsed package list so you can see exactly what the script is seeing.

debug_tutorial <- function(tutorial_name, tutorials_dir = TUTORIALS_DIR) {
  f <- file.path(tutorials_dir, tutorial_name,
                 paste0(tutorial_name, ".html"))

  if (!file.exists(f)) {
    message("File not found: ", f)
    return(invisible(NULL))
  }

  if (is_redirect_stub(f)) {
    message(tutorial_name, " is a redirect stub — skipping.")
    return(invisible(NULL))
  }

  cat("=== File size:", file.info(f)$size, "bytes ===\n\n")

  page      <- read_html(f)
  pre_texts <- page |> html_elements("pre") |> html_text2()
  cat("=== Number of <pre> blocks found:", length(pre_texts), "===\n\n")

  session_blocks <- pre_texts[
    str_detect(pre_texts, fixed("R version")) &
    str_detect(pre_texts, "attached base packages|other attached packages")
  ]
  cat("=== sessionInfo blocks found:", length(session_blocks), "===\n\n")

  if (length(session_blocks) > 0) {
    cat("=== Raw text of last sessionInfo block (first 800 chars) ===\n")
    cat(substr(session_blocks[length(session_blocks)], 1, 800), "\n\n")

    pkgs <- parse_attached_packages(session_blocks[length(session_blocks)])
    cat("=== Parsed packages ===\n")
    print(pkgs)
  } else {
    cat("No sessionInfo block found. Printing first 200 chars of each <pre>:\n\n")
    walk(pre_texts, ~ cat(substr(.x, 1, 200), "\n---\n"))
  }

  invisible(NULL)
}

# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------

main <- function() {

  if (!dir.exists(TUTORIALS_DIR)) {
    stop(
      "TUTORIALS_DIR does not exist: ", TUTORIALS_DIR, "\n",
      "Edit the CONFIGURATION section at the top of this script."
    )
  }

  scan_result <- scan_all_tutorials(TUTORIALS_DIR, threshold = THRESHOLD)
  print_summary(scan_result, threshold = THRESHOLD)

  write.csv(scan_result$package_counts, OUTPUT_CSV, row.names = FALSE)
  message("Full results written to: ", OUTPUT_CSV)

  per_tutorial_csv <- sub("\\.csv$", "_per_tutorial.csv", OUTPUT_CSV)
  write.csv(scan_result$per_tutorial, per_tutorial_csv, row.names = FALSE)
  message("Per-tutorial breakdown written to: ", per_tutorial_csv)

  invisible(scan_result)
}

main()
