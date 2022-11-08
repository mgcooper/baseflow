%% Getting Started with baseflow recession analysis
%% Description
% Baseflow recession analysis refers to a set of methods in hydrologic science
% designed to infer aquifer properties that cannot be observed, such as
% hydraulic conductivity, from something that can be observed - streamflow. This
% toolbox provides easy-to-use functions to conduct baseflow recession analysis
% using measured values of streamflow recorded on a daily timestep. Its 
% application here is meant for shallow (depth << breadth) unconfined riparian
% aquifers that discharge subsurface flow into adjacent stream channels. 
% 
%% Download 
% Clone or fork the repository from <https://github.com/mgcooper/baseflow>
%
%% Authors & Sources
% The code was written by Matt Cooper (matt.cooper@pnnl.gov) with some code
% borrowed from Clement Roques' exponential time step matlab code (available on
% request from Clement).
% 
% The underlying theory is based on idealized solutions to the one-dimensional
% (lateral) groundwater flow equation ("Boussinesq equation"). Details can be
% found in the following papers:
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
%% System Requirements 
% This toolbox depends on the following Mathworks products:  
% Statistics and Machine Learning Toolbox 
% <https://www.mathworks.com/products/statistics.html> 
% Curve Fitting Toolbox 
% <https://www.mathworks.com/products/curvefitting.html> 
% 
%% Features
% The toolbox supports three primary features:
% 
% # Recession (baseflow) event detection
% # Recession event fitting
% # Population (distribution) fitting
% 
% Functions that support event detection:
% 
% * Get a list of all events  (|bfra.getevents|)
% * Get a cell array of all events (|bfra.findevents|)
% * Find events on an array of flow data (|bfra.eventfinder|)
% * Pick events manually (|bfra.eventpicker|)
% * Plot events (|bfra.eventplotter|)
% 
% Functions that support event fitting:
% * |bfra.fitevents|
% * |bfra.fitets|
% 
% 
% 
%  All user accessible functions in this toolbox are defined inside the 'bfra'
%  package. This avoids naming conflicts with built-in matlab functions or any
%  other namespace collision due to user-defined functions. Functions inside
%  bfra.internal are not meant to be called directly. 
%  
%  +bfra/  - The package, with all user accessible functions
%  docs/ - Documentation
%  demos/ - Example scripts
%  utils/ - Utility functions required for the package
%
%% Installation
% 
% Place all files and folders in their own folder (e.g. baseflow) and then add
% that folder to your Matlab search path. Alternatively, run the included
% |Setup.m| installation script.
%
%% Examples
% These examples provide an introduction to the toolbox. The |demos| folder
% contains additional scripts with examples.
%

%% Detect recession events from a timeseries of daily streamflow

load dailyflow.mat
Events = bfra.getevents(T,Q,R);

%% 
% The output structure Events contains arrays that are the same size as the
% input time |T|, streamflow |Q|, and rainfall |R| arrays, but all non-recession
% flows are set nan. 
% 
%% Fit individual recession events
% We pass the Events structure to |bfra.fitevents| which cycles over each
% individual recession event and fits a curve to estimate the paramaters.

[Fits,K] = bfra.fitevents(Events);

%% 
% The output structure |Fits| is similar to the input |Events|, except that the
% streamflow data has been fit using an exponential timestep to reduce the
% impact of measurement noise on the measured data. In addition, the rate of
% change of streamflow, dQ/dt, is included.

%% 
% The output table |K| contains the parameters of the fit to each individual
% recession event. These parameters form the basis for subsequent analysis.
% 
%% Global fit
% Once the individual events have been fit, we conduct inference testing on the
% sample population. 


%% 
% First we transform the observed streamflow data into a timescale parameter tau
% using the fitted parameters in |K|

[tau,q,dqdt,tags] = bfra.eventtau(K,Events,Fits,'usefits',false);

% Then we pass that into a custom Pareto distribution fitting routine to
% estimate the sample-population-scale value of the parameters a and b:
TauFit = bfra.plfitb(tau,'plot',plotfits,'boot',false);

%% 
% The |TauFit| structure contains information about the Pareto Distribution fit
% including the minimum bound, tau0, the expected value, tau, and the
% parameter estimate bhat.
% 


TauFit.tau0
TauFit.tau
TauFit.bhat
