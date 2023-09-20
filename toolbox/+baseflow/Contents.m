% +BASEFLOW
% 
%   Contents file for +BASEFLOW and its subfolders.
%   
%   +BASEFLOW
%   baseflow.aQbString                           - Return a formatted string for equation aQ^b
%   baseflow.aquiferprops                        - Estimate aquifer depth, hydraulic conductivity, and porosity
%   baseflow.aquiferstorage                      - Estimate aquifer storage from recession event parameters
%   baseflow.aquiferthickness                    - Estimate aquifer thickness from recession event parameters
%   baseflow.aquifertrend                        - Estimate the linear trend in saturated aquifer thickness
%   baseflow.baseflowtrend                       - Estimate baseflow trend from annual streamflow timeseries
%   baseflow.basinlist                           - Load the list of basins in the baseflow database
%   baseflow.basinname                           - Return string 'basin' from the baseflow basin database
%   baseflow.characteristicTime                  - Compute the characteristic e-folding time for baseflow
%   baseflow.checkevent                          - Plot detected recession event and fitted values
%   baseflow.cloudphi                            - Estimate drainable porosity phi from the point cloud
%   baseflow.conversions                         - Convert inputvalue of inputvarname to the value of outputvarname
%   baseflow.dndtuncertainty                     - Compute combined uncertainty of the dn/dt trend estimate
%   baseflow.eventfinder                         - Find recession events using hydrograph and rainfall timeseries
%   baseflow.eventphi                            - Estimate drainable porosity phi from individual recession events
%   baseflow.eventpicker                         - Automated or user-guided recession event selection
%   baseflow.eventplotter                        - Plot recession events detected by eventfinder
%   baseflow.eventtau                            - Compute drainage timescale tau from event-scale parameters a and b
%   baseflow.expectedQ                           - Compute the expected value of baseflow
%   baseflow.fdcurve                             - Compute a flow duration curve from streamflow timeseries
%   baseflow.fitab                               - Fit event-scale recession equation -dq/dt = aQ^b
%   baseflow.fitevents                           - Wrapper around getdqdt and fitdqdt functions to fit all events
%   baseflow.fitphi                              - Estimate drainable porosity using early- and late-time solutions
%   baseflow.fitphidist                          - Fit drainable porosity (phi) values with a Beta distribution
%   baseflow.generateTestData                    - Generate test data for baseflow recession analysis
%   baseflow.getdqdt                             - Numerical estimation of the time derivative of discharge dQ/dt
%   baseflow.getevents                           - Get recession events from daily hydrograph timeseries T, Q, and R
%   baseflow.getEventsData                       - Get data from Events for event number eventTag
%   baseflow.getFitsData                         - Get data from Fits for event number eventTag
%   baseflow.getfunction                         - Get function handle from the baseflow function library
%   baseflow.getstring                           - Get latex-formatted string for equations in the baseflow library
%   baseflow.globalfit                           - Fit global parameters using all event-scale recession fits
%   baseflow.gpfitb                              - Fit Generalized Pareto Distribution to recession parameter tau
%   baseflow.help                                - Open toolbox html help document in the MATLAB Help browser
%   baseflow.hyetograph                          - Plot a discharge rainfall hyetograph
%   baseflow.loadbasins                          - Load boundary object for basin specified by basinname
%   baseflow.loadcalm                            - Load CALM ALT data for a basin in the Bounds struct
%   baseflow.loadExampleData                     - Load toolbox example data
%   baseflow.loadflow                            - Load timeseries of streamflow and metadata for basin
%   baseflow.loadghcnd                           - Read in a global hydroclimatology network database file
%   baseflow.loadgrace                           - Load grace data for basin in baseflow basin database
%   baseflow.loadmeta                            - Load metadata for basin indicated by basinname
%   baseflow.loadprops                           - Load basin properties from metadata table
%   baseflow.mapbasins                           - Map basin boundaries and color their faces by an attribute
%   baseflow.mapgages                            - Map a set of gage locations and color their faces by an attribute
%   baseflow.open                                - Open package namespace function file in the MATLAB Editor
%   baseflow.phifitensemble                      - Fit phi estimate ensemble using all recession events in Fits
%   baseflow.plfitb                              - Fit an unbounded Pareto Distribution to recession parameter tau
%   baseflow.plotaquifertrend                    - Plot the saturated aquifer thickness trend
%   baseflow.plotdqdt                            - Plot the log-log q vs dq/dt point-cloud
%   baseflow.plotrefline                         - Add a reference line to a point cloud plot
%   baseflow.plplotb                             - Plot the power law fit to the P(tau) pareto distribution
%   baseflow.pointcloudintercept                 - Estimate parameter 'a' from the point cloud intercept
%   baseflow.pointcloudplot                      - Plot a point-cloud diagram to estimate aquifer parameters
%   baseflow.prepfits                            - Preps q and -dq/dt for event-scale fitting
%   baseflow.printtrend                          - Print trends computed from columns in table Data to the screen
%   baseflow.privatefunction                     - Return handle to function in private/ folder
%   baseflow.Qnonlin                             - Plot the theoretical discharge predicted by a/b values
%   baseflow.QtauString                          - Return latex-formatted string for Q(tau) function
%   baseflow.QtString                            - Return latex-formatted string for Q(t) function
%   baseflow.setopts                             - Set algorithm options for functions getevents, fitevents, globalfit
%   baseflow.specialfunctions                    - Special function ibarary required for recession analysis
%   baseflow.stationlist                         - Return list of stations from the baseflow basin database
%   baseflow.stationname                         - Return string 'station' from the baseflow basin database
%   baseflow.trendplot                           - Plot a timeseries and linear trendline fit
%   baseflow.wrapevents                          - Detect recession events on an annual calendar basis
%   
%   +BASEFLOW/+DEPS
%   baseflow.deps.arrow                          - Draw a line with an arrowhead
%   baseflow.deps.derivative                     - Compute derivative while preserving dimensions
%   baseflow.deps.deta                           - Calculate Dirichlet functions of the form f = sum((-1)^n/(k*n+1)^z)
%   baseflow.deps.ginputc                        - Graphical input from mouse
%   baseflow.deps.hline                          - Draw a horizontal line on the current axes at specified location
%   baseflow.deps.ktaub                          - Mann-Kendall Tau (aka Tau-b) with Sen's Method (enhanced)
%   baseflow.deps.movingslope                    - Estimate local slope from point sequence using a sliding window
%   baseflow.deps.peakfinder                     - Noise tolerant fast peak finding algorithm
%   baseflow.deps.plfit                          - Fit a power-law distributional model to data
%   baseflow.deps.plotboxpos                     - Returns the position of the plotted axis region
%   baseflow.deps.plvar                          - Estimate the uncertainty in the estimated power-law parameters
%   baseflow.deps.rsquare                        - Compute coefficient of determination of data fit model and RMSE
%   baseflow.deps.tsregr                         - Theil-Sen estimator
%   baseflow.deps.zeta                           - Riemann Zeta function
%   
%   +BASEFLOW/+INTERNAL
%   baseflow.internal.basepath                   - Return toolbox basepath
%   baseflow.internal.buildpath                  - Build full path to toolbox folder or file
%   baseflow.internal.completions                - Generate function auto-completions for string literals
%   baseflow.internal.dependencies               - Generate function and product dependencies for function
%   baseflow.internal.docpath                    - Return path to toolbox doc file
%   baseflow.internal.makecontents               - Make contents.m for each toolbox folder including packages
%   baseflow.internal.makedocs                   - Publish GettingStarted.m as index.html for GitPages
%   baseflow.internal.replacePackagePrefix       - Replace namespace package prefix in function files
%   baseflow.internal.runtests                   - Run all tests in the test suite
%   baseflow.internal.showpath                   - Show the output of projectpath() and toolboxpath() to verify
%   baseflow.internal.version                    - Return the version number for the baseflow toolbox
%   
%   +BASEFLOW/+INTERNAL/PRIVATE
%   baseflow.internal/private.backupfile         - Create a backup file name or folder name and (optionally) a copy
%   baseflow.internal/private.cellmap            - Apply function to cell-array
%   baseflow.internal/private.closeifpublishing  - Close figure only if script is being published
%   baseflow.internal/private.convertlivescripts - Convert live script to m-files
%   baseflow.internal/private.getcontents        - Get the contents of a specified directory
%   baseflow.internal/private.getinstallpath     - Return toolbox installation path
%   baseflow.internal/private.ispublishing       - True if this script is currently being published
%   baseflow.internal/private.listfiles          - List all files in folder and (optionally) subfolders
%   baseflow.internal/private.listfolders        - Return a list of folders under a top-level directory
%   baseflow.internal/private.mpackagefolders    - List all package and sub-package folders in folder
%   baseflow.internal/private.projectpath        - Return project basepath
%   baseflow.internal/private.snapnowandclose    - Call SNAPNOW and CLOSE only if script is being published
%   baseflow.internal/private.toolboxpath        - Return toolbox basepath
%   baseflow.internal/private.updatecontents     - Create a Contents.m file including subdirectories
%   baseflow.internal/private.withcd             - Temporarily cd to a directory
%   
%   +BASEFLOW/+SYM
%   expectedvalue.mlx
%   
%   +BASEFLOW/+UTIL
%   baseflow.util.numevents                      - Count the number of events in struct returned by baseflow.getevents
%   baseflow.util.numfits                        - Count the number of fits in struct returned by baseflow.fitevents
%   baseflow.util.numtau                         - Count the number of tau values in struct returned by baseflow.fitevents
%   
%   +BASEFLOW/PRIVATE
%   baseflow/private.anomaly                     - Compute climatological anomalies and normals of column-wise data
%   baseflow/private.bootstrapci                 - Calculate confidence intervals by bootstrap resampling residuals
%   baseflow/private.catstructfields             - Concatenate struct arrays with common field names
%   baseflow/private.ccdf                        - Compute complementary cumulative distribution function
%   baseflow/private.cmd2cms                     - Convert cubic meters / second to cubic meters / day
%   baseflow/private.cms2cmd                     - Convert cubic meters / second to cubic meters / day
%   baseflow/private.dealout                     - Deal out function outputs
%   baseflow/private.emptyaxes                   - Return empty axes object
%   baseflow/private.fillnans                    - Fill sequences of nan values of length > fmax
%   baseflow/private.findevents                  - Returns flow Q and time T values of each individual recession event,
%   baseflow/private.findmin                     - Returns the k indici(s) of the min value and the value at those
%   baseflow/private.fitcts                      - Fit q/dqdt using constant time step. not implemented
%   baseflow/private.fitdqdt                     - Estimate event-scale recession q and first-derivative dqdt
%   baseflow/private.fitets                      - Fit recession event using the exponential timestep method
%   baseflow/private.fitNLS_matlab               - Initial estimates using log-log linear fit
%   baseflow/private.fitNLS_octave               - Initial estimates using log-log linear fit
%   baseflow/private.fitsts                      - Fit recession events using splines. not implemented
%   baseflow/private.fitvts                      - Fit recession event using the variable timestep method
%   baseflow/private.flattenevents               - Flatten the cell arrays returned by findevents
%   baseflow/private.formatPlotMarkers           - Apply custom formatting to plot markers. provides a cleaner
%   baseflow/private.getplotdata                 - Get data in current plot
%   baseflow/private.initfit                     - Initialize arrays for common fitting routines in the baseflow toolbox
%   baseflow/private.isaxis                      - Logical check if axis object
%   baseflow/private.ischarlike                  - Return true if input X is a cellstr, char, or string array
%   baseflow/private.isdatelike                  - Return true if input X is a datetime or datenum-like array
%   baseflow/private.isdoublescalar              - Return true if input X is a double scalar
%   baseflow/private.isdoublevector              - Return true if input X is a double vector
%   baseflow/private.iserrorbar                  - Return true if input X is an errorbar object
%   baseflow/private.islineconvex                - Return true if linear fit to input X is convex up
%   baseflow/private.islinepositive              - Return true if linear fit to input X has positive slope
%   baseflow/private.islocalmax                  - Return true for local maximum indices of X
%   baseflow/private.islogicalscalar             - Return true if input X is a logical scalar
%   baseflow/private.islogicalvector             - Return true if input X is a logical vector
%   baseflow/private.isminlength                 - Return true for runlengths exceeding minimum length
%   baseflow/private.isnumericscalar             - Return true if input X is a numeric scalar
%   baseflow/private.isnumericvector             - Return true if input X is a numeric vector
%   baseflow/private.isoctave                    - Return true if the environment is Octave
%   baseflow/private.istablelike                 - Return true if input T is a table or timetable
%   baseflow/private.latex2tex                   - Convert a LaTeX format string to a TeX interpreter format
%   baseflow/private.nancorr                     - Compute the sample correlation coefficient for data with NaNs
%   baseflow/private.nanmovmean                  - Moving average of a vector, ignoring NaNs
%   baseflow/private.nonnansegments              - Find start and end indices of complete non-nan segments
%   baseflow/private.olsfit                      - Fit ordinary least squares linear regressioin
%   baseflow/private.padtimeseries               - Pad nan from padstart to first date and last date to padend
%   baseflow/private.prepalttrend                - Prep for fitting linear trend to active layer thickness data
%   baseflow/private.preparecalendar             - Prepare time calendar
%   baseflow/private.prepCurveData               - Prepare data for curve fitting
%   baseflow/private.printnum                    - Display floating point number with specified precision
%   baseflow/private.quantreg                    - Quantile Regression
%   baseflow/private.replacevars                 - Replace vars in table T with new vars
%   baseflow/private.rmleadingnans               - Remove leading nans
%   baseflow/private.rmleapinds                  - Removes the feb 29 indices of data
%   baseflow/private.rmnan                       - Remove NaN values from data array
%   baseflow/private.rmtrailingnans              - Remove trailing nans
%   baseflow/private.rotatedLogLogText           - Add rotated text label to log-log axis
%   baseflow/private.runlength                   - Get run lengths of consecutive equal values along columns of data
%   baseflow/private.setconstantnan              - Set constant-valued runlengths exceeding RMAX nan
%   baseflow/private.setEventEmpty               - Set recession event to empty array in Events structure
%   baseflow/private.setlogticks                 - Set tick marks for log axis
%   baseflow/private.setnan                      - Sets logical indices in Data to nan
%   baseflow/private.setrainnan                  - Set rain data exceeding threshold RMIN nan
%   baseflow/private.siUnitsToTex                - Convert SI units to TeX or LaTeX-formatted strings
%   baseflow/private.smoothflow                  - Smooth measurement noise
%   baseflow/private.smoothnoise                 - Smooth measurement noise
%   baseflow/private.splinefit                   - Fit a spline to noisy data
%   baseflow/private.stderror                    - Compute the standard error of the mean from the standard deviation
%   baseflow/private.struct2vec                  - Concatenate scalar struct fields into a single column vector
%   baseflow/private.subtight                    - Create tight subplot
%   baseflow/private.taufunc                     - Return inline function for tau or the value of tau
%   baseflow/private.timetablereduce             - Statistical reduction of timetable data
%   baseflow/private.todatenum                   - Convert input to datenum
%    
%   This file was generated by updatecontents.m on 20 Sep 2023 at 14:08:07.
