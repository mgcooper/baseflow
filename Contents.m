% bfra/+BFRA
% Version 1.0.0 17-Jan-2023
% 
% Files
%   alttrend            - compute the linear trend in active layer (aquifer) thickness
%   aQbString           - return a formatted string for equation aQ^b
%   aquiferprops        - estimate aquifer properties
%   aquiferstorage      - estimate aquifer storage 
%   aquiferthickness    - estimate aquifer thickness
%   basinname           - return string 'basin' from the bfra basin database
%   cloudphi            - estimate drainable porosity phi from the point cloud
%   conversions         - convert inputvalue of inputvarname to the value of outputvarname
%   eventfinder         - find recession events on hydrograph timeseries t,q and rainfall r
%   eventphi            - estimate drainable porosity phi from individual recession events
%   eventpicker         - automated or user-guided recession event selection 
%   eventplotter        - plot recession events detected by eventfinder
%   eventsplitter       - eventsplitter split detected recession events into useable segments for fitting
%   eventtau            - compute drainage timescale tau from event-scale parameters a and b 
%   expectedQ           - compute the expected value of baseflow
%   fitab               - fit event-scale recession equation -dq/dt = aQ^b
%   fitdqdt             - estimate event-scale recession q and first-derivative dqdt
%   fitevents           - wrapper around getdqdt and fitdqdt functions to fit all events
%   fitets              - fit recession event using the exponential timestep method
%   fitphi              - estimates drainable porosity phi using an early- and late-time solution
%   fitphidist          - fit drainable porosity (phi) values with a Beta distribution
%   getdqdt             - Numerical estimation of the time derivative of discharge dQ/dt
%   getevents           - get individual recession events from daily timeseries T, Q, and R.
%   getstring           - get latex-formatted string for equations in the bfra library
%   globalfit           - fit global parameters using all individual event-scale recession data
%   gpfitb              - fit Generalized Pareto Distribution to recession parameter tau
%   loadcalm            - loads calm ALT data for a basin in the Bounds struct
%   loadghcnd           - reads in a global hydroclimatology network database file 
%   loadmeta            - load metadata for basin indicated by basinname
%   plfitb              - fit an unbounded Pareto Distribution to recession parameter tau
%   plotdqdt            - Plots the log-log q vs dq/dt with options to select the
%   plotrefline         - adds a reference line to a point cloud plot
%   plplotb             - plots the power law fit to the P(tau) pareto distribution
%   pointcloudintercept - estimate parameter 'a' from the point cloud intercept
%   pointcloudplot      - plot a 'point cloud' diagram to estimate aquifer parameters
%   prepfits            - preps q and -dq/dt for event-scale fitting
%   Qnonlin             - plots the theoretical discharge predicted by a/b values
%   QtauString          - returns latex-formatted string for Q(tau) function
%   QtString            - returns latex-formatted string for Q(t) function
%   setopts             - sets default or custom bfra algorithm options for type 'events' or 'fits'
%   specialfunctions    - libarary of special functions required for baseflow recession
%   taufunc             - returns inline function for tau or the value of tau
%   baseflowtrend       - compute baseflow expected value and rate of change
%   basinlist           - load the list of basins in the bfra database
%   characteristicTime  - compute the characteristic e-folding time for baseflow
%   dndtuncertainty     - compute combined uncertainty of the dn/dt trend estimate
%   fitcts              - fit q/dqdt using constant time step. not implemented.
%   fitsts              - fit recession events using splines. not implemented.
%   fitvts              - fit recession event using the variable timestep method
%   flattenevents       - flatten the cell arrays returned by findevents
%   generateTestData    - generate test data for baseflow recession analysis
%   getfunction         - get function handle from the bfra function library
%   initfit             - initialize arrays for common fitting routines in the bfra toolbox
%   loadbounds          - load boundary object for basin specified by basinname
%   loadflow            - load timeseries of streamflow and metadata for basin
%   loadprops           - load basin properties from metadata table
%   mapbasins           - map a set of basin boundaries and color their faces by an attribute
%   mapgages            - map a set of gage locations and color their faces by an attribute
%   peakfinder          - Noise tolerant fast peak finding algorithm
%   phifitensemble      - fit ensemble of phi estimates to all recession events in Fits
%   plotalttrend        - plot the active layer thickness trend
%   prepalttrend        - prep data for fitting linear trend to active layer thickness data
%   printtrend          - print trends computed from columns in table Data to the screen
%   querymeta           - query bfra toolbox metadata structure
%   seteventnan         - set recessoin event nan in Events structure
%   stationlist         - return list of stations from the bfra basin database
%   stationname         - return string 'station' from the bfra basin database
%   version             - return the version number for the bfra toolbox
%   wrapevents          - wrapper around bfra.getevents to get recession all recession events
%   wrapfits            - estimate recession coefficients (wrapper around bfra.fitab)









