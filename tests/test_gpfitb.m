classdef test_gpfitb < matlab.unittest.TestCase
   %TEST_GPFITB Test the gpfitb parameters, mean tau, and labels.
   %
   % gpfitb recovers b, k, and tau0 of a Pareto sample. A pdf exponent of
   % 2.5 gives b = 1.4 and k = 2/3, with tau0 = xmin. A Pareto sample with
   % lower bound xmin and pdf exponent alpha has the mean
   % xmin*(alpha-1)/(alpha-2) for alpha > 2. The mean diverges at or below
   % the tau pole at alpha = 2, so gpfitb must return Inf there, warn, and
   % draw no mean-tau label. Every sample is a deterministic inverse-CDF
   % draw, so the fit carries no sampling randomness.
   %
   % See also: test_getfunction

   properties (TestParameter)
      % Each case holds a pdf exponent above the pole and the mean for
      % xmin = 10: 10*(3-1)/(3-2) and 10*(4-1)/(4-2).
      finitetail = struct('alpha3', {{3, 20}}, 'alpha4', {{4, 15}})
   end

   properties (Constant)
      % Sample size and lower bound, in days, of every sample.
      nsamples = 5000
      xmin = 10

      % A pdf exponent below the pole. The formula tau0*(2-b)/(3-2*b)
      % gives tauExp = -10.01 for this sample.
      belowpolealpha = 1.5

      % Relative error allowed between the fitted and the true mean.
      reltol = 0.05

      % The identifier expectedtau warns with at the pole.
      poleid = 'baseflow:expectedtau:tauPole'
   end

   properties
      % Open-figure snapshot taken before each test.
      figsbefore
   end

   methods (TestMethodSetup)
      function snapshotfigures(testCase)
         % Close the figures each case opens (see tests/closenewfigs.m).
         testCase.figsbefore = findall(0, 'Type', 'figure');
         testCase.addTeardown(@() closenewfigs(testCase.figsbefore));
      end
   end

   methods (Access = private)
      function x = paretosample(testCase, alpha, n)
         %PARETOSAMPLE Draw a fixed Pareto sample with pdf exponent alpha.
         %
         %  x = paretosample(testCase, alpha) returns testCase.nsamples
         %  values with lower bound testCase.xmin from the inverse CDF at
         %  midpoint quantiles. A pdf exponent alpha gives the CDF
         %  exponent alpha - 1. x = paretosample(testCase, alpha, n)
         %  returns n values.
         if nargin < 3
            n = testCase.nsamples;
         end
         u = ((1:n)' - 0.5)/n;
         x = testCase.xmin * (1 - u).^(-1/(alpha - 1));
      end
   end

   methods (Test)
      function test_recoversParetoParameters(testCase)
         % gpfitb recovers b, k, and tau0 of a sample with pdf exponent 2.5,
         % with no figures when the plot and bootstrap options are off.
         % The default call runs private/ccdf.m, which must read the
         % makeplot option as p.Results.makeplot; a read of p.makeplot
         % errors.
         x = testCase.paretosample(2.5);
         b_expected = 1.4;
         k_expected = 2/3;
         tol = 0.02;

         returned = baseflow.gpfitb(x, 'xmin', testCase.xmin, ...
            'plotfit', false, 'bootfit', false);

         testCase.verifyEqual(returned.b, b_expected, 'AbsTol', tol)
         testCase.verifyEqual(returned.k, k_expected, 'AbsTol', tol)
         testCase.verifyEqual(returned.tau0, testCase.xmin, ...
            'RelTol', testCase.reltol)
         testCase.verifyEmpty(setdiff(findall(0, 'Type', 'figure'), ...
            testCase.figsbefore))
      end

      function test_labelDrawsTwoArrows(testCase)
         % Above the tau pole, gpfitb labels tau0 and the mean tau with an
         % arrow each. drawarrow draws each arrow as a tagged head patch and
         % a tagged shaft line.
         x = testCase.paretosample(2.5);
         nlabels_expected = 2;

         baseflow.gpfitb(x, 'xmin', testCase.xmin, 'plotfit', true, ...
            'bootfit', false, 'labelplot', true);

         ax = gca;
         testCase.verifyNumElements(findall(ax, 'Tag', 'refarrowhead'), ...
            nlabels_expected)
         testCase.verifyNumElements(findall(ax, 'Tag', 'refarrowshaft'), ...
            nlabels_expected)
      end

      function test_finiteMeanAbovePole(testCase, finitetail)
         % Above the pole, tauExp is the Pareto mean and gpfitb does not
         % warn.
         [alpha, expected] = finitetail{:};
         x = testCase.paretosample(alpha);

         Fit = testCase.verifyWarningFree(@() baseflow.gpfitb(x, ...
            'xmin', testCase.xmin, 'plotfit', false));

         returned = Fit.tauExp;
         testCase.verifyEqual(returned, expected, 'RelTol', testCase.reltol)
      end

      function test_meanDivergesBelowPole(testCase)
         % Below the pole, the mean tau is infinite and gpfitb warns with
         % an identifier that names the pole.
         x = testCase.paretosample(testCase.belowpolealpha);
         expected = Inf;

         Fit = testCase.verifyWarning(@() baseflow.gpfitb(x, ...
            'xmin', testCase.xmin, 'plotfit', false), testCase.poleid);

         returned = Fit.tauExp;
         testCase.verifyEqual(returned, expected)
      end

      function test_bootstrapTau0IsSigmaOverK(testCase)
         % The tau0 replicates are sigma/k, like the point estimate, so
         % their mean is near tau0 rather than near sigma = k*tau0. The
         % bootstrap resamples, so fix the seed and restore the caller's.
         rngstate = rng;
         testCase.addTeardown(@() rng(rngstate));
         % gpfitb draws 1000 replicates, so a small sample keeps it fast.
         rng(1)
         x = testCase.paretosample(3, 500);
         expected = testCase.xmin;

         Fit = baseflow.gpfitb(x, 'xmin', testCase.xmin, ...
            'plotfit', false, 'bootfit', true);

         returned = mean(Fit.tau0reps);
         testCase.verifyEqual(returned, expected, 'RelTol', testCase.reltol)
      end

      function test_labelOmitsDivergentMean(testCase)
         % Below the pole, the plot labels tau0 only. No text names a mean
         % tau, and drawarrow does not warn about a point off the log axis.
         x = testCase.paretosample(testCase.belowpolealpha);
         narrows_expected = 1;
         testCase.applyFixture( ...
            matlab.unittest.fixtures.SuppressedWarningsFixture( ...
            testCase.poleid));

         testCase.verifyWarningFree(@() baseflow.gpfitb(x, ...
            'xmin', testCase.xmin, 'plotfit', true, 'labelplot', true));

         ax = gca;
         testCase.verifyNumElements(findall(ax, 'Tag', 'refarrowhead'), ...
            narrows_expected)
         labels_returned = get(findall(ax, 'Type', 'text'), 'String');
         testCase.verifyFalse(any(contains(labels_returned, 'langle')))
      end
   end
end
