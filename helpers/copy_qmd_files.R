# Copy the .qmd files to the docs directory after rendering.
# Quarto doesn't do this by default :(

to_copy <- list.files("tutorials", "*.qmd", recursive =TRUE)

warnings()

for (qmd_file in to_copy) {
	src = file.path("tutorials", qmd_file)
	target = file.path("docs", "tutorials", qmd_file)
	file.copy(src, target)
}


