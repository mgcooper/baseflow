function result = runtests()
% Run all tests in the bfra.test package
import matlab.unittest.TestSuite
suite = TestSuite.fromPackage("bfra.test");
result = transpose(suite.run());

for n = 1:numel(result)
   if result(n).Passed == true
      disp(['Passed Test ' int2str(n)])
   else
      disp(['Failed Test ' int2str(n)])
   end
end

% to import from a class
% suite = TestSuite.fromClass(?ParameterizedTestBfra);
% result = table(suite.run());