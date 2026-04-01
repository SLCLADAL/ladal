# ============================================================
# LADAL Tutorial Folder Rename Migration Script
# ============================================================
# Run this script ONCE from the root of the ladal repo.
# It:
#   1. Renames tutorial folders (and the .qmd file inside each)
#   2. Updates all /tutorials/OLD/OLD.html links in .qmd files
#   3. Updates params$url fields in tutorial front matter
#   4. Adds redirect entries in helpers/generate_redirects.R
#      for every renamed tutorial
#   5. Prints a summary of everything changed
#
# BEFORE RUNNING:
#   - Commit or stash any uncommitted changes
#   - Run from the ladal repo root (where _quarto.yml lives)
#   - After running: re-render with quarto::quarto_render()
# ============================================================

library(here)

# ── Rename mapping: old folder name -> new folder name ─────────────────────
RENAMES <- list(
  # Too cryptic
  "llr"                           = "learner_language",
  "lex"                           = "lexicography",
  "key"                           = "keywords",
  "net"                           = "network_analysis",
  "sem"                           = "structural_equations",
  "tree"                          = "tree_models",
  "clust"                         = "cluster_analysis",
  "repro"                         = "reproducibility",
  "load"                          = "data_loading",
  "regex"                         = "regular_expressions",
  "simulate"                      = "data_simulation",
  "dviz"                          = "data_viz_advanced",
  "motion"                        = "interactive_viz",
  "power"                         = "power_analysis",
  "whyr"                          = "why_r",
  # Strip _tutorial suffix
  "workingwithcomputers_tutorial" = "working_with_computers",
  "corpuscompilation_tutorial"    = "corpus_compilation",
  "descriptivestats_tutorial"     = "descriptive_stats",
  "semanticvectors_tutorial"      = "semantic_vectors",
  "dimensionredux_tutorial"       = "dimension_reduction",
  "concordancing_tutorial"        = "concordancing",
  "collocation_tutorial"          = "collocations",
  "deeplearning_tutorial"         = "deep_learning",
  # Strip _showcase suffix
  "conceptualmaps_showcase"       = "conceptual_maps_comparison",
  "phylogenetic_showcase"         = "phylogenetic_methods",
  "localllm_showcase"             = "llm_privacy",
  "topicmodel_showcase"           = "topic_modelling_dickens",
  "corpuslinguistics_showcase"    = "corpus_linguistics",
  # Abbreviated but not obvious
  "introquant"                    = "quant_intro",
  "basicquant"                    = "quant_basics",
  "intror"                        = "r_intro",
  "introviz"                      = "viz_intro",
  "introta"                       = "text_analysis_intro",
  "basicstatz"                    = "inferential_stats",
  "pdf2txt"                       = "pdf_to_text",
  "txtsum"                        = "text_summarisation",
  "postag"                        = "pos_tagging",
  "rbert"                         = "bert_roberta",
  "reinfnlp"                      = "reinforcement_nlp",
  "lexsim"                        = "lexical_similarity"
)

# ── Helpers ─────────────────────────────────────────────────────────────────

tutorials_dir   <- here("tutorials")
base_url        <- "https://ladal.edu.au"
redirects_file  <- here("helpers", "generate_redirects.R")

log <- list(
  folders_renamed  = character(0),
  files_renamed    = character(0),
  qmds_updated     = character(0),
  skipped_missing  = character(0)
)

# ── Step 1: Rename folders and .qmd files inside them ───────────────────────

cat("\n========================================================\n")
cat("STEP 1 — Renaming folders and .qmd files\n")
cat("========================================================\n\n")

for (old_name in names(RENAMES)) {
  new_name <- RENAMES[[old_name]]
  old_dir  <- file.path(tutorials_dir, old_name)
  new_dir  <- file.path(tutorials_dir, new_name)

  if (!dir.exists(old_dir)) {
    cat(sprintf("  SKIP  %-40s (folder not found)\n", old_name))
    log$skipped_missing <- c(log$skipped_missing, old_name)
    next
  }

  if (dir.exists(new_dir)) {
    cat(sprintf("  SKIP  %-40s (target folder already exists)\n", old_name))
    next
  }

  # Rename the folder
  file.rename(old_dir, new_dir)
  log$folders_renamed <- c(log$folders_renamed, old_name)
  cat(sprintf("  OK    %-40s -> %s\n", old_name, new_name))

  # Rename the .qmd file inside (old_name.qmd -> new_name.qmd)
  old_qmd <- file.path(new_dir, paste0(old_name, ".qmd"))
  new_qmd <- file.path(new_dir, paste0(new_name, ".qmd"))

  if (file.exists(old_qmd)) {
    file.rename(old_qmd, new_qmd)
    log$files_renamed <- c(log$files_renamed, paste0(old_name, ".qmd"))
    cat(sprintf("        %-40s -> %s\n",
                paste0(old_name, ".qmd"), paste0(new_name, ".qmd")))
  }
}

# ── Step 2: Update all .qmd files that contain old links ───────────────────

