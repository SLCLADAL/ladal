# Overview and Setup

LADAL materials are written and rendered using [Quarto](https://quarto.org/). This is a system that can take and run computational documents and markdown files in many formats into the HTML pages in the site. In order to contribute you will need to have the following installed:

- [Quarto](https://quarto.org/)
- the [R programming language](r-project.org) 
- If you're making changes to computational content, an interactive editor that is aware of the notebook format, like [RStudio](https://posit.co/downloads/) will make your life a lot easier. 

The main content for the site is rendered from the `.qmd` (Quarto-Markdown) files in the root directory, and the subfolders (one per tutorial) in the `tutorials` directory. Each tutorial should be self-contained in its folder, with one `.qmd` file representing the content of that tutorial to be rendered to HTML, and all associated materials (such as data) in that tutorial's folder. 

The configuration for Quarto is in `_quarto.yml` file in the root of the repository and is used to drive all rendering and other decisions about the whole of the site. Note in particular:

- for consistency, rendering is done in the `project` context: all paths should be relative to the root of the repository
- all subfolders under `tutorials` are built by default

The `docs` folder contains the output HTML files to be served as the website.

All other folders are used for ancillary materials like utility scripts and references, or site assets that are used across all pages like CSS, header images and other assets.

Note that a lot of the material has been written and edited over time, so not everything is consistent with these principles.

# Workflow for Making Changes

LADAL is hosted on Github Pages, which is configured to serve everything under `docs/` as the site. To make content visible on the web you need to:

1. Edit the appropriate source file. For example to edit https://ladal.edu.au/tutorials/regression/regression.html you would need to find and change the corresponding `.qmd` at `tutorials/regression/regression.qmd`.
2. Render the notebook, using either Quarto via the command line or using RStudio's inbuilt render button.
3. Using git, checkin and push the changes to both the *source* file you edited, and the corresponding *output* changes in the `docs` directory.


# Rendering Pages from the Command Line

The whole site, or individual pages, can be re-rendered by running quarto from the root of the repository:

```bash
# Render everything
quarto render

# Render just the tutorials folder
quarto render tutorials

# Render a specific tutorial
quarto render tutorials/regression

```

This assumes that all R dependencies have already been installed, otherwise the render will fail.

