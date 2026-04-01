# ============================================================
# LADAL Tutorial Params Updater
# ============================================================
# Run this script ONCE from the root of the ladal repo.
#
# For each tutorial .qmd it will:
#   1. Set version: "3.1.1" (only if current value is date-style)
#   2. Set year: "2026" (if missing)
#   3. Derive date_published: "YYYY-MM-DD" from existing version
#      (falls back to today if version is not date-style)
#   4. Insert keywords: if missing or empty
#   5. Insert description: if missing or empty
#   6. Ensure doi: "" is present if doi field is missing entirely
#   7. Update Zenodo publication_date to use date_published
#
# RULES:
#   - Never overwrites existing non-empty doi, description, or keywords
#   - Never overwrites a version that already looks semantic (x.y.z)
#   - Inserts new fields in correct order:
#       title, author, year, date_published, version, url,
#       institution, description, keywords, doi
#
# BEFORE RUNNING:
#   - Run from the ladal repo root (where _quarto.yml lives)
#   - Commit any uncommitted changes first
#   - This script modifies .qmd files in place
# ============================================================

library(here)

TUTORIALS_DIR <- here("tutorials")
TODAY         <- format(Sys.Date(), "%Y-%m-%d")
NEW_VERSION   <- "3.1.1"
NEW_YEAR      <- "2026"

