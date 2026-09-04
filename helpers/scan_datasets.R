# =============================================================================
# scan_datasets.R
#
# Scans LADAL tutorial .qmd source files to identify:
#
#   (A) DATA FOLDER FILES — any file found in a data/ subfolder within each
#       tutorial folder (e.g. tutorials/sentiment/data/reviews.rda).
#       These are datasets already saved to disk that could be bundled.
#
#   (B) AD HOC INLINE DATASETS — datasets created directly inside tutorial
#       code chunks using common R patterns:
#         - data.frame() / tibble() / tribble() calls assigned to a variable
#         - read.csv() / read_csv() / readRDS() / readLines() / read.table()
#           loading from a local path (not a URL)
#         - Datasets from well-known packages accessed via data() or :: notation
#           (e.g. iris, mtcars, but also languageR::regularity)
#
# Usage:
#   1. Set QMD_DIR to the folder containing tutorial subfolders with .qmd files.
#   2. Run the script.
#   3. Results are printed to console and written to dataset_summary.csv.
#
# Output columns:
#   tutorial        — name of the tutorial folder
#   type            — "data_folder_file" | "readRDS" | "read_csv" | "read.csv"
#                     | "readLines" | "data_frame_literal" | "package_dataset"
#   name            — variable name assigned to, or file name
#   path_or_call    — the file path or function call as written in the source
#   line_number     — line in the .qmd where the pattern was found
# =============================================================================

library(stringr)
library(dplyr)
library(purrr)
library(tibble)

# -----------------------------------------------------------------------------
# CONFIGURATION
# -----------------------------------------------------------------------------

# Root folder containing tutorial subfolders, each with a .qmd file.
# Example structure:
#   tutorials/sentiment/sentiment.qmd
#   tutorials/sentiment/data/reviews.rda
QMD_DIR <- "tutorials"

# Output CSV
OUTPUT_CSV <- "dataset_summary.csv"

# Set TRUE to print every match as it is found (useful for debugging)
DEBUG_MODE <- FALSE

# -----------------------------------------------------------------------------
# STEP 1: Discover tutorial .qmd files (skip redirect stubs and non-tutorials)
# -----------------------------------------------------------------------------

discover_qmd_files <- function(qmd_dir) {
  subdirs <- list.dirs(qmd_dir, recursive = FALSE, full.names = TRUE)

  qmd_files <- map_chr(subdirs, function(d) {
    folder_name <- basename(d)
    candidate   <- file.path(d, paste0(folder_name, ".qmd"))
    if (file.exists(candidate)) candidate else NA_character_
  })

  qmd_files <- qmd_files[!is.na(qmd_files)]
  message("Found ", length(qmd_files), " tutorial .qmd files.")
  qmd_files
}

# -----------------------------------------------------------------------------
# STEP 2: Scan data/ subfolders for existing data files
# -----------------------------------------------------------------------------

scan_data_folder <- function(tutorial_dir) {
  # Looks for any file in [tutorial_dir]/data/ at any depth.
  # Covers .rda, .rds, .csv, .txt, .tsv, .xlsx, .json, .xml etc.

  data_dir <- file.path(tutorial_dir, "data")
  if (!dir.exists(data_dir)) return(tibble())

  files <- list.files(data_dir, recursive = TRUE, full.names = FALSE)
  if (length(files) == 0) return(tibble())

  tibble(
    tutorial     = basename(tutorial_dir),
    type         = "data_folder_file",
    name         = files,
    path_or_call = file.path("data", files),
    line_number  = NA_integer_,
    file_size_kb = round(
      file.info(file.path(data_dir, files))$size / 1024, 1
    )
  )
}

# -----------------------------------------------------------------------------
# STEP 3: Scan .qmd source for inline dataset patterns
# -----------------------------------------------------------------------------

