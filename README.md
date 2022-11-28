# `baseflow` - a matlab package for baseflow recession analysis

[![DOI](https://zenodo.org/badge/511647633.svg)](https://zenodo.org/badge/latestdoi/511647633)

Baseflow recession analysis refers to a set of methods in hydrologic science designed to infer watershed properties from streamflow measurements. Properties that cannot be observed, such as hydraulic conductivity, are inferred from something that can be observed, such as streamflow. The underlying theory is based on solutions to the one-dimensional (lateral) groundwater flow equation ("Boussinesq equation"). Its application here is meant for shallow unconfined riparian aquifers that discharge subsurface flow into adjacent stream channels.

## Dependencies

Developed on MATLAB Version: 9.9.0 (R2020b)  
Mathworks Statistics and Machine Learning Toolbox&trade;  
Mathworks Curve Fitting Toolbox&trade;  
Various utility functions included in this package

## Install

Run `Setup.m`:

- type `run Setup.m` (or just `Setup`) at the command line then press enter.
- If running in Octave, check `.octaverc`, it should source `Setup.m`.
- See `Setup.m` for additional configuration options. For example, you can activate `savepath` to save the paths to this package, to avoid running `Setup.m` every time you want to use this package.

## Usage

There are a number of ways to get started:

- Type `help +bfra` at the command line then press enter to see a list of the `bfra` package contents. Also see `Contents.m`.

- Type `doc +bfra` to see the `bfra` package contents in the help browser.

- Type `doc bfra` to see the extended documentation.

For a full-featured example, see `demos/demo_bfra.mlx`.

<!-- ## More details

The theory makes various strong assumptions, including that the aquifer extent is much larger in the lateral direction than the vertical, and that capillarity can be ignored or parameterized by the concept of 'drainable porosity'. This reduces the three-dimensional Richard's equation to one dimension and eliminates unsaturated flow considerations. The theory has been validated with laboratory experiments and may work better than you expect. When applied to entire catchments ("watersheds"), the theory becomes an effective one, meaning the inferred properties are those that give the same solution to the Boussinesq equation that one would obtain for a single hillslope with those same properties and geometric similarity. -->

<!-- ## Please make it stop

To get started with baseflow recession analysis, clone this repo or download it from the matlab file exchange. Then open `bfra_example.mlx`. -->

## How do I cite this?

A dedicated software citation is coming soon. If you find this software useful, please consider citing the following paper for which this software was developed (in revision, citation pending):

<!-- @ARTICLE{10.3389/fninf.2018.00087,
AUTHOR={Cooper, Matthew G, Zhou, Tian, Bennett, Katrina E, Bolton, W Robert, Coon, Ethan T, Fleming, Sean W, Rowland, Joel C, and Schwenk, Jon},   
TITLE={Detecting permafrost active layer thickness change from nonlinear baseflow recession},      
JOURNAL={Water Resources Reearch},      
VOLUME={XX},      
PAGES={XX},     
YEAR={2022},      
URL={https://www.frontiersin.org/article/10.3389/fninf.2018.00087},       
DOI={10.3389/fninf.2018.00087},      
ISSN={1662-5196},   
} -->
