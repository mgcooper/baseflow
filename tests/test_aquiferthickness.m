classdef test_aquiferthickness < matlab.unittest.TestCase
   %TEST_AQUIFERTHICKNESS Test the thickness of baseflow.aquiferthickness.

   properties (TestParameter)
      % The recession exponent, drainage timescale in days, and drainable
      % porosity of each thickness case.
      RecessionExponent = {1.0,1.5}; % linear and non-linear
      TauValue = {10, 100, 1000};
      PhiValue = {0.001, 0.01, 0.1};
   end

   methods (Test)

      %-------------------------------------------
      %-------------------------------------------
      function test_thicknessAndStorage(testCase,RecessionExponent,TauValue,PhiValue)

         % note: this implicitly tests baseflow.conversions

         % make test data
         Qb = 2;
         b = RecessionExponent;
         tau = TauValue;
         phi = PhiValue;

         % compute the expected result
         D_expected = tau/phi/(4-2*b)*Qb;
         S_expected = D_expected*phi;

         % get the actual result
         [D_returned,S_returned] = baseflow.aquiferthickness(b,tau,phi,Qb);

         % Verify that the actual result matches the expected result
         testCase.verifyEqual([D_returned,S_returned],[D_expected,S_expected]);

      end
   end
end
