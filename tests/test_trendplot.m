classdef test_trendplot < matlab.unittest.TestCase
   %TEST_TRENDPLOT Test the trendplot 'ols' trend and confidence bounds.
   %
   % trendplot fits the 'ols' trend with fitlm when alpha is set. The tests
   % compare the returned trend, slope error, fitted line, and bounds with
   % the fitlm LinearModel of the same decimal-year time and data.

   properties (TestParameter)
      % Significance levels. 0.1 checks that trendplot passes alpha to the
      % coefficient and fitted-line bounds instead of a fixed 95% level.
      alpha = struct('alpha05', 0.05, 'alpha10', 0.1)
      % Index of a missing value in the data. fitlm drops the missing row
      % from the fit, and trendplot still returns a fitted value there.
      missing = struct('complete', [], 'oneMissing', 5)
   end

   properties
      % Open-figure snapshot taken before each test.
      figsbefore
   end

   methods (TestMethodSetup)
      function snapshotfigures(testCase)
         % Record the figures that exist before the test runs.
         testCase.figsbefore = findall(0, 'Type', 'figure');
      end
   end

   methods (TestMethodTeardown)
      function closetestfigures(testCase)
         % Close figures created during the test (see tests/closenewfigs.m).
         closenewfigs(testCase.figsbefore)
      end
   end

   methods (Test)
      function test_olsMatchesLinearModel(testCase, alpha, missing)
         % The 'ols' trend, error, fitted line, and bounds equal the
         % LinearModel values at the significance level alpha.
         t = transpose(datetime(1990:2020, 7, 1));
         y = transpose(0.3 * (1:31) + sin(1:31));
         y(missing) = nan;
         tolerance = 1e-10;

         returned = baseflow.trendplot(t, y, 'method', 'ols', ...
            'alpha', alpha, 'anomalies', false, 'showfig', false);

         % trendplot fits against decimal years. The trend line holds them.
         tyears = reshape(get(returned.trend, 'XData'), [], 1);
         mdl = fitlm(tyears, y);
         confi = coefCI(mdl, alpha);
         ab_expected = transpose(mdl.Coefficients.Estimate);
         err_expected = confi(2, 2) - ab_expected(2);
         [yfit_expected, yci_expected] = predict(mdl, tyears, ...
            'Alpha', alpha);

         testCase.verifyEqual(returned.ab, ab_expected, 'RelTol', tolerance)
         testCase.verifyEqual(returned.err, err_expected, 'RelTol', tolerance)
         testCase.verifyEqual(returned.yfit, yfit_expected, 'RelTol', tolerance)
         testCase.verifyEqual(returned.yci, yci_expected, 'RelTol', tolerance)
      end
   end
end