# ── Keywords database ─────────────────────────────────────────────────────
KEYWORDS <- list(
  # Data Science Basics
  "workingwithcomputers_tutorial" = "digital research, file organisation, data management, research workflows, digital humanities, computational research, data storage",
  "datamanage"                    = "data management, file naming, folder structure, data documentation, research data, reproducible research, metadata",
  "repro"                         = "reproducible research, version control, open science, research workflows, documentation, Git, R Markdown, Quarto",
  "introquant"                    = "quantitative reasoning, scientific method, empirical research, quantitative methods, critical thinking, research design, humanities research",
  "basicquant"                    = "quantitative research, variables, measurements, descriptive statistics, inferential statistics, research design, data analysis",
  # R Basics
  "whyr"                          = "R programming, why R, open source, statistical computing, programming languages, data science, reproducibility",
  "intror"                        = "R programming, RStudio, introduction to R, R syntax, programming basics, data science, beginners",
  "load"                          = "data loading, file import, CSV, Excel, R programming, data import, file paths, tidyverse",
  "string"                        = "string processing, text manipulation, stringr, regular expressions, text cleaning, R programming, tidyverse",
  "regex"                         = "regular expressions, regex, pattern matching, text search, string processing, R programming, text mining",
  "table"                         = "data frames, tabular data, data manipulation, dplyr, tidyverse, data wrangling, R programming",
  "workingwithr"                  = "R programming, control flow, loops, functions, purrr, apply functions, functional programming, error handling, automation",
  "r_reproducibility"             = "reproducibility, R Markdown, Quarto, Git, version control, R Projects, open science, documentation",
  "simulate"                      = "data simulation, synthetic data, power analysis, pseudo-random numbers, Monte Carlo, reproducible research, statistical modelling, sociolinguistic variation, missing data, longitudinal data",
  # Data Visualisation
  "introviz"                      = "data visualisation, ggplot2, scatter plot, bar chart, line plot, box plot, R graphics, publication quality",
  "dviz"                          = "data visualisation, ggplot2, advanced visualisation, faceting, interactive plots, R graphics, data science",
  "conceptmaps"                   = "conceptual maps, semantic similarity, spring layout, word embeddings, GloVe, igraph, ggraph, community detection, corpus linguistics, cognitive linguistics",
  "leaflet"                       = "typological maps, geographical maps, leaflet, interactive maps, linguistic typology, dialectology, sociolinguistics, spatial data",
  "motion"                        = "interactive visualisation, plotly, gganimate, leaflet, DT, animated graphics, interactive maps, R graphics",
  # Statistics
  "descriptivestats_tutorial"     = "descriptive statistics, mean, median, variance, standard deviation, data distribution, outliers, summary statistics",
  "basicstatz"                    = "inferential statistics, t-test, chi-square, correlation, p-values, hypothesis testing, null hypothesis, frequentist statistics",
  "anova"                         = "ANOVA, MANOVA, ANCOVA, analysis of variance, factorial design, repeated measures, effect size, eta squared, experimental design",
  "regression_concepts"           = "regression analysis, ordinary least squares, OLS, linear regression, model assumptions, coefficients, R-squared, model selection",
  "regression"                    = "regression analysis, linear regression, logistic regression, ordinal regression, model diagnostics, lm, glm, R programming",
  "mixedmodel"                    = "mixed-effects models, random effects, fixed effects, lme4, hierarchical data, repeated measures, contrast coding, Simpson's paradox, nlme",
  "sem"                           = "structural equation modelling, SEM, confirmatory factor analysis, CFA, lavaan, path diagrams, latent variables, model fit, RMSEA, CFI",
  "tree"                          = "decision trees, random forests, machine learning, variable importance, classification, ensemble methods, tree-based models",
  "clust"                         = "cluster analysis, hierarchical clustering, k-means, correspondence analysis, unsupervised learning, data clustering, multivariate analysis",
  "lexsim"                        = "lexical similarity, string distance, edit distance, Levenshtein, Jaccard similarity, cosine similarity, text comparison",
  "semanticvectors_tutorial"      = "semantic vector space, distributional semantics, word similarity, co-occurrence matrix, vector space model, computational semantics",
  "dimensionredux_tutorial"       = "dimension reduction, PCA, principal component analysis, factor analysis, multidimensional scaling, MDS, multivariate statistics",
  "power"                         = "power analysis, sample size, effect size, statistical power, study design, pwr package, null hypothesis testing",
  "surveys"                       = "survey data, questionnaire analysis, Likert scale, ordinal data, attitude research, applied linguistics, visualisation",
  "eyetracking"                   = "eye-tracking, visual world paradigm, eyetrackingR, AOI, area of interest, fixation proportions, growth curve analysis, GAMMs, mixed-effects models, psycholinguistics",
  "phylogenetic_showcase"         = "phylogenetic methods, linguistic typology, glottoTrees, genealogical data, language families, quantitative typology, historical linguistics",
  # Text Analytics
  "introta"                       = "text analytics, computational text analysis, distant reading, text as data, NLP, digital humanities, research design",
  "textanalysis"                  = "text analysis, concordancing, word frequency, collocations, keywords, POS tagging, named entity recognition, dependency parsing, R",
  "concordancing_tutorial"        = "concordancing, KWIC, keyword in context, corpus linguistics, text search, concordance analysis, discourse analysis",
  "collocation_tutorial"          = "collocations, n-grams, association measures, PMI, log-likelihood, t-score, phraseology, lexical patterns, corpus linguistics",
  "key"                           = "keyness, keyword analysis, distinctive vocabulary, corpus comparison, log-likelihood, chi-square, contrastive analysis",
  "net"                           = "network analysis, igraph, network graphs, betweenness centrality, community detection, social network analysis, linguistic networks",
  "topic"                         = "topic modelling, LDA, latent Dirichlet allocation, text mining, distant reading, topic discovery, document clustering",
  "sentiment"                     = "sentiment analysis, polarity, NRC lexicon, emotion analysis, opinion mining, lexicon-based sentiment, affective computing",
  "postag"                        = "part-of-speech tagging, POS tagging, dependency parsing, udpipe, grammatical annotation, NLP, morphological analysis",
  "embeddings"                    = "word embeddings, word2vec, GloVe, fastText, distributional semantics, vector semantics, semantic change, bias detection",
  "txtsum"                        = "text summarisation, extractive summarisation, TextRank, automatic summarisation, sentence scoring, document summarisation",
  "spellcheck"                    = "spell checking, spelling correction, OCR errors, custom dictionaries, text cleaning, noisy text, historical corpora",
  "ollamar"                       = "large language models, LLM, Ollama, ollamar, local AI, privacy-preserving NLP, text generation, prompt engineering",
  "localllm_showcase"             = "large language models, LLM, Ollama, synthetic data, privacy-preserving research, sensitive data, clinical linguistics, data proxy, synthpop",
  "rbert"                         = "BERT, RoBERTa, transformers, large language models, sentiment analysis, named entity recognition, question answering, text classification, reticulate, huggingface",
  "deeplearning_tutorial"         = "deep learning, recurrent neural networks, LSTM, TensorFlow, Keras, text generation, sequence modelling, neural networks, R programming",
  # Case Studies / Showcases
  "atap_docclass"                 = "document classification, machine learning, political speeches, text classification, feature extraction, ATAP, supervised learning",
  "corpuslinguistics_showcase"    = "corpus linguistics, frequency analysis, dispersion, corpus comparison, quanteda, research workflow, case study",
  "llr"                           = "learner language, learner corpus, second language acquisition, SLA, error analysis, interlanguage, applied linguistics",
  "lex"                           = "lexicography, dictionary creation, computational lexicography, semantic similarity, synonyms, lexical resources",
  "vowelchart"                    = "vowel chart, acoustic phonetics, formants, F1, F2, Praat, vowel space, phonetics, sociolinguistics, vowel normalisation",
  "litsty"                        = "literary stylistics, stylometry, authorship attribution, digital humanities, computational stylistics, literary analysis, style",
  "reinfnlp"                      = "reinforcement learning, NLP, text summarisation, reward functions, machine learning, advanced NLP, computational linguistics",
  "topicmodel_showcase"           = "topic modelling, STM, structural topic model, Charles Dickens, literary corpus, digital humanities, corpus linguistics, computational stylistics",
  "conceptualmaps_showcase"       = "conceptual maps, semantic networks, t-SNE, UMAP, word embeddings, network layout, corpus linguistics, computational semantics",
  "corpuscompilation_tutorial"    = "corpus compilation, data collection, corpus design, text cleaning, metadata, corpus linguistics, research methods, ethics",
  # How-Tos
  "pdf2txt"                       = "PDF extraction, OCR, optical character recognition, text extraction, digitisation, PDF processing, corpus building",
  "notebooks"                     = "R Markdown, reproducible reports, literate programming, Quarto, dynamic documents, code documentation, research reporting",
  "publish"                       = "bookdown, online books, GitHub Pages, open access publishing, course books, R Markdown, academic publishing",
  "jupyter"                       = "Jupyter notebooks, interactive notebooks, Binder, teaching materials, reproducible research, Python, computational notebooks",
  "gutenberg"                     = "Project Gutenberg, literary corpus, public domain, corpus building, gutenbergr, text download, historical texts, digital humanities",
  "webscraping"                   = "web scraping, rvest, xml2, HTML parsing, data collection, online text, robots.txt, web data",
  "speechprocessing"              = "speech processing, automatic speech recognition, ASR, audio analysis, phonetics, R programming, signal processing"
)

