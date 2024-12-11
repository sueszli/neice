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

## methodology

- $A$ has BoW representations for each document $\mathcal{D}$ and $K$ topics
    - simple BoW matrix
- factorization: $A \approx WH$
- $W$ is the topic-term matrix: each row is a representation of a topic from the vocabulary $\mathcal{V}$
- $H$ is the document-topic matrix: each row is a representation of a document from the topics

*preprocessing*

- identify named entities in title and description
- link them to wikipedia entities using the "radboud entity linker" (REL) system
    - detect NE mentions using "Flair", a named entity recognition (NER) system using embeddings
    - find a unique candidate from list with wikipedia2vec
    - return the Wikipedia page of a unique named entity with a confidence score that helps us to choose if we treat it as: a span of text, as a named entity, words to be processed seperately
- clean vocabulary
    - use NameDataset library to remove actors, athletes, etc. that are too common

*computation*

- apply NE-related re-weighting to the tf factor

*datasets*

- itunes: drop duplicate titles, drop if title and description together have less than 3 terms
- spotify: drop duplicate titles, drop if title and description together have less than 3 terms, drop non-english podcasts (double check with "fastText", "CLD3")
- deezer: largest
- all have metadata (provided by creators), titles and descriptions, show name, in english-language
- drop unpopular genres (< 300 shows)

*evaluation*

- common metrics for "topic coherence" for topic quality
- normalized pointwise mutual information (NPMI) metric
    - computed with "Palmetto" for each topic $k$ on wikipdeia
- top words limit: 10
- top topics limit: 20, 50, 100, 200
- REL confidence threshold: 0.9
- drop words that appear in less than 5 documents
- remove stopwords using NLTK
- default hyperparams for all models
- original cluwords is evaluated on fastText and wikipedia2vec embeddings
- neice config:
    - alpha-word set to 0.34-0.4 because of cluwords (test range: 0.2, 0.3, 0.4, 0.5)
    - alpha-ent set similarly
- specs: Intel Xeon Gold 6134 CPU @ 3.20GHz with 32 cores and 128GB RAM

## results

# Experimental Setup

<!-- steps necessary to reproduce results -->

`RUN pip install git+https://github.com/informagi/REL` fails due to a version missmatch.

the authors didn't `pip-compile` their dependencies, which is why the installation fails.
