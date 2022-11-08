%% Getting Started with the Baseflow Recession Analysis Toolbox
% 
%% Description
% Baseflow recession analysis refers to a set of methods in hydrologic science
% designed to infer aquifer properties that cannot be observed, such as
% hydraulic conductivity, from something that can be observed, such as
% streamflow. This toolbox provides easy-to-use functions to conduct baseflow
% recession analysis using measured values of streamflow recorded on a daily
% timestep. Its application here is meant for shallow (depth << breadth)
% unconfined riparian aquifers that discharge subsurface flow into adjacent
% stream channels.
% 
%% Download 
% Clone or fork the repository from <https://github.com/mgcooper/baseflow>
%
%% Authors & Sources
% The code was written by Matt Cooper (matt.cooper@pnnl.gov) with some code
% borrowed from Clement Roques' exponential time step matlab code (available on
% request from Clement). The underlying theory is based on idealized solutions
% to the one-dimensional (lateral) groundwater flow equation ("Boussinesq
% equation"). Details can be found in the following papers: 
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
%
% *  Statistics and Machine Learning Toolbox(TM) <https://www.mathworks.com/products/statistics.html> 
% *  Curve Fitting Toolbox(TM) <https://www.mathworks.com/products/curvefitting.html> 
% 
%% Accessing Help 
% Need help? Just type 
% 
%  doc bfra
% 
%% Features
% The toolbox supports five main features:
% 
% # Recession (baseflow) event detection
% # Recession (baseflow) event curve-fitting
% # Recession (baseflow) parameter distribution-fitting
% # Aquifer-property estimation from event-scale curve-fitting parameters
% # Aquifer-property estimation from population-scale distribution-fitting
% parameters
% 
% Functions that support event detection:
% 
% * |getevents| Detect recession events on a multi-year timeseries of streamflow data, returned as an array
% * |findevents| Identify recession events from a multi-year timeseries of streamflow data, returned as a cell array (called by |getevents|) 
% * |eventfinder| Automatically detect recession events using objective parameters and filters to detect change points, convert detected recession events into segments (called by |findevents|)
% * |eventpicker| Pick events manually, rather than automatically using |eventfinder|
% * |eventplotter| Plot recession events detected by |eventfinder| or |eventpicker|
% 
% Functions that support event fitting:
% 
% * |fitevents| Curve-fit all events using the |Events| output of |getevents| 
% * |getdqdt| Estimate the rate of change of discharge dQ/dt prior to curve fitting using one of several numerical differentiation options
% * |fitdqdt| Estimate the rate of change of discharge dQ/dt prior to curve fitting using one of several numerical differentiation options
% * |fitets| Apply the exponential time step method to estimate the numerical derivative dQ/dt)
%
% Functions that support distribution fitting:
% 
% * |plfitb| Fit Pareto distribution to timescale parameter tau
% * |fitphidist| Fit Beta distribution to drainable porosity
% 
% Functions that support event-scale aquifer-property estimation:
% 
% * |fitab| Estimate recession parameters _a_ and _b_ from individual recession events
% * |eventphi| Estimate drainable porosity from individual recession events
% * |fitphi| Estimate drainable porosity from individual recession events (called by |eventphi|)
% * |eventtau| Estimate timescale parameter from individual recession events
% * |eventtau| Estimate timescale parameter from individual recession events
% * |aquiferstorage| Estimate aquifer storage from individual recession events
% 
% Functions that support population-scale aquifer-property estimation:
% 
% * |aquiferprops| Estimate aquifer depth, aquifer hydraulic conductivity, and aquifer drainable porosity using the point cloud method
% * |aquiferthickness| Estimate aquifer thickness from individual recession events
% * |cloudphi| Estimate aquifer drainable porosity using the point cloud method
% 
% All user accessible functions in this toolbox are defined inside the '+bfra'
% package. This avoids naming conflicts with built-in matlab functions or any
% other namespace collision due to user-defined functions. Functions inside
% bfra.internal are not meant to be called directly. 
%  
%  +bfra/  - The package, with all user accessible functions
%  docs/ - Documentation
%  demos/ - Example scripts
%  utils/ - Utility functions required for the package
%
%% Installation
% 
% Place all files and folders in their own folder (e.g. baseflow) and then add
% that folder to your Matlab search path.
% Alternatively, run the included |Setup.m| installation script.
%