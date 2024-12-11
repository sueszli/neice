---
title: "Report: Group 29"
subtitle: "Code: [`github.com/sueszli/neice`](https://github.com/sueszli/neice)"
output: pdf_document
documentclass: article
papersize: a4
pagestyle: empty
geometry:
    - top=5mm
    - bottom=5mm
    - left=5mm
    - right=5mm
header-includes:
    # title
    - \usepackage{titling}
    - \setlength{\droptitle}{-15pt}
    - \pretitle{\vspace{-30pt}\begin{center}\LARGE}
    - \posttitle{\end{center}\vspace{-30pt}}    
    # content
    - \usepackage{scrextend}
    - \changefontsizes[8pt]{8pt}
    # code
    - \usepackage{fancyvrb}
    - \fvset{fontsize=\fontsize{6pt}{6pt}\selectfont}
    - \usepackage{listings}
    - \lstset{basicstyle=\fontsize{6pt}{6pt}\selectfont\ttfamily}
    # code output
    - \DefineVerbatimEnvironment{verbatim}{Verbatim}{fontsize=\fontsize{6pt}{6pt}}
---

<!--

confirm the numbers reported / show inconsistencies
- existing codebased / previous attempts shouldn't influence results (try from scratch)
- statistically significant differences (significance tests, confidence intervals, p values, etc. variance)
- were experiments run multiple times (ie. different seeds for data splits)
- was variance reported
- were significance tests performed
- do conclusions hold with different seeds

report
- max 6 pages with template

machine readable report
- another file format (will be announced early january)

upload everything to zenodo
- will be public

short presentation
- 180s
- 4-5 slides
-->

# Introduction

<!-- information given in paper -->

<!-- https://arxiv.org/pdf/2201.04419 -->

*contributions (end of page 2)*

- we only care about algorithm.
- i. most extensive study to date on topic modeling podcast metadata (short text) & on most popular datasets and algorithms
- ii. NEiCE = Named Entity informed Corpus Embedding
- iii. Deezer dataset

*algorithm survery / benchmark*

- podcast metadata (title, description, etc.) are short
- these algorithms deal with short data
- studies show that NMF-based algorithms are better than probabilistic models on short text
- NMF-based are more interpretable than neural models

- **pseudo-documents-based**
    - concatenate and use conventional algorithms
- **probabilistic**
    - generalized polya urna dirichlet multinomial mixture (GPU-DMM)
        - https://dl.acm.org/doi/pdf/10.1145/2911451.2911499
- **neural**
    - Negative sampling and Quantization Topic Model (NQTM)
        - https://aclanthology.org/2020.emnlp-main.138.pdf
        - neural model
        - quantification method to get peakier distributions for decoding
        - better at discovering non-repetitive topics
- **NMF-based**
    - non-negative matrix factorization (NMF)
        - https://citeseerx.ist.psu.edu/document?type=pdf&doi=f452c605e8ecf8cd3541ea7909d81d27deb08181
        - decomposes term-document bag of words matrix into two low rank matrices
        - first: document-topic representaiton matrix
        - second: topic-term representaiton matrix 
    - semantics assisted NMF (SeaNMF)
        - https://dl.acm.org/doi/pdf/10.1145/3178876.3186009
        - integrats word-context embeddings
        - focuses on the learning
    - clustering words (CluWords)
        - https://dl.acm.org/doi/pdf/10.1145/3289600.3291032
        - nearest neighbor search
    - named entity informed corpus embedding (NEiCE)
        - https://arxiv.org/pdf/2201.04419
        - based on CluWords: https://dl.acm.org/doi/abs/10.1145/3289600.3291032
        - named entity information in word embeddings from NMF
        - NE makes sense because podcast metadata have a lot more named entities, and they are informative
        - Wikipedia2Vec as embeddings




# Experimental Setup

<!-- steps necessary to reproduce results -->