# ── Descriptions for tutorials likely missing them ────────────────────────
DESCRIPTIONS <- list(
  "speechprocessing"           = "This tutorial introduces speech processing in R, covering automatic speech recognition (ASR), audio file handling, feature extraction from speech signals, and the use of R packages for phonetic analysis. It is aimed at researchers in phonetics, linguistics, and digital humanities who want to apply computational methods to spoken language data.",
  "webscraping"                = "This tutorial introduces web scraping in R using the rvest and xml2 packages, covering HTML structure, CSS selectors, navigating multi-page websites, handling pagination, and storing scraped text and data for downstream analysis. It is aimed at researchers in corpus linguistics and digital humanities who want to collect text data from websites programmatically.",
  "motion"                     = "This tutorial introduces interactive data visualisation in R using plotly, gganimate, leaflet, and DT, covering interactive charts, animated graphics, interactive maps, and interactive tables, with a focus on practical application to linguistic data. It is aimed at researchers in linguistics and digital humanities who want to create engaging, shareable visualisations beyond static figures.",
  "rbert"                      = "This tutorial introduces BERT (Bidirectional Encoder Representations from Transformers) and RoBERTa (Robustly Optimised BERT Pretraining Approach) and demonstrates how to apply them to NLP tasks in R, including sentiment analysis, named entity recognition, question answering, and custom text classification. It covers the conceptual architecture of both models, the two main R interfaces (text and reticulate), R's dependence on Python for transformer inference, and hands-on workflows for five core tasks.",
  "deeplearning_tutorial"      = "This tutorial introduces deep learning with R, focusing on Recurrent Neural Networks (RNNs) and Long Short-Term Memory (LSTM) networks using the Keras interface to TensorFlow. It covers core concepts of deep learning architecture, the vanishing gradient problem and how LSTMs solve it, and applied examples relevant to language and text data including sequence classification and text generation. It is aimed at researchers in computational linguistics and digital humanities with existing knowledge of machine learning.",
  "phylogenetic_showcase"      = "This showcase tutorial demonstrates genealogically-sensitive statistical methods for linguistic typology in R, covering the ACL and BM methods for computing phylogenetically-weighted proportions and averages, constructing and manipulating linguistic family trees with glottoTrees, and a complete worked example reproducing a published typological study across 496 languages. It is aimed at researchers in quantitative typology and historical linguistics.",
  "topicmodel_showcase"        = "This showcase tutorial demonstrates an iterative Structural Topic Model (STM) workflow applied to the complete novels of Charles Dickens, covering corpus compilation from Project Gutenberg, POS tagging with udpipe for proper noun removal, chunk-size experimentation, and the interpretation of topics in relation to social criticism and literary realism. It is aimed at researchers in digital humanities and computational stylistics.",
  "conceptualmaps_showcase"    = "This showcase tutorial compares six semantic network layout algorithms applied to the COOEE corpus of Australian historical letters, including t-SNE, igraph Fruchterman-Reingold, igraph DRL, ForceAtlas2, UMAP, and textplot GML, using a word2vec semantic space trained with wordVectors. It is aimed at researchers in corpus linguistics and computational semantics who want to understand the strengths and limitations of different approaches to visualising semantic structure.",
  "corpuscompilation_tutorial" = "This tutorial introduces the principles and practical techniques for compiling a corpus in R, covering the complete workflow from research design through data collection, cleaning, formatting, and metadata organisation. It emphasises the consequential nature of corpus design decisions and provides hands-on experience with R tools for automating and documenting the compilation process. It is aimed at researchers in corpus linguistics and digital humanities who want a rigorous, step-by-step framework for building well-designed, consistently formatted text collections ready for downstream linguistic analysis.",
  "workingwithr"               = "This tutorial covers core R programming concepts including conditional logic, for and while loops, custom functions, the apply family of functions, functional programming with purrr, and error handling with tryCatch. It is aimed at researchers in linguistics and the humanities who want to move beyond basic R usage and write reusable, automated analysis pipelines.",
  "r_reproducibility"          = "This tutorial covers reproducibility practices in R, including R Markdown and Quarto for creating reproducible reports, version control with Git, and using R Projects for organised, portable research workflows. It is aimed at researchers in linguistics and the humanities who want to align their computational work with open science standards.",
  "notebooks"                  = "This tutorial introduces the creation of reproducible analysis documents in R using R Markdown, covering document formatting, the integration of code and narrative text, and the export of documents to multiple formats including HTML, PDF, and Word. It is aimed at researchers in linguistics and the humanities who want to document their analyses in a transparent and reproducible way.",
  "publish"                    = "This tutorial covers the creation and publication of free online books using the bookdown package in R, including chapter organisation, cross-referencing, and deployment to GitHub Pages. It is aimed at researchers and educators in linguistics and the humanities who want to publish course books, long-form documentation, or research monographs as open-access online resources.",
  "jupyter"                    = "This tutorial introduces the creation of interactive Jupyter notebooks that combine R code, visualisations, and narrative text, covering setup, notebook structure, and deployment via GitHub and Binder for sharing interactive computational content. It is aimed at researchers and educators in linguistics and digital humanities who want to create interactive teaching materials or reproducible research notebooks.",
  "gutenberg"                  = "This tutorial demonstrates how to download and process public domain texts from Project Gutenberg programmatically in R using the gutenbergr package, covering text search, batch downloading, and the cleaning of Gutenberg-specific formatting for use in corpus analysis. It is aimed at researchers in digital humanities and corpus linguistics who want to build literary corpora from freely available historical texts.",
  "simulate"                   = "This tutorial introduces data simulation in R from first principles, covering pseudo-random number generation, sampling from distributions relevant to linguistics, and the assembly of realistic synthetic datasets for a wide range of research applications. It goes beyond power analysis to demonstrate advanced simulation workflows including correlated predictors, sociolinguistic variation, missing data, longitudinal trajectories, and formal power analysis. It is aimed at researchers in quantitative linguistics and the social sciences who want to verify statistical models or create reproducible examples without distributing sensitive data.",
  "eyetracking"                = "This tutorial introduces the complete workflow for processing and analysing eye-tracking data in R, covering data loading, area-of-interest (AOI) coding, binning, cleaning, and statistical analysis using eyetrackingR, mixed-effects models, and Generalised Additive Mixed Models (GAMMs). It uses a synthetic dataset modelled on a visual world paradigm experiment and is aimed at researchers in psycholinguistics and language acquisition.",
  "surveys"                    = "This case study tutorial demonstrates how to analyse and visualise survey and questionnaire data in R, covering Likert scale analysis, the visualisation of categorical and ordinal data, and statistical testing for survey responses. It is aimed at researchers in linguistics, applied linguistics, and the social sciences who collect attitudinal or opinion data using surveys.",
  "vowelchart"                 = "This showcase tutorial demonstrates how to create vowel charts in R from acoustic phonetics data, covering the extraction of formant data from Praat, the processing and normalisation of F1/F2 values, and the creation of publication-quality vowel space visualisations for comparing speakers or language varieties. It is aimed at researchers in phonetics and sociolinguistics who work with acoustic data.",
  "litsty"                     = "This case study tutorial demonstrates computational literary stylistics in R, covering stylometric analysis, authorship attribution, the measurement and comparison of literary style, and the visualisation of stylistic features across authors and texts. It is aimed at researchers in digital humanities and literary studies who want to apply computational methods to questions of style and authorship.",
  "atap_docclass"              = "This case study tutorial demonstrates a complete document classification workflow in R, using American political speeches as a case study to show how to extract text features, train machine learning classifiers, evaluate model performance, and interpret results. It was created in collaboration with the Australian Text Analytics Platform (ATAP) and is aimed at researchers in computational linguistics and digital humanities.",
  "webscraping"                = "This tutorial introduces web scraping in R using the rvest and xml2 packages, covering HTML structure, CSS selectors, navigating multi-page websites, handling pagination, and storing scraped text and data for downstream analysis. It is aimed at researchers in corpus linguistics and digital humanities who want to collect text data from websites programmatically."
)

