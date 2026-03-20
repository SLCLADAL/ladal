---
title: "TextCleaner"
subtitle: "LADAL Text Cleaning Tool"
format:
  html:
    toc: true
    toc-depth: 3
    theme: cosmo
    highlight-style: github
---

## About

**TextCleaner** is a browser-based text cleaning tool developed by the
[Language Technology and Data Analysis Laboratory (LADAL)](https://ladal.edu.au)
at the University of Queensland. It allows researchers to remove and replace
text elements across uploaded plain-text files using pre-built one-click
options and custom regular expressions — with a live preview before
downloading the cleaned files.

The tool is built with [Shiny](https://shiny.posit.co/) and uses
[stringi](https://stringi.gagolewski.com/) for all text operations,
which provides C-level ICU regex processing for maximum speed even
on large corpora.

::: {.callout-note}
This tool accompanies the LADAL tutorial
[**String Processing in R**](https://ladal.edu.au/tutorials/string/string.html),
which explains the full methodology with reusable R code.
:::

---

## How to use

1. **Launch** the tool using one of the Binder links below.
2. **Upload** one or more `.txt` files using the *Upload texts* panel.
3. **Select pre-built removal options** — tick any combination of the
   eight one-click options.
4. **Add custom removal patterns** — enter any regular expressions
   (one per line) in the custom removal box.
5. **Add find → replace pairs** using the table — tick *Regex* to use
   regular expressions, tick *IC* for case-insensitive matching.
6. **Preview** the effect on one file by clicking **Preview**.
7. **Clean all files** by clicking **Clean all files**.
8. **Download** — individual cleaned `.txt` files or a single ZIP
   archive containing all of them.

---

## Features

- Upload multiple `.txt` files — each is cleaned independently
- **Eight pre-built removal options** (one-click checkboxes):
  XML/HTML tags · non-alphanumeric characters · punctuation · numbers ·
  URLs · email addresses · speaker labels · extra whitespace
- **Convert to lowercase** checkbox
- **Custom regex removal** — enter any number of ICU regular expression
  patterns, one per line
- **Find → Replace table** — add as many rows as needed; each row
  supports regex or fixed matching, case-sensitive or insensitive
- **Live preview** — side-by-side original vs cleaned view of any
  selected file before committing to all files
- **Change summary** — table showing characters removed and percentage
  reduction per file
- **Download** — individual `_cleaned.txt` files or all files as a ZIP
- Fast processing via `stringi` (C-level ICU, fastest R string library)

---

## Pre-built removal options

| Option | What it removes | Regex pattern |
|---|---|---|
| XML / HTML tags | `<b>`, `</p>`, `<br/>` etc. | `<[^>]*>` |
| Non-alphanumeric except spaces | Everything except letters, digits, spaces | `[^\p{L}\p{N} ]` |
| Punctuation | `.`, `,`, `;`, `:`, `!`, `?`, `"`, `'` etc. | `[^\p{L}\p{N}\s]` |
| Numbers | `1`, `42`, `2024` etc. | `\d+` |
| URLs | `https://…`, `www.…` | `https?://\S+\|www\.\S+` |
| Email addresses | `user@example.com` | standard email regex |
| Speaker labels | `[SPEAKER_A]:`, `<S1A-001$A>` | bracket/angle label patterns |
| Extra whitespace | Runs of spaces/tabs | collapses to single space |

---

## Custom regex patterns

Enter any [ICU regular expression](https://unicode-org.github.io/icu/userguide/strings/regexp.html)
in the custom removal box — one pattern per line. Examples:

```
<.*?>
\bACT\s+[IVX]+\b
\([^)]*\)
```

The tool uses **ICU regex syntax** (via `stringi`), which supports Unicode
property escapes such as `\p{L}` (any letter), `\p{N}` (any number),
and `\p{Z}` (any separator).

---

## Find → Replace examples

| Find | Replace with | Regex | Description |
|---|---|---|---|
| `ä` | `ae` | ☐ | Replace German umlaut (fixed) |
| `ö` | `oe` | ☐ | Replace German umlaut (fixed) |
| `ü` | `ue` | ☐ | Replace German umlaut (fixed) |
| `\b(\w+)\s+\1\b` | `$1` | ☑ | Remove repeated words |
| `(\w+)-\n(\w+)` | `$1$2` | ☑ | Join hyphenated line breaks |
| `\s+` | ` ` | ☑ | Normalise all whitespace to single space |

---

## Output files

Each cleaned file is named `[original_filename]_cleaned.txt` and
contains the cleaned text with the same line structure as the original
(after whitespace normalisation if selected).

---

## Launch

::: {.callout-tip}
## Which link should I use?

Use **ARDC BinderHub** if you have an Australian or New Zealand
research institution login (AAF or Tuakiri).

Use **MyBinder.org** if you do not have AAF/Tuakiri access.
:::

**ARDC BinderHub** *(recommended — requires AAF / Tuakiri login)*

```
https://binderhub.atap-binder.cloud.edu.au/v2/gh/SLCLADAL/interactive-notebooks-environment/main?urlpath=git-pull%3Frepo%3Dhttps%253A%252F%252Fgithub.com%252FSLCLADAL%252Ftools%26urlpath%3Dshiny%252Ftree%252Ftools%252Ftextcleaner%252F%26branch%3Dmain
```

**MyBinder.org** *(open access — no login required)*

```
https://mybinder.org/v2/gh/SLCLADAL/interactive-notebooks-environment/main?urlpath=git-pull%3Frepo%3Dhttps%253A%252F%252Fgithub.com%252FSLCLADAL%252Ftools%26urlpath%3Dshiny%252Ftree%252Ftools%252Ftextcleaner%252F%26branch%3Dmain
```

---

## Dependencies

All packages are pre-installed in the
[LADAL interactive notebooks environment](https://github.com/SLCLADAL/interactive-notebooks-environment):

| Package | Purpose |
|---|---|
| `shiny` | Web application framework |
| `stringi` | Fast C-level ICU regex text processing |
| `data.table` | Fast tabular state management |
| `readr` | Fast file I/O |
| `zip` | ZIP archive creation for download |
| `DT` | Interactive change summary table |

::: {.callout-important}
## Environment note

`stringi` is already installed as a dependency of `tidyverse` in the
environment. `readr` is part of `tidyverse`. Only `zip` may need to
be added to `install.R` if not already present (it was added for
UDPTagger).
:::

---

## Related tools and tutorials

- [**WordFinder**](../wordfinder/README.html) — concordancing
- [**KeywordExtractor**](../keywordextractor/README.html) — keyness
- [**WordMapper**](../wordmapper/README.html) — co-occurrence networks
- [**UDPTagger**](../udptagger/README.html) — POS tagging
- [**String Processing Tutorial**](https://ladal.edu.au/tutorials/string/string.html)
- [All LADAL tools](https://ladal.edu.au/tools.html)

---

## Citation

Schweinberger, Martin. (2025). *TextCleaner: LADAL Text Cleaning Tool*.
Brisbane: The University of Queensland. <https://ladal.edu.au/tools.html>

```bibtex
@misc{schweinberger2025textcleaner,
  author       = {Schweinberger, Martin},
  title        = {{TextCleaner}: {LADAL} Text Cleaning Tool},
  year         = {2025},
  organization = {The University of Queensland,
                  School of Languages and Cultures},
  address      = {Brisbane},
  url          = {https://ladal.edu.au/tools.html}
}
```

---

## Reporting issues

Email [m.schweinberger@uq.edu.au](mailto:m.schweinberger@uq.edu.au)
with the tool name, which Binder link you used, and a description of
the problem.

---

*Part of [LDaCA](https://ldaca.edu.au) · [ARDC](https://ardc.edu.au) ·
[NCRIS](https://www.education.gov.au/ncris) ·
[University of Queensland](https://www.uq.edu.au)*
