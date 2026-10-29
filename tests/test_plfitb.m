classdef test_plfitb < matlab.unittest.TestCase
   %TEST_PLFITB Test the plfitb exponent, mean tau, tau pole, and legend.
   %
   % plfitb recovers the exponent of a power-law sample. plfitb bootstraps
   % with baseflow.deps.plvar, which resamples the data, so a caller seed
   % must fix the replicates. tau = tau0*(2-b)/(3-2*b) has a pole at
   % b = 3/2, which is alpha = 2. The mean tau of a Pareto tail diverges at
   % or below the pole, so plfitb returns Inf there. plfitb warns for the
   % point estimate and for the replicates. The legend plfitb draws through
   % plplotb carries one bootstrap standard deviation, so it must name no
   % coverage level. Every sample except the exponent-recovery sample is a
   % deterministic Pareto draw, which leaves the bootstrap resampling as
   % the only random step.
   %
   % See also: test_plfitb_hanel, test_getfunction

   properties (TestParameter)
      % Seeds for the reproducibility test. Each value seeds two identical
      % runs, and the next integer seeds the run that must differ.
      seed = struct('seedone', 1, 'seedseven', 7)

      % Pareto exponents at and near the tau pole. Both put several of the
      % replicates at or below alpha = 2.
      poleexponent = struct('atpole', 2.00, 'nearpole', 2.05)

      % Pareto exponents the exponent-recovery test samples.
      PowerLawExponent = {1.5, 2.0, 2.5, 3.0, 3.5};

      % Each case holds a pdf exponent above the pole and the Pareto mean
      % tau0*(alpha-1)/(alpha-2) for tau0 = 10: 10*2/1 and 10*3/2.
      meantail = struct('alpha3', {{3, 20}}, 'alpha4', {{4, 15}})
   end

   properties (Constant)
      % Sample sizes and replicate count. All three stay small to keep one
      % bootstrap run under a second.
      nsample = 400
      npolesample = 200
      nreps = 50

      % The Pareto exponent of the well-behaved sample. It sits far above
      % the pole at alpha = 2.
      tailexponent = 3.5

      % The lower bound of every sample, in days.
      tau0 = 10

      % The seed of the runs that do not compare two seeds. The replicate
      % count at the pole depends on it.
      poleseed = 1

      % The exponent at the pole. A replicate at or below it has a
      % divergent mean tau, which plfitb returns as Inf.
      polealpha = 2

      % The identifier expectedtau warns with at the pole, for the point
      % estimate and the replicates alike.
      poleid = 'baseflow:expectedtau:tauPole'

      % A pdf exponent below the pole.
      belowpolealpha = 1.5

      % Relative error allowed between the fitted and the true mean tau.
      meanreltol = 0.05
   end

   properties
      % Open-figure snapshot taken before each test.
      figsbefore
   end

   methods (TestMethodSetup)
      function snapshotstate(testCase)
         % Record the figures that exist before the test runs.
         testCase.figsbefore = findall(0, 'Type', 'figure');

         % Every test seeds the generator, so restore the state the suite
         % ran with.
         rngstate = rng;
         testCase.addTeardown(@() rng(rngstate));
      end
   end

   methods (TestMethodTeardown)
      function closetestfigures(testCase)
         % Close figures created during the test (see tests/closenewfigs.m).
         closenewfigs(testCase.figsbefore)
      end
   end

   methods (Access = private)
      function x = paretosample(testCase, exponent, n)
         %PARETOSAMPLE Draw n Pareto values from the inverse CDF.
         %
         %  x = paretosample(testCase, exponent, n) returns a fixed sample
         %  of n values with the pdf exponent EXPONENT and the lower bound
         %  testCase.tau0. The inverse CDF at n midpoint quantiles removes
         %  the sampling randomness. A pdf exponent p gives the CDF
         %  exponent p - 1.
         u = ((1:n)' - 0.5)/n;
         x = testCase.tau0 * (1 - u).^(-1/(exponent - 1));
      end

      function Fit = runbootfit(testCase, x, seedvalue)
         %RUNBOOTFIT Seed the generator and bootstrap the fit of x.
         %
         %  Fit = runbootfit(testCase, x, seedvalue) seeds the generator
         %  with SEEDVALUE and returns the plfitb fit of the sample X with
         %  testCase.nreps bootstrap replicates.
         rng(seedvalue)
         Fit = baseflow.plfitb(x, 'bootfit', true, ...
            'bootreps', testCase.nreps);
      end
   end

   methods (Test)
      function test_seedFixesReplicates(testCase, seed)
         % Two runs with one seed give identical replicates and identical
         % sigmas. The next seed gives different ones.
         x = testCase.paretosample(testCase.tailexponent, testCase.nsample);

         expected = testCase.runbootfit(x, seed);
         returned = testCase.runbootfit(x, seed);
         otherseed_returned = testCase.runbootfit(x, seed + 1);

         testCase.verifyEqual(returned.reps.tau, expected.reps.tau)
         testCase.verifyEqual(returned.reps.alpha, expected.reps.alpha)
         testCase.verifyEqual(returned.BootFit.tau_sig, ...
            expected.BootFit.tau_sig)
         testCase.verifyEqual(returned.BootFit.b_sig, expected.BootFit.b_sig)

         testCase.verifyNotEqual(otherseed_returned.reps.tau, ...
            expected.reps.tau)
         testCase.verifyNotEqual(otherseed_returned.BootFit.tau_sig, ...
            expected.BootFit.tau_sig)
      end

      function test_warnsWhenReplicatesReachTauPole(testCase, poleexponent)
         % A flat tail puts replicates at or below alpha = 2, where tau is
         % unbounded. plfitb warns and counts them.
         x = testCase.paretosample(poleexponent, testCase.npolesample);

         % Promote the warning to an error, which gives the test its
         % message.
         warnstate = warning('error', testCase.poleid);
         testCase.addTeardown(@() warning(warnstate));

         % verifyError returns the outputs of the function under test, so
         % catch the error to read its message.
         rng(testCase.poleseed)
         err_returned = MException.empty;
         try
            baseflow.plfitb(x, 'bootfit', true, 'bootreps', testCase.nreps);
         catch err_returned
         end
         testCase.assertNotEmpty(err_returned)
         testCase.verifyEqual(err_returned.identifier, testCase.poleid)

         % The message names the count and the replicate total.
         testCase.verifySubstring(err_returned.message, ...
            sprintf('of %d values of b', testCase.nreps))
      end

      function test_poleWarningKeepsReturnedValues(testCase, poleexponent)
         % The warning leaves the fit and its bounds unchanged.
         x = testCase.paretosample(poleexponent, testCase.npolesample);

         % Silence the expected warning: this test reads the values.
         testCase.applyFixture( ...
            matlab.unittest.fixtures.SuppressedWarningsFixture( ...
            testCase.poleid));

         returned = testCase.runbootfit(x, testCase.poleseed);

         % The sample sits at the pole, so some replicates cross it. The
         % mean tau of each such replicate diverges.
         ispole = returned.reps.alpha <= testCase.polealpha;
         testCase.verifyGreaterThan(nnz(ispole), 0)
         testCase.verifyEqual(returned.reps.tau(ispole), Inf(nnz(ispole), 1))

         % tau is the point estimate of a fit without the bootstrap, and
         % the bounds stay one sigma wide.
         nobootfit = baseflow.plfitb(x);
         tau_expected = nobootfit.tau;
         testCase.verifyEqual(returned.tau, tau_expected)
         testCase.verifyEqual(returned.tau_L, ...
            returned.tau - returned.BootFit.tau_sig)
         testCase.verifyEqual(returned.tau_H, ...
            returned.tau + returned.BootFit.tau_sig)
      end

      function test_meanTauAbovePole(testCase, meantail)
         % Above the pole, tau is the Pareto mean and plfitb does not warn.
         [alpha, expected] = meantail{:};
         x = testCase.paretosample(alpha, testCase.nsample);

         Fit = testCase.verifyWarningFree(@() baseflow.plfitb(x, ...
            'xmin', testCase.tau0));

         returned = Fit.tau;
         testCase.verifyEqual(returned, expected, ...
            'RelTol', testCase.meanreltol)
      end

      function test_tailMaskIncludesXmin(testCase)
         % plfit fits the tail x >= xmin, and xmin is one of the samples, so
         % the tail mask that globalfit uses keeps that sample.
         x = testCase.paretosample(testCase.tailexponent, testCase.nsample);

         Fit = baseflow.plfitb(x);

         testCase.assertTrue(any(x == Fit.tau0))
         testCase.verifyTrue(all(Fit.taumask(x == Fit.tau0)))
      end

      function test_meanTauDivergesBelowPole(testCase)
         % Below the pole, the mean tau is infinite and plfitb warns with
         % an identifier that names the pole.
         x = testCase.paretosample(testCase.belowpolealpha, ...
            testCase.nsample);
         expected = Inf;

         Fit = testCase.verifyWarning(@() baseflow.plfitb(x, ...
            'xmin', testCase.tau0), testCase.poleid);

         returned = Fit.tau;
         testCase.verifyEqual(returned, expected)
      end

      %-------------------------------------------
      %-------------------------------------------
      function test_recoversExponent(testCase,PowerLawExponent)

         % An exponent at or below 2 puts the point estimate at the tau
         % pole, so plfitb warns. This test reads the exponent only.
         testCase.applyFixture( ...
            matlab.unittest.fixtures.SuppressedWarningsFixture( ...
            testCase.poleid));

         % generate power-law distributed test data
         x = (1-rand(10000,1)).^(-1/(PowerLawExponent-1));

         % compute the fit
         [~,returned] = baseflow.plfitb(x); % the second output is alpha
         expected = PowerLawExponent;

         % The estimate from random samples varies. Allow 0.1 absolute error.
         tol = 0.1;

         % Verify that the actual result matches the expected result
         testCase.verifyEqual(returned,expected,'AbsTol',tol);

      end

      function test_noPoleWarningAwayFromPole(testCase)
         % A sample with alpha near 3.5 keeps every replicate far from the
         % pole, so plfitb issues no warning.
         x = testCase.paretosample(testCase.tailexponent, testCase.nsample);

         rng(testCase.poleseed)
         returned = testCase.verifyWarningFree(@() baseflow.plfitb(x, ...
            'bootfit', true, 'bootreps', testCase.nreps));

         npole_returned = sum(returned.reps.alpha <= testCase.polealpha);
         testCase.verifyEqual(npole_returned, 0)
      end

      function test_plotfitLegendNamesNoCoverageLevel(testCase)
         % plfitb passes the point estimate plus and minus one bootstrap
         % standard deviation to plplotb, so the legend must not label the
         % interval 95%.
         x = testCase.paretosample(testCase.tailexponent, testCase.nsample);

         rng(testCase.poleseed)
         baseflow.plfitb(x, 'bootfit', true, 'bootreps', testCase.nreps, ...
            'plotfit', true);

         % plplotb draws one legend. The data entry comes first and the fit
         % entry second.
         legend_returned = findobj(gcf, 'Type', 'legend');
         testCase.assertNumElements(legend_returned, 1)
         fitlabel_returned = legend_returned.String{2};

         testCase.verifySubstring(fitlabel_returned, 'MLE fit')
         testCase.verifyFalse(contains(fitlabel_returned, '%'))
      end
   end
end
