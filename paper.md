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
date: DD February YYYY
bibliography: paper.bib
---

# Summary
<!-- Begin your paper with a summary of the high-level functionality of your software for a non-specialist reader. Avoid jargon in this section -->
`baseflow` is a MATLAB&reg; [@matlab_2020_] toolbox for baseflow recession analysis. Baseflow recession analysis refers to a set of methods in hydrologic science that are used to infer aquifer properties from streamflow measurements . In particular, aquifer properties that cannot be measured directly, such as hydraulic conductivity, are inferred from streamflow, which is measured routinely at streamflow gages worldwide [@brutsaert_1977_WRR]. The wide availability of streamflow measurements means that baseflow recession analysis can be used to estimate aquifer properties and their variation at a global scale over time periods that span the modern instrumental stream gage record. The `baseflow` toolbox provides easy-to-use functions to conduct baseflow recession analysis using measured values of streamflow recorded on a daily timestep. It is designed for shallow (depth << breadth) unconfined riparian aquifers that discharge groundwater laterally into adjacent stream channels, rather than confined aquifers or complex geologic structures for which specialized numerical groundwater models are appropriate. The toolbox can also be used to study the collective behavior of individual hillslope aquifers that comprise hydrologic catchments ("watersheds") using a non-linear dynamical systems perspective [@kirchner_2009_WRR]. Overall, `baseflow` enables consistent, objective estimation of unconfined hillslope aquifer properties and conceptual catchment-scale aquifer properties using recent advancements in the baseflow recession analysis literature [@roques_2017_AiWR; @dralle_2017_HESS].

# Statement of need

Baseflow refers to streamflow that originates from groundwater rather than rainfall, surface flow, managed reservoir release, or any source other than groundwater [@hall_1968_WRR]. Baseflow can be thought of as the water flowing in a river many days or weeks after other water sources such as rainfall or snowmelt have ceased. In that sense, baseflow is a critical water resource because it sets a lower bound on water availability during dry seasons, especially in systems that lack surface water storage [@cooper_2018_WRR]. Typically, baseflow is not directly observed, but rather must be inferred from measured values of streamflow. Inferring the presence or amount of baseflow involves signal processing, curve-fitting, and parameter estimation, which calls for specialized algorithms [@dralle_2017_HESS]. In addition to the basic determination of baseflow amount in a given river, the shape of the baseflow recession curve can be used to infer physical properties of aquifers, which are the geological structures that store and release groundwater to rivers [@brutsaert_1998_WRR; @troch_2013_WRR].

![Example of baseflow recession analysis and the core functionality of the `baseflow` toolbox. \label{fig:figure01}](figure01_joss.png)
<!-- Figure sizes can be customized by adding an optional second parameter: -->
<!-- ![Caption for example figure.](figure.png){ width=20% } -->

The API for `baseflow` was designed to provide a user-friendly interface to common operations such as baseflow recession event detection, event-scale parameter fitting, event-ensemble probability-distribution fitting, and visualization \autoref{fig:figure01}. `baseflow` emphasizes the non-linear nature of streamflow, which may arise from rate-dependent or spatial nonlinearity in underlying hydraulic properties [@rupp_2006_WRR], or from the nonlinear collective behavior of hillslope aquifer units that comprise hydrologic catchments [@harman_2009_WRR]. `baseflow` was designed to be used by researchers in the hydrologic sciences [@cooper_2023_WRR] and forms the basis of an ongoing investigation of changing groundwater storage capacity in Arctic and Subarctic catchments due to the gradual thawing of permafrost.

# State of the field

Publicly available software packages for objective and repeatable baseflow recession analysis have recently been made available [@dralle_2017_HESS; @gnann_2021_EM&S; @arciniega-esparza_2018_]. This is notable because baseflow recession analysis is notoriously sensitive to methodological decisions, which are often poorly documented [@dralle_2017_HESS]. Among the publicly available baseflow recession analysis packages reviewed here, there is a common focus on estimating the canonical parameters of the event-scale recession equation:

<!-- $$-\frac{dQ}{dt} = aQ^b$$ -->
\begin{equation}\label{eq:aQb}
-\dfrac{\mathrm{d}Q}{\mathrm{d}t}=aQ^b
\end{equation}

where $Q$ is streamflow, $t$ is time, and recession parameters $a$ and $b$ determine the shape of the recession curve \autoref{fig:figure01}.

Two software packages for baseflow recession analysis are available within the MATLAB ecosystem. `HYDRORECESSION` [@arciniega-esparza_2017_C&G; @arciniega-esparza_2018_] is a MATLAB toolbox organized around a graphical user interface (GUI) that provides methods to detect recession events and fit \autoref{eq:aQb}. Relative to `HYDRORECESSION`, the `baseflow` toolbox offers more features for aquifer property estimation in addition to the estimation of $a$ and $b$, including saturated aquifer thickness, saturated hydraulic conductivity, drainable porosity, and the characteristic drainage timescale. `HYDRORECESSION` and `baseflow` both provide methods libaries for fitting alternative forms of \autoref{eq:aQb} based on various solutions to the one-dimensional lateral groundwater flow equation. `baseflow`  would benefit from incorporating two of the four forms given in `HYDRORECESSION` which are not currently supported. In addition, basic data exploration with `baseflow` would benefit from the GUI provided by `HYDRORECESSION`.

The Toolbox for Streamflow Signatures in Hydrology (`TOSSH`) [@gnann_2021_EM&S] provides recession event-detection and curve-fitting algorithms but is broader in scope than `baseflow` and `HYDRORECESSION`. For example, `TOSSH` provides automated estimation of several dozen quantitative metrics of streamflow referred to as "hydrologic signatures", of which recession parameters $a$ and $b$ are members. Accordingly, `TOSSH` provides a narrower toolkit for estimating $a$ and $b$, and limited options for interpreting their values in terms of hydraulic groundwater theory. In contrast, `TOSSH` provides unique capability for interpreting $a$ and $b$ empirically in terms of hydrologic signatures. Although `baseflow` is intended as a tool for hillslope- and catchment-scale aquifer characterization, it might benefit from a slightly broader scope. For example, estimates of $a$ and $b$ are sensitive to evapotranspiration [@jachens_2020_HESS] but unlike `TOSSH`, `baseflow` does not provide methods for quantifying evapotranspiration, which would enable estimates of its impact on aquifer characterization.

# Unique functionality: power-law scaling of recession parameters

Development of the `baseflow` toolbox was motivated by the need to automate Pareto distribution ("power-law") fits to large-sample recession parameter ensembles, based on a recent derivation of the Pareto transformation of Equation 1 [@cooper_2023_WRR]. To our knowledge, `baseflow` provides the only automated Pareto distribution parameter fitting module for aquifer characterization. To implement this, `baseflow` wraps the widely-used (>10,000 citations) function `plfit` (and related functions) implemented in MATLAB [@clauset_2009_SR]. The wrapper effectively acts as a translator from the notation and functional forms of `plfit` to the notation and functional forms of hydraulic groundwater theory. The Pareto-fitting method implemented in `baseflow` is particularly important because it provides theoretically unbiased estimates of $a$ and $b$ for late-time aquifer drainage.

# Acknowledgements

The Interdisciplinary Research for Arctic Coastal Environments (InteRFACE) project funded this work through the United States Department of Energy, Office of Science, Biological and Environmental Research (BER) Regional and Global Model Analysis (RGMA) program. Awarded under contract grant #  89233218CNA000001 to Triad National Security, LLC (“Triad”). We acknowledge contributions from Clement Roques for the exponential time step method implemented in `baseflow` and Aaron Clauset for `plfit`.

# References