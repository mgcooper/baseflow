---
title: 'baseflow: a matlab/octave package for baseflow recession analysis'
tags:
  - Matlab
  - hydrology
  - groundwater
  - baseflow
  - streamflow
  - aquifer
authors:
  - name: Matthew G. Cooper
    orcid: 0000-0002-0165-209X
    corresponding: true
    affiliation: 1
  - name: Tian Zhou
    orcid: 0000-0003-1582-4005
    affiliation: 1
affiliations:
 - name: Atmospheric Science and Global Change, Pacific Northwest National Laboratory, Richland, WA, USA
   index: 1
date: DD February YYYY
bibliography: paper.bib
---

# Summary

# Statement of need

`baseflow` is a Matlab&trade package for baseflow recession analysis. The API
for `baseflow` was designed to provide a user-friendly interface to common
operations such as baseflow recession event detection, event-scale parameter
fitting, event-ensemble probability-distribution fitting, and visualization.
`baseflow` emphasizes the non-linear nature of lateral groundwater flow and
the collective behavior of hillslope units that comprise hydrologic catchments.

<!-- mgc example multiple citations: [@doe99; @smith2000; @smith2004] -->
<!-- more info: https://pandoc.org/MANUAL.html#extension-citations -->

`baseflow` was designed to be used by researchers in the hydrologic sciences
but is also useful for students studying catchment hydrology. The `baseflow`
software has been used in scientific publications [@cooper:2023] and forms
the basis of ongoing work investigating changes in groundwater storage in
permafrost regions.

# Mathematics

Single dollars ($) are required for inline mathematics e.g. $f(x) = e^{\pi/x}$

Double dollars make self-standing equations:

$$\Theta(x) = \left\{\begin{array}{l}
0\textrm{ if } x < 0\cr
1\textrm{ else}
\end{array}\right.$$

You can also use plain \LaTeX for equations
\begin{equation}\label{eq:fourier}
\hat f(\omega) = \int_{-\infty}^{\infty} f(x) e^{i\omega x} dx
\end{equation}
and refer to \autoref{eq:fourier} from text.

# Citations

<!-- Citations to entries in paper.bib should be in
[rMarkdown](http://rmarkdown.rstudio.com/authoring_bibliographies_and_citations.html)
format.

If you want to cite a software repository URL (e.g. something on GitHub without a preferred
citation) then you can do it with the example BibTeX entry below for @fidgit. -->

<!-- For a quick reference, the following citation commands can be used:
- `@author:2001`  ->  "Author et al. (2001)"
- `[@author:2001]` -> "(Author et al., 2001)"
- `[@author1:2001; @author2:2001]` -> "(Author1 et al., 2001; Author2 et al., 2002)" -->

# Figures

<!-- Figures can be included like this:
![Caption for example figure.\label{fig:example}](figure.png)
and referenced from text using \autoref{fig:example}.

Figure sizes can be customized by adding an optional second parameter:
![Caption for example figure.](figure.png){ width=20% } -->

# Acknowledgements

<!-- We acknowledge contributions from Brigitta Sipocz, Syrtis Major, and Semyeong
Oh, and support from Kathryn Johnston during the genesis of this project. -->

# References