scan_qmd_for_datasets <- function(qmd_path) {

  tutorial_name <- basename(dirname(qmd_path))
  lines         <- tryCatch(
    readLines(qmd_path, warn = FALSE, encoding = "UTF-8"),
    error = function(e) {
      warning("Could not read: ", qmd_path, " — ", conditionMessage(e),
              call. = FALSE)
      character(0)
    }
  )

  if (length(lines) == 0) return(tibble())

  results <- list()

  for (i in seq_along(lines)) {
    line <- lines[i]

    # Skip comment lines and markdown lines
    if (str_detect(line, "^\\s*#") || str_detect(line, "^\\s*[>#!`-]")) next

    # ── Pattern 1: readRDS() from a local path ────────────────────────────
    # Matches: obj <- readRDS("tutorials/foo/data/bar.rda")
    #          obj <- base::readRDS("data/bar.rds", "rb")
    # Does NOT match URLs (http/https)
    if (str_detect(line, "readRDS\\s*\\(") &&
        !str_detect(line, "https?://")) {

      var_name  <- str_extract(line, "^\\s*([a-zA-Z][a-zA-Z0-9._]*)\\s*<-") |>
        str_remove_all("\\s*<-\\s*") |> str_trim()
      file_path <- str_extract(line, "readRDS\\s*\\(['\"]([^'\"]+)['\"]",
                               group = 1)

      if (!is.na(file_path)) {
        results[[length(results) + 1]] <- tibble(
          tutorial     = tutorial_name,
          type         = "readRDS",
          name         = if (is.na(var_name) || nchar(var_name) == 0)
                           basename(file_path) else var_name,
          path_or_call = file_path,
          line_number  = i,
          file_size_kb = NA_real_
        )
      }
    }

    # ── Pattern 2: read_csv() / read.csv() / read_tsv() / read.table() ───
    # Matches local file paths only (not URLs)
    if (str_detect(line, "read[._](csv|tsv|table|delim|fwf)\\s*\\(") &&
        !str_detect(line, "https?://")) {

      var_name  <- str_extract(line, "^\\s*([a-zA-Z][a-zA-Z0-9._]*)\\s*<-") |>
        str_remove_all("\\s*<-\\s*") |> str_trim()
      fn_call   <- str_extract(line, "read[._][a-z]+\\s*\\(['\"]([^'\"]+)['\"]",
                               group = 1)

      if (!is.na(fn_call)) {
        results[[length(results) + 1]] <- tibble(
          tutorial     = tutorial_name,
          type         = str_extract(line, "read[._][a-z]+"),
          name         = if (is.na(var_name) || nchar(var_name) == 0)
                           basename(fn_call) else var_name,
          path_or_call = fn_call,
          line_number  = i,
          file_size_kb = NA_real_
        )
      }
    }

    # ── Pattern 3: readLines() from a local path ──────────────────────────
    if (str_detect(line, "readLines\\s*\\(") &&
        !str_detect(line, "https?://")) {

      var_name  <- str_extract(line, "^\\s*([a-zA-Z][a-zA-Z0-9._]*)\\s*<-") |>
        str_remove_all("\\s*<-\\s*") |> str_trim()
      file_path <- str_extract(line, "readLines\\s*\\(['\"]([^'\"]+)['\"]",
                               group = 1)

      if (!is.na(file_path)) {
        results[[length(results) + 1]] <- tibble(
          tutorial     = tutorial_name,
          type         = "readLines",
          name         = if (is.na(var_name) || nchar(var_name) == 0)
                           basename(file_path) else var_name,
          path_or_call = file_path,
          line_number  = i,
          file_size_kb = NA_real_
        )
      }
    }

    # ── Pattern 4: load() for .rda files ─────────────────────────────────
    if (str_detect(line, "\\bload\\s*\\(") &&
        !str_detect(line, "https?://")) {

      file_path <- str_extract(line, "load\\s*\\(['\"]([^'\"]+)['\"]",
                               group = 1)

      if (!is.na(file_path)) {
        results[[length(results) + 1]] <- tibble(
          tutorial     = tutorial_name,
          type         = "load_rda",
          name         = basename(file_path),
          path_or_call = file_path,
          line_number  = i,
          file_size_kb = NA_real_
        )
      }
    }

    # ── Pattern 5: data.frame() / tibble() / tribble() literals ──────────
    # Only flags cases where the result is assigned to a variable,
    # suggesting it is a reusable dataset rather than a throwaway example.
    if (str_detect(line, "<-\\s*(data\\.frame|tibble|tribble)\\s*\\(")) {

      var_name <- str_extract(line, "^\\s*([a-zA-Z][a-zA-Z0-9._]*)\\s*<-") |>
        str_remove_all("\\s*<-\\s*") |> str_trim()
      fn_used  <- str_extract(line, "(data\\.frame|tibble|tribble)")

      if (!is.na(var_name) && nchar(var_name) > 0) {
        results[[length(results) + 1]] <- tibble(
          tutorial     = tutorial_name,
          type         = paste0("inline_", fn_used),
          name         = var_name,
          path_or_call = paste0(fn_used, "(...)  [line ", i, "]"),
          line_number  = i,
          file_size_kb = NA_real_
        )
      }
    }

    # ── Pattern 6: well-known built-in / package datasets ────────────────
    # Catches: data(iris), data("BNC", package = "languageR"),
    #          languageR::regularity, datasets that appear by bare name
    #          commonly used in linguistics tutorials.
    #
    # We check for explicit data() calls and for :: accessor notation
    # that references a recognised dataset-providing package.

    # data() calls
    if (str_detect(line, "\\bdata\\s*\\(")) {
      dataset_name <- str_extract(
        line,
        "data\\s*\\(['\"]?([a-zA-Z][a-zA-Z0-9._]*)['\"]?",
        group = 1
      )
      pkg_name <- str_extract(
        line,
        "package\\s*=\\s*['\"]([a-zA-Z][a-zA-Z0-9.]*)['\"]",
        group = 1
      )

      if (!is.na(dataset_name)) {
        results[[length(results) + 1]] <- tibble(
          tutorial     = tutorial_name,
          type         = "data_call",
          name         = dataset_name,
          path_or_call = if (is.na(pkg_name))
                           paste0("data(", dataset_name, ")")
                         else
                           paste0("data(", dataset_name,
                                  ", package = '", pkg_name, "')"),
          line_number  = i,
          file_size_kb = NA_real_
        )
      }
    }

    # Package::dataset notation for known data-providing packages
    pkg_dataset_pattern <- paste0(
      "(languageR|lme4|MASS|datasets|car|vcd|",
      "quanteda\\.corpora|ggplot2|tidyr|dplyr|",
      "stringr|corpora|zipfR)::",
      "([a-zA-Z][a-zA-Z0-9._]*)"
    )
    if (str_detect(line, pkg_dataset_pattern)) {
      matches <- str_extract_all(line, pkg_dataset_pattern)[[1]]
      for (m in matches) {
        parts <- str_match(m, "([^:]+)::([^(\\s,]+)")
        if (!is.na(parts[1, 1])) {
          results[[length(results) + 1]] <- tibble(
            tutorial     = tutorial_name,
            type         = "package_dataset",
            name         = parts[1, 3],
            path_or_call = m,
            line_number  = i,
            file_size_kb = NA_real_
          )
        }
      }
    }

    if (DEBUG_MODE && length(results) > 0) {
      last <- results[[length(results)]]
      cat(sprintf("[%s] line %d  type=%-20s  name=%s\n",
                  tutorial_name, i, last$type, last$name))
    }
  }

  if (length(results) == 0) return(tibble())
  bind_rows(results)
}