# ── Helper: check if a version string is date-style (YYYY.MM.DD) ──────────
is_date_version <- function(v) {
  grepl("^[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}$", trimws(v))
}

# ── Helper: convert YYYY.MM.DD version to YYYY-MM-DD date ─────────────────
version_to_date <- function(v) {
  v <- trimws(v)
  if (is_date_version(v)) {
    gsub("\\.", "-", v)
  } else {
    TODAY
  }
}

# ── Helper: get value of a params field from lines ────────────────────────
get_param <- function(lines, field) {
  pat <- paste0("^\\s+", field, ":\\s*(.*)$")
  idx <- grep(pat, lines)
  if (length(idx) == 0) return(NULL)
  m <- regmatches(lines[idx[1]], regexec(pat, lines[idx[1]]))[[1]]
  trimws(gsub('^["\']|["\']$', "", m[2]))
}

# ── Helper: check if a params field exists and is non-empty ───────────────
param_exists_nonempty <- function(lines, field) {
  val <- get_param(lines, field)
  !is.null(val) && nchar(val) > 0
}

# ── Helper: check if a params field exists at all ─────────────────────────
param_exists <- function(lines, field) {
  pat <- paste0("^\\s+", field, ":")
  any(grepl(pat, lines))
}

# ── Helper: replace or insert a params field ──────────────────────────────
# If the field exists, replaces its value.
# If not, inserts it after the `after_field` field.
set_param <- function(lines, field, value, after_field = NULL) {
  pat     <- paste0("^(\\s+", field, ":\\s*).*$")
  new_line <- paste0('  ', field, ':       "', value, '"')

  idx <- grep(pat, lines)
  if (length(idx) > 0) {
    lines[idx[1]] <- new_line
  } else if (!is.null(after_field)) {
    after_pat <- paste0("^\\s+", after_field, ":")
    after_idx <- grep(after_pat, lines)
    if (length(after_idx) > 0) {
      lines <- c(
        lines[1:after_idx[1]],
        new_line,
        lines[(after_idx[1] + 1):length(lines)]
      )
    } else {
      # If after_field not found, append before closing ---
      params_end <- grep("^---$", lines)
      if (length(params_end) >= 2) {
        ins <- params_end[2] - 1
        lines <- c(lines[1:ins], new_line, lines[(ins + 1):length(lines)])
      }
    }
  }
  lines
}

