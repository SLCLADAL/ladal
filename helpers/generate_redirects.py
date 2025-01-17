"""
Github pages doesn't support any easy way to generate standard redirects, so
unfortunately we're going to have to redirect from the original flat URLs to the new
canonical URLs with a JS redirect.

"""

import os


to_redirect = [
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
	"topic",
]


template = """
<html>
	<head>
		<script>
			window.location.replace("https://ladal.edu.au/tutorials/{}.html");
		</script>
	</head>
</html>
"""


for folder in to_redirect:

	output_path = os.path.join("docs", f"{folder}.html")

	with open(output_path, 'w') as redirect_file:
		redirect_file.write(template.format(folder))

