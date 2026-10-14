classdef test_getfunction < matlab.unittest.TestCase
   %TEST_GETFUNCTION Test the expected-tau handle of baseflow.getfunction.
   %
   % A Pareto distribution with lower bound tau0 and pdf exponent alpha has
   % the mean tau0*(alpha-1)/(alpha-2) for alpha > 2. The mean integral
   % diverges for 1 < alpha <= 2, and alpha <= 1 gives no normalizable
   % distribution. The handle takes b = 1 + 1/alpha, so the tau pole at
   % alpha = 2 is b = 3/2. Each expected value below comes from the alpha
   % form of the mean, not from the b form the handle uses.
   %
   % See also: test_gpfitb, test_plfitb

   properties (TestParameter)
      % Each case holds b and the expected mean for tau0 = 10.
      % alpha = 4, 3, and 2.5 give the finite means 10*3/2, 10*2/1, and
      % 10*1.5/0.5. alpha = 2 is the pole and alpha = 1.5 lies below it,
      % so the mean diverges. alpha = 1 and alpha = -2 have no Pareto tail.
      expectedtau = struct( ...
         'alpha4', {{1.25, 15}}, ...
         'alpha3', {{4/3, 20}}, ...
         'alpha2p5', {{1.4, 30}}, ...
         'atpole', {{1.5, Inf}}, ...
         'belowpole', {{5/3, Inf}}, ...
         'alpha1', {{2, NaN}}, ...
         'negativealpha', {{0.5, NaN}})
   end

   properties (Constant)
      % The lower bound of the tau distribution, in days.
      tau0 = 10

      % Rounding error allowed in a finite mean. b = 4/3 has no exact
      % binary value.
      tolerance = 1e-12

      % The identifier expectedtau warns with at the pole.
      poleid = 'baseflow:expectedtau:tauPole'
   end

   methods (Test)
      function test_expectedTauAtThePole(testCase, expectedtau)
         % The handle returns the finite mean above the pole, Inf where
         % the mean diverges, and NaN where no Pareto tail exists.
         testCase.applyFixture( ...
            matlab.unittest.fixtures.SuppressedWarningsFixture( ...
            testCase.poleid));
         [b, expected] = expectedtau{:};
         Fnc = baseflow.getfunction('expectedTau');

         returned = Fnc(testCase.tau0, b);

         testCase.verifyEqual(returned, expected, ...
            'AbsTol', testCase.tolerance)
      end

      function test_poleWarningCountsTheValues(testCase)
         % A call above the pole does not warn. A call with two of three
         % values beyond it warns once and counts them.
         Fnc = baseflow.getfunction('expectedTau');
         testCase.verifyWarningFree(@() Fnc(testCase.tau0, [1.25 1.4]));

         % Promote the warning to an error, which gives the test its
         % message.
         warnstate = warning('error', testCase.poleid);
         testCase.addTeardown(@() warning(warnstate));
         err_returned = MException.empty;
         try
            Fnc(testCase.tau0, [1.4 1.6 0.5]);
         catch err_returned
         end
         testCase.assertNotEmpty(err_returned)
         testCase.verifyEqual(err_returned.identifier, testCase.poleid)
         testCase.verifySubstring(err_returned.message, '2 of 3 values of b')
      end

   end
end