# ── Main processing loop ───────────────────────────────────────────────────

all_qmds <- list.files(TUTORIALS_DIR, pattern = "\\.qmd$",
                        recursive = TRUE, full.names = TRUE)

cat("============================================================\n")
cat("LADAL Tutorial Params Updater\n")
cat(sprintf("Processing %d tutorial .qmd files\n", length(all_qmds)))
cat("============================================================\n\n")

log <- data.frame(
  file            = character(0),
  version_updated = logical(0),
  date_added      = logical(0),
  keywords_added  = logical(0),
  desc_added      = logical(0),
  doi_added       = logical(0),
  stringsAsFactors = FALSE
)

for (qmd_path in all_qmds) {

  rel_path    <- sub(paste0(here(), "/"), "", qmd_path)
  folder_name <- basename(dirname(qmd_path))
  lines       <- readLines(qmd_path, warn = FALSE)
  original    <- lines
  changed     <- FALSE

  # Find params block boundaries
  yaml_delims  <- which(trimws(lines) == "---")
  if (length(yaml_delims) < 2) next
  params_start <- grep("^params:", lines)
  if (length(params_start) == 0) next

  # ── 1. Version: only update if date-style ───────────────────────────────
  version_updated <- FALSE
  current_version <- get_param(lines, "version")
  if (!is.null(current_version) && is_date_version(current_version)) {
    lines           <- set_param(lines, "version", NEW_VERSION)
    version_updated <- TRUE
    changed         <- TRUE
  }

  # ── 2. date_published: derive from old version, add if missing ──────────
  date_added <- FALSE
  if (!param_exists(lines, "date_published")) {
    # Use the original version string (before we changed it) to get the date
    date_val <- if (!is.null(current_version)) {
      version_to_date(current_version)
    } else {
      TODAY
    }
    lines      <- set_param(lines, "date_published", date_val,
                             after_field = "version")
    date_added <- TRUE
    changed    <- TRUE
  }

  # ── 3. year: add if missing ──────────────────────────────────────────────
  if (!param_exists(lines, "year")) {
    lines   <- set_param(lines, "year", NEW_YEAR, after_field = "author")
    changed <- TRUE
  }

  # ── 4. keywords: insert if missing or empty ──────────────────────────────
  keywords_added <- FALSE
  if (!param_exists_nonempty(lines, "keywords")) {
    kw <- KEYWORDS[[folder_name]]
    if (!is.null(kw) && nchar(kw) > 0) {
      lines          <- set_param(lines, "keywords", kw,
                                   after_field = "description")
      keywords_added <- TRUE
      changed        <- TRUE
    }
  }

  # ── 5. description: insert if missing or empty ───────────────────────────
  desc_added <- FALSE
  if (!param_exists_nonempty(lines, "description")) {
    desc <- DESCRIPTIONS[[folder_name]]
    if (!is.null(desc) && nchar(desc) > 0) {
      lines      <- set_param(lines, "description", desc,
                               after_field = "institution")
      desc_added <- TRUE
      changed    <- TRUE
    } else if (!param_exists(lines, "description")) {
      # Insert empty placeholder so field exists
      lines   <- set_param(lines, "description", "",
                            after_field = "institution")
      changed <- TRUE
    }
  }

  # ── 6. doi: add empty field if completely missing ─────────────────────────
  doi_added <- FALSE
  if (!param_exists(lines, "doi")) {
    lines     <- set_param(lines, "doi", "", after_field = "keywords")
    doi_added <- TRUE
    changed   <- TRUE
  }

  # ── Write back if changed ────────────────────────────────────────────────
  if (changed) {
    writeLines(lines, qmd_path)
    cat(sprintf("  UPDATED  %s\n", rel_path))
    if (version_updated) cat("           version -> 3.1.1\n")
    if (date_added)      cat(sprintf("           date_published -> %s\n",
                               version_to_date(current_version %||% "")))
    if (keywords_added)  cat("           keywords added\n")
    if (desc_added)      cat("           description added\n")
    if (doi_added)       cat("           doi field added\n")
  }

  log <- rbind(log, data.frame(
    file            = rel_path,
    version_updated = version_updated,
    date_added      = date_added,
    keywords_added  = keywords_added,
    desc_added      = desc_added,
    doi_added       = doi_added,
    stringsAsFactors = FALSE
  ))
}

