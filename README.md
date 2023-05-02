# `baseflow`

A matlab toolbox for characterizing aquifer properties from streamflow measurements using baseflow recession analysis. Developed at the Pacific Northwest National Laboratory to study changes in soil water storage in Arctic and Subarctic watersheds. Supported by the Interdisciplinary Research for Arctic Coastal Environments (InteRFACE) project. For a quick introduction, see [Getting Started](https://mgcooper.github.io/baseflow/).

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

In addition to the toolbox documentation and examples provided in the Matlab help browser, the notebook in `demos/bfra_kuparuk.mlx` replicates the analysis in the paper [Detecting Permafrost Active Layer Thickness Change From Nonlinear Baseflow Recession](https://doi.org/10.1029/2022WR033154). There are also several other notebooks in the `demos` folder that demonstrate how to use the toolbox functions, each of which are also available as html files in the `docs` folder, and are viewable in the Matlab help browser.

## Contribute

If you find a bug, have a question, or want to contribute, feel free to open an [issue](https://github.com/mgcooper/baseflow/issues) or start a [discussion](https://github.com/mgcooper/baseflow/discussions).

<!-- Consider the [Style Guide](testbed/StyleGuide.md) before submitting. -->

## How do I cite this?

If you find this software useful, please consider citing the software release in `Citation.cff` and/or the following paper for which the software was developed:

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

## Configuration

Installing the `baseflow` toolbox is as simple as cloning this repo and adding it to the matlab search path. Users should manage the toolbox however they normally manage their search path, for example, using the `startup.m` file. However, the `+bfra` namespace prefix means that package functions will not interfere with functions sharing the same name on the search path. This means it is ok to put this toolbox on your `userpath` if you want it available on startup.

For extended use of the toolbox, the convenience function `Setup.m` includes options to manage the toolbox installation and paths. Starting from an initial install in your local repo directory:

- Running `Setup('install')` does the following:
  - Toolbox paths are added to the search path (not persistent between sessions).
  - Default toolbox preferences are added to a new user preferences group `baseflow` (persistent between sessions).
  <!-- - Dependencies are checked using `bfra.util.dependencies` to determine if the required files are on the search path. -->
- Note that `Setup` does not modify `userpath`, does not call `savepath`, and never modifies the root-level `pathdef.m` file. It only calls `addpath` and `rmpath` to put the toolbox on the user search path.
- In subsequent sessions, toolbox paths can be managed like so:
  - `Setup('addpath')` or simply `Setup` with no arguments adds the toolbox to the search path for the current session.
  - `Setup('rmpath')` removes the toolbox from the search path for the current session.
- To display the current toolbox preferences try `getpref('baseflow')`.

Running `Setup('install')` should only be necessary once (or not at all, if you choose to manage your search path however you normally manage third-party matlab/octave software). However, Octave users may find Setup particularly convenient because Setup will load the required packages (but see [Octave](#octave) for compatibility note). Although all dependencies are nominally included in this toolbox, if users encounter any missing dependencies, please open an [issue](https://github.com/mgcooper/baseflow/issues).

<!-- Disabled this after moving all dependencies to package namespace folders and running built in matlab dependency report -->
 <!-- If for some reason a dependencies is found that is not on the search path, a message is printed to the screen. To see the list of missing dependencies, check the `msg` output. At any time, a dependencies check can be run using: -->

<!-- - `msg = Setup('dependencies')` -->

<!-- After installation, if Matlab is closed, the package will not be on the search path the next time Matlab is opened, unless the package folder is added to the search path on startup. For example, if the package parent folder is placed in the `userpath` folder, then it should be available on startup. Or, if a statement is added to the user `startup.m` file such as: `addpath(genpath(/full/path/to/this/package))`, that will add the package parent folder and subfolders to the search path.

This can also be accomplished using the provided `Setup()` function:
- Running `Setup()` with no arguments is equivalent to `Setup('addpath')`.

See `Setup.m` for additional configuration options -->

## Package namespace

The `baseflow` toolbox uses the package namespace prefix `+bfra`, short for **b**ase**f**low **r**ecession **a**nalysis. Package functions are accessed using dot notation: `bfra.<function name>`. If dot notation is used, the package does not need to be imported. The package is imported implicitly by the `+` prefix on the directory name, as long as the **toolbox** (not package) directory is on the matlab search path (i.e., the parent folder containing the `+bfra` package directory needs to be on the Matlab search path).

If desired, package functions can be imported into a workspace using `import bfra.<function name>`. Subsequent calls to the imported function can then omit the package prefix. The entire package can be imported using `import bfra.*`. However, imported functions are only available in the calling workspace. To use imported package functions in called functions or class definition files, import them again in those files or just use dot notation at all times, which is the convention used throughout the `baseflow` toolbox.

<!-- If any other `+bfra` packages exist on the search path, functions in all packages share the `+bfra` namespace, similar to a [python namespace package](https://packaging.python.org/en/latest/guides/packaging-namespace-packages/) -->

## Octave

Octave is not currently supported due to missing functionality in the `tablicious` package which is required to support Matlab's `datetime` objects. However, the toolbox is designed to be compatible with Octave, and work is in progress to patch the `datetime` incompatibilities. Until that time, the information below is provided for reference.

`baseflow` has been tested on macOS with Octave v8.1.0. Octave can be downloaded [here](https://octave.org/download.html). `baseflow` was developed on Matlab, and users may encounter unexpected behavior on Octave (please open an [issue](https://github.com/mgcooper/baseflow/issues)). If running in Octave, the following packages are required:

`struct`
`statistics`
`tablicious`

To see which packages are installed:
`pkg list`

To install packages, use the pkg command in Octave:

`pkg install -forge struct`
`pkg install -forge statistics`

Install tablicious from the repository:
`pkg install https://github.com/apjanke/octave-tablicious/archive/refs/heads/master.zip`

Each time you use the baseflow toolbox, these packages need to be loaded:
`pkg load struct`
`pkg load statistics`
`pkg load tablicious`

To see which packages are loaded, use `pkg list`, loaded packages will have an asterisk next to their name. Use the convenience function `Setup.m` to automatically import these packages.

The `pkg load` commands listed above are included in the .octaverc file. Depending on your configuration, it may or may not be sourced at startup. Octave users are encouraged to run `Setup` when using the toolbox, it will load the required packages and manage warnings. See `Setup.m` for more information.

Limitations when running in Octave:

- The live scripts in the `demos/` folder will not work on Octave (see `bfra_example_octave.m` for an octave-compatible example)
- Functions relying on `datetime` objects will not work on Octave.
- The extended non-linear curve fitting try-catch block in `bfra.fitab` may not work on Octave.
- Some graphics functions may not work on Octave, including those that use `gobjects`.

Work is ongoing to patch these incompatibilities.

When running in Octave, be careful with blanket `warning on` or `warning off` commands. Octave ships with about a dozen warning states off, listed below. If they are turned on by a `warning on` command, there will be endless warning messages. If this happens, type `warning` in the commandwindow to confirm if the following warnings are off. If so, simply restart Octave to reset them, or reset them manually.

```Octave
    State  Warning ID
    off  Octave:array-as-logical
    off  Octave:array-to-scalar
    off  Octave:array-to-vector
    off  Octave:imag-to-real
    off  Octave:language-extension
    off  Octave:missing-semicolon
    off  Octave:neg-dim-as-zero
    off  Octave:separator-insert
    off  Octave:single-quote-string
    off  Octave:str-to-num
    off  Octave:mixed-string-concat
    off  Octave:variable-switch-label
```

## Acknowledgement

The Interdisciplinary Research for Arctic Coastal Environments (InteRFACE) project funded this work through the United States Department of Energy, Office of Science, Biological and Environmental Research (BER) Regional and Global Model Analysis (RGMA) program. Awarded under contract grant #  89233218CNA000001 to Triad National Security, LLC (“Triad”).

<!-- `doc bfra` brings up the Contents pane in a small help box rather than the extended documentation in the help browser, try `doc` without any arguments, then scroll down to "Supplemental Software" and click on "Baseflow Recession Analysis Toolbox". Alternatively, try `docsearch bfra` to bring up the search results in the help browser. This is a known issue that may occur if the version of Matlab used to generate the documentation differs from the version running locally. -->

<!-- ```shell
git clone https://github.com/mgcooper/baseflow.git baseflow
cd baseflow
/Applications/MATLAB_R2020b.app/bin/matlab -nodisplay -nosplash -nodesktop -r "run('Setup.m');exit;" | tail -n +11
``` -->

<!-- ## Detailed information

Baseflow recession analysis is a set of methods in hydrologic science used to estimate aquifer properties from streamflow measurements. Properties that cannot be observed, such as hydraulic conductivity, are inferred from something that can be observed, such as streamflow. The underlying theory is based on solutions to the one-dimensional (lateral) groundwater flow equation ("Boussinesq equation"). 

The theory makes various strong assumptions, including that the aquifer extent is much larger in the lateral direction than the vertical, and that capillarity can be ignored or parameterized by the concept of 'drainable porosity'. This reduces the three-dimensional Richard's equation to one dimension and eliminates unsaturated flow considerations. The theory has been validated with laboratory experiments and may work better than you expect. When applied to entire catchments ("watersheds"), the theory becomes an effective one, meaning the inferred properties are those that give the same solution to the Boussinesq equation that one would obtain for a single hillslope with those same properties and geometric similarity. 
-->