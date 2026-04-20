# ============================================================
# LADAL — Inject top-level description: and date: into tutorial .qmd files
# ============================================================
#
# Quarto renders:
#   <meta name="description"> from top-level `description:`
#   <meta name="dcterms.date"> from top-level `date:`
#
# Both values exist in each tutorial's params block but are not
# promoted to top-level fields. This script does that promotion.
#
# For `date:`, we use params$date_published (YYYY-MM-DD) which is
# more precise than the current top-level `date: "2026"` (year-only),
# which Quarto renders as 2026-01-01 — incorrect and bad for freshness signals.
#
# Safe behaviour:
#   - DRY_RUN = TRUE previews all changes without writing anything
#   - Never overwrites a top-level description: that already exists
#   - Updates top-level date: only if it's year-only (4 digits) and
#     params$date_published has a full YYYY-MM-DD value
#   - Saves a log CSV for review
#
# REQUIRES: yaml, here
#   install.packages(c("yaml", "here"))
# ============================================================

library(yaml)
library(here)

DRY_RUN <- FALSE   # <- Set to FALSE to write changes

TUTORIALS_DIR <- here("tutorials")

`%||%` <- function(a, b) if (!is.null(a) && nchar(trimws(as.character(a))) > 0) a else b

qmd_files <- list.files(
  path       = TUTORIALS_DIR,
  pattern    = "\\.qmd$",
  recursive  = TRUE,
  full.names = TRUE
)

cat("Found", length(qmd_files), "tutorial .qmd files\n")
cat("DRY_RUN:", DRY_RUN, "\n\n")

results <- data.frame(
  file                = character(),
  status              = character(),
  description_snippet = character(),
  date_change         = character(),
  stringsAsFactors    = FALSE
)

for (qmd_path in qmd_files) {
  rel_path <- gsub(paste0(here(), "/"), "", qmd_path)
  lines    <- readLines(qmd_path, warn = FALSE)

  # ── Find YAML front matter ────────────────────────────────────────────────
  delimiters <- which(trimws(lines) == "---")
  if (length(delimiters) < 2) {
    results <- rbind(results, data.frame(
      file = rel_path, status = "SKIPPED — no YAML",
      description_snippet = "", date_change = "", stringsAsFactors = FALSE
    ))
    next
  }

  yaml_start <- delimiters[1]
  yaml_end   <- delimiters[2]
  yaml_lines <- lines[(yaml_start + 1):(yaml_end - 1)]

  # ── Parse YAML ────────────────────────────────────────────────────────────
  parsed <- tryCatch(
    yaml::yaml.load(paste(yaml_lines, collapse = "\n")),
    error = function(e) NULL
  )
  if (is.null(parsed)) {
    results <- rbind(results, data.frame(
      file = rel_path, status = "SKIPPED — YAML parse error",
      description_snippet = "", date_change = "", stringsAsFactors = FALSE
    ))
    next
  }

  # ── Decide what needs injecting / updating ────────────────────────────────

  # description: — inject if missing at top level
  has_top_desc <- any(grepl("^description:", yaml_lines))
  params_desc  <- trimws(as.character(parsed$params$description %||% ""))
  inject_desc  <- !has_top_desc && nchar(params_desc) > 0

  # date: — update if current top-level date is year-only (e.g. "2026")
  current_date <- trimws(as.character(parsed$date %||% ""))
  params_date  <- trimws(as.character(parsed$params$date_published %||% ""))
  is_year_only <- grepl("^[0-9]{4}$", current_date)
  has_full_date <- grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}", params_date)
  update_date  <- is_year_only && has_full_date

  if (!inject_desc && !update_date) {
    results <- rbind(results, data.frame(
      file = rel_path,
      status = "SKIPPED — already has description: and full date:",
      description_snippet = "", date_change = "", stringsAsFactors = FALSE
    ))
    next
  }

  # ── Build modified YAML lines ─────────────────────────────────────────────
  new_yaml_lines <- yaml_lines

  # 1. Inject top-level description: after the title: line
  if (inject_desc) {
    desc_escaped  <- gsub('"', '\\"', params_desc, fixed = TRUE)
    new_desc_line <- paste0('description: "', desc_escaped, '"')

    title_idx <- which(grepl("^title:", new_yaml_lines))[1]
    insert_at <- if (!is.na(title_idx)) title_idx else 1
    new_yaml_lines <- c(
      new_yaml_lines[1:insert_at],
      new_desc_line,
      new_yaml_lines[(insert_at + 1):length(new_yaml_lines)]
    )
  }

  # 2. Replace year-only date: with full YYYY-MM-DD from params$date_published
  if (update_date) {
    full_date     <- substr(params_date, 1, 10)
    date_line_idx <- which(grepl("^date:", new_yaml_lines))[1]
    if (!is.na(date_line_idx)) {
      new_yaml_lines[date_line_idx] <- paste0('date: "', full_date, '"')
    }
  }

  # ── Assemble full file ────────────────────────────────────────────────────
  new_lines <- c(
    lines[1:yaml_start],
    new_yaml_lines,
    lines[yaml_end:length(lines)]
  )

  status_parts <- c(
    if (inject_desc)  "injected description:" else NULL,
    if (update_date)  paste0("updated date: ", current_date,
                             " -> ", substr(params_date, 1, 10)) else NULL
  )
  status_str <- paste(status_parts, collapse = "; ")

  if (DRY_RUN) {
    cat("WOULD MODIFY:", rel_path, "\n")
    cat(" ", status_str, "\n\n")
  } else {
    writeLines(new_lines, qmd_path)
    cat("MODIFIED:", rel_path, " —", status_str, "\n")
  }

  results <- rbind(results, data.frame(
    file                = rel_path,
    status              = if (DRY_RUN) paste("DRY RUN —", status_str) else status_str,
    description_snippet = if (inject_desc) substr(params_desc, 1, 80) else "",
    date_change         = if (update_date) paste0(current_date, " -> ",
                                                   substr(params_date, 1, 10)) else "",
    stringsAsFactors    = FALSE
  ))
}

# ── Summary ───────────────────────────────────────────────────────────────────
cat("\n============================================================\n")
cat("Summary\n")
cat("============================================================\n")
cat("Would modify / Modified:", sum(!grepl("SKIPPED", results$status)), "\n")
cat("  of which, description injected:",
    sum(grepl("description", results$status) & !grepl("SKIPPED", results$status)), "\n")
cat("  of which, date updated:        ",
    sum(grepl("date", results$status) & !grepl("SKIPPED", results$status)), "\n")
cat("Skipped:", sum(grepl("SKIPPED", results$status)), "\n")

log_path <- here("helpers", "inject_meta_fields_log.csv")
write.csv(results, log_path, row.names = FALSE)
cat("\nLog saved to:", log_path, "\n")
if (DRY_RUN) cat("\nSet DRY_RUN <- FALSE and re-run to apply changes.\n")