# ── Summary ──────────────────────────────────────────────────────────────

`%||%` <- function(a, b) if (!is.null(a) && nchar(as.character(a)) > 0) a else b

cat("\n============================================================\n")
cat("SUMMARY\n")
cat("============================================================\n\n")
cat(sprintf("  Total tutorials scanned:    %d\n",  nrow(log)))
cat(sprintf("  Versions updated to 3.1.1: %d\n",  sum(log$version_updated)))
cat(sprintf("  date_published added:       %d\n",  sum(log$date_added)))
cat(sprintf("  keywords added:             %d\n",  sum(log$keywords_added)))
cat(sprintf("  descriptions added:         %d\n",  sum(log$desc_added)))
cat(sprintf("  doi fields added:           %d\n",  sum(log$doi_added)))

# Report tutorials still missing keywords or description
missing_kw   <- log$file[!log$keywords_added &
                 sapply(log$file, function(f) {
                   folder <- basename(dirname(file.path(here(), f)))
                   is.null(KEYWORDS[[folder]])
                 })]
missing_desc <- log$file[!log$desc_added &
                 sapply(log$file, function(f) {
                   folder <- basename(dirname(file.path(here(), f)))
                   is.null(DESCRIPTIONS[[folder]])
                 })]

if (length(missing_kw) > 0) {
  cat("\n  Tutorials with NO keywords in database (add manually):\n")
  for (f in missing_kw) cat(sprintf("    - %s\n", f))
}
if (length(missing_desc) > 0) {
  cat("\n  Tutorials with NO description in database (add manually):\n")
  for (f in missing_desc) cat(sprintf("    - %s\n", f))
}

cat("\n  Done. Re-render with quarto::quarto_render() when ready.\n\n")

# Save log
log_path <- here("helpers", "params_update_log.csv")
write.csv(log, log_path, row.names = FALSE)
cat(sprintf("  Full log saved to: %s\n\n", log_path))
