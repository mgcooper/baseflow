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



% to import from a class
% suite = TestSuite.fromClass(?ParameterizedTestBfra);
% result = table(suite.run());