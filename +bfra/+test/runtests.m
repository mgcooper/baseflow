function out = all()
% Run all tests in the bfra.test package
import matlab.unittest.TestSuite
suite = TestSuite.fromPackage("bfra.test");
out = transpose(suite.run());

for n = 1:numel(out)
   if out(n).Passed == true
      disp(['Passed Test ' int2str(n)])
   else
      disp(['Failed Test ' int2str(n)])
   end
end