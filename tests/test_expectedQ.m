classdef test_expectedQ < matlab.unittest.TestCase
   %TEST_EXPECTEDQ Test the expected flows of baseflow.expectedQ.
   %
   % Qexp = (a*tau)^(1/(1-b)) and Q0 = Qexp*(3-b)/(2-b). With a = 0.01,
   % b = 1.5, and tau = 400 days, a*tau = 4. So Qexp = 4^-2 = 0.0625 and
   % Q0 = 3*Qexp = 0.1875. pQexp and pQ0 are the fdcurve positions
   % 1 - M/(N+1) of the two flows, where M counts the flows at or above
   % each one. A mean tau that is not finite gives NaN for all four.
   %
   % See also: test_plfitb, test_getfunction

   properties (TestParameter)
      % tau values with no mean: beyond the tau pole, and with no tail.
      notfinite = struct('diverges', Inf, 'notail', NaN)
   end

   properties (Constant)
      % Recession parameters of the hand-computed case.
      a = 0.01
      b = 1.5

      % Four flows: one below Qexp, one between Qexp and Q0, and two
      % above Q0. M is 3 for Qexp and 2 for Q0, and N is 4.
      flow = [0.05; 0.1; 0.2; 0.3]

      % Rounding error allowed in the hand-computed values.
      tolerance = 1e-12
   end

   methods (Test)
      function test_finiteTauGivesFlows(testCase)
         % A finite tau gives the hand-computed flows and positions.
         tau = 400;
         expected = [0.0625 0.1875 1-3/5 1-2/5];

         [Qexp, Q0, pQexp, pQ0] = baseflow.expectedQ(testCase.a, ...
            testCase.b, tau, [], [], [], 'qtls', testCase.flow);

         returned = [Qexp Q0 pQexp pQ0];
         testCase.verifyEqual(returned, expected, ...
            'AbsTol', testCase.tolerance)
      end

      function test_tauNotFiniteGivesNaN(testCase, notfinite)
         % A tau that is not finite gives NaN flows and positions, with no
         % warning of its own: the pole warning comes from expectedtau.
         expected = nan(1, 4);

         [Qexp, Q0, pQexp, pQ0] = testCase.verifyWarningFree(@() ...
            baseflow.expectedQ(testCase.a, testCase.b, notfinite, [], ...
            [], [], 'qtls', testCase.flow));

         returned = [Qexp Q0 pQexp pQ0];
         testCase.verifyEqual(returned, expected)
      end

      function test_plfitbTauBeyondPoleGivesNaN(testCase)
         % globalfit passes the plfitb mean tau to expectedQ. A Pareto
         % sample with alpha = 1.5 is beyond the pole, so tau is Inf. The
         % flows are then NaN rather than the zero flow of an infinite tau.
         testCase.applyFixture( ...
            matlab.unittest.fixtures.SuppressedWarningsFixture( ...
            'baseflow:expectedtau:tauPole'));
         nsamples = 400;
         tau0 = 10;
         belowpolealpha = 1.5;
         expected = [NaN NaN];

         u = ((1:nsamples)' - 0.5)/nsamples;
         x = tau0 * (1 - u).^(-1/(belowpolealpha - 1));
         Fit = baseflow.plfitb(x, 'xmin', tau0);
         [Qexp, Q0] = baseflow.expectedQ(testCase.a, Fit.b, Fit.tau, ...
            [], [], Fit.tau0);

         returned = [Qexp Q0];
         testCase.verifyEqual(returned, expected)
      end
   end
end
