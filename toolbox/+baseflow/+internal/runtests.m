function result = runtests(varargin)
   %RUNTESTS Run all tests in the test suite.
   %
   %  result = runtests() Runs all tests.
   %  result = runtests('debug') Runs all tests in verbose / debug mode.
   %
   % See also: runtests, runperf, testsuite

   % Import necessary classes
   import matlab.unittest.TestSuite
   import matlab.unittest.TestRunner
   import matlab.unittest.Verbosity
   import matlab.unittest.plugins.DiagnosticsValidationPlugin
   import matlab.unittest.plugins.StopOnFailuresPlugin

   % Draw every test figure off screen. The tests close the figures they
   % open, so on a desktop a window flashes open and shut for each one.
   % Nothing in the suite reads the Visible property. Both exits below put
   % the default back, so a run that errors leaves the caller's figures
   % visible. A figure created with an explicit 'Visible' of 'on' ignores
   % this default, so the functions that take a show option ask
   % private/figurevisibility what to draw.
   %
   % This bookkeeping stays inline: a function here would be a function the
   % suite this runner starts cannot reach, so it could carry no tests.
   % 'remove' clears the default, which is what the root had when it had
   % none.
   defaults = get(groot, 'default');
   if isfield(defaults, 'defaultFigureVisible')
      previousvisibility = get(groot, 'defaultFigureVisible');
   else
      previousvisibility = 'remove';
   end
   set(groot, 'defaultFigureVisible', 'off');

   try
      % Create a test suite from the tests/ folder
      suite = TestSuite.fromFolder(fullfile(projectpath(), 'tests'));

      if nargin < 1
         % Run parameterized test suite
         result = transpose(suite.run());

         % Print the results to the screen
         for n = 1:numel(result)
            if result(n).Passed == true
               disp(['Passed Test ' int2str(n)])
            else
               disp(['Failed Test ' int2str(n)])
            end
         end
         % To examine failed tests
         % ifailed = find(arrayfun(@(r) r.Failed, results));

      else
         % For verbose and/or debugging
         validatestring(varargin{1}, {'debug'}, mfilename, 'option', 1)

         % Create a test runner with detailed text output
         runner = TestRunner.withTextOutput('Verbosity', Verbosity.Detailed);

         % Create a plugin to validate diagnostics. This helps ensure that
         % diagnostic messages are free of errors. The
         % 'IncludingPassingDiagnostics' option means that the plugin checks
         % diagnostics for passing tests as well as failing ones.
         % 'ValidateUsingBaseWorkspace' means that the plugin validates that the
         % diagnostic code can execute in the base workspace without errors.
         %
         % plugin = DiagnosticsValidationPlugin('IncludingPassingDiagnostics',true,...
         %                                      'ValidateUsingBaseWorkspace',true);
         % runner.addPlugin(plugin)

         % Add a plugin to stop execution and enter debug mode when a test fails
         runner.addPlugin(StopOnFailuresPlugin)

         % Run the test suite using the configured runner
         result = runner.run(suite);
      end
   catch err
      set(groot, 'defaultFigureVisible', previousvisibility);
      rethrow(err)
   end

   % Put the figure default back now that the run is over.
   set(groot, 'defaultFigureVisible', previousvisibility);

   % Use built-in runtests with debugging to run function tests:
   % result = runtests(<test_function>, 'Debug', true);

   % % To run a coverage report
   % import matlab.unittest.TestSuite
   % import matlab.unittest.TestRunner
   % import matlab.unittest.plugins.CodeCoveragePlugin
   % import matlab.unittest.plugins.codecoverage.CoverageReport
   %
   % suite = TestSuite.fromPackage("baseflow.test");
   % runner = TestRunner.withNoPlugins;
   % runner.addPlugin(CodeCoveragePlugin.forPackage("baseflow.test", ...
   %    'Producing',CoverageReport('+baseflow/+test/baseflowCoverageResults', ...
   %    'MainFile','baseflowCoverageTestResults.html')))
   % runner.run(suite)

   % % to import from a class
   % suite = TestSuite.fromClass(?ParameterizedTestBfra);
   % result = table(suite.run());
end

