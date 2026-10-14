classdef test_aquiferstorage < matlab.unittest.TestCase
   %TEST_AQUIFERSTORAGE Test the storage bounds of baseflow.aquiferstorage.

   properties (TestParameter)
      % The recession exponents with a closed-form storage.
      RecessionExponent = {1.0,1.5}; % linear and non-linear
   end

   methods (Test)

      %-------------------------------------------
      %-------------------------------------------
      function test_storageBounds(testCase,RecessionExponent)

         % make test data
         qmin = 1;
         qmax = 100;
         a = 1;
         b = RecessionExponent;

         % compute the expected result
         switch RecessionExponent
            case 1.0
               Smin_expected = 1/a*qmin;
               Smax_expected = 1/a*qmax;

            case 1.5
               Smin_expected = 1/a/(2-b).*(qmin.^(2-b));
               Smax_expected = 1/a/(2-b).*(qmax.^(2-b));
         end

         % get the actual result
         [Smin_returned,Smax_returned] = baseflow.aquiferstorage( ...
            a,b,qmin,qmax);

         % Verify that the actual result matches the expected result
         testCase.verifyEqual([Smin_returned,Smax_returned], ...
            [Smin_expected,Smax_expected]);

      end

   end
end
