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
% See the <baseflow_examples_contents.html Examples> for an introduction to using the toolbox.
%
%% *Tutorials*
%
% See the <baseflow_theory_contents.html Tutorials> for an introduction to the underlying theoretical basis of the baseflow toolbox.
%
%% *Functions*
%
% A list of toolbox functions is included below. For extended documentation, see the <m2html/function_index.html Function Index>.
% Call each function with the |baseflow.| prefix, for example |baseflow.getevents|.
%
% * |aquifertrend|       - compute the linear trend in saturated aquifer thickness
% * |aQbString|          - return a formatted string for equation aQ^b
% * |aquiferprops|       - estimate aquifer properties
% * |aquiferstorage|     - estimate aquifer storage
% * |aquiferthickness|   - estimate aquifer thickness
% * |baseflowtrend|      - compute baseflow expected value and rate of change
% * |basinlist|          - load the list of basins in the baseflow database
% * |basinname|          - return a basin name string from the baseflow basin database
% * |characteristicTime| - compute the characteristic e-folding time for baseflow
% * |checkevent|         - plot detected recession event and fitted values
% * |cloudphi|           - estimate drainable porosity phi from the point cloud
% * |conversions|        - convert inputvalue of inputvarname to the value of outputvarname
% * |dndtuncertainty|    - compute combined uncertainty of the dn/dt trend estimate
% * |eventfinder|        - find recession events on hydrograph timeseries t,q and rainfall r
% * |eventphi|           - estimate drainable porosity phi from individual recession events
% * |eventpicker|        - automated or user-guided recession event selection
% * |eventplotter|       - plot recession events detected by eventfinder
% * |eventtau|           - compute drainage timescale tau from event-scale parameters a and b
% * |expectedQ|          - compute the expected value of baseflow
% * |fdcurve|            - compute a flow duration curve from streamflow timeseries
% * |fitab|              - fit event-scale recession equation -dq/dt = aQ^b
% * |fitevents|          - fit all recession events with getdqdt and fitab
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
% * |help|               - open toolbox html help document in the MATLAB Help browser
% * |hyetograph|         - plot a discharge rainfall hyetograph
% * |loadbasins|         - load boundary object for basin specified by basinname
% * |loadExampleData|    - load toolbox example data
% * |loadflow|           - load timeseries of streamflow and metadata for basin
% * |loadmeta|           - load metadata for basin indicated by basinname
% * |loadprops|          - load basin properties from metadata table
% * |open|               - open package namespace function file in the Editor
% * |phifitensemble|     - fit ensemble of phi estimates to all recession events in Fits
% * |printtrend|         - print trends computed from columns in table Data to the screen
% * |plfitb|             - fit an unbounded Pareto Distribution to recession parameter tau
% * |plotaquifertrend|   - plot the saturated aquifer thickness trend
% * |plotdqdt|           - plot the log-log q vs dq/dt point cloud
% * |plotrefline|        - adds a reference line to a point cloud plot
% * |plplotb|            - plots the power law fit to the P(tau) pareto distribution
% * |pointcloudintercept|- estimate parameter 'a' from the point cloud intercept
% * |pointcloudplot|     - plot a 'point cloud' diagram to estimate aquifer parameters
% * |prepfits|           - preps q and -dq/dt for event-scale fitting
% * |privatefunction|    - return handle to function in private/ folder
% * |Qnonlin|            - plots the theoretical discharge predicted by a/b values
% * |QtauString|         - returns latex-formatted string for Q(tau) function
% * |QtString|           - returns latex-formatted string for Q(t) function
% * |setopts|            - set algorithm options for functions getevents, fitevents, and globalfit
% * |stationlist|        - return list of stations from the baseflow basin database
% * |stationname|        - return a station name string from the baseflow basin database
% * |specialfunctions|   - library of special functions required for recession analysis
% * |trendplot|          - plot a timeseries and linear trendline fit
% * |wrapevents|         - detect recession events on an annual calendar basis with baseflow.getevents
%
% Utility functions (not documented)
%
% * |generateTestData|   - generate test data for baseflow recession analysis
%
% Functions in the |+util| package. Call each one as |baseflow.util.<name>|.
%
% * |numevents|          - count the number of events in EventData returned by baseflow.getevents
% * |numfits|            - count the number of fits in EventFits returned by baseflow.fitevents
% * |numtau|             - count the number of tau values in the struct returned by baseflow.fitevents
%
% Functions in the |+internal| package. Call each one as |baseflow.internal.<name>|.
%
% * |version|            - return the version number for the baseflow toolbox
%
% Private functions in |+baseflow/private|. Toolbox functions call them. They are not meant to be called by users.
%
% * |fitcts|             - fit q/dqdt using a constant-time-step finite difference (use getdqdt method 'CTS')
% * |fitdqdt|            - estimate event-scale recession q and first-derivative dqdt
% * |fitets|             - fit recession event using the exponential timestep method (use getdqdt method 'ETS')
% * |fitsts|             - fit recession events using splines. Not implemented.
% * |fitvts|             - fit recession event using the variable timestep method (use getdqdt method 'VTS')
% * |flattenevents|      - flatten the cell arrays returned by findevents
% * |initfit|            - initialize arrays for common fitting routines in the baseflow toolbox
% * |prepalttrend|       - prep data for fitting linear trend to active layer thickness data
% * |setEventEmpty|      - set recession event to empty array in Events structure
% * |taufunc|            - returns inline function for tau or the value of tau
