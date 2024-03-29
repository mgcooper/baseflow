%% Baseflow Toolbox Contents
%  
% This page lists the contents of the Baseflow Recession Analysis Toolbox. 
% 
%% *Getting Started*
% 
% See <baseflow_gettingStarted.html Getting Started> for help setting up the toolbox.
% 
%% *User Guide*
% 
% See the <baseflow_demo.html Examples> for an introduction to using the toolbox.
% 
%% *Tutorials*
% 
% See the <baseflow_theory_contents.html Tutorials> for an introduction to the underlying theoretical basis of the baseflow toolbox.
% 
%% *Functions*
% 
% A list of toolbox functions is included below. For extended documentation, see the <m2html/function_index.html Function Index>.
% 
% * |aquifertrend|       - compute the linear trend in saturated aquifer thickness
% * |aQbString|          - return a formatted string for equation aQ^b
% * |aquiferprops|       - estimate aquifer properties
% * |aquiferstorage|     - estimate aquifer storage 
% * |aquiferthickness|   - estimate aquifer thickness
% * |baseflowtrend|      - compute baseflow expected value and rate of change
% * |basinlist|          - load the list of basins in the baseflow database
% * |basinname|          - return string 'basin' from the baseflow basin database
% * |characteristicTime| - compute the characteristic e-folding time for baseflow
% * |checkevent|         - plot detected recession event and fitted values
% * |cloudphi|           - estimate drainable porosity phi from the point cloud
% * |conversions|        - convert inputvalue of inputvarname to the value of outputvarname
% * |dndtuncertainty|    - compute combined uncertainty of the dn/dt trend estimate
% * |eventfinder|        - find recession events on hydrograph timeseries t,q and rainfall r
% * |eventphi|           - estimate drainable porosity phi from individual recession events
% * |eventpicker|        - automated or user-guided recession event selection 
% * |eventplotter|       - plot recession events detected by eventfinder
% * |eventsplitter|      - eventsplitter split detected recession events into useable segments for fitting
% * |eventtau|           - compute drainage timescale tau from event-scale parameters a and b 
% * |expectedQ|          - compute the expected value of baseflow
% * |fitab|              - fit event-scale recession equation -dq/dt = aQ^b
% * |fitcts|             - fit q/dqdt using constant time step. not implemented.
% * |fitsts|             - fit recession events using splines. not implemented.
% * |fitvts|             - fit recession event using the variable timestep method
% * |flattenevents|      - flatten the cell arrays returned by findevents
% * |fitdqdt|            - estimate event-scale recession q and first-derivative dqdt
% * |fitevents|          - wrapper around getdqdt and fitdqdt functions to fit all events
% * |fitets|             - fit recession event using the exponential timestep method
% * |fitphi|             - estimates drainable porosity phi using an early- and late-time solution
% * |fitphidist|         - fit drainable porosity (phi) values with a Beta distribution
% * |getdqdt|            - Numerical estimation of the time derivative of discharge dQ/dt
% * |getevents|          - get individual recession events from daily timeseries T, Q, and R.
% * |getEventsData|      - get data from Events for event number eventTag
% * |getFitsData|        - get data from Fits for event number eventTag
% * |getstring|          - get latex-formatted string for equations in the baseflow library
% * |getfunction|        - get function handle from the baseflow function library
% * |globalfit|          - fit global parameters using all individual event-scale recession data
% * |gpfitb|             - fit Generalized Pareto Distribution to recession parameter tau
% * |initfit|            - initialize arrays for common fitting routines in the baseflow toolbox
% * |loadbasins|         - loadbasins load boundary object for basin specified by basinname
% * |loadcalm|           - loads calm ALT data for a basin in the Bounds struct
% * |loadflow|           - load timeseries of streamflow and metadata for basin
% * |loadghcnd|          - reads in a global hydroclimatology network database file 
% * |loadmeta|           - load metadata for basin indicated by basinname
% * |loadprops|          - load basin properties from metadata table
% * |mapbasins|          - map a set of basin boundaries and color their faces by an attribute
% * |mapgages|           - map a set of gage locations and color their faces by an attribute
% * |phifitensemble|     - fit ensemble of phi estimates to all recession events in Fits
% * |prepalttrend|       - prep data for fitting linear trend to active layer thickness data
% * |printtrend|         - print trends computed from columns in table Data to the screen
% * |plfitb|             - fit an unbounded Pareto Distribution to recession parameter tau
% * |plotdqdt|           - Plots the log-log q vs dq/dt with options to select the
% * |plotrefline|        - adds a reference line to a point cloud plot
% * |plplotb|            - plots the power law fit to the P(tau) pareto distribution
% * |pointcloudintercept|- estimate parameter 'a' from the point cloud intercept
% * |pointcloudplot|     - plot a 'point cloud' diagram to estimate aquifer parameters
% * |prepfits|           - preps q and -dq/dt for event-scale fitting
% * |Qnonlin|            - plots the theoretical discharge predicted by a/b values
% * |QtauString|         - returns latex-formatted string for Q(tau) function
% * |QtString|           - returns latex-formatted string for Q(t) function
% * |setopts|            - set algorithm options for functions getevents, fitevents, and globalfit
% * |stationlist|        - return list of stations from the baseflow basin database
% * |stationname|        - return string 'station' from the baseflow basin database
% * |specialfunctions|   - libarary of special functions required for recession analysis
% * |taufunc|            - returns inline function for tau or the value of tau
% * |wrapevents|         - wrapper around baseflow.getevents to get recession all recession events
% * |wrapfits|           - estimate recession coefficients (wrapper around baseflow.fitab)
% 
% Utility functions (not documented)
% 
% * |generateTestData|   - generate test data for baseflow recession analysis
% * |plotalttrend|       - plot the saturated aquifer thickness trend
% * |setEventEmpty|      - set recessoin event empty in Events structure
% * |version|            - return the version number for the baseflow toolbox