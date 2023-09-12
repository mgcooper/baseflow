function result = runtests(varargin)
   %RUNTESTS Run all tests in the baseflow test suite.
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
   
   % Create a test suite from the tests/ folder
   suite = TestSuite.fromFolder(fullfile(fileparts(basepath()), 'tests'));

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
      % diagnostic code can execute in the base workspace without errors. plugin
      % = DiagnosticsValidationPlugin('IncludingPassingDiagnostics',true,...
      %                                      'ValidateUsingBaseWorkspace',true);
      % runner.addPlugin(plugin)

      % Add a plugin to stop execution and enter debug mode when a test fails
      runner.addPlugin(StopOnFailuresPlugin)

      % Run the test suite using the configured runner
      result = runner.run(suite);
   end

   % Use built-in runtests with debugging to run function tests:
   % result = runtests(<test_function>, 'Debug', true);

   % % To run a coverage report
   % import matlab.unittest.TestSuite
   % import matlab.unittest.TestRunner
   % import matlab.unittest.plugins.CodeCoveragePlugin
   % import matlab.unittest.plugins.codecoverage.CoverageReport
   %
   % suite = TestSuite.fromPackage("bfra.test");
   % runner = TestRunner.withNoPlugins;
   % runner.addPlugin(CodeCoveragePlugin.forPackage("bfra.test", ...
   %    'Producing',CoverageReport('+bfra/+test/bfraCoverageResults', ...
   %    'MainFile','bfraCoverageTestResults.html')))
   % runner.run(suite)

   % % to import from a class
   % suite = TestSuite.fromClass(?ParameterizedTestBfra);
   % result = table(suite.run());
end