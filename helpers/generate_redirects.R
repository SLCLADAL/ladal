# Github pages doesn't support any easy way to generate standard redirects, so
# unfortunately we're going to have to redirect from the original flat URLs to the new
# canonical URLs with a JS redirect.

# ── Standard redirects ────────────────────────────────────────────
# These assume the tutorial folder name and file name are identical,
# e.g. docs/kwics.html → https://ladal.edu.au/tutorials/kwics/kwics.html

to_redirect <- c(
  "atap_docclass",
  "comp",
  "gutenberg",
  "key",
  "litsty",
  "pdf2txt",
  "reinfnlp",
  "surveys",
  "tree",
  "basicquant",
  "corplingr",
  "introquant",
  "kwics",
  "llr",
  "postag",
  "repro",
  "svm",
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
  "dstats",
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
  # Note: "vc" and "coll" removed — handled below as renamed tutorials
)

template_start <- "
<html>
	<head>
		<script>
			window.location.replace(\"https://ladal.edu.au/tutorials/"
template_end <- ".html\");
		</script>
	</head>
</html>
"

for (folder in to_redirect) {
  output_path <- paste("docs/", folder, ".html", sep="")
  output_content <- paste(template_start, folder, "/", folder, template_end, sep="")
  cat(output_content, file=output_path)
}

# ── Renamed tutorial redirects ────────────────────────────────────
# Format: old_name = new_folder/new_file
# e.g. docs/vc.html → https://ladal.edu.au/tutorials/vowelchart/vowelchart.html

renamed_tutorials <- list(
  "vc"   = "vowelchart/vowelchart",
  "coll" = "collocation_tutorial/collocation_tutorial",
  "svm" = "semanticvectors_tutorial/semanticvectors_tutorial",
  "comp" = "workingwithcomputers_tutorial/workingwithcomputers_tutorial",
  "dstats" = "descriptivestats_tutorial/descriptivestats_tutorial",
  "corplingr" = "corpuslinguistics_showcase/corpuslinguistics_showcase"
)

for (old_name in names(renamed_tutorials)) {
  new_path     <- renamed_tutorials[[old_name]]
  output_path  <- paste("docs/", old_name, ".html", sep="")
  output_content <- paste(
    "\n<html>\n\t<head>\n\t\t<script>\n\t\t\twindow.location.replace(\"https://ladal.edu.au/tutorials/",
    new_path,
    ".html\");\n\t\t</script>\n\t</head>\n</html>\n",
    sep=""
  )
  cat(output_content, file=output_path)
}
