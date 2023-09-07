%% Getting Started with the Baseflow Toolbox
%% Description
% Baseflow recession analysis is a set of methods in hydrologic science that 
% aim to estimate unobservable aquifer properties, such as hydraulic conductivity, 
% from readily available streamflow records. This toolbox provides high-level 
% MATLAB APIs that standardize the process of conducting baseflow recession analysis 
% using daily streamflow data. The methods implemented in this toolbox are based 
% on solutions to the one-dimensional groundwater flow equation and are intended 
% primarily for application to shallow, unconfined riparian aquifers discharging 
% subsurface flow into adjacent stream channels.
%% Download
% Clone or fork the repository <https://github.com/mgcooper/baseflow on Github>.
%% Installation
% Place all files and folders in their own folder (e.g. |baseflow|) and then 
% add that folder to the Matlab search path. Alternatively, run the included |Setup.m| 
% installation function: 
%%
% 
%   Setup('install') % for an initial install.
%
%% 
% In subsequent sessions:
%%
% 
%   Setup('addpath') % or just Setup(), to add all toolbox paths to the search path.
%
%% System Requirements
% This toolbox depends on the following Mathworks products: 
%% 
% * <https://www.mathworks.com/products/statistics.html Statistics and Machine 
% Learning Toolbox>™. 
% * <https://www.mathworks.com/products/curvefitting.html Curve Fitting Toolbox>™.
%% Accessing Help
% Need help? To see a list of toolbox functions, at the command window type: 
%%
% 
%   doc +bfra
%
%% 
% To see the complete toolbox documentation in the MATLAB Help browser, type:
%%
% 
%   bfra.help()
%
%% 
% To see the documentation for a specific function, type: 
%%
% 
%   bfra.help('function_name')
%
%% 
% where |function_name| is the name of a toolbox function. For example, |bfra.help('getevents')| 
% opens the help page for |getevents| in the Help browser. Use tab-completion 
% to see the full menu of documented toolbox functions.
% 
% Toolbox documentation can also be accessed by typing |doc()| without any arguments 
% to open the Help browser, then navigate to the documentation home page, scroll 
% down to *Supplemental Software* at the bottom of the page, and click on *Baseflow 
% Recession Analysis Toolbox*.
%% Toolbox Features
% The toolbox supports three main features:
%% 
% # Baseflow recession event-detection.
% # Baseflow recession curve-fitting.
% # Aquifer property estimation.
%% 
% These features are exposed to the user by three APIs (high-level matlab functions 
% that simplify toolbox use):
%% 
% # |bfra.getevents| Detect recession events from daily streamflow timeseries.
% # |bfra.fitevents| Curve-fit all events detected by |getevents|.
% # |bfra.globalfit| Distribution-fit all parameters estimated with |fitevents|.
%% 
% The toolbox supports two user-interfaces for passing inputs to these APIs: 
%% 
% # Name-value parameter pairs passed directly to the functions.
% # An options struct created by |bfra.setopts()|.
%% 
% Both of these user-interfaces are demonstrated in the example live-scripts 
% in the |demos| folder. 
%% API Specification
% The API specification for the toolbox is defined below and is also defined 
% in the |setopts| function documentation.
% 
% API specification for |*getevents*|:
%%
% 
%     qmin        :  (numeric scalar) Minimum flow value, below which values are set nan [m3/d]. Default = 1.
%     nmin        :  (numeric scalar) Minimum event length. Events with fewer than nmin data values are ignored [#]. Default = 4;
%     fmax        :  (numeric scalar) Maximum # of missing flow values gap-filled prior to fitting [#]. Default = 1.
%     rmax        :  (numeric scalar) Maximum run-length of sequential constant values, above which an event is ignored [#]. Default = 2.
%     rmin        :  (numeric scalar) Maximum allowable rainfall, above which corresponding flow values are set nan. [mm/d]. Default = 1. 
%     cmax        :  (numeric scalar) Maximum run of sequential convex dQ/dt values, above which flow values are set nan (true) or not (false). Default = 2.
%     rmconvex    :  (logical scalar) Flag indicating whether to remove convex derivatives (true) or not (false). Default = false.
%     rmnochange  :  (logical scalar) Flag indicating whether to remove consecutive constant derivates(true) or not( false). Default = true.
%     rmrain      :  (logical scalar) Flag indicating whether to remove flow values on days with rainfall>rmin (true) or not (false). Default = true.
%     pickevents  :  (logical scalar) Flag indicating whether to manually pick events (true) or use automated detection (false). Default = false.
%     plotevents  :  (logical scalar) Flag indicating whether to plot picked events. Default = false.
%     asannual    :  (logical scalar) Flag indicating whether to detect events on an annual basis. Set true if pickevents true. Default = false.
%
%% 
% API specification for |*fitevents*|:
%%
% 
%     derivmethod    : (char) derivative (dQ/dt) method. Default = 'ETS'.
%     fitmethod      : (char) -dQ/dt = aQb fitting method. Default = 'nls'.
%     fitorder       : (numeric scalar) fitting order (value of exponent b) [-]. Default = NaN.
%     pickfits       : (logical scalar) Flag indicating whether to pick fits manually. Default = false.
%     pickmethod     : (char) Method to fit picks manually. Default = 'none'.
%     plotfits       : (logical scalar) Flag indicating whether to plot the fits. Default = false.
%     savefitplots   : (logical scalar) Flag indicating whether to save plots of fits. Default = false.
%     etsparam       : (numeric scalar) Min flow length parameter for ETS algorithm [-]. Default = 0.2.
%     vtsparam       : (numeric scalar) Min flow length parameter for VTS algorithm [-]. Default = 1.0.
%     drainagearea   : (numeric scalar) Drainage area upstream of streamflow gauge [m2]. Default = NaN.
%     gageID         : (char) Station name or ID. Default = none.
%
%% 
% API specification for |*globalfit*|:
%%
% 
%       drainagearea      : (numeric scalar) Drainage area upstream of streamflow gauge [m2]. Default = NaN.
%       drainagedensity   : (numeric scalar) Drainage density = streamlength/drainagearea [km-1]. Default = 0.8.
%       aquiferdepth      : (numeric scalar) Reference aquifer thickness [m]. Default = NaN.
%       streamlength      : (numeric scalar) Effective channel length [m]. Default = NaN.
%       aquiferslope      : (numeric scalar) Effective aquifer slope [-]. Default = 0.0.
%       aquiferbreadth    : (numeric scalar) Distance from channel to catchment divide [m]. Default = NaN.
%       drainableporosity : (numeric scalar) Drainable porosity [-]. Default = 0.1.
%       isflat            : (logical scalar) Flag indicating true or false. Default = true.
%       plotfits          : (logical scalar) Flag indicating whether to plot the various global fits. Default = false.
%       bootfit           : (logical scalar) Flag indicating whether to bootstrap the uncertainties. Default = false.
%       bootreps          : (numeric scalar) Number of reps for bootstrapping. Default = 1000.
%       phimethod         : (char) Method used to fit drainable porosity. Default = 'pointcloud'.
%       refqtls           : (numeric vector) Quantiles of Q and -dQ/dt for early/late reference lines (units: N/A). Default = [0.50 0.50].
%       earlyqtls         : (numeric vector) Quantiles of Q and -dQ/dt for early reference lines (units: N/A). Default = [0.95 0.95].
%       lateqtls          : (numeric vector) Quantiles of Q and -dQ/dt for late reference lines (units: N/A). Default = [0.50 0.50].
%
%% Toolbox Functions
% Most |baseflow| workflows will revolve around calls to the three primary APIs 
% described above, which implement the underlying methods of baseflow recession 
% analysis by calling both public and private toolbox functions. These functions 
% are described below, organized around the three main toolbox features: event-detection, 
% event-scale curve fitting, and population-scale distribution fitting.
% 
% Event-detection is the process of identifying periods of declining flow in 
% streamflow timeseries, known as "recession events". Curve-fitting refers to 
% parameter estimation from individual recession events. Aquifer properties can 
% be estimated from individual recession event parameters, or from distribution 
% fits to parameter samples estimated from many events, depending on data availability 
% and the intended application.
% 
% Functions that support event detection:
%% 
% * |eventfinder| The algorithm called by |getevents| to detect recession events.
% * |eventpicker| Pick events manually, rather than automatically using |eventfinder|.
% * |eventplotter| Plot recession events detected by |eventfinder| or |eventpicker|
% * |getdqdt| Estimate the rate of change of discharge _dQ/dt_ prior to curve 
% fitting using one of several numerical differentiation options.
% * |fitets| Apply the exponential time step method to estimate the numerical 
% derivative _dQ/dt._
% * |fitcts| Apply the constant time step method to estimate the numerical derivative 
% _dQ/dt._
% * |fitvts| Apply the variable time step method to estimate the numerical derivative 
% _dQ/dt._
%% 
% Functions that support aquifer-property estimation:
%% 
% * |aquiferprops| Estimate aquifer depth, hydraulic conductivity, and drainable 
% porosity.
% * |aquiferstorage| Estimate aquifer storage from recession event parameters.
% * |aquiferthickness| Estimate aquifer thickness from recession event parameters.
% * |cloudphi| Estimate aquifer drainable porosity using the point cloud method
% * |expectedQ| Compute the expected value of baseflow.
% * |fitab| Estimate recession parameters _a_ and _b_ from individual recession 
% events
% * |eventphi| Estimate drainable porosity from individual recession events
% * |fitphi| Estimate drainable porosity from individual recession events (called 
% by |eventphi|)
% * |eventtau| Estimate timescale parameter from individual recession events
% * |pointcloudintercept| Estimate aquifer parameter _a_ from the point cloud 
% intercept
%% 
% Functions that support distribution fitting:
%% 
% * |plfitb| Fit Pareto distribution to recession timescale parameter tau.
% * |fitphidist| Fit Beta distribution to drainable porosity.
% * |gpfitb| Fit Generalized Pareto Distribution to recession parameter tau.
%% 
% Functions that support aquifer-property change detection:
%% 
% * |aquifertrend| Estimate the linear trend in saturated aquifer thickness.
% * |baseflowtrend| Estimate baseflow trend from annual streamflow timeseries.
%% 
% Functions used for visualization:
%% 
% * |hyetograph| Plot a discharge rainfall hyetograph.
% * |pointcloudplot| Plot a point-cloud diagram to estimate aquifer parameters
% * |plotdqdt| (deprecated) Plot the log-log q vs -dq/dt point-cloud with options 
% to select recession segments for fitting
% * |plotrefline| Add a reference line to a point cloud plot
% * |plplotb| Plot the power law fit to the P(tau) Pareto distribution
% * |checkevent| Plot detected recession event and fitted values
%% 
% Functions that simplify routine tasks:
%% 
% * |aQbstring| Return a formatted string for equation aQ^b .
% * |basinlist| Generate a list of basins in the |baseflow| database.
% * |basinname| Generate a list of basins in the |baseflow| database.
% * |characteristicTime| Compute the characteristic e-folding time for aquifer 
% discharge
% * |conversions| Convert common variables to their equivalent value in terms 
% of another variable
% * |fdcurve| Compute a flow duration curve from streamflow timeseries.
% * |getfunction| Get an anonymous function from the toolbox function library
% * |getstring| Get a latex-formatted string for common variables used for plot 
% labels
% * |privatefunction| Get an anonymous function for a private toolbox function
% * |setopts| Set algorithm options for functions getevents, fitevents, and 
% globalfit
% * |specialfunctions| Libarary of special functions required for recession 
% analysis
%% 
% Functions that support toolbox management:
%% 
% * |completions| Generate function auto-completions for string literals.
% * |help| Open toolbox html help document in the MATLAB Help browser.
% * |open| Open package namespace function file in the MATLAB Editor.
% * |privatefunction| Return handle to function in private/ folder.
% * |loadExampleData| Load toolbox test data. 
% * |generateTestData| Generate test data. 
%% Toolbox Structure
% All user accessible and documented functions in this toolbox are defined inside 
% the |+bfra| namespace package. This avoids naming conflicts with built-in or 
% user-defined matlab functions. Functions inside |+bfra/private| are available 
% only to functions in the parent |+bfra/| folder and are not meant to be called 
% by users. Functions inside |+bfra/+test| are primarily developer-focused but 
% are accessible to users to run unit tests if desired. Functions inside the +bfra/+deps 
% folder are third-party dependencies and are not meant to be called by the user.
%%
% 
%  +bfra/ - The package, with all documented, user accessible functions.
%     +deps/ - Third-party functions called by package functions.
%     +sym/ - Symbolic functions accessible to users.
%     +test/ - Test functions accessible to users.
%     private/ - Undocumented private methods not accessible to users.
%  data/ - Example datasets.
%  demos/ - Example live scripts.
%  docs/ - Documentation.
%  functionSignatures.json - function signatures to enable auto-completion.
%  Setup.m - user-facing installation function.
%
%% Authors & Sources
% The code was written by Matt Cooper (<mailto:matt.cooper@pnnl.gov matt.cooper@pnnl.gov>). 
% The exponential time step method implementation was inspired by Clement Roques' 
% exponential time step matlab code (available on request from Clement). The underlying 
% theory is based on idealized solutions to the one-dimensional (lateral) groundwater 
% flow equation ("Boussinesq equation"). Details can be found in the following 
% papers:
%% 
% * Brutsaert W and Nieber J L 1977 Regionalized drought flow hydrographs from 
% a mature glaciated plateau Water Resour. Res. 13 637–43.
% * Brutsaert W and Lopez J P 1998 Basin-scale geohydrologic drought flow features 
% of riparian aquifers in the Southern Great Plains Water Resour. Res. 34 233–40.
% * Rupp D E and Selker J S 2006 On the use of the Boussinesq equation for interpreting 
% recession hydrographs from sloping aquifers Water Resour. Res. 42 W12421.
%% Acknowledgements
% The Interdisciplinary Research for Arctic Coastal Environments (InteRFACE) 
% project funded this work through the United States Department of Energy, Office 
% of Science, Biological and Environmental Research (BER) Regional and Global 
% Model Analysis (RGMA) program. Awarded under contract grant # 89233218CNA000001 
% to Triad National Security, LLC (“Triad”).