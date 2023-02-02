# `baseflow` - a matlab package for baseflow recession analysis

[![DOI](https://zenodo.org/badge/511647633.svg)](https://zenodo.org/badge/latestdoi/511647633) [![GitHub license](https://img.shields.io/github/license/mgcooper/baseflow)](https://github.com/mgcooper/baseflow/blob/main/LICENSE) ![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/mgcooper/baseflow?include_prereleases) [![MATLAB](https://github.com/mgcooper/baseflow/actions/workflows/ci.yml/badge.svg?branch=dev)](https://github.com/mgcooper/baseflow/actions/workflows/ci.yml)

<!-- [![View baseflow on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/<insert final part of baseflow link here>) -->

Baseflow recession analysis is a set of methods in hydrologic science used to estimate watershed properties from streamflow measurements. Properties that cannot be observed, such as hydraulic conductivity, are inferred from something that can be observed, such as streamflow. The underlying theory is based on solutions to the one-dimensional (lateral) groundwater flow equation ("Boussinesq equation").

For more information, see the [documentation](https://mgcooper.github.io/baseflow/).

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

In your Matlab environment:

- Type `help +bfra` at the command line then press enter to see a list of the `bfra` package contents. Also see `Contents.m`.
- Type `doc +bfra` to see the `bfra` package contents in the help browser.
- Type `doc bfra` to see the extended documentation.
- For a full-featured notebook, see `demos/demo_bfra.mlx`.

<!-- ## More details

The theory makes various strong assumptions, including that the aquifer extent is much larger in the lateral direction than the vertical, and that capillarity can be ignored or parameterized by the concept of 'drainable porosity'. This reduces the three-dimensional Richard's equation to one dimension and eliminates unsaturated flow considerations. The theory has been validated with laboratory experiments and may work better than you expect. When applied to entire catchments ("watersheds"), the theory becomes an effective one, meaning the inferred properties are those that give the same solution to the Boussinesq equation that one would obtain for a single hillslope with those same properties and geometric similarity. -->

## Contribute

If you find a bug, have a question, or want to contribute, feel free to open an [issue](https://github.com/mgcooper/baseflow/issues) or start a [discussion](https://github.com/mgcooper/baseflow/discussions).

Please see the [Style Guide](testbed/StyleGuide.md) before submitting.

## How do I cite this?

If you find this software useful, please consider citing the software release in `Citation.cff` or the following paper for which the `baseflow` software was developed:

    @ARTICLE{10.1029/2022WR033154,
    AUTHOR={Cooper, Matthew G, Zhou, Tian, Bennett, Katrina E, Bolton, W Robert, Coon, Ethan T, Fleming, Sean W, Rowland, Joel C, and Schwenk, Jon},
    TITLE={Detecting Permafrost Active Layer Thickness Change From Nonlinear Baseflow Recession},
    JOURNAL={Water Resources Research},
    VOLUME={59},
    PAGES={e2022WR033154},
    YEAR={2023},
    URL={https://doi.org/10.1029/2022WR033154},
    DOI={10.1029/2022WR033154},
    ISSN={1944-7973},
    }
