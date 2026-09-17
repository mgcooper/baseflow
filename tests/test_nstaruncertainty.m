classdef test_nstaruncertainty < matlab.unittest.TestCase
   %TEST_NSTARUNCERTAINTY Test the private nstaruncertainty helper.
   %
   % nstaruncertainty is private, so the tests reach it with
   % baseflow.privatefunction. N* = 1/(4-2b), so the propagated
   % uncertainty is |dN*/db|*sig_b. The tests compare the helper with a
   % central finite difference of N*, which is written independently of
   % the helper.

   properties (TestParameter)
      % Recession exponents that cover the linear reservoir (b = 1), the
      % Boussinesq late-time value (b = 3/2), and a value between them.
      b = struct('linear', 1, 'boussinesq', 1.5, 'between', 1.27)
   end

   properties
      % The private nstaruncertainty function handle.
      nstaruncertainty
   end

   methods (TestClassSetup)
      function gethandle(testCase)
         % Store the private function handle once for every test.
         testCase.nstaruncertainty = baseflow.privatefunction( ...
            'nstaruncertainty');
      end
   end

   methods (Test)
      function test_matchesNumericDerivative(testCase, b)
         % The propagated uncertainty equals the numeric derivative of
         % N* = 1/(4-2b) times sig_b.
         Nstar = @(x) 1 ./ (4 - 2.*x);
         step = 1e-6;
         sig_b = 0.05;
         tolerance = 1e-6;
         expected = abs(Nstar(b + step) - Nstar(b - step)) ...
            / (2*step) * sig_b;

         returned = testCase.nstaruncertainty(b, sig_b);

         testCase.verifyEqual(returned, expected, 'RelTol', tolerance)
      end

      function test_factorTwoOnlyAtBoussinesq(testCase)
         % The plain factor 2 holds for b = 3/2 and not for b = 1.
         sig_b = 0.05;
         b_boussinesq = 1.5;
         b_linear = 1;
         expected_boussinesq = 2*sig_b;

         testCase.verifyEqual(testCase.nstaruncertainty(b_boussinesq, ...
            sig_b), expected_boussinesq)
         testCase.verifyNotEqual(testCase.nstaruncertainty(b_linear, ...
            sig_b), expected_boussinesq)
      end
   end
end
