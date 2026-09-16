classdef test_plfitb < matlab.unittest.TestCase
   %TEST_PLFITB Test the plfitb bootstrap seed, tau pole, and plot legend.
   %
   % plfitb bootstraps with baseflow.deps.plvar, which resamples the data,
   % so a caller seed must fix the replicates. tau = tau0*(2-b)/(3-2*b) has
   % a pole at b = 3/2, which is alpha = 2, and plfitb warns when a
   % replicate reaches it. The legend plfitb draws through plplotb carries
   % one bootstrap standard deviation, so it must name no coverage level.
   % Every sample is a deterministic Pareto draw, which leaves the
   % bootstrap resampling as the only random step.
   %
   % See also: test_plfitb_hanel

   properties (TestParameter)
      % Seeds for the reproducibility test. Each value seeds two identical
      % runs, and the next integer seeds the run that must differ.
      seed = struct('seedone', 1, 'seedseven', 7)

      % Pareto exponents at and near the tau pole. Both put several of the
      % replicates at or below alpha = 2.
      poleexponent = struct('atpole', 2.00, 'nearpole', 2.05)
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

      % The exponent at the pole. A replicate at or below it returns a
      % negative or unbounded tau.
      polealpha = 2

      % The identifier plfitb warns with at the pole.
      poleid = 'baseflow:plfitb:tauPoleReplicates'
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
            sprintf('of %d bootstrap replicates', testCase.nreps))
      end

      function test_poleWarningKeepsReturnedValues(testCase, poleexponent)
         % The warning leaves the fit and its bounds unchanged.
         x = testCase.paretosample(poleexponent, testCase.npolesample);

         % Silence the expected warning: this test reads the values.
         warnstate = warning('off', testCase.poleid);
         testCase.addTeardown(@() warning(warnstate));

         returned = testCase.runbootfit(x, testCase.poleseed);

         % The sample sits at the pole, so some replicates cross it.
         npole_returned = sum(returned.reps.alpha <= testCase.polealpha);
         testCase.verifyGreaterThan(npole_returned, 0)

         % tau is the point estimate, and the bounds stay one sigma wide.
         tau_expected = returned.tau0 ...
            * (2-returned.b) / (3-2*returned.b);
         testCase.verifyEqual(returned.tau, tau_expected)
         testCase.verifyEqual(returned.tau_L, ...
            returned.tau - returned.BootFit.tau_sig)
         testCase.verifyEqual(returned.tau_H, ...
            returned.tau + returned.BootFit.tau_sig)
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
