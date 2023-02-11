# `baseflow`

A matlab toolbox for characterizing aquifer properties from streamflow measurements using baseflow recession analysis. Developed at the Pacific Northwest National Laboratory to study changes in soil water storage in Arctic and Subarctic watersheds due to thawing permafrost. Supported by the Interdisciplinary Research for Arctic Coastal Environments (InteRFACE) project.

[![DOI](https://zenodo.org/badge/511647633.svg)](https://zenodo.org/badge/latestdoi/511647633) ![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/mgcooper/baseflow?include_prereleases) [![MATLAB](https://github.com/mgcooper/baseflow/actions/workflows/ci.yml/badge.svg?branch=dev)](https://github.com/mgcooper/baseflow/actions/workflows/ci.yml) [![GitHub license](https://img.shields.io/github/license/mgcooper/baseflow)](https://github.com/mgcooper/baseflow/blob/main/LICENSE)

<!-- [![View baseflow on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/<insert final part of baseflow link here>) -->

## Dependencies

Developed on MATLAB Version: 9.9.0 (R2020b)  
Mathworks Statistics and Machine Learning Toolbox&trade;  
Mathworks Curve Fitting Toolbox&trade;  
Various utility functions included in this toolbox

## Install

- Clone this repo **or** use [`mpm`](http://mobeets.github.io/mpm/) in your Matlab terminal:
  - `mpm install baseflow`
- cd into the toolbox top-level directory.
- Run `Setup.m`:
  - Type `msg = Setup('install')` at the command line then press enter.
  - Check `msg` for information about the installation.
- If running in Octave, see `.octaverc`, it should source `Setup.m`.
- To use the toolbox in new Matlab sessions, navigate to the toolbox directory and try `Setup('addpath')` or just `Setup` to add the toolbox to your search path, or manage the search path however you normally do.

For more options, see [Configuration](#configuration).

## Get started

Toolbox functions are located in the `+bfra` namespace package folder. To get started using the toolbox, in your Matlab environment:

- Type `doc bfra` to see the extended documentation in the help browser.
- Type `help +bfra` at the command line then press enter to list the package contents.
- Type `doc +bfra` to see the package contents in the help browser.
- See the example notebook `demos/demo_bfra.mlx`.

For an introduction, see [Getting Started](https://mgcooper.github.io/baseflow/).

<!-- ## More details

The theory makes various strong assumptions, including that the aquifer extent is much larger in the lateral direction than the vertical, and that capillarity can be ignored or parameterized by the concept of 'drainable porosity'. This reduces the three-dimensional Richard's equation to one dimension and eliminates unsaturated flow considerations. The theory has been validated with laboratory experiments and may work better than you expect. When applied to entire catchments ("watersheds"), the theory becomes an effective one, meaning the inferred properties are those that give the same solution to the Boussinesq equation that one would obtain for a single hillslope with those same properties and geometric similarity. -->

## Contribute

If you find a bug, have a question, or want to contribute, feel free to open an [issue](https://github.com/mgcooper/baseflow/issues) or start a [discussion](https://github.com/mgcooper/baseflow/discussions).

<!-- Consider the [Style Guide](testbed/StyleGuide.md) before submitting. -->

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

<!-- ```shell
git clone https://github.com/mgcooper/baseflow.git baseflow
cd baseflow
/Applications/MATLAB_R2020b.app/bin/matlab -nodisplay -nosplash -nodesktop -r "run('Setup.m');exit;" | tail -n +11
``` -->

<!-- ## Detailed information

Baseflow recession analysis is a set of methods in hydrologic science used to estimate aquifer properties from streamflow measurements. Properties that cannot be observed, such as hydraulic conductivity, are inferred from something that can be observed, such as streamflow. The underlying theory is based on solutions to the one-dimensional (lateral) groundwater flow equation ("Boussinesq equation"). -->

## Configuration

Installing the `baseflow` toolbox is as simple as cloning this repo and adding it to the matlab search path. Users should manage the toolbox however they normally manage their search path, for example by modifying their `startup.m` file. The `+bfra` namespace prefix means that package functions will not interfere with functions sharing the same name on the search path. This means it is ok to put this toolbox on your `userpath` if you want it available on startup.

The convenience function `Setup.m` includes options to manage repeated use of the toolbox. Starting from an initial installation:

- Running `Setup('install')` does the following:
  - Toolbox paths are added to the search path (not persistent between sessions).
  - Default toolbox preferences are added to a new user preferences group `baseflow` (persistent between sessions).
  - Dependencies are checked using `bfra.util.dependencies` to determine if the required files are on the search path.
- Note that `Setup` does not modify `userpath`, does not call `savepath`, and never modifies the root-level `pathdef.m` file. It only calls `addpath` and `rmpath` to put the toolbox on the user search path.
- In subsequent sessions, toolbox paths can be managed like so:
  - `Setup('addpath')` or simply `Setup` with no arguments adds the toolbox to the search path for the current session.
  - `Setup('rmpath')` removes the toolbox from the search path for the current session.
- To display the current toolbox preferences try `getpref('baseflow')`.

Running `Setup('install')` should only be necessary once. Note that all dependencies are included in this toolbox, and are added to the search path during installation. If for some reason the dependencies are not found on the search path, a message is printed to the screen. To see the list of missing dependencies, check the `msg` output. At any time, a dependencies check can be run using:

- `msg = Setup('dependencies')`

<!-- After installation, if Matlab is closed, the package will not be on the search path the next time Matlab is opened, unless the package folder is added to the search path on startup. For example, if the package parent folder is placed in the `userpath` folder, then it should be available on startup. Or, if a statement is added to the user `startup.m` file such as: `addpath(genpath(/full/path/to/this/package))`, that will add the package parent folder and subfolders to the search path.

This can also be accomplished using the provided `Setup()` function:
- Running `Setup()` with no arguments is equivalent to `Setup('addpath')`.

See `Setup.m` for additional configuration options -->

## Package namespace

The `baseflow` toolbox uses the package namespace prefix `+bfra`, short for **b**ase**f**low **r**ecession **a**nalysis. Package functions are accessed using dot notation: `bfra.<function name>`. If dot notation is used, the package does not need to be imported. The package is imported implicitly by the `+` folder prefix, as long as the toolbox directory is on the matlab search path. Functions can be imported into a workspace using `import bfra.<function name>`. Subsequent calls to the imported function can then omit the package prefix. The entire package can be imported using `import bfra.*`. However, imported functions are only available in the calling workspace. To use imported package functions in called functions or class definition files, import them again in those files or just use dot notation at all times, which is the convention used throughout the `baseflow` toolbox.

<!-- If any other `+bfra` packages exist on the search path, functions in all packages share the `+bfra` namespace, similar to a [python namespace package](https://packaging.python.org/en/latest/guides/packaging-namespace-packages/) -->

## Acknowledgement

The Interdisciplinary Research for Arctic Coastal Environments (InteRFACE) project funded this work through the United States Department of Energy, Office of Science, Biological and Environmental Research (BER) Regional and Global Model Analysis (RGMA) program. Awarded under contract grant #  89233218CNA000001 to Triad National Security, LLC (“Triad”).
