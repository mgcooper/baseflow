classdef test_fitlm_octmat < matlab.unittest.TestCase
   %TEST_FITLM_OCTMAT Test the private fitlm_octmat linear model helper.
   %
   % fitlm_octmat is private, so the tests reach it with
   % baseflow.privatefunction. The tests compare the Fit and stats structs
   % with the fitlm LinearModel of the same data.

   properties (TestParameter)
      % Each case holds the optional alpha argument and the significance
      % level it gives. An omitted alpha gives 0.05.
      alpha = struct( ...
         'omitted', {{{}, 0.05}}, ...
         'alpha10', {{{0.1}, 0.1}})
   end

   properties
      % The private fitlm_octmat function handle.
      fitlm_octmat
   end

   methods (TestClassSetup)
      function gethandle(testCase)
         % Store the private function handle once for every test.
         testCase.fitlm_octmat = baseflow.privatefunction('fitlm_octmat');
      end
   end

   methods (Test)
      function test_matchesLinearModel(testCase, alpha)
         % Fit_returned and stats_returned hold the LinearModel values,
         % and both the coefficient and fitted-line bounds use the alpha
         % level.
         [alphaarg, alphalevel] = alpha{:};
         X = transpose(1:40);
         y = 2 + 0.5 * X + sin(X);
         tolerance = 1e-10;

         mdl = fitlm(X, y);
         [yFit_expected, yCI_expected] = predict(mdl, X, ...
            'Alpha', alphalevel);
         CI_expected = coefCI(mdl, alphalevel);

         [Fit_returned, stats_returned] = testCase.fitlm_octmat(X, y, ...
            alphaarg{:});

         testCase.verifyEqual(Fit_returned.X, X)
         testCase.verifyEqual(Fit_returned.y, y)
         testCase.verifyEqual(Fit_returned.yFit, yFit_expected, ...
            'AbsTol', tolerance)
         testCase.verifyEqual(Fit_returned.yCI, yCI_expected, ...
            'AbsTol', tolerance)
         testCase.verifyEqual(stats_returned.Coefficients.Estimate, ...
            mdl.Coefficients.Estimate, 'AbsTol', tolerance)
         testCase.verifyEqual(stats_returned.Coefficients.SE, ...
            mdl.Coefficients.SE, 'AbsTol', tolerance)
         testCase.verifyEqual(stats_returned.Coefficients.CI, CI_expected, ...
            'AbsTol', tolerance)
         testCase.verifyEqual(stats_returned.Coefficients.tStat, ...
            mdl.Coefficients.tStat, 'AbsTol', tolerance)
         testCase.verifyEqual(stats_returned.Coefficients.pValue, ...
            mdl.Coefficients.pValue, 'AbsTol', tolerance)
         testCase.verifyEqual(stats_returned.CoefficientCovariance, ...
            mdl.CoefficientCovariance, 'AbsTol', tolerance)
         testCase.verifyEqual(stats_returned.MSE, mdl.MSE, 'AbsTol', tolerance)
         testCase.verifyEqual(stats_returned.DFE, mdl.DFE)
      end
   end
end
