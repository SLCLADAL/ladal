---
title: "ContextMapper"
subtitle: "LADAL Word Co-occurrence Network Tool"
format:
  html:
    toc: true
    toc-depth: 3
    theme: cosmo
    highlight-style: github
---

## About

**NetworkMapper** is a browser-based word co-occurrence network tool developed by the [Language Technology and Data Analysis Laboratory (LADAL)](https://ladal.edu.au) at the University of Queensland. It takes plain-text files, builds a feature co-occurrence matrix (FCM) using a sliding context window, and visualises the words that co-occur most frequently with a keyword of your choice — both as an interactive network you can explore in the browser and as a static downloadable plot.

No R knowledge or software installation is required. The tool runs entirely in the browser via [Binder](https://mybinder.org/).

::: {.callout-note}
This tool accompanies the LADAL tutorial [**Network Analysis using R**](https://ladal.edu.au/tutorials/net/net.html), which explains the full methodology including community detection, centrality measures, and `ggraph` visualisation.
:::

---

## What is a word co-occurrence network?

A **word co-occurrence network** represents the vocabulary of a text as a graph: each word is a **node**, and two nodes are connected by an **edge** if the two words appear within a defined context window of each other. The thicker the edge, the more often the two words co-occur.

NetworkMapper builds **keyword-centred** networks: you supply one keyword and the tool shows the words that appear most often in its vicinity across your texts. This is useful for:

- exploring the **semantic context** of a term across a corpus
- identifying **collocational patterns** — which words habitually appear with your keyword
- comparing how the **contextual neighbourhood** of a term varies across text types or time periods
- discovering unexpected **thematic associations**

The network is built from a **feature co-occurrence matrix (FCM)** using a sliding word window. The FCM records, for every pair of words, how many times they appear within the window of each other.

---

## How to use

1. **Launch** the tool using one of the Binder links below.
2. **Upload** one or more `.txt` files using the *Upload texts* panel on the left.
3. **Enter a keyword** — the word whose co-occurrence network you want to explore.
4. **Configure settings:**
   - *Remove stopwords* — choose a language to filter out function words, or select *None* to keep all words.
   - *Context window* — how many words either side of each token count as co-occurring (default: ±5).
   - *Max co-occurring words* — how many top co-occurring words to show as nodes.
   - *Min. co-occurrence frequency* — words co-occurring fewer times than this are excluded.
5. **Adjust visual options** — edge colour, transparency, node size, and label size.
6. **Click Build Network.**
7. **Explore** results across three tabs:
   - **Interactive network** — drag nodes, hover for counts, click to highlight neighbours.
   - **Static network** — a `quanteda.textplots`-style plot for screenshots and download.
   - **Co-occurrence table** — the raw frequency data behind the network.
8. **Download** the static network as PNG, or the co-occurrence table as Excel or CSV.

---

## Features

- Upload multiple `.txt` files (all merged into one corpus)
- Stopword removal for 9 languages (English, German, French, Spanish, Italian, Dutch, Portuguese, Russian, Arabic) — or keep all words
- Sliding context window (±1 to ±15 words)
- Keyword-centred network: only the keyword's co-occurrence neighbourhood is shown
- **Interactive network** (visNetwork): drag, zoom, hover tooltips, click-to-highlight
- **Static network** (quanteda.textplots): node sizes and edge widths proportional to frequency, keyword highlighted in LADAL purple
- Full co-occurrence table with sortable columns and colour-bar frequency display
- Summary stat cards: number of co-occurring words, total co-occurrences, top collocate, corpus size
- Visual customisation: edge colour, transparency, node size, label size
- Download: static network as **PNG**, co-occurrence table as **Excel** or **CSV**

---

## Understanding the settings

### Context window

The context window determines which pairs of words are counted as co-occurring. A token-based sliding window of ±*n* means two words co-occur if they appear within *n* words of each other (not necessarily adjacent). Smaller windows (±2–3) capture tight syntactic and collocational relationships; larger windows (±10–15) capture broader topical associations.

### Minimum co-occurrence frequency

Words that co-occur with the keyword fewer times than this threshold are excluded from the network. Raising the threshold produces a sparser, cleaner network; lowering it shows more detail but may include noise. A value of 2–5 is recommended for most analyses.

### Stopword removal

Removing stopwords before building the FCM prevents high-frequency function words (*the*, *a*, *of*, *and*…) from dominating the network. This is usually recommended for semantic and collocational analysis. If you are studying grammatical patterns or discourse markers, you may want to keep stopwords.

---

## Launch

::: {.callout-tip}
## Which link should I use?

Use **ARDC BinderHub** if you have an Australian or New Zealand research institution login (AAF or Tuakiri). It offers more computing resources and faster load times.

Use **MyBinder.org** if you do not have AAF/Tuakiri access. It is free and open to everyone but may occasionally be slower.
:::

**ARDC BinderHub** *(recommended — requires AAF / Tuakiri login)*

```
https://binderhub.atap-binder.cloud.edu.au/v2/gh/SLCLADAL/interactive-notebooks-environment/main?urlpath=git-pull%3Frepo%3Dhttps%253A%252F%252Fgithub.com%252FSLCLADAL%252Ftools%26urlpath%3Dshiny%252Ftree%252Ftools%252Fnetworkmapper%252F%26branch%3Dmain
```

**MyBinder.org** *(open access — no login required)*

```
https://mybinder.org/v2/gh/SLCLADAL/interactive-notebooks-environment/main?urlpath=git-pull%3Frepo%3Dhttps%253A%252F%252Fgithub.com%252FSLCLADAL%252Ftools%26urlpath%3Dshiny%252Ftree%252Ftools%252Fnetworkmapper%252F%26branch%3Dmain
```

---

## Input format

NetworkMapper accepts **plain-text files only** (`.txt`). Files should be:

- Saved with UTF-8 encoding where possible
- Unformatted (no Word `.docx`, no PDF, no HTML)
- One file per document — multiple files are merged into a single corpus

---

## Dependencies

All packages are pre-installed in the [LADAL interactive notebooks environment](https://github.com/SLCLADAL/interactive-notebooks-environment):

| Package | Purpose |
|---|---|
| `shiny` | Web application framework |
| `quanteda` | Tokenisation, DFM, and FCM construction |
| `quanteda.textplots` | Static network visualisation |
| `igraph` | Graph data structures |
| `visNetwork` | Interactive network visualisation |
| `tidyverse` | Data manipulation and CSV export |
| `writexl` | Excel export |
| `DT` | Interactive co-occurrence table |

::: {.callout-important}
## Environment note

`visNetwork` must be added to `install.R` in the
[interactive-notebooks-environment](https://github.com/SLCLADAL/interactive-notebooks-environment)
if not already present. Check before deploying.
:::

---

## Related tools and tutorials

- [**WordFinder**](../wordfinder/README.html) — keyword-in-context concordancing
- [**KeywordExtractor**](../keywordextractor/README.html) — keyness analysis (target vs reference corpus)
- [**Network Analysis using R** (tutorial)](https://ladal.edu.au/tutorials/net/net.html) — full methodology with community detection, centrality measures, and `ggraph`
- [All LADAL tools](https://ladal.edu.au/tools.html)

---

## Citation

Schweinberger, Martin. (2026). *NetworkMapper: LADAL Word Co-occurrence Network Tool*. Brisbane: The University of Queensland. <https://ladal.edu.au/tools.html>

```bibtex
@misc{schweinberger2026networkmapper,
  author       = {Schweinberger, Martin},
  title        = {{NetworkMapper}: {LADAL} Word Co-occurrence Network Tool},
  year         = {2026},
  organization = {The University of Queensland,
                  School of Languages and Cultures},
  address      = {Brisbane},
  url          = {https://ladal.edu.au/tools.html}
}
```

---

## Reporting issues

If the tool fails to launch or produces unexpected results, please email [m.schweinberger@uq.edu.au](mailto:m.schweinberger@uq.edu.au) with the tool name, which Binder link you used, and a brief description of the problem.

---

*Part of [LDaCA](https://ldaca.edu.au) · [ARDC](https://ardc.edu.au) · [NCRIS](https://www.education.gov.au/ncris) · [University of Queensland](https://www.uq.edu.au)*