cat("\n========================================================\n")
cat("STEP 2 — Updating links in all .qmd files\n")
cat("========================================================\n\n")

# Find every .qmd in the repo (tutorials + top-level pages)
all_qmds <- c(
  list.files(tutorials_dir, pattern = "\\.qmd$",
             recursive = TRUE, full.names = TRUE),
  list.files(here(), pattern = "\\.qmd$",
             recursive = FALSE, full.names = TRUE)
)

for (qmd_file in all_qmds) {
  original <- readLines(qmd_file, warn = FALSE)
  updated  <- original
  changed  <- FALSE

  for (old_name in names(RENAMES)) {
    new_name <- RENAMES[[old_name]]

    # Pattern 1: href links  /tutorials/OLD/OLD.html
    old_link <- paste0("/tutorials/", old_name, "/", old_name, ".html")
    new_link <- paste0("/tutorials/", new_name, "/", new_name, ".html")
    if (any(grepl(old_link, updated, fixed = TRUE))) {
      updated <- gsub(old_link, new_link, updated, fixed = TRUE)
      changed <- TRUE
    }

    # Pattern 2: params$url  https://ladal.edu.au/tutorials/OLD/OLD.html
    old_url <- paste0(base_url, "/tutorials/", old_name, "/", old_name, ".html")
    new_url <- paste0(base_url, "/tutorials/", new_name, "/", new_name, ".html")
    if (any(grepl(old_url, updated, fixed = TRUE))) {
      updated <- gsub(old_url, new_url, updated, fixed = TRUE)
      changed <- TRUE
    }
  }

  if (changed) {
    writeLines(updated, qmd_file)
    rel_path <- sub(paste0(here(), "/"), "", qmd_file)
    log$qmds_updated <- c(log$qmds_updated, rel_path)
    cat(sprintf("  UPDATED  %s\n", rel_path))
  }
}

# ── Step 3: Append redirect entries to generate_redirects.R ─────────────────

cat("\n========================================================\n")
cat("STEP 3 — Adding redirects to helpers/generate_redirects.R\n")
cat("========================================================\n\n")

redirect_lines <- c(
  "",
  "# ── Section 4: Renamed tutorial redirects (post-coherence-rename) ───────────",
  "# These redirect old folder-name URLs to the new coherent folder names.",
  "# Generated automatically by rename_tutorials.R",
  ""
)

for (old_name in names(RENAMES)) {
  new_name <- RENAMES[[old_name]]
  redirect_lines <- c(
    redirect_lines,
    sprintf(
      'write_redirect(\n  output_path     = "docs/%s.html",\n  destination_url = "https://ladal.edu.au/tutorials/%s/%s.html"\n)',
      old_name, new_name, new_name
    ),
    ""
  )
}

# Also add deep-path redirects for tutorials that were at
# docs/tutorials/OLD/OLD.html (Google may have indexed these)
redirect_lines <- c(
  redirect_lines,
  "# Deep-path redirects: docs/tutorials/OLD/OLD.html -> new location",
  ""
)
for (old_name in names(RENAMES)) {
  new_name <- RENAMES[[old_name]]
  redirect_lines <- c(
    redirect_lines,
    sprintf(
      'write_redirect(\n  output_path     = "docs/tutorials/%s/%s.html",\n  destination_url = "https://ladal.edu.au/tutorials/%s/%s.html"\n)',
      old_name, old_name, new_name, new_name
    ),
    ""
  )
}

# Append to generate_redirects.R
write(redirect_lines, file = redirects_file, append = TRUE)
cat(sprintf("  Appended %d redirect entries to %s\n",
            length(RENAMES) * 2, redirects_file))

# ── Summary ──────────────────────────────────────────────────────────────────

cat("\n========================================================\n")
cat("SUMMARY\n")
cat("========================================================\n\n")
cat(sprintf("  Folders renamed:      %d\n", length(log$folders_renamed)))
cat(sprintf("  .qmd files renamed:   %d\n", length(log$files_renamed)))
cat(sprintf("  .qmd files updated:   %d (links and params URLs)\n",
            length(log$qmds_updated)))
cat(sprintf("  Skipped (not found):  %d\n", length(log$skipped_missing)))
cat(sprintf("  Redirects added:      %d\n", length(RENAMES) * 2))

if (length(log$skipped_missing) > 0) {
  cat("\n  Folders not found (check these manually):\n")
  for (s in log$skipped_missing) cat(sprintf("    - %s\n", s))
}

cat("\n========================================================\n")
cat("NEXT STEPS\n")
cat("========================================================\n\n")
cat("  1. Review the changes above for anything unexpected\n")
cat("  2. Run quarto::quarto_render() to rebuild the site\n")
cat("  3. Check that docs/ contains the new HTML paths\n")
cat("  4. Run zenodo_create_drafts.R to create new Zenodo\n")
cat("     draft records for all renamed tutorials\n")
cat("  5. Commit and push to GitHub\n\n")
