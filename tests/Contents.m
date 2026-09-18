% TESTS
%
%   Contents file for the tests folder. The suite runner is
%   baseflow.internal.runtests, which builds the suite from this folder.
%   octave_smoke is a plain script that the suite builder skips; run it
%   directly in Octave or MATLAB. Unit tests of helpers vendored from
%   matfunclib live in the matfunclib library test folders.
%
%   closenewfigs           - Delete figures opened since the FIGSBEFORE snapshot
%   verifydecadeticks      - Verify every decade inside the axis limits has a tick
%   octave_smoke           - Core-chain smoke test runnable in GNU Octave and MATLAB
%   TestBaseflow           - Test the baseflow toolbox (parameterized class)
%   test_anomaly           - Test the private anomaly helper with vector input
%   test_checkevent        - Test the baseflow.checkevent event plot
%   test_breflinetext      - Test the b value text of a reference-line label
%   test_conversions       - Test baseflow.conversions
%   test_corechain         - Core-workflow coverage for eventtau, globalfit, cloudphi, fitphi, dndtuncertainty, gpfitb, fitphidist, aQbString
%   test_demos             - Run every demo script in toolbox/demos/mfiles headless
%   test_drawarrow         - Test the arrow of a reference-line label
%   test_dependencies      - Test the dependency tooling and list agreement
%   test_eqstrings         - Test the equation label helpers
%   test_fillnans          - Test the private fillnans helper
%   test_fitcts            - Test the constant-time-step dq/dt method
%   test_figurevisibility  - Test the visibility of a figure asked to show
%   test_fitevents         - Test the fitevents plotfits option
%   test_fitopts           - Test the fitab fitopts pass-through
%   test_getdqdt           - Test the getdqdt fit-plot option
%   test_hyetograph        - Test the figure that baseflow.hyetograph draws in
%   test_internal          - Test the toolbox internal functions
%   test_islabelcolor      - Test the private islabelcolor validator
%   test_islinehandle      - Test the private islinehandle predicate
%   test_islocalmax        - Test baseflow/private/islocalmax.m
%   test_labelanchor       - Test the private labelanchor helper
%   test_labelrefline      - Test the shared reference-line label
%   test_loadflow          - Test the loadflow unit conversions
%   test_nstaruncertainty  - Test the private nstaruncertainty helper
%   test_peakfinder        - Test the vendored +deps/peakfinder function
%   test_plfitb            - Test the plfitb bootstrap seed, tau pole, and plot legend
%   test_plfitb_hanel      - Test the r_plfit arguments plfitb's 'hanel' passes
%   test_plotaquifertrend  - Test the plotaquifertrend branch handles
%   test_plotdqdt          - Test the plotdqdt reference lines, ticks, and labels
%   test_plotrefline       - Test the plotrefline label position
%   test_pointcloudplot    - Test the pointcloudplot ticks, limits, and axes
%   test_preparecalendar   - Test the private preparecalendar helper
%   test_relayoutloglogtext - Test the angle reset of a rotated log-log label
%   test_rotatedLogLogText - Test the rotated log-log label angle
%   test_setlogticks       - Test the private setlogticks decade ticks
%   test_setrainnan        - Test the private setrainnan helper
%   test_siUnitsToTex      - Test the private siUnitsToTex unit label helper
%   test_sizefigure        - Test the size of a point-cloud figure
%   test_smoothnoise       - Test the private smoothnoise helper
%   test_snaploglims       - Test the private snaploglims limit policy
%   test_todatenum         - Test baseflow/private/todatenum
%   test_trendplot         - Test the trendplot 'ols' trend and confidence bounds
%   test_version           - Assert the version metadata locations agree
