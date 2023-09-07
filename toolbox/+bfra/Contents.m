% +BFRA
% 
%   Contents file for +BFRA and its subfolders.
%   
%   +BFRA
%   bfra.aQbString                 - Return a formatted string for equation aQ^b
%   bfra.aquiferprops              - Estimate aquifer depth, hydraulic conductivity, and porosity
%   bfra.aquiferstorage            - Estimate aquifer storage from recession event parameters
%   bfra.aquiferthickness          - Estimate aquifer thickness from recession event parameters
%   bfra.aquifertrend              - Estimate the linear trend in saturated aquifer thickness
%   bfra.baseflowtrend             - Estimate baseflow trend from annual streamflow timeseries
%   bfra.basinlist                 - Load the list of basins in the bfra database
%   bfra.basinname                 - Return string 'basin' from the bfra basin database
%   bfra.characteristicTime        - Compute the characteristic e-folding time for baseflow
%   bfra.checkevent                - Plot detected recession event and fitted values
%   bfra.cloudphi                  - Estimate drainable porosity phi from the point cloud
%   bfra.completions               - Generate function auto-completions for string literals
%   bfra.conversions               - Convert inputvalue of inputvarname to the value of outputvarname
%   bfra.dependencies              - Generate function and product dependencies for function
%   bfra.dndtuncertainty           - Compute combined uncertainty of the dn/dt trend estimate
%   bfra.eventfinder               - Find recession events using hydrograph and rainfall timeseries
%   bfra.eventphi                  - Estimate drainable porosity phi from individual recession events
%   bfra.eventpicker               - Automated or user-guided recession event selection
%   bfra.eventplotter              - Plot recession events detected by eventfinder
%   bfra.eventtau                  - Compute drainage timescale tau from event-scale parameters a and b
%   bfra.expectedQ                 - Compute the expected value of baseflow
%   bfra.fdcurve                   - Compute a flow duration curve from streamflow timeseries
%   bfra.fitab                     - Fit event-scale recession equation -dq/dt = aQ^b
%   bfra.fitevents                 - Wrapper around getdqdt and fitdqdt functions to fit all events
%   bfra.fitphi                    - Estimate drainable porosity using early- and late-time solutions
%   bfra.fitphidist                - Fit drainable porosity (phi) values with a Beta distribution
%   bfra.generateTestData          - Generate test data for baseflow recession analysis
%   bfra.getdqdt                   - Numerical estimation of the time derivative of discharge dQ/dt
%   bfra.getevents                 - Get recession events from daily hydrograph timeseries T, Q, and R
%   bfra.getEventsData             - Get data from Events for event number eventTag
%   bfra.getFitsData               - Get data from Fits for event number eventTag
%   bfra.getfunction               - Get function handle from the bfra function library
%   bfra.getstring                 - Get latex-formatted string for equations in the baseflow library
%   bfra.globalfit                 - Fit global parameters using all event-scale recession fits
%   bfra.gpfitb                    - Fit Generalized Pareto Distribution to recession parameter tau
%   bfra.help                      - Open toolbox html help document in the MATLAB Help browser
%   bfra.hyetograph                - Plot a discharge rainfall hyetograph
%   bfra.loadbasins                - Load boundary object for basin specified by basinname
%   bfra.loadcalm                  - Load CALM ALT data for a basin in the Bounds struct
%   bfra.loadExampleData           - Load toolbox example data
%   bfra.loadflow                  - Load timeseries of streamflow and metadata for basin
%   bfra.loadghcnd                 - Read in a global hydroclimatology network database file
%   bfra.loadgrace                 - Load grace data for basin in baseflow basin database
%   bfra.loadmeta                  - Load metadata for basin indicated by basinname
%   bfra.loadprops                 - Load basin properties from metadata table
%   bfra.mapbasins                 - Map basin boundaries and color their faces by an attribute
%   bfra.mapgages                  - Map a set of gage locations and color their faces by an attribute
%   bfra.open                      - Open package namespace function file in the MATLAB Editor
%   bfra.phifitensemble            - Fit phi estimate ensemble using all recession events in Fits
%   bfra.plfitb                    - Fit an unbounded Pareto Distribution to recession parameter tau
%   bfra.plotaquifertrend          - Plot the saturated aquifer thickness trend
%   bfra.plotdqdt                  - Plot the log-log q vs dq/dt point-cloud
%   bfra.plotrefline               - Add a reference line to a point cloud plot
%   bfra.plplotb                   - Plot the power law fit to the P(tau) pareto distribution
%   bfra.pointcloudintercept       - Estimate parameter 'a' from the point cloud intercept
%   bfra.pointcloudplot            - Plot a point-cloud diagram to estimate aquifer parameters
%   bfra.prepfits                  - Preps q and -dq/dt for event-scale fitting
%   bfra.printtrend                - Print trends computed from columns in table Data to the screen
%   bfra.privatefunction           - Return handle to function in private/ folder
%   bfra.Qnonlin                   - Plot the theoretical discharge predicted by a/b values
%   bfra.QtauString                - Return latex-formatted string for Q(tau) function
%   bfra.QtString                  - Return latex-formatted string for Q(t) function
%   bfra.setopts                   - Set algorithm options for functions getevents, fitevents, globalfit
%   bfra.specialfunctions          - Special function ibarary required for recession analysis
%   bfra.stationlist               - Return list of stations from the bfra basin database
%   bfra.stationname               - Return string 'station' from the bfra basin database
%   bfra.trendplot                 - Plot a timeseries and linear trendline fit
%   bfra.version                   - Return the version number for the baseflow toolbox
%   bfra.wrapevents                - Detect recession events on an annual calendar basis
%   
%   +BFRA/+DEPS
%   bfra.deps.arrow                - Draw a line with an arrowhead
%   bfra.deps.derivative           - Compute derivative while preserving dimensions
%   bfra.deps.deta                 - Calculate Dirichlet functions of the form f = sum((-1)^n/(k*n+1)^z)
%   bfra.deps.ginputc              - Graphical input from mouse
%   bfra.deps.hline                - Draw a horizontal line on the current axes at specified location
%   bfra.deps.ktaub                - Mann-Kendall Tau (aka Tau-b) with Sen's Method (enhanced)
%   bfra.deps.movingslope          - Estimate local slope from point sequence using a sliding window
%   bfra.deps.peakfinder           - Noise tolerant fast peak finding algorithm
%   bfra.deps.plfit                - Fit a power-law distributional model to data
%   bfra.deps.plotboxpos           - Returns the position of the plotted axis region
%   bfra.deps.plvar                - Estimate the uncertainty in the estimated power-law parameters
%   bfra.deps.rsquare              - Compute coefficient of determination of data fit model and RMSE
%   bfra.deps.tsregr               - Theil-Sen estimator
%   bfra.deps.zeta                 - Riemann Zeta function
%   
%   +BFRA/+SYM
%   expectedvalue.mlx
%   
%   +BFRA/+TEST
%   bfra.test.runtests             - Run all tests in the bfra.test package
%   bfra.test.test_conversions     - Test bfra.conversions
%   bfra.test.test_islocalmax      - Test bfra/private/islocalmax.m
%   bfra.test.test_todatenum       - Test bfra/private/todatenum
%   bfra.test.test_withcd          - Test withcd
%   bfra.test.TestBaseflow         - Test the baseflow toolbox
%   
%   +BFRA/+UTIL
%   bfra.util.numevents            - Count the number of events in struct returned by bfra.getevents
%   bfra.util.numfits              - Count the number of fits in struct returned by bfra.fitevents
%   bfra.util.numtau               - Count the number of tau values in struct returned by bfra.fitevents
%   
%   +BFRA/PRIVATE
%   bfra/private.anomaly           - Compute climatological anomalies and normals of column-wise data
%   bfra/private.basepath          - Return toolbox basepath
%   bfra/private.bootstrapci       - Calculate confidence intervals by bootstrap resampling residuals
%   bfra/private.catstructfields   - Concatenate struct arrays with common field names
%   bfra/private.ccdf              - Compute complementary cumulative distribution function
%   bfra/private.cmd2cms           - Convert cubic meters / second to cubic meters / day
%   bfra/private.cms2cmd           - Convert cubic meters / second to cubic meters / day
%   bfra/private.dealout           - Deal out function outputs
%   bfra/private.demopath          - Return toolbox demo path
%   bfra/private.docspath          - Return toolbox docs path
%   bfra/private.emptyaxes         - Return empty axes object
%   bfra/private.fillnans          - Fill sequences of nan values of length > fmax
%   bfra/private.findevents        - Returns flow Q and time T values of each individual recession event,
%   bfra/private.findmin           - Returns the k indici(s) of the min value and the value at those
%   bfra/private.fitcts            - Fit q/dqdt using constant time step. not implemented
%   bfra/private.fitdqdt           - Estimate event-scale recession q and first-derivative dqdt
%   bfra/private.fitets            - Fit recession event using the exponential timestep method
%   bfra/private.fitNLS_matlab     - Initial estimates using log-log linear fit
%   bfra/private.fitNLS_octave     - Initial estimates using log-log linear fit
%   bfra/private.fitsts            - Fit recession events using splines. not implemented
%   bfra/private.fitvts            - Fit recession event using the variable timestep method
%   bfra/private.flattenevents     - Flatten the cell arrays returned by findevents
%   bfra/private.formatPlotMarkers - Apply custom formatting to plot markers. provides a cleaner
%   bfra/private.getinstallpath    - Return toolbox installation path
%   bfra/private.getplotdata       - Get data in current plot
%   bfra/private.initfit           - Initialize arrays for common fitting routines in the bfra toolbox
%   bfra/private.isaxis            - Logical check if axis object
%   bfra/private.ischarlike        - Return true if input X is a cellstr, char, or string array
%   bfra/private.isdatelike        - Return true if input X is a datetime or datenum-like array
%   bfra/private.isdoublescalar    - Return true if input X is a double scalar
%   bfra/private.isdoublevector    - Return true if input X is a double vector
%   bfra/private.iserrorbar        - Return true if input X is an errorbar object
%   bfra/private.islineconvex      - Return true if linear fit to input X is convex up
%   bfra/private.islinepositive    - Return true if linear fit to input X has positive slope
%   bfra/private.islocalmax        - Return true for local maximum indices of X
%   bfra/private.islogicalscalar   - Return true if input X is a logical scalar
%   bfra/private.islogicalvector   - Return true if input X is a logical vector
%   bfra/private.isminlength       - Return true for runlengths exceeding minimum length
%   bfra/private.isnumericscalar   - Return true if input X is a numeric scalar
%   bfra/private.isnumericvector   - Return true if input X is a numeric vector
%   bfra/private.isoctave          - Return true if the environment is Octave
%   bfra/private.istablelike       - Return true if input T is a table or timetable
%   bfra/private.latex2tex         - Convert a LaTeX format string to a TeX interpreter format
%   bfra/private.nancorr           - Compute the sample correlation coefficient for data with NaNs
%   bfra/private.nanmovmean        - Moving average of a vector, ignoring NaNs
%   bfra/private.nonnansegments    - Find start and end indices of complete non-nan segments
%   bfra/private.olsfit            - Fit ordinary least squares linear regressioin
%   bfra/private.padtimeseries     - Pad nan from padstart to first date and last date to padend
%   bfra/private.prepalttrend      - Prep for fitting linear trend to active layer thickness data
%   bfra/private.preparecalendar   - Prepare time calendar
%   bfra/private.prepCurveData     - Prepare data for curve fitting
%   bfra/private.printnum          - Display floating point number with specified precision
%   bfra/private.quantreg          - Quantile Regression
%   bfra/private.replacevars       - Replace vars in table T with new vars
%   bfra/private.rmleadingnans     - Consecutive leading nans true
%   bfra/private.rmleapinds        - Removes the feb 29 indices of data
%   bfra/private.rmnan             - Remove NaN values from data array
%   bfra/private.rmtrailingnans    - Remove trailing nans
%   bfra/private.rotatedLogLogText - Add rotated text label to log-log axis
%   bfra/private.runlength         - Get run lengths of consecutive equal values along columns of data
%   bfra/private.setconstantnan    - Set constant-valued runlengths exceeding RMAX nan
%   bfra/private.setEventEmpty     - Set recession event to empty array in Events structure
%   bfra/private.setlogticks       - Set tick marks for log axis
%   bfra/private.setnan            - Sets logical indices in Data to nan
%   bfra/private.setrainnan        - Set rain data exceeding threshold RMIN nan
%   bfra/private.siUnitsToTex      - Convert SI units to TeX or LaTeX-formatted strings
%   bfra/private.smoothflow        - Smooth measurement noise
%   bfra/private.smoothnoise       - Smooth measurement noise
%   bfra/private.splinefit         - Fit a spline to noisy data
%   bfra/private.stderror          - Compute the standard error of the mean from the standard deviation
%   bfra/private.struct2vec        - Concatenate scalar struct fields into a single column vector
%   bfra/private.subtight          - Create tight subplot
%   bfra/private.taufunc           - Return inline function for tau or the value of tau
%   bfra/private.timetablereduce   - Statistical reduction of timetable data
%   bfra/private.todatenum         - Convert input to datenum
%    
%   This file was generated by updatecontents.m on 06 Sep 2023 at 15:36:12.
