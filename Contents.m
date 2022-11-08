% bfra/+BFRA
% Version 1.0.0 04-Nov-2020
% 
% Files
%   alttrend            - computes the linear trend in active layer (aquifer) thickness
%   aQbString           - returns a formatted string for equation aQ^b
%   aquiferprops        - computes aquifer properties hydraulic conductivity k, depth D, and
%   aquiferstorage      - computes aquifer storage given input parameters a,b and flow
%   aquiferthickness    - compute the aquifer thickness from recession parameters
%   baseflow            - computes the expected value of baseflow and rate of change
%   basinname           - returns a string 'basinname' from the bfra basin database, which can
%   cloudphi            - estimates drainable porosity phi from the point cloud using the
%   conversions         - convert inputvalue from its value in terms of inputvarname to
%   defaultopts         - set default bfra algorithm options for type 'events' or 'fits'
%   eventfinder         - finds recession events on input hydrographs with time 't',
%   eventphi            - estimates drainable porosity phi from individual recession
%   eventpicker         - automated or user-guided recession event selection from input
%   eventplotter        - plots recession events detected by getevents, with options to
%   eventsplitter       - eventsplitter splits events into useable segments eg if an event is
%   eventtau            - computes drainage timescale tau from the event-scale parameters
%   expectedQ           - general description of function
%   findevents          - returns flow Q and time T values of each individual recession event,
%   fitab               - fits -dq/dt = aQ^b to estimate parameters a and b
%   fitdqdt             - estimate q and dqdt during recession events to send to fitab
%   fitevents           - wrapper around getdqdt and fitdqdt functions to fit all events
%   fitets              - fits recession event using the exponential timestep method
%   fitphi              - estimates drainable porosity phi using an early-time and
%   fitphidist          - fits a Beta distribution to a sample of drainable porosity (phi) values 
%   getdqdt             - Numerical estimation of the time derivative of discharge dQ/dt
%   getevents           - wrapper around bfra.findevents to get recession all recession events
%   getstring           - returns various latex-formatted strings
%   globalfit           - takes the event-scale recession analysis parameters saved in
%   gpfitb              - returns [b,alpha,k]=gpfitb(x,xmin) where parmhat=gpfit(xhat)
%   loadcalm            - loads calm ALT data for a basin in the Bounds struct
%   loadcalm_new        - loads calm ALT data for a basin in the Bounds struct
%   loadghcnd           - reads in a global hydroclimatology network database file
%   loadmeta            - load metadata for basin indicated by basinname
%   plfitb              - returns [b,alpha,k]=bfra.plfitb(x,varargin) where x is continuous data
%   plotdqdt            - Plots the log-log q vs dq/dt with options to select the
%   plotrefline         - adds a reference line to a point cloud plot
%   plplotb             - plots the power law fit to the P(tau) pareto distribution
%   pointcloudintercept - estimate parameter 'a' from the point cloud intercept
%   pointcloudplot      - plots a 'point cloud' diagram to estimate aquifer parameters
%   prepfits            - preps q and -dq/dt for event-scale fitting
%   Qnonlin             - plots the theoretical discharge predicted by a/b values
%   QtauString          - returns latex-formatted string for Q(tau) function
%   QtString            - returns latex-formatted string for Q(t) function
%   specialfunctions    - libarary of special functions required for baseflow recession
%   taufunc             - returns inline function for tau or the value of tau
%   wrapFits            - estimates the recession coefficient (wrapper around bfra.fitab)
