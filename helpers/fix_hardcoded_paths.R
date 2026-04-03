# ============================================================
# Fix hardcoded here::here() paths in renamed tutorials
# ============================================================
# Run from the root of the ladal repo.
#
# After renaming tutorial folders, any hardcoded path like
#   here::here("tutorials/clust/data/file.rda")
# inside code chunks needs updating to:
#   here::here("tutorials/cluster_analysis/data/file.rda")
#
# This script scans all tutorial .qmd files and replaces
# old folder names with new ones in any here::here() call,
# file.path() call, or quoted path string.
#
# Set DRY_RUN <- TRUE to preview, FALSE to apply.
# ============================================================

library(here)

DRY_RUN <- FALSE

# ── Same rename mapping as rename_tutorials.R ─────────────────────────────

RENAMES <- list(
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
  "workingwithcomputers_tutorial" = "working_with_computers",
  "corpuscompilation_tutorial"    = "corpus_compilation",
  "descriptivestats_tutorial"     = "descriptive_stats",
  "semanticvectors_tutorial"      = "semantic_vectors",
  "dimensionredux_tutorial"       = "dimension_reduction",
  "concordancing_tutorial"        = "concordancing",
  "collocation_tutorial"          = "collocations",
  "deeplearning_tutorial"         = "deep_learning",
  "conceptualmaps_showcase"       = "conceptual_maps_comparison",
  "phylogenetic_showcase"         = "phylogenetic_methods",
  "localllm_showcase"             = "llm_privacy",
  "topicmodel_showcase"           = "topic_modelling_dickens",
  "corpuslinguistics_showcase"    = "corpus_linguistics",
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

# ── Find all tutorial .qmd files ─────────────────────────────────────────

all_qmds <- list.files(
  here("tutorials"),
  pattern    = "\\.qmd$",
  recursive  = TRUE,
  full.names = TRUE
)

cat("============================================================\n")
cat("Fix hardcoded here::here() paths in renamed tutorials\n")
cat(sprintf("Mode: %s\n",
    if (DRY_RUN) "DRY RUN (no files written)" else "LIVE (files modified)"))
cat(sprintf("Tutorials to scan: %d\n", length(all_qmds)))
cat("============================================================\n\n")

n_changed <- 0
n_clean   <- 0

for (qmd_path in all_qmds) {

  rel_path <- sub(paste0(here(), "/"), "", qmd_path)
  lines    <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")
  updated  <- lines
  changed  <- FALSE
  changes  <- character(0)

  for (old_name in names(RENAMES)) {
    new_name <- RENAMES[[old_name]]

    # Match any occurrence of the old folder name inside a path string.
    # Covers: here::here("tutorials/OLD/..."), file.path(..., "OLD", ...),
    # and any bare quoted path "tutorials/OLD/..."
    # We match OLD only when preceded by "tutorials/" and followed by
    # "/" or a quote — to avoid partial matches.

    pattern     <- paste0('tutorials/', old_name, '([/"])')
    replacement <- paste0('tutorials/', new_name, '\\1')

    hits <- grep(pattern, updated, perl = TRUE)

    if (length(hits) > 0) {
      for (h in hits) {
        old_line <- updated[h]
        new_line <- gsub(pattern, replacement, updated[h], perl = TRUE)
        if (old_line != new_line) {
          changes <- c(changes,
            sprintf("    Line %d: %s\n           -> %s",
                    h, trimws(old_line), trimws(new_line)))
          updated[h] <- new_line
          changed <- TRUE
        }
      }
    }
  }

  if (changed) {
    n_changed <- n_changed + 1
    cat(sprintf("  %s  %s\n",
        if (DRY_RUN) "WOULD UPDATE" else "UPDATED", rel_path))
    for (ch in changes) cat(ch, "\n")
    cat("\n")
    if (!DRY_RUN) {
      writeLines(updated, qmd_path, useBytes = FALSE)
    }
  } else {
    n_clean <- n_clean + 1
  }
}

# ── Summary ───────────────────────────────────────────────────────────────

cat("============================================================\n")
cat("SUMMARY\n")
cat("============================================================\n\n")
cat(sprintf("  Files with paths to update: %d\n", n_changed))
cat(sprintf("  Files already clean:        %d\n", n_clean))

if (DRY_RUN && n_changed > 0) {
  cat("\n  Set DRY_RUN <- FALSE and re-run to apply changes.\n")
}
cat("\n")
