# Github pages doesn't support any easy way to generate standard redirects, so
# unfortunately we're going to have to redirect from the original flat URLs to the new
# canonical URLs with a JS redirect.

# ── Helper: write a redirect HTML file ───────────────────────────────────────
# Creates any necessary subdirectories automatically.

write_redirect <- function(output_path, destination_url) {
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  content <- paste0(
    "<!DOCTYPE html>\n<html>\n\t<head>\n",
    "\t\t<meta charset=\"UTF-8\">\n",
    "\t\t<meta http-equiv=\"refresh\" content=\"0; url=", destination_url, "\">\n",
    "\t\t<link rel=\"canonical\" href=\"", destination_url, "\">\n",
    "\t\t<script>\n\t\t\t",
    "window.location.replace(\"", destination_url, "\");\n\t\t</script>\n",
    "\t</head>\n",
    "\t<body>\n",
    "\t\t<p>Redirecting to <a href=\"", destination_url, "\">", destination_url, "</a></p>\n",
    "\t</body>\n</html>\n"
  )
  cat(content, file = output_path)
}

BASE <- "https://ladal.edu.au/tutorials"

# ── Master mapping: every known old name → current canonical folder/file ─────
#
# Format: "old_name" = "new_folder/new_file"
# Covers ALL tutorials that have ever had a public URL, including:
#   - tutorials whose folder name is unchanged (old flat URL still needs redirect)
#   - tutorials renamed once or multiple times
#   - showcase and how-to tutorials with old names
#
# speechprocessing is deliberately excluded (not yet published).

