---
title: 'baseflow: a MATLAB and GNU Octave package for baseflow recession analysis'
tags:
  - Matlab
  - Octave
  - hydrology
  - groundwater
  - baseflow
  - streamflow
  - aquifer
  - Pareto distribution
  - power law
  - plfit
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
date: today
bibliography: paper.bib
---

<!-- TODO: more detail on Figure 1 caption, let tian know about the review criteria section that says to compare with other software -->

# Summary
<!-- Begin your paper with a summary of the high-level functionality of your software for a non-specialist reader. Avoid jargon in this section -->
`baseflow` is a MATLAB&reg; [@matlab_2020_] toolbox that facilitates baseflow recession analysis, a set of methods used in hydrologic science to infer aquifer properties that cannot be measured directly [@brutsaert_1977_WRR]. The widespread availability of streamflow measurements means that baseflow recession analysis can be used to estimate aquifer properties, such as hydraulic conductivity or drainable porosity, and their variations globally over the modern instrumental stream gage record. This toolbox offers easy-to-use functions for baseflow recession analysis using measured values of streamflow recorded on a daily timestep. It is primarily designed for shallow (depth << breadth) unconfined riparian aquifers that discharge groundwater laterally into adjacent stream channels, rather than confined aquifers or complex geologic structures which require specialized numerical groundwater models. The toolbox can also be used to study the collective behavior of individual hillslope aquifers that constitute hydrologic catchments, known as "watersheds", using a non-linear dynamical systems perspective [@kirchner_2009_WRR]. By leveraging recent advancements in the baseflow recession analysis literature [@roques_2017_AiWR; @dralle_2017_HESS], `baseflow` enables consistent, objective estimation of unconfined hillslope aquifer properties and conceptual catchment-scale aquifer properties.

# Statement of need

Baseflow is the component of streamflow that originates solely from aquifer discharge, particularly during periods of no recharge [@hall_1968_WRR]. This excludes direct contributions from other sources like rainfall, surface water, or managed reservoir release, and essentially reflects the delayed release of groundwater storage into streams. Baseflow plays a crucial role in sustaining water availability during dry seasons, especially in regions with limited surface water storage [@cooper_2018_WRR]. Baseflow is therefore important for managing water scarcity, and understanding the baseflow recession process is a central task in hydrologic science [@hall_1968_WRR; @kirchner_2009_WRR; @troch_2013_WRR].

The baseflow recession curve represents the decline in streamflow during low-flow periods, effectively capturing the gradual drawdown of aquifer storage [@brutsaert_1977_WRR]. Parameters derived from this curve can reveal key unconfined aquifer properties, such as hydraulic conductivity, drainable porosity, and the saturated zone thickness [@brutsaert_1998_WRR; @troch_1993_WRR; @rupp_2006_WRR]. However, detecting baseflow segments from measured streamflow data is a complex task, requiring specialized algorithms for signal processing, curve-fitting, and parameter estimation, complicated further by potential contamination due to measurement error [@dralle_2017_HESS; @rupp_2006_AiWR].

\bigskip
\begin{figure}[!tbh]
\centering
\includegraphics[width=\textwidth]{docs/figure_1.png}
\caption{Example of baseflow recession analysis, the core functionality of the `baseflow` toolbox. (a) Daily discharge hydrograph for the Kuparuk River, Alaska recorded at United States Geological Streamflow gage 1596000 and one recession event detected with the `baseflow` toolbox. (b-c) Observed discharge ($Q$) and its rate of change ($-\mathrm{d}Q/\mathrm{d}t$) for the event highlighted in (a) compared with values fitted with the `baseflow` toolbox. (d) Fitted relationship between $Q$ and $-\mathrm{d}Q/\mathrm{d}t$ to estimate parameters $a$ and $b$.}
\label{fig:figure_1}
\end{figure}

<!-- ![Example of baseflow recession analysis, the core functionality of the `baseflow` toolbox.\label{fig:figure_1}](./docs/figure_1.png) -->

The `baseflow` API was designed to provide a user-friendly interface for common baseflow recession analysis tasks such as event detection, parameter fitting, probability-distribution fitting, and visualization (\autoref{fig:figure_1}). The toolbox emphasizes the non-linear nature of streamflow, which can arise from rate-dependent hydraulic properties [@rupp_2006_WRR], or the nonlinear collective behavior of hillslope aquifer units that comprise hydrologic catchments [@harman_2009_WRR]. `baseflow` is intended for use by researchers in the hydrologic sciences [@cooper_2023_WRR] and serves as the foundation for ongoing investigations into changing groundwater storage capacity in Arctic and Subarctic catchments resulting from permafrost thaw.

# State of the field

Recent developments in publicly available software packages for baseflow recession analysis have provided hydrologists with objective and repeatable methods for estimating baseflow parameters [@dralle_2017_HESS; @gnann_2021_EM&S; @arciniega-esparza_2018_]. This is important because baseflow recession analysis is sensitive to methodological decisions that are often poorly documented. Among the reviewed packages, there is a shared focus on estimating the canonical parameters of the event-scale recession equation:

