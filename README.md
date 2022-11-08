# `baseflow` - a matlab package for baseflow recession analysis

Baseflow recession analysis refers to a set of methods in hydrologic science designed to infer watershed properties that cannot be observed from something that can be observed - streamflow. The underlying theory is based on idealized solutions to the one-dimensional (lateral) groundwater flow equation ("Boussinesq equation"). Its application here is meant for shallow unconfined riparian aquifers, those that discharge subsurface flow into adjacent stream channels.

## Dependencies
Developed on MATLAB Version: 9.9.0 (R2020b)  
Mathworks Statistics and Machine Learning Toolbox&trade;  
Mathworks Curve Fitting Toolbox&trade;  


## Install

Run `Setup.m`:

- type `run Setup.m` (or just `Setup`) at the command line then press enter.
- If running in Octave, check `.octaverc`, it should source `Setup.m`.
- See `Setup.m` for additional configuration options. For example, you can activate `savepath` to save the paths to this package, to avoid running `Setup.m` every time you want to use this package.

## Usage

Type `doc bfra` to see the documentation.

See `demos/demo_bfra.mlx`.

Type `help +bfra` at the command line then press enter to see a list of the `bfra` package contents. Also see `Contents.m`.

## More details

The theory makes various strong assumptions, including that the aquifer extent is much larger in the lateral direction than the vertical, and that capillarity can ignored or parameterized by the concept of 'drainable porosity'. This reduces the three-dimensional Richard's equation to one dimension and eliminates unsaturated flow considerations. The theory has been validated with laboratory experiments and may work better than you expect. When applied to entire catchments ("watersheds"), the theory becomes an effective one, meaning the inferred properties are those that give the same solution to the Boussinesq equation that one would obtain for a single hillslope with those same properties and geometric similarity.

<!-- ## Please make it stop

To get started with baseflow recession analysis, clone this repo or download it from the matlab file exchange. Then open `bfra_example.mlx`. -->

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