# -----------------------------------------------------------------------------
# STEP 4: Combine data folder scan and inline scan for all tutorials
# -----------------------------------------------------------------------------

scan_all_datasets <- function(qmd_dir) {

  qmd_files <- discover_qmd_files(qmd_dir)
  if (length(qmd_files) == 0) {
    stop("No .qmd files found in: ", qmd_dir,
         "\nCheck that QMD_DIR is set correctly.")
  }

  message("Scanning data/ subfolders and .qmd source files...")

  all_results <- map_dfr(qmd_files, function(f) {
    tutorial_dir <- dirname(f)

    folder_data <- scan_data_folder(tutorial_dir)
    inline_data <- scan_qmd_for_datasets(f)

    bind_rows(folder_data, inline_data)
  })

  if (nrow(all_results) == 0) {
    message("No datasets found.")
    return(all_results)
  }

  # Remove obvious duplicates: same tutorial + type + name + path
  all_results <- all_results |>
    distinct(tutorial, type, name, path_or_call, .keep_all = TRUE) |>
    arrange(tutorial, type, name)

  all_results
}

# -----------------------------------------------------------------------------
# STEP 5: Print summary
# -----------------------------------------------------------------------------

print_dataset_summary <- function(results) {

  cat("\n", strrep("=", 62), "\n", sep = "")
  cat("  LADAL Dataset Scan Summary\n")
  cat(strrep("=", 62), "\n\n", sep = "")
  cat("  Total dataset references found:", nrow(results), "\n")
  cat("  Tutorials with at least one:   ",
      n_distinct(results$tutorial), "\n\n")

  cat(strrep("-", 62), "\n", sep = "")
  cat("  BREAKDOWN BY TYPE\n")
  cat(strrep("-", 62), "\n\n", sep = "")

  type_counts <- results |>
    count(type, sort = TRUE) |>
    as.data.frame()
  print(type_counts, row.names = FALSE)
  cat("\n")

  cat(strrep("-", 62), "\n", sep = "")
  cat("  DATA FOLDER FILES (candidates for bundling in ladal package)\n")
  cat(strrep("-", 62), "\n\n", sep = "")

  folder_files <- results |>
    filter(type == "data_folder_file") |>
    select(tutorial, name, path_or_call, file_size_kb) |>
    arrange(tutorial, name) |>
    as.data.frame()

  if (nrow(folder_files) == 0) {
    cat("  None found.\n\n")
  } else {
    print(folder_files, row.names = FALSE)
    cat("\n")
  }

  cat(strrep("-", 62), "\n", sep = "")
  cat("  LOADED FILES (readRDS / read_csv / load_rda etc.)\n")
  cat(strrep("-", 62), "\n\n", sep = "")

  loaded_files <- results |>
    filter(type %in% c("readRDS", "read_csv", "read.csv", "read_tsv",
                       "read.table", "readLines", "load_rda")) |>
    select(tutorial, type, name, path_or_call, line_number) |>
    arrange(tutorial, name) |>
    as.data.frame()

  if (nrow(loaded_files) == 0) {
    cat("  None found.\n\n")
  } else {
    print(loaded_files, row.names = FALSE)
    cat("\n")
  }

  cat(strrep("-", 62), "\n", sep = "")
  cat("  INLINE DATASETS (data.frame / tibble / tribble literals)\n")
  cat(strrep("-", 62), "\n\n", sep = "")

  inline <- results |>
    filter(str_starts(type, "inline_")) |>
    select(tutorial, type, name, line_number) |>
    arrange(tutorial, name) |>
    as.data.frame()

  if (nrow(inline) == 0) {
    cat("  None found.\n\n")
  } else {
    print(inline, row.names = FALSE)
    cat("\n")
  }

  cat(strrep("=", 62), "\n\n", sep = "")
}

# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------

main <- function() {

  if (!dir.exists(QMD_DIR)) {
    stop(
      "QMD_DIR does not exist: ", QMD_DIR, "\n",
      "Edit the CONFIGURATION section at the top of this script.\n",
      "This should point to the folder containing tutorial subfolders,\n",
      "each of which contains a .qmd file with the same name as the folder.\n",
      "Example: tutorials/sentiment/sentiment.qmd"
    )
  }

  results <- scan_all_datasets(QMD_DIR)
  print_dataset_summary(results)

  write.csv(results, OUTPUT_CSV, row.names = FALSE)
  message("Full results written to: ", OUTPUT_CSV)

  invisible(results)
}

main()
