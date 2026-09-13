% TESTS
%
%   Contents file for the tests folder. The suite runner is
%   baseflow.internal.runtests, which builds the suite from this folder.
%   octave_smoke is a plain script that the suite builder skips; run it
%   directly in Octave or MATLAB.
%
%   closenewfigs           - Delete figures opened since the FIGSBEFORE snapshot
%   octave_smoke           - Core-chain smoke test runnable in GNU Octave and MATLAB
%   TestBaseflow           - Test the baseflow toolbox (parameterized class)
%   test_anomaly           - Test the private anomaly helper
%   test_conversions       - Test baseflow.conversions
%   test_corechain         - Core-workflow coverage for eventtau, globalfit, fitphi, gpfitb, fitphidist, aQbString
%   test_demos             - Run every demo script in toolbox/demos/mfiles headless
%   test_dependencies      - Test the dependency tooling and list agreement
%   test_fillnans          - Test the private fillnans helper
%   test_fitcts            - Test the constant-time-step dq/dt method
%   test_fitopts           - Test the fitab fitopts pass-through
%   test_getplotdata       - Test the private getplotdata helper
%   test_internal          - Test the toolbox internal functions
%   test_internalfilelists - Test the listfiles and mpackagefolders helpers
%   test_islocalmax        - Test baseflow/private/islocalmax.m
%   test_makedocs          - Test the docpages option of baseflow.internal.makedocs
%   test_nanstats          - Test the private nanmean and nanmedian helpers
%   test_nonnansegements   - Test the nonnansegments private function
%   test_peakfinder        - Test the vendored +deps/peakfinder function
%   test_plfitb_hanel      - Test the r_plfit arguments plfitb's 'hanel' passes
%   test_runlength         - Test the private runlength helper
%   test_setrainnan        - Test the private setrainnan helper
%   test_smoothnoise       - Test the private smoothnoise helper
%   test_timetablereduce   - Test timetablereduce and renametimetabletimevar
%   test_tocolumn          - Test the private tocolumn helper
%   test_todatenum         - Test baseflow/private/todatenum
%   test_version           - Assert the version metadata locations agree
%   test_withcd            - Test the withcd temporary-directory helper
%   test_yorkfit           - Test the York bivariate regression helper