all_tutorials <- list(
  
  # ── Data Science Basics ────────────────────────────────────────────────────
  "working_with_computers"              = "working_with_computers/working_with_computers",
  "workingwithcomputers_tutorial"       = "working_with_computers/working_with_computers",
  "comp"                                = "working_with_computers/working_with_computers",
  "datamanage"                          = "datamanagement/datamanagement",
  "datamanagement"                      = "datamanagement/datamanagement",
  "reproducibility"                     = "reproducibility/reproducibility",
  "repro"                               = "reproducibility/reproducibility",
  "quant_intro"                         = "quant_intro/quant_intro",
  "introquant"                          = "quant_intro/quant_intro",
  "quant_basics"                        = "quant_basics/quant_basics",
  "basicquant"                          = "quant_basics/quant_basics",
  
  # ── R Basics ──────────────────────────────────────────────────────────────
  "r_intro"                             = "r_intro/r_intro",
  "intror"                              = "r_intro/r_intro",
  "data_loading"                        = "data_loading/data_loading",
  "load"                                = "data_loading/data_loading",
  "string"                              = "string/string",
  "regular_expressions"                 = "regular_expressions/regular_expressions",
  "regex"                               = "regular_expressions/regular_expressions",
  "table"                               = "table/table",
  "workingwithr"                        = "workingwithr/workingwithr",
  "r_reproducibility"                   = "r_reproducibility/r_reproducibility",
  "notebooks"                           = "notebooks/notebooks",
  "publish"                             = "publish/publish",
  "jupyter"                             = "jupyter/jupyter",
  "why_r"                               = "why_r/why_r",
  "whyr"                                = "why_r/why_r",
  
  # ── Data Collection and Acquisition ───────────────────────────────────────
  "corpus_compilation"                  = "corpus_compilation/corpus_compilation",
  "corpuscompilation_tutorial"          = "corpus_compilation/corpus_compilation",
  "gutenberg"                           = "gutenberg/gutenberg",
  "webscraping"                         = "webscraping/webscraping",
  "data_simulation"                     = "data_simulation/data_simulation",
  "simulate"                            = "data_simulation/data_simulation",
  "pdf_to_text"                         = "pdf_to_text/pdf_to_text",
  "pdf2txt"                             = "pdf_to_text/pdf_to_text",
  
  # ── Data Visualization ────────────────────────────────────────────────────
  "data_viz_intro"                      = "data_viz_intro/data_viz_intro",
  "viz_intro"                           = "data_viz_intro/data_viz_intro",
  "introviz"                            = "data_viz_intro/data_viz_intro",
  "data_viz_advanced"                   = "data_viz_advanced/data_viz_advanced",
  "dviz"                                = "data_viz_advanced/data_viz_advanced",
  "interactive_viz"                     = "interactive_viz/interactive_viz",
  "motion"                              = "interactive_viz/interactive_viz",
  "conceptmaps"                         = "conceptmaps/conceptmaps",
  "leaflet"                             = "leaflet/leaflet",
  "conceptual_maps_comparison"          = "conceptual_maps_comparison/conceptual_maps_comparison",
  "conceptualmaps_showcase"             = "conceptual_maps_comparison/conceptual_maps_comparison",
  "conceptualmaps_showcase2"            = "conceptual_maps_comparison/conceptual_maps_comparison",
  "vowelchart"                          = "vowelchart/vowelchart",
  "vc"                                  = "vowelchart/vowelchart",
  
  # ── Statistics ────────────────────────────────────────────────────────────
  "descriptive_stats"                   = "descriptive_stats/descriptive_stats",
  "descriptivestats_tutorial"           = "descriptive_stats/descriptive_stats",
  "dstats"                              = "descriptive_stats/descriptive_stats",
  "basicstatz"                          = "inferential_stats/inferential_stats",
  "inferential_stats"                   = "inferential_stats/inferential_stats",
  "anova"                               = "anova/anova",
  "regression_concepts"                 = "regression_concepts/regression_concepts",
  "regression"                          = "regression/regression",
  "mixedmodel"                          = "mixedmodel/mixedmodel",
  "structural_equations"                = "structural_equations/structural_equations",
  "sem"                                 = "structural_equations/structural_equations",
  "tree_models"                         = "tree_models/tree_models",
  "tree"                                = "tree_models/tree_models",
  "cluster_analysis"                    = "cluster_analysis/cluster_analysis",
  "clust"                               = "cluster_analysis/cluster_analysis",
  "phylogenetic_methods"                = "phylogenetic_methods/phylogenetic_methods",
  "phylogenetic_showcase"               = "phylogenetic_methods/phylogenetic_methods",
  "reinforcement_nlp"                   = "reinforcement_nlp/reinforcement_nlp",
  "reinfnlp"                            = "reinforcement_nlp/reinforcement_nlp",
  "lexical_similarity"                  = "lexical_similarity/lexical_similarity",
  "lexsim"                              = "lexical_similarity/lexical_similarity",
  "semantic_vectors"                    = "semantic_vectors/semantic_vectors",
  "semanticvectors_tutorial"            = "semantic_vectors/semantic_vectors",
  "svm"                                 = "semantic_vectors/semantic_vectors",
  "dimension_reduction"                 = "dimension_reduction/dimension_reduction",
  "dimensionredux_tutorial"             = "dimension_reduction/dimension_reduction",
  "dimred"                              = "dimension_reduction/dimension_reduction",
  "power_analysis"                      = "power_analysis/power_analysis",
  "power"                               = "power_analysis/power_analysis",
  "pwr"                                 = "power_analysis/power_analysis",
  "surveys"                             = "surveys/surveys",
  "eyetracking"                         = "eyetracking/eyetracking",
  
  # ── Text Analytics ────────────────────────────────────────────────────────
  "text_analysis_intro"                 = "text_analysis_intro/text_analysis_intro",
  "introta"                             = "text_analysis_intro/text_analysis_intro",
  "textanalysis"                        = "textanalysis/textanalysis",
  "concordancing"                       = "concordancing/concordancing",
  "concordancing_tutorial"              = "concordancing/concordancing",
  "kwics"                               = "concordancing/concordancing",
  "collocations"                        = "collocations/collocations",
  "collocation_tutorial"                = "collocations/collocations",
  "coll"                                = "collocations/collocations",
  "keywords"                            = "keywords/keywords",
  "key"                                 = "keywords/keywords",
  "pos_tagging"                         = "pos_tagging/pos_tagging",
  "postag"                              = "pos_tagging/pos_tagging",
  "network_analysis"                    = "network_analysis/network_analysis",
  "net"                                 = "network_analysis/network_analysis",
  "topic"                               = "topic/topic",
  "sentiment"                           = "sentiment/sentiment",
  "text_summarisation"                  = "text_summarisation/text_summarisation",
  "txtsum"                              = "text_summarisation/text_summarisation",
  "spellcheck"                          = "spellcheck/spellcheck",
  "embeddings"                          = "embeddings/embeddings",
  "bert_roberta"                        = "bert_roberta/bert_roberta",
  "rbert"                               = "bert_roberta/bert_roberta",
  "deep_learning"                       = "deep_learning/deep_learning",
  "deeplearning_tutorial"               = "deep_learning/deep_learning",
  "ollamar"                             = "ollamar/ollamar",
  "llm_privacy"                         = "llm_privacy/llm_privacy",
  "localllm_showcase"                   = "llm_privacy/llm_privacy",
  "document_classification"             = "document_classification/document_classification",
  "atap_docclass"                       = "document_classification/document_classification",
  "topic_modelling_dickens"             = "topic_modelling_dickens/topic_modelling_dickens",
  "topicmodel_showcase"                 = "topic_modelling_dickens/topic_modelling_dickens",
  "corpus_linguistics"                  = "corpus_linguistics/corpus_linguistics",
  "corpuslinguistics_showcase"          = "corpus_linguistics/corpus_linguistics",
  "corplingr"                           = "corpus_linguistics/corpus_linguistics",
  "learner_language"                    = "learner_language/learner_language",
  "llr"                                 = "learner_language/learner_language",
  "laegs"                               = "learner_language/learner_language",
  "litsty"                              = "litsty/litsty",
  "lexicography"                        = "lexicography/lexicography",
  "lex"                                 = "lexicography/lexicography"
)

