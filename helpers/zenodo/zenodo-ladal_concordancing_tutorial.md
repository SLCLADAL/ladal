# LADAL Tutorial — Zenodo Record Template
# Use this as the master record. For each new tutorial, click Duplicate in Zenodo and update the fields marked UPDATE.

# ============================================================
# RECORD TYPE
# ============================================================
Resource type:        Publication
Publication type:     Tutorial

# ============================================================
# BASIC METADATA — UPDATE these for each tutorial
# ============================================================
Title:                Finding Words in Text: Concordancing with R   # UPDATE
Authors:              Schweinberger, Martin                         # UPDATE — add/replace for external contributors
  ORCID:              0000-0003-1923-9153                           # UPDATE — use contributor's ORCID if available
Affiliation:          University of Queensland                      # UPDATE if external contributor

# ============================================================
# DESCRIPTION — UPDATE the first paragraph for each tutorial
# ============================================================
Description:
  This tutorial introduces concordancing and Keyword-in-Context
  (KWIC) analysis using R. It covers how to load text data, generate
  KWIC displays, and interpret concordance output for corpus
  linguistic research. The tutorial is part of the Language
  Technology and Data Analysis Laboratory (LADAL), a free,
  open-access research infrastructure at the University of
  Queensland.

  LADAL provides tutorials, tools, and courses for researchers
  working with language data. All LADAL materials are freely
  available at https://ladal.edu.au and are part of the Language
  Data Commons of Australia (LDaCA), funded by ARDC and NCRIS.

# ============================================================
# DATE & VERSION — UPDATE for each tutorial
# ============================================================
Publication date:     2026-03-24                                    # UPDATE to tutorial publication/revision date
Version:              2.0.0                                         # UPDATE if revised

# ============================================================
# LICENCE — keep consistent across all tutorials
# ============================================================
Licence:              Creative Commons Attribution 4.0 International (CC BY 4.0)
# Note: CC BY 4.0 is recommended for tutorials rather than GPL,
# which is designed for software. CC BY 4.0 allows anyone to
# reuse and adapt with attribution — standard for open educational
# resources.

# ============================================================
# KEYWORDS — UPDATE, keep the last four on every record
# ============================================================
Keywords:
  - concordancing                                                   # UPDATE — add tutorial-specific keywords
  - KWIC
  - corpus linguistics
  - text analysis
  - R
  - computational linguistics
  - LADAL                                                           # keep on every record
  - language technology                                             # keep on every record
  - open educational resource                                       # keep on every record
  - University of Queensland                                        # keep on every record

# ============================================================
# RELATED IDENTIFIERS — update the tutorial URL for each record
# ============================================================
Related identifiers:
  - URL:              https://ladal.edu.au/tutorials/kwics/kwics.html   # UPDATE — live tutorial page
    Relation:         Is supplement to

  - URL:              https://ladal.edu.au
    Relation:         Is part of

  - URL:              https://github.com/SLCLADAL/ladal
    Relation:         Is supplement to

  - URL:              https://www.ldaca.edu.au
    Relation:         Is part of

# ============================================================
# COMMUNITY — keep on every record
# ============================================================
Community:            ladal

# ============================================================
# FUNDING — keep on every record
# ============================================================
Funding:
  - Funder:           Australian Research Data Commons (ARDC)
  - Funder:           National Collaborative Research Infrastructure Strategy (NCRIS)

# ============================================================
# FILE TO UPLOAD
# ============================================================
# Upload the rendered HTML file of the tutorial, e.g. kwics.html
# Optionally also upload the .qmd source file.
# File name convention: ladal-[short-name]-tutorial.html
# Example:             ladal-concordancing-tutorial.html
