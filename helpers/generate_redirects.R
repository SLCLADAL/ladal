# Github pages doesn't support any easy way to generate standard redirects, so
# unfortunately we're going to have to redirect from the original flat URLs to the new
# canonical URLs with a JS redirect.

# ── Helper: write a redirect HTML file ───────────────────────────────────────
# Creates any necessary subdirectories automatically.

write_redirect <- function(output_path, destination_url) {
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  content <- paste0(
    "<!DOCTYPE html>\n<html>\n\t<head>\n\t\t<script>\n\t\t\t",
    "window.location.replace(\"", destination_url, "\");\n\t\t</script>\n",
    "\t</head>\n</html>\n"
  )
  cat(content, file = output_path)
}

# ── Section 1: Standard tutorial redirects ───────────────────────────────────
# Flat docs/[name].html → https://ladal.edu.au/tutorials/[name]/[name].html
# Assumes folder name and file name are identical.
# Note: tutorials also in the renamed list below are excluded here to avoid
# redundancy (the renamed version takes precedence).

to_redirect <- c(
  "atap_docclass",
  "gutenberg",
  "key",
  "litsty",
  "pdf2txt",
  "reinfnlp",
  "surveys",
  "tree",
  "basicquant",
  "introquant",
  "kwics",
  "llr",
  "postag",
  "repro",
  "txtsum",
  "basicstatz",
  "dimred",
  "intror",
  "laegs",
  "load",
  "pwr",
  "sentiment",
  "table",
  "clust",
  "introta",
  "lex",
  "motion",
  "regex",
  "spellcheck",
  "textanalysis",
  "whyr",
  "dviz",
  "introviz",
  "lexsim",
  "net",
  "regression",
  "string",
  "topic"
  # Note: "vc", "coll", "svm", "comp", "dstats", "corplingr" removed here
  # — handled below in renamed_tutorials
)

for (folder in to_redirect) {
  write_redirect(
    output_path     = paste0("docs/", folder, ".html"),
    destination_url = paste0("https://ladal.edu.au/tutorials/", folder, "/", folder, ".html")
  )
}

# ── Section 2: Renamed tutorial redirects ────────────────────────────────────
# docs/[old_name].html → https://ladal.edu.au/tutorials/[new_folder]/[new_file].html

renamed_tutorials <- list(
  "vc"        = "vowelchart/vowelchart",
  "coll"      = "collocation_tutorial/collocation_tutorial",
  "svm"       = "semanticvectors_tutorial/semanticvectors_tutorial",
  "comp"      = "workingwithcomputers_tutorial/workingwithcomputers_tutorial",
  "dstats"    = "descriptivestats_tutorial/descriptivestats_tutorial",
  "corplingr" = "corpuslinguistics_showcase/corpuslinguistics_showcase"
)

for (old_name in names(renamed_tutorials)) {
  write_redirect(
    output_path     = paste0("docs/", old_name, ".html"),
    destination_url = paste0("https://ladal.edu.au/tutorials/", renamed_tutorials[[old_name]], ".html")
  )
}

# ── Section 3: 404 fixes ─────────────────────────────────────────────────────
# These address URLs that Google has indexed but no longer exist.
# Each entry is: output path (relative to repo root) = destination URL

fixes_404 <- list(
  
  # Old flat tutorial URLs that moved to subfolders
  "docs/tutorials/ngrams/ngrams.html"              = "https://ladal.edu.au/tutorials/coll/coll.html",
  "docs/tutorials/textanalysis/textanalysis2.html" = "https://ladal.edu.au/tutorials/textanalysis/textanalysis.html",
  "docs/tutorials/keywords/keywords.html"          = "https://ladal.edu.au/tutorials/key/key.html",
  "docs/tutorials/statistics/statistics.html"      = "https://ladal.edu.au/tutorials/basicstatz/basicstatz.html",
  "docs/tutorials/embeddings.html"                 = "https://ladal.edu.au/tutorials/embeddings/embeddings.html",
  "docs/tutorials/atap_docclass.html"              = "https://ladal.edu.au/tutorials/atap_docclass/atap_docclass.html",
  "docs/tutorials/textanalysis.html"               = "https://ladal.edu.au/tutorials/textanalysis/textanalysis.html",
  "docs/tutorials/svm.html"                        = "https://ladal.edu.au/tutorials/svm/svm.html",
  "docs/tutorials/reinfnlp.html"                   = "https://ladal.edu.au/tutorials/reinfnlp/reinfnlp.html",
  "docs/tutorials/repro.html"                       = "https://ladal.edu.au/tutorials/repro/repro.html",
  "docs/tutorials/txtsum.html"                     = "https://ladal.edu.au/tutorials/txtsum/txtsum.html",
  "docs/tutorials/clust.html"                      = "https://ladal.edu.au/tutorials/clust/clust.html",
  "docs/tutorials/tree.html"                       = "https://ladal.edu.au/tutorials/tree/tree.html",
  "docs/tutorials/regression.html"                 = "https://ladal.edu.au/tutorials/regression/regression.html",
  "docs/tutorials/comp.html"                       = "https://ladal.edu.au/tutorials/comp/comp.html",
  "docs/tutorials/reinfnlp/intror.html"            = "https://ladal.edu.au/tutorials/intror/intror.html",
  
  # Old .Rmd and content file URLs → corresponding HTML tutorial page
  "docs/tutorials/surveys/surveys.Rmd"             = "https://ladal.edu.au/tutorials/surveys/surveys.html",
  "docs/content/introviz.Rmd"                      = "https://ladal.edu.au/tutorials/introviz/introviz.html",
  "docs/content/kwics.Rmd"                         = "https://ladal.edu.au/tutorials/kwics/kwics.html",
  "docs/content/dviz.Rmd"                          = "https://ladal.edu.au/tutorials/dviz/dviz.html",
  "docs/content/clust.Rmd"                         = "https://ladal.edu.au/tutorials/clust/clust.html",
  
  # Retired or renamed top-level pages → best current equivalent
  "docs/topicmodels.html"                          = "https://ladal.edu.au/tutorials/topic/topic.html",
  "docs/news.html"                                 = "https://ladal.edu.au/events.html",
  "docs/phylo.html"                                = "https://ladal.edu.au/tutorials.html",
  "docs/gviz.html"                                 = "https://ladal.edu.au/tutorials/introviz/introviz.html",
  "docs/tagging.html"                              = "https://ladal.edu.au/tutorials/postag/postag.html",
  "docs/webcrawling.html"                          = "https://ladal.edu.au/tutorials.html",
  "docs/compthink.html"                            = "https://ladal.edu.au/tutorials/introquant/introquant.html",
  "docs/compthinking.html"                         = "https://ladal.edu.au/tutorials/introquant/introquant.html",
  
  # Data and resource files → closest relevant tutorial
  "docs/data/PDFs/pdf3.pdf"                        = "https://ladal.edu.au/tutorials/pdf2txt/pdf2txt.html",
  "docs/assets/bibliography.bib"                   = "https://ladal.edu.au/about.html",
  "docs/resources/stopwords_en.txt"                = "https://ladal.edu.au/tutorials/topic/topic.html",
  
  # Malformed URL
  "docs/www.ladal.edu.au"                          = "https://ladal.edu.au"
)

for (output_path in names(fixes_404)) {
  write_redirect(
    output_path     = output_path,
    destination_url = fixes_404[[output_path]]
  )
}

message(
  "Redirects written: ",
  length(to_redirect), " standard + ",
  length(renamed_tutorials), " renamed + ",
  length(fixes_404), " 404 fixes"
)