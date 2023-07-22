# `baseflow` - a matlab package for baseflow recession analysis

<!-- [![View baseflow on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/<insert final part of baseflow link here>) -->  

## Dependencies

Developed on MATLAB Version: 9.9.0 (R2020b).  
Mathworks Statistics and Machine Learning Toolbox&trade;.  
Mathworks Curve Fitting Toolbox&trade;.  
Compatible with Octave, tested on version 8.2.0.  
Requires Statistics, Optimization, Struct, and Tablicious packages.  

## Install

- Clone this repo **or** use [`mpm`](http://mobeets.github.io/mpm/) in your Matlab terminal:
  - `mpm install baseflow`
- cd into the toolbox top-level directory.
- Run `Setup.m`:
  - Type `msg = Setup('install')` at the command line then press enter.
  - Check `msg` for information about the installation.
- If running in Octave, see `.octaverc`, it should source `Setup.m`.
- Unit tests are located in `+bfra/+test`, they can be run in a matlab session by typing `bfra.test.runtests` at the command window and pressing enter.
- To use the toolbox in new Matlab sessions, navigate to the toolbox directory and try `Setup('addpath')` or just `Setup` to add the toolbox to your search path, or manage the search path however you normally do.

For more options, see [Configuration](#configuration).  
For Octave compatibility, see [Octave](#octave).  

## Get started

Toolbox functions are located in the `+bfra` namespace package folder. To see a list of toolbox functions, type `help +bfra` at the command line then press enter. To see the help for a specific function, click on any of the hyperlinks, or type `help bfra.function_name` at the command line then press enter.

Toolbox documentation and examples are also available in the Matlab help browser. To get started, in your Matlab command window:

- Type `doc baseflow` to open the documentation in the help browser.
- Type `doc bfra` or try `doc +bfra` to see the package contents in the help browser.
- If the documentation does not open in the help browser, try `doc` without any arguments, then scroll down to "Supplemental Software" and click on "Baseflow Recession Analysis Toolbox". You can also try `docsearch bfra`.

In addition to the toolbox documentation and examples provided in the Matlab help browser, there are several notebooks in `demos/`. The notebook `bfra_kuparuk.mlx` replicates the analysis in the paper [Detecting Permafrost Active Layer Thickness Change From Nonlinear Baseflow Recession](https://doi.org/10.1029/2022WR033154). Several other notebooks in the `demos` folder demonstrate how to use the toolbox functions, each of which are also available as html files in the `docs` folder, and are viewable in the Matlab help browser. All demos are available as live `.mlx` files compatible with Matlab, and as `.m` files compatible with Octave.

## Contribute

If you find a bug, have a question, or want to contribute, feel free to open an [issue](https://github.com/mgcooper/baseflow/issues) or start a [discussion](https://github.com/mgcooper/baseflow/discussions).

<!-- Consider the [Style Guide](testbed/StyleGuide.md) before submitting. -->

## How do I cite this?

<!-- @ARTICLE{10.3389/fninf.2018.00087,
AUTHOR={Gorur-Shandilya, Srinivas and Hoyland, Alec and Marder, Eve},   
TITLE={Xolotl: An Intuitive and Approachable Neuron and Network Simulator for Research and Teaching},      
JOURNAL={Frontiers in Neuroinformatics},      
VOLUME={12},      
PAGES={87},     
YEAR={2018},      
URL={https://www.frontiersin.org/article/10.3389/fninf.2018.00087},       
DOI={10.3389/fninf.2018.00087},      
ISSN={1662-5196},   
} -->

The theory makes various strong assumptions, including that the aquifer extent is much larger in the lateral direction than the vertical, and that capillarity can be ignored or parameterized by the concept of 'drainable porosity'. This reduces the three-dimensional Richard's equation to one dimension and eliminates unsaturated flow considerations. The theory has been validated with laboratory experiments and may work better than you expect. When applied to entire catchments ("watersheds"), the theory becomes an effective one, meaning the inferred properties are those that give the same solution to the Boussinesq equation that one would obtain for a single hillslope with those same properties and geometric similarity. 
-->