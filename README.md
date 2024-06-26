# `baseflow`

A matlab toolbox for characterizing aquifer properties from streamflow measurements using baseflow recession analysis. Developed at the Pacific Northwest National Laboratory to study changes in soil water storage in Arctic and Subarctic watersheds. Supported by the Interdisciplinary Research for Arctic Coastal Environments (InteRFACE) project.  

For an overview, see [Getting Started](https://mgcooper.github.io/baseflow/).  

[![status](https://joss.theoj.org/papers/d0adcf9e526c841f7265c30844c576a3/status.svg)](https://joss.theoj.org/papers/d0adcf9e526c841f7265c30844c576a3) [![DOI](https://zenodo.org/badge/511647633.svg)](https://zenodo.org/badge/latestdoi/511647633) ![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/mgcooper/baseflow?include_prereleases) [![MATLAB](https://github.com/mgcooper/baseflow/actions/workflows/run-tests.yml/badge.svg?branch=dev)](https://github.com/mgcooper/baseflow/actions/workflows/run-tests.yml) [![GitHub license](https://img.shields.io/github/license/mgcooper/baseflow)](https://github.com/mgcooper/baseflow/blob/main/LICENSE)

<!-- This is the joss badge but the status one above links to the same place -->
<!-- [![DOI](https://joss.theoj.org/papers/10.21105/joss.05492/status.svg)](https://doi.org/10.21105/joss.05492) -->

<!-- [![View baseflow on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/<insert final part of baseflow link here>) -->  

## Requirements

- MATLAB&reg;, developed on version 9.9.0 (R2020b).
  - Mathworks Statistics and Machine Learning Toolbox.  
  - Mathworks Curve Fitting Toolbox.  
- Octave, tested on version 8.2.0.  
  - Statistics, Optimization, Struct, Tablicious, and Statistics-bootstrap packages.  

## Install

- Clone this repo or use [`mpm`](http://mobeets.github.io/mpm/) in your Matlab terminal:
  - `mpm install baseflow`
- cd into the `toolbox` directory.
- Run `Setup.m`:
  - Type `msg = Setup('install')` at the command window then press enter.
  - Check `msg` for information about the installation.
- If running in Octave, see `.octaverc` for recommended startup options.
- Unit tests are in `tests/`. To run them from the top-level folder:
  - Type `runtests('tests')` at the command window and press enter.
  - To debug, try `runtests('tests', debug=true)`.
- In new Matlab sessions, cd to the toolbox directory and try `Setup('addpath')` or just `Setup` to add the toolbox to your search path (or manage the search path however you normally do).

For more options, see [Configuration](#configuration).  
For Octave compatibility, see [Octave](#octave).  

## Get started

Toolbox functions are in the `+baseflow` namespace. To see a list of toolbox functions, type `help +baseflow` at the command line then press enter. To see the help for a specific function, click on any of the hyperlinks, or type `help baseflow.<function_name>` at the command line then press enter.

Toolbox documentation is available in the Matlab help browser. To get started, in your Matlab command window:

- Type `baseflow.help()` to open the toolbox documentation in the help browser.
- Type `baseflow.help('<function_name>')` to open documentation for a specific function.
- Type `doc baseflow` or try `doc +baseflow` to see the package contents in the help browser.
- If the documentation does not open in the help browser, try `doc` without any arguments, then scroll down to "Supplemental Software" and click on "Baseflow Recession Analysis Toolbox". You can also try `docsearch baseflow`.

Notebooks are in `demos/`. The notebook `baseflow_demo_kuparuk.mlx` replicates the analysis in the paper [Detecting Permafrost Active Layer Thickness Change From Nonlinear Baseflow Recession](https://doi.org/10.1029/2022WR033154). Each demo is available as an html file in `toolbox/docs`. Double click to view them in the Matlab help browser, or use `baseflow.help(<docname>)`. All demos are available as live `.mlx` files compatible with Matlab, and as `.m` files compatible with both Matlab and Octave in the `demos/mfiles` folder.

## Contribute

If you find a bug, have a question, or want to contribute, feel free to open an [issue](https://github.com/mgcooper/baseflow/issues) or start a [discussion](https://github.com/mgcooper/baseflow/discussions).

<!-- Consider the [Style Guide](testbed/StyleGuide.md) before submitting. -->

## How do I cite this?

If you find this software useful, please consider citing the software release in `Citation.cff` and/or the following paper for which the software was developed:

```bib
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
```

## Configuration

Installing `baseflow` is as simple as cloning this repo and adding it to the Matlab search path. Users should manage the toolbox however they normally manage their search path, for example using `startup.m`. Note that functions in the `+baseflow` namespace will not interfere with functions sharing the same name on the search path, so feel free to put the toolbox on your `userpath` if you want it available on startup.

For more control, use the convenience function `Setup.m` to manage the toolbox installation and paths. Starting from an initial install in your local repo directory:

- Running `Setup('install')` does the following:
  - Toolbox paths are added to the search path (not persistent between sessions).
  - Default toolbox preferences are added to a new user preferences group `baseflow` (persistent between sessions).
  <!-- - Dependencies are checked using `baseflow.internal.dependencies` to determine if the required files are on the search path. -->
- Note that `Setup` does not modify `userpath`, does not call `savepath`, and never modifies the root-level `pathdef.m` file. It only calls `addpath` and `rmpath` to add and remove the toolbox from the search path.
- In subsequent sessions, toolbox paths can be managed like so:
  - `Setup('addpath')` or simply `Setup` with no arguments adds the toolbox to the search path for the current session.
  - `Setup('rmpath')` removes the toolbox from the search path for the current session.
- To display the current toolbox preferences try `getpref('baseflow')`.

Running `Setup('install')` should only be necessary once (or not at all, if you choose to manage your search path however you normally manage third-party Matlab/Octave software). However, Octave users may find `Setup` particularly convenient because it will load the required packages. Although all dependencies are nominally included in this toolbox, if users encounter any missing dependencies, please open an [issue](https://github.com/mgcooper/baseflow/issues).

<!-- Disabled this after moving all dependencies to package namespace folders and running built in matlab dependency report -->
 <!-- If for some reason a dependencies is found that is not on the search path, a message is printed to the screen. To see the list of missing dependencies, check the `msg` output. At any time, a dependencies check can be run using: -->

<!-- - `msg = Setup('dependencies')` -->

<!-- After installation, if Matlab is closed, the package will not be on the search path the next time Matlab is opened, unless the package folder is added to the search path on startup. For example, if the package parent folder is placed in the `userpath` folder, then it should be available on startup. Or, if a statement is added to the user `startup.m` file such as: `addpath(genpath(/full/path/to/this/package))`, that will add the package parent folder and subfolders to the search path.

This can also be accomplished using the provided `Setup()` function:
- Running `Setup()` with no arguments is equivalent to `Setup('addpath')`.

See `Setup.m` for additional configuration options -->

## Package namespace

The `baseflow` toolbox uses the package namespace `+baseflow`. Package functions are accessed using dot notation: `baseflow.<function name>`. The package does not need to be imported, but the parent folder containing the `+baseflow` package folder (i.e., the **toolbox** folder) needs to be on the Matlab search path.

If desired, package functions can be imported into a workspace using `import baseflow.<function name>`. Subsequent calls to the imported function can omit the package prefix. The entire package can be imported using `import baseflow.*`. However, imported functions are only available in the calling workspace. To use imported package functions in called functions or class definition files, import them again in those files or just use dot notation at all times, which is the convention used throughout the `baseflow` toolbox.

<!-- If any other `+baseflow` packages exist on the search path, functions in all packages share the `+baseflow` namespace, similar to a [python namespace package](https://packaging.python.org/en/latest/guides/packaging-namespace-packages/) -->

## Octave

Octave is supported but `baseflow` was developed on Matlab, and users may encounter unexpected behavior on Octave (please open an [issue](https://github.com/mgcooper/baseflow/issues)). In particular, `baseflow` uses the [`tablicious`](https://github.com/apjanke/octave-tablicious) package for `string` and `datetime` support, but `tablicious` does not fully support these objects. `baseflow` was tested on macOS with Octave v8.1.0 and 8.2.0. Octave can be downloaded [here](https://octave.org/download.html). If running in Octave, the following packages are required:

`struct`  
`optim`  
`statistics`  
`tablicious`  
`statistics-bootstrap`  
`financial`  

For some demos, the `Symbolic` package is needed.  

To see which packages are installed:
`pkg list`

To install packages, use the pkg command in Octave:

`pkg install -forge struct`  
`pkg install -forge optim`  
`pkg install -forge statistics`  

Install tablicious from the repository:  
`pkg install https://github.com/apjanke/octave-tablicious/archive/refs/heads/master.zip`

To load a package, use `pkg load <pkgname>`. To see which packages are loaded, use `pkg list`, loaded packages will have an asterisk next to their name. Use the convenience function `Setup.m` to automatically import required packages.

The `pkg load` commands listed above are included in the .octaverc file. Depending on your configuration, it may or may not be sourced at startup. Octave users are encouraged to run `Setup` when using the toolbox, it will load the required packages and manage warnings. See `Setup.m` for more information.

Limitations when running in Octave:

- The live scripts in the `demos/` folder will not work on Octave, use the `.m` files instead.
- Functions relying on `datetime` objects may not work on Octave.
- Graphics objects are not supported in Octave, including `gobjects` which may cause errors.
- Latex interpreter is not supported in Octave.

Work is ongoing to patch these incompatibilities. See `+baseflow/private/isoctave` to patch errors.

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

<!-- ```shell
git clone https://github.com/mgcooper/baseflow.git baseflow
cd baseflow
/Applications/MATLAB_R2020b.app/bin/matlab -nodisplay -nosplash -nodesktop -r "run('Setup.m');exit;" | tail -n +11
``` -->

<!-- ## Detailed information

Baseflow recession analysis is a set of methods in hydrologic science used to estimate aquifer properties from streamflow measurements. Properties that cannot be observed, such as hydraulic conductivity, are inferred from something that can be observed, such as streamflow. The underlying theory is based on solutions to the one-dimensional (lateral) groundwater flow equation ("Boussinesq equation"). 

The theory makes various strong assumptions, including that the aquifer extent is much larger in the lateral direction than the vertical, and that capillarity can be ignored or parameterized by the concept of 'drainable porosity'. This reduces the three-dimensional Richard's equation to one dimension and eliminates unsaturated flow considerations. The theory has been validated with laboratory experiments and may work better than you expect. When applied to entire catchments ("watersheds"), the theory becomes an effective one, meaning the inferred properties are those that give the same solution to the Boussinesq equation that one would obtain for a single hillslope with those same properties and geometric similarity. 
-->