# ── Section 1: Flat redirects ─────────────────────────────────────────────────
# docs/[old_name].html → https://ladal.edu.au/tutorials/[new]/[new].html
# Catches old bookmarked or linked flat URLs.

message("Writing flat redirects...")
for (old_name in names(all_tutorials)) {
  write_redirect(
    output_path     = paste0("docs/", old_name, ".html"),
    destination_url = paste0(BASE, "/", all_tutorials[[old_name]], ".html")
  )
}

# ── Section 2: Deep-path redirects ───────────────────────────────────────────
# docs/tutorials/[old_name]/[old_name].html → https://ladal.edu.au/tutorials/[new]/[new].html
# Catches links to old subfolder structure (e.g. from Google, external sites).
#
# IMPORTANT: Only write a deep-path redirect when the old_name differs from
# the canonical folder name (the first segment of the all_tutorials value).
# If old_name == canonical folder, writing a redirect would create a loop
# because the redirect file would overwrite the real rendered tutorial HTML.

message("Writing deep-path redirects...")
for (old_name in names(all_tutorials)) {
  # Extract canonical folder name from "folder/file" value
  canonical_folder <- strsplit(all_tutorials[[old_name]], "/")[[1]][1]
  # Only redirect if the old name is genuinely different from canonical
  if (old_name != canonical_folder) {
    write_redirect(
      output_path     = paste0("docs/tutorials/", old_name, "/", old_name, ".html"),
      destination_url = paste0(BASE, "/", all_tutorials[[old_name]], ".html")
    )
  }
}

# ── Section 3: 404 fixes ─────────────────────────────────────────────────────
# Specific URLs indexed by Google or linked externally that don't fit the
# standard flat/deep-path pattern above.

