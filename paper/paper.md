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

# Summary

`baseflow` is a MATLAB&reg; [@matlab_2022_] toolbox designed for baseflow recession analysis, a technique used in hydrologic science to infer aquifer properties from streamflow [@brutsaert_1977_WRR]. Leveraging widely-available streamflow data, the toolbox can be used to estimate aquifer properties such as hydraulic conductivity and drainable porosity over the modern instrumental stream gage record. The toolbox is intended for analysis of measured streamflow values recorded on a daily timestep, and is tailored for shallow, unconfined riparian aquifers that discharge groundwater laterally into adjacent streams. Additionally, `baseflow` can analyze the collective behavior of individual hillslope aquifers constituting hydrologic catchments, known as "watersheds", from a nonlinear dynamical systems perspective [@kirchner_2009_WRR]. The toolbox incorporates recent advances in baseflow recession analysis [@roques_2017_AiWR; @dralle_2017_HESS; @cooper_2023_WRR] to enable objective estimations of aquifer properties, and their sensitivity to methodological decisions, at both hillslope and catchment scales.

# Statement of need

Baseflow is a vital component of streamflow sourced exclusively from aquifer discharge, rather than rainfall, surface water, or managed reservoir release [@hall_1968_WRR]. Baseflow essentially reflects the delayed release of groundwater storage into streams, and sustains water availability during dry seasons, especially in regions with limited surface water storage [@cooper_2018_WRR]. Baseflow is therefore important for managing water scarcity, and understanding the baseflow recession process is a central task in hydrologic science [@hall_1968_WRR; @kirchner_2009_WRR; @troch_2013_WRR].

The baseflow recession curve captures the decline in streamflow during low-flow periods [@brutsaert_1977_WRR]. Parameters derived from this curve can be used to estimate unconfined aquifer properties, including hydraulic conductivity, drainable porosity, and the saturated zone thickness [@brutsaert_1998_WRR; @troch_1993_WRR; @rupp_2006_WRR]. Detecting baseflow segments from measured streamflow data, however, is a complex task that requires signal processing, curve fitting, and parameter estimation algorithms, further complicated by measurement error and noise [@dralle_2017_HESS; @rupp_2006_AiWR].

\bigskip
\begin{figure}[!tbh]
\centering
\includegraphics[width=\textwidth]{figure_1.png}
\caption{Example of baseflow recession analysis using the `baseflow` toolbox. (a) Daily discharge hydrograph for the Kuparuk River, Alaska recorded at United States Geological Survey gage 1596000 and one detected recession event. (b-c) Observed and fitted discharge values ($Q$) and their rate of change ($-\mathrm{d}Q/\mathrm{d}t$) for the event highlighted in (a). (d) Log-log relationship between $Q$ and $-\mathrm{d}Q/\mathrm{d}t$, comparing three fitting methods to estimate parameters $a$ and $b$: ordinary least squares (ols), nonlinear least squares (nls), and quantile regression (qtl).}
\label{fig:figure_1}
\end{figure}

The `baseflow` API offers a user-friendly interface for essential baseflow recession analysis tasks, including event detection, parameter fitting, and visualization (\autoref{fig:figure_1}). The toolbox also addresses the nonlinear behavior of baseflow, which can arise due to rate-dependent hydraulic properties [@rupp_2006_WRR], or the nonlinear collective behavior of hillslope aquifer units that comprise watersheds [@harman_2009_WRR]. `baseflow` is primarily intended for hydrologic research, and provides a foundational tool for studying groundwater storage changes in Arctic and Subarctic regions affected by permafrost thaw [@cooper_2023_WRR]. The toolbox also includes several interactive notebooks that introduce linear and nonlinear reservoir theory, serving as educational resources for hydrologic science.

# State of the field

Several publicly available software packages provide standardized methods for baseflow recession analysis [@dralle_2017_HESS; @gnann_2021_EM&S; @arciniega-esparza_2018_]. These tools focus on estimating the canonical parameters of the event-scale recession equation (\ref{eq:aQb}), which relate the rate of change of streamflow to streamflow itself:

<!-- $$-\frac{dQ}{dt} = aQ^b$$ -->
\begin{equation}\label{eq:aQb}
-\dfrac{\mathrm{d}Q}{\mathrm{d}t}=aQ^b
\end{equation}

where $Q$ is streamflow, $t$ is time, and recession parameters $a$ and $b$ determine the shape of the recession curve (\autoref{fig:figure_1}).

Two MATLAB-based toolboxes for baseflow recession analysis are available to our knowledge. The `HYDRORECESSION` [@arciniega-esparza_2017_C&G; @arciniega-esparza_2018_] toolbox provides methods to detect recession events and fit \autoref{eq:aQb}, organized around a graphical user interface (GUI). Relative to `HYDRORECESSION`, the `baseflow` toolbox offers additional features for aquifer property estimation, such as saturated aquifer thickness, hydraulic conductivity, and drainable porosity. `HYDRORECESSION` and `baseflow` both provide methods for fitting both linear and nonlinear forms of \autoref{eq:aQb} based on alternative solutions to the one-dimensional lateral groundwater flow equation. `baseflow` could benefit from similar GUI capabilities, and the digital-filter baseflow separation methods available in `HYDRORECESSION`.

The Toolbox for Streamflow Signatures in Hydrology (`TOSSH`) [@gnann_2021_EM&S] provides recession event-detection and curve fitting algorithms but is broader in scope than both `baseflow` and `HYDRORECESSION`. For example, `TOSSH` provides automated estimation of several dozen quantitative streamflow metrics known as "hydrologic signatures", including recession parameters $a$ and $b$. It provides a narrower toolkit for estimating $a$ and $b$, and limited options for interpreting their values in terms of hydraulic groundwater theory. However, `TOSSH` provides a unique capability for interpreting $a$ and $b$ empirically in terms of hydrologic signatures. Although `baseflow` is designed for hillslope- and catchment-scale aquifer characterization, it could benefit from a broader scope that includes methods for quantifying evapotranspiration, which impacts estimates of $a$ and $b$ [@jachens_2020_HESS].

# Unique functionality: power-law scaling of recession parameters

The `baseflow` toolbox uniquely offers an automated Pareto distribution parameter-fitting module for aquifer characterization, motivated by a recent derivation of the Pareto transformation of \autoref{eq:aQb} [@cooper_2023_WRR]. To do so, the toolbox utilizes the function `plfit` [@clauset_2009_SR], translating its notation and functional forms to those of hydraulic groundwater theory. This probabilistic approach provides theoretically unbiased estimates of $a$ and $b$ for late-time aquifer drainage, which are necessary to obtain meaningful estimates of aquifer properties from baseflow recession analysis.

# Software Availability

`baseflow` is [on GitHub](https://github.com/mgcooper/baseflow/tree/joss).

# Acknowledgements

The Interdisciplinary Research for Arctic Coastal Environments (InteRFACE) project funded this work through the United States Department of Energy, Office of Science, Biological and Environmental Research (BER) Regional and Global Model Analysis (RGMA) program. Awarded under contract grant #  89233218CNA000001 to Triad National Security, LLC (“Triad”). We acknowledge contributions from Clement Roques for the exponential time step method implemented in `baseflow` and Aaron Clauset for `plfit`.

# References
