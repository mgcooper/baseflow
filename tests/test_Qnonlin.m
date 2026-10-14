classdef test_Qnonlin < matlab.unittest.TestCase
   %TEST_QNONLIN Test the recession solution of baseflow.Qnonlin.
   %
   % Q(t) solves -dQ/dt = aQ^b from Q(0) = Q0. b = 1 is the exponential
   % Q0*exp(-a*t). For b = 1/2, sqrt(Q) falls linearly as
   % sqrt(Q0) - a*t/2, so the reservoir empties at t = 2*sqrt(Q0)/a and
   % then stays empty. For b = 0, Q falls at the rate a until it is 0, and
   % an empty reservoir has a rate of 0.

   properties (Constant)
      % Rounding error allowed in the closed-form values.
      tolerance = 1e-12
   end

   methods (Test)
      function test_linearReservoirIsExponential(testCase)
         % b = 1 gives Q0*exp(-a*t), not the constant that 1/(1-b) = Inf
         % gives in the power-law form.
         a = 0.1;
         Q0 = 100;
         t = (0:3)';
         expected = Q0*exp(-a*t);

         returned = baseflow.Qnonlin(a, 1, Q0, t);

         testCase.verifyEqual(returned, expected, ...
            'RelTol', testCase.tolerance)
      end

      function test_subLinearReservoirEmpties(testCase)
         % With a = 1/2, b = 1/2, and Q0 = 1, Q = (1 - t/4)^2 until t = 4,
         % and 0 after.
         a = 0.5;
         b = 0.5;
         Q0 = 1;
         t = (0:5)';
         expected = [1; 0.5625; 0.25; 0.0625; 0; 0];

         returned = baseflow.Qnonlin(a, b, Q0, t);

         testCase.verifyEqual(returned, expected, ...
            'AbsTol', testCase.tolerance)
      end

      function test_emptyReservoirHasNoRate(testCase)
         % With a = 1/2, b = 0, and Q0 = 1, Q = 1 - t/2 until t = 2. The
         % rate is -1/2 while flow remains and 0 once the reservoir is
         % empty, where a*Q^0 would still give -1/2.
         a = 0.5;
         b = 0;
         Q0 = 1;
         t = (0:3)';
         Q_expected = [1; 0.5; 0; 0];
         dQdt_expected = [-0.5; -0.5; 0; 0];

         [Q_returned, dQdt_returned] = baseflow.Qnonlin(a, b, Q0, t);

         testCase.verifyEqual(Q_returned, Q_expected, ...
            'AbsTol', testCase.tolerance)
         testCase.verifyEqual(dQdt_returned, dQdt_expected, ...
            'AbsTol', testCase.tolerance)
      end
   end
end
