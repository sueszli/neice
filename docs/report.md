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
- statistically significant differences (significance tests, confidence intervals, p values, etc. variance)

report
- max 6 pages
- 

another file format (will be announced early january)

-->

# Introduction

<!-- information given in paper -->

# Experimental Setup

<!-- steps necessary to reproduce results -->