function result = runtests()
%runtests Run all tests in the bfra.test package

% Run parameterized test suite
import matlab.unittest.TestSuite
suite = TestSuite.fromPackage("bfra.test");
result = transpose(suite.run());

% print the results to the screen (bit more user friendly than the default)
for n = 1:numel(result)
   if result(n).Passed == true
      disp(['Passed Test ' int2str(n)])
   else
      disp(['Failed Test ' int2str(n)])
   end
end

% To examine failed tests
% ifailed = find(arrayfun(@(r) r.Failed, results));

%% For verbose and/or debugging

% % If you simply want to use runtests with debugging:
% % result = runtests('Debug',true);
% 
% % If using a TestSuite:
% 
% % Import necessary classes
% import matlab.unittest.TestRunner;
% import matlab.unittest.Verbosity;
% import matlab.unittest.plugins.DiagnosticsValidationPlugin;
% 
% % Create a test suite from a package
% suite = matlab.unittest.TestSuite.fromPackage("bfra.test");
% 
% % Create a test runner with detailed text output
% runner = TestRunner.withTextOutput('Verbosity', Verbosity.Detailed);
% 
% % Create a plugin to validate diagnostics. This helps ensure that diagnostic
% % messages are free of errors. The 'IncludingPassingDiagnostics' option means
% % that the plugin checks diagnostics for passing tests as well as failing ones.
% % 'ValidateUsingBaseWorkspace' means that the plugin validates that the
% % diagnostic code can execute in the base workspace without errors.
% plugin = DiagnosticsValidationPlugin('IncludingPassingDiagnostics',true,...
%                                      'ValidateUsingBaseWorkspace',true);
% runner.addPlugin(plugin)
% 
% % Add a plugin to stop execution and enter debug mode when a test fails
% import matlab.unittest.plugins.StopOnFailuresPlugin
% runner.addPlugin(StopOnFailuresPlugin)
% 
% % Run the test suite using the configured runner
% result = runner.run(suite);


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