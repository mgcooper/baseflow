%% Getting Started with the Baseflow Recession Analysis Toolbox
% 
%% Description
% Baseflow recession analysis is a set of methods in hydrologic science
% that aim to estimate unobservable aquifer properties, such as hydraulic
% conductivity, from readily available streamflow records. This toolbox provides
% high-level MATLAB APIs that standardize the process of conducting baseflow
% recession analysis using daily streamflow data. The methods implemented in
% this toolbox are based on solutions to the one-dimensional groundwater flow
% equation and are intended primarily for application to shallow, unconfined
% riparian aquifers discharging subsurface flow into adjacent stream channels.

%% Download 
% Clone or fork the repository from <https://github.com/mgcooper/baseflow>
%
%% Installation
% 
% Place all files and folders in their own folder (e.g. |baseflow|) and then add
% that folder to the Matlab search path. 
% 
% Alternatively, run the included |Setup.m| installation function: 
%  
%  Setup('install') % for an initial install.
%  Setup('addpath') % or just Setup() in subsequent sessions, to add all toolbox paths to the search path.
% 
%% System Requirements 
% This toolbox depends on the following Mathworks products:  
%
% *  Statistics and Machine Learning Toolbox(TM) <https://www.mathworks.com/products/statistics.html> 
% *  Curve Fitting Toolbox(TM) <https://www.mathworks.com/products/curvefitting.html> 
% 
%% Accessing Help 
% Need help? Just type 
% 
%  doc bfra
% 
%% Toolbox Features
% The toolbox supports three main features:
% 
% # Baseflow recession event-detection
% # Baseflow recession curve-fitting
% # Aquifer property estimation
% 
% Event-detection is the process of identifying periods of declining flow in
% streamflow timeseries, known as "recession events". Curve-fitting refers to
% parameter estimation from individual recession events. Aquifer properties can
% be estimated from individual recession event parameters, or from distribution
% fits to parameter samples estimated from many events, depending on data
% availability and the intended application. 
% 
% Each of these three features is exposed to the user by a single API. In this
% context, an API is a high-level matlab function designed to simplify toolbox
% usage. Most |baseflow| workflows will revolve around calls to three APIs:
% 
% * |getevents| Detect recession events from timeseries of daily streamflow data.
% * |fitevents| Curve-fit all events detected by |getevents|.
% * |globalfit| Distribution-fit all parameters estimated with |fitevents|.
% 
% User calls to these three high-level APIs implement underlying methods of
% baseflow recession analysis by calling other toolbox functions, both public
% and private, depending on the user specification (inputs). The toolbox
% supports two user-interfaces for declaring inputs to these API functions. The
% first option is to pass name-value parameter pairs directly to the API
% functions. The second option is to use the |setopts| function to create an
% options structure which can be passed to the APIs in lieu of explicit
% name-value pairs. Both of these user-interfaces are demonstrated in the
% example live-scripts in the |demos| folder.
% 
% The following table defines the API specification for the toolbox, which is
% also defined in the |setopts| function documentation: 
% 
%  Optional name-value inputs for type 'getevents'
%
%     opts        :  structure containing any of the following fields
%
%     qmin        :  minimum flow value, below which values are set nan (m3/d)
%     nmin        :  minimum event length
%     fmax        :  maximum # of missing values gap-filled
%     rmax        :  maximum runlength of sequential constant values
%     rmin        :  maximum allowable rainfall in mm/d 
%     cmax        :  maximum run of sequential convex dQ/dt values
%     rmconvex    :  remove convex derivatives
%     rmnochange  :  remove consecutive constant derivates
%     rmrain      :  remove data on days with rainfall>rmin
%     pickevents  :  option to manually pick events
%     plotevents  :  option to plot picked events
%     asannual    :  option to detect events on an annual basis
%
%  Optional name-value inputs for type 'fitevents'
% 
%     derivmethod    : derivative (dQ/dt) method
%     fitmethod      : -dQ/dt = aQb fitting method
%     fitorder       : fitting order (value of exponent b)
%     fitnmin        : minimum number of values required to fit -dQ/dt = aQb 
%     pickfits       : pick fits manually?
%     pickmethod     : method to fit picks manually
%     plotfits       : plot the fits?
%     savefitplots   : save plots of fits?
%     etsparam       : min flow length parameter for ETS algorithm
%     vtsparam       : min flow length parameter for VTS algorithm
%     drainagearea   : drainage area in m2
%     gageID         : station name or ID
% 
%  Optional name-value inputs for type 'globalfit'
% 
%     drainagearea   : drainage area [m2]
%     drainagedens   : drainage density [km-1] = streamlength/drainagearea
%     aquiferdepth   : reference aquifer thickness [m]
%     streamlength   : effective channel length [m]
%     aquiferslope   : effective aquifer slope
%     aquiferbreadth : distance from channel to divide
%     drainableporos : drainable porosity
%     isflat         : logical indicating true or false
%     plotfits       : plot the various global fits?e
%     bootfit        : logical indicating whether to bootstrap the uncertainites
%     nreps          : number of reps for bootstrapping 
%     phimethod      : method used to fit drainable porosity
%     refqtls        : quantiles of Q and -dQ/dt for early/late reference lines
%     earlyqtls      : quantiles of Q and -dQ/dt for early reference lines
%     lateqtls       : quantiles of Q and -dQ/dt for late reference lines
% 
% 
% In addition to the three main user-facing APIs, many public toolbox functions
% are available for advanced use. These functions are described below, organized
% around the three main  toolbox features (event-detection, event-scale curve
% fitting, population-scale distribution fitting):
% 
%% Toolbox Functions
% 
% Functions that support event-scale aquifer-property estimation:
% 
% * |fitab| Estimate recession parameters _a_ and _b_ from individual recession events
% * |eventphi| Estimate drainable porosity from individual recession events
% * |fitphi| Estimate drainable porosity from individual recession events (called by |eventphi|)
% * |eventtau| Estimate timescale parameter from individual recession events
% * |aquiferstorage| Estimate aquifer storage from individual recession events
% 
% Functions that support population-scale aquifer-property estimation:
% 
% * |aquiferprops| Estimate aquifer depth, aquifer hydraulic conductivity, and aquifer drainable porosity using the point cloud method
% * |aquiferthickness| Estimate aquifer thickness from individual recession events
% * |cloudphi| Estimate aquifer drainable porosity using the point cloud method
% * |pointcloudintercept| Estimate aquifer parameter _a_ from the point cloud intercept
% 
% Functions used for visualization:
% 
% * |pointcloudplot| Plot a point-cloud diagram to estimate aquifer parameters
% * |plotdqdt| (deprecated) Plot the log-log q vs -dq/dt point-cloud with options to select recession segments for fitting
% * |plotrefline| Add a reference line to a point cloud plot
% * |plplotb| Plot the power law fit to the P(tau) Pareto distribution
% * |checkevent| Plot detected recession event and fitted values
% 
% Functions that simplify routine tasks:
% 
% * |characteristicTime| Compute the characteristic e-folding time for aquifer discharge
% * |conversions| Convert common variables to their equivalent value in terms of another variable
% * |getfunction| Get an anonymous function from the toolbox function library
% * |getstring| Get a latex-formatted string for common variables used for plot labels
% * |privatefunction| Get an anonymous function for a private toolbox function
% * |setopts| Set algorithm options for functions getevents, fitevents, and globalfit
% * |specialfunctions| Libarary of special functions required for recession analysis
% 
% All user accessible and documented functions in this toolbox are defined
% inside the |+bfra| namespace package. This avoids naming conflicts with
% built-in or user-defined matlab functions. Functions inside |+bfra/private|
% are available only to functions in the parent |+bfra/| folder and are not
% meant to be called by users. Functions inside |+bfra/+test| are primarily
% developer-focused but are accessible to users to run unit tests if desired.
% Functions inside the +bfra/+deps folder are third-party dependencies and are
% not meant to be called by the user.
%  
%  +bfra/ - The package, with all documented, user accessible functions
%     +deps/ - Third-party functions called by package functions
%     +sym/ - Symbolic functions accessible to users.
%     +test/ - Test functions accessible to users.
%     private/ - Undocumented private methods not accessible to users
%  data/ - Example datasets
%  demos/ - Example live scripts
%  docs/ - Documentation
%  functionSignatures.json - function signatures to enable auto-completion
%  Setup.m - user-facing installation function
% 
%% Authors & Sources
% The code was written by Matt Cooper (matt.cooper@pnnl.gov). The exponential
% time step method implementation was inspired by Clement Roques' exponential
% time step matlab code (available on request from Clement).  The underlying
% theory is based on idealized solutions to the one-dimensional (lateral)
% groundwater flow equation ("Boussinesq equation"). Details can be found in the
% following papers:
% 
% *  Brutsaert W and Nieber J L 1977 Regionalized drought flow hydrographs from
% a mature glaciated plateau Water Resour. Res. 13 637–43.
% *  Brutsaert W and Lopez J P 1998 Basin-scale geohydrologic drought flow
% features of riparian aquifers in the Southern Great Plains Water Resour. Res.
% 34 233–40.
% *  Rupp D E and Selker J S 2006 On the use of the Boussinesq equation for
% interpreting recession hydrographs from sloping aquifers Water Resour. Res. 42
% W12421.
% 
%% Acknowledgements
% The Interdisciplinary Research for Arctic Coastal Environments (InteRFACE)
% project funded this work through the United States Department of Energy,
% Office of Science, Biological and Environmental Research (BER) Regional and
% Global Model Analysis (RGMA) program. Awarded under contract grant #
% 89233218CNA000001 to Triad National Security, LLC (“Triad”).



% * |eventfinder| The algorithm called by |getevents| to detect recession events
% * |eventpicker| Pick events manually, rather than automatically using |eventfinder|
% * |eventplotter| Plot recession events detected by |eventfinder| or |eventpicker|
% * |eventsplitter| Split detected recession events into useable segments for fitting

% * |getdqdt| Estimate the rate of change of discharge _dQ/dt_ prior to curve fitting using one of several numerical differentiation options
% * |fitets| Apply the exponential time step method to estimate the numerical derivative _dQ/dt_
% * |fitcts| Apply the constant time step method to estimate the numerical derivative _dQ/dt_
% * |fitvts| Apply the variable time step method to estimate the numerical derivative _dQ/dt_

% * |plfitb| Fit Pareto distribution to timescale parameter tau
% * |fitphidist| Fit Beta distribution to drainable porosity