<!-- $$-\frac{dQ}{dt} = aQ^b$$ -->
\begin{equation}\label{eq:aQb}
-\dfrac{\mathrm{d}Q}{\mathrm{d}t}=aQ^b
\end{equation}

where $Q$ is streamflow, $t$ is time, and recession parameters $a$ and $b$ determine the shape of the recession curve (\autoref{fig:figure_1}). This equation, which is used to determine the shape of the recession curve, relates the rate of change of streamflow to streamflow itself.

Two packages for baseflow recession analysis are available within the MATLAB ecosystem. `HYDRORECESSION` [@arciniega-esparza_2017_C&G; @arciniega-esparza_2018_] is a MATLAB toolbox organized around a graphical user interface that provides methods to detect recession events and fit \autoref{eq:aQb}. Relative to `HYDRORECESSION`, the `baseflow` toolbox offers additional features for aquifer property estimation, such as saturated aquifer thickness, saturated hydraulic conductivity, and drainable porosity. `HYDRORECESSION` and `baseflow` both provide methods libraries for fitting alternative forms of \autoref{eq:aQb} based on solutions to the one-dimensional lateral groundwater flow equation. `baseflow` could benefit from incorporating two of the four forms available in `HYDRORECESSION` and a graphical user interface for data exploration.

The Toolbox for Streamflow Signatures in Hydrology (`TOSSH`) [@gnann_2021_EM&S] provides recession event-detection and curve-fitting algorithms but is broader in scope than `baseflow` and `HYDRORECESSION`. For example, `TOSSH` provides automated estimation of several dozen quantitative metrics of streamflow  known as "hydrologic signatures" including recession parameters $a$ and $b$. It provides a narrower toolkit for estimating $a$ and $b$, and limited options for interpreting their values in terms of hydraulic groundwater theory. However, `TOSSH` provides a unique capability for interpreting $a$ and $b$ empirically in terms of hydrologic signatures. Although `baseflow` is designed for hillslope- and catchment-scale aquifer characterization, it could benefit from a broader scope that includes methods for quantifying evapotranspiration, which significantly affects estimates of $a$ and $b$ [@jachens_2020_HESS].

# Unique functionality: power-law scaling of recession parameters

Development of the `baseflow` toolbox was motivated by the need to automate Pareto distribution fits to large-sample recession parameter ensembles, based on recent research [@cooper_2023_WRR] that derived the Pareto transformation of \autoref{eq:aQb}. `baseflow` provides the only automated Pareto distribution parameter fitting module for aquifer characterization that we know of. The toolbox accomplishes this by wrapping the function `plfit`, a Matlab function for fitting Pareto distributions which has been cited over 10,000 times [@clauset_2009_SR]. This wrapper serves as a translator from the notation and functional forms of `plfit` to those of hydraulic groundwater theory. The Pareto-fitting method implemented in baseflow is especially important because it provides theoretically unbiased estimates of $a$ and $b$ for late-time aquifer drainage, which are necessary for obtaining meaningful estimates of aquifer properties from baseflow recession analysis.

<!-- Baseflow is not directly observable, and thus its estimation demands specialized analytical tools. Baseflow recession analysis provides estimates of aquifer properties by fitting the recession curve of streamflow, which is the decrease in streamflow over time during aquifer drawdown [@brutsaert_1977_WRR]. The estimation of baseflow is critical for water resource management, and the ability to estimate it consistently and objectively is important for gaining insight into the role of groundwater in the water cycle and ecosystem dynamics. -->

<!-- To address these challenges, various analytical tools and software packages have been developed to estimate baseflow from streamflow measurements.  -->

# Software Availability

`baseflow` is [on GitHub](https://github.com/mgcooper/baseflow/tree/joss).

# Acknowledgements

The Interdisciplinary Research for Arctic Coastal Environments (InteRFACE) project funded this work through the United States Department of Energy, Office of Science, Biological and Environmental Research (BER) Regional and Global Model Analysis (RGMA) program. Awarded under contract grant #  89233218CNA000001 to Triad National Security, LLC (“Triad”). We acknowledge contributions from Clement Roques for the exponential time step method implemented in `baseflow` and Aaron Clauset for `plfit`.

# References

<!-- these are here for convenience -->
<!-- @arciniega-esparza_2017_C&G
@arciniega-esparza_2018_
@brutsaert_1977_WRR
@brutsaert_1998_WRR
@clauset_2009_SR
@cooper_2023_WRR
@cooper_2018_WRR
@dralle_2017_HESS
@gnann_2021_EM&S
@hall_1968_WRR
@harman_2009_WRR
@jachens_2020_HESS
@kirchner_2009_WRR
@matlab_2020_
@roques_2017_AiWR
@rupp_2005_WRR
@rupp_2006_WRR
@troch_2013_WRR -->