fixes_404 <- list(
  
  # Old URLs with non-standard paths or filenames
  "docs/tutorials/ngrams/ngrams.html"              = paste0(BASE, "/collocations/collocations.html"),
  "docs/tutorials/textanalysis/textanalysis2.html" = paste0(BASE, "/textanalysis/textanalysis.html"),
  "docs/tutorials/statistics/statistics.html"      = paste0(BASE, "/inferential_stats/inferential_stats.html"),
  "docs/tutorials/embeddings.html"                 = paste0(BASE, "/embeddings/embeddings.html"),
  "docs/tutorials/atap_docclass.html"              = paste0(BASE, "/document_classification/document_classification.html"),
  "docs/tutorials/textanalysis.html"               = paste0(BASE, "/textanalysis/textanalysis.html"),
  "docs/tutorials/svm.html"                        = paste0(BASE, "/semantic_vectors/semantic_vectors.html"),
  "docs/tutorials/reinfnlp.html"                   = paste0(BASE, "/reinforcement_nlp/reinforcement_nlp.html"),
  "docs/tutorials/repro.html"                      = paste0(BASE, "/reproducibility/reproducibility.html"),
  "docs/tutorials/txtsum.html"                     = paste0(BASE, "/text_summarisation/text_summarisation.html"),
  "docs/tutorials/clust.html"                      = paste0(BASE, "/cluster_analysis/cluster_analysis.html"),
  "docs/tutorials/tree.html"                       = paste0(BASE, "/tree_models/tree_models.html"),
  "docs/tutorials/regression.html"                 = paste0(BASE, "/regression/regression.html"),
  "docs/tutorials/comp.html"                       = paste0(BASE, "/working_with_computers/working_with_computers.html"),
  "docs/tutorials/reinfnlp/intror.html"            = paste0(BASE, "/r_intro/r_intro.html"),
  
  # Old .Rmd and content file URLs
  "docs/tutorials/pdf2txt/pdf2txt.Rmd"             = paste0(BASE, "/pdf_to_text/pdf_to_text.html"),
  "docs/tutorials/surveys/surveys.Rmd"             = paste0(BASE, "/surveys/surveys.html"),
  "docs/content/introviz.Rmd"                      = paste0(BASE, "/data_viz_intro/data_viz_intro.html"),
  "docs/content/kwics.Rmd"                         = paste0(BASE, "/concordancing/concordancing.html"),
  "docs/content/dviz.Rmd"                          = paste0(BASE, "/data_viz_advanced/data_viz_advanced.html"),
  "docs/content/clust.Rmd"                         = paste0(BASE, "/cluster_analysis/cluster_analysis.html"),
  
  # Retired or renamed top-level pages
  "docs/topicmodels.html"                          = paste0(BASE, "/topic/topic.html"),
  "docs/tutorials/bookdown/bookdown.html"          = paste0(BASE, "/publish/publish.html"),
  # NOTE: tutorials/keywords/keywords.html is intentionally NOT listed here —
  # that path is the real rendered tutorial file. A redirect there would
  # overwrite it with a loop back to itself.
  "docs/news.html"                                 = "https://ladal.edu.au/events.html",
  "docs/phylo.html"                                = "https://ladal.edu.au/tutorials.html",
  "docs/gviz.html"                                 = paste0(BASE, "/data_viz_intro/data_viz_intro.html"),
  "docs/tagging.html"                              = paste0(BASE, "/pos_tagging/pos_tagging.html"),
  "docs/webcrawling.html"                          = "https://ladal.edu.au/tutorials.html",
  "docs/compthink.html"                            = paste0(BASE, "/quant_intro/quant_intro.html"),
  "docs/compthinking.html"                         = paste0(BASE, "/quant_intro/quant_intro.html"),
  
  # Data and resource files
  # PDF data files from old pdf2txt tutorial folder — GitHub Pages will serve
  # the HTML redirect file even for .pdf paths when the actual file is absent.
  "docs/tutorials/pdf2txt/data/PDFs/pdf2.pdf"      = paste0(BASE, "/pdf_to_text/pdf_to_text.html"),
  "docs/tutorials/pdf2txt/data/PDFs/pdf3.pdf"      = paste0(BASE, "/pdf_to_text/pdf_to_text.html"),
  "docs/data/PDFs/pdf3.pdf"                        = paste0(BASE, "/pdf_to_text/pdf_to_text.html"),
  "docs/assets/bibliography.bib"                   = "https://ladal.edu.au/about.html",
  "docs/resources/stopwords_en.txt"                = paste0(BASE, "/topic/topic.html"),
  
  # Malformed URL
  "docs/www.ladal.edu.au"                          = "https://ladal.edu.au"
)

message("Writing 404 fixes...")
for (output_path in names(fixes_404)) {
  write_redirect(
    output_path     = output_path,
    destination_url = fixes_404[[output_path]]
  )
}

# Compute accurate deep-path count (canonical-name entries are skipped in Section 2)
deep_path_count <- sum(sapply(names(all_tutorials), function(n) {
  strsplit(all_tutorials[[n]], "/")[[1]][1] != n
}))

message(
  "Done. Redirects written:\n",
  "  Flat:      ", length(all_tutorials), "\n",
  "  Deep-path: ", deep_path_count, "\n",
  "  404 fixes: ", length(fixes_404), "\n",
  "  TOTAL:     ", length(all_tutorials) + deep_path_count + length(fixes_404)
)