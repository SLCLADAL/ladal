# Github pages doesn't support any easy way to generate standard redirects, so
# unfortunately we're going to have to redirect from the original flat URLs to the new
# canonical URLs with a JS redirect.


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
	"vc",
	"clust",
	"dstats",
	"introta",
	"lex",
	"motion",
	"regex",
	"spellcheck",
	"textanalysis",
	"whyr",
	"coll",
	"dviz",
	"introviz",
	"lexsim",
	"net",
	"regression",
	"string",
	"topic"
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
	output_content <- paste(template_start, folder, template_end, sep="")

	cat(output_content, file=output_path)

}


