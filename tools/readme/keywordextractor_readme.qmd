---
title: "KeywordExtractor"
subtitle: "LADAL Keyword & Keyness Analysis Tool"
format:
  html:
    toc: true
    toc-depth: 3
    theme: cosmo
    highlight-style: github
---

## About

**KeywordExtractor** is a browser-based keyword analysis tool developed by the [Language Technology and Data Analysis Laboratory (LADAL)](https://ladal.edu.au) at the University of Queensland. It identifies vocabulary that is statistically over- or under-represented in a **target corpus** compared to a **reference corpus** — words that are distinctive of your texts rather than just common in general language.

The tool is built with [Shiny](https://shiny.posit.co/) and runs entirely in the browser via [Binder](https://mybinder.org/). No R knowledge or software installation is required. All processing happens on the server; no data is stored.

::: {.callout-note}
This tool accompanies the LADAL tutorial [**Keyword and Keyness Analysis in R**](https://ladal.edu.au/tutorials/key/key.html), which explains the methodology in depth and provides reusable R code for more advanced workflows.
:::

---

## What is keyword analysis?

A **keyword** in corpus linguistics is a word that occurs with a statistically unusual frequency in one corpus compared to another. Keywords are not simply frequent words — they are words whose frequency is *surprising* relative to what you would expect given the size of the two corpora. This makes keyword analysis a powerful method for:

- identifying the characteristic vocabulary of a genre, register, or author
- comparing the language of different time periods, groups, or text types
- discovering thematic focus and ideological framing in discourse
- finding distinctive technical terminology in specialised texts

KeywordExtractor implements three standard keyness statistics, each measuring something slightly different about the difference between the two corpora.

---

## How to use

1. **Launch** the tool using one of the Binder links below.
2. **Upload target texts** — the corpus you want to analyse for distinctive vocabulary. Use the *Target corpus* upload in the left panel.
3. **Upload reference texts** — the comparison corpus. Use the *Reference corpus* upload. This is typically a larger, more general corpus, or a contrasting text type.
4. **Choose a keyness statistic** (see [Keyness statistics](#keyness-statistics) below).
5. **Set the minimum frequency** — words appearing fewer times than this threshold in both corpora are excluded from results. A value of 3–5 is recommended to filter out noise.
6. **Click Extract Keywords** to run the analysis.
7. **Explore** results in the bar chart and interactive table.
8. **Download** the full results as Excel, CSV, or PNG.

---

## Features

- Upload multiple `.txt` files for both target and reference corpora
- Three keyness statistics (G², chi-squared, log-ratio) — user's choice
- Adjustable minimum frequency threshold to filter rare words
- Option to show only target keywords (positive scores) or both directions
- Summary stat cards: total word types, target keywords, reference keywords, corpus sizes
- Interactive bar chart — top N keywords, colour-coded by direction (purple = target, amber = reference)
- Full sortable and filterable results table with colour-bar visualisation
- Built-in measure guide explaining each statistic with rules of thumb
- Download results as **Excel** (`.xlsx`), **CSV**, or **chart** (`.png`)

---

## Keyness statistics {#keyness-statistics}

KeywordExtractor offers three measures. All three compare the relative frequency of each word in the target corpus against the reference corpus.

### G² — Log-likelihood ratio *(recommended)*

Developed by Dunning (1993), G² compares observed frequencies with the frequencies you would expect if the word were distributed equally across both corpora. It is the standard keyness measure in corpus linguistics and is robust to differences in corpus size.

- **Positive G²**: word is over-represented in the target corpus (target keyword)
- **Negative G²**: word is over-represented in the reference corpus (reference keyword)
- **Rules of thumb**: G² ≥ 3.84 (*p* < .05) · ≥ 6.63 (*p* < .01) · ≥ 10.83 (*p* < .001)

### χ² — Chi-squared (Yates-corrected)

The classic Pearson chi-squared test with Yates' continuity correction. Familiar to researchers with a statistics background. Note that chi-squared is sensitive to small expected frequencies — results should be treated with caution when any expected cell count is below 5, which can occur with low-frequency words.

- **Rules of thumb**: χ² ≥ 3.84 (*p* < .05) · ≥ 6.63 (*p* < .01)

### Log-ratio — Effect size (Hardie 2014)

Rather than testing significance, log-ratio measures the *size* of the frequency difference. A word with a log-ratio of 1 is twice as common in the target as in the reference; a log-ratio of −1 means twice as common in the reference; 0 means no difference. Log-ratio is best used alongside G² or χ²: a word can be statistically significant but practically unimportant (common function words with tiny frequency differences), or have a large log-ratio but appear too rarely to be meaningful.

::: {.callout-tip}
## Which statistic should I use?

**G²** is the best default for most analyses. Use **log-ratio** alongside it when you want to understand the *magnitude* of the difference, not just its significance. Use **chi-squared** if your audience expects it for methodological comparability with prior work.
:::

---

## Launch

::: {.callout-tip}
## Which link should I use?

Use **ARDC BinderHub** if you have an Australian or New Zealand research institution login (AAF or Tuakiri). It offers more computing resources and faster load times.

Use **MyBinder.org** if you do not have AAF/Tuakiri access. It is free and open to everyone but may occasionally be slower.
:::

**ARDC BinderHub** *(recommended — requires AAF / Tuakiri login)*

```
https://binderhub.rc.nectar.org.au/v2/gh/SLCLADAL/interactive-notebooks-environment/main?urlpath=git-pull%3Frepo%3Dhttps%253A%252F%252Fgithub.com%252FSLCLADAL%252Ftools%26urlpath%3Dshiny%252Ftree%252Ftools%252Fkeywordextractor%252F%26branch%3Dmain
```

**MyBinder.org** *(open access — no login required)*

```
https://mybinder.org/v2/gh/SLCLADAL/interactive-notebooks-environment/main?urlpath=git-pull%3Frepo%3Dhttps%253A%252F%252Fgithub.com%252FSLCLADAL%252Ftools%26urlpath%3Dshiny%252Ftree%252Ftools%252Fkeywordextractor%252F%26branch%3Dmain
```

---

## Input format

KeywordExtractor accepts **plain-text files only** (`.txt`) for both corpora. Files should be:

- Saved with UTF-8 encoding where possible
- Unformatted (no Word `.docx`, no PDF, no HTML)
- One file per document — multiple files are merged into a single corpus for the analysis

There is no enforced size limit, but very large corpora may slow the analysis. For very large datasets, consider running the analysis locally in R using the [keyword analysis tutorial](https://ladal.edu.au/tutorials/key/key.html).

::: {.callout-important}
## Both corpora must be uploaded

KeywordExtractor requires both a target corpus and a reference corpus. Neither alone is sufficient. If you do not have a ready-made reference corpus, a common approach is to use a general language corpus (e.g. a sample of news texts or Wikipedia articles) as the reference.
:::

---

## Dependencies

All packages are pre-installed in the [LADAL interactive notebooks environment](https://github.com/SLCLADAL/interactive-notebooks-environment):

| Package | Purpose |
|---|---|
| `shiny` | Web application framework |
| `quanteda` | Tokenisation and corpus management |
| `quanteda.textstats` | Keyness calculation |
| `data.table` | Fast frequency table computation |
| `tidyverse` | Data manipulation and CSV export |
| `writexl` | Excel export |
| `DT` | Interactive results table |
| `ggplot2` | Keyword bar chart |

---

## Related tools and tutorials

- [**WordFinder**](../wordfinder/README.html) — search for words and phrases across your texts using keyword-in-context concordancing
- [**Keyword and Keyness Analysis in R** (tutorial)](https://ladal.edu.au/tutorials/key/key.html) — full methodology with reusable R code
- [All LADAL tools](https://ladal.edu.au/tools.html)

---

## Citation

Schweinberger, Martin. (2026). *KeywordExtractor: LADAL Keyword Analysis Tool*. Brisbane: The University of Queensland. <https://ladal.edu.au/tools.html>

```bibtex
@misc{schweinberger2026keywordextractor,
  author       = {Schweinberger, Martin},
  title        = {{KeywordExtractor}: {LADAL} Keyword Analysis Tool},
  year         = {2026},
  organization = {The University of Queensland,
                  School of Languages and Cultures},
  address      = {Brisbane},
  url          = {https://ladal.edu.au/tools.html}
}
```

### References

Dunning, Ted. 1993. Accurate methods for the statistics of surprise and coincidence. *Computational Linguistics* 19(1): 61–74.

Hardie, Andrew. 2014. Log ratio: An informal introduction. *ESRC Centre for Corpus Approaches to Social Science*. <http://cass.lancs.ac.uk/log-ratio-an-informal-introduction/>

---

## Reporting issues

If the tool fails to launch or produces unexpected results, please email [m.schweinberger@uq.edu.au](mailto:m.schweinberger@uq.edu.au) with the tool name, which Binder link you used, and a brief description of the problem.

---

*Part of [LDaCA](https://ldaca.edu.au) · [ARDC](https://ardc.edu.au) · [NCRIS](https://www.education.gov.au/ncris) · [University of Queensland](https://www.uq.edu.au)*
