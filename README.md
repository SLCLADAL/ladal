![LADAL banner](/images/uq1.jpg)

# LADAL — Language Technology and Data Analysis Laboratory

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.XXXXXXX.svg)](https://doi.org/10.5281/zenodo.XXXXXXX)
[![GitHub Pages](https://img.shields.io/badge/site-ladal.edu.au-51247A)](https://ladal.edu.au)
[![Part of LDaCA](https://img.shields.io/badge/part%20of-LDaCA-00A2C7)](https://ldaca.edu.au)
[![University of Queensland](https://img.shields.io/badge/institution-UQ-51247A)](https://www.uq.edu.au)

**[ladal.edu.au](https://ladal.edu.au)** &nbsp;·&nbsp; 1.1M+ page views &nbsp;·&nbsp; 500K+ users &nbsp;·&nbsp; 100+ countries &nbsp;·&nbsp; Est. 2019

---

## Table of Contents

- [Overview](#overview)
- [What LADAL Offers](#what-ladal-offers)
- [Who LADAL is For](#who-ladal-is-for)
- [Tutorial Collection](#tutorial-collection)
- [Courses](#courses)
- [Interactive Tools](#interactive-tools)
- [Repository Structure](#repository-structure)
- [Technical Stack](#technical-stack)
- [Getting Started (Local Development)](#getting-started-local-development)
- [Contributing](#contributing)
- [Citation](#citation)
- [Contributors](#contributors)
- [Affiliated Infrastructure](#affiliated-infrastructure)
- [Licence](#licence)
- [Contact](#contact)

---

## Overview

LADAL (pronounced *lah'dahl*) is a free, open-access research infrastructure providing tutorials, interactive tools, and structured courses for anyone working with language data. Established in 2019 by the [School of Languages and Cultures](https://languages-cultures.uq.edu.au/) at the [University of Queensland](https://www.uq.edu.au/), LADAL is part of the [Language Data Commons of Australia (LDaCA)](https://ldaca.edu.au) — Australia's largest language data infrastructure project in the humanities and social sciences.

LADAL is funded through LDaCA, a co-investment partnership with the [Australian Research Data Commons (ARDC)](https://ardc.edu.au) through the HASS and Indigenous Research Data Commons, enabled by the Australian Government's National Collaborative Research Infrastructure Strategy (NCRIS).

**No programming experience required** — LADAL is designed from the ground up to be accessible to complete beginners while remaining a useful reference for expert researchers.

---

## What LADAL Offers

### 📖 Tutorials
57 comprehensive, step-by-step tutorials covering data science, statistics, text analytics, and computational linguistics. All tutorials include fully runnable R code, downloadable scripts, and browser-based Jupyter notebooks so you can follow along without installing anything. Tutorials are peer-reviewed, regularly updated, and freely citable via individual Zenodo DOIs.

### 🎓 Courses
Structured short and long courses that organise tutorials into coherent learning pathways. Short courses (5–10 tutorials) target focused skill development; long courses (12 weeks) provide comprehensive training suitable for university teaching or self-directed study. Each course includes learning objectives, tutorial sequences, suggested readings, and practice exercises.

### 🔧 Tools
Browser-based, point-and-click text analysis tools built on Jupyter notebooks — no installation, no account, no coding required. Upload your own texts and run concordance, collocation, keyword, POS tagging, network analysis, topic modelling, and sentiment analyses directly in your browser.

### 📚 Resources
A curated guide to external tools, corpora, learning resources, conferences, and communities for language technology and text analysis — covering both free and commercial options across corpus linguistics, NLP, and digital humanities.

---

## Who LADAL is For

LADAL is designed for researchers, students, and educators in any field that involves language data:

| Audience | What LADAL offers |
|---|---|
| **Linguists** | Corpus analysis, concordancing, collocations, POS tagging, phonetics |
| **Digital humanists** | Text analytics, distant reading, network analysis, stylometry |
| **Social scientists** | Quantitative methods, survey analysis, sentiment analysis |
| **Applied linguists & SLA researchers** | Learner corpus analysis, statistical modelling, mixed-effects models |
| **Complete beginners** | Zero-prerequisite introductions to R, statistics, and text analysis |
| **Advanced researchers** | Mixed-effects models, SEM, word embeddings, transformer models |
| **Course conveners** | Ready-to-use course materials, citable tutorials, browser-based tools for students |
| **Industry practitioners** | NLP applications, text classification, topic modelling |

---

## Tutorial Collection

LADAL tutorials are organised into seven sections. All tutorials are free, open-access, and available at [ladal.edu.au/tutorials.html](https://ladal.edu.au/tutorials.html).

### Data Science Basics (5 tutorials)
Foundational concepts for digital research — no prerequisites required.

| Tutorial | Description |
|---|---|
| [Working with Computers](https://ladal.edu.au/tutorials/comp/comp.html) | File organisation, digital workflows, data storage |
| [Introduction to Data Management](https://ladal.edu.au/tutorials/datamanage/datamanage.html) | Folder structures, file naming, documentation |
| [Reproducible Research](https://ladal.edu.au/tutorials/repro/repro.html) | Reproducibility principles, version control, workflows |
| [Introduction to Quantitative Reasoning](https://ladal.edu.au/tutorials/introquant/introquant.html) | Scientific method, quantitative thinking, critical analysis |
| [Basic Concepts in Quantitative Research](https://ladal.edu.au/tutorials/basicquant/basicquant.html) | Variables, measurements, descriptive vs inferential statistics |

### R Basics (8 tutorials)
Core programming skills in R — required foundation for all other sections.

| Tutorial | Description |
|---|---|
| [Getting Started with R](https://ladal.edu.au/tutorials/intror/intror.html) | Installation, RStudio, basic syntax ⭐ Start here |
| [Loading and Saving Data](https://ladal.edu.au/tutorials/load/load.html) | Reading/writing CSV, Excel, and text files |
| [String Processing](https://ladal.edu.au/tutorials/string/string.html) | Text manipulation with stringr |
| [Regular Expressions](https://ladal.edu.au/tutorials/regex/regex.html) | Pattern matching and advanced text search |
| [Handling Tables in R](https://ladal.edu.au/tutorials/table/table.html) | Data frames, subsetting, reshaping, merging |
| [Working with R: Control Flow, Functions & Programming](https://ladal.edu.au/tutorials/workingwithr/workingwithr.html) | Loops, conditionals, custom functions, purrr |
| [Reproducibility with R](https://ladal.edu.au/tutorials/r_reproducibility/r_reproducibility.html) | R Markdown, Git, R Projects |
| [Why R?](https://ladal.edu.au/tutorials/whyr/whyr.html) | Rationale for R in language research |

### Data Visualisation (4 tutorials)
Creating professional, publication-quality visualisations with ggplot2.

| Tutorial | Description |
|---|---|
| [Introduction to Data Visualisation](https://ladal.edu.au/tutorials/introviz/introviz.html) | ggplot2 foundations, basic plot types |
| [Mastering Data Visualisation with R](https://ladal.edu.au/tutorials/dviz/dviz.html) | Advanced techniques, faceting, interactive plots |
| [Showcase: Conceptual Maps](https://ladal.edu.au/tutorials/conceptmaps/conceptmaps.html) | Semantic similarity maps, spring-layout, community detection |
| [Showcase: Creating Typological Maps](https://ladal.edu.au/tutorials/leaflet/leaflet.html) | Interactive geographical maps with leaflet |

### Statistics (13 tutorials)
Statistical methods from descriptive to advanced modelling.

| Tutorial | Description |
|---|---|
| [Descriptive Statistics](https://ladal.edu.au/tutorials/dstats/dstats.html) | Central tendency, dispersion, distributions |
| [Basic Inferential Statistics](https://ladal.edu.au/tutorials/basicstatz/basicstatz.html) | t-tests, chi-square, correlation, p-values |
| [ANOVA, MANOVA & ANCOVA](https://ladal.edu.au/tutorials/anova/anova.html) | Group comparisons, interaction effects, effect sizes |
| [Regression Concepts](https://ladal.edu.au/tutorials/regression_concepts/regression_concepts.html) | OLS foundations, assumptions, model selection |
| [Regression Analysis in R](https://ladal.edu.au/tutorials/regression/regression.html) | Linear, logistic, ordinal regression |
| [Mixed-Effects Models](https://ladal.edu.au/tutorials/mixedmodel/mixedmodel.html) | Hierarchical data, random effects, lme4 |
| [Structural Equation Modelling](https://ladal.edu.au/tutorials/sem/sem.html) | CFA, path models, lavaan, fit indices |
| [Tree-Based Models](https://ladal.edu.au/tutorials/tree/tree.html) | Decision trees, random forests, variable importance |
| [Cluster and Correspondence Analysis](https://ladal.edu.au/tutorials/clust/clust.html) | Clustering, k-means, correspondence analysis |
| [Introduction to Lexical Similarity](https://ladal.edu.au/tutorials/lexsim/lexsim.html) | String distance, edit distance, document comparison |
| [Semantic Vector Space Models](https://ladal.edu.au/tutorials/svm/svm.html) | Distributional semantics, word similarity |
| [Dimension Reduction Methods](https://ladal.edu.au/tutorials/dimred/dimred.html) | PCA, factor analysis, MDS |
| [Power Analysis](https://ladal.edu.au/tutorials/pwr/pwr.html) | Sample size, effect sizes, study planning |

### Text Analytics (14 tutorials)
Computational text analysis from basic concordancing to advanced NLP.

| Tutorial | Description |
|---|---|
| [Introduction to Text Analysis: Concepts](https://ladal.edu.au/tutorials/introta/introta.html) | Foundations, terminology, research design |
| [Introduction to Text Analysis: Practical R](https://ladal.edu.au/tutorials/textanalysis/textanalysis.html) | Concordancing, frequency, POS tagging, NER |
| [Concordancing with R](https://ladal.edu.au/tutorials/kwics/kwics.html) | KWIC displays, search patterns, exporting |
| [Collocation and N-gram Analysis](https://ladal.edu.au/tutorials/coll/coll.html) | Association measures, phraseology |
| [Keyness and Keyword Analysis](https://ladal.edu.au/tutorials/key/key.html) | Distinctive vocabulary, corpus comparison |
| [Network Analysis](https://ladal.edu.au/tutorials/net/net.html) | Network graphs, metrics, community detection |
| [Topic Modelling](https://ladal.edu.au/tutorials/topic/topic.html) | LDA, topic interpretation, visualisation |
| [Sentiment Analysis](https://ladal.edu.au/tutorials/sentiment/sentiment.html) | Polarity, NRC emotions, lexicon-based scoring |
| [Tagging and Parsing](https://ladal.edu.au/tutorials/postag/postag.html) | POS tagging, dependency parsing, udpipe |
| [Word Embeddings and Vector Semantics](https://ladal.edu.au/tutorials/embeddings/embeddings.html) | word2vec, GloVe, semantic change |
| [Automated Text Summarisation](https://ladal.edu.au/tutorials/txtsum/txtsum.html) | Extractive summarisation, TextRank |
| [Spell Checking](https://ladal.edu.au/tutorials/spellcheck/spellcheck.html) | OCR correction, custom dictionaries |
| [Local LLMs with Ollama](https://ladal.edu.au/tutorials/ollama/ollama.html) | Running LLMs locally, ollamar package |
| [Privacy-Preserving Analysis with Local LLMs](https://ladal.edu.au/tutorials/localllm_showcase/localllm_showcase.html) | Synthetic data proxies, sensitive data workflows |

### Case Studies (8 tutorials)
Complete research workflows demonstrating how methods combine in practice.

| Tutorial | Research focus |
|---|---|
| [Classifying American Speeches](https://ladal.edu.au/tutorials/atap_docclass/atap_docclass.html) | Political speech classification |
| [Corpus Linguistics with R](https://ladal.edu.au/tutorials/corplingr/corplingr.html) | Complete corpus analysis workflows |
| [Analysing Learner Language](https://ladal.edu.au/tutorials/llr/llr.html) | Learner corpus, SLA, error analysis |
| [Lexicography and Creating Dictionaries](https://ladal.edu.au/tutorials/lex/lex.html) | Computational dictionary creation |
| [Visualising Survey Data](https://ladal.edu.au/tutorials/surveys/surveys.html) | Likert scales, questionnaire analysis |
| [Creating Vowel Charts in R](https://ladal.edu.au/tutorials/vc/vc.html) | Acoustic phonetics, formant visualisation |
| [Computational Literary Stylistics](https://ladal.edu.au/tutorials/litsty/litsty.html) | Stylometry, authorship attribution |
| [Reinforcement Learning and NLP](https://ladal.edu.au/tutorials/reinfnlp/reinfnlp.html) | RL-based text summarisation |

### How-Tos (5 tutorials)
Quick, practical guides for common tasks.

| Tutorial | Task |
|---|---|
| [Converting PDFs to Text](https://ladal.edu.au/tutorials/pdf2txt/pdf2txt.html) | PDF extraction, OCR |
| [Creating R Notebooks](https://ladal.edu.au/tutorials/notebooks/notebooks.html) | R Markdown, reproducible reports |
| [Creating eBooks with bookdown](https://ladal.edu.au/tutorials/bookdown/bookdown.html) | Online books, GitHub Pages publishing |
| [Creating Jupyter Notebooks](https://ladal.edu.au/tutorials/jupyter/jupyter.html) | Interactive notebooks, Binder |
| [Downloading from Project Gutenberg](https://ladal.edu.au/tutorials/gutenberg/gutenberg.html) | Literary corpora, public domain texts |

---

## Courses

LADAL offers structured short and long courses at [ladal.edu.au/courses.html](https://ladal.edu.au/courses.html).

### Short Courses
Focused learning sequences of 5–10 tutorials:

- Introduction to Language Technology
- Introduction to Corpus Linguistics
- Introduction to Text Analysis
- Data Visualisation for Linguists
- Introduction to Statistics
- Introduction to Learner Corpus Research
- Natural Language Processing with R

### Long Courses
Full-semester courses (12 weeks) suitable for university teaching:

- Introduction to Digital Humanities with R
- Corpus Linguistics and Text Analysis with R
- Introduction to Statistics in the Humanities
- Advanced Statistics in the Humanities

---

## Interactive Tools

LADAL provides browser-based tools at [ladal.edu.au/tools.html](https://ladal.edu.au/tools.html). No installation or account required — upload your texts and run analyses directly in your browser.

| Tool | What it does |
|---|---|
| Concordancing | KWIC displays for words or phrases |
| Collocations | Association measures and collocation statistics |
| Keywords | Over/under-represented words vs. a reference corpus |
| POS Tagging | Part-of-speech tagging for 60+ languages |
| Corpus Text Cleaning | Remove/replace words, tags, and patterns |
| Network Analysis | Generate and visualise network graphs |
| Topic Modelling | LDA topic discovery across text collections |
| Sentiment Analysis | Polarity scoring and eight basic emotion categories |

Tools are available on multiple platforms: **ATAP BinderHub** and **ARDC BinderHub** (require Australian/NZ institutional login via AAF or Tuakiri) and **mybinder.org** (open, no login required).

---

## Repository Structure

```
ladal/
├── _quarto.yml               # Site configuration — navbar, footer, theme, plugins
├── index.qmd                 # Homepage
├── about.qmd                 # About LADAL, contributors, FAQ
├── tutorials.qmd             # Tutorials index page
├── courses.qmd               # Courses page
├── tools.qmd                 # Tools page
├── events.qmd                # Events and community
├── resources.qmd             # External resources
├── contact.qmd               # Contact and contributing
├── CITATION.cff              # Machine-readable citation metadata
├── CONTRIBUTING.md           # Contributor guide
│
├── tutorials/                # Tutorial source files
│   └── [topic]/
│       └── [topic].qmd       # Individual tutorial
│
├── assets/
│   ├── custom_header.html    # Open Graph tags, banner script
│   ├── custom_footer.html    # Site footer HTML
│   └── bibliography.bib      # Shared bibliography
│
├── css/
│   └── styles.css            # Global stylesheet (UQ brand colours)
│
├── images/                   # Site images, logos, tutorial figures
├── helpers/
│   └── generate_redirects.R  # Post-render redirect generator
├── notebooks/                # Jupyter notebooks
├── rscripts/                 # Standalone R scripts
├── tools/                    # Tool source files
├── udpipemodels/             # UDPipe language models
└── docs/                     # Rendered HTML output (GitHub Pages source)
```

---

## Technical Stack

| Component | Technology |
|---|---|
| Site framework | [Quarto](https://quarto.org/) 1.6+ |
| Primary language | R (with Python tutorials in development) |
| Styling | CSS with [UQ brand palette](https://marketing-communication.uq.edu.au/brand-guidelines) |
| Hosting | GitHub Pages via `docs/` output directory |
| Domain | Custom domain via CNAME (`ladal.edu.au`) |
| Analytics | Google Analytics (`G-VSGK4KYDQZ`) |
| Interactive tools | Jupyter notebooks via ATAP BinderHub, ARDC BinderHub, mybinder.org |
| Citations | Zenodo DOIs per tutorial + platform-level CITATION.cff |
| Redirects | Custom post-render R script (`helpers/generate_redirects.R`) |

---

## Getting Started (Local Development)

### Prerequisites

- [R](https://cran.r-project.org/) ≥ 4.2
- [Quarto](https://quarto.org/docs/download/) ≥ 1.6
- [RStudio](https://posit.co/download/rstudio-desktop/) (recommended) or VS Code with Quarto extension

### Clone and render

```r
# Clone the repo
git clone https://github.com/SLCLADAL/ladal.git
cd ladal

# Install R dependencies (renv is used for package management)
install.packages("renv")
renv::restore()

# Preview the site locally
quarto preview
```

The site will be served at `http://localhost:1234` by default (configured in `_quarto.yml`).

### Render to `docs/`

```r
quarto render
```

This renders all `.qmd` files to `docs/` and runs the post-render redirect script. Push `docs/` to the `main` branch to deploy.

### Rendering a single tutorial

```r
quarto render tutorials/kwics/kwics.qmd
```

---

## Contributing

Contributions of all kinds are welcome — new tutorials, corrections, code improvements, translations, and feedback.

See **[CONTRIBUTING.md](CONTRIBUTING.md)** for full guidance including:

- How to propose a new tutorial
- Style guide and code conventions
- How to submit corrections or improvements
- How to report broken links or errors
- The review and publication process

**Quick start:** Open an [issue](https://github.com/SLCLADAL/ladal/issues) to discuss your idea before submitting a pull request.

---

## Citation

### Citing the LADAL platform

> Schweinberger, Martin. 2026. *The Language Technology and Data Analysis Laboratory (LADAL)*. Brisbane: The University of Queensland, School of Languages and Cultures. https://ladal.edu.au (Version 2026.02.09).

```bibtex
@manual{schweinberger2026ladal,
  author       = {Schweinberger, Martin},
  title        = {The Language Technology and Data Analysis Laboratory (LADAL)},
  year         = {2026},
  organization = {The University of Queensland, School of Languages and Cultures},
  address      = {Brisbane},
  note         = {https://ladal.edu.au},
  edition      = {2026.02.09}
}
```

### Citing individual tutorials

Each tutorial has its own citation and Zenodo DOI. See the citation box at the bottom of each tutorial page, or use the "Cite this repository" button on GitHub (powered by `CITATION.cff`).

---

## Contributors

LADAL is built and maintained by an international team. For the full contributor list with roles, see the [About page](https://ladal.edu.au/about.html#contributors).

**Directors:**
- [Martin Schweinberger](https://languages-cultures.uq.edu.au/profile/4295/martin-schweinberger) (University of Queensland) — Founder, primary author
- [Michael Haugh](https://languages-cultures.uq.edu.au/profile/1498/michael-haugh) (University of Queensland) — Co-director

**Core team:**
[Laurence Anthony](https://www.laurenceanthony.net/) · [Sam Hames](https://languages-cultures.uq.edu.au/profile/8379/sam-hames) · Ruby Baird · [Erich Round](https://researchers.uq.edu.au/researcher/1761) · [Ludovic De Cuypere](https://orcid.org/0000-0002-0050-1097) · [Gerold Schneider](https://www.cl.uzh.ch/de/people/team/compling/gschneid.html) · Max Lauber

Early LADAL content drew substantially on the work of [Andreas Niekler](https://www.uni-leipzig.de/en/profile/mitarbeiter/dr-andreas-niekler) and [Gregor Wiedemann](https://leibniz-hbi.de/en/staff/gregor-wiedemann) — we gratefully acknowledge their foundational contribution.

---

## Affiliated Infrastructure

LADAL is part of a broader ecosystem of Australian language data infrastructure:

| Organisation | Role |
|---|---|
| [LDaCA](https://ldaca.edu.au) | Language Data Commons of Australia — LADAL's parent infrastructure |
| [ARDC](https://ardc.edu.au) | Australian Research Data Commons — primary funder |
| [ATAP](https://www.atap.edu.au) | Australian Text Analytics Platform — tools and notebooks |
| [School of Languages and Cultures, UQ](https://languages-cultures.uq.edu.au/) | Host institution |
| [AcqVA Aurora Lab, UiT](https://site.uit.no/acqvalab) | Collaborating research centre |
| [Text Crunching Center, UZH](https://www.cl.uzh.ch/en/TCC.html) | Collaborating research centre |
| [Sydney Corpus Lab](https://sydneycorpuslab.com/) | Collaborating research centre |

---

## Licence

All LADAL content is freely available under the [GNU General Public License, Version 3](https://www.gnu.org/licenses/gpl-3.0.html). You are welcome to use, adapt, and redistribute LADAL materials in your teaching and research, provided you cite LADAL appropriately, keep derivatives open-source, and maintain licence notices.

![GPL v3](/images/license.png)

---

## Contact

| Channel | Details |
|---|---|
| **Email** | [ladal@uq.edu.au](mailto:ladal@uq.edu.au) |
| **Website** | [ladal.edu.au](https://ladal.edu.au) |
| **YouTube** | [LADAL channel](https://www.youtube.com/channel/UCrPUPT8UvOAxUnorC95-F4Q) |
| **GitHub** | [SLCLADAL organisation](https://github.com/SLCLADAL) |
| **Issues** | [GitHub Issues](https://github.com/SLCLADAL/ladal/issues) |

---

*LADAL is a free, open-access resource. If you find it useful, please cite it, share it with colleagues, and consider [contributing](CONTRIBUTING.md).*