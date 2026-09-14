% TESTS
%
%   Contents file for the tests folder. The suite runner is
%   baseflow.internal.runtests, which builds the suite from this folder.
%   octave_smoke is a plain script that the suite builder skips; run it
%   directly in Octave or MATLAB. Unit tests of helpers vendored from
%   matfunclib live in the matfunclib library test folders.
%
%   closenewfigs           - Delete figures opened since the FIGSBEFORE snapshot
%   octave_smoke           - Core-chain smoke test runnable in GNU Octave and MATLAB
%   TestBaseflow           - Test the baseflow toolbox (parameterized class)
%   test_conversions       - Test baseflow.conversions
%   test_corechain         - Core-workflow coverage for eventtau, globalfit, fitphi, gpfitb, fitphidist, aQbString
%   test_demos             - Run every demo script in toolbox/demos/mfiles headless
%   test_dependencies      - Test the dependency tooling and list agreement
%   test_fitcts            - Test the constant-time-step dq/dt method
%   test_fitopts           - Test the fitab fitopts pass-through
%   test_internal          - Test the toolbox internal functions
%   test_islocalmax        - Test baseflow/private/islocalmax.m
%   test_peakfinder        - Test the vendored +deps/peakfinder function
%   test_plfitb_hanel      - Test the r_plfit arguments plfitb's 'hanel' passes
%   test_todatenum         - Test baseflow/private/todatenum
%   test_version           - Assert the version metadata locations agree
